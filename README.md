# App de Eventos (Dart + MySQL)

## Preparação do banco (MySQL Workbench / DBeaver, Alt+X)
1. Crie o banco e as tabelas (script `schema_completo_mydb.sql`, se você tiver).
2. Opcional: dados da planilha (`popular_mydb.sql`).
3. Organizadores de teste (`recriar_organizadores.sql`), se precisar.

## Configuração
Em `lib/banco.dart`, ajuste a classe `ConfigBanco` (host, porta, usuário, senha, nome do banco).

## Rodando
- `dart pub get`
- `dart run bin/cadastrar_usuario.dart` (cria um organizador)
- `dart run bin/app_eventos.dart` (sistema com login)

## Regras de login
- 3 tentativas (nome, email e senha, conferidos no banco).
- Após 3 erros: bloqueio de 60 segundos, gravado no banco.
- Mais 2 tentativas. Se errar, "Esqueci minha senha" troca a senha do mesmo cadastro.

## Menu principal
1 convidados · 2 convites · 3 check-in (inclui refazer) · 4 sair · 5 estatísticas ·
6 eventos · 7 consultar tabelas · 8 exibir evento completo · 9 estatística após novo check-in ·
10 economia de insumos · 11 lista de espera e vagas

## Lista de espera (menu 11, qualquer usuário logado)
- Antes de usar, rode `sql/lista_espera.sql` (ou só `sql/trigger_reserva.sql`, se o resto já existe).
- Limite de vagas por evento (pode ser alterado; 0 = sem limite).
- Vagas calculadas no código (`lib/vagas_evento.dart`): convite ativo = não recusado.
- Evento lotado: convidar coloca a pessoa na fila (fim da fila, por ordem de chegada).
- Convite recusado: o código oferece a vaga ao 1º da fila.
- Promover/remover grava o histórico em `historico_lista_espera` pelo código;
  a trigger do banco só age para outros programas (`@historico_pelo_codigo`).

## Testes
- `dart test`
