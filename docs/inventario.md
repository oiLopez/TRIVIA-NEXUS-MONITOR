# Inventário de Hosts

## Visão Geral

O arquivo `nexus_hosts.config` é o inventário oficial de hosts, zonas, servidores, consoles e componentes monitorados pelo NEXUS MONITOR.

Ele é utilizado pelos coletores para identificar quais ativos devem ser monitorados, qual endereço IP deve ser utilizado, qual usuário SSH deve ser usado e qual papel operacional cada host exerce.

---

## Local do Arquivo

```text
backend/config/nexus_hosts.config
```

---

## Objetivo

O inventário tem como objetivo centralizar as informações dos ativos monitorados, evitando que listas de hosts fiquem duplicadas dentro dos scripts.

Com isso, os coletores passam a usar uma fonte única de verdade.

---

## Formato Geral

O arquivo utiliza campos separados por ponto e vírgula `;`.

Formato base:

```text
TIPO;NOME;IP;USUARIO;FUNCAO;GRUPO;TECNOLOGIA;CATEGORIA;LOCALIZACAO;OBSERVACAO
```

Nem todos os registros precisam possuir exatamente a mesma quantidade de campos nesta fase inicial, mas os quatro primeiros campos devem ser mantidos como padrão obrigatório.

---

## Campos Obrigatórios

| Campo     | Descrição                          | Exemplo        |
| --------- | ---------------------------------- | -------------- |
| `TIPO`    | Tipo lógico do ativo               | `ZONE_FIXA`    |
| `NOME`    | Nome lógico do host                | `sft1`         |
| `IP`      | Endereço IP utilizado para conexão | `192.0.2.22` |
| `USUARIO` | Usuário utilizado para acesso SSH  | `prodix`       |

---

## Campos Complementares

| Campo         | Descrição                              | Exemplo      |
| ------------- | -------------------------------------- | ------------ |
| `FUNCAO`      | Função principal do ativo              | `servidor`   |
| `GRUPO`       | Grupo operacional ou sistema associado | `LDOM1`      |
| `TECNOLOGIA`  | Tipo técnico ou camada                 | `VM`         |
| `CATEGORIA`   | Categoria operacional                  | `Servidor`   |
| `LOCALIZACAO` | Localização, alça ou contexto          | `Alça Norte` |
| `OBSERVACAO`  | Observações adicionais                 | `(sft1)`     |

---

## Tipos de Ativos

### `ZONE_FIXA`

Representa zonas ou servidores com posição operacional fixa.

Exemplo:

```text
ZONE_FIXA;sft1;192.0.2.22;prodix;servidor;LDOM1;VM;Servidor;Alça;Norte;(sft1)
```

Uso principal:

* servidores SFT;
* servidores de operação;
* zonas fixas associadas a LDOMs;
* ativos com função definida e esperada.

---

### `ZONE_MOVEL`

Representa zonas ou consoles que podem estar associados a painéis, IHMs ou posições operacionais móveis.

Exemplo:

```text
ZONE_MOVEL;cptm1;192.0.2.10;prodix;console;CONA;VM;IHM;cptm1
```

Uso principal:

* consoles;
* IHMs;
* painéis operacionais;
* estações associadas ao painel sinótico.

---

## Regras de Padronização

O inventário deve seguir estas regras:

* Usar ponto e vírgula `;` como separador.
* Não usar espaços no início ou fim dos campos.
* Manter os nomes lógicos em minúsculas sempre que possível.
* Manter o campo `TIPO` em maiúsculas.
* Manter os quatro primeiros campos obrigatórios em todas as linhas.
* Não duplicar nomes de hosts.
* Não duplicar IPs, salvo quando houver justificativa técnica documentada.
* Não armazenar senhas no inventário.
* Não armazenar chaves privadas no inventário.
* Não colocar comentários no meio das linhas de dados.
* Documentar qualquer novo tipo de ativo neste arquivo.

---

## Campos Mínimos Aceitos

Todo registro válido deve possuir pelo menos:

```text
TIPO;NOME;IP;USUARIO
```

Exemplo mínimo:

```text
ZONE_FIXA;sft1;192.0.2.22;prodix
```

---

## Uso pelos Coletores

O coletor `collector_operacao_auto.sh` utiliza os campos:

```text
TIPO;NOME;IP;USUARIO
```

Para `ZONE_FIXA`, ele coleta o estado dos servidores SFT.

Para `ZONE_MOVEL`, ele coleta o estado das aplicações de painel sinótico.

---

## Exemplo de Leitura

Para listar hosts `ZONE_FIXA`:

```bash
awk -F';' '$1 == "ZONE_FIXA" {print $2 ";" $3 ";" $4}' backend/config/nexus_hosts.config
```

Saída esperada:

```text
sft1;192.0.2.22;prodix
sft1b;192.0.2.48;prodix
sft2;192.0.2.25;prodix
```

Para listar hosts `ZONE_MOVEL`:

```bash
awk -F';' '$1 == "ZONE_MOVEL" {print $2 ";" $3 ";" $4}' backend/config/nexus_hosts.config
```

Saída esperada:

```text
sme3;192.0.2.27;prodix
sme3b;192.0.2.53;prodix
cptm1;192.0.2.10;prodix
```

---

## Validação Recomendada

Antes de usar o inventário em produção, recomenda-se validar:

awk -F';' '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*$/ {next}
    NF < 4 {print "Linha inválida: " NR " -> " $0}
' backend/config/nexus_hosts.config

Esse comando lista linhas com menos de quatro campos.

Também é recomendado verificar nomes duplicados:

```bash
awk -F';' 'NF >= 2 {print $2}' backend/config/nexus_hosts.config | sort | uniq -d
```

E IPs duplicados:

```bash
awk -F';' 'NF >= 3 {print $3}' backend/config/nexus_hosts.config | sort | uniq -d
```

---

## Segurança

O inventário não deve conter:

* senhas;
* tokens;
* chaves privadas;
* credenciais administrativas sensíveis;
* dados pessoais desnecessários;
* informações que não sejam necessárias para operação do sistema.

O acesso SSH deve ser feito por chave, política local do ambiente ou mecanismo seguro definido pela administração da infraestrutura.

---

## Evolução Futura

Futuramente, o inventário poderá evoluir para:

* validação automática;
* geração de relatórios;
* integração com banco de dados;
* interface web de edição;
* versionamento de alterações;
* histórico de ativos;
* associação com criticidade operacional;
* associação com linha, trecho, sistema e dependências;
* integração com mapa operacional.
