#!/usr/bin/env bash
# ==========================================================
# NEXUS MONITOR - Validador do nexus_events.csv
#
# Valida o contrato CSV de eventos operacionais:
#   TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
#
# Uso:
#   bash tools/validators/validate_events_csv.sh
#   bash tools/validators/validate_events_csv.sh backend/data/events/nexus_events.csv
#   bash tools/validators/validate_events_csv.sh backend/data/samples/nexus_events.sample.csv
# ==========================================================

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEFAULT_FILE="${PROJECT_ROOT}/backend/data/events/nexus_events.csv"
TARGET_FILE="${DEFAULT_FILE}"

EXPECTED_HEADER="TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM"

ERRORS=0
WARNINGS=0
VALID_ROWS=0

usage() {
  cat <<EOF
NEXUS MONITOR - Validador do nexus_events.csv

Uso:
  bash tools/validators/validate_events_csv.sh [arquivo]

Exemplos:
  bash tools/validators/validate_events_csv.sh
  bash tools/validators/validate_events_csv.sh backend/data/events/nexus_events.csv
  bash tools/validators/validate_events_csv.sh backend/data/samples/nexus_events.sample.csv
EOF
}

for arg in "$@"; do
  case "${arg}" in
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

is_allowed_status() {
  local status="$1"

  case "${status}" in
    OK|INFO|ALERTA|ALERT|WARN|WARNING|CRITICO|CRÍTICO|CRITICAL|FALHA|OFFLINE|DOWN|UP|ONLINE|RECUPERADO)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_allowed_module() {
  local module="$1"

  case "${module}" in
    SISTEMA|HARDWARE|VIRTUALIZACAO|VIRTUALIZAÇÃO|SERVICO|SERVIÇO|WORKSTATION|REDE|COLETOR|INVENTARIO|INVENTÁRIO|FRONTEND|BACKEND)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_valid_timestamp() {
  local timestamp="$1"

  [[ "${timestamp}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]
}

if [[ ! -f "${TARGET_FILE}" ]]; then
  error "Arquivo não encontrado: ${TARGET_FILE}"
  exit 1
fi

info "Validando arquivo: ${TARGET_FILE}"

header_found=0
line_number=0

while IFS= read -r line || [[ -n "${line}" ]]; do
  line_number=$((line_number + 1))

  line="$(trim "${line}")"

  # Ignora linhas vazias e comentários antes/depois do cabeçalho.
  if [[ -z "${line}" || "${line}" == \#* ]]; then
    continue
  fi

  if [[ "${header_found}" -eq 0 ]]; then
    if [[ "${line}" == "${EXPECTED_HEADER}" ]]; then
      header_found=1
      continue
    fi

    error "Linha ${line_number}: cabeçalho inválido."
    echo "       Esperado: ${EXPECTED_HEADER}" >&2
    echo "       Atual:    ${line}" >&2
    continue
  fi

  semicolons="${line//[^;]/}"

  if [[ "${#semicolons}" -ne 6 ]]; then
    error "Linha ${line_number}: quantidade inválida de colunas. Esperado: 7 colunas separadas por ';'. Linha: ${line}"
    continue
  fi

  IFS=';' read -r timestamp hostname module status metric value message <<< "${line}"

  timestamp="$(trim "${timestamp}")"
  hostname="$(trim "${hostname}")"
  module="$(trim "${module}")"
  status="$(trim "${status}")"
  metric="$(trim "${metric}")"
  value="$(trim "${value}")"
  message="$(trim "${message}")"

  module="${module^^}"
  status="${status^^}"

  if [[ -z "${timestamp}" ]]; then
    error "Linha ${line_number}: TIMESTAMP vazio."
    continue
  fi

  if ! is_valid_timestamp "${timestamp}"; then
    error "Linha ${line_number}: TIMESTAMP inválido '${timestamp}'. Formato esperado: YYYY-MM-DD HH:MM:SS."
    continue
  fi

  if [[ -z "${hostname}" ]]; then
    error "Linha ${line_number}: HOSTNAME vazio."
    continue
  fi

  if [[ "${hostname}" =~ [[:space:]] ]]; then
    error "Linha ${line_number}: HOSTNAME não pode conter espaços: '${hostname}'."
    continue
  fi

  if [[ -z "${module}" ]]; then
    error "Linha ${line_number}: MODULO vazio para hostname '${hostname}'."
    continue
  fi

  if ! is_allowed_module "${module}"; then
    warn "Linha ${line_number}: MODULO não padronizado '${module}'."
  fi

  if [[ -z "${status}" ]]; then
    error "Linha ${line_number}: STATUS vazio para hostname '${hostname}'."
    continue
  fi

  if ! is_allowed_status "${status}"; then
    error "Linha ${line_number}: STATUS inválido '${status}' para hostname '${hostname}'."
    continue
  fi

  if [[ -z "${metric}" ]]; then
    error "Linha ${line_number}: METRICA vazia para hostname '${hostname}'."
    continue
  fi

  if [[ -z "${value}" ]]; then
    error "Linha ${line_number}: VALOR vazio para hostname '${hostname}'. Use '-' quando desconhecido."
    continue
  fi

  if [[ -z "${message}" ]]; then
    error "Linha ${line_number}: MENSAGEM vazia para hostname '${hostname}'."
    continue
  fi

  VALID_ROWS=$((VALID_ROWS + 1))
done < "${TARGET_FILE}"

if [[ "${header_found}" -eq 0 ]]; then
  error "Cabeçalho oficial não encontrado: ${EXPECTED_HEADER}"
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
