#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: collector_operacao_auto.sh
# Descrição: Coletor automático de estado operacional de servidores SFT e
#            aplicações do painel sinótico.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, ssh, awk, grep, tr, coreutils
# Saída:
#   - backend/data/current/operacao_servidores.csv
#   - backend/data/current/painel_sinotico.csv
#   - backend/data/events/nexus_events.csv
# ==============================================================================

set -euo pipefail

# ============================================================
# Caminhos internos
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_DIR="$BACKEND_DIR/config"
DATA_DIR="$BACKEND_DIR/data"
CURRENT_DIR="$DATA_DIR/current"

HOSTS_CONFIG="$CONFIG_DIR/nexus_hosts.config"

OPERACAO_FILE="$CURRENT_DIR/operacao_servidores.csv"
PAINEL_FILE="$CURRENT_DIR/painel_sinotico.csv"

TMP_OPERACAO="$(mktemp /tmp/nexus_operacao.XXXXXX)"
TMP_PAINEL="$(mktemp /tmp/nexus_painel.XXXXXX)"

mkdir -p "$CURRENT_DIR"

# Carrega biblioteca core de eventos.
source "$BACKEND_DIR/core/nexus_db.sh"

# ============================================================
# Configurações
# ============================================================

HOSTNAME_LOCAL="$(hostname)"
MODULO="OPERACAO_AUTO"

SSH_OPTS=(
    -o BatchMode=yes
    -o ConnectTimeout=6
    -o StrictHostKeyChecking=no
)

# Processos usados para identificar servidores SFT ativos.
SFT_PROCESS_REGEX="sb_envia|sb_recebe|sb_watchdog|sb_ping|bac_eth"

# Processo usado para identificar aplicação de painel sinótico.
PAINEL_PROCESS_REGEX="painelcon"

# ============================================================
# Limpeza
# ============================================================

cleanup() {
    rm -f "$TMP_OPERACAO" "$TMP_PAINEL"
}

trap cleanup EXIT

# ============================================================
# Funções auxiliares
# ============================================================

to_upper() {
    tr '[:lower:]' '[:upper:]'
}

validar_config() {
    if [[ ! -f "$HOSTS_CONFIG" ]]; then
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "CONFIG" \
            "NAO_ENCONTRADO" \
            "Arquivo de configuração não encontrado: $HOSTS_CONFIG"

        echo "Erro: arquivo de configuração não encontrado: $HOSTS_CONFIG" >&2
        exit 1
    fi
}

listar_hosts_sft() {
    # Seleciona zonas fixas relacionadas aos servidores de operação.
    # Campos esperados no inventário:
    # TIPO;NOME;IP;USUARIO;...
    awk -F';' '
        $1 == "ZONE_FIXA" {
            print $2
        }
    ' "$HOSTS_CONFIG" | sort -u
}

listar_hosts_painel() {
    # Seleciona zonas móveis relacionadas às IHMs e painéis operacionais.
    # Campos esperados no inventário:
    # TIPO;NOME;IP;USUARIO;...
    awk -F';' '
        $1 == "ZONE_MOVEL" {
            print $2
        }
    ' "$HOSTS_CONFIG" | sort -u
}

executar_ssh_check() {
    local host="$1"
    local process_regex="$2"

    ssh "${SSH_OPTS[@]}" "$host" \
        "pgrep -f \"$process_regex\" > /dev/null && echo ATIVO || echo PARADO; exit 0" \
        2>/dev/null
}

detect_sft() {
    local host="$1"
    local host_upper
    local resultado

    host_upper="$(echo "$host" | to_upper)"

    if ! resultado="$(executar_ssh_check "$host" "$SFT_PROCESS_REGEX")"; then
        echo "${host_upper};OFFLINE;0;SSH_FALHA"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "SFT_${host_upper}" \
            "OFFLINE" \
            "Falha de comunicação SSH com servidor SFT ${host}."

        return 0
    fi

    if [[ "$resultado" == "ATIVO" ]]; then
        echo "${host_upper};ATIVO;1;SFT_ATIVO"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "SFT_${host_upper}" \
            "ATIVO" \
            "Servidor SFT ${host} está ativo."
    else
        echo "${host_upper};STANDBY;0;SFT_STANDBY"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "SFT_${host_upper}" \
            "STANDBY" \
            "Servidor SFT ${host} está em standby."
    fi
}

detect_painel() {
    local host="$1"
    local host_upper
    local resultado

    host_upper="$(echo "$host" | to_upper)"

    if ! resultado="$(executar_ssh_check "$host" "$PAINEL_PROCESS_REGEX")"; then
        echo "${host_upper};OFFLINE;0;SSH_FALHA"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "PAINEL_${host_upper}" \
            "OFFLINE" \
            "Falha de comunicação SSH com host de painel ${host}."

        return 0
    fi

    if [[ "$resultado" == "ATIVO" ]]; then
        echo "${host_upper};ATIVO;1;PAINEL_ATIVO"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "PAINEL_${host_upper}" \
            "ATIVO" \
            "Aplicação de painel ativa em ${host}."
    else
        echo "${host_upper};PARADO;0;PAINEL_PARADO"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "WARNING" \
            "PAINEL_${host_upper}" \
            "PARADO" \
            "Aplicação de painel parada em ${host}."
    fi
}

coletar_sfts() {
    {
        echo "NOME;MODO;PROCESSOS;DETALHE"

        while read -r host; do
            [[ -z "$host" ]] && continue
            detect_sft "$host"
        done < <(listar_hosts_sft)
    } > "$TMP_OPERACAO"

    mv "$TMP_OPERACAO" "$OPERACAO_FILE"
}

coletar_paineis() {
    {
        echo "NOME;MODO;PROCESSOS;DETALHE"

        while read -r host; do
            [[ -z "$host" ]] && continue
            detect_painel "$host"
        done < <(listar_hosts_painel)
    } > "$TMP_PAINEL"

    mv "$TMP_PAINEL" "$PAINEL_FILE"
}

registrar_status_final() {
    local total_sft
    local total_painel

    total_sft="$(tail -n +2 "$OPERACAO_FILE" | wc -l | tr -d ' ')"
    total_painel="$(tail -n +2 "$PAINEL_FILE" | wc -l | tr -d ' ')"

    nexus_db_insert \
        "$HOSTNAME_LOCAL" \
        "$MODULO" \
        "OK" \
        "COLETA_FINALIZADA" \
        "${total_sft}_SFT_${total_painel}_PAINEL" \
        "Coleta operacional finalizada com ${total_sft} servidor(es) SFT e ${total_painel} host(s) de painel."
}

main() {
    validar_config
    coletar_sfts
    coletar_paineis
    registrar_status_final
}

main "$@"
