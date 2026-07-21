# Contrato de Dados - Prodix Remote Targets

Arquivo sample:

    backend/config/prodix_remote_targets.sample.csv

Arquivo local real, não versionado:

    backend/config/prodix_remote_targets.local.csv

Objetivo:

    Definir quais máquinas podem ser consultadas em modo read-only para coleta
    de evidência de processos Prodix via ps -ef.

Cabeçalho oficial:

    host_id;host_name;ldom;access_method;gateway;target;output_file;enabled

Campos:

    host_id
        Identificador único do alvo no NEXUS.
        Exemplo: CPTM4_LDOM1.

    host_name
        Nome lógico exibido no NEXUS.
        Exemplo: CPTM4.

    ldom
        LDOM associada ao alvo, quando aplicável.
        Exemplo: LDOM1, LDOM2 ou N/A.

    access_method
        Método de acesso read-only.

        Valores aceitos:

            local
                Executa ps -ef na própria máquina onde o NEXUS está rodando.

            ssh
                Executa ps -ef diretamente no alvo via SSH.

            ssh_gateway_ssh
                Acessa um gateway via SSH e, a partir dele, executa SSH no alvo.

            ssh_gateway_rsh
                Acessa um gateway via SSH e, a partir dele, executa rsh no alvo.

            manual_rlogin
                Alvo conhecido como acessível apenas via rlogin interativo.
                Não executa coleta automática para evitar travamento do pipeline.

    gateway
        Gateway intermediário, quando aplicável.
        Para acesso direto/local, usar vazio.

    target
        Host alvo da coleta.

    output_file
        Caminho relativo onde a evidência ps será salva.
        Deve apontar para backend/data/runtime/prodix_ps/*.ps.

    enabled
        true ou false.

Segurança:

    - O coletor executa somente ps -ef.
    - Não executa start, stop, kill, ipcrm, scripts Prodix ou comandos de alteração.
    - Evidências reais ficam em backend/data/runtime/ e não devem ser versionadas.
    - Configuração real fica em backend/config/*.local.csv e não deve ser versionada.
