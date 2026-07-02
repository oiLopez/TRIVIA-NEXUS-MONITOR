# NEXUS MONITOR - Fechamento da Fase Frontend Dashboard v0.1

## Objetivo da Fase

A fase Frontend Dashboard v0.1 teve como objetivo criar a primeira interface gráfica local do NEXUS MONITOR, mantendo compatibilidade com o ambiente offline e preparando a base para evolução futura como plataforma de monitoramento operacional.

A interface foi desenvolvida com:

- HTML5;
- CSS3;
- JavaScript puro;
- CSV como fonte inicial de dados;
- servidor web local;
- sem frameworks externos;
- sem dependências de Internet.

## Branch da Fase

```text
feature/frontend-dashboard-v01

# Estrutura consolidada 
frontend/
├── index.html
└── assets/
    ├── css/
    │   └── style.css
    └── js/
        ├── api.js
        ├── app.js
        ├── config.js
        ├── state.js
        └── ui.js

Responsabilidades dos Módulos JavaScript
config.js

Centraliza configurações do frontend:

caminho do CSV de status;
caminho do CSV de eventos;
intervalos de atualização;
grupos de status.
api.js

Responsável pela leitura e parsing dos arquivos CSV publicados pelo backend:

status_ldom.csv;
nexus_events.csv.
state.js

Mantém o estado em memória da interface:

dados atuais de status;
eventos carregados;
horário da última atualização;
erros de leitura;
avaliação de saúde dos dados.
ui.js

Responsável pela renderização visual:

relógio;
badges de status;
telemetria visual;
painel de eventos;
filtros de eventos;
indicador de saúde dos dados.
app.js

Ponto de entrada da interface:

inicializa o dashboard;
agenda atualizações periódicas;
coordena leitura de dados;
coordena renderização da interface.
