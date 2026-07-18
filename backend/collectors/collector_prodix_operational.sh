#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor: collector_prodix_operational.sh
#
# Objetivo:
#   Gerar backend/data/runtime/operational_status.csv com foco no modelo
#   operacional ALSTOM/Prodix.
#
# Segurança:
#   - Coletor somente leitura.
#   - Não executa start/stop.
#   - Não altera processos.
#   - Não executa scripts PRODIX/STOPPRODIX.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OUTPUT_FILE="${NEXUS_OPERATIONAL_OUTPUT:-$PROJECT_ROOT/backend/data/runtime/operational_status.csv}"
TIMESTAMP="${NEXUS_OPERATIONAL_TIMESTAMP:-$(date '+%Y-%m-%d %H:%M:%S')}"

MODE="${NEXUS_PRODIX_COLLECTOR_MODE:-snapshot}"

SNAPSHOT_FILE="${NEXUS_PRODIX_SNAPSHOT_FILE:-$PROJECT_ROOT/backend/data/runtime/prodix_process_snapshot.csv}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

HEADER="timestamp;asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message"

printf '%s\n' "$HEADER" > "$TMP_FILE"

emit_row() {
  local asset_id="$1"
  local logical_asset_id="$2"
  local asset_name="$3"
  local asset_type="$4"
  local parent_asset="$5"
  local ldom="$6"
  local ip_address="$7"
  local technical_comm="$8"
  local health_status="$9"
  local operational_role="${10}"
  local redundancy_group="${11}"
  local redundancy_conflict="${12}"
  local message="${13}"

  printf '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n' \
    "$TIMESTAMP" \
    "$asset_id" \
    "$logical_asset_id" \
    "$asset_name" \
    "$asset_type" \
    "$parent_asset" \
    "$ldom" \
    "$ip_address" \
    "$technical_comm" \
    "$health_status" \
    "$operational_role" \
    "$redundancy_group" \
    "$redundancy_conflict" \
    "$message" >> "$TMP_FILE"
}

normalize_bool() {
  case "${1:-}" in
    true|TRUE|1|sim|SIM|yes|YES) echo "true" ;;
    *) echo "false" ;;
  esac
}

normalize_comm() {
  case "${1:-WAIT}" in
    OK|ok) echo "OK" ;;
    WARN|warn|WARNING|warning) echo "WARN" ;;
    CRIT|crit|CRITICAL|critical) echo "CRIT" ;;
    *) echo "WAIT" ;;
  esac
}

derive_prodix_health() {
  local technical_comm="$1"
  local sb_recebe="$2"
  local ma="$3"
  local sb_watdog="$4"

  if [[ "$technical_comm" != "OK" ]]; then
    echo "WAIT"
    return 0
  fi

  if [[ "$sb_recebe" == "true" && "$ma" == "true" && "$sb_watdog" == "true" ]]; then
    echo "OK"
    return 0
  fi

  if [[ "$sb_recebe" == "true" || "$ma" == "true" || "$sb_watdog" == "true" ]]; then
    echo "WARN"
    return 0
  fi

  echo "CRIT"
}

derive_prodix_role() {
  local technical_comm="$1"
  local sb_recebe="$2"
  local ma="$3"
  local sb_watdog="$4"

  if [[ "$technical_comm" != "OK" ]]; then
    echo "DESLIGADO"
    return 0
  fi

  if [[ "$sb_recebe" == "true" && "$ma" == "true" && "$sb_watdog" == "true" ]]; then
    echo "ATIVO"
    return 0
  fi

  if [[ "$sb_recebe" == "true" || "$ma" == "true" || "$sb_watdog" == "true" ]]; then
    echo "FALHA"
    return 0
  fi

  echo "STANDBY"
}

emit_static_infra() {
  emit_row "ILOM1" "ILOM1" "Chassi ILOM 1" "ILOM" "N/A" "N/A" "192.0.2.13" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "ILOM comunicando normalmente"
  emit_row "ILOM2" "ILOM2" "Chassi ILOM 2" "ILOM" "N/A" "N/A" "192.0.2.14" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "ILOM comunicando normalmente"

  emit_row "CONTROL_DOMAIN_1" "CONTROL_DOMAIN_1" "Control Domain 1" "CONTROL_DOMAIN" "ILOM1" "N/A" "192.0.2.11" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "Control Domain operacional"
  emit_row "CONTROL_DOMAIN_2" "CONTROL_DOMAIN_2" "Control Domain 2" "CONTROL_DOMAIN" "ILOM2" "N/A" "192.0.2.12" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "Control Domain operacional"

  emit_row "LDOM1" "LDOM1" "LDOM 1" "LDOM" "CONTROL_DOMAIN_1" "LDOM1" "192.0.2.15" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "LDOM operacional"
  emit_row "LDOM2" "LDOM2" "LDOM 2" "LDOM" "CONTROL_DOMAIN_2" "LDOM2" "192.0.2.17" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "LDOM operacional"
}

emit_fixed_servers() {
  emit_row "SFT1" "SFT1" "Servidor SFT1" "FIXED_SERVER" "LDOM1" "LDOM1" "192.0.2.19" "OK" "OK" "ATIVO" "SFT_PAIR" "false" "Servidor fixo ativo em operacao"
  emit_row "SFT2" "SFT2" "Servidor SFT2" "FIXED_SERVER" "LDOM2" "LDOM2" "192.0.2.21" "OK" "OK" "STANDBY" "SFT_PAIR" "false" "Servidor fixo em standby"

  emit_row "METROSP44" "METROSP44" "Servidor METROSP44" "FIXED_SERVER" "LDOM1" "LDOM1" "192.0.2.23" "OK" "OK" "STANDBY" "METROSP_PAIR" "false" "Servidor fixo em standby"
  emit_row "METROSP45" "METROSP45" "Servidor METROSP45" "FIXED_SERVER" "LDOM2" "LDOM2" "192.0.2.25" "OK" "OK" "ATIVO" "METROSP_PAIR" "false" "Servidor fixo ativo em operacao"
}

emit_ihm_from_snapshot_row() {
  local ihm="$1"
  local ldom="$2"
  local ip="$3"
  local technical_comm="$4"
  local sb_recebe="$5"
  local ma="$6"
  local sb_watdog="$7"

  technical_comm="$(normalize_comm "$technical_comm")"
  sb_recebe="$(normalize_bool "$sb_recebe")"
  ma="$(normalize_bool "$ma")"
  sb_watdog="$(normalize_bool "$sb_watdog")"

  local health_status
  local operational_role

  health_status="$(derive_prodix_health "$technical_comm" "$sb_recebe" "$ma" "$sb_watdog")"
  operational_role="$(derive_prodix_role "$technical_comm" "$sb_recebe" "$ma" "$sb_watdog")"

  emit_row \
    "${ihm}_IHM_${ldom}" \
    "${ihm}_IHM" \
    "IHM Movel ${ihm} - ${ldom}" \
    "MOBILE_IHM" \
    "$ldom" \
    "$ldom" \
    "$ip" \
    "$technical_comm" \
    "$health_status" \
    "$operational_role" \
    "${ihm}_IHM" \
    "false" \
    "Estado derivado de processos Prodix: sb_recebe=${sb_recebe}, ma=${ma}, sb_watdog=${sb_watdog}"
}

load_snapshot_ihms() {
  if [[ ! -f "$SNAPSHOT_FILE" ]]; then
    echo "[NEXUS][WARN] Snapshot Prodix não encontrado: $SNAPSHOT_FILE" >&2
    echo "[NEXUS][WARN] Gere um snapshot ou use o simulador operacional." >&2
    return 0
  fi

  local header
  header="$(head -n 1 "$SNAPSHOT_FILE")"

  local expected_header="ihm;ldom;ip_address;technical_comm;sb_recebe;ma;sb_watdog"

  if [[ "$header" != "$expected_header" ]]; then
    echo "[NEXUS][ERRO] Cabeçalho inválido no snapshot Prodix." >&2
    echo "[NEXUS][INFO] Esperado: $expected_header" >&2
    echo "[NEXUS][INFO] Atual:    $header" >&2
    exit 1
  fi

  tail -n +2 "$SNAPSHOT_FILE" | while IFS=';' read -r ihm ldom ip technical_comm sb_recebe ma sb_watdog; do
    [[ -z "${ihm:-}" ]] && continue
    emit_ihm_from_snapshot_row "$ihm" "$ldom" "$ip" "$technical_comm" "$sb_recebe" "$ma" "$sb_watdog"
  done
}

mark_redundancy_conflicts() {
  local input_file="$1"
  local output_file="$2"

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
    group[NR] = $12
    role[NR] = $11

    if ($12 != "" && $12 != "NONE" && $12 != "N/A" && $11 == "ATIVO") {
      active_count[$12]++
    }

    max_nr = NR
  }

  END {
    for (i = 2; i <= max_nr; i++) {
      split(rows[i], f, FS)

      current_group = f[12]
      current_role = f[11]

      if (current_group != "" && current_group != "NONE" && current_group != "N/A" && current_role == "ATIVO" && active_count[current_group] > 1) {
        f[10] = "CRITICAL"
        f[13] = "true"
        f[14] = "Conflito operacional: mais de uma instancia ATIVA no grupo " current_group
      }

      print f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9], f[10], f[11], f[12], f[13], f[14]
    }
  }
  ' "$input_file" > "$output_file"
}

main() {
  emit_static_infra
  emit_fixed_servers

  case "$MODE" in
    snapshot)
      load_snapshot_ihms
      ;;
    *)
      echo "[NEXUS][ERRO] Modo inválido: $MODE" >&2
      echo "[NEXUS][INFO] Use NEXUS_PRODIX_COLLECTOR_MODE=snapshot" >&2
      exit 1
      ;;
  esac

  local conflict_tmp
  conflict_tmp="$(mktemp)"
  trap 'rm -f "$TMP_FILE" "$conflict_tmp"' EXIT

  mark_redundancy_conflicts "$TMP_FILE" "$conflict_tmp"

  mv "$conflict_tmp" "$OUTPUT_FILE"

  echo "[NEXUS] operational_status.csv gerado em: $OUTPUT_FILE"
}

main "$@"
