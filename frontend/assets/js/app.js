/* =========================================================
   NEXUS MONITOR - Dashboard Frontend v0.1
   Ambiente alvo: servidor local/offline, HTML/CSS/JavaScript puro.
   ========================================================= */

'use strict';

const NEXUS_CONFIG = Object.freeze({
  statusLdomCsv: '../backend/data/current/status_ldom.csv',
  refreshIntervalMs: 2000,
  clockIntervalMs: 1000,
});

const STATUS_GROUPS = Object.freeze({
  ok: ['ATIVO', 'ONLINE', 'OK', 'UP'],
  standby: ['STANDBY', 'RESERVA', 'BACKUP'],
  warning: ['ALERTA', 'ALERT', 'WARN', 'WARNING', 'DEGRADED', 'DEGRADADO'],
  critical: ['OFFLINE', 'FALHA', 'DOWN', 'CRITICAL', 'CRITICO', 'CRÍTICO'],
});

function getElement(id) {
  return document.getElementById(id);
}

function setText(id, value) {
  const element = getElement(id);
  if (element) {
    element.textContent = value;
  }
}

function setStatusBadge(element, status) {
  if (!element) {
    return;
  }

  const normalizedStatus = normalizeStatus(status);
  const statusGroup = getStatusGroup(normalizedStatus);

  element.textContent = normalizedStatus || 'WAIT';
  element.className = 'badge';

  if (statusGroup === 'ok') {
    element.classList.add('status-ok');
    return;
  }

  if (statusGroup === 'standby') {
    element.classList.add('status-standby');
    return;
  }

  if (statusGroup === 'warning') {
    element.classList.add('status-warn');
    return;
  }

  if (statusGroup === 'critical') {
    element.classList.add('status-crit');
    return;
  }

  element.classList.add('status-wait');
}

function normalizeStatus(status) {
  return String(status || '').trim().toUpperCase();
}

function getStatusGroup(status) {
  if (STATUS_GROUPS.ok.includes(status)) {
    return 'ok';
  }

  if (STATUS_GROUPS.standby.includes(status)) {
    return 'standby';
  }

  if (STATUS_GROUPS.warning.includes(status)) {
    return 'warning';
  }

  if (STATUS_GROUPS.critical.includes(status)) {
    return 'critical';
  }

  return 'unknown';
}

function isOperationalStatus(status) {
  const group = getStatusGroup(normalizeStatus(status));
  return group === 'ok' || group === 'standby';
}

function updateClock() {
  const clock = getElement('clock');
  if (!clock) {
    return;
  }

  const now = new Date();
  clock.textContent = now.toLocaleTimeString('pt-BR');
}

function parseCsv(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .filter((line) => !line.toLowerCase().startsWith('hostname'))
    .map((line) => {
      const columns = line.split(';').map((column) => column.trim());

      return {
        hostname: String(columns[0] || '').toLowerCase(),
        ldom: String(columns[1] || '').toLowerCase(),
        status: normalizeStatus(columns[2] || 'WAIT'),
        uptime: columns[3] || '-',
        raw: line,
      };
    })
    .filter((row) => row.hostname && row.ldom && row.status);
}

function resolveStatusTargets(row) {
  if (row.ldom === 'infra' || row.ldom === 'ws') {
    return {
      badgeId: `status-${row.hostname}`,
      uptimeId: `up-${row.hostname}`,
    };
  }

  return {
    badgeId: `${row.hostname}-${row.ldom}`,
    uptimeId: `up-${row.hostname}-${row.ldom}`,
  };
}

function updateUptime(id, status, uptime) {
  const uptimeTag = getElement(id);
  if (!uptimeTag) {
    return;
  }

  const group = getStatusGroup(status);
  const hasValidUptime = uptime && uptime !== '-';

  if ((group === 'ok' || group === 'standby') && hasValidUptime) {
    uptimeTag.textContent = `⏱ ${uptime}`;
    uptimeTag.style.display = 'inline-flex';
    return;
  }

  uptimeTag.textContent = '';
  uptimeTag.style.display = 'none';
}

function updateHostStatus(row) {
  const targets = resolveStatusTargets(row);
  const badge = getElement(targets.badgeId);

  setStatusBadge(badge, row.status);
  updateUptime(targets.uptimeId, row.status, row.uptime);
}

function updateIlomTelemetry(row) {
  if (row.hostname !== 'ilom1' && row.hostname !== 'ilom2') {
    return;
  }

  const group = getStatusGroup(row.status);
  const isOnline = group === 'ok' || group === 'standby';

  const fans = getElement(`${row.hostname}-fans`);
  const temp = getElement(`${row.hostname}-temp`);
  const psu = getElement(`${row.hostname}-psu`);
  const cooling = getElement(`${row.hostname}-cooling`);

  if (fans) {
    fans.textContent = isOnline ? 'OK' : 'FALHA';
    fans.className = isOnline ? 'tel-ok' : 'tel-crit';
  }

  if (temp) {
    if (isOnline) {
      temp.textContent = row.hostname === 'ilom1' ? '38°C' : '41°C';
      temp.className = row.hostname === 'ilom1' ? 'tel-ok' : 'tel-alert';
    } else {
      temp.textContent = '--°C';
      temp.className = 'tel-crit';
    }
  }

  if (psu) {
    psu.textContent = isOnline ? 'A+B OK' : 'FALHA';
    psu.className = isOnline ? 'tel-ok' : 'tel-crit';
  }

  if (cooling) {
    cooling.textContent = isOnline ? '100%' : '0%';
    cooling.className = isOnline ? 'tel-ok' : 'tel-crit';
  }
}

function updateLdomTelemetry(rows) {
  ['ldom1', 'ldom2'].forEach((ldomName) => {
    const ldomHostRow = rows.find((row) => row.hostname === ldomName);
    const hostedRows = rows.filter((row) => row.ldom === ldomName && row.hostname !== ldomName);
    const activeServices = hostedRows.filter((row) => isOperationalStatus(row.status)).length;

    const ldomStatusGroup = ldomHostRow ? getStatusGroup(ldomHostRow.status) : 'unknown';
    const isOnline = ldomStatusGroup === 'ok' || ldomStatusGroup === 'standby';
    const cpuTarget = isOnline ? Math.min(95, 10 + activeServices * 4) : 0;

    setText(`${ldomName}-cpu-text`, `${cpuTarget}%`);
    setText(`${ldomName}-services-count`, `${activeServices} Sistemas`);

    const cpuBar = getElement(`${ldomName}-cpu-bar`);
    if (cpuBar) {
      cpuBar.style.width = `${cpuTarget}%`;
    }
  });
}

function updateSummary(rows) {
  const counters = {
    total: rows.length,
    operational: 0,
    critical: 0,
    high: 0,
    medium: 0,
    info: 0,
  };

  rows.forEach((row) => {
    const group = getStatusGroup(row.status);

    if (group === 'ok') {
      counters.operational += 1;
      return;
    }

    if (group === 'standby') {
      counters.operational += 1;
      counters.info += 1;
      return;
    }

    if (group === 'warning') {
      counters.high += 1;
      return;
    }

    if (group === 'critical') {
      counters.critical += 1;
      return;
    }

    counters.medium += 1;
  });

  const healthPercentage = counters.total > 0
    ? ((counters.operational / counters.total) * 100).toFixed(1)
    : '0.0';

  setText('global-health-percentage', `${healthPercentage}%`);
  setText('count-crit', counters.critical);
  setText('count-alto', counters.high);
  setText('count-medio', counters.medium);
  setText('count-info', counters.info);

  const healthBar = document.querySelector('.progress-fill');
  if (healthBar) {
    healthBar.style.width = `${healthPercentage}%`;
  }
}

function updateNavigationState() {
  const links = document.querySelectorAll('.nav-menu a');

  links.forEach((link) => {
    link.addEventListener('click', () => {
      links.forEach((item) => item.classList.remove('active'));
      link.classList.add('active');
    });
  });
}

async function loadClusterState() {
  try {
    const response = await fetch(`${NEXUS_CONFIG.statusLdomCsv}?t=${Date.now()}`, {
      cache: 'no-store',
    });

    if (!response.ok) {
      throw new Error(`Arquivo não encontrado. HTTP ${response.status}`);
    }

    const text = await response.text();
    const rows = parseCsv(text);

    rows.forEach((row) => {
      updateHostStatus(row);
      updateIlomTelemetry(row);
    });

    updateLdomTelemetry(rows);
    updateSummary(rows);
  } catch (error) {
    console.warn(`NEXUS MONITOR: aguardando CSV de status (${error.message})`);
  }
}

function initNexusDashboard() {
  updateClock();
  updateNavigationState();
  loadClusterState();

  setInterval(updateClock, NEXUS_CONFIG.clockIntervalMs);
  setInterval(loadClusterState, NEXUS_CONFIG.refreshIntervalMs);
}

document.addEventListener('DOMContentLoaded', initNexusDashboard);