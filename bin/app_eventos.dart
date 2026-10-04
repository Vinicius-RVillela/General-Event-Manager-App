import 'dart:io';
import 'package:app_eventos/login.dart';
import 'package:app_eventos/gerenciador_convidados.dart';
import 'package:app_eventos/gerenciamentoConvites.dart';
import 'package:app_eventos/gerenciamentoCheckin.dart';
import 'package:app_eventos/convidado.dart';
import 'package:app_eventos/Convite.dart';
import 'package:app_eventos/Checkin.dart';
import 'package:app_eventos/estatisticas_evento.dart';

Future<void> main() async {
  var usuario = await executarLogin();

  if (usuario == null) {
    return;
  }

  List<Convidado> convidados = [];
  List<Convite> convites = [];
  List<Checkin> checkins = [];

  bool continuar = true;
  while (continuar) {
    print('\n=== MENU PRINCIPAL ===');
    print('1 - Gerenciar convidados');
    print('2 - Gerenciar convites');
    print('3 - Gerenciar check-in');
    print('4 - Sair');
    print('5 - Ver estatísticas');

    String opcao = stdin.readLineSync()!;

    switch (opcao) {
      case '1':
        gerenciarConvidados(convidados);
        break;

      case '2':
        if (usuario.eventoGerenciado == null) {
          print('Nenhum evento vinculado a este usuário.');
        } else {
          gerenciarConvites(convidados, convites, usuario.eventoGerenciado!);
        }
        break;

      case '3':
        gerenciarCheckin(convites, checkins);
        break;

      case '4':
        print('Saindo do sistema...');
        continuar = false;
        break;

      case '5':
        var stats = calcularEstatisticas(convites, checkins);
        print('Total de convites: ${stats.totalConvites}');
        print('Confirmados: ${stats.totalConfirmados} (${stats.percentualConfirmados.toStringAsFixed(1)}%)');
        print('Check-ins: ${stats.totalCheckins} (${stats.percentualPresenca.toStringAsFixed(1)}% dos confirmados)');
        break;

      default:
        print('Opção inválida.');
    }
  }
}
