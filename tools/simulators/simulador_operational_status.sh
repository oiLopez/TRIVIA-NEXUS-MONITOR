#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

OUTPUT_FILE="${NEXUS_OPERATIONAL_OUTPUT:-$ROOT_DIR/backend/data/runtime/operational_status.csv}"
TIMESTAMP="${NEXUS_OPERATIONAL_TIMESTAMP:-$(date '+%Y-%m-%d %H:%M:%S')}"
SIMULATE_CPTM2_CONFLICT="${NEXUS_SIMULATE_CPTM2_CONFLICT:-0}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

TMP_FILE="$(mktemp)"

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

emit_fixed_server() {
  local name="$1"
  local parent="$2"
  local ldom="$3"
  local ip="$4"
  local role="$5"
  local redundancy_group="$6"

  local message="Servidor fixo em standby"

  if [[ "$role" == "ATIVO" ]]; then
    message="Servidor fixo ativo em operacao"
  fi

  emit_row \
    "$name" \
    "$name" \
    "Servidor $name" \
    "FIXED_SERVER" \
    "$parent" \
    "$ldom" \
    "$ip" \
    "OK" \
    "OK" \
    "$role" \
    "$redundancy_group" \
    "false" \
    "$message"
}

emit_ihm_instance() {
  local ihm="$1"
  local ldom="$2"
  local ip="$3"
  local role="$4"
  local health="$5"
  local conflict="$6"
  local message="$7"

  emit_row \
    "${ihm}_IHM_${ldom}" \
    "${ihm}_IHM" \
    "IHM Movel ${ihm} - ${ldom}" \
    "MOBILE_IHM" \
    "$ldom" \
    "$ldom" \
    "$ip" \
    "OK" \
    "$health" \
    "$role" \
    "${ihm}_IHM" \
    "$conflict" \
    "$message"
}

emit_ihm_pair() {
  local ihm="$1"
  local ip="$2"
  local active_ldom="$3"

  if [[ "$active_ldom" == "LDOM1" ]]; then
    emit_ihm_instance "$ihm" "LDOM1" "$ip" "ATIVO" "OK" "false" "IHM logica ativa na LDOM1"
    emit_ihm_instance "$ihm" "LDOM2" "$ip" "STANDBY" "OK" "false" "Mesma IHM logica em standby na LDOM2 usando o mesmo IP"
  else
    emit_ihm_instance "$ihm" "LDOM1" "$ip" "STANDBY" "OK" "false" "Mesma IHM logica em standby na LDOM1 usando o mesmo IP"
    emit_ihm_instance "$ihm" "LDOM2" "$ip" "ATIVO" "OK" "false" "IHM logica ativa na LDOM2"
  fi
}

emit_row "ILOM1" "ILOM1" "Chassi ILOM 1" "ILOM" "N/A" "N/A" "192.0.2.13" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "ILOM comunicando normalmente"
emit_row "ILOM2" "ILOM2" "Chassi ILOM 2" "ILOM" "N/A" "N/A" "192.0.2.14" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "ILOM comunicando normalmente"

emit_row "CONTROL_DOMAIN_1" "CONTROL_DOMAIN_1" "Control Domain 1" "CONTROL_DOMAIN" "ILOM1" "N/A" "192.0.2.11" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "Control Domain operacional"
emit_row "CONTROL_DOMAIN_2" "CONTROL_DOMAIN_2" "Control Domain 2" "CONTROL_DOMAIN" "ILOM2" "N/A" "192.0.2.12" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "Control Domain operacional"

emit_row "LDOM1" "LDOM1" "LDOM 1" "LDOM" "CONTROL_DOMAIN_1" "LDOM1" "192.0.2.15" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "LDOM operacional"
emit_row "LDOM2" "LDOM2" "LDOM 2" "LDOM" "CONTROL_DOMAIN_2" "LDOM2" "192.0.2.17" "OK" "OK" "NAO_APLICAVEL" "NONE" "false" "LDOM operacional"

emit_fixed_server "SFT1" "LDOM1" "LDOM1" "192.0.2.19" "ATIVO" "SFT_PAIR"
emit_fixed_server "SFT2" "LDOM2" "LDOM2" "192.0.2.21" "STANDBY" "SFT_PAIR"
emit_fixed_server "METROSP44" "LDOM1" "LDOM1" "192.0.2.23" "STANDBY" "METROSP_PAIR"
emit_fixed_server "METROSP45" "LDOM2" "LDOM2" "192.0.2.25" "ATIVO" "METROSP_PAIR"

emit_ihm_pair "CPTM1" "192.0.2.33" "LDOM1"

if [[ "$SIMULATE_CPTM2_CONFLICT" == "1" ]]; then
  emit_ihm_instance "CPTM2" "LDOM1" "192.0.2.35" "ATIVO" "CRITICAL" "true" "Conflito de IP: mesma IHM ativa nas duas LDOMs"
  emit_ihm_instance "CPTM2" "LDOM2" "192.0.2.35" "ATIVO" "CRITICAL" "true" "Conflito de IP: mesma IHM ativa nas duas LDOMs"
else
  emit_ihm_pair "CPTM2" "192.0.2.35" "LDOM1"
fi

emit_ihm_pair "CPTM3" "192.0.2.37" "LDOM2"
emit_ihm_pair "CPTM4" "192.0.2.39" "LDOM1"
emit_ihm_pair "SME3" "192.0.2.27" "LDOM1"
emit_ihm_pair "CONS1" "192.0.2.29" "LDOM1"
emit_ihm_pair "CONS5" "192.0.2.31" "LDOM2"
emit_ihm_pair "CPTM12" "192.0.2.41" "LDOM2"

mv "$TMP_FILE" "$OUTPUT_FILE"

echo "[NEXUS] operational_status.csv gerado em: $OUTPUT_FILE"
