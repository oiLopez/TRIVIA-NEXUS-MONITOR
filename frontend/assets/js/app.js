const PATH_HA = '../backend/data/current/status_ldom.csv'; 

async function loadClusterState() {
    try {
        const response = await fetch(PATH_HA + '?t=' + Date.now());
        if (!response.ok) throw new Error(`Arquivo não encontrado! Status: ${response.status}`);
        
        const text = await response.text();
        const lines = text.split('\n');
        
        let totalSistemas = 0;
        let sistemasOperacionais = 0;
        let alarmesCriticos = 0;
        let alarmesAltos = 0;
        let alarmesMedios = 0;
        let alarmesInfo = 0;

        lines.forEach(line => {
            const cols = line.split(';');
            
            if (cols.length >= 3 && !line.startsWith('hostname')) {
                const hostname = cols[0].trim().toLowerCase();
                const ldom = cols[1].trim().toLowerCase();
                const status = cols[2].trim().toUpperCase();
                const uptime = cols.length >= 4 ? cols[3].trim() : '-'; // RECUPERADO O UPTIME!
                
                let badge = null;
                let upTag = null;
                totalSistemas++;

                // MAPEAMENTO DE IDs
                if (ldom === 'infra' || ldom === 'ws') {
                    badge = document.getElementById(`status-${hostname}`);
                    upTag = document.getElementById(`up-${hostname}`);
                } else {
                    badge = document.getElementById(`${hostname}-${ldom}`);
                    upTag = document.getElementById(`up-${hostname}-${ldom}`);
                }
                
                // ATUALIZAÇÃO DOS BADGES
                if (badge) {
                    badge.textContent = status;
                    badge.className = 'badge'; 
                    
                    if (status === 'ATIVO' || status === 'ONLINE') {
                        badge.classList.add('status-ok');
                        sistemasOperacionais++;
                    } else if (status === 'STANDBY' || status === 'RESERVA') {
                        badge.classList.add('status-standby');
                        sistemasOperacionais++; 
                        alarmesInfo++;           
                    } else if (status === 'OFFLINE' || status === 'FALHA') {
                        badge.classList.add('status-crit');
                        alarmesCriticos++;       
                    } else {
                        badge.classList.add('status-wait');
                    }
                }

                // INJEÇÃO DO UPTIME EM TELA
                if (upTag) {
                    if (status !== 'OFFLINE' && status !== 'FALHA' && uptime !== '-') {
                        upTag.textContent = `⏱ ${uptime}`;
                        upTag.style.display = 'inline-block';
                    } else {
                        upTag.style.display = 'none';
                    }
                }

                // TELEMETRIA ILOM (Apenas ilustrativo / Alimenta os cards visuais)
                if (hostname === 'ilom1' || hostname === 'ilom2') {
                    const isOnline = (status === 'ONLINE');
                    const fans = document.getElementById(`${hostname}-fans`);
                    const temp = document.getElementById(`${hostname}-temp`);
                    const psu = document.getElementById(`${hostname}-psu`);
                    const cooling = document.getElementById(`${hostname}-cooling`);

                    if (fans) { fans.textContent = isOnline ? "OK (4200 RPM)" : "FALHA"; fans.className = isOnline ? "tel-ok" : "tel-crit"; }
                    if (temp) {
                        if (isOnline) {
                            temp.textContent = hostname === 'ilom1' ? "38°C" : "41°C";
                            temp.className = hostname === 'ilom1' ? "tel-ok" : "tel-alert";
                            if (hostname === 'ilom2') alarmesMedios++; 
                        } else {
                            temp.textContent = "--°C"; temp.className = "tel-crit";
                        }
                    }
                    if (psu) { psu.textContent = isOnline ? "A+B OK" : "FALHA"; psu.className = isOnline ? "tel-ok" : "tel-crit"; }
                    if (cooling) { cooling.textContent = isOnline ? "100%" : "0%"; cooling.className = isOnline ? "tel-ok" : "tel-crit"; }
                }

                // TELEMETRIA LDOM (Apenas ilustrativo / Alimenta os cards visuais)
                if (hostname === 'ldom1' || hostname === 'ldom2') {
                    const isOnline = (status === 'ONLINE');
                    const cpuText = document.getElementById(`${hostname}-cpu-text`);
                    const cpuBar = document.getElementById(`${hostname}-cpu-bar`);
                    const svcCount = document.getElementById(`${hostname}-services-count`);

                    let cpuTarget = 0; let numServicos = "0 Sistemas";
                    if (isOnline) {
                        if (hostname === 'ldom1') { cpuTarget = 42; numServicos = "8 Sistemas"; } 
                        else { cpuTarget = 12; numServicos = "2 Sistemas"; alarmesInfo++; }
                    }
                    if (cpuText) cpuText.textContent = `${cpuTarget}%`;
                    if (cpuBar) cpuBar.style.width = `${cpuTarget}%`;
                    if (svcCount) svcCount.textContent = numServicos;
                }
            }
        });

        // ATUALIZA PAINÉIS DE SUMÁRIO SUPERIORES
        if (totalSistemas > 0) {
            const percentualFuncional = ((sistemasOperacionais / totalSistemas) * 100).toFixed(1);
            const healthText = document.getElementById('global-health-percentage');
            const healthBar = document.querySelector('.progress-fill');
            if (healthText) healthText.textContent = `${percentualFuncional}%`;
            if (healthBar) healthBar.style.width = `${percentualFuncional}%`;
        }

        alarmesAltos = alarmesCriticos > 0 ? 1 : 0; 
        
        const elCrit = document.getElementById('count-crit');
        const elAlto = document.getElementById('count-alto');
        const elMedio = document.getElementById('count-medio');
        const elInfo = document.getElementById('count-info');

        if (elCrit) elCrit.textContent = alarmesCriticos;
        if (elAlto) elAlto.textContent = alarmesAltos;
        if (elMedio) elMedio.textContent = alarmesMedios;
        if (elInfo) elInfo.textContent = alarmesInfo;

    } catch (error) {
        console.error("⚠️ Falha ao ler o CSV do simulador:", error.message);
    }
}

setInterval(loadClusterState, 2000);
loadClusterState();