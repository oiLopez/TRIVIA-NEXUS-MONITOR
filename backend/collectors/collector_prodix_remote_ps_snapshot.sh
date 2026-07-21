#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NEXUS MONITOR
# Coletor: collector_prodix_remote_ps_snapshot.sh
#
# Objetivo:
#   Coletar evidências read-only de processos Prodix usando ps -ef e salvar em
#   backend/data/runtime/prodix_ps/*.ps.
#
# Segurança:
#   - Executa somente ps -ef.
#   - Não executa start/stop/kill/ipcrm.
#   - Não altera processos remotos.
#   - Config real deve ficar em backend/config/*.local.csv.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGETS_FILE="${NEXUS_PRODIX_REMOTE_TARGETS_FILE:-$PROJECT_ROOT/backend/config/prodix_remote_targets.local.csv}"
SAMPLE_TARGETS_FILE="$PROJECT_ROOT/backend/config/prodix_remote_targets.sample.csv"

SSH_BIN="${NEXUS_SSH_BIN:-ssh}"
SSH_OPTIONS="${NEXUS_SSH_OPTIONS:--o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new}"
COLLECT_TIMEOUT="${NEXUS_REMOTE_PS_TIMEOUT:-15}"

EXPECTED_HEADER="host_id;host_name;ldom;access_method;gateway;target;output_file;enabled"

if [[ ! -f "$TARGETS_FILE" ]]; then
  TARGETS_FILE="$SAMPLE_TARGETS_FILE"
  echo "[NEXUS][WARN] Config local de remote targets não encontrada. Usando sample seguro: $TARGETS_FILE" >&2
fi

if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "[NEXUS][ERRO] Config de remote targets não encontrada: $TARGETS_FILE" >&2
  exit 1
fi

header="$(head -n 1 "$TARGETS_FILE")"

if [[ "$header" != "$EXPECTED_HEADER" ]]; then
  echo "[NEXUS][ERRO] Cabeçalho inválido em: $TARGETS_FILE" >&2
  echo "[NEXUS][INFO] Esperado: $EXPECTED_HEADER" >&2
  echo "[NEXUS][INFO] Atual:    $header" >&2
  exit 1
fi

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$COLLECT_TIMEOUT" "$@"
  else
    "$@"
  fi
}

is_safe_token() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9_.@-]+$ ]]
}

is_safe_output_file() {
  local value="$1"
  [[ "$value" =~ ^backend/data/runtime/prodix_ps/[A-Za-z0-9_.-]+\.ps$ ]]
}

collect_ps() {
  local access_method="$1"
  local gateway="$2"
  local target="$3"

  case "$access_method" in
    local)
      ps -ef
      ;;

    ssh)
      run_with_timeout "$SSH_BIN" $SSH_OPTIONS "$target" "ps -ef"
      ;;

    ssh_gateway_ssh)
      run_with_timeout "$SSH_BIN" $SSH_OPTIONS "$gateway" "ssh $target 'ps -ef'"
      ;;

    ssh_gateway_rsh)
      run_with_timeout "$SSH_BIN" $SSH_OPTIONS "$gateway" "rsh $target ps -ef"
      ;;

    manual_rlogin)
      echo "[NEXUS][WARN] manual_rlogin não é automatizado para evitar sessão interativa travada." >&2
      return 2
      ;;

    *)
      echo "[NEXUS][ERRO] access_method não suportado: $access_method" >&2
      return 1
      ;;
  esac
}

success_count=0
fail_count=0
skip_count=0

tail -n +2 "$TARGETS_FILE" | while IFS=';' read -r host_id host_name ldom access_method gateway target output_file enabled; do
  [[ -z "${host_id:-}" ]] && continue

  if [[ "$enabled" != "true" ]]; then
    echo "[NEXUS][SKIP] $host_id desabilitado."
    skip_count=$((skip_count + 1))
    continue
  fi

  if ! is_safe_token "$host_id" || ! is_safe_token "$host_name"; then
    echo "[NEXUS][ERRO] Token inseguro em host_id/host_name: $host_id / $host_name" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if [[ -n "$gateway" ]] && ! is_safe_token "$gateway"; then
    echo "[NEXUS][ERRO] Gateway inseguro para $host_id: $gateway" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if [[ -n "$target" ]] && ! is_safe_token "$target"; then
    echo "[NEXUS][ERRO] Target inseguro para $host_id: $target" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if ! is_safe_output_file "$output_file"; then
    echo "[NEXUS][ERRO] output_file inseguro para $host_id: $output_file" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  output_path="$PROJECT_ROOT/$output_file"
  output_dir="$(dirname "$output_path")"
  tmp_file="$(mktemp)"

  mkdir -p "$output_dir"

  echo "[NEXUS][INFO] Coletando ps -ef de $host_id via $access_method..."

  if collect_ps "$access_method" "$gateway" "$target" > "$tmp_file" 2>"$tmp_file.err"; then
    if [[ -s "$tmp_file" ]]; then
      mv "$tmp_file" "$output_path"
      rm -f "$tmp_file.err"
      echo "[NEXUS][OK] Evidência atualizada: $output_file"
      success_count=$((success_count + 1))
    else
      rm -f "$tmp_file" "$tmp_file.err" "$output_path"
      echo "[NEXUS][WARN] Coleta vazia para $host_id. Evidência removida para gerar WAIT." >&2
      fail_count=$((fail_count + 1))
    fi
  else
    rm -f "$tmp_file" "$tmp_file.err" "$output_path"
    echo "[NEXUS][WARN] Falha na coleta de $host_id. Evidência removida para gerar WAIT." >&2
    fail_count=$((fail_count + 1))
  fi
done

echo "[NEXUS] Coleta remote ps finalizada."
