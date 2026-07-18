#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/data/runtime/prodix_process_snapshot.csv}"

EXPECTED_HEADER="ihm;ldom;ip_address;technical_comm;sb_recebe;ma;sb_watdog"

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

NF != 7 {
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 7: %s\n", NR, NF, $0) > "/dev/stderr"
  errors++
  next
}

{
  ihm = $1
  ldom = $2
  ip_address = $3
  technical_comm = $4
  sb_recebe = $5
  ma = $6
  sb_watdog = $7

  if (ihm !~ /^(CPTM1|CPTM2|CPTM3|CPTM4|SME3|CONS1|CONS5|CPTM12)$/) {
    printf("[NEXUS][ERRO] Linha %d: IHM inválida: %s\n", NR, ihm) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2)$/) {
    printf("[NEXUS][ERRO] Linha %d: LDOM inválida: %s\n", NR, ldom) > "/dev/stderr"
    errors++
  }

  if (technical_comm !~ /^(OK|WARN|CRIT|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: technical_comm inválido: %s\n", NR, technical_comm) > "/dev/stderr"
    errors++
  }

  if (sb_recebe !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: sb_recebe inválido: %s\n", NR, sb_recebe) > "/dev/stderr"
    errors++
  }

  if (ma !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: ma inválido: %s\n", NR, ma) > "/dev/stderr"
    errors++
  }

  if (sb_watdog !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: sb_watdog inválido: %s\n", NR, sb_watdog) > "/dev/stderr"
    errors++
  }

  key = ihm ";" ldom
  seen[key]++

  if (seen[key] > 1) {
    printf("[NEXUS][ERRO] Linha %d: combinação IHM/LDOM duplicada: %s/%s\n", NR, ihm, ldom) > "/dev/stderr"
    errors++
  }
}

END {
  if (errors > 0) {
    printf("[NEXUS][ERRO] Validação do snapshot Prodix falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] snapshot Prodix válido\n")
}
' "$CSV_FILE"
