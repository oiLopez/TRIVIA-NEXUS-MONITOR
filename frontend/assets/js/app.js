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

function activateView(viewName) {
  const panels = document.querySelectorAll("[data-view-panel]");
  const links = document.querySelectorAll("[data-view-link]");

  panels.forEach((panel) => {
    const isActive = panel.dataset.viewPanel === viewName;
    panel.classList.toggle("active", isActive);
  });

  links.forEach((link) => {
    const isActive = link.dataset.viewLink === viewName;
    link.classList.toggle("active", isActive);
  });
}

function getViewFromHash() {
  const hash = window.location.hash.replace("#", "");

  if (hash === "alertas") {
    return "alertas";
  }

  if (hash === "servidores") {
    return "servidores";
  }

  return "dashboard";
}

function initViewTabs() {
  activateView(getViewFromHash());

  window.addEventListener("hashchange", () => {
    activateView(getViewFromHash());
  });
}

initViewTabs();

function copyElementState(sourceId, targetId) {
  const source = document.getElementById(sourceId);
  const target = document.getElementById(targetId);

  if (!source || !target) {
    return;
  }

  target.textContent = source.textContent;
  target.className = source.className;
}

function syncServerAssetsView() {
  const badgeMappings = [
    ["cptm1-ldom1", "srv-cptm1-ldom1"],
    ["cptm2-ldom1", "srv-cptm2-ldom1"],
    ["cptm3-ldom1", "srv-cptm3-ldom1"],
    ["cptm4-ldom1", "srv-cptm4-ldom1"],
    ["sme3-ldom1", "srv-sme3-ldom1"],
    ["cons1-ldom1", "srv-cons1-ldom1"],
    ["cons5-ldom1", "srv-cons5-ldom1"],
    ["cptm12-ldom1", "srv-cptm12-ldom1"],

    ["cptm1-ldom2", "srv-cptm1-ldom2"],
    ["cptm2-ldom2", "srv-cptm2-ldom2"],
    ["cptm3-ldom2", "srv-cptm3-ldom2"],
    ["cptm4-ldom2", "srv-cptm4-ldom2"],
    ["sme3-ldom2", "srv-sme3-ldom2"],
    ["cons1-ldom2", "srv-cons1-ldom2"],
    ["cons5-ldom2", "srv-cons5-ldom2"],
    ["cptm12-ldom2", "srv-cptm12-ldom2"],

    ["status-ws11", "srv-status-ws11"],
    ["status-ws12", "srv-status-ws12"],
    ["status-ws13", "srv-status-ws13"],
    ["status-ws21", "srv-status-ws21"],
    ["status-ws22", "srv-status-ws22"],
    ["status-ws23", "srv-status-ws23"],
    ["status-ws24", "srv-status-ws24"],
    ["status-ws25", "srv-status-ws25"],
  ];

  const uptimeMappings = [
    ["up-cptm1-ldom1", "srv-up-cptm1-ldom1"],
    ["up-cptm2-ldom1", "srv-up-cptm2-ldom1"],
    ["up-cptm3-ldom1", "srv-up-cptm3-ldom1"],
    ["up-cptm4-ldom1", "srv-up-cptm4-ldom1"],
    ["up-sme3-ldom1", "srv-up-sme3-ldom1"],
    ["up-cons1-ldom1", "srv-up-cons1-ldom1"],
    ["up-cons5-ldom1", "srv-up-cons5-ldom1"],
    ["up-cptm12-ldom1", "srv-up-cptm12-ldom1"],

    ["up-cptm1-ldom2", "srv-up-cptm1-ldom2"],
    ["up-cptm2-ldom2", "srv-up-cptm2-ldom2"],
    ["up-cptm3-ldom2", "srv-up-cptm3-ldom2"],
    ["up-cptm4-ldom2", "srv-up-cptm4-ldom2"],
    ["up-sme3-ldom2", "srv-up-sme3-ldom2"],
    ["up-cons1-ldom2", "srv-up-cons1-ldom2"],
    ["up-cons5-ldom2", "srv-up-cons5-ldom2"],
    ["up-cptm12-ldom2", "srv-up-cptm12-ldom2"],

    ["up-ws11", "srv-up-ws11"],
    ["up-ws12", "srv-up-ws12"],
    ["up-ws13", "srv-up-ws13"],
    ["up-ws21", "srv-up-ws21"],
    ["up-ws22", "srv-up-ws22"],
    ["up-ws23", "srv-up-ws23"],
    ["up-ws24", "srv-up-ws24"],
    ["up-ws25", "srv-up-ws25"],
  ];

  badgeMappings.forEach(([sourceId, targetId]) => {
    copyElementState(sourceId, targetId);
  });

  uptimeMappings.forEach(([sourceId, targetId]) => {
    copyElementState(sourceId, targetId);
  });
}

function initServerAssetsMirror() {
  syncServerAssetsView();

  const sourceIds = [
    "cptm1-ldom1",
    "cptm2-ldom1",
    "cptm3-ldom1",
    "cptm4-ldom1",
    "sme3-ldom1",
    "cons1-ldom1",
    "cons5-ldom1",
    "cptm12-ldom1",
    "cptm1-ldom2",
    "cptm2-ldom2",
    "cptm3-ldom2",
    "cptm4-ldom2",
    "sme3-ldom2",
    "cons1-ldom2",
    "cons5-ldom2",
    "cptm12-ldom2",
    "status-ws11",
    "status-ws12",
    "status-ws13",
    "status-ws21",
    "status-ws22",
    "status-ws23",
    "status-ws24",
    "status-ws25",
  ];

  const observer = new MutationObserver(() => {
    syncServerAssetsView();
  });

  sourceIds.forEach((sourceId) => {
    const source = document.getElementById(sourceId);

    if (!source) {
      return;
    }

    observer.observe(source, {
      attributes: true,
      childList: true,
      subtree: true,
      characterData: true,
    });
  });

  window.addEventListener("hashchange", syncServerAssetsView);
  setInterval(syncServerAssetsView, 5000);
}

initServerAssetsMirror();

function normalizeIhmOperationalStatus() {
  const ihmOperationalIds = [
    "cptm1-ldom1",
    "cptm2-ldom1",
    "cptm3-ldom1",
    "cptm4-ldom1",
    "sme3-ldom1",
    "cons1-ldom1",
    "cons5-ldom1",
    "cptm12-ldom1",

    "cptm1-ldom2",
    "cptm2-ldom2",
    "cptm3-ldom2",
    "cptm4-ldom2",
    "sme3-ldom2",
    "cons1-ldom2",
    "cons5-ldom2",
    "cptm12-ldom2",

    "srv-cptm1-ldom1",
    "srv-cptm2-ldom1",
    "srv-cptm3-ldom1",
    "srv-cptm4-ldom1",
    "srv-sme3-ldom1",
    "srv-cons1-ldom1",
    "srv-cons5-ldom1",
    "srv-cptm12-ldom1",

    "srv-cptm1-ldom2",
    "srv-cptm2-ldom2",
    "srv-cptm3-ldom2",
    "srv-cptm4-ldom2",
    "srv-sme3-ldom2",
    "srv-cons1-ldom2",
    "srv-cons5-ldom2",
    "srv-cptm12-ldom2",
  ];

  ihmOperationalIds.forEach((id) => {
    const el = document.getElementById(id);

    if (!el) {
      return;
    }

    const value = el.textContent.trim().toUpperCase();

    if (value === "OK") {
      el.textContent = "ATIVO";
      el.classList.remove("status-ok");
      el.classList.add("status-active");
    }
  });
}

function initIhmOperationalNormalizer() {
  normalizeIhmOperationalStatus();

  const observer = new MutationObserver(() => {
    normalizeIhmOperationalStatus();
  });

  document.querySelectorAll(".mobile-zones-grid .badge, .server-asset-status .badge").forEach((el) => {
    observer.observe(el, {
      attributes: true,
      childList: true,
      characterData: true,
      subtree: true,
    });
  });

  setInterval(normalizeIhmOperationalStatus, 3000);
}

initIhmOperationalNormalizer();