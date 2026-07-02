#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: validate_inventory.sh
# Descrição: Validador do inventário oficial de hosts do NEXUS MONITOR.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, awk, sort, uniq, coreutils
# Entrada: backend/config/nexus_hosts.config
# ==============================================================================

set -euo pipefail

# ============================================================
# Caminhos internos
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DEFAULT_INVENTORY_FILE="$PROJECT_ROOT/backend/config/nexus_hosts.config"
INVENTORY_FILE="${1:-$DEFAULT_INVENTORY_FILE}"

# Tipos aceitos inicialmente.
# Pode ser expandido futuramente por variável de ambiente.
ALLOWED_TYPES="${NEXUS_ALLOWED_INVENTORY_TYPES:-ILOM CONTROL LDOM ZONE_FIXA ZONE_MOVEL WS}"


# ============================================================
# Contadores
# ============================================================

TOTAL_LINES=0
DATA_LINES=0
ERRORS=0
WARNINGS=0

TMP_NAMES="$(mktemp /tmp/nexus_inventory_names.XXXXXX)"
TMP_IPS="$(mktemp /tmp/nexus_inventory_ips.XXXXXX)"

cleanup() {
    rm -f "$TMP_NAMES" "$TMP_IPS"
}

trap cleanup EXIT

# ============================================================
# Funções auxiliares
# ============================================================

print_info() {
    echo "[INFO] $*"
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

trim() {
    local value="${1:-}"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf "%s" "$value"
}

is_allowed_type() {
    local type="$1"
    local allowed_type

    for allowed_type in $ALLOWED_TYPES; do
        [[ "$type" == "$allowed_type" ]] && return 0
    done

    return 1
}

is_ipv4() {
    local ip="$1"
    local octet

    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

    for octet in "$o1" "$o2" "$o3" "$o4"; do
        [[ "$octet" =~ ^[0-9]+$ ]] || return 1
        (( octet >= 0 && octet <= 255 )) || return 1
    done

    return 0
}

validate_inventory_exists() {
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        print_error "Arquivo de inventário não encontrado: $INVENTORY_FILE"
        exit 1
    fi
}

validate_line() {
    local line_number="$1"
    local line="$2"
    local clean_line
    local field_count
    local tipo
    local nome
    local ip
    local usuario
    local restante

    clean_line="$(trim "$line")"

    # Ignora comentários e linhas vazias.
    [[ -z "$clean_line" ]] && return 0
    [[ "$clean_line" =~ ^# ]] && return 0

    DATA_LINES=$((DATA_LINES + 1))

    field_count="$(awk -F';' '{print NF}' <<< "$line")"

    if (( field_count < 4 )); then
        print_error "Linha $line_number inválida: possui menos de 4 campos obrigatórios."
        return 0
    fi

    IFS=';' read -r tipo nome ip usuario restante <<< "$line"

    tipo="$(trim "$tipo")"
    nome="$(trim "$nome")"
    ip="$(trim "$ip")"
    usuario="$(trim "$usuario")"

    if [[ -z "$tipo" ]]; then
        print_error "Linha $line_number inválida: campo TIPO vazio."
    fi

    if [[ -z "$nome" ]]; then
        print_error "Linha $line_number inválida: campo NOME vazio."
    fi

    if [[ -z "$ip" ]]; then
        print_error "Linha $line_number inválida: campo IP vazio."
    fi

    if [[ -z "$usuario" ]]; then
        print_error "Linha $line_number inválida: campo USUARIO vazio."
    fi

    if [[ -n "$tipo" ]] && ! is_allowed_type "$tipo"; then
        print_warn "Linha $line_number: tipo desconhecido '$tipo'. Tipos conhecidos: $ALLOWED_TYPES."
    fi

    if [[ -n "$ip" ]] && ! is_ipv4 "$ip"; then
        print_error "Linha $line_number inválida: IP '$ip' não parece ser IPv4 válido."
    fi

    if [[ -n "$nome" ]]; then
        echo "${nome};${line_number}" >> "$TMP_NAMES"
    fi

    if [[ -n "$ip" ]]; then
        echo "${ip};${line_number}" >> "$TMP_IPS"
    fi
}

validate_duplicates() {
    local item
    local count
    local lines

    while IFS=';' read -r item count lines; do
        [[ -z "${item:-}" ]] && continue

        print_warn "Nome repetido no inventário: '$item' aparece $count vezes. Linhas:${lines}. Verificar se representa redundância A/B ou múltiplas interfaces."
    done < <(
        awk -F';' '
            {
                count[$1]++
                lines[$1] = lines[$1] " " $2
            }
            END {
                for (item in count) {
                    if (count[item] > 1) {
                        print item ";" count[item] ";" lines[item]
                    }
                }
            }
        ' "$TMP_NAMES"
    )

    while IFS=';' read -r item count lines; do
        [[ -z "${item:-}" ]] && continue

        print_warn "IP duplicado no inventário: '$item' aparece $count vezes. Linhas:${lines}"
    done < <(
        awk -F';' '
            {
                count[$1]++
                lines[$1] = lines[$1] " " $2
            }
            END {
                for (item in count) {
                    if (count[item] > 1) {
                        print item ";" count[item] ";" lines[item]
                    }
                }
            }
        ' "$TMP_IPS"
    )
}

print_summary() {
    echo
    echo "============================================================"
    echo "Resumo da validação do inventário"
    echo "============================================================"
    echo "Arquivo:        $INVENTORY_FILE"
    echo "Linhas totais:  $TOTAL_LINES"
    echo "Linhas de dados:$DATA_LINES"
    echo "Avisos:         $WARNINGS"
    echo "Erros:          $ERRORS"
    echo "============================================================"

    if (( ERRORS > 0 )); then
        echo "[FAIL] Inventário possui erro(s) e precisa ser corrigido."
        return 1
    fi

    echo "[OK] Inventário validado com sucesso."
    return 0
}

main() {
    local line

    validate_inventory_exists

    print_info "Validando inventário: $INVENTORY_FILE"

    while IFS= read -r line || [[ -n "$line" ]]; do
        TOTAL_LINES=$((TOTAL_LINES + 1))
        validate_line "$TOTAL_LINES" "$line"
    done < "$INVENTORY_FILE"

    validate_duplicates
    print_summary
}

main "$@"
