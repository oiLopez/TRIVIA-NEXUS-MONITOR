/* =========================================================
   NEXUS MONITOR - Frontend Config
   Centraliza caminhos, intervalos e constantes da interface.
   ========================================================= */

'use strict';

export const NEXUS_CONFIG = Object.freeze({
  statusLdomCsv: '../backend/data/current/status_ldom.csv',
  eventsCsv: '../backend/data/events/nexus_events.csv',

  refreshIntervalMs: 2000,
  eventsRefreshIntervalMs: 5000,
  clockIntervalMs: 1000,
});

export const STATUS_GROUPS = Object.freeze({
  ok: ['ATIVO', 'ONLINE', 'OK', 'UP'],
  standby: ['STANDBY', 'RESERVA', 'BACKUP'],
  warning: ['ALERTA', 'ALERT', 'WARN', 'WARNING', 'DEGRADED', 'DEGRADADO'],
  critical: ['OFFLINE', 'FALHA', 'DOWN', 'CRITICAL', 'CRITICO', 'CRÍTICO'],
});