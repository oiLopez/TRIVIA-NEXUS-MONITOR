# Padrões do Projeto

Este documento define os padrões iniciais de organização, nomenclatura e desenvolvimento do NEXUS MONITOR.

---

## Estrutura de Diretórios

Estrutura principal:

```text
nexus-monitor/
├── backend/
├── docs/
├── frontend/
├── scripts/
├── tests/
├── tools/
├── README.md
├── CHANGELOG.md
├── ROADMAP.md
└── VERSION

## Padrão de CSV

Os arquivos CSV do NEXUS MONITOR devem utilizar ponto e vírgula `;` como separador padrão.

Esse padrão foi adotado para melhor compatibilidade com ambientes brasileiros e para evitar conflitos com valores numéricos que podem utilizar vírgula decimal.

Exemplo:

```csv
TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
2026-07-02 10:00:00;server01;SERVICOS;OK;HTTP;UP;Serviço ativo
