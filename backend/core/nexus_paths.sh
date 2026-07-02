#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: nexus_paths.sh
# Descrição: Biblioteca core responsável por definir caminhos oficiais do projeto.
# Autor: miyo
# Versão: 0.2.0
# Dependências: bash, coreutils
# ==============================================================================

# Evita redefinir os caminhos caso a biblioteca seja carregada mais de uma vez.
if [[ "${NEXUS_PATHS_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

NEXUS_PATHS_LOADED=1

# ============================================================
# Diretórios principais
# ============================================================

# Diretório deste arquivo:
# backend/core/
NEXUS_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diretório backend:
# backend/
NEXUS_BACKEND_DIR="$(cd "$NEXUS_CORE_DIR/.." && pwd)"

# Raiz do projeto:
# nexus-monitor/
NEXUS_PROJECT_ROOT="$(cd "$NEXUS_BACKEND_DIR/.." && pwd)"

# ============================================================
# Diretórios oficiais
# ============================================================

NEXUS_FRONTEND_DIR="$NEXUS_PROJECT_ROOT/frontend"
NEXUS_DOCS_DIR="$NEXUS_PROJECT_ROOT/docs"
NEXUS_SCRIPTS_DIR="$NEXUS_PROJECT_ROOT/scripts"
NEXUS_TESTS_DIR="$NEXUS_PROJECT_ROOT/tests"
NEXUS_TOOLS_DIR="$NEXUS_PROJECT_ROOT/tools"

NEXUS_CONFIG_DIR="$NEXUS_BACKEND_DIR/config"
NEXUS_COLLECTORS_DIR="$NEXUS_BACKEND_DIR/collectors"
NEXUS_DATA_DIR="$NEXUS_BACKEND_DIR/data"
NEXUS_LOGS_DIR="$NEXUS_BACKEND_DIR/logs"

NEXUS_CURRENT_DIR="$NEXUS_DATA_DIR/current"
NEXUS_EVENTS_DIR="$NEXUS_DATA_DIR/events"
NEXUS_HISTORY_DIR="$NEXUS_DATA_DIR/history"
NEXUS_SAMPLES_DIR="$NEXUS_DATA_DIR/samples"

# ============================================================
# Arquivos oficiais
# ============================================================

NEXUS_HOSTS_CONFIG="$NEXUS_CONFIG_DIR/nexus_hosts.config"

NEXUS_EVENTS_FILE="$NEXUS_EVENTS_DIR/nexus_events.csv"
NEXUS_STATUS_LDOM_FILE="$NEXUS_CURRENT_DIR/status_ldom.csv"
NEXUS_ALERTS_ACTIVE_FILE="$NEXUS_CURRENT_DIR/alertas_ativos.csv"
NEXUS_ALERTS_HISTORY_FILE="$NEXUS_HISTORY_DIR/alertas_historico.csv"

NEXUS_OPERATION_FILE="$NEXUS_CURRENT_DIR/operacao_servidores.csv"
NEXUS_PANEL_FILE="$NEXUS_CURRENT_DIR/painel_sinotico.csv"
NEXUS_MIGRATION_HISTORY_FILE="$NEXUS_HISTORY_DIR/historico_migracoes.csv"

# ============================================================
# Funções auxiliares
# ============================================================

nexus_paths_init_dirs() {
    mkdir -p \
        "$NEXUS_CONFIG_DIR" \
        "$NEXUS_COLLECTORS_DIR" \
        "$NEXUS_DATA_DIR" \
        "$NEXUS_CURRENT_DIR" \
        "$NEXUS_EVENTS_DIR" \
        "$NEXUS_HISTORY_DIR" \
        "$NEXUS_SAMPLES_DIR" \
        "$NEXUS_LOGS_DIR"
}

nexus_paths_print() {
    echo "NEXUS_PROJECT_ROOT=$NEXUS_PROJECT_ROOT"
    echo "NEXUS_BACKEND_DIR=$NEXUS_BACKEND_DIR"
    echo "NEXUS_CORE_DIR=$NEXUS_CORE_DIR"
    echo "NEXUS_CONFIG_DIR=$NEXUS_CONFIG_DIR"
    echo "NEXUS_DATA_DIR=$NEXUS_DATA_DIR"
    echo "NEXUS_CURRENT_DIR=$NEXUS_CURRENT_DIR"
    echo "NEXUS_EVENTS_DIR=$NEXUS_EVENTS_DIR"
    echo "NEXUS_HISTORY_DIR=$NEXUS_HISTORY_DIR"
    echo "NEXUS_HOSTS_CONFIG=$NEXUS_HOSTS_CONFIG"
    echo "NEXUS_EVENTS_FILE=$NEXUS_EVENTS_FILE"
}
