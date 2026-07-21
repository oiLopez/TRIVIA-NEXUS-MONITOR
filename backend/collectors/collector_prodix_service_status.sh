#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor: collector_prodix_service_status.sh
#
# Objetivo:
#   Gerar backend/data/runtime/service_status.csv a partir de evidências locais
#   read-only de processos Prodix.
#
# Segurança:
#   - Não acessa remoto.
#   - Não executa start/stop.
#   - Não altera processos.
#   - Apenas lê arquivos locais de evidência ps.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGETS_FILE="${NEXUS_PRODIX_TARGETS_FILE:-$PROJECT_ROOT/backend/config/prodix_ihm_targets.sample.csv}"
SERVICES_FILE="${NEXUS_PRODIX_SERVICES_FILE:-$PROJECT_ROOT/backend/config/prodix_services.local.csv}"
SERVICES_SAMPLE_FILE="$PROJECT_ROOT/backend/config/prodix_services.sample.csv"

OUTPUT_FILE="${NEXUS_SERVICE_STATUS_OUTPUT:-$PROJECT_ROOT/backend/data/runtime/service_status.csv}"
TIMESTAMP="${NEXUS_SERVICE_STATUS_TIMESTAMP:-$(date '+%Y-%m-%d %H:%M:%S')}"

EXPECTED_TARGETS_HEADER="ihm;ldom;ip_address;evidence_file"
EXPECTED_SERVICES_HEADER="service_name;display_name;service_pattern;description;expected_scope"
OUTPUT_HEADER="timestamp;host_id;host_name;host_type;ldom;ip_address;service_name;service_pattern;expected_scope;technical_comm;service_status;pid_count;pids;message"

mkdir -p "$(dirname "$OUTPUT_FILE")"

if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "[NEXUS][ERRO] Config de alvos não encontrada: $TARGETS_FILE" >&2
  exit 1
fi

targets_header="$(head -n 1 "$TARGETS_FILE")"

if [[ "$targets_header" != "$EXPECTED_TARGETS_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $TARGETS_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_TARGETS_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $targets_header" >&2
  exit 1
fi

if [[ ! -f "$SERVICES_FILE" ]]; then
  SERVICES_FILE="$SERVICES_SAMPLE_FILE"
  echo "[NEXUS][WARN] Config local de serviços não encontrada. Usando sample fictício: $SERVICES_FILE" >&2
fi

if [[ ! -f "$SERVICES_FILE" ]]; then
  echo "[NEXUS][ERRO] Config de serviços Prodix não encontrada: $SERVICES_FILE" >&2
  exit 1
fi

services_header="$(head -n 1 "$SERVICES_FILE")"

if [[ "$services_header" != "$EXPECTED_SERVICES_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $SERVICES_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_SERVICES_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $services_header" >&2
  exit 1
fi

extract_lock_pid() {
  local evidence_file="$1"

  grep -Eio 'outra instancia.*PID[[:space:]]+[0-9]+' "$evidence_file" 2>/dev/null \
    | grep -Eo '[0-9]+' \
    | head -n 1 || true
}

extract_service_pids() {
  local evidence_file="$1"
  local pattern="$2"

  awk -v pattern="$pattern" '
    BEGIN {
      IGNORECASE = 1
    }

    $0 ~ pattern && $0 !~ /grep/ && $2 ~ /^[0-9]+$/ {
      print $2
    }
  ' "$evidence_file" | sort -u
}

join_pids() {
  paste -sd',' -
}

TMP_FILE="$(mktemp)"
DUP_TMP=""
trap 'rm -f "${TMP_FILE:-}" "${DUP_TMP:-}"' EXIT

printf '%s\n' "$OUTPUT_HEADER" > "$TMP_FILE"

tail -n +2 "$TARGETS_FILE" | while IFS=';' read -r ihm ldom ip_address evidence_file; do
  [[ -z "${ihm:-}" ]] && continue

  host_id="${ihm}_${ldom}"
  host_name="$ihm"
  host_type="IHM"
  evidence_path="$PROJECT_ROOT/$evidence_file"

  while IFS=';' read -r service_name display_name service_pattern description expected_scope; do
    [[ -z "${service_name:-}" || "$service_name" == "service_name" ]] && continue

    technical_comm="WAIT"
    service_status="WAIT"
    pid_count="0"
    pids="N/A"
    message="Evidencia local nao encontrada para ${host_id}"

    if [[ -f "$evidence_path" ]]; then
      technical_comm="OK"

      lock_pid=""

      if [[ "$service_name" == "evtreport" ]]; then
        lock_pid="$(extract_lock_pid "$evidence_path")"
      fi

      if [[ -n "$lock_pid" ]]; then
        service_status="LOCKED"
        pid_count="1"
        pids="$lock_pid"
        message="Existe outra instancia em execucao de PID ${lock_pid}"
      else
        found_pids="$(extract_service_pids "$evidence_path" "$service_pattern" | join_pids || true)"

        if [[ -n "$found_pids" ]]; then
          service_status="RUNNING"
          pids="$found_pids"
          pid_count="$(printf '%s\n' "$found_pids" | awk -F',' '{ print NF }')"

          if [[ "$service_name" == "painel" ]]; then
            message="Painel operacional carregado nesta maquina"
          else
            message="Servico ${service_name} ativo nesta maquina"
          fi
        else
          service_status="STOPPED"
          pid_count="0"
          pids="N/A"

          if [[ "$service_name" == "painel" ]]; then
            message="Painel operacional nao encontrado nesta maquina"
          else
            message="Servico ${service_name} nao encontrado nesta maquina"
          fi
        fi
      fi
    fi

    printf '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n' \
      "$TIMESTAMP" \
      "$host_id" \
      "$host_name" \
      "$host_type" \
      "$ldom" \
      "$ip_address" \
      "$service_name" \
      "$service_pattern" \
      "$expected_scope" \
      "$technical_comm" \
      "$service_status" \
      "$pid_count" \
      "$pids" \
      "$message" >> "$TMP_FILE"
  done < "$SERVICES_FILE"
done

DUP_TMP="$(mktemp)"

awk -F';' '
BEGIN {
  OFS = FS
}

NR == 1 {
  print
  next
}

{
  rows[NR] = $0

  if ($11 == "RUNNING" && $9 == "SINGLE_ACTIVE") {
    running_count[$7]++
  }

  max_nr = NR
}

END {
  for (i = 2; i <= max_nr; i++) {
    split(rows[i], f, FS)

    if (f[11] == "RUNNING" && f[9] == "SINGLE_ACTIVE" && running_count[f[7]] > 1) {
      f[11] = "DUPLICATE"
      f[14] = "Servico " f[7] " encontrado em mais de uma maquina simultaneamente"
    }

    print f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9], f[10], f[11], f[12], f[13], f[14]
  }
}
' "$TMP_FILE" > "$DUP_TMP"

mv "$DUP_TMP" "$OUTPUT_FILE"
DUP_TMP=""

echo "[NEXUS] service_status.csv gerado em: $OUTPUT_FILE"
