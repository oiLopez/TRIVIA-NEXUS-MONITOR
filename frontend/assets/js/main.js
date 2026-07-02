// =========================================================
// NEXUS MONITOR - TRIVIA TRENS (Linhas 11 e 12)
// Lógica de Atualização em Tempo Real e HA (High Availability)
// =========================================================

// Caminhos dos arquivos CSV gerados pelos seus scripts Bash
const PATH_STATUS = '../backend/data/status.csv'; // Ajuste o caminho se a sua pasta data ficar em outro lugar
const PATH_VIRT = '../backend/data/virtualizacao/estado_atual.csv';

// Função auxiliar para atualizar o status visual de um Node (Servidor/Consola/WS)
function updateNodeStatus(hostname, status) {
    const badge = document.getElementById('st-' + hostname.toLowerCase());
    if (!badge) return; // Se a máquina não estiver no HTML, ignora

    if (status === 'ONLINE') {
        badge.textContent = 'ONLINE';
        badge.className = 'badge status-ok';
    } else if (status === 'OFFLINE') {
        badge.textContent = 'OFFLINE';
        badge.className = 'badge status-crit';
    } else {
        badge.textContent = status;
        badge.className = 'badge status-wait';
    }
}

// Função para atualizar a Tag de Host (LDOM) das Zonas Móveis
function updateFloatingHost(hostname, ldomsArray) {
    const hostTag = document.getElementById('host-' + hostname.toLowerCase());
    if (!hostTag) return;

    if (ldomsArray.length === 0) {
        hostTag.textContent = 'OFF';
        hostTag.className = 'host-tag';
    } 
    else if (ldomsArray.length === 1) {
        const ldom = ldomsArray[0]; // 'LDOM1' ou 'LDOM2'
        hostTag.textContent = ldom;
        hostTag.className = 'host-tag ' + (ldom === 'LDOM1' ? 'host-ldom1' : 'host-ldom2');
    } 
    else {
        // PERIGO: Máquina rodando em mais de uma LDOM (Split-Brain)
        hostTag.textContent = 'SPLIT-BRAIN';
        hostTag.className = 'host-tag host-split';
        console.error(`ALERTA CRÍTICO: ${hostname} em Split-Brain!`);
        // Aqui você pode adicionar um alert() ou mostrar um Modal vermelho na tela
    }
}

// 1. Coleta o Status de Ping (ONLINE/OFFLINE)
async function fetchStatus() {
    try {
        const response = await fetch(PATH_STATUS + '?t=' + Date.now()); // Evita cache
        if (!response.ok) throw new Error('CSV não encontrado');
        
        const text = await response.text();
        const lines = text.split('\n').filter(line => line.trim() !== '' && !line.startsWith('data_hora'));
        
        lines.forEach(line => {
            // Formato: data_hora;tipo;nome;ip;status
            const cols = line.split(';');
            if (cols.length >= 5) {
                updateNodeStatus(cols[2], cols[4]);
            }
        });
    } catch (error) {
        console.warn("Aguardando coleta de status...");
    }
}

// 2. Coleta o Estado da Virtualização (Onde as Zonas Móveis estão rodando)
async function fetchVirtualization() {
    try {
        const response = await fetch(PATH_VIRT + '?t=' + Date.now());
        if (!response.ok) return; // Se o arquivo ainda não existir, ignora
        
        const text = await response.text();
        const lines = text.split('\n').filter(line => line.trim() !== '');
        
        // Mapeia onde cada IHM está rodando
        // Exemplo: { 'cptm1': ['LDOM1'], 'sme3': ['LDOM1', 'LDOM2'] }
        const hostMap = {};

        lines.forEach(line => {
            // Formato: CPTM1;LDOM1 ou CPTM1B;LDOM2
            const [vmNameUpper, ldom] = line.split(';');
            if (!vmNameUpper || !ldom) return;

            // Remove o 'B' do final se for a rede redundante, para unificarmos a visualização no card
            const baseName = vmNameUpper.replace(/B$/, '').toLowerCase();

            if (!hostMap[baseName]) hostMap[baseName] = [];
            
            // Só adiciona a LDOM se ela já não estiver na lista (evita duplicação se A e B estiverem na mesma LDOM)
            if (!hostMap[baseName].includes(ldom.toUpperCase())) {
                hostMap[baseName].push(ldom.toUpperCase());
            }
        });

        // Agora atualiza o HTML para cada zona móvel detectada
        for (const [hostname, ldoms] of Object.entries(hostMap)) {
            updateFloatingHost(hostname, ldoms);
        }

    } catch (error) {
        console.warn("Aguardando coleta de virtualização...");
    }
}

// =========================================================
// LOOP PRINCIPAL DE ATUALIZAÇÃO (A cada 5 segundos)
// =========================================================
function refreshDashboard() {
    fetchStatus();
    fetchVirtualization();
}

// Roda a primeira vez imediatamente, depois a cada 5 segundos
refreshDashboard();
setInterval(refreshDashboard, 5000);

// Caminho do CSV gerado pelo simulador
const PATH_HA = '../backend/data/current/status_ldom.csv'; 

async function loadClusterState() {
    try {
        const response = await fetch(PATH_HA + '?t=' + Date.now());
        if (!response.ok) throw new Error('Arquivo não encontrado');
        
        const text = await response.text();
        const lines = text.split('\n');
        
        lines.forEach(line => {
            const cols = line.split(';');
            if (cols.length >= 3 && !line.startsWith('hostname')) {
                const hostname = cols[0].trim().toLowerCase();
                const ldom = cols[1].trim().toLowerCase();
                const status = cols[2].trim().toUpperCase();
                
                // Monta o ID exato, ex: "cptm1-ldom1"
                const badge = document.getElementById(`${hostname}-${ldom}`);
                
                if (badge) {
                    badge.textContent = status;
                    
                    if (status === 'ATIVO' || status === 'ONLINE') {
                        badge.className = 'badge status-ok';
                    } else if (status === 'STANDBY' || status === 'RESERVA') {
                        badge.className = 'badge status-standby';
                    } else if (status === 'OFFLINE' || status === 'FALHA') {
                        badge.className = 'badge status-crit';
                    }
                }
            }
        });
    } catch (error) {
        console.warn("Aguardando simulador...");
    }
}

// Atualiza o painel a cada 2 segundos para fins de teste
setInterval(loadClusterState, 2000);
loadClusterState();