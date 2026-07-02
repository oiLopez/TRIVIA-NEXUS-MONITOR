#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: nexus_db.sh
# Descrição: Biblioteca core para gravação segura e padronizada de eventos em CSV.
# Autor: miyo
# Dependências: bash, coreutils, util-linux/flock
# Saída: backend/data/events/nexus_events.csv
# ==============================================================================

# Evita execução direta com variáveis indefinidas dentro das funções.
set -o nounset

# ============================================================
# Caminhos internos do NEXUS MONITOR
# ============================================================

# Diretório onde este arquivo está localizado:
# backend/core/
NEXUS_DB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega os caminhos oficiais do projeto.
source "$NEXUS_DB_SCRIPT_DIR/nexus_paths.sh"

# Arquivo principal de eventos:
# backend/data/events/nexus_events.csv
NEXUS_DB_FILE="$NEXUS_EVENTS_FILE"



# ============================================================
# Funções internas
# ============================================================

nexus_db_init() {
    mkdir -p "$NEXUS_EVENTS_DIR"

    if [[ ! -f "$NEXUS_DB_FILE" ]]; then
        echo "$NEXUS_EVENTS_HEADER" > "$NEXUS_DB_FILE"
    fi
}

nexus_db_sanitize_field() {
    local value="${1:-}"

    # Remove quebras de linha e substitui ponto e vírgula para não quebrar o CSV.
    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"
    value="${value//;/,}"

    echo "$value"
}

# ============================================================
# API pública
# ============================================================

nexus_db_insert() {
    local host="${1:-UNKNOWN_HOST}"
    local modulo="${2:-UNKNOWN_MODULE}"
    local status="${3:-UNKNOWN_STATUS}"
    local metrica="${4:-UNKNOWN_METRIC}"
    local valor="${5:-UNKNOWN_VALUE}"
    local mensagem="${6:-}"

    local timestamp
    local linha_csv

    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

    host="$(nexus_db_sanitize_field "$host")"
    modulo="$(nexus_db_sanitize_field "$modulo")"
    status="$(nexus_db_sanitize_field "$status")"
    metrica="$(nexus_db_sanitize_field "$metrica")"
    valor="$(nexus_db_sanitize_field "$valor")"
    mensagem="$(nexus_db_sanitize_field "$mensagem")"

    linha_csv="${timestamp};${host};${modulo};${status};${metrica};${valor};${mensagem}"

    (
        flock -x 200
        echo "$linha_csv" >> "$NEXUS_DB_FILE"
    ) 200> "$NEXUS_LOCK_FILE"
}

# Inicializa automaticamente ao carregar a biblioteca.
nexus_db_init
