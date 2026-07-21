#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Pipeline operacional Prodix
#
# Executa a cadeia local:
#   prodix_raw_process_snapshot.csv
#       -> prodix_process_snapshot.csv
#       -> operational_status.csv
#       -> validações
#
# Segurança:
#   - Não executa start/stop.
#   - Não altera processos.
#   - Não acessa sistema remoto diretamente.
#   - Apenas consome snapshots locais e gera CSV runtime.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "[NEXUS] Iniciando pipeline operacional Prodix..."

echo
echo "[NEXUS] 1/7 - Gerando raw snapshot Prodix"
backend/collectors/collector_prodix_remote_ps_snapshot.sh
backend/collectors/collector_prodix_raw_snapshot.sh

echo
echo "[NEXUS] 2/7 - Validando raw snapshot Prodix"
tools/validators/validate_prodix_raw_process_snapshot.sh backend/data/runtime/prodix_raw_process_snapshot.csv

echo
echo "[NEXUS] 3/7 - Gerando prodix_process_snapshot.csv"
backend/collectors/collector_prodix_snapshot.sh

echo
echo "[NEXUS] 4/7 - Validando snapshot Prodix"
tools/validators/validate_prodix_process_snapshot.sh backend/data/runtime/prodix_process_snapshot.csv

echo
echo "[NEXUS] 5/7 - Gerando operational_status.csv"
backend/collectors/collector_prodix_operational.sh

echo
echo "[NEXUS] 6/7 - Validando contrato operational_status"
tools/validators/validate_operational_status.sh backend/data/runtime/operational_status.csv

echo
echo "[NEXUS] 7/7 - Validando conflitos operacionais"
tools/validators/validate_operational_conflicts.sh backend/data/runtime/operational_status.csv

echo
echo "[NEXUS][OK] Pipeline operacional Prodix concluído com sucesso."
