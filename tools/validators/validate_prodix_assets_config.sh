#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/config/prodix_assets.sample.csv}"

EXPECTED_HEADER="asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message"

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

NF != 13 {
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 13: %s\n", NR, NF, $0) > "/dev/stderr"
  errors++
  next
}

{
  asset_id = $1
  logical_asset_id = $2
  asset_name = $3
  asset_type = $4
  parent_asset = $5
  ldom = $6
  ip_address = $7
  technical_comm = $8
  health_status = $9
  operational_role = $10
  redundancy_group = $11
  redundancy_conflict = $12
  message = $13

  if (asset_id == "" || logical_asset_id == "" || asset_name == "" || message == "") {
    printf("[NEXUS][ERRO] Linha %d: campos obrigatórios vazios\n", NR) > "/dev/stderr"
    errors++
  }

  if (asset_type !~ /^(ILOM|CONTROL_DOMAIN|LDOM|FIXED_SERVER|MOBILE_IHM|WS)$/) {
    printf("[NEXUS][ERRO] Linha %d: asset_type inválido: %s\n", NR, asset_type) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2|N\/A)$/) {
    printf("[NEXUS][ERRO] Linha %d: ldom inválido: %s\n", NR, ldom) > "/dev/stderr"
    errors++
  }

  if (technical_comm !~ /^(OK|WARN|CRIT|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: technical_comm inválido: %s\n", NR, technical_comm) > "/dev/stderr"
    errors++
  }

  if (health_status !~ /^(OK|WARN|CRIT|CRITICAL|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: health_status inválido: %s\n", NR, health_status) > "/dev/stderr"
    errors++
  }

  if (operational_role !~ /^(ATIVO|STANDBY|DESLIGADO|FALHA|NAO_APLICAVEL)$/) {
    printf("[NEXUS][ERRO] Linha %d: operational_role inválido: %s\n", NR, operational_role) > "/dev/stderr"
    errors++
  }

  if (redundancy_conflict !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: redundancy_conflict inválido: %s\n", NR, redundancy_conflict) > "/dev/stderr"
    errors++
  }

  seen[asset_id]++

  if (seen[asset_id] > 1) {
    printf("[NEXUS][ERRO] Linha %d: asset_id duplicado: %s\n", NR, asset_id) > "/dev/stderr"
    errors++
  }
}

END {
  if (errors > 0) {
    printf("[NEXUS][ERRO] Validação de ativos Prodix falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] config de ativos Prodix válida\n")
}
' "$CSV_FILE"
