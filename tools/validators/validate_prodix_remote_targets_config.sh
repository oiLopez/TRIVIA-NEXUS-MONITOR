#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${1:-backend/config/prodix_remote_targets.sample.csv}"
EXPECTED_HEADER="host_id;host_name;ldom;access_method;gateway;target;output_file;enabled"

errors=0
warnings=0

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "[NEXUS][ERRO] Arquivo não encontrado: $TARGET_FILE" >&2
  exit 1
fi

header="$(head -n 1 "$TARGET_FILE")"

if [[ "$header" != "$EXPECTED_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em $TARGET_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $header" >&2
  exit 1
fi

awk -F';' '
BEGIN {
  errors = 0
  warnings = 0
}

NR == 1 {
  next
}

NF != 8 {
  printf("[NEXUS][ERRO] Linha %d: esperado 8 campos, encontrado %d\n", NR, NF) > "/dev/stderr"
  errors++
  next
}

{
  host_id = $1
  host_name = $2
  ldom = $3
  access_method = $4
  gateway = $5
  target = $6
  output_file = $7
  enabled = $8

  if (host_id == "" || host_name == "" || ldom == "" || access_method == "" || output_file == "" || enabled == "") {
    printf("[NEXUS][ERRO] Linha %d: campo obrigatório vazio\n", NR) > "/dev/stderr"
    errors++
  }

  if (host_id !~ /^[A-Za-z0-9_.-]+$/) {
    printf("[NEXUS][ERRO] Linha %d: host_id inválido: %s\n", NR, host_id) > "/dev/stderr"
    errors++
  }

  if (host_name !~ /^[A-Za-z0-9_.-]+$/) {
    printf("[NEXUS][ERRO] Linha %d: host_name inválido: %s\n", NR, host_name) > "/dev/stderr"
    errors++
  }

  if (ldom !~ /^(LDOM1|LDOM2|N\/A|NA|UNKNOWN)$/) {
    printf("[NEXUS][WARN] Linha %d: ldom não padronizada: %s\n", NR, ldom) > "/dev/stderr"
    warnings++
  }

  if (access_method !~ /^(local|ssh|ssh_gateway_ssh|ssh_gateway_rsh|manual_rlogin)$/) {
    printf("[NEXUS][ERRO] Linha %d: access_method inválido: %s\n", NR, access_method) > "/dev/stderr"
    errors++
  }

  if (access_method ~ /^ssh_gateway_/ && gateway == "") {
    printf("[NEXUS][ERRO] Linha %d: access_method %s exige gateway\n", NR, access_method) > "/dev/stderr"
    errors++
  }

  if (access_method != "local" && target == "") {
    printf("[NEXUS][ERRO] Linha %d: access_method %s exige target\n", NR, access_method) > "/dev/stderr"
    errors++
  }

  if (gateway != "" && gateway !~ /^[A-Za-z0-9_.@-]+$/) {
    printf("[NEXUS][ERRO] Linha %d: gateway inválido: %s\n", NR, gateway) > "/dev/stderr"
    errors++
  }

  if (target != "" && target !~ /^[A-Za-z0-9_.@-]+$/) {
    printf("[NEXUS][ERRO] Linha %d: target inválido: %s\n", NR, target) > "/dev/stderr"
    errors++
  }

  if (output_file !~ /^backend\/data\/runtime\/prodix_ps\/[A-Za-z0-9_.-]+\.ps$/) {
    printf("[NEXUS][ERRO] Linha %d: output_file deve apontar para backend/data/runtime/prodix_ps/*.ps: %s\n", NR, output_file) > "/dev/stderr"
    errors++
  }

  if (enabled !~ /^(true|false)$/) {
    printf("[NEXUS][ERRO] Linha %d: enabled inválido: %s\n", NR, enabled) > "/dev/stderr"
    errors++
  }
}

END {
  if (errors > 0) {
    printf("[NEXUS][ERRO] Config de remote targets inválida com %d erro(s)\n", errors) > "/dev/stderr"
    exit 1
  }

  printf("[NEXUS][OK] config de remote targets Prodix válida\n")
}
' "$TARGET_FILE"
