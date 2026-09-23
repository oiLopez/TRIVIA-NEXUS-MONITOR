#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Simulador dos canais de Rede A/B para a aba Topologia.
#
# Uso:
#   tools/simulators/simulador_rede_ab.sh normal
#   tools/simulators/simulador_rede_ab.sh b_down CPTM2
#   tools/simulators/simulador_rede_ab.sh a_unstable WS24
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
COLLECTOR="$PROJECT_DIR/backend/collectors/collector_rede_ab.sh"

SCENARIO="${1:-normal}"
TARGET="${2:-CPTM2}"

if [[ ! -x "$COLLECTOR" ]]; then
    echo "[NEXUS][ERRO] Collector não executável: $COLLECTOR" >&2
    echo "Execute: chmod +x backend/collectors/collector_rede_ab.sh" >&2
    exit 1
fi

case "$SCENARIO" in
    normal|a_down|b_down|both_down|a_unstable|b_unstable|a_unstable_b_down|b_unstable_a_down)
        ;;
    *)
        echo "[NEXUS][ERRO] Cenário inválido: $SCENARIO" >&2
        echo "Cenários: normal, a_down, b_down, both_down, a_unstable, b_unstable, a_unstable_b_down, b_unstable_a_down" >&2
        exit 2
        ;;
esac

echo "[NEXUS][SIM] cenário=$SCENARIO alvo=${TARGET^^}"

exec "$COLLECTOR" \
    --mode simulated \
    --scenario "$SCENARIO" \
    --target "$TARGET"
