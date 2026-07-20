#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor: collector_prodix_snapshot.sh
#
# Objetivo:
#   Gerar backend/data/runtime/prodix_process_snapshot.csv com base em
#   evidências read-only dos processos Prodix.
#
# Segurança:
#   - Não inicia processos.
#   - Não mata processos.
#   - Não executa PRODIX/STOPPRODIX.
#   - Apenas interpreta snapshots de processo.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OUTPUT_FILE="${NEXUS_PRODIX_SNAPSHOT_OUTPUT:-$PROJECT_ROOT/backend/data/runtime/prodix_process_snapshot.csv}"
INPUT_FILE="${NEXUS_PRODIX_SNAPSHOT_INPUT:-$PROJECT_ROOT/backend/data/runtime/prodix_raw_process_snapshot.csv}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

HEADER="ihm;ldom;ip_address;technical_comm;sb_recebe;ma;sb_watdog"
EXPECTED_INPUT_HEADER="ihm;ldom;ip_address;technical_comm;process_list"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "[NEXUS][ERRO] Snapshot bruto não encontrado: $INPUT_FILE" >&2
  echo "[NEXUS][INFO] Esperado CSV com cabeçalho:" >&2
  echo "[NEXUS][INFO] $EXPECTED_INPUT_HEADER" >&2
  exit 1
fi

input_header="$(head -n 1 "$INPUT_FILE")"

if [[ "$input_header" != "$EXPECTED_INPUT_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $INPUT_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_INPUT_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $input_header" >&2
  exit 1
fi

normalize_comm() {
  case "${1:-WAIT}" in
    OK|ok) echo "OK" ;;
    WARN|warn|WARNING|warning) echo "WARN" ;;
    CRIT|crit|CRITICAL|critical) echo "CRIT" ;;
    *) echo "WAIT" ;;
  esac
}

has_process() {
  local process_list="$1"
  local process_name="$2"

  printf '%s\n' "$process_list" | grep -Eq "(^|[[:space:]/])${process_name}([[:space:]]|$)"
}

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

printf '%s\n' "$HEADER" > "$TMP_FILE"

tail -n +2 "$INPUT_FILE" | while IFS=';' read -r ihm ldom ip_address technical_comm process_list; do
  [[ -z "${ihm:-}" ]] && continue

  technical_comm="$(normalize_comm "$technical_comm")"

  sb_recebe="false"
  ma="false"
  sb_watdog="false"

  if [[ "$technical_comm" == "OK" ]]; then
    if has_process "$process_list" "sb_recebe"; then
      sb_recebe="true"
    fi

    if has_process "$process_list" "ma"; then
      ma="true"
    fi

    if has_process "$process_list" "sb_watdog"; then
      sb_watdog="true"
    fi
  fi

  printf '%s;%s;%s;%s;%s;%s;%s\n' \
    "$ihm" \
    "$ldom" \
    "$ip_address" \
    "$technical_comm" \
    "$sb_recebe" \
    "$ma" \
    "$sb_watdog" >> "$TMP_FILE"
done

mv "$TMP_FILE" "$OUTPUT_FILE"

echo "[NEXUS] prodix_process_snapshot.csv gerado em: $OUTPUT_FILE"
