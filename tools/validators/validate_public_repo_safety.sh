#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

print_error() {
  echo "[NEXUS][ERRO] $*" >&2
  ERRORS=$((ERRORS + 1))
}

print_warn() {
  echo "[NEXUS][WARN] $*" >&2
}

print_ok() {
  echo "[NEXUS][OK] $*"
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  print_error "Este validador precisa ser executado dentro de um repositório Git."
fi

tracked_runtime="$(git ls-files 'backend/data/runtime/*' | grep -v '^backend/data/runtime/.gitkeep$' || true)"

if [[ -n "$tracked_runtime" ]]; then
  print_error "Arquivos runtime versionados encontrados:"
  echo "$tracked_runtime" >&2
else
  print_ok "Nenhum arquivo runtime sensível versionado."
fi

tracked_local_files="$(git ls-files | grep -Ei '(^|/).*(\.local|secret|senha|password|token)(\.|$)' || true)"

if [[ -n "$tracked_local_files" ]]; then
  print_error "Arquivos com nome potencialmente sensível versionados:"
  echo "$tracked_local_files" >&2
else
  print_ok "Nenhum arquivo local/segredo versionado por nome."
fi

is_allowed_ip() {
  local ip="$1"

  case "$ip" in
    192.0.2.*|198.51.100.*|203.0.113.*|127.0.0.1|0.0.0.0|255.255.255.255)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

ip_hits="$(git grep -nE '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)"

if [[ -n "$ip_hits" ]]; then
  while IFS= read -r line; do
    while IFS= read -r ip; do
      [[ -z "$ip" ]] && continue

      if ! is_allowed_ip "$ip"; then
        print_error "IP não permitido em repo público: $ip"
        echo "  $line" >&2
      fi
    done < <(printf '%s\n' "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)
  done <<< "$ip_hits"
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "[NEXUS][ERRO] Auditoria pública falhou com $ERRORS erro(s)." >&2
  exit 1
fi

print_ok "Auditoria pública do repositório validada."
