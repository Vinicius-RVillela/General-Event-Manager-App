import 'banco.dart';
import 'Evento.dart';
import 'Organizador.dart';
import 'validacao.dart';

/// Menu de eventos do organizador logado. Criar grava no banco na hora.
Future<void> gerenciarEventos(Organizador org, List<Evento> eventos) async {
  bool continuar = true;

  while (continuar) {
    print('\n=== Gerenciador de Eventos ===');
    print('Evento ativo: ${org.eventoGerenciado?.nomeEvento ?? 'nenhum'}');
    print('1 - Criar novo evento');
    print('2 - Listar eventos');
    print('3 - Trocar evento ativo');
    print('4 - Criar novo tipo de evento');
    print('5 - Voltar');

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
        print(novo.obterDadosEvento());
        break;

      case '2':
        if (eventos.isEmpty) {
          print('Nenhum evento cadastrado ainda.');
        } else {
          for (var e in eventos) {
            String marcador = identical(e, org.eventoGerenciado) ? '*' : ' ';
            print('$marcador ${e.obterDadosEvento()}');
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
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
