/* =========================================================
   NEXUS MONITOR - Frontend State
   Mantém o estado atual da interface em memória.
   ========================================================= */

'use strict';

export const nexusState = {
  clusterRows: [],
  eventRows: [],

  lastUpdate: null,
  eventsLastUpdate: null,

  lastError: null,
  eventsLastError: null,
};

export function setClusterRows(rows) {
  nexusState.clusterRows = Array.isArray(rows) ? rows : [];
  nexusState.lastUpdate = new Date();
  nexusState.lastError = null;
}

export function setEventRows(rows) {
  nexusState.eventRows = Array.isArray(rows) ? rows : [];
  nexusState.eventsLastUpdate = new Date();
  nexusState.eventsLastError = null;
}

export function setFrontendError(error) {
  nexusState.lastError = error;
}

export function setEventsError(error) {
  nexusState.eventsLastError = error;
}