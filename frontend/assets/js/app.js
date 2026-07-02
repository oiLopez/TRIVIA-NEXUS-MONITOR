/* =========================================================
   NEXUS MONITOR - Frontend App
   Ponto de entrada da interface gráfica.
   ========================================================= */

'use strict';

import { NEXUS_CONFIG } from './config.js';
import { fetchClusterRows } from './api.js';
import { nexusState, setClusterRows, setFrontendError } from './state.js';
import {
  bindNavigationState,
  renderClock,
  renderDashboard,
  renderDataError,
} from './ui.js';

async function refreshClusterState() {
  try {
    const rows = await fetchClusterRows();

    setClusterRows(rows);
    renderDashboard(nexusState.clusterRows, nexusState.lastUpdate);
  } catch (error) {
    setFrontendError(error);
    renderDataError(error);
  }
}

function startIntervals() {
  setInterval(renderClock, NEXUS_CONFIG.clockIntervalMs);
  setInterval(refreshClusterState, NEXUS_CONFIG.refreshIntervalMs);
}

function initNexusDashboard() {
  renderClock();
  bindNavigationState();
  refreshClusterState();
  startIntervals();
}

document.addEventListener('DOMContentLoaded', initNexusDashboard);