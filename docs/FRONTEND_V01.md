# NEXUS MONITOR - Frontend v0.1

## Objetivo

A fase Frontend v0.1 tem como objetivo iniciar a interface gráfica local do NEXUS MONITOR, com foco em visualização operacional, leitura de arquivos CSV gerados pelo backend e apresentação de status em formato de painel técnico.

A interface deve funcionar em ambiente local, sem Internet, sem frameworks externos e sem dependências remotas.

## Ambiente Alvo

- Red Hat Enterprise Linux 9
- Servidor web local
- HTML5
- CSS3
- JavaScript puro
- CSV como fonte inicial de dados
- Execução offline
- Sem banco de dados nesta fase

## Arquivos Principais

```text
frontend/
├── index.html
└── assets/
    ├── css/
    │   └── style.css
    └── js/
        └── app.js
