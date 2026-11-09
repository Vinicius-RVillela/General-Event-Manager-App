import 'banco.dart';
import 'Checkin.dart';
import 'Convite.dart';
import 'Evento.dart';
import 'Organizador.dart';
import 'validacao.dart';

Future<void> gerenciarEventos(
  Organizador org,
  List<Evento> eventos,
  List<Convite> convites,
  List<Checkin> checkins,
) async {
  bool continuar = true;

  while (continuar) {
    final admin = org.ehAdministrador;

    print('\n=== Gerenciador de Eventos ===');
    print('Evento ativo: ${org.eventoGerenciado?.nomeEvento ?? 'nenhum'}');
    print('1 - Criar novo evento');
    print('2 - Listar eventos');
    print('3 - Trocar evento ativo');
    print('4 - Criar novo tipo de evento');
    if (admin) {
      print('5 - Excluir evento (somente administradores)');
      print('6 - Voltar');
    } else {
      print('5 - Voltar');
    }

    String opcao = lerLinha().trim();

    switch (opcao) {
      case '1':
        String? tipo = escolherTipoEvento();
        if (tipo == null) {
          print('Criação de evento cancelada.');
          break;
        }

        var novo = Evento.lerDoTerminal(tipo);
        try {
          await banco.salvarEventoCompleto(org, novo);
        } catch (e) {
          print('Erro ao salvar o evento no banco. Nada foi gravado. Detalhe: $e');
          break;
        }
        eventos.add(novo);
        org.eventoGerenciado = novo;
        print('Evento salvo no banco e definido como ativo!');
        print(novo.obterDados());
        break;

      case '2':
        if (eventos.isEmpty) {
          print('Nenhum evento cadastrado ainda.');
        } else {
          for (var e in eventos) {
            String marcador = identical(e, org.eventoGerenciado) ? '*' : ' ';
            print('$marcador ${e.obterDados()}');
          }
          print('(* = evento ativo)');
        }
        break;

      case '3':
        if (eventos.isEmpty) {
          print('Nenhum evento cadastrado ainda.');
          break;
        }
        for (var e in eventos) {
          print('${e.idBanco} - ${e.nomeEvento} (${e.tipodeevento}, ${formatarData(e.dataEvento)})');
        }
        print('Digite o ID do evento que deseja gerenciar: ');
        int? id = int.tryParse(lerLinha().trim());

        Evento? escolhido;
        for (var e in eventos) {
          if (e.idBanco == id) {
            escolhido = e;
            break;
          }
        }

        if (escolhido == null) {
          print('Evento não encontrado.');
        } else {
          org.eventoGerenciado = escolhido;
          print('Agora você está gerenciando: ${escolhido.nomeEvento}');
        }
        break;

      case '4':
        criarTipoEvento();
        break;

      case '5':
        if (admin) {
          await _excluirEvento(org, eventos, convites, checkins);
        } else {
          continuar = false;
        }
        break;

      case '6':
        if (admin) {
          continuar = false;
        } else {
          print('Opção inválida.');
        }
        break;

      default:
        print('Opção inválida.');
    }
  }
}

Future<void> _excluirEvento(
  Organizador org,
  List<Evento> eventos,
  List<Convite> convites,
  List<Checkin> checkins,
) async {
  // Segunda checagem de segurança, além de esconder a opção no menu.
  if (!org.ehAdministrador) {
    print('Acesso negado. Apenas administradores podem excluir eventos.');
    return;
  }

  if (eventos.isEmpty) {
    print('Nenhum evento cadastrado ainda.');
    return;
  }

  print('\n--- Excluir evento ---');
  for (var e in eventos) {
    print('${e.idBanco} - ${e.nomeEvento} (${e.tipodeevento}, ${formatarData(e.dataEvento)})');
  }
  print('Digite o ID do evento que deseja EXCLUIR (Enter para cancelar): ');
  final entrada = lerLinha().trim();
  if (entrada.isEmpty) {
    print('Exclusão cancelada.');
    return;
  }

  final id = int.tryParse(entrada);
  Evento? escolhido;
  if (id != null) {
    for (var e in eventos) {
      if (e.idBanco == id) {
        escolhido = e;
        break;
      }
    }
  }

  if (escolhido == null) {
    print('Evento não encontrado.');
    return;
  }

  print('ATENÇÃO: o evento "${escolhido.nomeEvento}" será apagado do banco, '
      'junto com seus convites, check-ins e mesas. Isso não pode ser desfeito.');
  print('Para confirmar, digite o ID do evento novamente (${escolhido.idBanco}): ');
  if (lerLinha().trim() != '${escolhido.idBanco}') {
    print('Confirmação não confere. Exclusão cancelada.');
    return;
  }

  try {
    await banco.excluirEvento(escolhido);
  } catch (e) {
    print('Erro ao excluir o evento. Nada foi apagado. Detalhe: $e');
    return;
  }

  eventos.remove(escolhido);
  convites.removeWhere((c) => c.evento == escolhido);
  checkins.removeWhere((chk) => chk.convite.evento == escolhido);
  if (identical(org.eventoGerenciado, escolhido)) {
    org.eventoGerenciado = null;
  }
  print('Evento "${escolhido.nomeEvento}" excluído com sucesso.');
}