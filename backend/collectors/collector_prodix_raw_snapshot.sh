#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor bruto Prodix
#
# Objetivo:
#   Gerar prodix_raw_process_snapshot.csv a partir de evidências locais read-only.
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
OUTPUT_FILE="${NEXUS_PRODIX_RAW_SNAPSHOT_OUTPUT:-$PROJECT_ROOT/backend/data/runtime/prodix_raw_process_snapshot.csv}"

EXPECTED_HEADER="ihm;ldom;ip_address;evidence_file"
OUTPUT_HEADER="ihm;ldom;ip_address;technical_comm;process_list"

mkdir -p "$(dirname "$OUTPUT_FILE")"

if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "[NEXUS][ERRO] Config de alvos não encontrada: $TARGETS_FILE" >&2
  exit 1
fi

header="$(head -n 1 "$TARGETS_FILE")"

if [[ "$header" != "$EXPECTED_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $TARGETS_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $header" >&2
  exit 1
fi

has_process() {
  local evidence_file="$1"
  local process_name="$2"

  grep -Eq "(^|[[:space:]/])${process_name}([[:space:]]|$)" "$evidence_file"
}

extract_process_list() {
  local evidence_file="$1"
  local processes=()

  if has_process "$evidence_file" "sb_recebe"; then
    processes+=("sb_recebe")
  fi

  if has_process "$evidence_file" "ma"; then
    processes+=("ma")
  fi

  if has_process "$evidence_file" "sb_watdog"; then
    processes+=("sb_watdog")
  fi

  if has_process "$evidence_file" "painelcon"; then
    processes+=("painelcon")
  fi

  printf '%s ' "${processes[@]}" | sed 's/[[:space:]]$//'
}

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

printf '%s\n' "$OUTPUT_HEADER" > "$TMP_FILE"

tail -n +2 "$TARGETS_FILE" | while IFS=';' read -r ihm ldom ip_address evidence_file; do
  [[ -z "${ihm:-}" ]] && continue

  evidence_path="$PROJECT_ROOT/$evidence_file"

  technical_comm="WAIT"
  process_list=""

  if [[ -f "$evidence_path" ]]; then
    technical_comm="OK"
    process_list="$(extract_process_list "$evidence_path")"
  fi

  printf '%s;%s;%s;%s;%s\n' \
    "$ihm" \
    "$ldom" \
    "$ip_address" \
    "$technical_comm" \
    "$process_list" >> "$TMP_FILE"
done

mv "$TMP_FILE" "$OUTPUT_FILE"

echo "[NEXUS] prodix_raw_process_snapshot.csv gerado em: $OUTPUT_FILE"
