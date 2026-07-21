#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATUS_LDOM_FILE="$PROJECT_ROOT/backend/data/current/status_ldom.csv"
MODE="${1:-normal}"

case "$MODE" in
  normal|conflito)
    ;;
  *)
    echo "Uso: $0 {normal|conflito}" >&2
    exit 1
    ;;
esac

if [[ ! -f "$STATUS_LDOM_FILE" ]]; then
  echo "[ERRO] Arquivo não encontrado: $STATUS_LDOM_FILE" >&2
  exit 1
fi

cp "$STATUS_LDOM_FILE" "/tmp/status_ldom.backup-cptm2-${MODE}-$(date +%Y%m%d-%H%M%S)"

if [[ "$MODE" == "conflito" ]]; then
  awk -F';' '
  BEGIN { OFS=FS }
  tolower($1)=="cptm2" && tolower($2)=="ldom1" {
    $3="ALERTA"
    $4="00d 00h"
  }
  tolower($1)=="cptm2" && tolower($2)=="ldom2" {
    $3="ALERTA"
    $4="00d 00h"
  }
  { print }
  ' "$STATUS_LDOM_FILE" > /tmp/status_ldom.cptm2

  mv /tmp/status_ldom.cptm2 "$STATUS_LDOM_FILE"

  NEXUS_SIMULATE_CPTM2_CONFLICT=1 "$PROJECT_ROOT/tools/simulators/simulador_operational_status.sh"
else
  awk -F';' '
  BEGIN { OFS=FS }
  tolower($1)=="cptm2" && tolower($2)=="ldom1" {
    $3="OK"
    if ($4=="" || $4=="-" || $4=="00d 00h") $4="02d 14h"
  }
  tolower($1)=="cptm2" && tolower($2)=="ldom2" {
    $3="STANDBY"
    if ($4=="" || $4=="-" || $4=="00d 00h") $4="02d 14h"
  }
  { print }
  ' "$STATUS_LDOM_FILE" > /tmp/status_ldom.cptm2

  mv /tmp/status_ldom.cptm2 "$STATUS_LDOM_FILE"

  NEXUS_SIMULATE_CPTM2_CONFLICT=0 "$PROJECT_ROOT/tools/simulators/simulador_operational_status.sh"
fi

echo "[OK] CPTM2 simulada em modo: $MODE"
echo
grep -Ei '^cptm2;' "$STATUS_LDOM_FILE" || true
grep -Ei 'CPTM2_IHM' "$PROJECT_ROOT/backend/data/runtime/operational_status.csv" || true
