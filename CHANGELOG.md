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
