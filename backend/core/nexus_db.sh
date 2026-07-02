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
# Carrega biblioteca de logs internos.
source "$NEXUS_DB_SCRIPT_DIR/nexus_logger.sh"
# Carrega biblioteca de logs internos.
source "$NEXUS_DB_SCRIPT_DIR/nexus_logger.sh"

# Carrega biblioteca de manipulação CSV.
source "$NEXUS_DB_SCRIPT_DIR/nexus_csv.sh"

# Arquivo principal de eventos:
# backend/data/events/nexus_events.csv
NEXUS_DB_FILE="$NEXUS_EVENTS_FILE"

# Arquivo de lock para escrita segura.
NEXUS_LOCK_FILE="/tmp/nexus_monitor_db.lock"

# ============================================================
# Funções internas
# ============================================================

nexus_db_init() {
    mkdir -p "$NEXUS_EVENTS_DIR"

    if [[ ! -f "$NEXUS_DB_FILE" ]]; then
        echo "$NEXUS_EVENTS_HEADER" > "$NEXUS_DB_FILE"

        nexus_log_info \
            "NEXUS_DB" \
            "Arquivo de eventos criado: $NEXUS_DB_FILE"
    fi
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

    linha_csv="$(
    nexus_csv_join_fields \
        ";" \
        "$timestamp" \
        "$host" \
        "$modulo" \
        "$status" \
        "$metrica" \
        "$valor" \
        "$mensagem"
	)"
    (
        flock -x 200
        echo "$linha_csv" >> "$NEXUS_DB_FILE"
    ) 200> "$NEXUS_LOCK_FILE"
	nexus_log_debug \
    	"NEXUS_DB" \
    	"Evento registrado: modulo=${modulo}, status=${status}, metrica=${metrica}, valor=${valor}"
}

# Inicializa automaticamente ao carregar a biblioteca.
nexus_db_init
