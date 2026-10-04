import 'dart:io';
import 'Convite.dart';
import 'Checkin.dart';

/// Gerencia o check-in dos convidados no dia do evento.
/// Só permite check-in de convites com status "confirmado" — quem nunca
/// confirmou presença não pode ser marcado como presente.
void gerenciarCheckin(List<Convite> convites, List<Checkin> checkins) {
  bool continuar = true;

  while (continuar) {
    print('\n=== Gerenciador de Check-in ===');
    print('1 - Fazer check-in');
    print('2 - Listar check-ins realizados');
    print('3 - Sair');

    String opcao = stdin.readLineSync()!;

    switch (opcao) {
      case '1':
        var confirmados =
            convites.where((c) => c.status == StatusConfirmacao.confirmado).toList();

        if (confirmados.isEmpty) {
          print('Nenhum convite confirmado disponível para check-in.');
          break;
        }

        print('Convites confirmados:');
        for (var c in confirmados) {
          print('${c.id} - ${c.convidado?.nome}');
        }
        print('Digite o ID do convite para dar check-in: ');
        int? idConvite = int.tryParse(stdin.readLineSync()!);

        Convite? conviteEscolhido;
        for (var c in confirmados) {
          if (c.id == idConvite) {
            conviteEscolhido = c;
            break;
          }
        }

        if (conviteEscolhido == null) {
          print('Convite não encontrado entre os confirmados.');
          break;
        }

        bool jaFezCheckin = checkins.any((chk) => chk.convite == conviteEscolhido);
        if (jaFezCheckin) {
          print('Este convidado já fez check-in anteriormente.');
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
        if (checkins.isEmpty) {
          print('Nenhum check-in realizado ainda.');
        } else {
          for (var chk in checkins) {
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