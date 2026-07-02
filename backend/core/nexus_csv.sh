#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: nexus_csv.sh
# Descrição: Biblioteca core para manipulação padronizada de arquivos CSV.
# Autor: miyo
# Versão: 0.2.0
# Dependências: bash, coreutils, util-linux/flock
# ==============================================================================

# Evita recarregar a biblioteca mais de uma vez.
if [[ "${NEXUS_CSV_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

NEXUS_CSV_LOADED=1

# ============================================================
# Caminhos internos
# ============================================================

NEXUS_CSV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega caminhos oficiais do projeto.
source "$NEXUS_CSV_SCRIPT_DIR/nexus_paths.sh"

# Carrega logger interno.
source "$NEXUS_CSV_SCRIPT_DIR/nexus_logger.sh"

# ============================================================
# Configurações
# ============================================================

# Delimitador padrão dos arquivos CSV do Nexus.
NEXUS_CSV_DELIMITER="${NEXUS_CSV_DELIMITER:-;}"

# Lock genérico para operações CSV.
NEXUS_CSV_LOCK_FILE="${NEXUS_CSV_LOCK_FILE:-/tmp/nexus_monitor_csv.lock}"

# ============================================================
# Funções auxiliares
# ============================================================

nexus_csv_sanitize_field() {
    local value="${1:-}"
    local delimiter="${2:-$NEXUS_CSV_DELIMITER}"

    # Remove quebras de linha.
    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"

    # Evita quebrar a estrutura do CSV.
    value="${value//${delimiter}/,}"

    echo "$value"
}

nexus_csv_join_fields() {
    local delimiter="${1:-$NEXUS_CSV_DELIMITER}"
    shift || true

    local output=""
    local field
    local sanitized

    for field in "$@"; do
        sanitized="$(nexus_csv_sanitize_field "$field" "$delimiter")"

        if [[ -z "$output" ]]; then
            output="$sanitized"
        else
            output="${output}${delimiter}${sanitized}"
        fi
    done

    echo "$output"
}

nexus_csv_init_file() {
    local file_path="$1"
    local header="$2"

    local dir_path
    dir_path="$(dirname "$file_path")"

    mkdir -p "$dir_path"

    if [[ ! -f "$file_path" ]]; then
        echo "$header" > "$file_path"

        nexus_log_info \
            "NEXUS_CSV" \
            "Arquivo CSV criado: $file_path"
    fi
}

nexus_csv_append_row() {
    local file_path="$1"
    local delimiter="$2"

    shift 2 || true

    local row
    row="$(nexus_csv_join_fields "$delimiter" "$@")"

    (
        flock -x 200
        echo "$row" >> "$file_path"
    ) 200> "$NEXUS_CSV_LOCK_FILE"
}

nexus_csv_count_rows() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo 0
        return 0
    fi

    tail -n +2 "$file_path" | wc -l | tr -d ' '
}

nexus_csv_header_matches() {
    local file_path="$1"
    local expected_header="$2"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    local current_header
    current_header="$(head -n 1 "$file_path")"

    [[ "$current_header" == "$expected_header" ]]
}

nexus_csv_require_header() {
    local file_path="$1"
    local expected_header="$2"

    if nexus_csv_header_matches "$file_path" "$expected_header"; then
        return 0
    fi

    nexus_log_warn \
        "NEXUS_CSV" \
        "Cabeçalho CSV inesperado em $file_path"

    return 1
}
