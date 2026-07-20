# Pipeline Operacional Prodix

## Objetivo

Este documento descreve a cadeia local do NEXUS MONITOR responsável por transformar evidências operacionais do ambiente Prodix em `operational_status.csv`.

O pipeline é somente leitura e não executa ações de controle, start, stop, kill, limpeza de IPC, reinicialização ou alteração de processos.

## Escopo

Este pipeline cobre a camada operacional Prodix relacionada às IHMs móveis e aos ativos fixos/virtuais representados no contrato `operational_status.csv`.

Ele foi desenhado para separar corretamente:

    technical_comm       comunicação técnica / ping / acesso
    health_status        saúde operacional observada
    operational_role     papel operacional, como ATIVO ou STANDBY
    redundancy_conflict  conflito operacional de redundância

## Cadeia de processamento

    prodix_raw_process_snapshot.csv
            ↓
    collector_prodix_snapshot.sh
            ↓
    prodix_process_snapshot.csv
            ↓
    collector_prodix_operational.sh
            ↓
    operational_status.csv
            ↓
    validators
            ↓
    frontend

## Arquivos runtime

Os arquivos runtime são locais e não devem ser versionados.

Diretório:

    backend/data/runtime/

Arquivos principais:

    backend/data/runtime/prodix_raw_process_snapshot.csv
    backend/data/runtime/prodix_process_snapshot.csv
    backend/data/runtime/operational_status.csv

Apenas o arquivo `.gitkeep` deve existir versionado dentro de `backend/data/runtime/`.

## Arquivos sample

Os arquivos sample são públicos, versionados e usam dados fictícios.

Samples relacionados:

    backend/data/samples/prodix_raw_process_snapshot.sample.csv
    backend/data/samples/prodix_process_snapshot.sample.csv
    backend/data/samples/operational_status.sample.csv
    backend/config/prodix_assets.sample.csv

Os IPs usados em samples, como `192.0.2.x`, são fictícios e servem apenas para documentação e desenvolvimento.

## Configuração de ativos Prodix

O coletor operacional não deve manter IPs hardcoded no código.

A configuração pública fictícia fica em:

    backend/config/prodix_assets.sample.csv

A configuração real/local fica em:

    backend/config/prodix_assets.local.csv

O arquivo `.local.csv` é ignorado pelo Git e pode conter dados reais do ambiente quando necessário.

Formato esperado:

    asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message

## Raw snapshot Prodix

Arquivo runtime:

    backend/data/runtime/prodix_raw_process_snapshot.csv

Sample:

    backend/data/samples/prodix_raw_process_snapshot.sample.csv

Formato:

    ihm;ldom;ip_address;technical_comm;process_list

Este arquivo representa a visão bruta dos processos observados por IHM e LDOM.

Exemplo fictício:

    CPTM2;LDOM1;192.0.2.35;OK;sb_recebe ma sb_watdog painelcon
    CPTM2;LDOM2;192.0.2.35;OK;sb_recebe ma sb_watdog painelcon

Campos:

    ihm             identificador lógico da IHM
    ldom            LDOM onde a instância foi observada
    ip_address      IP associado à IHM naquela observação
    technical_comm  estado de comunicação técnica
    process_list    lista bruta de processos observados

Valores esperados para `technical_comm`:

    OK
    WARN
    CRIT
    WAIT

## Snapshot normalizado Prodix

Arquivo runtime:

    backend/data/runtime/prodix_process_snapshot.csv

Formato:

    ihm;ldom;ip_address;technical_comm;sb_recebe;ma;sb_watdog

Este arquivo é gerado por:

    backend/collectors/collector_prodix_snapshot.sh

Ele transforma `process_list` em flags booleanas para os processos críticos:

    sb_recebe
    ma
    sb_watdog

Exemplo fictício:

    CPTM2;LDOM1;192.0.2.35;OK;true;true;true
    CPTM2;LDOM2;192.0.2.35;OK;true;true;true

## Processos críticos

A interpretação inicial do modelo Prodix considera os seguintes processos:

    sb_recebe
    ma
    sb_watdog

Regra operacional básica:

    sb_recebe=true + ma=true + sb_watdog=true
        → instância operacionalmente ATIVA

    nenhum processo crítico ativo
        → instância em STANDBY, se houver comunicação OK

    apenas parte dos processos críticos ativa
        → instância em FALHA ou WARN/CRIT operacional

    comunicação indisponível
        → instância DESLIGADO ou WAIT, conforme contexto

## Status operacional final

Arquivo runtime:

    backend/data/runtime/operational_status.csv

Contrato:

    timestamp;asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message

Este arquivo é gerado por:

    backend/collectors/collector_prodix_operational.sh

Ele consolida:

    ativos fixos e virtuais configurados
    IHMs móveis
    comunicação técnica
    saúde operacional
    papel operacional
    conflito de redundância

## Interpretação de papéis operacionais

Valores esperados para `operational_role`:

    ATIVO
    STANDBY
    DESLIGADO
    FALHA
    NAO_APLICAVEL

Uso esperado:

    ATIVO
        Instância operacional principal naquele momento.

    STANDBY
        Instância disponível ou parada operacionalmente como reserva.

    DESLIGADO
        Sem comunicação ou sem evidência operacional.

    FALHA
        Comunicação existe, mas os processos observados indicam falha parcial.

    NAO_APLICAVEL
        Usado para ativos onde papel operacional não se aplica diretamente.

## Interpretação de saúde

Valores esperados para `health_status`:

    OK
    WARN
    CRIT
    CRITICAL
    WAIT

Uso esperado:

    OK
        Ativo ou instância em condição normal.

    WARN
        Estado parcial ou atenção operacional.

    CRIT / CRITICAL
        Falha crítica ou conflito operacional.

    WAIT
        Aguardando dados, sem snapshot ou sem comunicação suficiente.

## Conflito operacional de redundância

Cada IHM móvel possui um grupo lógico de redundância.

Exemplo:

    CPTM2_IHM_LDOM1
    CPTM2_IHM_LDOM2

Ambas pertencem ao grupo:

    CPTM2_IHM

Se mais de uma instância do mesmo grupo estiver `ATIVO` ao mesmo tempo, o coletor marca conflito:

    health_status=CRITICAL
    operational_role=ATIVO
    redundancy_conflict=true

Exemplo fictício de conflito:

    CPTM2_IHM_LDOM1;CPTM2_IHM;...;OK;CRITICAL;ATIVO;CPTM2_IHM;true;Conflito operacional...
    CPTM2_IHM_LDOM2;CPTM2_IHM;...;OK;CRITICAL;ATIVO;CPTM2_IHM;true;Conflito operacional...

Esse cenário representa conflito operacional de redundância, como duas instâncias da mesma IHM lógica ativas simultaneamente.

## Validadores envolvidos

Validadores usados na cadeia:

    tools/validators/validate_prodix_raw_process_snapshot.sh
    tools/validators/validate_prodix_process_snapshot.sh
    tools/validators/validate_prodix_assets_config.sh
    tools/validators/validate_operational_status.sh
    tools/validators/validate_operational_conflicts.sh
    tools/validators/validate_public_repo_safety.sh

## Execução do pipeline

Comando principal:

    scripts/run_prodix_operational_pipeline.sh

O pipeline executa:

    1. valida o raw snapshot Prodix
    2. gera prodix_process_snapshot.csv
    3. valida o snapshot Prodix normalizado
    4. gera operational_status.csv
    5. valida o contrato operational_status
    6. valida conflitos operacionais

## Teste local com dados fictícios

Para testar com sample:

    cp backend/data/samples/prodix_raw_process_snapshot.sample.csv backend/data/runtime/prodix_raw_process_snapshot.csv

    scripts/run_prodix_operational_pipeline.sh

Depois é possível consultar o resultado final:

    grep -Ei 'CPTM2|SFT1|SFT2|METROSP44|METROSP45' backend/data/runtime/operational_status.csv

## Check geral do projeto

O check geral deve validar o projeto completo:

    bash scripts/check_project.sh

Esse check inclui validações de:

    estrutura do projeto
    sintaxe Shell
    inventário
    CSVs principais
    status LDOM
    eventos
    operational_status
    snapshot Prodix
    config de ativos Prodix
    conflitos operacionais
    segurança para repositório público

## Segurança

O pipeline não deve executar:

    PRODIX
    STOPPRODIX
    kill
    pkill
    ipcrm
    start
    stop
    scripts de inicialização
    scripts de parada
    comandos remotos com alteração de estado

O pipeline deve ser somente leitura.

## Política para repositório público

Permitido versionar:

    código-fonte
    documentação
    contratos CSV
    validadores
    simuladores
    samples fictícios
    IPs de documentação como 192.0.2.x

Não permitido versionar:

    IP real
    senha
    token
    chave privada
    log real de produção
    arquivo runtime real
    saída real de comandos remotos
    arquivos proprietários de terceiros
    scripts originais de sistemas de terceiros
    prodix_assets.local.csv

## Relação com o frontend

O frontend consome:

    backend/data/runtime/operational_status.csv

A interface deve exibir separadamente:

    comunicação técnica
    saúde operacional
    papel operacional
    conflito de redundância

Para IHMs móveis, o dashboard deve priorizar o papel operacional e o conflito.

A comunicação da instância reserva pode ser exibida em visão detalhada, como a guia Servidores.

## Estado atual

A implementação atual usa snapshots locais como entrada.

A próxima fase prevista é criar um coletor bruto read-only capaz de gerar:

    backend/data/runtime/prodix_raw_process_snapshot.csv

a partir de evidências seguras, sem executar ações de alteração no ambiente.
