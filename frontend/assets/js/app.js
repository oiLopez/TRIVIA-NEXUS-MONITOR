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

  document
  .querySelectorAll(
    ".mobile-zones-grid .badge, .server-asset-status .badge, .server-asset-status-dual .server-role-badge"
  )
  .forEach((el) => {
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

function initSidebarToggle() {
  const sidebar = document.getElementById("sidebar");
  const toggle = document.getElementById("sidebar-toggle");

  if (!sidebar || !toggle) {
    return;
  }

  const storageKey = "nexus-sidebar-collapsed";

  function applySidebarState(isCollapsed) {
    sidebar.classList.toggle("is-collapsed", isCollapsed);

    toggle.setAttribute("aria-expanded", String(!isCollapsed));
    toggle.setAttribute(
      "aria-label",
      isCollapsed ? "Expandir menu lateral" : "Recolher menu lateral"
    );
    toggle.setAttribute(
      "title",
      isCollapsed ? "Expandir menu" : "Recolher menu"
    );
  }

  const savedState = localStorage.getItem(storageKey) === "true";
  applySidebarState(savedState);

  toggle.addEventListener("click", () => {
    const shouldCollapse = !sidebar.classList.contains("is-collapsed");

    localStorage.setItem(storageKey, String(shouldCollapse));
    applySidebarState(shouldCollapse);
  });
}

initSidebarToggle();

function syncServerDetailView() {
  const mappings = [
    ["status-ldom1", "status-ldom1-server-view"],
    ["status-ldom2", "status-ldom2-server-view"],

    ["sft1-ldom1", "sft1-server-view"],
    ["metrosp44-ldom1", "metrosp44-server-view"],
    ["sft2-ldom2", "sft2-server-view"],
    ["metrosp45-ldom2", "metrosp45-server-view"],

    ["role-sft1-ldom1", "role-sft1-server-view"],
    ["role-metrosp44-ldom1", "role-metrosp44-server-view"],
    ["role-sft2-ldom2", "role-sft2-server-view"],
    ["role-metrosp45-ldom2", "role-metrosp45-server-view"],
  ];

  mappings.forEach(([sourceId, targetId]) => {
    copyElementState(sourceId, targetId);
  });
}

function normalizePingBadgeFromOperationalStatus(sourceId, pingId) {
  const source = document.getElementById(sourceId);
  const ping = document.getElementById(pingId);

  if (!source || !ping) {
    return;
  }

  const value = source.textContent.trim().toUpperCase();

  ping.className = "badge";

  if (["ATIVO", "STANDBY", "OK"].includes(value)) {
    ping.textContent = "PING OK";
    ping.classList.add("status-ok");
    return;
  }

  if (["ALERTA", "WARN", "WARNING"].includes(value)) {
    ping.textContent = "PING";
    ping.classList.add("status-warn");
    return;
  }

  if (["FALHA", "CRIT", "CRITICAL"].includes(value)) {
    ping.textContent = "PING FALHA";
    ping.classList.add("status-crit");
    return;
  }

  ping.textContent = "PING";
  ping.classList.add("status-wait");
}

function syncIhmCommunicationBadges() {
  const ihmIds = [
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
  ];

  ihmIds.forEach((id) => {
    normalizePingBadgeFromOperationalStatus(id, `srv-comm-${id}`);
  });
}

function initServersViewRefinement() {
  syncServerDetailView();
  syncIhmCommunicationBadges();

  const sourceIds = [
    "status-ldom1",
    "status-ldom2",

    "sft1-ldom1",
    "metrosp44-ldom1",
    "sft2-ldom2",
    "metrosp45-ldom2",

    "role-sft1-ldom1",
    "role-metrosp44-ldom1",
    "role-sft2-ldom2",
    "role-metrosp45-ldom2",

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
  ];

  const observer = new MutationObserver(() => {
    syncServerDetailView();
    syncIhmCommunicationBadges();
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

  window.addEventListener("hashchange", () => {
    syncServerDetailView();
    syncIhmCommunicationBadges();
  });

  setInterval(() => {
    syncServerDetailView();
    syncIhmCommunicationBadges();
  }, 3000);
}

initServersViewRefinement();
/**
 * NEXUS MONITOR - Operational Status Runtime Data Layer
 *
 * Loads backend/data/runtime/operational_status.csv when running locally.
 * GitHub Pages may not provide this file; in that case the frontend keeps
 * the static/demo state.
 */

const NEXUS_OPERATIONAL_STATUS_PATH = "../backend/data/runtime/operational_status.csv";

function parseNexusCsvLine(line, separator = ";") {
  return line.split(separator).map((value) => value.trim());
}

function parseNexusOperationalStatusCsv(csvText) {
  const lines = csvText
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length < 2) {
    return [];
  }

  const headers = parseNexusCsvLine(lines[0]);

  return lines.slice(1).map((line) => {
    const values = parseNexusCsvLine(line);
    const row = {};

    headers.forEach((header, index) => {
      row[header] = values[index] ?? "";
    });

    return row;
  });
}

async function loadNexusOperationalStatus() {
  try {
    const response = await fetch(NEXUS_OPERATIONAL_STATUS_PATH, {
      cache: "no-store",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const csvText = await response.text();
    const rows = parseNexusOperationalStatusCsv(csvText);

    window.NEXUS_OPERATIONAL_STATUS = rows;

    console.info(
      `[NEXUS] operational_status.csv carregado: ${rows.length} registros`
    );
    
    nexusRenderFixedServerOperationalRoles();

    return rows;
  } catch (error) {
    window.NEXUS_OPERATIONAL_STATUS = [];

    console.warn(
      "[NEXUS] operational_status.csv indisponível. Mantendo estado estático/demo.",
      error.message
    );

    return [];
  }
}

function initNexusOperationalStatusDataLayer() {
  loadNexusOperationalStatus();
  setInterval(loadNexusOperationalStatus, NEXUS_CONFIG.refreshIntervalMs);
}

document.addEventListener("DOMContentLoaded", initNexusOperationalStatusDataLayer);

const NEXUS_FIXED_SERVERS = ["METROSP44", "METROSP45", "SFT1", "SFT2"];

function nexusGetRowValue(row, possibleKeys) {
  if (!row) return "";

  for (const key of possibleKeys) {
    if (row[key] !== undefined && row[key] !== null && String(row[key]).trim() !== "") {
      return String(row[key]).trim();
    }
  }

  const normalizedMap = {};
  Object.keys(row).forEach((key) => {
    normalizedMap[key.toLowerCase()] = row[key];
  });

  for (const key of possibleKeys) {
    const value = normalizedMap[key.toLowerCase()];
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return String(value).trim();
    }
  }

  return "";
}

function nexusNormalizeAssetName(value) {
  return String(value || "")
    .trim()
    .toUpperCase();
}

function nexusNormalizeOperationalRole(value) {
  const role = String(value || "")
    .trim()
    .toUpperCase();

  if (["ATIVO", "ACTIVE"].includes(role)) return "ATIVO";
  if (["STANDBY", "RESERVA"].includes(role)) return "STANDBY";
  if (["DESLIGADO", "OFF", "OFFLINE", "SHUTDOWN"].includes(role)) return "DESLIGADO";
  if (["FALHA", "FAIL", "FAILED", "ERROR"].includes(role)) return "FALHA";

  return "INDEFINIDO";
}

function nexusGetOperationalRows() {
  return Array.isArray(window.NEXUS_OPERATIONAL_STATUS)
    ? window.NEXUS_OPERATIONAL_STATUS
    : [];
}

function nexusFindOperationalRowByAssetName(assetName) {
  const target = nexusNormalizeAssetName(assetName);

  return nexusGetOperationalRows().find((row) => {
    const possibleNames = [
      nexusGetRowValue(row, ["asset_id", "ASSET_ID"]),
      nexusGetRowValue(row, ["logical_asset_id", "LOGICAL_ASSET_ID"]),
      nexusGetRowValue(row, ["asset_name", "ASSET_NAME"]),
      nexusGetRowValue(row, ["name", "NAME"]),
      nexusGetRowValue(row, ["hostname", "HOSTNAME"]),
      nexusGetRowValue(row, ["server_name", "SERVER_NAME"]),
    ].map(nexusNormalizeAssetName);

    return possibleNames.includes(target);
  });
}

function nexusGetFixedServerOperationalRole(serverName) {
  const row = nexusFindOperationalRowByAssetName(serverName);

  if (!row) {
    return "INDEFINIDO";
  }

  return nexusNormalizeOperationalRole(
    nexusGetRowValue(row, [
      "operational_role",
      "OPERATIONAL_ROLE",
      "role",
      "ROLE",
      "papel_operacional",
      "PAPEL_OPERACIONAL",
      "operational_status",
      "OPERATIONAL_STATUS",
      "state",
      "STATE"
    ])
  );
}

const NEXUS_FIXED_SERVER_ROLE_TARGET_IDS = {
  SFT1: ["role-sft1-ldom1", "role-sft1-server-view"],
  METROSP44: ["role-metrosp44-ldom1", "role-metrosp44-server-view"],
  SFT2: ["role-sft2-ldom2", "role-sft2-server-view"],
  METROSP45: ["role-metrosp45-ldom2", "role-metrosp45-server-view"],
};

const NEXUS_SERVER_ROLE_CLASS_NAMES = [
  "server-role-active",
  "server-role-standby",
  "server-role-off",
  "server-role-fault",
  "server-role-unknown",
];

function nexusGetServerRolePresentation(role) {
  switch (nexusNormalizeOperationalRole(role)) {
    case "ATIVO":
      return {
        label: "Ativo",
        className: "server-role-active",
      };
      case "FALHA":
        return {
          label: "Falha",
          className: "server-role-fault",
      };

    case "STANDBY":
      return {
        label: "Standby",
        className: "server-role-standby",
      };

    case "DESLIGADO":
      return {
        label: "Desligado",
        className: "server-role-off",
      };

    case "FALHA":
      return {
        label: "Falha",
        className: "server-role-fail",
      };

    default:
      return {
        label: "Indefinido",
        className: "server-role-unknown",
      };
  }
}

function nexusUpdateServerRoleBadge(elementId, role) {
  const element = document.getElementById(elementId);

  if (!element) {
    return;
  }

  const presentation = nexusGetServerRolePresentation(role);

  element.textContent = presentation.label;
  element.classList.remove(...NEXUS_SERVER_ROLE_CLASS_NAMES);
  element.classList.add("server-role-badge", presentation.className);
  element.dataset.operationalRole = nexusNormalizeOperationalRole(role);
}

function nexusRenderFixedServerOperationalRoles() {
  NEXUS_FIXED_SERVERS.forEach((serverName) => {
    const role = nexusGetFixedServerOperationalRole(serverName);
    const targetIds = NEXUS_FIXED_SERVER_ROLE_TARGET_IDS[serverName] || [];

    targetIds.forEach((targetId) => {
      nexusUpdateServerRoleBadge(targetId, role);
    });
  });

  syncServerDetailView();
}