# NEXUS MONITOR

**NEXUS MONITOR** é uma plataforma local de monitoramento operacional desenvolvida para acompanhar a infraestrutura das Linhas **11 Coral** e **12 Safira** da **TRIVIATRENS**.

O objetivo do projeto é evoluir de um conjunto inicial de coletores Shell para um sistema estruturado, documentado e expansível, com características de uma pequena plataforma SCADA moderna.

---

## Visão Geral

O NEXUS MONITOR foi criado para centralizar informações operacionais de servidores, virtualização, rede, serviços, aplicações e eventos críticos em uma interface web local.

O sistema é executado em ambiente restrito, sem acesso à Internet, utilizando tecnologias simples, confiáveis e compatíveis com infraestrutura corporativa local.

---

## Ambiente Alvo

* Red Hat Enterprise Linux 9
* Servidor Web local
* HTML
* CSS
* JavaScript puro
* Shell Script
* CSV
* Sem banco de dados na fase inicial

---

## Objetivos do Projeto

* Monitorar a infraestrutura operacional das Linhas 11 Coral e 12 Safira.
* Consolidar informações técnicas em painéis web.
* Padronizar coletores de dados baseados em Shell Script.
* Armazenar dados iniciais em arquivos CSV.
* Criar uma arquitetura limpa, modular e documentada.
* Evoluir futuramente para uma plataforma semelhante a um pequeno SCADA moderno.
* Servir como base para análises, alarmes, histórico, relatórios e automações.

---

## Módulos Atuais

O projeto já contempla ou prevê os seguintes módulos:

* Dashboard
* Arquitetura
* Oracle ILOM
* LDOMs
* Zones Solaris
* Workstations
* Aplicações IHM
* Rede A/B
* Serviços
* Painel Sinótico
* Migrações
* Alertas
* Integridade
* Logs
* Configurações
* Acesso Remoto

---

## Estrutura Atual do Projeto

```text
nexus-monitor/
├── backend/
│   ├── collectors/
│   ├── config/
│   ├── core/
│   ├── data/
│   └── logs/
├── docs/
├── frontend/
│   ├── assets/
│   │   ├── css/
│   │   ├── icons/
│   │   ├── images/
│   │   └── js/
│   ├── modules/
│   ├── templates/
│   └── index.html
├── scripts/
├── testes/
└── README.md
```

---

## Arquitetura Conceitual

O NEXUS MONITOR é organizado em camadas:

```text
Coletores Shell
      ↓
Arquivos de Dados CSV
      ↓
Núcleo de Processamento
      ↓
Frontend Web Local
      ↓
Operador / Manutenção / Gerência
```

### Camada de Coleta

Responsável por executar comandos, verificar serviços, consultar hosts, coletar estados operacionais e gerar arquivos de saída padronizados.

### Camada de Dados

Responsável por armazenar os dados coletados em arquivos CSV, permitindo leitura simples pelo frontend e pelos módulos internos.

### Camada Core

Responsável por funções reutilizáveis, padronização de saída, validação, tratamento de erros e apoio aos coletores.

### Camada Frontend

Responsável por apresentar os dados em uma interface web local, com dashboards, painéis, alertas e visualizações operacionais.

---

## Tecnologias Utilizadas

| Camada              | Tecnologia                  |
| ------------------- | --------------------------- |
| Sistema Operacional | Red Hat Enterprise Linux 9  |
| Backend inicial     | Shell Script                |
| Dados               | CSV                         |
| Frontend            | HTML, CSS e JavaScript puro |
| Servidor            | Web Server local            |
| Versionamento       | Git                         |

---

## Princípios do Projeto

O NEXUS MONITOR deve ser desenvolvido como software profissional.

Princípios adotados:

* Código organizado
* Estrutura modular
* Comentários técnicos claros
* Documentação contínua
* Versionamento com Git
* Histórico de alterações
* Reutilização de funções
* Baixo acoplamento entre módulos
* Facilidade de manutenção
* Compatibilidade com ambiente offline
* Evolução gradual e segura

---

## Padrões Iniciais

### Nome de Arquivos Shell

Coletores devem seguir o padrão:

```text
collector_<nome_do_modulo>.sh
```

Exemplos:

```text
collector_alertas.sh
collector_virtualizacao.sh
collector_rede_ab.sh
collector_operacao_auto.sh
```

### Arquivos de Dados

Arquivos CSV devem possuir nomes descritivos:

```text
status_ldom.csv
nexus_events.csv
status_rede_ab.csv
status_servicos.csv
```

### Comentários

Todo script deve conter cabeçalho técnico com:

* Nome do arquivo
* Descrição
* Autor
* Versão
* Data de criação
* Última alteração
* Dependências
* Formato de saída

---

## Status do Projeto

Status atual: **fase inicial de estruturação**

O sistema já possui coletores, arquivos CSV e frontend inicial. A próxima fase será a padronização da arquitetura, organização dos módulos e criação da documentação técnica.

---

## Roadmap Inicial

### Versão 0.1

* Organizar estrutura de diretórios
* Padronizar nomes de arquivos
* Criar README inicial
* Criar CHANGELOG
* Criar ROADMAP
* Documentar arquitetura inicial
* Padronizar coletores Shell
* Separar dados atuais, eventos e históricos

### Versão 0.2

* Criar padrão visual do frontend
* Melhorar dashboard principal
* Criar módulos web independentes
* Normalizar leitura de CSV no JavaScript
* Implementar primeiros alertas visuais

### Versão 0.3

* Criar histórico operacional
* Melhorar logs internos
* Criar painel de integridade
* Criar documentação por módulo
* Criar scripts de instalação local

### Futuro

* Gráficos SVG
* Sistema de eventos
* Sistema de alarmes
* Banco de dados
* API local
* Exportação PDF
* Exportação Excel
* Modo desktop
* Modo mobile
* Dark theme e light theme
* Controle de usuários
* Sistema de plugins
* IA integrada
* Diagnóstico automático
* Relatórios automáticos

---

## Documentação

A documentação do projeto será mantida na pasta:

```text
docs/
```

Documentos previstos:

```text
docs/
├── arquitetura.md
├── instalacao.md
├── manual-tecnico.md
├── manual-operador.md
├── padroes.md
├── coletores.md
├── frontend.md
├── changelog.md
└── roadmap.md
```

---

## Execução

A forma de execução será documentada futuramente no manual de instalação.

Na fase inicial, os coletores Shell são executados localmente e geram arquivos CSV consumidos pela interface web.

---

## Licença

Licença ainda não definida.

---

## Autor

Projeto desenvolvido por **miyo** com apoio de desenvolvimento assistido por IA.

---

## Observação

Este projeto está em desenvolvimento ativo e será evoluído gradualmente, mantendo foco em robustez, clareza, documentação e utilidade operacional.

