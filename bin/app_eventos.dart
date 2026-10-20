import 'dart:io';
import 'package:app_eventos/login.dart';
import 'package:app_eventos/gerenciador_convidados.dart';
import 'package:app_eventos/gerenciamentoEventos.dart';
import 'package:app_eventos/gerenciamentoConvites.dart';
import 'package:app_eventos/gerenciamentoCheckin.dart';
import 'package:app_eventos/convidado.dart';
import 'package:app_eventos/Convite.dart';
import 'package:app_eventos/Checkin.dart';
import 'package:app_eventos/Evento.dart';
import 'package:app_eventos/estatisticas_evento.dart';

Future<void> main() async {
  var usuario = await executarLogin();

  if (usuario == null) {
    return;
  }

  List<Evento> eventos = [];
  List<Convidado> convidados = [];
  List<Convite> convites = [];
  List<Checkin> checkins = [];

  bool continuar = true;
  while (continuar) {
    print('\n=== MENU PRINCIPAL ===');
    print('Evento ativo: ${usuario.eventoGerenciado?.nomeEvento ?? 'nenhum'}');
    print('1 - Gerenciar convidados');
    print('2 - Gerenciar convites');
    print('3 - Gerenciar check-in');
    print('4 - Sair');
    print('5 - Ver estatísticas');
    print('6 - Gerenciar eventos');

    String opcao = stdin.readLineSync() ?? '';

    switch (opcao) {
      case '1':
        gerenciarConvidados(convidados);
        break;

      case '2':
        if (usuario.eventoGerenciado == null) {
          print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
        } else {
          gerenciarConvites(convidados, convites, usuario.eventoGerenciado!);
        }
        break;

      case '3':
        if (usuario.eventoGerenciado == null) {
          print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
        } else {
          gerenciarCheckin(convites, checkins, usuario.eventoGerenciado!);
        }
        break;

      case '4':
        print('Saindo do sistema...');
        continuar = false;
        break;

      case '5':
        final eventoAtivo = usuario.eventoGerenciado;
        if (eventoAtivo == null) {
          print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
          break;
        }

        // Filtra só o que pertence ao evento ativo, para as porcentagens
        // não misturarem eventos diferentes.
        final convitesDoEvento = convites.where((c) => c.evento == eventoAtivo).toList();
        final checkinsDoEvento =
            checkins.where((chk) => chk.convite?.evento == eventoAtivo).toList();

        var stats = calcularEstatisticas(convitesDoEvento, checkinsDoEvento);
        print('--- Estatísticas de ${eventoAtivo.nomeEvento} ---');
        print('Total de convites: ${stats.totalConvites}');
        print('Confirmados: ${stats.totalConfirmados} (${stats.percentualConfirmados.toStringAsFixed(1)}%)');
        print('Check-ins: ${stats.totalCheckins} (${stats.percentualPresenca.toStringAsFixed(1)}% dos confirmados)');
        break;

      case '6':
        gerenciarEventos(usuario, eventos);
        break;

      default:
        print('Opção inválida.');
    }
  }
}
