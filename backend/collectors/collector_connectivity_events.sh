#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# NEXUS MONITOR - Coletor de Eventos de Conectividade
#
# Objetivo:
#   Registrar evidências de desconexão/oscilação de IHMs e WS,
#   incluindo conflitos de IP/redundância vindos do operational_status.csv.
#
# Segurança:
#   - Não executa comando remoto.
#   - Não usa ping.
#   - Não altera rede.
#   - Não inicia/para serviços.
#   - Apenas lê CSVs locais e grava eventos.
# ============================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

STATUS_LDOM_FILE="${NEXUS_STATUS_LDOM_FILE:-$PROJECT_ROOT/backend/data/current/status_ldom.csv}"
OPERATIONAL_STATUS_FILE="${NEXUS_OPERATIONAL_STATUS_FILE:-$PROJECT_ROOT/backend/data/runtime/operational_status.csv}"
EVENTS_FILE="${NEXUS_EVENTS_FILE:-$PROJECT_ROOT/backend/data/events/nexus_events.csv}"
STATE_FILE="${NEXUS_CONNECTIVITY_EVENTS_STATE_FILE:-$PROJECT_ROOT/backend/data/runtime/connectivity_events.state}"

EVENTS_HEADER="TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM"

mkdir -p "$(dirname "$EVENTS_FILE")" "$(dirname "$STATE_FILE")"

if [[ ! -f "$EVENTS_FILE" ]]; then
  echo "$EVENTS_HEADER" > "$EVENTS_FILE"
fi

TMP_STATE="$(mktemp)"
trap 'rm -f "$TMP_STATE"' EXIT

declare -A PREVIOUS_STATE

if [[ -f "$STATE_FILE" ]]; then
  while IFS=';' read -r state_key state_value _rest; do
    [[ -z "${state_key:-}" ]] && continue
    PREVIOUS_STATE["$state_key"]="${state_value:-}"
  done < "$STATE_FILE"
fi

upper() {
  echo "${1:-}" | tr '[:lower:]' '[:upper:]'
}

lower() {
  echo "${1:-}" | tr '[:upper:]' '[:lower:]'
}

sanitize() {
  echo "${1:-}" | tr '\n\r;' '   ' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

map_status_to_severity() {
  local status
  status="$(upper "$1")"

  case "$status" in
    OK|ATIVO|ACTIVE|ONLINE|UP|STANDBY|RESERVA|BACKUP)
      echo "OK"
      ;;
    ALERTA|ALERT|WARN|WARNING|DEGRADED|DEGRADADO|WAIT|UNKNOWN|INDEFINIDO)
      echo "ALERTA"
      ;;
    FALHA|FAIL|FAILED|ERROR|OFFLINE|DOWN|CRIT|CRITICAL|CRITICO|CRÍTICO)
      echo "CRITICO"
      ;;
    *)
      echo "ALERTA"
      ;;
  esac
}

append_event() {
  local host="$1"
  local module="$2"
  local severity="$3"
  local metric="$4"
  local value="$5"
  local message="$6"
  local timestamp

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  printf '%s;%s;%s;%s;%s;%s;%s\n' \
    "$timestamp" \
    "$(sanitize "$host")" \
    "$(sanitize "$module")" \
    "$(sanitize "$severity")" \
    "$(sanitize "$metric")" \
    "$(sanitize "$value")" \
    "$(sanitize "$message")" \
    >> "$EVENTS_FILE"
}

record_state() {
  local key="$1"
  local host="$2"
  local module="$3"
  local severity="$4"
  local metric="$5"
  local state_value="$6"
  local event_value="$7"
  local message="$8"
  local previous

  printf '%s;%s|%s\n' "$key" "$severity" "$state_value" >> "$TMP_STATE"

  previous="${PREVIOUS_STATE[$key]-}"

  if [[ "$previous" == "$severity|$state_value" ]]; then
    return
  fi

  # Primeira execução em estado OK não gera ruído.
  if [[ -z "$previous" && "$severity" == "OK" ]]; then
    return
  fi

  append_event "$host" "$module" "$severity" "$metric" "$event_value" "$message"
}

is_ihm_host() {
  local host
  host="$(lower "$1")"

  case "$host" in
    cptm1|cptm2|cptm3|cptm4|cptm12|sme3|cons1|cons5)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_ws_host() {
  local host ldom
  host="$(lower "$1")"
  ldom="$(lower "$2")"

  [[ "$ldom" == "ws" || "$host" =~ ^ws[0-9]+$ ]]
}

process_status_ldom() {
  if [[ ! -f "$STATUS_LDOM_FILE" ]]; then
    return
  fi

  while IFS=';' read -r host ldom status uptime _rest; do
    [[ -z "${host:-}" ]] && continue
    [[ "$host" =~ ^# ]] && continue

    local host_l ldom_l status_u severity module label event_host metric value message

    host_l="$(lower "$host")"
    ldom_l="$(lower "$ldom")"
    status_u="$(upper "$status")"

    if is_ihm_host "$host_l"; then
      module="SERVICO"
      label="IHM"
      metric="CONECTIVIDADE_IHM"
    elif is_ws_host "$host_l" "$ldom_l"; then
      module="WORKSTATION"
      label="WS"
      metric="CONECTIVIDADE_WS"
    else
      continue
    fi

    severity="$(map_status_to_severity "$status_u")"
    event_host="$(upper "${host_l}_${ldom_l}")"
    value="${status_u}:UPTIME=${uptime:-N/A}"

    case "$severity" in
      OK)
        message="${label} $(upper "$host_l")/$(upper "$ldom_l") recuperou conectividade. Uptime ${uptime:-N/A}."
        ;;
      WARN)
        message="${label} $(upper "$host_l")/$(upper "$ldom_l") em alerta ou oscilacao. Uptime ${uptime:-N/A}."
        ;;
      CRIT)
        message="${label} $(upper "$host_l")/$(upper "$ldom_l") desconectada ou em falha. Uptime ${uptime:-N/A}."
        ;;
      *)
        message="${label} $(upper "$host_l")/$(upper "$ldom_l") com estado indefinido. Uptime ${uptime:-N/A}."
        ;;
    esac

    # O estado não inclui uptime para não gerar evento a cada mudança de tempo.
    record_state \
      "STATUS_LDOM|${host_l}|${ldom_l}" \
      "$event_host" \
      "$module" \
      "$severity" \
      "$metric" \
      "$status_u" \
      "$value" \
      "$message"

  done < "$STATUS_LDOM_FILE"
}

process_operational_status() {
  if [[ ! -f "$OPERATIONAL_STATUS_FILE" ]]; then
    return
  fi

  while IFS=';' read -r timestamp asset_id logical_asset_id asset_name asset_type parent_asset ldom ip_address technical_comm health_status operational_role redundancy_group redundancy_conflict message _rest; do
    [[ -z "${asset_id:-}" ]] && continue
    [[ "$asset_id" == "asset_id" ]] && continue
    [[ "$asset_id" =~ ^# ]] && continue

    local asset_type_u conflict_l logical_u ldom_u role_u health_u comm_u event_host severity state_value event_value event_message

    asset_type_u="$(upper "$asset_type")"

    if [[ "$asset_type_u" != "MOBILE_IHM" && "$asset_type_u" != "IHM" ]]; then
      continue
    fi

    conflict_l="$(lower "$redundancy_conflict")"
    logical_u="$(upper "$logical_asset_id")"
    ldom_u="$(upper "$ldom")"
    role_u="$(upper "$operational_role")"
    health_u="$(upper "$health_status")"
    comm_u="$(upper "$technical_comm")"
    event_host="$(upper "${logical_asset_id}_${ldom}")"

    if [[ "$conflict_l" == "true" || "$conflict_l" == "1" || "$conflict_l" == "sim" || "$conflict_l" == "yes" ]]; then
      severity="CRITICO"
      state_value="CONFLITO"
      event_value="${logical_u}:${ldom_u}:CONFLITO_IP"
      event_message="Conflito de IP/redundancia detectado em ${logical_u}/${ldom_u}. ${message:-Mesma IHM pode estar ativa em mais de uma LDOM.}"
    else
      severity="OK"
      state_value="SEM_CONFLITO"
      event_value="${logical_u}:${ldom_u}:SEM_CONFLITO"
      event_message="Conflito de IP/redundancia recuperado em ${logical_u}/${ldom_u}."
    fi

    record_state \
      "OP_CONFLICT|${logical_u}|${ldom_u}" \
      "$event_host" \
      "SERVICO" \
      "$severity" \
      "REDUNDANCIA_IP" \
      "$state_value" \
      "$event_value" \
      "$event_message"

    # Comunicação técnica declarada pelo operational_status.csv.
    if [[ "$comm_u" != "OK" && -n "$comm_u" ]]; then
      severity="$(map_status_to_severity "$comm_u")"
      state_value="$comm_u"
      event_value="${logical_u}:${ldom_u}:COMM=${comm_u}"
      event_message="Comunicacao tecnica da IHM ${logical_u}/${ldom_u} em estado ${comm_u}."
    else
      severity="OK"
      state_value="OK"
      event_value="${logical_u}:${ldom_u}:COMM=OK"
      event_message="Comunicacao tecnica da IHM ${logical_u}/${ldom_u} recuperada."
    fi

    record_state \
      "OP_COMM|${logical_u}|${ldom_u}" \
      "$event_host" \
      "SERVICO" \
      "$severity" \
      "COMUNICACAO_IHM" \
      "$state_value" \
      "$event_value" \
      "$event_message"

    # Papel operacional em falha/desligado também vira evidência.
    case "$role_u" in
      FALHA|FAIL|FAILED|ERROR)
        severity="CRITICO"
        state_value="$role_u"
        event_value="${logical_u}:${ldom_u}:ROLE=${role_u}:HEALTH=${health_u}"
        event_message="IHM ${logical_u}/${ldom_u} em falha operacional."
        ;;
      DESLIGADO|OFF|OFFLINE|SHUTDOWN)
        severity="ALERTA"
        state_value="$role_u"
        event_value="${logical_u}:${ldom_u}:ROLE=${role_u}:HEALTH=${health_u}"
        event_message="IHM ${logical_u}/${ldom_u} desligada ou fora de operacao."
        ;;
      *)
        severity="OK"
        state_value="OPERACIONAL"
        event_value="${logical_u}:${ldom_u}:ROLE=${role_u}:HEALTH=${health_u}"
        event_message="IHM ${logical_u}/${ldom_u} com papel operacional normalizado."
        ;;
    esac

    record_state \
      "OP_ROLE|${logical_u}|${ldom_u}" \
      "$event_host" \
      "SERVICO" \
      "$severity" \
      "PAPEL_OPERACIONAL_IHM" \
      "$state_value" \
      "$event_value" \
      "$event_message"

  done < "$OPERATIONAL_STATUS_FILE"
}

process_status_ldom
process_operational_status

mv "$TMP_STATE" "$STATE_FILE"
trap - EXIT

echo "[NEXUS][OK] eventos de conectividade atualizados: $EVENTS_FILE"
