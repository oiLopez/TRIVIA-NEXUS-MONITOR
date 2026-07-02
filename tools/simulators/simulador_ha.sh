#!/bin/bash
DATA_DIR="$HOME/nexus-monitor/backend/data"
ARQ="$DATA_DIR/current/status_ldom.csv"
mkdir -p "$DATA_DIR"

# Cabeçalho padrão
echo "hostname;ldom;status;uptime" > "$ARQ"

# --- INFRAESTRUTURA GLOBAL ---
echo "ilom1;infra;ONLINE;365d 11h" >> "$ARQ"
echo "control1;infra;ONLINE;180d 05h" >> "$ARQ"
echo "ldom1;infra;ONLINE;142d 08h" >> "$ARQ"
echo "ilom2;infra;ONLINE;365d 10h" >> "$ARQ"
echo "control2;infra;ONLINE;180d 04h" >> "$ARQ"
echo "ldom2;infra;ONLINE;142d 08h" >> "$ARQ"

# --- SERVIDORES FIXOS ---
echo "sft1;LDOM1;ONLINE;142d 08h" >> "$ARQ"
echo "metrosp44;LDOM1;ONLINE;142d 08h" >> "$ARQ"
echo "sft2;LDOM2;RESERVA;142d 07h" >> "$ARQ"
echo "metrosp45;LDOM2;RESERVA;142d 07h" >> "$ARQ"

# --- CONSOLAS MÓVEIS ---
echo "cptm1;LDOM1;ATIVO;45d 12h" >> "$ARQ"
echo "cptm1;LDOM2;STANDBY;45d 12h" >> "$ARQ"
echo "cptm2;LDOM1;ATIVO;45d 12h" >> "$ARQ"
echo "cptm2;LDOM2;STANDBY;45d 12h" >> "$ARQ"
echo "sme3;LDOM1;ATIVO;12d 03h" >> "$ARQ"
echo "sme3;LDOM2;STANDBY;12d 03h" >> "$ARQ"
echo "cons1;LDOM1;ATIVO;08d 22h" >> "$ARQ"
echo "cons1;LDOM2;STANDBY;08d 22h" >> "$ARQ"
echo "cptm3;LDOM1;STANDBY;33d 10h" >> "$ARQ"
echo "cptm3;LDOM2;ATIVO;33d 10h" >> "$ARQ"
echo "cptm4;LDOM1;STANDBY;33d 10h" >> "$ARQ"
echo "cptm4;LDOM2;ATIVO;33d 10h" >> "$ARQ"
echo "cons5;LDOM1;STANDBY;02d 15h" >> "$ARQ"
echo "cons5;LDOM2;ATIVO;02d 15h" >> "$ARQ"
echo "cptm12;LDOM1;STANDBY;18d 05h" >> "$ARQ"
echo "cptm12;LDOM2;ATIVO;18d 05h" >> "$ARQ"

# --- WORKSTATIONS FÍSICAS (Marcadas como 'ws' na coluna ldom) ---
echo "ws11;ws;ATIVO;15d 02h" >> "$ARQ"
echo "ws12;ws;ATIVO;28d 11h" >> "$ARQ"
echo "ws13;ws;ATIVO;04d 19h" >> "$ARQ"
echo "ws21;ws;ATIVO;41d 06h" >> "$ARQ"
echo "ws22;ws;ATIVO;12d 23h" >> "$ARQ"
echo "ws23;ws;STANDBY;02d 01h" >> "$ARQ"
echo "ws24;ws;ATIVO;89d 14h" >> "$ARQ"
echo "ws25;ws;FALHA;-" >> "$ARQ"

echo "Simulacao com todas as Workstations atualizada!"
