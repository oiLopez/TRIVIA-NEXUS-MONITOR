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



check_public_repo_safety() {
    print_header "Validando segurança do repositório público"

    local validator="tools/validators/validate_public_repo_safety.sh"

    if [[ ! -f "$validator" ]]; then
        print_error "Validador não encontrado: $validator"
        return 0
    fi

    if bash "$validator"; then
        print_ok "Auditoria pública validada."
    else
        print_error "Auditoria pública apresentou erro(s)."
    fi
}


check_operational_status() {
    print_header "Validando operational_status.csv"

    local csv_file="backend/data/runtime/operational_status.csv"
    local contract_validator="tools/validators/validate_operational_status.sh"
    local conflict_validator="tools/validators/validate_operational_conflicts.sh"

    if [[ ! -f "$csv_file" ]]; then
        print_warn "Arquivo runtime não encontrado: $csv_file"
        print_warn "Validação de operational_status ignorada porque runtime é local/gerado."
        return 0
    fi

    if [[ ! -f "$contract_validator" ]]; then
        print_error "Validador não encontrado: $contract_validator"
        return 0
    fi

    if [[ ! -f "$conflict_validator" ]]; then
        print_error "Validador não encontrado: $conflict_validator"
        return 0
    fi

    if bash "$contract_validator" "$csv_file"; then
        print_ok "Contrato operational_status validado."
    else
        print_error "Contrato operational_status apresentou erro(s)."
    fi

    if bash "$conflict_validator" "$csv_file"; then
        print_ok "Conflitos operacionais validados."
    else
        print_error "Conflitos operacionais apresentaram erro(s)."
    fi
}


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
        "backend/collectors/collector_prodix_operational.sh"
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

check_status_ldom() {
    print_header "Validação do status_ldom.csv"

    local validator="tools/validators/validate_status_ldom.sh"
    local current_file="backend/data/current/status_ldom.csv"
    local sample_file="backend/data/samples/status_ldom.sample.csv"

    if [[ ! -f "$validator" ]]; then
        print_warn "Validador não encontrado: $validator"
        return 0
    fi

    if [[ -f "$current_file" ]]; then
        if bash "$validator" "$current_file"; then
            print_ok "status_ldom atual válido: $current_file"
        else
            print_error "status_ldom atual inválido: $current_file"
        fi
    else
        print_warn "Arquivo status_ldom atual ainda não existe: $current_file"
    fi

    if [[ -f "$sample_file" ]]; then
        if bash "$validator" "$sample_file" --strict; then
            print_ok "Sample status_ldom válido: $sample_file"
        else
            print_error "Sample status_ldom inválido: $sample_file"
        fi
    else
        print_warn "Sample status_ldom não encontrado: $sample_file"
    fi
}

check_events_csv() {
    print_header "Validação do nexus_events.csv"

    local validator="tools/validators/validate_events_csv.sh"
    local events_file="backend/data/events/nexus_events.csv"
    local sample_file="backend/data/samples/nexus_events.sample.csv"

    if [[ ! -f "$validator" ]]; then
        print_warn "Validador não encontrado: $validator"
        return 0
    fi

    if [[ -f "$events_file" ]]; then
        if bash "$validator" "$events_file"; then
            print_ok "Eventos atuais válidos: $events_file"
        else
            print_error "Eventos atuais inválidos: $events_file"
        fi
    else
        print_warn "Arquivo de eventos ainda não existe: $events_file"
    fi

    if [[ -f "$sample_file" ]]; then
        if bash "$validator" "$sample_file"; then
            print_ok "Sample de eventos válido: $sample_file"
        else
            print_error "Sample de eventos inválido: $sample_file"
        fi
    else
        print_warn "Sample de eventos não encontrado: $sample_file"
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
    check_status_ldom
    check_events_csv
    print_summary
}

main "$@"



check_prodix_assets_config() {
    print_header "Validando config de ativos Prodix"

    local sample_file="backend/config/prodix_assets.sample.csv"
    local local_file="backend/config/prodix_assets.local.csv"
    local validator="tools/validators/validate_prodix_assets_config.sh"

    if [[ ! -f "$validator" ]]; then
        print_error "Validador não encontrado: $validator"
        return 0
    fi

    if [[ -f "$sample_file" ]]; then
        if bash "$validator" "$sample_file"; then
            print_ok "Sample de ativos Prodix validado."
        else
            print_error "Sample de ativos Prodix apresentou erro(s)."
        fi
    else
        print_error "Sample de ativos Prodix não encontrado: $sample_file"
    fi

    if [[ -f "$local_file" ]]; then
        if bash "$validator" "$local_file"; then
            print_ok "Config local de ativos Prodix validada."
        else
            print_error "Config local de ativos Prodix apresentou erro(s)."
        fi
    else
        print_warn "Config local de ativos Prodix não encontrada; usando sample fictício."
    fi
}


check_prodix_process_snapshot() {
    print_header "Validando snapshot Prodix"

    local sample_file="backend/data/samples/prodix_process_snapshot.sample.csv"
    local runtime_file="backend/data/runtime/prodix_process_snapshot.csv"
    local validator="tools/validators/validate_prodix_process_snapshot.sh"

    if [[ ! -f "$validator" ]]; then
        print_error "Validador não encontrado: $validator"
        return 0
    fi

    if [[ -f "$sample_file" ]]; then
        if bash "$validator" "$sample_file"; then
            print_ok "Sample Prodix validado."
        else
            print_error "Sample Prodix apresentou erro(s)."
        fi
    else
        print_warn "Sample Prodix não encontrado: $sample_file"
    fi

    if [[ -f "$runtime_file" ]]; then
        if bash "$validator" "$runtime_file"; then
            print_ok "Runtime Prodix validado."
        else
            print_error "Runtime Prodix apresentou erro(s)."
        fi
    else
        print_warn "Runtime Prodix não encontrado; validação local ignorada."
    fi
}

check_operational_status
check_prodix_assets_config
check_prodix_process_snapshot
check_public_repo_safety
