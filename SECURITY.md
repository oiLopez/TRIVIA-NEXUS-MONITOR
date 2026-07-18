# Segurança e Dados Sensíveis

Este repositório é público e deve conter apenas código, documentação, contratos de dados, validadores e arquivos sample com dados fictícios.

## Dados permitidos no repositório

- IPs de documentação, como 192.0.2.x;
- exemplos e samples fictícios;
- simuladores;
- contratos CSV;
- documentação técnica do NEXUS MONITOR;
- frontend estático sem dados reais.

## Dados proibidos no repositório

- IPs reais do ambiente operacional;
- usuários reais;
- senhas, chaves, tokens ou segredos;
- logs reais;
- saídas reais de comandos remotos;
- arquivos runtime;
- arquivos proprietários de terceiros;
- scripts originais de sistemas de terceiros;
- capturas de tela contendo dados reais.

## Diretórios locais/runtime

Arquivos dentro de `backend/data/runtime/` são locais e não devem ser versionados.

Apenas `.gitkeep` pode existir nesse diretório no Git.
