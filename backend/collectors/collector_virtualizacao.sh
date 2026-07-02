#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: collector_virtualizacao.sh
# Descrição: Coletor de estado das Zones Solaris distribuídas entre LDOM1 e LDOM2.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, ssh, grep, awk, sort, coreutils
# Saída:
#   - backend/data/current/status_ldom.csv
#   - backend/data/history/historico_migracoes.csv
#   - backend/data/events/nexus_events.csv
# ==============================================================================

set -euo pipefail

# ============================================================
# Caminhos internos
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DATA_DIR="$BACKEND_DIR/data"
CURRENT_DIR="$DATA_DIR/current"
HISTORY_DIR="$DATA_DIR/history"

ARQ_ATUAL="$CURRENT_DIR/status_ldom.csv"
ARQ_HIST="$HISTORY_DIR/historico_migracoes.csv"

TMP1="$(mktemp /tmp/nexus_ldom1.XXXXXX)"
TMP2="$(mktemp /tmp/nexus_ldom2.XXXXXX)"
NOVO_RAW="$(mktemp /tmp/nexus_estado_raw.XXXXXX)"
NOVO="$(mktemp "$CURRENT_DIR/status_ldom.XXXXXX")"

mkdir -p "$CURRENT_DIR" "$HISTORY_DIR"

# Carrega biblioteca core de eventos.
source "$BACKEND_DIR/core/nexus_db.sh"

# Remove arquivos temporários ao finalizar.
cleanup() {
    rm -f "$TMP1" "$TMP2" "$NOVO_RAW" "$NOVO"
}

trap cleanup EXIT

# ============================================================
# Configurações do coletor
# ============================================================

HOSTNAME_LOCAL="$(hostname)"
MODULO="VIRTUALIZACAO"

CONTROL_DOMAIN_1="root@192.0.2.31"
CONTROL_DOMAIN_2="root@192.0.2.33"

LDOM_1="LDOM1"
LDOM_2="LDOM2"

SSH_OPTS=(
    -n
    -x
    -q
    -o LogLevel=ERROR
    -o Tunnel=no
    -o ForwardX11=no
    -o ClearAllForwardings=yes
    -o ConnectTimeout=8
)

ZONES_MONITORADAS_REGEX="SFT1|SFT1B|SFT2|SFT2B|METROSP44|METROSP44B|METROSP45|METROSP45B|SME3|SME3B|CONS1|CONS1B|CONS5|CONS5B|CPTM1|CPTM1B|CPTM2|CPTM2B|CPTM3|CPTM3B|CPTM4|CPTM4B|CPTM12|CPTM12B"

# ============================================================
# Funções
# ============================================================

init_history_file() {
    if [[ ! -f "$ARQ_HIST" ]]; then
        echo "TIMESTAMP;ZONE;LDOM_ANTERIOR;LDOM_ATUAL;MENSAGEM" > "$ARQ_HIST"
    fi
}

collect_zones_from_domain() {
    local control_domain="$1"
    local ldom_name="$2"
    local output_file="$3"

    if ssh "${SSH_OPTS[@]}" "$control_domain" "zoneadm list -cv" > "$output_file" 2>/dev/null; then
        grep "running" "$output_file" \
            | awk -v ldom="$ldom_name" '{print toupper($2) ";" ldom}'
    else
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "SSH_${ldom_name}" \
            "DOWN" \
            "Falha de comunicação SSH com ${control_domain}."

        return 1
    fi
}

get_ldom_from_file() {
    local zone_name="$1"
    local file_path="$2"

    awk -F';' -v zone="$zone_name" '$1 == zone {print $2; exit}' "$file_path"
}

register_changes() {
    local timestamp
    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

    # Se o arquivo atual ainda não existe, registra o primeiro estado como baseline.
    if [[ ! -f "$ARQ_ATUAL" ]]; then
        cp "$NOVO" "$ARQ_ATUAL"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "BASELINE" \
            "CRIADO" \
            "Estado inicial de virtualização criado."

        return 0
    fi

    # Se não houve alteração, apenas registra coleta OK.
    if cmp -s "$ARQ_ATUAL" "$NOVO"; then
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "STATUS_LDOM" \
            "SEM_ALTERACAO" \
            "Nenhuma alteração de virtualização detectada."

        return 0
    fi

    # Registra diferenças entre estado anterior e estado novo.
    awk -F';' '{print $1}' "$ARQ_ATUAL" "$NOVO" | sort -u | while read -r zone_name; do
        [[ -z "$zone_name" ]] && continue

        local old_ldom
        local new_ldom
        local mensagem

        old_ldom="$(get_ldom_from_file "$zone_name" "$ARQ_ATUAL")"
        new_ldom="$(get_ldom_from_file "$zone_name" "$NOVO")"

        [[ "$old_ldom" == "$new_ldom" ]] && continue

        [[ -z "$old_ldom" ]] && old_ldom="NOVO"
        [[ -z "$new_ldom" ]] && new_ldom="REMOVIDO"

        mensagem="Zone ${zone_name} alterada de ${old_ldom} para ${new_ldom}."

        echo "${timestamp};${zone_name};${old_ldom};${new_ldom};${mensagem}" >> "$ARQ_HIST"

        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "WARNING" \
            "MIGRACAO_${zone_name}" \
            "${old_ldom}_PARA_${new_ldom}" \
            "$mensagem"
    done

    # Atualiza o estado atual somente depois de registrar as alterações.
    mv "$NOVO" "$ARQ_ATUAL"

    nexus_db_insert \
        "$HOSTNAME_LOCAL" \
        "$MODULO" \
        "OK" \
        "STATUS_LDOM" \
        "ATUALIZADO" \
        "Estado atual de virtualização atualizado."
}

main() {
    init_history_file

    {
        collect_zones_from_domain "$CONTROL_DOMAIN_1" "$LDOM_1" "$TMP1" || true
        collect_zones_from_domain "$CONTROL_DOMAIN_2" "$LDOM_2" "$TMP2" || true
    } > "$NOVO_RAW"

    grep -E "$ZONES_MONITORADAS_REGEX" "$NOVO_RAW" | sort -u > "$NOVO" || true

    if [[ ! -s "$NOVO" ]]; then
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "STATUS_LDOM" \
            "SEM_DADOS" \
            "Nenhuma zone monitorada foi coletada. O estado atual não foi alterado."

        exit 1
    fi

    register_changes
}

main "$@"
