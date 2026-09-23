#!/bin/bash
# ==============================================================================
# NEXUS MONITOR
# Arquivo: collector_rede_ab.sh
# Descrição: Coleta/simula o estado das Redes A/B de Workstations e Prodix.
# Versão: 0.2.0
#
# Saídas:
#   - backend/data/runtime/network_channel_status.csv
#   - backend/data/events/nexus_events.csv (somente transições de estado)
#
# Modos:
#   --mode simulated  (padrão seguro para desenvolvimento)
#   --mode real       (executa ping nos IPs do inventário)
#
# Exemplos:
#   collector_rede_ab.sh --mode simulated --scenario normal
#   collector_rede_ab.sh --mode simulated --scenario b_down --target CPTM2
#   collector_rede_ab.sh --mode real
# ==============================================================================

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"

CONFIG_FILE="${NEXUS_HOSTS_CONFIG:-$BACKEND_DIR/config/nexus_hosts.config}"
RUNTIME_DIR="${NEXUS_RUNTIME_DIR:-$BACKEND_DIR/data/runtime}"
OUTPUT_FILE="${NEXUS_NETWORK_STATUS_FILE:-$RUNTIME_DIR/network_channel_status.csv}"
EVENTS_LIB="$BACKEND_DIR/core/nexus_db.sh"

MODE="${NEXUS_REDE_AB_MODE:-simulated}"
SCENARIO="${NEXUS_REDE_AB_SCENARIO:-normal}"
TARGET="${NEXUS_REDE_AB_TARGET:-CPTM2}"
PING_COUNT="${NEXUS_REDE_AB_PING_COUNT:-3}"
PING_TIMEOUT="${NEXUS_REDE_AB_PING_TIMEOUT:-1}"
WINDOW_SECONDS="${NEXUS_REDE_AB_WINDOW_SECONDS:-30}"

HEADER='timestamp;asset_id;asset_name;asset_type;parent_asset;ldom;channel;ip_address;technical_comm;stability_status;loss_count;window_seconds;latency_ms;message'

usage() {
    cat <<'EOF'
Uso:
  collector_rede_ab.sh [opções]

Opções:
  --mode simulated|real
  --scenario normal|a_down|b_down|both_down|a_unstable|b_unstable|a_unstable_b_down|b_unstable_a_down
  --target ASSET
  --help

Exemplos:
  collector_rede_ab.sh --mode simulated --scenario normal
  collector_rede_ab.sh --mode simulated --scenario b_down --target CPTM2
  collector_rede_ab.sh --mode simulated --scenario a_unstable --target WS24
  collector_rede_ab.sh --mode real
EOF
}

while (($#)); do
    case "$1" in
        --mode)
            MODE="${2:-}"
            shift 2
            ;;
        --scenario)
            SCENARIO="${2:-}"
            shift 2
            ;;
        --target)
            TARGET="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[NEXUS][ERRO] Argumento desconhecido: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

MODE="${MODE,,}"
SCENARIO="${SCENARIO,,}"
TARGET="${TARGET^^}"

case "$MODE" in
    simulated|real) ;;
    *)
        echo "[NEXUS][ERRO] Modo inválido: $MODE" >&2
        exit 2
        ;;
esac

case "$SCENARIO" in
    normal|a_down|b_down|both_down|a_unstable|b_unstable|a_unstable_b_down|b_unstable_a_down) ;;
    *)
        echo "[NEXUS][ERRO] Cenário inválido: $SCENARIO" >&2
        exit 2
        ;;
esac

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "[NEXUS][ERRO] Inventário não encontrado: $CONFIG_FILE" >&2
    exit 1
fi

mkdir -p "$RUNTIME_DIR"

if [[ -r "$EVENTS_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$EVENTS_LIB"
fi

timestamp_now() {
    date '+%Y-%m-%d %H:%M:%S'
}

normalize_asset_name() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

prodix_parent_ws() {
    case "${1^^}" in
        SME3)   printf 'WS11' ;;
        CONS1)  printf 'WS12' ;;
        CONS5)  printf 'WS13' ;;
        CPTM4)  printf 'WS21' ;;
        CPTM12) printf 'WS22' ;;
        CPTM1)  printf 'WS23' ;;
        CPTM2)  printf 'WS24' ;;
        CPTM3)  printf 'WS25' ;;
        *)      printf '' ;;
    esac
}

prodix_description() {
    case "${1^^}" in
        SME3)   printf 'MANUTENCAO' ;;
        CONS1)  printf 'EBILOCK - Bras - Luz' ;;
        CONS5)  printf 'MICROLOCK - Luz - BFU' ;;
        CPTM4)  printf 'MANUTENCAO' ;;
        CPTM12) printf 'CONS - L-11 EXT' ;;
        CPTM1)  printf 'CONA - L-11 EXP' ;;
        CPTM2)  printf 'CONB - L-12' ;;
        CPTM3)  printf 'CONC - Cabine de rotas (TAT - SGU)' ;;
        *)      printf 'Aplicacao Prodix' ;;
    esac
}

is_supported_prodix() {
    case "${1^^}" in
        SME3|CONS1|CONS5|CPTM4|CPTM12|CPTM1|CPTM2|CPTM3) return 0 ;;
        *) return 1 ;;
    esac
}

is_supported_ws() {
    case "${1^^}" in
        WS11|WS12|WS13|WS21|WS22|WS23|WS24|WS25) return 0 ;;
        *) return 1 ;;
    esac
}

simulation_state() {
    local asset="$1"
    local channel="$2"

    SIM_TECHNICAL="OK"
    SIM_STABILITY="OK"
    SIM_LOSS="0"
    SIM_LATENCY="2"
    SIM_MESSAGE="Canal simulado operacional."

    if [[ "${asset^^}" != "$TARGET" ]]; then
        return 0
    fi

    case "$SCENARIO" in
        normal)
            ;;
        a_down)
            [[ "$channel" == "A" ]] || return 0
            SIM_TECHNICAL="FALHA"
            SIM_STABILITY="FALHA"
            SIM_LOSS="$PING_COUNT"
            SIM_LATENCY=""
            SIM_MESSAGE="Rede A simulada indisponivel."
            ;;
        b_down)
            [[ "$channel" == "B" ]] || return 0
            SIM_TECHNICAL="FALHA"
            SIM_STABILITY="FALHA"
            SIM_LOSS="$PING_COUNT"
            SIM_LATENCY=""
            SIM_MESSAGE="Rede B simulada indisponivel."
            ;;
        both_down)
            SIM_TECHNICAL="FALHA"
            SIM_STABILITY="FALHA"
            SIM_LOSS="$PING_COUNT"
            SIM_LATENCY=""
            SIM_MESSAGE="Canal simulado indisponivel."
            ;;
        a_unstable)
            [[ "$channel" == "A" ]] || return 0
            SIM_TECHNICAL="OK"
            SIM_STABILITY="INSTAVEL"
            SIM_LOSS="1"
            SIM_LATENCY="38"
            SIM_MESSAGE="Rede A simulada com perda/oscilacao."
            ;;
        b_unstable)
            [[ "$channel" == "B" ]] || return 0
            SIM_TECHNICAL="OK"
            SIM_STABILITY="INSTAVEL"
            SIM_LOSS="1"
            SIM_LATENCY="41"
            SIM_MESSAGE="Rede B simulada com perda/oscilacao."
            ;;
        a_unstable_b_down)
            if [[ "$channel" == "A" ]]; then
                SIM_TECHNICAL="OK"
                SIM_STABILITY="INSTAVEL"
                SIM_LOSS="1"
                SIM_LATENCY="45"
                SIM_MESSAGE="Rede A simulada instavel."
            else
                SIM_TECHNICAL="FALHA"
                SIM_STABILITY="FALHA"
                SIM_LOSS="$PING_COUNT"
                SIM_LATENCY=""
                SIM_MESSAGE="Rede B simulada indisponivel."
            fi
            ;;
        b_unstable_a_down)
            if [[ "$channel" == "B" ]]; then
                SIM_TECHNICAL="OK"
                SIM_STABILITY="INSTAVEL"
                SIM_LOSS="1"
                SIM_LATENCY="45"
                SIM_MESSAGE="Rede B simulada instavel."
            else
                SIM_TECHNICAL="FALHA"
                SIM_STABILITY="FALHA"
                SIM_LOSS="$PING_COUNT"
                SIM_LATENCY=""
                SIM_MESSAGE="Rede A simulada indisponivel."
            fi
            ;;
    esac
}

probe_real() {
    local ip="$1"
    local output rc loss_pct received avg_ms

    REAL_TECHNICAL="WAIT"
    REAL_STABILITY="WAIT"
    REAL_LOSS="$PING_COUNT"
    REAL_LATENCY=""
    REAL_MESSAGE="Coleta nao realizada."

    set +e
    output="$(ping -n -c "$PING_COUNT" -W "$PING_TIMEOUT" "$ip" 2>&1)"
    rc=$?
    set -e

    loss_pct="$(printf '%s\n' "$output" | awk -F', ' '/packet loss/ {gsub(/% packet loss.*/, "", $3); print $3; exit}')"
    received="$(printf '%s\n' "$output" | awk '/packets transmitted/ {print $4; exit}')"
    avg_ms="$(printf '%s\n' "$output" | awk -F'=' '/^rtt |^round-trip / {gsub(/^ +| +$/, "", $2); split($2,a,"/"); print a[2]; exit}')"

    if [[ "$loss_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        if awk "BEGIN{exit !($loss_pct >= 100)}"; then
            REAL_TECHNICAL="FALHA"
            REAL_STABILITY="FALHA"
            REAL_MESSAGE="Sem resposta ao ping."
        elif awk "BEGIN{exit !($loss_pct > 0)}"; then
            REAL_TECHNICAL="OK"
            REAL_STABILITY="INSTAVEL"
            REAL_MESSAGE="Canal responde com perda de pacotes."
        else
            REAL_TECHNICAL="OK"
            REAL_STABILITY="OK"
            REAL_MESSAGE="Canal operacional."
        fi

        if [[ "$received" =~ ^[0-9]+$ ]]; then
            REAL_LOSS=$(( PING_COUNT - received ))
            (( REAL_LOSS < 0 )) && REAL_LOSS=0
        fi

        REAL_LATENCY="$avg_ms"
        return 0
    fi

    if (( rc == 0 )); then
        REAL_TECHNICAL="OK"
        REAL_STABILITY="OK"
        REAL_LOSS="0"
        REAL_LATENCY="$avg_ms"
        REAL_MESSAGE="Canal operacional."
    else
        REAL_TECHNICAL="FALHA"
        REAL_STABILITY="FALHA"
        REAL_MESSAGE="Falha ao consultar canal."
    fi
}

event_severity() {
    case "$1" in
        OK)       printf 'OK' ;;
        INSTAVEL) printf 'ALERTA' ;;
        FALHA)    printf 'CRITICO' ;;
        *)        printf 'INFO' ;;
    esac
}

emit_event_if_changed() {
    local previous_file="$1"
    local asset="$2"
    local channel="$3"
    local technical="$4"
    local stability="$5"
    local previous

    [[ -r "$previous_file" ]] || return 0
    declare -F nexus_db_insert >/dev/null 2>&1 || return 0

    previous="$(
        awk -F';' -v asset="$asset" -v channel="$channel" '
            NR > 1 && toupper($3) == toupper(asset) && toupper($7) == toupper(channel) {
                print $9 ";" $10
                exit
            }
        ' "$previous_file"
    )"

    [[ -n "$previous" ]] || return 0
    [[ "$previous" == "$technical;$stability" ]] && return 0

    local severity metric value message
    severity="$(event_severity "$stability")"
    metric="REDE_${channel}"
    value="${technical}:${stability}"
    message="${asset} Rede ${channel}: ${previous} -> ${technical};${stability}."

    nexus_db_insert \
        "$asset" \
        "REDE_AB" \
        "$severity" \
        "$metric" \
        "$value" \
        "$message"
}

append_row() {
    local tmp_file="$1"
    local previous_file="$2"
    local asset_name="$3"
    local asset_type="$4"
    local parent_asset="$5"
    local channel="$6"
    local ip="$7"

    local technical stability loss latency message
    if [[ "$MODE" == "simulated" ]]; then
        simulation_state "$asset_name" "$channel"
        technical="$SIM_TECHNICAL"
        stability="$SIM_STABILITY"
        loss="$SIM_LOSS"
        latency="$SIM_LATENCY"
        message="$SIM_MESSAGE"
    else
        probe_real "$ip"
        technical="$REAL_TECHNICAL"
        stability="$REAL_STABILITY"
        loss="$REAL_LOSS"
        latency="$REAL_LATENCY"
        message="$REAL_MESSAGE"
    fi

    local asset_id ts
    asset_id="$(printf '%s' "$asset_name" | tr '[:upper:]' '[:lower:]')"
    ts="$(timestamp_now)"

    printf '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n' \
        "$ts" \
        "$asset_id" \
        "$asset_name" \
        "$asset_type" \
        "$parent_asset" \
        "BOTH" \
        "$channel" \
        "$ip" \
        "$technical" \
        "$stability" \
        "$loss" \
        "$WINDOW_SECONDS" \
        "$latency" \
        "$message" >> "$tmp_file"

    emit_event_if_changed \
        "$previous_file" "$asset_name" "$channel" "$technical" "$stability"
}

collect_inventory() {
    local tmp_file="$1"
    local previous_file="$2"
    local type name ip f4 f5 f6 f7 rest base channel asset parent

    declare -A seen_ws_channel=()
    declare -A seen_prodix_channel=()
    declare -A ws_occurrence=()

    while IFS=';' read -r type name ip f4 f5 f6 f7 rest; do
        [[ -n "${type:-}" ]] || continue
        [[ "$type" == \#* ]] && continue

        if [[ "$type" == "WS" ]]; then
            asset="$(normalize_asset_name "$name")"
            is_supported_ws "$asset" || continue

            # No inventário atual, cada WS aparece duas vezes:
            # primeira ocorrência = Rede A; segunda ocorrência = Rede B.
            local occurrence="${ws_occurrence[$asset]:-0}"
            occurrence=$(( occurrence + 1 ))
            ws_occurrence["$asset"]="$occurrence"

            if (( occurrence == 1 )); then
                channel="A"
            elif (( occurrence == 2 )); then
                channel="B"
            else
                continue
            fi

            [[ -z "${seen_ws_channel[$asset:$channel]:-}" ]] || continue
            seen_ws_channel["$asset:$channel"]=1
            append_row "$tmp_file" "$previous_file" "$asset" "WORKSTATION" "" "$channel" "$ip"
            continue
        fi

        if [[ "$type" == "ZONE_MOVEL" ]]; then
            base="${name,,}"
            if [[ "$base" == *b ]]; then
                channel="B"
                base="${base%b}"
            else
                channel="A"
            fi

            asset="$(normalize_asset_name "$base")"
            is_supported_prodix "$asset" || continue

            [[ -z "${seen_prodix_channel[$asset:$channel]:-}" ]] || continue
            seen_prodix_channel["$asset:$channel"]=1
            parent="$(prodix_parent_ws "$asset")"
            append_row "$tmp_file" "$previous_file" "$asset" "PRODIX" "$parent" "$channel" "$ip"
        fi
    done < "$CONFIG_FILE"
}

validate_snapshot() {
    local file="$1"
    local rows
    rows=$(( $(wc -l < "$file") - 1 ))

    if (( rows != 32 )); then
        echo "[NEXUS][ERRO] Snapshot incompleto: esperado 32 canais, encontrado $rows." >&2
        return 1
    fi

    local duplicate_count
    duplicate_count="$(
        awk -F';' '
            NR > 1 {
                key=toupper($3) "|" toupper($7)
                count[key]++
            }
            END {
                d=0
                for (k in count) if (count[k] != 1) d++
                print d
            }
        ' "$file"
    )"

    if (( duplicate_count != 0 )); then
        echo "[NEXUS][ERRO] Snapshot possui canais duplicados/ausentes." >&2
        return 1
    fi
}

main() {
    local previous_file tmp_file
    previous_file="$OUTPUT_FILE"
    tmp_file="$(mktemp "$RUNTIME_DIR/.network_channel_status.XXXXXX")"
    trap 'rm -f "$tmp_file"' EXIT

    printf '%s\n' "$HEADER" > "$tmp_file"
    collect_inventory "$tmp_file" "$previous_file"
    validate_snapshot "$tmp_file"

    mv "$tmp_file" "$OUTPUT_FILE"
    trap - EXIT

    echo "[NEXUS][OK] network_channel_status atualizado: $OUTPUT_FILE"
    echo "[NEXUS][INFO] modo=$MODE scenario=$SCENARIO target=$TARGET canais=32"
}

main "$@"
