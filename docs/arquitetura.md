# Arquitetura do Sistema

## Visão Geral

O NEXUS MONITOR é uma plataforma local de monitoramento operacional baseada em coletores Shell, arquivos CSV e interface web.

O sistema foi projetado para funcionar em ambiente restrito, sem acesso à Internet, utilizando tecnologias simples, auditáveis e compatíveis com servidores Linux corporativos.

---

## Camadas do Sistema

A arquitetura inicial é dividida em quatro camadas principais:

```text
Coletores Shell
      ↓
Arquivos CSV
      ↓
Núcleo do Sistema
      ↓
Interface Web
