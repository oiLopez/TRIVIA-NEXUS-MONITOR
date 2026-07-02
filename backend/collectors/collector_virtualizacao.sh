#!/bin/bash
BASE="/home/prodix/nexus-monitor"
ARQ_ATUAL="$BASE/data/virtualizacao/estado_atual.csv"
ARQ_HIST="$BASE/logs/virtualizacao/historico_migracoes.csv"
mkdir -p "$BASE/data/virtualizacao" "$BASE/logs/virtualizacao"

TMP1="/tmp/nexus_ldom1.$$"
TMP2="/tmp/nexus_ldom2.$$"
NOVO="/tmp/nexus_estado_novo.$$"

SSH_OPTS="-n -x -q -o LogLevel=ERROR -o Tunnel=no -o ForwardX11=no -o ClearAllForwardings=yes -o ConnectTimeout=8"

# Bate nos IPs dos Control Domains (control1 e control2)
ssh $SSH_OPTS root@192.0.2.31 "zoneadm list -cv" > "$TMP1" 2>/dev/null
ssh $SSH_OPTS root@192.0.2.33 "zoneadm list -cv" > "$TMP2" 2>/dev/null

# Filtra pelas máquinas exatas do seu ficheiro TXT
(grep "running" "$TMP1" | awk '{print toupper($2) ";LDOM1"}'; grep "running" "$TMP2" | awk '{print toupper($2) ";LDOM2"}') | egrep "SFT1|SFT1B|SFT2|SFT2B|METROSP44|METROSP44B|METROSP45|METROSP45B|SME3|SME3B|CONS1|CONS1B|CONS5|CONS5B|CPTM1|CPTM1B|CPTM2|CPTM2B|CPTM3|CPTM3B|CPTM4|CPTM4B|CPTM12|CPTM12B" | sort > "$NOVO"

[ ! -f "$ARQ_ATUAL" ] && cp "$NOVO" "$ARQ_ATUAL"

rm -f "$TMP1" "$TMP2"
