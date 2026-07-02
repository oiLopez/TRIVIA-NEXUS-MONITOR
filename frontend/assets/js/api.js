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

function normalizeStatus(status) {
  return String(status || '').trim().toUpperCase();
}