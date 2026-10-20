import 'dart:io';

import 'usuario.dart';
import 'Evento.dart';
import 'validacao.dart';

/// Gerencia os eventos do usuário logado: criar eventos (escolhendo ou criando
/// o tipo, com data e descrição), listar e trocar qual evento está ativo.
///
/// O "evento ativo" é o que fica em usuario.eventoGerenciado — é nele que
/// os menus de convites e check-in trabalham.
///
/// MOCK: os eventos ficam em memória, na lista compartilhada vinda do main.dart.
/// Quando o MySQL entrar, criar/listar vira INSERT/SELECT na tabela evento.
void gerenciarEventos(Usuario usuario, List<Evento> eventos) {
  // Garante que o evento criado no login também apareça na lista.
  final eventoDoLogin = usuario.eventoGerenciado;
  if (eventoDoLogin != null && !eventos.contains(eventoDoLogin)) {
    eventos.add(eventoDoLogin);
  }

  bool continuar = true;

  while (continuar) {
    print('\n=== Gerenciador de Eventos ===');
    print('Evento ativo: ${usuario.eventoGerenciado?.nomeEvento ?? 'nenhum'}');
    print('1 - Criar novo evento');
    print('2 - Listar eventos');
    print('3 - Trocar evento ativo');
    print('4 - Criar novo tipo de evento');
    print('5 - Sair');

    String opcao = stdin.readLineSync() ?? '';

    switch (opcao) {
      case '1':
        String? tipo = escolherTipoEvento();
        if (tipo == null) {
          print('Criação de evento cancelada.');
          break;
        }

        var novoEvento = Evento(tipodeevento: tipo);
        novoEvento.cadastrarEvento();
        eventos.add(novoEvento);
        usuario.eventoGerenciado = novoEvento;
        print('Evento criado e definido como ativo!');
        print(novoEvento.obterDadosEvento());
        break;

      case '2':
        if (eventos.isEmpty) {
          print('Nenhum evento criado ainda.');
        } else {
          for (var e in eventos) {
            String marcador = identical(e, usuario.eventoGerenciado)
                ? '*'
                : ' ';
            print('$marcador ${e.obterDadosEvento()}');
          }
          print('(* = evento ativo)');
        }
        break;

      case '3':
        if (eventos.isEmpty) {
          print('Nenhum evento criado ainda.');
          break;
        }
        for (var e in eventos) {
          print(
            '${e.id} - ${e.nomeEvento} (${e.tipodeevento}, ${formatarData(e.dataEvento)})',
          );
        }
        print('Digite o ID do evento que deseja gerenciar: ');
        int? idEvento = int.tryParse(stdin.readLineSync() ?? '');

        Evento? eventoEscolhido;
        for (var e in eventos) {
          if (e.id == idEvento) {
            eventoEscolhido = e;
            break;
          }
        }

        if (eventoEscolhido == null) {
          print('Evento não encontrado.');
        } else {
          usuario.eventoGerenciado = eventoEscolhido;
          print('Agora você está gerenciando: ${eventoEscolhido.nomeEvento}');
        }
        break;

      case '4':
        criarTipoEvento();
        break;

      case '5':
        print('Saindo do gerenciador de eventos...');
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
