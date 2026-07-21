#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/data/samples/service_status.sample.csv}"

EXPECTED_HEADER="timestamp;host_id;host_name;host_type;ldom;ip_address;service_name;service_pattern;technical_comm;service_status;pid_count;pids;message"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[NEXUS][ERRO] Arquivo não encontrado: $CSV_FILE" >&2
  exit 1
fi

header="$(head -n 1 "$CSV_FILE")"

if [[ "$header" != "$EXPECTED_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $CSV_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $header" >&2
  exit 1
fi

awk -F';' '
BEGIN {
  errors = 0
}

NR == 1 {
  next
}

NF != 13 {
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 13: %s\n", NR, NF, $0) > "/dev/stderr"
  errors++
  next
}

{
  timestamp = $1
  host_id = $2
  host_name = $3
  host_type = $4
  ldom = $5
  ip_address = $6
  service_name = $7
  service_pattern = $8
  technical_comm = $9
  service_status = $10
  pid_count = $11
  pids = $12
  message = $13

  if (timestamp == "" || host_id == "" || host_name == "" || service_name == "" || service_pattern == "" || message == "") {
    printf("[NEXUS][ERRO] Linha %d: campos obrigatórios vazios\n", NR) > "/dev/stderr"
    errors++
  }

  if (host_type !~ /^(IHM|FIXED_SERVER|LDOM|CONTROL_DOMAIN|ILOM|WS|UNKNOWN)$/) {
    printf("[NEXUS][ERRO] Linha %d: host_type inválido: %s\n", NR, host_type) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2|N\/A)$/) {
    printf("[NEXUS][ERRO] Linha %d: ldom inválido: %s\n", NR, ldom) > "/dev/stderr"
    errors++
  }

  if (technical_comm !~ /^(OK|WARN|CRIT|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: technical_comm inválido: %s\n", NR, technical_comm) > "/dev/stderr"
    errors++
  }

  if (service_status !~ /^(RUNNING|STOPPED|UNKNOWN|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: service_status inválido: %s\n", NR, service_status) > "/dev/stderr"
    errors++
  }

  if (pid_count !~ /^[0-9]+$/) {
    printf("[NEXUS][ERRO] Linha %d: pid_count inválido: %s\n", NR, pid_count) > "/dev/stderr"
    errors++
  }

  if (service_status == "RUNNING" && pid_count == "0") {
    printf("[NEXUS][ERRO] Linha %d: RUNNING com pid_count=0\n", NR) > "/dev/stderr"
    errors++
  }

  if (service_status == "STOPPED" && pid_count != "0") {
    printf("[NEXUS][ERRO] Linha %d: STOPPED com pid_count diferente de 0: %s\n", NR, pid_count) > "/dev/stderr"
    errors++
  }

  if (pid_count == "0" && pids != "N/A") {
    printf("[NEXUS][ERRO] Linha %d: pid_count=0 deve usar pids=N/A\n", NR) > "/dev/stderr"
    errors++
  }

  if (pid_count != "0" && pids !~ /^[0-9]+(,[0-9]+)*$/) {
    printf("[NEXUS][ERRO] Linha %d: pids inválido: %s\n", NR, pids) > "/dev/stderr"
    errors++
  }
}

END {
  if (errors > 0) {
    printf("[NEXUS][ERRO] Validação de service_status falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] service_status válido\n")
}
' "$CSV_FILE"
