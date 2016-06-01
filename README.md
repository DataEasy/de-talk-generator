[![Build Status](https://travis-ci.org/DataEasy/de-talk-generator.svg?branch=master)](https://travis-ci.org/DataEasy/de-talk-generator)
    
DE Talk Manager
===============================

## O que a aplicação faz?

1. Permite autenticação tanto por usuários criados no banco de dados, quanto via LDAP.
2. Lê um template em `svg`, edita os campos de acordo com os dados informado no form e gera um `png` com a capa da DE Talk.
3. Publica a DE Talk no Slack.
4. Cria uma pasta da DE Talk numa pasta do Google Drive compartilhada com a aplicação e copia a imagem de capa para ela.

Veja algumas screenshots [aqui](./docs/screenshots.md)

# Docker

A aplicação é divida em container:

* db - Banco de dados
* redis - Servidor redis
* sidekiq - Container que roda as tarefas assincronas
* web - Aplicação

## Execução

Caso queira fazer alguma configuração antes de criar a imagem, crie o arquivo (o script o fará se você fizer nada)
`config/detalk.example.yml`
baseado no `config/detalk.example.yml` e execute `bash init.sh` ou use volume
do [docker-compose.yml](docker-compose.yml) para montar o arquivo de configuração no container.

```
bash init.sh
```

Informações detalhadas sobre a configuração, acesse [aqui](./docs/configuration.md)

# Dependências

* sed
* docker
* docker-compose
