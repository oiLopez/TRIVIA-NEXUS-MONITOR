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

  if (hash === "topologia") {
    return "topologia";
  }

  if (hash === "painel") {
    return "painel";
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

// initIhmOperationalNormalizer();

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
      nexusRenderIhmOperationalStatus();

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

function nexusParseOperationalTimestamp(value) {
  const parsed = Date.parse(String(value || "").replace(" ", "T"));
  return Number.isNaN(parsed) ? 0 : parsed;
}

function nexusGetLatestOperationalRow(rows) {
  return [...rows].sort((a, b) => {
    return nexusParseOperationalTimestamp(b.timestamp) - nexusParseOperationalTimestamp(a.timestamp);
  })[0] || null;
}

function nexusFindLatestOperationalRowByLogicalAssetAndLdom(logicalAssetId, ldom) {
  const targetLogicalAsset = nexusNormalizeAssetName(logicalAssetId);
  const targetLdom = nexusNormalizeAssetName(ldom);

  const matches = nexusGetOperationalRows().filter((row) => {
    const rowLogicalAsset = nexusNormalizeAssetName(
      nexusGetRowValue(row, ["logical_asset_id", "LOGICAL_ASSET_ID"])
    );

    const rowLdom = nexusNormalizeAssetName(
      nexusGetRowValue(row, ["ldom", "LDOM"])
    );

    return rowLogicalAsset === targetLogicalAsset && rowLdom === targetLdom;
  });

  return nexusGetLatestOperationalRow(matches);
}

function nexusNormalizeBoolean(value) {
  return ["true", "1", "sim", "yes"].includes(
    String(value || "").trim().toLowerCase()
  );
}



function nexusRenderIhmOperationalStatus() {
  const targets = [
    "CPTM1",
    "CPTM2",
    "CPTM3",
    "CPTM4",
    "SME3",
    "CONS1",
    "CONS5",
    "CPTM12",
  ].flatMap((ihmName) => {
    const ihmId = ihmName.toLowerCase();

    return [
      {
        logicalAssetId: `${ihmName}_IHM`,
        ldom: "LDOM1",
        roleId: `srv-${ihmId}-ldom1`,
        commId: `srv-comm-${ihmId}-ldom1`,
        dashboardId: `${ihmId}-ldom1`,
      },
      {
        logicalAssetId: `${ihmName}_IHM`,
        ldom: "LDOM2",
        roleId: `srv-${ihmId}-ldom2`,
        commId: `srv-comm-${ihmId}-ldom2`,
        dashboardId: `${ihmId}-ldom2`,
      },
    ];
  });

  targets.forEach((target) => {
    const row = nexusFindLatestOperationalRowByLogicalAssetAndLdom(
      target.logicalAssetId,
      target.ldom
    );

    if (!row) {
      return;
    }

    const role = nexusGetRowValue(row, [
      "operational_role",
      "OPERATIONAL_ROLE",
    ]);

    const technicalComm = nexusGetRowValue(row, [
      "technical_comm",
      "TECHNICAL_COMM",
    ]);

    const message = nexusGetRowValue(row, [
      "message",
      "MESSAGE",
    ]);

    const conflict = nexusNormalizeBoolean(
      nexusGetRowValue(row, [
        "redundancy_conflict",
        "REDUNDANCY_CONFLICT",
      ])
    );

    nexusUpdateServerRoleBadge(
      target.roleId,
      conflict ? "FALHA" : role
    );

    const roleElement = document.getElementById(target.roleId);

    if (roleElement) {
      roleElement.title = message || "";

      if (conflict) {
        roleElement.textContent = "Conflito";
      }
    }

    function nexusUpdateTechnicalStatusBadge(elementId, status) {
  const element = document.getElementById(elementId);

  if (!element) {
    return;
  }

  element.classList.remove(
    "status-ok",
    "status-warn",
    "status-crit",
    "status-wait",
    "status-standby",
    "status-active"
  );

  element.classList.add(`status-${normalizedStatus.toLowerCase()}`);
  element.textContent = normalizedStatus;
}

    nexusUpdateIhmDashboardBadge(
      target.dashboardId,
      conflict ? "CONFLITO" : role,
      message
    );
  });
}

function nexusUpdateIhmDashboardBadge(elementId, role, message) {
  const element = document.getElementById(elementId);

  if (!element) {
    return;
  }

  const normalizedRole = String(role || "").trim().toUpperCase();

  element.classList.remove(
    "status-ok",
    "status-warn",
    "status-crit",
    "status-wait",
    "status-standby",
    "status-active"
  );

  element.classList.add("badge");

  if (normalizedRole === "CONFLITO") {
    element.textContent = "Conflito";
    element.classList.add("status-crit");
  } else if (normalizedRole === "ATIVO") {
    element.textContent = "Ativo";
    element.classList.add("status-active");
  } else if (normalizedRole === "STANDBY") {
    element.textContent = "Standby";
    element.classList.add("status-standby");
  } else if (normalizedRole === "FALHA") {
    element.textContent = "Falha";
    element.classList.add("status-crit");
  } else if (normalizedRole === "DESLIGADO") {
    element.textContent = "Off";
    element.classList.add("status-wait");
  } else {
    element.textContent = "Wait";
    element.classList.add("status-wait");
  }

  element.title = message || "";
}
/* =========================================================
   NEXUS SAFE FIX - IHM OPERATIONAL BADGES
   Objetivo:
   - impedir que badges de IHM herdem classe verde antiga;
   - manter separado papel operacional e comunicação técnica;
   - usar server-role-fault para conflito/falha operacional.
   ========================================================= */

(() => {
  const ihmNames = [
    "CPTM1",
    "CPTM2",
    "CPTM3",
    "CPTM4",
    "SME3",
    "CONS1",
    "CONS5",
    "CPTM12",
  ];

  const wsNames = [
    "WS11",
    "WS12",
    "WS13",
    "WS21",
    "WS22",
    "WS23",
    "WS24",
    "WS25",
  ];

  function safeNormalizeText(value) {
    return String(value || "").trim().toUpperCase();
  }

  function safeNormalizeRole(value) {
    const role = safeNormalizeText(value);

    if (["ATIVO", "ACTIVE"].includes(role)) return "ATIVO";
    if (["STANDBY", "RESERVA"].includes(role)) return "STANDBY";
    if (["DESLIGADO", "OFF", "OFFLINE", "SHUTDOWN"].includes(role)) return "DESLIGADO";
    if (["FALHA", "FAIL", "FAILED", "ERROR", "CRIT", "CRITICAL"].includes(role)) return "FALHA";
    if (["NAO_APLICAVEL", "N/A", "NA"].includes(role)) return "NAO_APLICAVEL";

    return "INDEFINIDO";
  }

  function safeNormalizeTechnicalStatus(value) {
    const status = safeNormalizeText(value);

    if (status === "OK") return "OK";
    if (["WARN", "WARNING", "ALERTA"].includes(status)) return "WARN";
    if (["CRIT", "CRITICAL", "FALHA", "FAIL", "FAILED", "ERROR"].includes(status)) return "CRIT";
    if (["WAIT", "PING", "PENDING", "UNKNOWN", "INDEFINIDO", ""].includes(status)) return "WAIT";

    return "WAIT";
  }

  function safeNormalizeBoolean(value) {
    return ["true", "1", "sim", "yes"].includes(
      String(value || "").trim().toLowerCase()
    );
  }

  function safeGetRowValue(row, possibleKeys) {
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

  function safeParseOperationalTimestamp(value) {
    const parsed = Date.parse(String(value || "").replace(" ", "T"));
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  function safeGetOperationalRows() {
    return Array.isArray(window.NEXUS_OPERATIONAL_STATUS)
      ? window.NEXUS_OPERATIONAL_STATUS
      : [];
  }

  function safeGetLatestOperationalRow(rows) {
    return [...rows].sort((a, b) => {
      const timestampA = safeGetRowValue(a, ["timestamp", "TIMESTAMP"]);
      const timestampB = safeGetRowValue(b, ["timestamp", "TIMESTAMP"]);

      return safeParseOperationalTimestamp(timestampB) - safeParseOperationalTimestamp(timestampA);
    })[0] || null;
  }

  function safeFindLatestOperationalRowByLogicalAssetAndLdom(logicalAssetId, ldom) {
    const targetLogicalAsset = safeNormalizeText(logicalAssetId);
    const targetLdom = safeNormalizeText(ldom);

    const matches = safeGetOperationalRows().filter((row) => {
      const rowLogicalAsset = safeNormalizeText(
        safeGetRowValue(row, ["logical_asset_id", "LOGICAL_ASSET_ID"])
      );

      const rowLdom = safeNormalizeText(
        safeGetRowValue(row, ["ldom", "LDOM"])
      );

      return rowLogicalAsset === targetLogicalAsset && rowLdom === targetLdom;
    });

    return safeGetLatestOperationalRow(matches);
  }

  function safeGetServerRolePresentation(role) {
    switch (safeNormalizeRole(role)) {
      case "ATIVO":
        return {
          label: "Ativo",
          className: "server-role-active",
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
          className: "server-role-fault",
        };

      default:
        return {
          label: "Indefinido",
          className: "server-role-unknown",
        };
    }
  }

  function safeUpdateServerRoleBadge(elementId, role, labelOverride, message) {
    const element = document.getElementById(elementId);

    if (!element) {
      return;
    }

    const presentation = safeGetServerRolePresentation(role);

    element.className = "server-role-badge";
    element.classList.add(presentation.className);
    element.textContent = labelOverride || presentation.label;
    element.dataset.operationalRole = safeNormalizeRole(role);
    element.title = message || "";
  }

  function safeUpdateTechnicalStatusBadge(elementId, status, message) {
    const element = document.getElementById(elementId);

    if (!element) {
      return;
    }

    const normalizedStatus = safeNormalizeTechnicalStatus(status);

    element.className = "badge";
    element.classList.add(`status-${normalizedStatus.toLowerCase()}`);
    element.textContent = normalizedStatus;
    element.title = message || "";
  }

  function safeUpdateIhmDashboardBadge(elementId, role, message) {
    const element = document.getElementById(elementId);

    if (!element) {
      return;
    }

    const normalizedRole = safeNormalizeText(role);

    element.className = "badge";

    if (normalizedRole === "CONFLITO") {
      element.textContent = "Conflito";
      element.classList.add("status-crit");
    } else if (normalizedRole === "ATIVO") {
      element.textContent = "Ativo";
      element.classList.add("status-active");
    } else if (normalizedRole === "STANDBY") {
      element.textContent = "Standby";
      element.classList.add("status-standby");
    } else if (normalizedRole === "FALHA") {
      element.textContent = "Falha";
      element.classList.add("status-crit");
    } else if (normalizedRole === "DESLIGADO") {
      element.textContent = "Off";
      element.classList.add("status-wait");
    } else {
      element.textContent = "Wait";
      element.classList.add("status-wait");
    }

    element.title = message || "";
  }

  function safeCopyBadgeState(sourceId, targetId) {
    const source = document.getElementById(sourceId);
    const target = document.getElementById(targetId);

    if (!source || !target) {
      return;
    }

    target.className = source.className;
    target.textContent = source.textContent;
    target.title = source.title || "";
  }

  function safeCopyTextState(sourceId, targetId) {
    const source = document.getElementById(sourceId);
    const target = document.getElementById(targetId);

    if (!source || !target) {
      return;
    }

    target.textContent = source.textContent;
    target.title = source.title || "";
  }

  function safeSyncServerAssetsView() {
    /*
     * Não espelhar mais IHMs do dashboard para a guia Servidores.
     *
     * Motivo:
     * - dashboard usa "badge status-*";
     * - guia Servidores usa "server-role-badge server-role-*";
     * - copiar classe entre essas camadas deixa CONFLITO/ATIVO/STANDBY verde indevidamente.
     *
     * Mantemos apenas WS e uptime.
     */

    wsNames.forEach((wsName) => {
      const wsId = wsName.toLowerCase();

      safeCopyBadgeState(`status-${wsId}`, `srv-status-${wsId}`);
      safeCopyTextState(`up-${wsId}`, `srv-up-${wsId}`);
    });

    ihmNames.forEach((ihmName) => {
      const ihmId = ihmName.toLowerCase();

      safeCopyTextState(`up-${ihmId}-ldom1`, `srv-up-${ihmId}-ldom1`);
      safeCopyTextState(`up-${ihmId}-ldom2`, `srv-up-${ihmId}-ldom2`);
    });
  }

  function safeRenderIhmOperationalStatus() {
    const targets = ihmNames.flatMap((ihmName) => {
      const ihmId = ihmName.toLowerCase();

      return [
        {
          logicalAssetId: `${ihmName}_IHM`,
          ldom: "LDOM1",
          dashboardId: `${ihmId}-ldom1`,
          serverRoleId: `srv-${ihmId}-ldom1`,
          serverCommId: `srv-comm-${ihmId}-ldom1`,
        },
        {
          logicalAssetId: `${ihmName}_IHM`,
          ldom: "LDOM2",
          dashboardId: `${ihmId}-ldom2`,
          serverRoleId: `srv-${ihmId}-ldom2`,
          serverCommId: `srv-comm-${ihmId}-ldom2`,
        },
      ];
    });

    targets.forEach((target) => {
      const row = safeFindLatestOperationalRowByLogicalAssetAndLdom(
        target.logicalAssetId,
        target.ldom
      );

      if (!row) {
        return;
      }

      const role = safeGetRowValue(row, ["operational_role", "OPERATIONAL_ROLE"]);
      const technicalComm = safeGetRowValue(row, ["technical_comm", "TECHNICAL_COMM"]);
      const message = safeGetRowValue(row, ["message", "MESSAGE"]);
      const conflict = safeNormalizeBoolean(
        safeGetRowValue(row, ["redundancy_conflict", "REDUNDANCY_CONFLICT"])
      );

      /*
       * Guia Servidores:
       * Papel operacional fica em server-role-badge.
       * Comunicação/ping fica em badge status-*.
       */
      safeUpdateServerRoleBadge(
        target.serverRoleId,
        conflict ? "FALHA" : role,
        conflict ? "Conflito" : "",
        message
      );

      safeUpdateTechnicalStatusBadge(
        target.serverCommId,
        technicalComm,
        message
      );

      /*
       * Dashboard:
       * Mostra papel operacional resumido.
       * Conflito sempre vermelho.
       */
      safeUpdateIhmDashboardBadge(
        target.dashboardId,
        conflict ? "CONFLITO" : role,
        message
      );
    });
  }

  try {
    syncServerAssetsView = safeSyncServerAssetsView;
  } catch (error) {
    console.warn("[NEXUS] Não foi possível sobrescrever syncServerAssetsView", error);
  }

  try {
    nexusUpdateServerRoleBadge = function nexusUpdateServerRoleBadgeSafe(elementId, role) {
      safeUpdateServerRoleBadge(elementId, role);
    };
  } catch (error) {
    console.warn("[NEXUS] Não foi possível sobrescrever nexusUpdateServerRoleBadge", error);
  }

  try {
    nexusRenderIhmOperationalStatus = safeRenderIhmOperationalStatus;
  } catch (error) {
    console.warn("[NEXUS] Não foi possível sobrescrever nexusRenderIhmOperationalStatus", error);
  }

  try {
    nexusUpdateIhmDashboardBadge = safeUpdateIhmDashboardBadge;
  } catch (error) {
    console.warn("[NEXUS] Não foi possível sobrescrever nexusUpdateIhmDashboardBadge", error);
  }

  try {
    nexusUpdateTechnicalStatusBadge = safeUpdateTechnicalStatusBadge;
  } catch (error) {
    console.warn("[NEXUS] Não foi possível sobrescrever nexusUpdateTechnicalStatusBadge", error);
  }

  try {
    safeSyncServerAssetsView();
    safeRenderIhmOperationalStatus();

    if (typeof nexusRenderFixedServerOperationalRoles === "function") {
      nexusRenderFixedServerOperationalRoles();
    }
  } catch (error) {
    console.error("[NEXUS] Falha ao aplicar correção segura de badges operacionais", error);
  }
})();

/* ==========================================================================
 * NEXUS - Service Status / Topologia
 * ========================================================================== */

(() => {
  const SERVICE_STATUS_PATH = "../backend/data/runtime/service_status.csv";

  function parseServiceStatusCsv(text) {
    const lines = String(text || "")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"));

    if (lines.length < 2) {
      return [];
    }

    const headers = lines[0].split(";").map((header) => header.trim());

    return lines.slice(1).map((line) => {
      const values = line.split(";");
      const row = {};

      headers.forEach((header, index) => {
        row[header] = (values[index] || "").trim();
      });

      return row;
    });
  }

  function getServiceBadgeClass(status) {
    const normalized = String(status || "WAIT").toUpperCase();

    if (normalized === "RUNNING") {
      return "status-ok";
    }

    if (normalized === "LOCKED") {
      return "status-warn";
    }

    if (normalized === "DUPLICATE" || normalized === "ERROR") {
      return "status-crit";
    }

    if (normalized === "STOPPED") {
      return "status-standby";
    }

    return "status-wait";
  }

  function getServiceSummary(rows) {
    if (!rows.length) {
      return {
        label: "AGUARDANDO",
        className: "status-wait",
      };
    }

    const hasDuplicate = rows.some((row) => String(row.service_status || "").toUpperCase() === "DUPLICATE");
    const hasRunning = rows.some((row) => String(row.service_status || "").toUpperCase() === "RUNNING");
    const hasLocked = rows.some((row) => String(row.service_status || "").toUpperCase() === "LOCKED");

    if (hasDuplicate) {
      return {
        label: "DUPLICADO",
        className: "status-crit",
      };
    }

    if (hasRunning) {
      const runningRow = rows.find((row) => String(row.service_status || "").toUpperCase() === "RUNNING");
      return {
        label: `RODANDO EM ${runningRow.host_name || runningRow.host_id || "HOST"}`,
        className: "status-ok",
      };
    }

    if (hasLocked) {
      return {
        label: "INSTÂNCIA EXISTENTE",
        className: "status-warn",
      };
    }

    return {
      label: "NÃO LOCALIZADO",
      className: "status-wait",
    };
  }

  function renderServiceStatus(rows) {
    const evtreportRows = rows.filter((row) => {
      return String(row.service_name || "").toLowerCase() === "evtreport";
    });

    const grid = document.getElementById("service-status-grid");
    const summary = document.getElementById("service-status-summary");

    if (!grid) {
      return;
    }

    if (!evtreportRows.length) {
      grid.innerHTML = '<div class="events-empty">Aguardando backend/data/runtime/service_status.csv</div>';

      if (summary) {
        summary.textContent = "AGUARDANDO";
        summary.className = "badge status-wait";
      }

      return;
    }

    const summaryState = getServiceSummary(rows);

    if (summary) {
      summary.textContent = summaryState.label;
      summary.className = `badge ${summaryState.className}`;
    }

    const statusPriority = {
      DUPLICATE: 0,
      ERROR: 1,
      RUNNING: 2,
      LOCKED: 3,
      STOPPED: 4,
      UNKNOWN: 5,
      WAIT: 6,
    };

    const sortedRows = [...evtreportRows].sort((a, b) => {
      const statusA = String(a.service_status || "WAIT").toUpperCase();
      const statusB = String(b.service_status || "WAIT").toUpperCase();

      const priorityA = statusPriority[statusA] ?? 99;
      const priorityB = statusPriority[statusB] ?? 99;

      if (priorityA !== priorityB) {
        return priorityA - priorityB;
      }

      return String(a.host_id || "").localeCompare(String(b.host_id || ""));
    });

    grid.innerHTML = sortedRows
      .map((row) => {
        const status = String(row.service_status || "WAIT").toUpperCase();
        const badgeClass = getServiceBadgeClass(status);
        const hostName = row.host_name || row.host_id || "HOST";
        const ldom = row.ldom || "N/A";
        const hostTitle = ldom && ldom !== "N/A" ? `${hostName} / ${ldom}` : hostName;
        const pidCount = row.pid_count || "0";
        const pids = row.pids || "N/A";
        const ip = row.ip_address || "N/A";
        const message = row.message || "Sem mensagem operacional.";

        return `
          <article class="service-status-card service-status-card-${status.toLowerCase()}">
            <div class="service-status-card-header">
              <div>
                <div class="service-status-host">${hostTitle}</div>
                <div class="service-status-pids">PID(s): ${pids}</div>
              </div>
              <span class="badge ${badgeClass}">${status}</span>
            </div>

            <div class="service-status-meta">
              <span>LDOM: ${ldom}</span>
              <span>IP: ${ip}</span>
              <span>Qtd: ${pidCount}</span>
            </div>

            <div class="service-status-message">${message}</div>
          </article>
        `;
      })
      .join("");
  }

  async function loadServiceStatus() {
    try {
      const response = await fetch(`${SERVICE_STATUS_PATH}?t=${Date.now()}`, {
        cache: "no-store",
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const text = await response.text();
      const rows = parseServiceStatusCsv(text);

      window.NEXUS_SERVICE_STATUS = rows;
      renderServiceStatus(rows);

      console.info(`[NEXUS] service_status.csv carregado: ${rows.length} registros`);
    } catch (error) {
      window.NEXUS_SERVICE_STATUS = [];
      renderServiceStatus([]);

      console.warn("[NEXUS] service_status.csv indisponível. Mantendo Topologia em WAIT.", error);
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    loadServiceStatus();
    setInterval(loadServiceStatus, 30000);
  });
})();

/* ==========================================================================
 * NEXUS - Painel View
 * ========================================================================== */

(() => {
  const PAINEL_SERVICE_STATUS_PATH = "../backend/data/runtime/service_status.csv";

  function parsePainelServiceStatusCsv(text) {
    const lines = String(text || "")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"));

    if (lines.length < 2) {
      return [];
    }

    const headers = lines[0].split(";").map((header) => header.trim());

    return lines.slice(1).map((line) => {
      const values = line.split(";");
      const row = {};

      headers.forEach((header, index) => {
        row[header] = (values[index] || "").trim();
      });

      return row;
    });
  }

  function getPainelBadgeClass(status) {
    const normalized = String(status || "WAIT").toUpperCase();

    if (normalized === "RUNNING") {
      return "status-ok";
    }

    if (normalized === "LOCKED") {
      return "status-warn";
    }

    if (normalized === "DUPLICATE" || normalized === "ERROR") {
      return "status-crit";
    }

    if (normalized === "STOPPED") {
      return "status-standby";
    }

    return "status-wait";
  }

  function getPainelPriority(status) {
    const normalized = String(status || "WAIT").toUpperCase();

    const priorities = {
      RUNNING: 0,
      LOCKED: 1,
      DUPLICATE: 2,
      ERROR: 3,
      STOPPED: 4,
      UNKNOWN: 5,
      WAIT: 6,
    };

    return priorities[normalized] ?? 99;
  }

  function renderPainelStatus(rows) {
    const painelRows = rows.filter((row) => {
      return String(row.service_name || "").toLowerCase() === "painel";
    });

    const grid = document.getElementById("painel-status-grid");
    const summary = document.getElementById("painel-status-summary");
    const badge = document.getElementById("painel-service-badge");
    const runningCountEl = document.getElementById("painel-running-count");
    const pidCountEl = document.getElementById("painel-pid-count");

    if (!grid) {
      return;
    }

    if (!painelRows.length) {
      grid.innerHTML = '<div class="events-empty">Aguardando dados de painel em service_status.csv</div>';

      if (summary) summary.textContent = "AGUARDANDO";
      if (badge) {
        badge.textContent = "AGUARDANDO";
        badge.className = "badge status-wait";
      }
      if (runningCountEl) runningCountEl.textContent = "0";
      if (pidCountEl) pidCountEl.textContent = "0";

      return;
    }

    const runningRows = painelRows.filter((row) => {
      return String(row.service_status || "").toUpperCase() === "RUNNING";
    });

    const totalPids = runningRows.reduce((total, row) => {
      const count = Number.parseInt(row.pid_count || "0", 10);
      return total + (Number.isNaN(count) ? 0 : count);
    }, 0);

    const sortedRows = [...painelRows].sort((a, b) => {
      const priorityA = getPainelPriority(a.service_status);
      const priorityB = getPainelPriority(b.service_status);

      if (priorityA !== priorityB) {
        return priorityA - priorityB;
      }

      return String(a.host_id || "").localeCompare(String(b.host_id || ""));
    });

    const summaryLabel = runningRows.length > 0
      ? `${runningRows.length} MÁQUINA(S)`
      : "NÃO LOCALIZADO";

    const summaryClass = runningRows.length > 0 ? "status-ok" : "status-wait";

    if (summary) summary.textContent = summaryLabel;

    if (badge) {
      badge.textContent = runningRows.length > 0 ? "PAINEL ATIVO" : "SEM PAINEL";
      badge.className = `badge ${summaryClass}`;
    }

    if (runningCountEl) runningCountEl.textContent = String(runningRows.length);
    if (pidCountEl) pidCountEl.textContent = String(totalPids);

    grid.innerHTML = sortedRows
      .map((row) => {
        const status = String(row.service_status || "WAIT").toUpperCase();
        const badgeClass = getPainelBadgeClass(status);
        const hostName = row.host_name || row.host_id || "HOST";
        const ldom = row.ldom || "N/A";
        const hostTitle = ldom && ldom !== "N/A" ? `${hostName} / ${ldom}` : hostName;
        const pidCount = row.pid_count || "0";
        const pids = row.pids || "N/A";
        const ip = row.ip_address || "N/A";
        const message = row.message || "Sem mensagem operacional.";

        return `
          <article class="service-status-card service-status-card-${status.toLowerCase()} ${status === "RUNNING" ? "service-status-card-painel-running" : ""}">
            <div class="service-status-card-header">
              <div>
                <div class="service-status-host">${hostTitle}</div>
                <div class="service-status-pids">PID(s): ${pids}</div>
              </div>
              <span class="badge ${badgeClass}">${status}</span>
            </div>

            <div class="service-status-meta">
              <span>IP: ${ip}</span>
              <span>Qtd: ${pidCount}</span>
              <span>Escopo: MULTI_ACTIVE</span>
            </div>

            <div class="service-status-message">${message}</div>
          </article>
        `;
      })
      .join("");
  }

  async function loadPainelStatus() {
    try {
      const response = await fetch(`${PAINEL_SERVICE_STATUS_PATH}?t=${Date.now()}`, {
        cache: "no-store",
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const text = await response.text();
      const rows = parsePainelServiceStatusCsv(text);

      renderPainelStatus(rows);

      console.info(`[NEXUS] Painel service_status carregado: ${rows.length} registros`);
    } catch (error) {
      renderPainelStatus([]);
      console.warn("[NEXUS] service_status.csv indisponível para aba Painel.", error);
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    loadPainelStatus();
    setInterval(loadPainelStatus, 30000);
  });
})();
