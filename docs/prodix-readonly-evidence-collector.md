# Coletor de Evidências Read-Only Prodix

## Objetivo

Este documento define o modelo de coleta read-only para evidências operacionais Prodix dentro do NEXUS MONITOR.

O objetivo do coletor é produzir arquivos locais de evidência de processos, que depois serão transformados no pipeline operacional Prodix.

A saída esperada futura é alimentar arquivos como:

    backend/data/runtime/prodix_ps/*.ps

Esses arquivos serão consumidos por:

    backend/collectors/collector_prodix_raw_snapshot.sh

que gera:

    backend/data/runtime/prodix_raw_process_snapshot.csv

## Princípio de segurança

O coletor de evidências deve ser exclusivamente read-only.

Ele pode observar:

    processos
    hostname
    data/hora
    conectividade
    resposta de comandos de consulta
    existência de sessão ou host acessível

Ele não pode alterar:

    processos
    serviços
    arquivos de configuração
    IPC
    banco de dados
    interfaces de rede
    estado operacional do Prodix
    estado de IHMs
    estado de servidores

## Comandos permitidos

Comandos permitidos devem ser apenas comandos de consulta.

Lista inicial permitida:

    hostname
    uname -n
    date
    ps -ef
    whoami

Uso esperado principal:

    ps -ef

O comando `ps -ef` será usado para observar a presença de processos críticos, como:

    sb_recebe
    ma
    sb_watdog
    painelcon

## Comandos proibidos

O coletor nunca deve executar comandos de alteração de estado.

Comandos e padrões proibidos:

    PRODIX
    STOPPRODIX
    STARTPRODIX
    STOPIHM
    STARTIHM
    STOPPAINEL
    PAINEL
    IHM
    kill
    pkill
    killall
    ipcrm
    ipcs -d
    rm
    mv
    cp para destino remoto
    chmod
    chown
    reboot
    shutdown
    init
    svcadm
    service
    systemctl
    ifconfig com alteração
    route com alteração
    sql
    isql
    comandos Sybase de escrita
    scripts de start
    scripts de stop
    comandos com redirecionamento remoto de escrita

Também são proibidos comandos contendo:

    ;
    &&
    ||
    >
    >>
    <
    |
    `command`
    $(command)

Esses padrões serão evitados para reduzir risco de execução encadeada ou alteração acidental.

## Processos críticos observados

A primeira versão do modelo operacional considera:

    sb_recebe
    ma
    sb_watdog

Processos auxiliares que podem ser observados:

    painelcon
    blinker
    gmstimer
    interbd

A interpretação operacional inicial usa principalmente:

    sb_recebe
    ma
    sb_watdog

## Interpretação inicial

Quando a comunicação técnica está OK:

    sb_recebe presente
    ma presente
    sb_watdog presente

indica instância Prodix operacionalmente ativa.

Quando nenhum dos processos críticos está presente, mas há comunicação OK:

    instância em STANDBY

Quando apenas parte dos processos críticos está presente:

    instância em FALHA ou WARN/CRIT operacional

Quando não há comunicação:

    technical_comm=WAIT ou CRIT
    operational_role=DESLIGADO

## Modos previstos

O coletor deve evoluir em fases.

### Modo 1 - Local evidence

Lê arquivos locais `.ps` já existentes em:

    backend/data/runtime/prodix_ps/

Esse modo não acessa rede.

É o modo mais seguro para desenvolvimento e teste.

### Modo 2 - Local command

Executa comandos read-only na própria máquina local, como:

    ps -ef

Esse modo serve para testar a extração real sem acesso remoto.

### Modo 3 - SSH read-only

Executa comandos read-only via SSH.

Exemplo conceitual:

    ssh usuario@host "ps -ef"

Somente comandos previamente permitidos poderão ser executados.

### Modo 4 - Hop WS21 para CPTM4

Modelo previsto:

    WS21
        ↓ ssh
    CPTM4

Esse modo deve continuar read-only.

### Modo 5 - rlogin CPTM4 para CPTM2

Modelo observado:

    CPTM4
        ↓ rlogin
    CPTM2

Esse modo é mais sensível e deve ser implementado apenas depois que os modos anteriores estiverem validados.

A regra permanece:

    consulta apenas
    sem start
    sem stop
    sem kill
    sem alteração

## Arquivos gerados

O coletor de evidências deve gerar arquivos locais runtime.

Exemplo:

    backend/data/runtime/prodix_ps/CPTM2_LDOM1.ps
    backend/data/runtime/prodix_ps/CPTM2_LDOM2.ps

Esses arquivos são runtime e não devem ser versionados.

O `.gitignore` deve impedir versionamento de:

    backend/data/runtime/**

exceto:

    backend/data/runtime/.gitkeep

## Relação com prodix_ihm_targets

Arquivo público sample:

    backend/config/prodix_ihm_targets.sample.csv

Esse arquivo define os alvos lógicos e o caminho esperado das evidências locais.

Formato:

    ihm;ldom;ip_address;evidence_file

Exemplo fictício:

    CPTM2;LDOM1;192.0.2.35;backend/data/runtime/prodix_ps/CPTM2_LDOM1.ps
    CPTM2;LDOM2;192.0.2.35;backend/data/runtime/prodix_ps/CPTM2_LDOM2.ps

Em ambiente real, IPs reais devem ficar apenas em arquivos locais ignorados pelo Git.

## Relação com o pipeline operacional

Fluxo completo previsto:

    coletor de evidências read-only
            ↓
    backend/data/runtime/prodix_ps/*.ps
            ↓
    collector_prodix_raw_snapshot.sh
            ↓
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
    frontend

## Segurança para repositório público

Nunca versionar:

    arquivos .ps reais
    logs reais
    saída real de comandos remotos
    IP real
    usuário real sensível
    senha
    token
    chave privada
    arquivos originais proprietários
    scripts originais de terceiros

É permitido versionar:

    samples fictícios
    documentação
    código do coletor
    validadores
    contratos CSV
    IPs de documentação 192.0.2.x

## Critérios de aceite

Uma implementação do coletor read-only só será considerada válida se:

    passar no bash -n
    não executar comandos proibidos
    gerar arquivos apenas em backend/data/runtime/
    não versionar runtime
    passar no validate_public_repo_safety.sh
    integrar com run_prodix_operational_pipeline.sh
    manter o pipeline operacional validado
    preservar o comportamento read-only

## Próxima implementação prevista

A próxima etapa técnica será criar uma primeira versão local do coletor de evidências.

Nome previsto:

    backend/collectors/collector_prodix_evidence_local.sh

Essa versão deverá:

    ler uma configuração de alvos
    gerar arquivos .ps fictícios ou locais
    não acessar remoto
    não alterar processos
    preparar a base para futura coleta SSH/rlogin read-only
