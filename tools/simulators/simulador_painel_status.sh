#!/usr/bin/env bash
set -euo pipefail

# NEXUS MONITOR - Simulador PAINEL por VM
# Cenário normal:
#   PAINEL ON  -> CPTM2 / LDOM1
#   PAINEL ON  -> CPTM4 / LDOM2
#   PAINEL OFF -> demais 14 instâncias

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGETS_FILE="$ROOT_DIR/backend/config/prodix_ihm_targets.sample.csv"
SERVICES_FILE="${NEXUS_PRODIX_SERVICES_FILE:-$ROOT_DIR/backend/config/prodix_services.local.csv}"
SERVICES_SAMPLE="$ROOT_DIR/backend/config/prodix_services.sample.csv"
PS_DIR="$ROOT_DIR/backend/data/runtime/prodix_ps"
COLLECTOR="$ROOT_DIR/backend/collectors/collector_prodix_service_status.sh"

mkdir -p "$PS_DIR"

if [[ ! -x "$COLLECTOR" ]]; then
  echo "[NEXUS][ERRO] Collector não executável: $COLLECTOR" >&2
  exit 1
fi

if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "[NEXUS][ERRO] Targets não encontrados: $TARGETS_FILE" >&2
  exit 1
fi

if [[ ! -f "$SERVICES_FILE" ]]; then
  SERVICES_FILE="$SERVICES_SAMPLE"
fi

if [[ ! -f "$SERVICES_FILE" ]]; then
  echo "[NEXUS][ERRO] Config de serviços não encontrada." >&2
  exit 1
fi

if ! awk -F';' 'tolower($1)=="painel" { found=1 } END { exit !found }' "$SERVICES_FILE"; then
  echo "[NEXUS][ERRO] Serviço painel não encontrado em: $SERVICES_FILE" >&2
  exit 1
fi

write_evidence() {
  local ihm="$1"
  local ldom="$2"
  local state="$3"
  local file="$PS_DIR/${ihm}_${ldom}.ps"

  {
    echo "UID        PID  PPID  C STIME TTY          TIME CMD"
    echo "prodix    2100     1  0 17:00 ?        00:00:01 sb_recebe"
    echo "prodix    2101     1  0 17:00 ?        00:00:01 ma"
    echo "prodix    2102     1  0 17:00 ?        00:00:01 sb_watdog"

    if [[ "$state" == "ON" ]]; then
      echo "prodix    4201     1  0 17:00 ?        00:00:03 painelcon"
    fi
  } > "$file"
}

while IFS=';' read -r ihm ldom ip evidence_file; do
  [[ "$ihm" == "ihm" || -z "$ihm" ]] && continue
  write_evidence "$ihm" "$ldom" "OFF"
done < "$TARGETS_FILE"

write_evidence "CPTM2" "LDOM1" "ON"
write_evidence "CPTM4" "LDOM2" "ON"

NEXUS_PRODIX_TARGETS_FILE="$TARGETS_FILE" \
NEXUS_PRODIX_SERVICES_FILE="$SERVICES_FILE" \
"$COLLECTOR"

echo
echo "[NEXUS][SIM] Status do PAINEL por VM:"
awk -F';' '
  NR > 1 && tolower($7) == "painel" {
    printf "%-7s %-6s %-8s PID=%s\n", $3, $5, $11, $13
  }
' "$ROOT_DIR/backend/data/runtime/service_status.csv"

echo
echo "[NEXUS][SIM] Esperado: 2 RUNNING e 14 STOPPED."
