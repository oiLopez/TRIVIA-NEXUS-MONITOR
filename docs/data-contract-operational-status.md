# Contrato de Dados - Status Operacional

## Objetivo

Este documento define o contrato de dados para representar o estado técnico e operacional dos ativos monitorados pelo NEXUS MONITOR.

A principal regra é separar:

```text
comunicação técnica
saúde do ativo
papel operacional

### Cabeçalho CSV:
timestamp;asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message

### logical_asset_id

Identificador da entidade operacional lógica representada pelo ativo.

Este campo é usado quando a mesma IHM ou serviço possui instâncias em LDOMs diferentes, mas representa a mesma função operacional.

Exemplo:

```text
CPTM2_IHM_LDOM1 → logical_asset_id = CPTM2_IHM
CPTM2_IHM_LDOM2 → logical_asset_id = CPTM2_IHM


### IHM móvel

A mesma IHM lógica pode existir em mais de uma LDOM, porém usando o mesmo endereço IP.

Exemplo:

```text
CPTM2 em LDOM1 = 192.0.2.102
CPTM2 em LDOM2 = 192.0.2.102
