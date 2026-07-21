#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor: collector_service_status_events.sh
#
# Objetivo:
#   Converter mudanças relevantes de service_status.csv em eventos operacionais
#   centralizados em backend/data/events/nexus_events.csv.
#
# Segurança:
#   - Não acessa remoto.
#   - Não executa start/stop.
#   - Apenas lê CSV runtime e grava eventos locais.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SERVICE_STATUS_FILE="${NEXUS_SERVICE_STATUS_FILE:-$PROJECT_ROOT/backend/data/runtime/service_status.csv}"
EVENTS_FILE="${NEXUS_EVENTS_FILE:-$PROJECT_ROOT/backend/data/events/nexus_events.csv}"
STATE_FILE="${NEXUS_SERVICE_STATUS_EVENTS_STATE:-$PROJECT_ROOT/backend/data/runtime/service_status_events.state}"

EVENTS_HEADER="TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM"
STATE_HEADER="key;technical_comm;service_status;pids"

mkdir -p "$(dirname "$EVENTS_FILE")" "$(dirname "$STATE_FILE")"

if [[ ! -f "$SERVICE_STATUS_FILE" ]]; then
  echo "[NEXUS][WARN] service_status.csv não encontrado: $SERVICE_STATUS_FILE" >&2
  exit 0
fi

if [[ ! -s "$EVENTS_FILE" ]]; then
  printf '%s\n' "$EVENTS_HEADER" > "$EVENTS_FILE"
fi

declare -A PREV_SIG
declare -A PREV_STATUS

if [[ -f "$STATE_FILE" ]]; then
  while IFS=';' read -r key technical_comm service_status pids; do
    [[ -z "${key:-}" || "$key" == "key" ]] && continue
    PREV_SIG["$key"]="${technical_comm}|${service_status}|${pids}"
    PREV_STATUS["$key"]="$service_status"
  done < "$STATE_FILE"
fi

sanitize_event_field() {
  local value="${1:-}"
  value="${value//$'\r'/ }"
  value="${value//$'\n'/ }"
  value="${value//;/,}"
  printf '%s' "$value"
}

map_event_severity() {
  local service_status="$1"

  case "$service_status" in
    DUPLICATE|ERROR)
      printf 'CRIT'
      ;;
    LOCKED|STOPPED|WAIT|UNKNOWN)
      printf 'WARN'
      ;;
    RUNNING)
      printf 'OK'
      ;;
    *)
      printf 'WARN'
      ;;
  esac
}

build_event_message() {
  local service_name="$1"
  local host_id="$2"
  local host_name="$3"
  local ldom="$4"
  local service_status="$5"
  local pids="$6"
  local message="$7"

  local service_label
  service_label="$(printf '%s' "$service_name" | tr '[:lower:]' '[:upper:]')"

  case "$service_status" in
    RUNNING)
      if [[ "$service_name" == "painel" ]]; then
        printf 'PAINEL carregado em %s/%s com PID(s) %s' "$host_name" "$ldom" "$pids"
      else
        printf '%s executado em %s/%s com PID(s) %s' "$service_label" "$host_name" "$ldom" "$pids"
      fi
      ;;
    LOCKED)
      printf '%s com instância já existente em %s/%s: %s' "$service_label" "$host_name" "$ldom" "$message"
      ;;
    DUPLICATE)
      printf '%s detectado em mais de uma máquina simultaneamente. Host atual: %s/%s' "$service_label" "$host_name" "$ldom"
      ;;
    ERROR)
      printf '%s com erro em %s/%s: %s' "$service_label" "$host_name" "$ldom" "$message"
      ;;
    STOPPED)
      if [[ "$service_name" == "painel" ]]; then
        printf 'PAINEL deixou de ser detectado em %s/%s' "$host_name" "$ldom"
      else
        printf '%s deixou de ser detectado em %s/%s' "$service_label" "$host_name" "$ldom"
      fi
      ;;
    WAIT)
      printf 'Sem evidência atual para %s em %s/%s' "$service_label" "$host_name" "$ldom"
      ;;
    *)
      printf '%s mudou para %s em %s/%s: %s' "$service_label" "$service_status" "$host_name" "$ldom" "$message"
      ;;
  esac
}

emit_event() {
  local timestamp="$1"
  local host_id="$2"
  local service_name="$3"
  local service_status="$4"
  local pids="$5"
  local message="$6"

  local severity
  local metric
  local value

  severity="$(map_event_severity "$service_status")"
  metric="$(printf '%s_STATUS' "$service_name" | tr '[:lower:]' '[:upper:]')"
  value="${service_name}:${service_status}:${host_id}:${pids}"

  timestamp="$(sanitize_event_field "$timestamp")"
  host_id="$(sanitize_event_field "$host_id")"
  service_name="$(sanitize_event_field "$service_name")"
  service_status="$(sanitize_event_field "$service_status")"
  value="$(sanitize_event_field "$value")"
  message="$(sanitize_event_field "$message")"

  printf '%s;%s;%s;%s;%s;%s;%s\n' \
    "$timestamp" \
    "$host_id" \
    "PRODIX_SERVICE" \
    "$severity" \
    "$metric" \
    "$value" \
    "$message" >> "$EVENTS_FILE"
}

is_active_like_status() {
  local service_status="$1"

  case "$service_status" in
    RUNNING|LOCKED|DUPLICATE|ERROR)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

TMP_STATE="$(mktemp)"
trap 'rm -f "${TMP_STATE:-}"' EXIT

printf '%s\n' "$STATE_HEADER" > "$TMP_STATE"

tail -n +2 "$SERVICE_STATUS_FILE" | while IFS=';' read -r \
  timestamp \
  host_id \
  host_name \
  host_type \
  ldom \
  ip_address \
  service_name \
  service_pattern \
  expected_scope \
  technical_comm \
  service_status \
  pid_count \
  pids \
  message
do
  [[ -z "${timestamp:-}" || -z "${host_id:-}" || -z "${service_name:-}" ]] && continue

  key="${service_name}|${host_id}"
  current_sig="${technical_comm}|${service_status}|${pids}"
  previous_sig="${PREV_SIG[$key]:-}"
  previous_status="${PREV_STATUS[$key]:-}"

  should_emit="false"

  if [[ "$current_sig" != "$previous_sig" ]]; then
    if is_active_like_status "$service_status"; then
      should_emit="true"
    elif [[ "$service_status" == "STOPPED" || "$service_status" == "WAIT" ]]; then
      if is_active_like_status "$previous_status"; then
        should_emit="true"
      fi
    fi
  fi

  if [[ "$should_emit" == "true" ]]; then
    event_message="$(build_event_message "$service_name" "$host_id" "$host_name" "$ldom" "$service_status" "$pids" "$message")"
    emit_event "$timestamp" "$host_id" "$service_name" "$service_status" "$pids" "$event_message"
  fi

  printf '%s;%s;%s;%s\n' "$key" "$technical_comm" "$service_status" "$pids" >> "$TMP_STATE"
done

mv "$TMP_STATE" "$STATE_FILE"
TMP_STATE=""

echo "[NEXUS] Eventos de service_status processados em: $EVENTS_FILE"
