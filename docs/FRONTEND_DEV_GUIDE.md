# NEXUS MONITOR - Guia de Operação do Frontend

## Objetivo

Este documento descreve como iniciar, testar e validar a interface gráfica local do NEXUS MONITOR durante a fase de desenvolvimento frontend.

A interface é executada em servidor web local, sem Internet, utilizando HTML, CSS, JavaScript puro e arquivos CSV publicados pelo backend.

## Comando Padrão

Na raiz do projeto:

```bash
cd ~/nexus-monitor
bash scripts/dev_frontend.sh
```

O script executa automaticamente:

1. publicação do CSV sample em `backend/data/current/status_ldom.csv`;
2. validação do contrato `status_ldom.csv`;
3. verificação geral do projeto com `scripts/check_project.sh`;
4. inicialização de servidor HTTP local com Python 3.

## URL da Interface

Após iniciar o servidor, acessar no navegador:

```text
http://127.0.0.1:8000/frontend/index.html
```

## Usar Outra Porta

Caso a porta `8000` esteja ocupada:

```bash
bash scripts/dev_frontend.sh 8080
```

Acessar:

```text
http://127.0.0.1:8080/frontend/index.html
```

## Encerrar o Servidor

No terminal onde o servidor está rodando:

```text
Ctrl + C
```

## Fonte de Dados Usada no Teste

Durante o desenvolvimento, o script publica o sample:

```text
backend/data/samples/status_ldom.sample.csv
```

Para o caminho consumido pelo frontend:

```text
backend/data/current/status_ldom.csv
```

O contrato oficial desse arquivo está documentado em:

```text
docs/DATA_CONTRACT_STATUS_LDOM.md
```

## Validação Manual do CSV

Para validar o CSV atual:

```bash
bash tools/validators/validate_status_ldom.sh backend/data/current/status_ldom.csv
```

Para validar o sample em modo completo:

```bash
bash tools/validators/validate_status_ldom.sh backend/data/samples/status_ldom.sample.csv --strict
```

## Verificação Geral do Projeto

Executar:

```bash
bash scripts/check_project.sh
```

Essa verificação inclui sintaxe Shell, inventário, cabeçalhos CSV e validação do `status_ldom.csv`.

## Diagnóstico Rápido

### Tela abre, mas os cards ficam em `Wait`

Verificar se o CSV atual existe:

```bash
ls -l backend/data/current/status_ldom.csv
```

Republicar o sample:

```bash
bash scripts/publish_frontend_sample.sh
```

Validar o CSV:

```bash
bash tools/validators/validate_status_ldom.sh backend/data/current/status_ldom.csv
```

### Interface não carrega CSS ou JavaScript

Confirmar que o servidor foi iniciado na raiz do projeto:

```bash
pwd
```

O resultado esperado deve terminar com:

```text
nexus-monitor
```

O servidor deve ser iniciado assim:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

E não dentro da pasta `frontend`.

### Erro de porta ocupada

Usar outra porta:

```bash
bash scripts/dev_frontend.sh 8080
```

### Alterações não aparecem no navegador

Atualizar a página com recarregamento forçado:

```text
Ctrl + F5
```

Também é possível reiniciar o servidor com:

```text
Ctrl + C
bash scripts/dev_frontend.sh
```

## Arquivos Principais do Frontend

```text
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
```

## Regra de Arquitetura

O frontend não coleta dados e não altera arquivos CSV.

O backend é a fonte da verdade operacional.
O frontend apenas lê os arquivos publicados, interpreta estados e atualiza a interface visual.

## Status da Fase

Este guia pertence à fase:

```text
feature/frontend-dashboard-v01
```

Objetivo da fase:

```text
Consolidar a primeira interface gráfica local do NEXUS MONITOR, com base modular, execução offline, contrato CSV validado e fluxo de desenvolvimento documentado.
```
