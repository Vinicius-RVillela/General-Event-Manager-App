import 'dart:io';

import 'Convite.dart';
import 'Checkin.dart';
import 'Evento.dart';

/// Gerencia o check-in dos convidados no dia do evento.
/// Só permite check-in de convites com status "confirmado" DO EVENTO ATIVO —
/// quem nunca confirmou presença, ou foi convidado para outro evento,
/// não pode ser marcado como presente aqui.
void gerenciarCheckin(
  List<Convite> convites,
  List<Checkin> checkins,
  Evento evento,
) {
  bool continuar = true;

  while (continuar) {
    // Recalculadas a cada volta do menu, porque as listas mudam durante o uso.
    final confirmados = convites
        .where(
          (c) => c.evento == evento && c.status == StatusConfirmacao.confirmado,
        )
        .toList();
    final checkinsDoEvento = checkins
        .where((chk) => chk.convite?.evento == evento)
        .toList();
    // Confirmados que ainda não chegaram (não têm check-in registrado).
    final aguardando = confirmados
        .where((c) => !checkinsDoEvento.any((chk) => chk.convite == c))
        .toList();

    print('\n=== Gerenciador de Check-in (${evento.nomeEvento}) ===');
    print(
      'Já chegaram: ${checkinsDoEvento.length} | Aguardando: ${aguardando.length}',
    );
    print('1 - Fazer check-in');
    print('2 - Listar check-ins realizados');
    print('3 - Sair');

    String opcao = stdin.readLineSync() ?? '';

    switch (opcao) {
      case '1':
        if (confirmados.isEmpty) {
          print(
            'Nenhum convite confirmado disponível para check-in neste evento.',
          );
          break;
        }
        if (aguardando.isEmpty) {
          print('Todos os convidados confirmados já fizeram check-in.');
          break;
        }

        print('Convidados aguardando check-in:');
        for (var c in aguardando) {
          print('${c.id} - ${c.convidado?.nome}');
        }
        print('Digite o ID do convite para dar check-in: ');
        int? idConvite = int.tryParse(stdin.readLineSync() ?? '');

        Convite? conviteEscolhido;
        for (var c in aguardando) {
          if (c.id == idConvite) {
            conviteEscolhido = c;
            break;
          }
        }

        if (conviteEscolhido == null) {
          print('Convite não encontrado entre os que aguardam check-in.');
          break;
        }

        var novoCheckin = Checkin(
          dataHora: DateTime.now(),
          presente: true,
          convite: conviteEscolhido,
        );
        checkins.add(novoCheckin);
        print('Check-in realizado! ${novoCheckin.obterDados()}');
        break;

      case '2':
        if (checkinsDoEvento.isEmpty) {
          print('Nenhum check-in realizado ainda neste evento.');
        } else {
          for (var chk in checkinsDoEvento) {
            print(chk.obterDados());
          }
        }
        break;

      case '3':
        print('Saindo do gerenciador de check-in...');
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
