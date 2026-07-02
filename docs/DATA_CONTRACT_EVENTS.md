# NEXUS MONITOR - Contrato CSV: nexus_events.csv

## Objetivo

O arquivo `nexus_events.csv` registra eventos operacionais gerados pelo backend do NEXUS MONITOR.

Ele será usado pelo frontend para exibir histórico recente, alertas, falhas, mensagens informativas e ocorrências relevantes do ambiente monitorado.

## Caminho Oficial

Arquivo corrente:

```text
backend/data/events/nexus_events.csv
```

Arquivo sample:

```text
backend/data/samples/nexus_events.sample.csv
```

## Formato

O arquivo deve usar ponto e vírgula como separador:

```csv
TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
```

## Colunas

| Coluna      | Obrigatória | Descrição                                               |
| ----------- | ----------: | ------------------------------------------------------- |
| `TIMESTAMP` |         Sim | Data e hora do evento no formato `YYYY-MM-DD HH:MM:SS`. |
| `HOSTNAME`  |         Sim | Host, serviço, módulo lógico ou origem do evento.       |
| `MODULO`    |         Sim | Área responsável pelo evento.                           |
| `STATUS`    |         Sim | Severidade ou estado do evento.                         |
| `METRICA`   |         Sim | Métrica, verificação ou tipo de condição observada.     |
| `VALOR`     |         Sim | Valor coletado ou estado resultante.                    |
| `MENSAGEM`  |         Sim | Descrição textual do evento.                            |

## Valores Recomendados para STATUS

| Status    | Interpretação                                 |
| --------- | --------------------------------------------- |
| `OK`      | Evento normal ou recuperação.                 |
| `INFO`    | Informação operacional.                       |
| `ALERTA`  | Condição que exige atenção.                   |
| `WARN`    | Atenção ou degradação leve.                   |
| `CRITICO` | Falha crítica ou indisponibilidade.           |
| `CRÍTICO` | Variante acentuada aceita para falha crítica. |
| `FALHA`   | Falha operacional.                            |
| `OFFLINE` | Item indisponível.                            |

## Valores Recomendados para MODULO

| Módulo          | Uso                                                      |
| --------------- | -------------------------------------------------------- |
| `SISTEMA`       | Eventos internos do NEXUS MONITOR.                       |
| `HARDWARE`      | ILOM, temperatura, fonte, ventoinha, refrigeração.       |
| `VIRTUALIZACAO` | LDOMs, Control Domains e recursos virtuais.              |
| `SERVICO`       | Serviços, servidores e aplicações monitoradas.           |
| `WORKSTATION`   | Estações físicas.                                        |
| `REDE`          | Conectividade, ping, latência e disponibilidade de rede. |
| `COLETOR`       | Execução dos scripts coletores.                          |

## Exemplo

```csv
TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
2026-07-02 09:02:30;ws13;WORKSTATION;CRITICO;PING;DOWN;Workstation WS13 indisponível
```

## Regras

* O cabeçalho deve ser exatamente:
  `TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM`
* Linhas iniciadas com `#` são comentários.
* Linhas vazias devem ser ignoradas.
* O separador oficial é `;`.
* Cada linha útil deve conter exatamente 7 colunas.
* A mensagem não deve conter `;` nesta fase inicial.
* O backend é responsável por gerar e manter este arquivo.
* O frontend apenas lê e exibe os eventos.

## Responsabilidades do Backend

O backend deve:

* registrar eventos relevantes;
* preservar o formato do contrato;
* evitar escrita parcial;
* usar timestamps consistentes;
* classificar eventos por severidade;
* manter o arquivo legível para o frontend.

## Responsabilidades do Frontend

O frontend deve:

* ler o CSV;
* exibir eventos recentes;
* classificar visualmente por severidade;
* permitir futura filtragem por status, host e módulo;
* não alterar o arquivo.

## Evolução Futura

Em versões futuras, este contrato poderá evoluir para incluir:

```csv
ID;TIMESTAMP;HOSTNAME;MODULO;STATUS;SEVERIDADE;METRICA;VALOR;MENSAGEM;ORIGEM
```

Na fase atual, o contrato oficial é:

```csv
TIMESTAMP;HOSTNAME;MODULO;STATUS;METRICA;VALOR;MENSAGEM
```
