/* =========================================================
   NEXUS MONITOR - Frontend State
   Mantém o estado atual da interface em memória.
   ========================================================= */

'use strict';

export const nexusState = {
  clusterRows: [],
  lastUpdate: null,
  lastError: null,
};

export function setClusterRows(rows) {
  nexusState.clusterRows = Array.isArray(rows) ? rows : [];
  nexusState.lastUpdate = new Date();
  nexusState.lastError = null;
}

export function setFrontendError(error) {
  nexusState.lastError = error;
}