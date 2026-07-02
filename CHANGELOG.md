# Changelog

Todas as mudanças relevantes do projeto NEXUS MONITOR serão documentadas neste arquivo.

O formato segue uma organização simples por versão, data e tipo de alteração.

---

## [0.1.0] - 2026-07-02

### Adicionado

- Estrutura inicial do projeto.
- Separação entre backend, frontend, documentação, scripts, testes e ferramentas.
- Organização dos coletores Shell em `backend/collectors/`.
- Organização dos arquivos de configuração em `backend/config/`.
- Organização da camada core em `backend/core/`.
- Separação dos dados em `backend/data/current/`, `backend/data/events/`, `backend/data/history/` e `backend/data/samples/`.
- Criação da pasta `tools/simulators/` para simuladores e ferramentas auxiliares.
- Criação da pasta `docs/diagrams/` para diagramas e fluxogramas.
- Criação do arquivo `.gitignore`.
- Criação do arquivo `VERSION`.
- Criação do arquivo `ROADMAP.md`.
- Criação da documentação inicial de arquitetura.
- Criação da documentação inicial de padrões do projeto.

### Alterado

- Renomeada a pasta `testes/` para `tests/`.
- Movido o simulador HA para `tools/simulators/`.
- Movido `status_ldom.csv` para `backend/data/current/`.
- Movido `nexus_events.csv` para `backend/data/events/`.
- Atualizados os caminhos internos no frontend e no backend.
- Padronizado o coletor de Rede A/B para `collector_rede_ab.sh`.

### Validado
- Verificação de sintaxe Shell realizada com `bash -n`.
- Estrutura do projeto validada após reorganização inicial.
- reorganização estrutural;
- criação de documentação base;
- padronização inicial dos coletores;
- criação do validador de inventário;
- criação do verificador geral do projeto;
- uso do inventário oficial nos coletores;
- correção de caminhos frágeis;
- padronização de eventos CSV.
