/* =========================================================
   NEXUS MONITOR - Frontend App
   Ponto de entrada da interface gráfica.
   ========================================================= */

'use strict';

import { NEXUS_CONFIG } from './config.js';
import { fetchClusterRows, fetchEventRows } from './api.js';
import {
  getDataFreshnessStatus,
  nexusState,
  setClusterRows,
  setEventRows,
  setFrontendError,
  setEventsError,
} from './state.js';
import {
  bindNavigationState,
  bindEventsFilterControls,
  renderClock,
  renderDashboard,
  renderDataError,
  renderDataFreshnessIndicator,
  renderEventsPanel,
  renderEventsError,
} from './ui.js';

function updateDataFreshnessIndicator() {
  renderDataFreshnessIndicator(getDataFreshnessStatus());
}

async function refreshClusterState() {
  try {
    const rows = await fetchClusterRows();

    setClusterRows(rows);
    renderDashboard(nexusState.clusterRows, nexusState.lastUpdate);
  } catch (error) {
    setFrontendError(error);
    renderDataError(error);
  } finally {
    updateDataFreshnessIndicator();
  }
}

async function refreshEventsState() {
  try {
    const rows = await fetchEventRows();

    setEventRows(rows);
    renderEventsPanel(nexusState.eventRows, nexusState.eventsLastUpdate);
  } catch (error) {
    setEventsError(error);
    renderEventsError(error);
  } finally {
    updateDataFreshnessIndicator();
  }
}

function startIntervals() {
  setInterval(renderClock, NEXUS_CONFIG.clockIntervalMs);
  setInterval(refreshClusterState, NEXUS_CONFIG.refreshIntervalMs);
  setInterval(refreshEventsState, NEXUS_CONFIG.eventsRefreshIntervalMs);
}

function initNexusDashboard() {
  renderClock();
  updateDataFreshnessIndicator();

  bindNavigationState();
  bindEventsFilterControls(() => {
    renderEventsPanel(nexusState.eventRows, nexusState.eventsLastUpdate);
  });

  refreshClusterState();
  refreshEventsState();

  startIntervals();
}

document.addEventListener('DOMContentLoaded', initNexusDashboard);