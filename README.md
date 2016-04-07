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

## Instalação

```
cp config/detalk.example.yml config/detalk.yml

docker-compose build --force-rm

docker-compose run web rake db:create --rm
docker-compose run web rake db:migrate --rm
docker-compose run web rake db:seed --rm

docker-compose up -d
```

Informações detalhadas sobre a configuração, acesse [aqui](./docs/configuration.md)

# Dependências

* docker
* docker-compose