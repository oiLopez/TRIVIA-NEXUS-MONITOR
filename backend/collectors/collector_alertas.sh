#!/bin/bash
BASE="/home/prodix/nexus-monitor"
STATUS="$BASE/data/status.csv"
VIRT="$BASE/data/virtualizacao/estado_atual.csv"
ALERTAS="$BASE/data/alertas/alertas_ativos.csv"
HIST="$BASE/logs/alertas_historico.csv"

mkdir -p "$BASE/data/alertas" "$BASE/logs"
DATA=$(date '+%Y-%m-%d %H:%M:%S')

echo "data_hora;nivel;origem;mensagem" > "$ALERTAS"
[ ! -f "$HIST" ] && echo "data_hora;nivel;origem;mensagem" > "$HIST"

registrar_alerta() { 
    echo "$DATA;$1;$2;$3" >> "$ALERTAS"
    echo "$DATA;$1;$2;$3" >> "$HIST"
}

# Verifica Status Offline
[ -f "$STATUS" ] && tail -n +2 "$STATUS" | while IFS=";" read D TIPO NOME IP ST; do 
    [ "$ST" != "ONLINE" ] && registrar_alerta "CRITICO" "$NOME" "$TIPO $NOME esta OFFLINE - IP $IP"
done

# Valida se SFT1 e SFT2 estão nas LDOMs corretas
if [ -f "$VIRT" ]; then
    SFT1_LDOM=$(grep "^SFT1;" "$VIRT" | cut -d';' -f2)
    SFT2_LDOM=$(grep "^SFT2;" "$VIRT" | cut -d';' -f2)
    
    [ "$SFT1_LDOM" != "LDOM1" ] && [ -n "$SFT1_LDOM" ] && registrar_alerta "CRITICO" "SFT1" "SFT1 deveria estar na LDOM1, mas esta em $SFT1_LDOM"
    [ "$SFT2_LDOM" != "LDOM2" ] && [ -n "$SFT2_LDOM" ] && registrar_alerta "CRITICO" "SFT2" "SFT2 deveria estar na LDOM2, mas esta em $SFT2_LDOM"
fi
