# Contrato de dados — Network Channel Status

## Objetivo

`network_channel_status.csv` representa o **estado atual** dos canais de comunicação
Rede A e Rede B dos ativos exibidos na aba **Topologia** do NEXUS Monitor.

Ele não substitui:

- `status_ldom.csv`: saúde/conectividade geral;
- `operational_status.csv`: papel operacional/HA;
- `service_status.csv`: processos Prodix;
- `nexus_events.csv`: histórico de eventos/transições.

## Arquivos

Runtime local:

```text
backend/data/runtime/network_channel_status.csv
```

Sample público:

```text
backend/data/samples/network_channel_status.sample.csv
```

O runtime não deve ser versionado em repositório público.

## Cabeçalho

```text
timestamp;asset_id;asset_name;asset_type;parent_asset;ldom;channel;ip_address;technical_comm;stability_status;loss_count;window_seconds;latency_ms;message
```

## Campos

| Campo | Descrição |
|---|---|
| `timestamp` | instante da coleta |
| `asset_id` | identificador normalizado em minúsculas |
| `asset_name` | nome operacional do ativo |
| `asset_type` | `WORKSTATION` ou `PRODIX` |
| `parent_asset` | WS associada à aplicação Prodix; vazio para WS |
| `ldom` | `BOTH` nesta versão, pois os mesmos pares são apresentados em LDOM1 e LDOM2 |
| `channel` | `A` ou `B` |
| `ip_address` | IP do canal |
| `technical_comm` | `OK`, `FALHA` ou `WAIT` |
| `stability_status` | `OK`, `INSTAVEL`, `FALHA` ou `WAIT` |
| `loss_count` | quantidade de perdas observadas na janela |
| `window_seconds` | janela de observação |
| `latency_ms` | latência média; pode ficar vazio em falha |
| `message` | contexto operacional curto |

## Ativos

A versão atual possui 16 ativos únicos:

- 8 Workstations: WS11, WS12, WS13, WS21, WS22, WS23, WS24, WS25;
- 8 aplicações Prodix: SME3, CONS1, CONS5, CPTM4, CPTM12, CPTM1, CPTM2, CPTM3.

Cada ativo possui dois canais. Portanto o snapshot completo possui **32 linhas de dados**.

## Associação WS ↔ Prodix

| Workstation | Aplicação | Função |
|---|---|---|
| WS11 | SME3 | MANUTENÇÃO |
| WS12 | CONS1 | EBILOCK — Brás - Luz |
| WS13 | CONS5 | MICROLOCK — Luz - BFU |
| WS21 | CPTM4 | MANUTENÇÃO |
| WS22 | CPTM12 | CONS — L-11 EXT |
| WS23 | CPTM1 | CONA — L-11 EXP |
| WS24 | CPTM2 | CONB — L-12 |
| WS25 | CPTM3 | CONC — Cabine de rotas (TAT - SGU) |

Os mesmos pares são apresentados na LDOM1 e na LDOM2.

## Consolidação da redundância

A redundância é calculada por ativo a partir de seus dois canais:

```text
A OK + B OK            -> OK
A OK + B FALHA         -> DEGRADADA
A FALHA + B OK         -> DEGRADADA
A INSTAVEL + B OK      -> DEGRADADA
A OK + B INSTAVEL      -> DEGRADADA
A FALHA + B FALHA      -> INDISPONIVEL
WAIT presente          -> WAIT, enquanto não houver evidência suficiente
```

`INSTAVEL` não deve ser tratado como `FALHA`: o canal ainda responde, mas possui
perda/oscilação.

## Simulação

O collector inicia em modo `simulated` por segurança.

```bash
tools/simulators/simulador_rede_ab.sh normal
tools/simulators/simulador_rede_ab.sh b_down CPTM2
tools/simulators/simulador_rede_ab.sh a_unstable WS24
tools/simulators/simulador_rede_ab.sh both_down CONS1
```

O cenário afeta somente o ativo-alvo; os demais permanecem `OK`.

## Coleta real

A coleta real deve ser habilitada explicitamente:

```bash
backend/collectors/collector_rede_ab.sh --mode real
```

Nesse modo o collector usa os IPs de `backend/config/nexus_hosts.config`.
No ambiente real, o inventário deve ser local/adequadamente protegido quando
contiver endereçamento sensível.

## Eventos

O collector mantém `nexus_events.csv` como trilha de eventos, mas registra
somente **transições de estado** quando já existe snapshot anterior.

Se um canal passar de `OK` para `INSTAVEL`, por exemplo:

```text
MODULO=REDE_AB
STATUS=ALERTA
METRICA=REDE_A
```

Se passar para `FALHA`:

```text
STATUS=CRITICO
```

Isso evita gravar o mesmo evento a cada ciclo de coleta.
