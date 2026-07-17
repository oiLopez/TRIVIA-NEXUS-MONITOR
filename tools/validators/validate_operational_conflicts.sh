#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/data/runtime/operational_status.csv}"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[NEXUS][ERRO] Arquivo não encontrado: $CSV_FILE" >&2
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
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 14\n", NR, NF) > "/dev/stderr"
  errors++
  next
}

{
  timestamp = $1
  asset_id = $2
  logical_asset_id = $3
  asset_type = $5
  ldom = $7
  health_status = $10
  operational_role = $11
  redundancy_group = $12
  redundancy_conflict = $13

  if (first_timestamp == "") {
    first_timestamp = timestamp
  }

  if (timestamp != first_timestamp) {
    printf("[NEXUS][ERRO] Linha %d: runtime deve ser snapshot; timestamp diferente encontrado: %s != %s\n", NR, timestamp, first_timestamp) > "/dev/stderr"
    errors++
  }

  asset_seen[asset_id]++

  if (asset_seen[asset_id] > 1) {
    printf("[NEXUS][ERRO] Linha %d: asset_id duplicado no snapshot: %s\n", NR, asset_id) > "/dev/stderr"
    errors++
  }

  if (redundancy_group != "" && redundancy_group != "NONE" && redundancy_group != "N/A") {
    group_seen[redundancy_group] = 1

    if (operational_role == "ATIVO") {
      active_count[redundancy_group]++
      active_members[redundancy_group] = active_members[redundancy_group] " " asset_id

      if (redundancy_conflict == "true") {
        active_conflict_count[redundancy_group]++
      }

      if (health_status == "CRIT" || health_status == "CRITICAL") {
        active_critical_count[redundancy_group]++
      }
    }

    if (redundancy_conflict == "true") {
      conflict_true_count[redundancy_group]++
    }
  }
}

END {
  for (group in group_seen) {
    active = active_count[group] + 0
    marked_conflict = active_conflict_count[group] + 0
    marked_critical = active_critical_count[group] + 0
    any_conflict = conflict_true_count[group] + 0

    if (active > 1) {
      if (marked_conflict != active) {
        printf("[NEXUS][ERRO] Grupo %s possui %d ativos simultaneos, mas nem todos estao com redundancy_conflict=true. Membros:%s\n", group, active, active_members[group]) > "/dev/stderr"
        errors++
      }

      if (marked_critical != active) {
        printf("[NEXUS][ERRO] Grupo %s possui conflito ativo, mas nem todos os ativos estao com health_status CRIT/CRITICAL. Membros:%s\n", group, active, active_members[group]) > "/dev/stderr"
        errors++
      }
    }

    if (active <= 1 && any_conflict > 0) {
      printf("[NEXUS][ERRO] Grupo %s esta marcado com redundancy_conflict=true, mas possui apenas %d ativo(s)\n", group, active) > "/dev/stderr"
      errors++
    }
  }

  if (errors > 0) {
    printf("[NEXUS][ERRO] Validacao de conflitos falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] conflitos operacionais validos\n")
}
' "$CSV_FILE"
