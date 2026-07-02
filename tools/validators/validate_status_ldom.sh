#!/usr/bin/env bash
# ==========================================================
# NEXUS MONITOR - Validador do status_ldom.csv
#
# Valida o contrato CSV consumido pelo frontend:
#   hostname;ldom;status;uptime
#
# Uso:
#   bash tools/validators/validate_status_ldom.sh
#   bash tools/validators/validate_status_ldom.sh backend/data/current/status_ldom.csv
#   bash tools/validators/validate_status_ldom.sh backend/data/samples/status_ldom.sample.csv --strict
#
# Modo strict:
#   Além de validar formato e valores, exige que todos os itens
#   esperados pelo dashboard estejam presentes.
# ==========================================================

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEFAULT_FILE="${PROJECT_ROOT}/backend/data/current/status_ldom.csv"
TARGET_FILE="${DEFAULT_FILE}"
STRICT_MODE=0

ERRORS=0
WARNINGS=0
VALID_ROWS=0

usage() {
  cat <<EOF
NEXUS MONITOR - Validador do status_ldom.csv

Uso:
  bash tools/validators/validate_status_ldom.sh [arquivo] [--strict]

Exemplos:
  bash tools/validators/validate_status_ldom.sh
  bash tools/validators/validate_status_ldom.sh backend/data/current/status_ldom.csv
  bash tools/validators/validate_status_ldom.sh backend/data/samples/status_ldom.sample.csv --strict
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --strict)
      STRICT_MODE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      TARGET_FILE="${arg}"
      ;;
  esac
done

if [[ "${TARGET_FILE}" != /* ]]; then
  TARGET_FILE="${PROJECT_ROOT}/${TARGET_FILE}"
fi

info() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
  WARNINGS=$((WARNINGS + 1))
}

error() {
  echo "[ERRO] $*" >&2
  ERRORS=$((ERRORS + 1))
}

trim() {
  local value="$*"

  value="${value//$'\r'/}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "${value}"
}

is_allowed_ldom() {
  local ldom="$1"

  case "${ldom}" in
    infra|ws|ldom1|ldom2)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_allowed_status() {
  local status="$1"

  case "${status}" in
    OK|ATIVO|ONLINE|UP|STANDBY|RESERVA|BACKUP|ALERTA|ALERT|WARN|WARNING|DEGRADED|DEGRADADO|OFFLINE|FALHA|DOWN|CRITICAL|CRITICO|CRÍTICO|WAIT)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

declare -A EXPECTED_PAIRS
declare -A SEEN_PAIRS

add_expected_pair() {
  local hostname="$1"
  local ldom="$2"

  EXPECTED_PAIRS["${hostname}|${ldom}"]=1
}

# Infraestrutura principal
add_expected_pair "ilom1" "infra"
add_expected_pair "control1" "infra"
add_expected_pair "ldom1" "infra"

add_expected_pair "ilom2" "infra"
add_expected_pair "control2" "infra"
add_expected_pair "ldom2" "infra"

# Servidores fixos
add_expected_pair "sft1" "ldom1"
add_expected_pair "metrosp44" "ldom1"

add_expected_pair "sft2" "ldom2"
add_expected_pair "metrosp45" "ldom2"

# Consoles móveis na LDOM 1
add_expected_pair "cptm1" "ldom1"
add_expected_pair "cptm2" "ldom1"
add_expected_pair "cptm3" "ldom1"
add_expected_pair "cptm4" "ldom1"
add_expected_pair "sme3" "ldom1"
add_expected_pair "cons1" "ldom1"
add_expected_pair "cons5" "ldom1"
add_expected_pair "cptm12" "ldom1"

# Consoles móveis na LDOM 2
add_expected_pair "cptm1" "ldom2"
add_expected_pair "cptm2" "ldom2"
add_expected_pair "cptm3" "ldom2"
add_expected_pair "cptm4" "ldom2"
add_expected_pair "sme3" "ldom2"
add_expected_pair "cons1" "ldom2"
add_expected_pair "cons5" "ldom2"
add_expected_pair "cptm12" "ldom2"

# Workstations físicas
add_expected_pair "ws11" "ws"
add_expected_pair "ws12" "ws"
add_expected_pair "ws13" "ws"
add_expected_pair "ws21" "ws"
add_expected_pair "ws22" "ws"
add_expected_pair "ws23" "ws"
add_expected_pair "ws24" "ws"
add_expected_pair "ws25" "ws"

if [[ ! -f "${TARGET_FILE}" ]]; then
  error "Arquivo não encontrado: ${TARGET_FILE}"
  exit 1
fi

info "Validando arquivo: ${TARGET_FILE}"

line_number=0

while IFS= read -r line || [[ -n "${line}" ]]; do
  line_number=$((line_number + 1))

  line="$(trim "${line}")"

  # Ignora linhas vazias e comentários.
  if [[ -z "${line}" || "${line}" == \#* ]]; then
    continue
  fi

  # Ignora cabeçalho.
  if [[ "${line,,}" == "hostname;ldom;status;uptime" ]]; then
    continue
  fi

  semicolons="${line//[^;]/}"

  if [[ "${#semicolons}" -ne 3 ]]; then
    error "Linha ${line_number}: quantidade inválida de colunas. Esperado: 4 colunas separadas por ';'. Linha: ${line}"
    continue
  fi

  IFS=';' read -r hostname ldom status uptime <<< "${line}"

  hostname="$(trim "${hostname}")"
  ldom="$(trim "${ldom}")"
  status="$(trim "${status}")"
  uptime="$(trim "${uptime}")"

  hostname="${hostname,,}"
  ldom="${ldom,,}"
  status="${status^^}"

  if [[ -z "${hostname}" ]]; then
    error "Linha ${line_number}: hostname vazio."
    continue
  fi

  if [[ -z "${ldom}" ]]; then
    error "Linha ${line_number}: ldom vazio para hostname '${hostname}'."
    continue
  fi

  if [[ -z "${status}" ]]; then
    error "Linha ${line_number}: status vazio para '${hostname};${ldom}'."
    continue
  fi

  if [[ -z "${uptime}" ]]; then
    error "Linha ${line_number}: uptime vazio para '${hostname};${ldom}'. Use '-' quando desconhecido."
    continue
  fi

  if [[ "${hostname}" =~ [[:space:]] ]]; then
    error "Linha ${line_number}: hostname não pode conter espaços: '${hostname}'."
    continue
  fi

  if [[ "${ldom}" =~ [[:space:]] ]]; then
    error "Linha ${line_number}: ldom não pode conter espaços: '${ldom}'."
    continue
  fi

  if ! is_allowed_ldom "${ldom}"; then
    error "Linha ${line_number}: ldom inválido '${ldom}' para hostname '${hostname}'. Valores aceitos: infra, ws, ldom1, ldom2."
    continue
  fi

  if ! is_allowed_status "${status}"; then
    error "Linha ${line_number}: status inválido '${status}' para '${hostname};${ldom}'."
    continue
  fi

  pair_key="${hostname}|${ldom}"

  if [[ -n "${SEEN_PAIRS[${pair_key}]+x}" ]]; then
    error "Linha ${line_number}: par duplicado '${hostname};${ldom}'."
    continue
  fi

  SEEN_PAIRS["${pair_key}"]=1

  if [[ -z "${EXPECTED_PAIRS[${pair_key}]+x}" ]]; then
    error "Linha ${line_number}: par '${hostname};${ldom}' não existe no dashboard atual."
    continue
  fi

  VALID_ROWS=$((VALID_ROWS + 1))
done < "${TARGET_FILE}"

if [[ "${STRICT_MODE}" -eq 1 ]]; then
  for expected_key in "${!EXPECTED_PAIRS[@]}"; do
    if [[ -z "${SEEN_PAIRS[${expected_key}]+x}" ]]; then
      error "Modo strict: item esperado ausente no CSV: ${expected_key/|/;}"
    fi
  done
fi

echo
info "Linhas válidas: ${VALID_ROWS}"
info "Avisos: ${WARNINGS}"
info "Erros: ${ERRORS}"

if [[ "${ERRORS}" -ne 0 ]]; then
  echo
  echo "Resultado: FALHA"
  exit 1
fi

echo
echo "Resultado: OK"
exit 0
