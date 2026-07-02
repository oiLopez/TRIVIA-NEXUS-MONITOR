#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: collector_alertas.sh
# Descrição: Coletor responsável por consolidar alertas ativos a partir de eventos
#            e regras operacionais do NEXUS MONITOR.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, awk, grep, sort, coreutils
# Saída:
#   - backend/data/current/alertas_ativos.csv
#   - backend/data/history/alertas_historico.csv
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
EVENTS_DIR="$DATA_DIR/events"
HISTORY_DIR="$DATA_DIR/history"

EVENTS_FILE="$EVENTS_DIR/nexus_events.csv"
STATUS_LDOM_FILE="$CURRENT_DIR/status_ldom.csv"
ALERTAS_ATIVOS_FILE="$CURRENT_DIR/alertas_ativos.csv"
ALERTAS_HIST_FILE="$HISTORY_DIR/alertas_historico.csv"

mkdir -p "$CURRENT_DIR" "$EVENTS_DIR" "$HISTORY_DIR"

# Carrega biblioteca core de eventos.
source "$BACKEND_DIR/core/nexus_db.sh"

# ============================================================
# Configurações
# ============================================================

HOSTNAME_LOCAL="$(hostname)"
MODULO="ALERTAS"

ALERTAS_HEADER="TIMESTAMP;NIVEL;ORIGEM;MENSAGEM"
DATA_EXECUCAO="$(date '+%Y-%m-%d %H:%M:%S')"

# ============================================================
# Funções
# ============================================================

init_files() {
    echo "$ALERTAS_HEADER" > "$ALERTAS_ATIVOS_FILE"

    if [[ ! -f "$ALERTAS_HIST_FILE" ]]; then
        echo "$ALERTAS_HEADER" > "$ALERTAS_HIST_FILE"
    fi
}

sanitize_field() {
    local value="${1:-}"

    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"
    value="${value//;/,}"

    echo "$value"
}

registrar_alerta() {
    local nivel="$1"
    local origem="$2"
    local mensagem="$3"

    nivel="$(sanitize_field "$nivel")"
    origem="$(sanitize_field "$origem")"
    mensagem="$(sanitize_field "$mensagem")"

    echo "${DATA_EXECUCAO};${nivel};${origem};${mensagem}" >> "$ALERTAS_ATIVOS_FILE"
    echo "${DATA_EXECUCAO};${nivel};${origem};${mensagem}" >> "$ALERTAS_HIST_FILE"

    nexus_db_insert \
        "$HOSTNAME_LOCAL" \
        "$MODULO" \
        "$nivel" \
        "$origem" \
        "ATIVO" \
        "$mensagem"
}

analisar_eventos_criticos() {
    if [[ ! -f "$EVENTS_FILE" ]]; then
        registrar_alerta \
            "WARNING" \
            "EVENTOS" \
            "Arquivo de eventos não encontrado: $EVENTS_FILE"

        return 0
    fi

    # Captura eventos CRITICAL ou WARNING já existentes no barramento de eventos.
    # Formato esperado:
    # TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
    awk -F';' '
        NR > 1 && ($4 == "CRITICAL" || $4 == "WARNING") {
            print $1 ";" $3 ";" $4 ";" $5 ";" $6 ";" $7
        }
    ' "$EVENTS_FILE" | while IFS=';' read -r timestamp modulo status metrica valor mensagem; do
        [[ -z "${modulo:-}" ]] && continue

        registrar_alerta \
            "$status" \
            "${modulo}/${metrica}" \
            "${mensagem} Valor: ${valor}. Evento original: ${timestamp}."
    done
}

get_ldom() {
    local zone="$1"

    if [[ ! -f "$STATUS_LDOM_FILE" ]]; then
        return 0
    fi

    awk -F';' -v zone="$zone" '$1 == zone {print $2; exit}' "$STATUS_LDOM_FILE"
}

validar_posicao_sfts() {
    if [[ ! -f "$STATUS_LDOM_FILE" ]]; then
        registrar_alerta \
            "WARNING" \
            "VIRTUALIZACAO" \
            "Arquivo de estado das LDOMs não encontrado: $STATUS_LDOM_FILE"

        return 0
    fi

    local sft1_ldom
    local sft2_ldom

    sft1_ldom="$(get_ldom "SFT1")"
    sft2_ldom="$(get_ldom "SFT2")"

    if [[ -n "$sft1_ldom" && "$sft1_ldom" != "LDOM1" ]]; then
        registrar_alerta \
            "CRITICAL" \
            "SFT1" \
            "SFT1 deveria estar na LDOM1, mas está em ${sft1_ldom}."
    fi

    if [[ -n "$sft2_ldom" && "$sft2_ldom" != "LDOM2" ]]; then
        registrar_alerta \
            "CRITICAL" \
            "SFT2" \
            "SFT2 deveria estar na LDOM2, mas está em ${sft2_ldom}."
    fi
}

registrar_status_final() {
    local total_alertas

    total_alertas="$(tail -n +2 "$ALERTAS_ATIVOS_FILE" | wc -l | tr -d ' ')"

    if [[ "$total_alertas" -eq 0 ]]; then
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "ALERTAS_ATIVOS" \
            "0" \
            "Nenhum alerta ativo identificado."
    else
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "WARNING" \
            "ALERTAS_ATIVOS" \
            "$total_alertas" \
            "Foram identificados ${total_alertas} alerta(s) ativo(s)."
    fi
}

main() {
    init_files
    analisar_eventos_criticos
    validar_posicao_sfts
    registrar_status_final
}

main "$@"
