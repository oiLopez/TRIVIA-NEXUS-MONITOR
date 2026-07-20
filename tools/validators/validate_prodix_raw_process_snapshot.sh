#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="${1:-backend/data/runtime/prodix_raw_process_snapshot.csv}"

EXPECTED_HEADER="ihm;ldom;ip_address;technical_comm;process_list"

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

NF != 5 {
  printf("[NEXUS][ERRO] Linha %d possui %d campos; esperado 5: %s\n", NR, NF, $0) > "/dev/stderr"
  errors++
  next
}

{
  ihm = $1
  ldom = $2
  ip_address = $3
  technical_comm = $4
  process_list = $5

  if (ihm !~ /^(CPTM1|CPTM2|CPTM3|CPTM4|SME3|CONS1|CONS5|CPTM12)$/) {
    printf("[NEXUS][ERRO] Linha %d: IHM inválida: %s\n", NR, ihm) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2)$/) {
    printf("[NEXUS][ERRO] Linha %d: LDOM inválida: %s\n", NR, ldom) > "/dev/stderr"
    errors++
  }

  if (ip_address == "") {
    printf("[NEXUS][ERRO] Linha %d: ip_address vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (technical_comm !~ /^(OK|WARN|CRIT|WAIT)$/) {
    printf("[NEXUS][ERRO] Linha %d: technical_comm inválido: %s\n", NR, technical_comm) > "/dev/stderr"
    errors++
  }

  if (process_list ~ /;/) {
    printf("[NEXUS][ERRO] Linha %d: process_list não deve conter ponto e vírgula\n", NR) > "/dev/stderr"
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
    printf("[NEXUS][ERRO] Validação do raw snapshot Prodix falhou com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] raw snapshot Prodix válido\n")
}
' "$CSV_FILE"
