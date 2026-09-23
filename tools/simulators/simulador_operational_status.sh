#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Simulador operacional Prodix baseado em snapshot.
#
# Fonte simulada:
#   backend/data/runtime/prodix_process_snapshot.csv
#
# Derivação:
#   collector_prodix_operational.sh
#       -> backend/data/runtime/operational_status.csv
#
# Regra:
#   - exatamente uma instância ATIVA por aplicação em cenário normal;
#   - a outra LDOM permanece STANDBY;
#   - NEXUS_SIMULATE_CPTM2_CONFLICT=1 força CPTM2 ATIVO nas duas LDOMs.
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SNAPSHOT_FILE="${NEXUS_PRODIX_SNAPSHOT_FILE:-$ROOT_DIR/backend/data/runtime/prodix_process_snapshot.csv}"
COLLECTOR="$ROOT_DIR/backend/collectors/collector_prodix_operational.sh"
SIMULATE_CPTM2_CONFLICT="${NEXUS_SIMULATE_CPTM2_CONFLICT:-0}"

mkdir -p "$(dirname "$SNAPSHOT_FILE")"

if [[ ! -x "$COLLECTOR" ]]; then
  echo "[NEXUS][ERRO] Collector não executável: $COLLECTOR" >&2
  echo "Execute: chmod +x backend/collectors/collector_prodix_operational.sh" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

printf '%s\n' 'ihm;ldom;ip_address;technical_comm;sb_recebe;ma;sb_watdog' > "$TMP_FILE"

emit_active() {
  local ihm="$1"
  local ldom="$2"
  local ip="$3"
  printf '%s;%s;%s;OK;true;true;true\n' "$ihm" "$ldom" "$ip" >> "$TMP_FILE"
}

emit_standby() {
  local ihm="$1"
  local ldom="$2"
  local ip="$3"
  printf '%s;%s;%s;OK;false;false;false\n' "$ihm" "$ldom" "$ip" >> "$TMP_FILE"
}

emit_pair() {
  local ihm="$1"
  local ip="$2"
  local active_ldom="$3"

  if [[ "$active_ldom" == "LDOM1" ]]; then
    emit_active "$ihm" "LDOM1" "$ip"
    emit_standby "$ihm" "LDOM2" "$ip"
  else
    emit_standby "$ihm" "LDOM1" "$ip"
    emit_active "$ihm" "LDOM2" "$ip"
  fi
}

# Balanceamento simulado:
# LDOM1: CPTM1, CPTM2, SME3, CONS1
# LDOM2: CPTM3, CPTM4, CONS5, CPTM12

emit_pair "CPTM1"  "192.0.2.33" "LDOM1"

if [[ "$SIMULATE_CPTM2_CONFLICT" == "1" ]]; then
  emit_active "CPTM2" "LDOM1" "192.0.2.35"
  emit_active "CPTM2" "LDOM2" "192.0.2.35"
else
  emit_pair "CPTM2" "192.0.2.35" "LDOM1"
fi

emit_pair "CPTM3"  "192.0.2.37" "LDOM2"
emit_pair "CPTM4"  "192.0.2.39" "LDOM2"
emit_pair "SME3"   "192.0.2.27" "LDOM1"
emit_pair "CONS1"  "192.0.2.29" "LDOM1"
emit_pair "CONS5"  "192.0.2.31" "LDOM2"
emit_pair "CPTM12" "192.0.2.41" "LDOM2"

mv "$TMP_FILE" "$SNAPSHOT_FILE"
trap - EXIT

echo "[NEXUS][SIM] prodix_process_snapshot.csv gerado."
echo "[NEXUS][SIM] conflito CPTM2=${SIMULATE_CPTM2_CONFLICT}"

NEXUS_PRODIX_COLLECTOR_MODE=snapshot \
NEXUS_PRODIX_SNAPSHOT_FILE="$SNAPSHOT_FILE" \
"$COLLECTOR"

echo
echo "[NEXUS][SIM] Distribuição operacional:"
awk -F';' '
  NR > 1 && $5 == "MOBILE_IHM" {
    printf "%-6s %-6s papel=%-8s health=%-4s conflito=%s\n", $3, $7, $11, $10, $13
  }
' "$ROOT_DIR/backend/data/runtime/operational_status.csv"
