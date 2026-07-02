#!/bin/bash
# ==============================================================================
# NEXUS MONITOR ENTERPRISE
# Arquivo: nexus_db.sh
# Descrição: Biblioteca Core para gravação segura e padronizada em CSV.
# ==============================================================================

# Caminho do "Banco de Dados" e do arquivo de trava (Lock)
NEXUS_DB_FILE="../data/events/nexus_events.csv"
NEXUS_LOCK_FILE="/tmp/nexus_db.lock"

# Função que cria o cabeçalho do CSV se o arquivo não existir
nexus_db_init() {
    if [[ ! -f "$NEXUS_DB_FILE" ]]; then
        echo "TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM" > "$NEXUS_DB_FILE"
    fi
}

# Função que insere os dados de forma segura
nexus_db_insert() {
    local host="$1"
    local modulo="$2"
    local status="$3"
    local metrica="$4"
    local valor="$5"
    local mensagem="$6"
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local linha_csv="${timestamp};${host};${modulo};${status};${metrica};${valor};${mensagem}"

    # O flock garante que apenas um processo escreva por vez
    (
        flock -x 200
        echo "$linha_csv" >> "$NEXUS_DB_FILE"
    ) 200> "$NEXUS_LOCK_FILE"
}

# Sempre que esta biblioteca for chamada, ela garante que o banco existe
nexus_db_init
