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

export function getDataFreshnessStatus() {
  if (nexusState.lastError) {
    return {
      status: 'critical',
      label: 'Falha na leitura do status',
      detail: nexusState.lastError.message,
    };
  }

  if (nexusState.eventsLastError) {
    return {
      status: 'warning',
      label: 'Eventos indisponíveis',
      detail: nexusState.eventsLastError.message,
    };
  }

  if (nexusState.lastUpdate && nexusState.eventsLastUpdate) {
    const latestUpdate = new Date(Math.max(
      nexusState.lastUpdate.getTime(),
      nexusState.eventsLastUpdate.getTime(),
    ));

    return {
      status: 'ok',
      label: `Dados atualizados às ${latestUpdate.toLocaleTimeString('pt-BR')}`,
      detail: 'Status e eventos carregados',
    };
  }

  if (nexusState.lastUpdate || nexusState.eventsLastUpdate) {
    return {
      status: 'wait',
      label: 'Aguardando todos os dados',
      detail: 'Carregamento parcial',
    };
  }

  return {
    status: 'wait',
    label: 'Aguardando dados',
    detail: 'Nenhum CSV carregado ainda',
  };
}