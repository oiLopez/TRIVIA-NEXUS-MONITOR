#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/data/runtime/operational_status.csv}"

EXPECTED_HEADER="timestamp;asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[NEXUS][ERRO] Arquivo não encontrado: $CSV_FILE" >&2
  exit 1
fi

header="$(head -n 1 "$CSV_FILE")"

if [[ "$header" != "$EXPECTED_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $CSV_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $header" >&2
  exit 1
fi

awk -F';' '
BEGIN {
  errors = 0
}

NR == 1 {
  next
}

NF != 14 {
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 14: %s\n", NR, NF, $0) > "/dev/stderr"
  errors++
  next
}

{
  timestamp = $1
  asset_id = $2
  logical_asset_id = $3
  asset_name = $4
  asset_type = $5
  parent_asset = $6
  ldom = $7
  ip_address = $8
  technical_comm = $9
  health_status = $10
  operational_role = $11
  redundancy_group = $12
  redundancy_conflict = $13
  message = $14

  if (timestamp == "") {
    printf("[NEXUS][ERRO] Linha %d: timestamp vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (asset_id == "") {
    printf("[NEXUS][ERRO] Linha %d: asset_id vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (logical_asset_id == "") {
    printf("[NEXUS][ERRO] Linha %d: logical_asset_id vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (asset_name == "") {
    printf("[NEXUS][ERRO] Linha %d: asset_name vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (asset_type !~ /^(ILOM|CONTROL_DOMAIN|LDOM|FIXED_SERVER|MOBILE_IHM|WS)$/) {
    printf("[NEXUS][ERRO] Linha %d: asset_type invalido: %s\n", NR, asset_type) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2|N\/A)$/) {
    printf("[NEXUS][ERRO] Linha %d: ldom invalido: %s\n", NR, ldom) > "/dev/stderr"
    errors++
  }

  if (technical_comm !~ /^(OK|WARN|CRIT|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: technical_comm invalido: %s\n", NR, technical_comm) > "/dev/stderr"
    errors++
  }

  if (health_status !~ /^(OK|WARN|CRIT|CRITICAL|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: health_status invalido: %s\n", NR, health_status) > "/dev/stderr"
    errors++
  }

  if (operational_role !~ /^(ATIVO|STANDBY|DESLIGADO|FALHA|NAO_APLICAVEL)$/) {
    printf("[NEXUS][ERRO] Linha %d: operational_role invalido: %s\n", NR, operational_role) > "/dev/stderr"
    errors++
  }

  if (redundancy_conflict !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: redundancy_conflict invalido: %s\n", NR, redundancy_conflict) > "/dev/stderr"
    errors++
  }

  if (redundancy_conflict == "true" && health_status !~ /^(CRIT|CRITICAL)$/) {
    printf("[NEXUS][ERRO] Linha %d: redundancy_conflict=true exige health_status CRIT ou CRITICAL\n", NR) > "/dev/stderr"
    errors++
  }

  if (asset_type == "MOBILE_IHM" && redundancy_group == "NONE") {
    printf("[NEXUS][ERRO] Linha %d: MOBILE_IHM precisa de redundancy_group logico\n", NR) > "/dev/stderr"
    errors++
  }

  if (message == "") {
    printf("[NEXUS][ERRO] Linha %d: message vazio\n", NR) > "/dev/stderr"
    errors++
  }
}

END {
  if (errors > 0) {
    printf("[NEXUS][ERRO] Validacao falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] operational_status valido\n")
}
' "$CSV_FILE"
