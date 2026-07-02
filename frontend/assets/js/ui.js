/* =========================================================
   NEXUS MONITOR - Frontend UI
   Responsável por atualizar elementos visuais da interface.
   ========================================================= */

'use strict';

import { STATUS_GROUPS } from './config.js';

export function renderClock() {
  const clock = getElement('clock');

  if (!clock) {
    return;
  }

  const now = new Date();
  clock.textContent = now.toLocaleTimeString('pt-BR');
}

export function bindNavigationState() {
  const links = document.querySelectorAll('.nav-menu a');

  links.forEach((link) => {
    link.addEventListener('click', () => {
      links.forEach((item) => item.classList.remove('active'));
      link.classList.add('active');
    });
  });
}

export function renderDashboard(rows, lastUpdate) {
  rows.forEach((row) => {
    updateHostStatus(row);
    updateIlomTelemetry(row);
  });

  updateLdomTelemetry(rows);
  updateSummary(rows, lastUpdate);
}

export function renderDataError(error) {
  console.warn(`NEXUS MONITOR: aguardando CSV de status (${error.message})`);

  const subtext = document.querySelector('.status-subtext');
  if (subtext) {
    subtext.textContent = 'Aguardando arquivo de status do backend';
  }
}

function getElement(id) {
  return document.getElementById(id);
}

function setText(id, value) {
  const element = getElement(id);

  if (element) {
    element.textContent = value;
  }
}

function normalizeStatus(status) {
  return String(status || '').trim().toUpperCase();
}

function getStatusGroup(status) {
  const normalizedStatus = normalizeStatus(status);

  if (STATUS_GROUPS.ok.includes(normalizedStatus)) {
    return 'ok';
  }

  if (STATUS_GROUPS.standby.includes(normalizedStatus)) {
    return 'standby';
  }

  if (STATUS_GROUPS.warning.includes(normalizedStatus)) {
    return 'warning';
  }

  if (STATUS_GROUPS.critical.includes(normalizedStatus)) {
    return 'critical';
  }

  return 'unknown';
}

function isOperationalStatus(status) {
  const group = getStatusGroup(status);
  return group === 'ok' || group === 'standby';
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

function updateHostStatus(row) {
  const targets = resolveStatusTargets(row);
  const badge = getElement(targets.badgeId);

  setStatusBadge(badge, row.status);
  updateUptime(targets.uptimeId, row.status, row.uptime);
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

function updateSummary(rows, lastUpdate) {
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

  const subtext = document.querySelector('.status-subtext');
  if (subtext && lastUpdate) {
    subtext.textContent = `Última atualização: ${lastUpdate.toLocaleTimeString('pt-BR')}`;
  }
}