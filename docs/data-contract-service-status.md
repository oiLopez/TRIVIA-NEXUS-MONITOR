# Contrato de Dados - service_status.csv

## Objetivo

O arquivo `service_status.csv` representa o estado de serviços/processos relevantes do ambiente Prodix por máquina.

Ele será usado principalmente pela aba Topologia do NEXUS MONITOR para demonstrar onde serviços operacionais estão rodando em determinado momento.

Exemplo de serviço monitorado:

    evtreport

O serviço `evtreport` é responsável pela geração da tabela de eventos consumida pelos supervisores/controladores em ciclo periódico.

## Arquivo runtime

    backend/data/runtime/service_status.csv

## Arquivo sample

    backend/data/samples/service_status.sample.csv

## Cabeçalho

    timestamp;host_id;host_name;host_type;ldom;ip_address;service_name;service_pattern;technical_comm;service_status;pid_count;pids;message

## Campos

    timestamp
        Data/hora da coleta.

    host_id
        Identificador técnico da máquina.

    host_name
        Nome exibível da máquina.

    host_type
        Tipo do host, como IHM, FIXED_SERVER, LDOM ou CONTROL_DOMAIN.

    ldom
        LDOM associada ao host, quando aplicável.

    ip_address
        IP do host. Em samples públicos deve ser fictício.

    service_name
        Nome lógico do serviço monitorado.

    service_pattern
        Padrão usado para localizar o processo na saída de ps.

    technical_comm
        Estado de comunicação técnica com o host.

    service_status
        Estado do serviço observado.

    pid_count
        Quantidade de processos encontrados para o serviço.

    pids
        Lista de PIDs encontrados, separados por vírgula.

    message
        Mensagem operacional resumida.

## Valores esperados

technical_comm:

    OK
    WARN
    CRIT
    WAIT

service_status:

    RUNNING
    STOPPED
    UNKNOWN
    WAIT

## Segurança

A coleta deve ser read-only.

O comando base permitido é:

    ps -ef

O filtro por processo deve ser feito pelo coletor local, evitando comandos remotos encadeados como:

    ps -ef | grep processo

O coletor não deve executar:

    kill
    pkill
    PRODIX
    STOPPRODIX
    start
    stop
    ipcrm
    comandos de escrita
    comandos de alteração de estado

## Uso na Topologia

A aba Topologia deve usar esse CSV para exibir:

    serviço
    máquina onde está rodando
    status
    quantidade de PIDs
    mensagem operacional

Exemplo:

    evtreport rodando em CPTM2 / LDOM1
