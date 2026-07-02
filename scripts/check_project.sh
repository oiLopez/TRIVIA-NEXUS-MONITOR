#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: check_project.sh
# Descrição: Verificador geral de qualidade e integridade do projeto.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, find, xargs, coreutils
# ==============================================================================

set -euo pipefail

# ============================================================
# Caminhos internos
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# ============================================================
# Contadores
# ============================================================

ERRORS=0
WARNINGS=0

# ============================================================
# Funções auxiliares
# ============================================================

print_header() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

print_ok() {
    echo "[OK] $*"
}

print_warn() {
    echo "[WARN] $*"
    WARNINGS=$((WARNINGS + 1))
}

print_error() {
    echo "[ERROR] $*"
    ERRORS=$((ERRORS + 1))
}

check_required_dir() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        print_ok "Diretório encontrado: $dir"
    else
        print_error "Diretório obrigatório não encontrado: $dir"
    fi
}

check_required_file() {
    local file="$1"

    if [[ -f "$file" ]]; then
        print_ok "Arquivo encontrado: $file"
    else
        print_error "Arquivo obrigatório não encontrado: $file"
    fi
}

check_optional_file() {
    local file="$1"

    if [[ -f "$file" ]]; then
        print_ok "Arquivo opcional encontrado: $file"
    else
        print_warn "Arquivo opcional não encontrado: $file"
    fi
}

# ============================================================
# Validações
# ============================================================

check_directories() {
    print_header "Validando diretórios obrigatórios"

    local dirs=(
        "backend"
        "backend/collectors"
        "backend/config"
        "backend/core"
        "backend/data"
        "backend/data/current"
        "backend/data/events"
        "backend/data/history"
        "backend/data/samples"
        "backend/logs"
        "docs"
        "docs/diagrams"
        "frontend"
        "frontend/assets"
        "frontend/assets/css"
        "frontend/assets/js"
        "frontend/assets/icons"
        "frontend/assets/images"
        "frontend/modules"
        "frontend/templates"
        "scripts"
        "tests"
        "tools"
        "tools/validators"
    )

    local dir
    for dir in "${dirs[@]}"; do
        check_required_dir "$dir"
    done
}

check_files() {
    print_header "Validando arquivos obrigatórios"

    local files=(
        ".gitignore"
        "README.md"
        "CHANGELOG.md"
        "ROADMAP.md"
        "VERSION"
        "backend/config/nexus_hosts.config"
	"backend/core/nexus_paths.sh"
	"backend/core/nexus_csv.sh"
        "backend/core/nexus_db.sh"
	"backend/core/nexus_logger.sh"
        "backend/collectors/collector_alertas.sh"
        "backend/collectors/collector_operacao_auto.sh"
        "backend/collectors/collector_rede_ab.sh"
        "backend/collectors/collector_virtualizacao.sh"
        "docs/arquitetura.md"
        "docs/padroes.md"
        "docs/inventario.md"
        "tools/validators/validate_inventory.sh"
    )

    local file
    for file in "${files[@]}"; do
        check_required_file "$file"
    done

    check_optional_file "backend/data/events/nexus_events.csv"
    check_optional_file "backend/data/current/status_ldom.csv"
}

check_shell_syntax() {
    print_header "Validando sintaxe dos scripts Shell"

    if find backend tools scripts -name "*.sh" -print -quit | grep -q .; then
        if find backend tools scripts -name "*.sh" -print0 | xargs -0 bash -n; then
            print_ok "Sintaxe Shell validada com sucesso."
        else
            print_error "Erro de sintaxe encontrado em algum script Shell."
        fi
    else
        print_warn "Nenhum script Shell encontrado em backend, tools ou scripts."
    fi
}

check_inventory() {
    print_header "Validando inventário"

    if [[ ! -f "tools/validators/validate_inventory.sh" ]]; then
        print_error "Validador de inventário não encontrado."
        return 0
    fi

    if [[ -x "tools/validators/validate_inventory.sh" ]]; then
        if tools/validators/validate_inventory.sh; then
            print_ok "Inventário validado pelo validador automático."
        else
            print_error "Inventário apresentou erro(s)."
        fi
    else
        print_warn "Validador não está executável. Executando com bash."
        if bash tools/validators/validate_inventory.sh; then
            print_ok "Inventário validado pelo validador automático."
        else
            print_error "Inventário apresentou erro(s)."
        fi
    fi
}

check_csv_headers() {
    print_header "Validando cabeçalhos CSV principais"

    local events_file="backend/data/events/nexus_events.csv"
    local expected_events_header="TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM"

    if [[ -f "$events_file" ]]; then
        local current_header
        current_header="$(head -n 1 "$events_file")"

        if [[ "$current_header" == "$expected_events_header" ]]; then
            print_ok "Cabeçalho válido: $events_file"
        else
            print_warn "Cabeçalho inesperado em $events_file"
            echo "       Esperado: $expected_events_header"
            echo "       Atual:    $current_header"
        fi
    else
        print_warn "Arquivo de eventos ainda não existe: $events_file"
    fi
}

print_summary() {
    print_header "Resumo geral"

    echo "Projeto:  NEXUS MONITOR"
    echo "Raiz:     $PROJECT_ROOT"
    echo "Avisos:   $WARNINGS"
    echo "Erros:    $ERRORS"

    if (( ERRORS > 0 )); then
        echo
        echo "[FAIL] Verificação concluída com erro(s)."
        return 1
    fi

    echo
    echo "[OK] Verificação concluída com sucesso."
    return 0
}

main() {
    print_header "NEXUS MONITOR - Verificação do Projeto"

    check_directories
    check_files
    check_shell_syntax
    check_inventory
    check_csv_headers
    print_summary
}

main "$@"
