# Modelo Operacional ALSTOM/Prodix para o NEXUS MONITOR

## Objetivo

Este documento descreve como o NEXUS MONITOR deve interpretar o estado operacional dos ativos ALSTOM/Prodix com base na análise estática dos scripts e da arquitetura observada.

O objetivo é separar claramente:

- comunicação técnica;
- saúde de processos;
- papel operacional;
- conflito de redundância;
- conflito de IHM/IP.

---

## Premissa de segurança

A análise considerada neste documento é estática/offline, baseada em cópias/exportações de arquivos e observações controladas.

O NEXUS MONITOR não deve modificar o ambiente ALSTOM/Prodix. O sistema deve apenas coletar, interpretar e exibir informações operacionais.

---

## Elementos principais observados

### Aplicação Prodix

A aplicação Prodix é iniciada por scripts do ambiente ALSTOM, com destaque para:

- PRODIX;
- STOPPRODIX;
- IHM;
- PAINEL;
- STOPIHM;
- STOPPAINEL;
- scripts auxiliares de IPC/FIFO.

Caminho principal observado:

    /home/cmwprodix/ihm_stef_v7.5/bin

Link operacional observado:

    cmwprodix/bin -> /home/cmwprodix/ihm_stef_v7.5/bin

---

## Processos críticos

A análise indicou processos usados como referência operacional:

    primeiro_processo = sb_recebe
    ultimo_processo   = ma
    watchdog          = sb_watdog

Para o NEXUS MONITOR:

- sb_recebe pode indicar início da cadeia operacional Prodix;
- ma pode indicar processo final esperado da aplicação;
- sb_watdog representa supervisão operacional da cadeia de processos.

---

## Servidores principais e redundância

Foram observadas referências a servidores A/B:

    SVRA  = metrosp44
    SVRB  = metrosp45
    SVRAb = metrosp44b
    SVRBb = metrosp45b

No NEXUS MONITOR, os servidores fixos são representados por pares de redundância:

    SFT1      <-> SFT2
    METROSP44 <-> METROSP45

Regra operacional:

- os dois membros de um mesmo par não devem estar simultaneamente ATIVOS;
- um membro pode estar ATIVO e o outro STANDBY;
- ambos com comunicação OK não significa conflito;
- conflito só existe quando ambos assumem papel operacional ATIVO no mesmo grupo de redundância.

---

## Comunicação técnica

A comunicação técnica representa a capacidade de alcançar o ativo.

Exemplos:

- ping;
- ssh;
- rlogin;
- teste de porta;
- comando remoto de leitura.

No contrato operational_status.csv, isso é representado por:

    technical_comm

Valores permitidos:

    OK
    WARN
    CRIT
    WAIT

Importante:

    technical_comm=OK não significa operational_role=ATIVO

Um servidor ou IHM pode responder ping e ainda estar em STANDBY.

---

## Saúde do ativo

A saúde representa a condição interna do ativo ou aplicação.

No contrato:

    health_status

Exemplos de critérios futuros:

- processo sb_recebe ativo;
- processo ma ativo;
- sb_watdog ativo;
- IHM iniciada;
- painel ativo;
- ausência de restart em loop;
- ausência de conflito de IP;
- ausência de oscilação operacional.

Valores esperados:

    OK
    WARN
    CRIT
    CRITICAL
    WAIT

---

## Papel operacional

O papel operacional representa a função real do ativo no sistema.

No contrato:

    operational_role

Valores esperados:

    ATIVO
    STANDBY
    DESLIGADO
    FALHA
    NAO_APLICAVEL

Interpretação:

    ATIVO          = ativo funcionalmente no sistema
    STANDBY        = reserva, pronto ou em espera
    DESLIGADO      = sem papel operacional ativo
    FALHA          = deveria operar, mas está em falha
    NAO_APLICAVEL  = ativo sem papel operacional, como ILOM ou camada física

---

## IHMs móveis

As IHMs móveis podem existir como instâncias em duas LDOMs, mas representam a mesma função lógica.

Exemplo:

    CPTM2_IHM_LDOM1 -> logical_asset_id = CPTM2_IHM
    CPTM2_IHM_LDOM2 -> logical_asset_id = CPTM2_IHM

Regra operacional:

- a mesma IHM lógica não deve estar ATIVA simultaneamente nas duas LDOMs;
- se as duas instâncias estiverem ATIVAS, há conflito operacional;
- como usam o mesmo IP lógico, esse cenário pode causar oscilação da aplicação.

---

## Conflito de IHM/IP

Um conflito ocorre quando:

    logical_asset_id igual
    ldom diferente
    operational_role=ATIVO em mais de uma instância

Resultado esperado no NEXUS MONITOR:

    technical_comm      = OK
    health_status       = CRITICAL
    operational_role    = ATIVO
    redundancy_conflict = true
    message             = Conflito de IP/IHM ativa nas duas LDOMs

Na interface:

    PING / COMUNICAÇÃO = OK
    PAPEL OPERACIONAL  = CONFLITO

---

## Acesso observado para CPTM2

Caminho operacional conhecido:

    WS21 -> CPTM4 -> CPTM2

Observação:

    WS21 acessa CPTM4 via SSH
    CPTM4 acessa CPTM2 via rlogin

Para o coletor real, CPTM4 pode atuar como ponte de coleta para CPTM2.

---

## Mapeamento para operational_status.csv

Contrato atual:

    timestamp;asset_id;logical_asset_id;asset_name;asset_type;parent_asset;ldom;ip_address;technical_comm;health_status;operational_role;redundancy_group;redundancy_conflict;message

Interpretação por campo:

    technical_comm      = alcance técnico, ping, ssh, rlogin ou equivalente
    health_status       = condição de processos/aplicação
    operational_role    = papel funcional no sistema
    redundancy_group    = grupo lógico de redundância
    redundancy_conflict = true quando há conflito operacional
    message             = explicação humana do estado

---

## Diretriz para coletores

O backend deve ser responsável por decidir:

    technical_comm
    health_status
    operational_role
    redundancy_conflict
    message

O frontend deve apenas exibir essas decisões.

A regra de negócio não deve ficar concentrada no JavaScript.

---

## Próximos passos

1. Validar operational_status.csv.
2. Detectar conflito de redundância por grupo.
3. Detectar conflito de IHM por logical_asset_id.
4. Evoluir coleta real com ping, ssh/rlogin e leitura de processos.
5. Exibir mensagens operacionais claras no frontend.
