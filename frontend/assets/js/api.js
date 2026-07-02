/* =========================================================
   NEXUS MONITOR - Frontend API
   Responsável por ler fontes locais publicadas pelo backend.
   ========================================================= */

'use strict';

import { NEXUS_CONFIG } from './config.js';

export async function fetchClusterRows() {
  const response = await fetch(`${NEXUS_CONFIG.statusLdomCsv}?t=${Date.now()}`, {
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error(`Arquivo não encontrado. HTTP ${response.status}`);
  }

  const text = await response.text();
  return parseStatusLdomCsv(text);
}

export function parseStatusLdomCsv(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .filter((line) => !line.toLowerCase().startsWith('hostname'))
    .map((line) => {
      const columns = line.split(';').map((column) => column.trim());

      return {
        hostname: String(columns[0] || '').toLowerCase(),
        ldom: String(columns[1] || '').toLowerCase(),
        status: normalizeStatus(columns[2] || 'WAIT'),
        uptime: columns[3] || '-',
        raw: line,
      };
    })
    .filter((row) => row.hostname && row.ldom && row.status);
}

export async function fetchEventRows() {
  const response = await fetch(`${NEXUS_CONFIG.eventsCsv}?t=${Date.now()}`, {
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error(`Arquivo de eventos não encontrado. HTTP ${response.status}`);
  }

  const text = await response.text();
  return parseEventsCsv(text);
}

export function parseEventsCsv(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .filter((line) => !line.toUpperCase().startsWith('TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM'))
    .map((line) => {
      const columns = line.split(';').map((column) => column.trim());

      return {
        timestamp: columns[0] || '',
        hostname: String(columns[1] || '').toLowerCase(),
        module: String(columns[2] || '').toUpperCase(),
        status: normalizeStatus(columns[3] || 'INFO'),
        metric: String(columns[4] || '').toUpperCase(),
        value: columns[5] || '-',
        message: columns[6] || '',
        raw: line,
      };
    })
    .filter((row) => (
      row.timestamp &&
      row.hostname &&
      row.module &&
      row.status &&
      row.metric &&
      row.value &&
      row.message
    ));
}

function normalizeStatus(status) {
  return String(status || '').trim().toUpperCase();
}
