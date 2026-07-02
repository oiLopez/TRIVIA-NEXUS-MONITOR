#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: nexus_logger.sh
# Descrição: Biblioteca core para registro padronizado de logs internos.
# Autor: miyo
# Versão: 0.2.0
# Dependências: bash, coreutils, util-linux/flock
# Saída: backend/logs/nexus.log
# ==============================================================================

# Evita recarregar a biblioteca mais de uma vez.
if [[ "${NEXUS_LOGGER_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

NEXUS_LOGGER_LOADED=1

# ============================================================
# Caminhos internos
# ============================================================

NEXUS_LOGGER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega caminhos oficiais do projeto.
source "$NEXUS_LOGGER_SCRIPT_DIR/nexus_paths.sh"

# Arquivo principal de log interno.
NEXUS_LOG_FILE="${NEXUS_LOG_FILE:-$NEXUS_LOGS_DIR/nexus.log}"

# Arquivo de lock para escrita segura.
NEXUS_LOG_LOCK_FILE="${NEXUS_LOG_LOCK_FILE:-/tmp/nexus_monitor_logger.lock}"

# Nível mínimo de log.
# Valores aceitos: DEBUG, INFO, WARN, ERROR
NEXUS_LOG_LEVEL="${NEXUS_LOG_LEVEL:-INFO}"

# ============================================================
# Funções internas
# ============================================================

nexus_logger_init() {
    mkdir -p "$NEXUS_LOGS_DIR"

    if [[ ! -f "$NEXUS_LOG_FILE" ]]; then
        touch "$NEXUS_LOG_FILE"
    fi
}

nexus_log_sanitize() {
    local value="${1:-}"

    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"

    echo "$value"
}

nexus_log_level_value() {
    local level="${1:-INFO}"

    case "$level" in
        DEBUG) echo 10 ;;
        INFO)  echo 20 ;;
        WARN)  echo 30 ;;
        ERROR) echo 40 ;;
        *)     echo 20 ;;
    esac
}

nexus_log_should_write() {
    local message_level="$1"

    local current_value
    local message_value

    current_value="$(nexus_log_level_value "$NEXUS_LOG_LEVEL")"
    message_value="$(nexus_log_level_value "$message_level")"

    [[ "$message_value" -ge "$current_value" ]]
}

nexus_log_write() {
    local level="$1"
    local module="${2:-GERAL}"
    local message="${3:-}"

    local timestamp
    local line

    level="$(nexus_log_sanitize "$level")"
    module="$(nexus_log_sanitize "$module")"
    message="$(nexus_log_sanitize "$message")"

    if ! nexus_log_should_write "$level"; then
        return 0
    fi

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    line="${timestamp} [${level}] [${module}] ${message}"

    (
        flock -x 200
        echo "$line" >> "$NEXUS_LOG_FILE"
    ) 200> "$NEXUS_LOG_LOCK_FILE"
}

# ============================================================
# API pública
# ============================================================

nexus_log_debug() {
    local module="$1"
    local message="$2"

    nexus_log_write "DEBUG" "$module" "$message"
}

nexus_log_info() {
    local module="$1"
    local message="$2"

    nexus_log_write "INFO" "$module" "$message"
}

nexus_log_warn() {
    local module="$1"
    local message="$2"

    nexus_log_write "WARN" "$module" "$message"
}

nexus_log_error() {
    local module="$1"
    local message="$2"

    nexus_log_write "ERROR" "$module" "$message"
}

# Inicializa automaticamente ao carregar a biblioteca.
nexus_logger_init
