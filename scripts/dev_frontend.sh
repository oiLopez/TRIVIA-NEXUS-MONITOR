#!/usr/bin/env bash
# ==========================================================
# NEXUS MONITOR - Ambiente local de desenvolvimento Frontend
#
# Publica dados sample, valida contrato CSV e sobe servidor
# HTTP local para testar a interface gráfica.
#
# Uso:
#   bash scripts/dev_frontend.sh
#   bash scripts/dev_frontend.sh 8080
# ==========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PORT="${1:-8000}"
HOST="127.0.0.1"

FRONTEND_URL="http://${HOST}:${PORT}/frontend/index.html"

cd "${PROJECT_ROOT}"

echo "=========================================================="
echo " NEXUS MONITOR - Frontend Dev Server"
echo "=========================================================="
echo "Projeto: ${PROJECT_ROOT}"
echo "Host:    ${HOST}"
echo "Porta:   ${PORT}"
echo

echo "[1/4] Publicando sample CSV para backend/data/current..."
bash scripts/publish_frontend_sample.sh
echo

echo "[2/4] Validando contrato status_ldom.csv..."
bash tools/validators/validate_status_ldom.sh backend/data/current/status_ldom.csv
echo

echo "[3/4] Executando verificação geral do projeto..."
bash scripts/check_project.sh
echo

echo "[4/4] Iniciando servidor local..."
echo
echo "Interface:"
echo "  ${FRONTEND_URL}"
echo
echo "Para encerrar:"
echo "  Ctrl + C"
echo

python3 -m http.server "${PORT}" --bind "${HOST}"
