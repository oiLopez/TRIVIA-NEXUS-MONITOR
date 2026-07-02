#!/bin/bash
set -euo pipefail
source ../core/nexus_db.sh

HOSTNAME=$(hostname)
MODULO="REDE_AB"

# Na simulação, faremos ping em um IP que sempre responde (localhost) e um que falha
IP_REDE_A="127.0.0.1"   # Vai dar OK
IP_REDE_B="192.0.2.60" # Vai dar CRITICAL

check_network() {
    local interface="$1"
    local ip="$2"
    
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        nexus_db_insert "$HOSTNAME" "$MODULO" "OK" "STATUS_${interface}" "UP" "Rede operacional (Simulado)."
    else
        nexus_db_insert "$HOSTNAME" "$MODULO" "CRITICAL" "STATUS_${interface}" "DOWN" "Falha na rota $ip (Simulado)."
    fi
}

check_network "REDE_A" "$IP_REDE_A"
check_network "REDE_B" "$IP_REDE_B"
