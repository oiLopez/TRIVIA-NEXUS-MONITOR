#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: collector_rede_ab.sh
# Descrição: Coletor de status das redes A e B.
# Autor: miyo
# Versão: 0.1.0
# Dependências: bash, ping, coreutils
# Saída: backend/data/events/nexus_events.csv
# ==============================================================================

set -euo pipefail

# Diretório onde este coletor está localizado:
# backend/collectors/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diretório backend:
# backend/
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Carrega biblioteca core de eventos.
source "$BACKEND_DIR/core/nexus_db.sh"

HOSTNAME_LOCAL="$(hostname)"
MODULO="REDE_AB"

# Ambiente de simulação:
# Rede A usa localhost e deve retornar OK.
# Rede B usa IP inválido/simulado e deve retornar CRITICAL.
IP_REDE_A="127.0.0.1"
IP_REDE_B="192.0.2.60"

check_network() {
    local interface="$1"
    local ip="$2"

    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "OK" \
            "STATUS_${interface}" \
            "UP" \
            "Rede operacional."
    else
        nexus_db_insert \
            "$HOSTNAME_LOCAL" \
            "$MODULO" \
            "CRITICAL" \
            "STATUS_${interface}" \
            "DOWN" \
            "Falha de comunicação com IP $ip."
    fi
}

main() {
    check_network "REDE_A" "$IP_REDE_A"
    check_network "REDE_B" "$IP_REDE_B"
}

main "$@"
