## 1.0.0

- Initial version.

## v3.3
- Aplicativo executado somente pelo terminal, com acesso direto ao MySQL pelo `mysql_client`.
- Camada HTTP (API shelf) e módulos de cálculo removidos do projeto.
- Classe base `Registro` com `obterDados()` abstrato e `toString()` herdado por todas as entidades.
- `Usuario` passa a ser abstrata, com `nome`, `email` e `telefone` em getters e setters validados.
- `Convidado`, `Evento`, `Convite`, `Checkin`, `Organizador` e `Mesa` com getters e setters.
- Construtores nomeados `doBanco` para montar objetos a partir das linhas do MySQL.
- Método `obterDadosEvento()` substituído por `obterDados()`, como nas demais entidades.

## v3.4
- SQL ajustado para a tabela `usuario` (antes `organizador`).
- Menu 11 "Lista de espera e vagas", liberado para administrador e organizadores.
- Classe `ItemListaEspera` (herda de `Registro`) e classe `VagasEvento` (cálculo de vagas no código).
- `Evento.limiteConvidados` com getter e setter validado (null = sem limite).
- Convites: evento lotado manda a pessoa para a fila; recusa oferece a vaga ao 1º da fila;
  reativar convite recusado respeita o limite.
- Histórico da fila gravado pelo código, com renumeração das posições; a trigger vira reserva.
- Testes em `test/lista_espera_test.dart`.
