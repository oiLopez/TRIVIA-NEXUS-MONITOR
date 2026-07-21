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

function isMobileIhmStatusRow(row) {
  const hostname = String(row.hostname || '').trim().toLowerCase();
  const ldom = String(row.ldom || '').trim().toLowerCase();

  const mobileIhms = new Set([
    'cptm1', 'cptm2', 'cptm3', 'cptm4',
    'sme3', 'cons1', 'cons5', 'cptm12',
  ]);

  return mobileIhms.has(hostname) && (ldom === 'ldom1' || ldom === 'ldom2');
}

function updateHostStatus(row) {
  const targets = resolveStatusTargets(row);
  const badge = getElement(targets.badgeId);

  /*
   * IHMs móveis no Dashboard não exibem status técnico do status_ldom.csv.
   * O badge operacional é responsabilidade do operational_status.csv.
   * Aqui mantemos apenas o uptime.
   */
  if (!isMobileIhmStatusRow(row)) {
    setStatusBadge(badge, row.status);
  }

  updateUptime(targets.uptimeId, row.status, row.uptime);
}

function updateUptime(id, status, uptime) {
  const uptimeTag = getElement(id);

  if (!uptimeTag) {
    return;
  }

  const hasValidUptime = uptime && uptime !== '-';

  if (hasValidUptime) {
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


export function renderEventsPanel(rows, lastUpdate) {
  const tableBody = document.getElementById('events-table-body');
  const lastUpdateElement = document.getElementById('events-last-update');

  if (!tableBody) {
    return;
  }

  updateEventFilterControls(getActiveEventFilter());

  const sourceRows = Array.isArray(rows) ? rows : [];
  const filteredRows = filterEventsByActiveSeverity(sourceRows);
  const events = filteredRows.slice(-20).reverse();

  if (lastUpdateElement && lastUpdate) {
    lastUpdateElement.textContent = `Atualizado às ${lastUpdate.toLocaleTimeString('pt-BR')}`;
  }

  if (events.length === 0) {
    tableBody.innerHTML = `
      <tr>
        <td colspan="7" class="events-empty">Nenhum evento disponível.</td>
      </tr>
    `;
    return;
  }

  tableBody.innerHTML = events.map((event) => {
    const severity = getEventSeverity(event.status);

    return `
      <tr class="event-row event-${severity}">
        <td class="event-time">${escapeHtml(formatEventTimestamp(event.timestamp))}</td>
        <td class="event-host">${escapeHtml(event.hostname)}</td>
        <td>${escapeHtml(event.module)}</td>
        <td><span class="event-badge event-badge-${severity}">${escapeHtml(event.status)}</span></td>
        <td>${escapeHtml(event.metric)}</td>
        <td>${escapeHtml(event.value)}</td>
        <td class="event-message">${escapeHtml(event.message)}</td>
      </tr>
    `;
  }).join('');
}

export function renderEventsError(error) {
  console.warn(`NEXUS MONITOR: aguardando CSV de eventos (${error.message})`);

  const tableBody = document.getElementById('events-table-body');
  const lastUpdateElement = document.getElementById('events-last-update');

  if (lastUpdateElement) {
    lastUpdateElement.textContent = 'Aguardando arquivo de eventos';
  }

  if (tableBody) {
    tableBody.innerHTML = `
      <tr>
        <td colspan="7" class="events-empty">Aguardando backend/data/events/nexus_events.csv</td>
      </tr>
    `;
  }
}

function getEventSeverity(status) {
  const normalizedStatus = String(status || '').trim().toUpperCase();

  if (['CRITICO', 'CRÍTICO', 'CRITICAL', 'FALHA', 'OFFLINE', 'DOWN'].includes(normalizedStatus)) {
    return 'critical';
  }

  if (['ALERTA', 'ALERT', 'WARN', 'WARNING', 'DEGRADED', 'DEGRADADO'].includes(normalizedStatus)) {
    return 'warning';
  }

  if (['OK', 'ONLINE', 'UP', 'ATIVO', 'RECUPERADO'].includes(normalizedStatus)) {
    return 'ok';
  }

  return 'info';
}

function formatEventTimestamp(timestamp) {
  if (!timestamp) {
    return '--';
  }

  const parts = String(timestamp).split(' ');
  return parts[1] || timestamp;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

let activeEventFilter = 'all';

export function bindEventsFilterControls(onFilterChange) {
  const buttons = document.querySelectorAll('[data-event-filter]');

  buttons.forEach((button) => {
    button.addEventListener('click', () => {
      const selectedFilter = button.getAttribute('data-event-filter') || 'all';

      setActiveEventFilter(selectedFilter);
      updateEventFilterControls(selectedFilter);

      if (typeof onFilterChange === 'function') {
        onFilterChange(selectedFilter);
      }
    });
  });
}

function setActiveEventFilter(filter) {
  const allowedFilters = ['all', 'critical', 'warning', 'ok', 'info'];
  activeEventFilter = allowedFilters.includes(filter) ? filter : 'all';
}

function getActiveEventFilter() {
  return activeEventFilter;
}

function updateEventFilterControls(filter) {
  const buttons = document.querySelectorAll('[data-event-filter]');

  buttons.forEach((button) => {
    const buttonFilter = button.getAttribute('data-event-filter') || 'all';
    button.classList.toggle('active', buttonFilter === filter);
  });
}

function filterEventsByActiveSeverity(rows) {
  const filter = getActiveEventFilter();

  if (filter === 'all') {
    return rows;
  }

  return rows.filter((event) => getEventSeverity(event.status) === filter);
}


export function renderDataFreshnessIndicator(freshness) {
  const widget = document.getElementById('data-freshness-widget');
  const text = document.getElementById('data-freshness-text');

  if (!widget || !text) {
    return;
  }

  const status = freshness?.status || 'wait';
  const label = freshness?.label || 'Aguardando dados';

  widget.classList.remove(
    'data-freshness-ok',
    'data-freshness-wait',
    'data-freshness-warning',
    'data-freshness-critical',
  );

  widget.classList.add(`data-freshness-${status}`);
  widget.setAttribute('title', freshness?.detail || label);

  text.textContent = label;
}
