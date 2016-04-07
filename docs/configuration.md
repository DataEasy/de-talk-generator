DE Talk Manager | Configurações
===============================

## Configuração padrão

Inicialmente o app só faz o gerenciamento das DE Talks. Para fazer mais coisas, é necessário alterar o
arquivo de configuração detalk.yml (criado a partir do [detalk.example.yml](../config/detalk.example.yml)).

Use volume do [docker-compose.yml](../docker-compose.yml) para montar o arquivo de configuração na aplicação.

## Autenticação

Por padrão é feita via banco de dados com o usuário padrão **demo/demo**, mas também é possível fazer via LDAP.

Para habilitar a configuração LDAP, vá ao arquivo [devise.rb](../config/initializers/devise.rb), descomente a linha:
`# manager.default_strategies(scope: :user).unshift :ldap_authenticatable`. Em seguida vá ao arquivo de
configuração (detalk.yml) e informe:

```
# Exemplo
ldap:
    host:
    port:
    username:
    password:
    search:
      base:
      filter:
```

Reinicie à aplicação e tente fazer o login usando um usuário do LDAP.

## Google Drive

Exite uma funcionalidade que cria pastas no google drive para cada DE Talk publicada, é preciso criar um
service account token e compartilhar uma pasta com a aplicação. Essa funcionalidade não pede para o usuário
fazer login com uma conta google.

### Como gerar o arquivo json service account

* Vá no [Developers Console](https://console.developers.google.com/project) e crie um novo projeto
* Você será redirecionado para o API Manager, procure pela `Drive API`, clique nele e habilite
* Agora vá em *Credentias*, *Create credentials*, selecione *Service account key*
* Em *Service account*, selecione *New service account*, informe o *Service account name*. No Key type, selecione JSON e crie.
* Então um arquivo do tipo <ServiceAccountName>-<Pequeno hash>.json será baixado (ou avisando pra baixar, vai depender do browser),
é esse arquivo que à aplicação vai usar para autenticar e conseguir criar as pastas no Google Drive.
* Agora, na tela de Credentials, clique em *Manage service accounts*.
* No Manage service accounts, você vai ver a sua credential criada. Na coluna *Service account ID* possui o um email,
é com esse email que você vai compartilhar a pasta onde vai ficar as pasta da DE Talk, então guarde-o.

Use o volume no docker-compose.yml para montar o arquivo do service account gerado pelo Google, depois informe o caminho
completo do arquivo (dentro do container) nas configurações.

### Compartilhando a pasta com a aplicação

* Faça login no google, vá no Google Drive selecione uma pasta que você deseja que a aplicação tenha acesso.
* Clique com o botão direito sobre ela, vá em *Compartilhar*.
* Insira o email que o service account gerou (Service account ID) e clique em enviar.
* Selecione *Poder editar* e clique em enviar.

Fazendo as configurações abaixo, à aplicação vai consegui enxergar a pasta compartilhada.

```
# Exemplo
google_drive:
  active: true
  shared_folder: "All Talks" # Coloque o nome da pasta que você compartilhou aqui
  service_account_json: /detalk/config/DeTalk-ae50hca862q2.json # Informe o caminho completo aqui
```

Reinicie a aplicação.

## Slack

A aplicação também integra com o Slack, avisando quando uma DE Talk foi publicada ou cancelada. Altera o arquivo de
configuração e informe os dados:

```
# Exemplo
slack:
  active: true
  channel: #geral
  token: # API token
  message: Hey Pessoal! DE Talk %s publicada! Bora lá?
  message_talk_canceled: Pessoal. A DE Talk %s foi cancelada :(
```

## Banco de dados fora do Docker

Caso não queria usar o banco que o docker-compose vai iniciar, pare os container e remova o do banco de dados:

```
docker-compose stop
docker-compose rm -vf db
```

Comente toda à configuração do service `db:` no docker-compose.yml e altere as variáveis de ambiente no `web:`

```
environment:
  - DETALK_DB_HOST=<Endreço do servidor>
  - DETALK_DB=<Nome do Banco>
  - DETALK_DB_USER=<Usuário do banco>
  - DETALK_DB_PASSWORD=<Senha do banco>
```

Execute novamente os comandos para inicializar o banco:

```
docker-compose run web rake db:create --rm
docker-compose run web rake db:migrate --rm
docker-compose run web rake db:seed --rm
```

Agora inicie os containers novamente `docker-compose up -d`.

Se estiver usando um nome no lugar de IP para a DETALK_DB_HOST, não se esquece de informar o(s) endereço(s) do DNS:

```
dns:
  - 192.168.1.100
  - 192.168.1.101
```