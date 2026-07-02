#!/bin/bash
BASE="/home/prodix/nexus-monitor"
DATA="$BASE/data"
TMP="$BASE/tmp"
mkdir -p "$DATA" "$TMP"

# Variáveis exatas do seu ficheiro nexus_hosts.txt
SFT_HOSTS="sft1 sft1b sft2 sft2b metrosp44 metrosp44b metrosp45 metrosp45b"
PAINEL_HOSTS="sme3 sme3b cons1 cons1b cons5 cons5b cptm1 cptm1b cptm2 cptm2b cptm3 cptm3b cptm4 cptm4b cptm12 cptm12b"

SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=6 -o StrictHostKeyChecking=no"

detect_sft() {
  H="$1"
  OUT="$TMP/${H}_processos.txt"
  ssh $SSH_OPTS "$H" 'pgrep -f "sb_envia|sb_recebe|sb_watchdog|sb_ping|bac_eth" > /dev/null && echo "ATIVO" || echo "STANDBY"; exit 0' > "$OUT" 2>/dev/null
  RC=$?
  if [ "$RC" -ne 0 ]; then
    echo "$(echo "$H" | tr a-z A-Z);OFFLINE;0;SSH_FALHA"
    return
  fi
  RES=$(cat "$OUT")
  echo "$(echo "$H" | tr a-z A-Z);$RES;1;SFT_$RES"
}

detect_painel() {
  H="$1"
  OUT="$TMP/${H}_painel.txt"
  ssh $SSH_OPTS "$H" 'pgrep -f painelcon > /dev/null && echo "ATIVO" || echo "PARADO"; exit 0' > "$OUT" 2>/dev/null
  RC=$?
  if [ "$RC" -ne 0 ]; then
    echo "$(echo "$H" | tr a-z A-Z);OFFLINE;0;SSH_FALHA"
    return
  fi
  RES=$(cat "$OUT")
  echo "$(echo "$H" | tr a-z A-Z);$RES;1;PAINEL_$RES"
}

# SFT automático
{
  echo "nome;modo;processos;detalhe"
  for H in $SFT_HOSTS; do detect_sft "$H"; done
} > "$DATA/operacao_servidores.csv.tmp"
mv "$DATA/operacao_servidores.csv.tmp" "$DATA/operacao_servidores.csv"

# Painel automático
{
  echo "nome;modo;processos;detalhe"
  for H in $PAINEL_HOSTS; do detect_painel "$H"; done
} > "$DATA/painel_sinotico.csv.tmp"
mv "$DATA/painel_sinotico.csv.tmp" "$DATA/painel_sinotico.csv"
