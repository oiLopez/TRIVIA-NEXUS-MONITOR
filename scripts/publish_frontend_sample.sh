#!/usr/bin/env bash
# ==========================================================
# NEXUS MONITOR - Publicador de Sample do Frontend
# Copia o CSV sample para backend/data/current/status_ldom.csv
# ==========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SAMPLE_FILE="${PROJECT_ROOT}/backend/data/samples/status_ldom.sample.csv"
CURRENT_DIR="${PROJECT_ROOT}/backend/data/current"
CURRENT_FILE="${CURRENT_DIR}/status_ldom.csv"

if [[ ! -f "${SAMPLE_FILE}" ]]; then
  echo "ERRO: sample não encontrado: ${SAMPLE_FILE}" >&2
  exit 1
fi

mkdir -p "${CURRENT_DIR}"

cp "${SAMPLE_FILE}" "${CURRENT_FILE}"

echo "Sample publicado com sucesso:"
echo "${CURRENT_FILE}"
