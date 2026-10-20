import 'dart:io';

import 'convidado.dart';
import 'Convite.dart';
import 'Evento.dart';

/// Gerencia a criação e confirmação de convites, ligando um Convidado
/// ao Evento que o usuário logado está gerenciando.
///
/// Agora tudo é filtrado pelo evento ativo: a lista de convites é
/// compartilhada entre todos os eventos, mas cada menu só mostra e altera
/// os convites do evento atual.
///
/// MOCK: por enquanto os convites ficam em memória, na lista compartilhada
/// vinda do main.dart. Quando o MySQL entrar, cada opção do menu (criar,
/// confirmar, listar) vira uma consulta/insert no banco — a estrutura da
/// classe Convite já está pronta pra isso.
void gerenciarConvites(
  List<Convidado> convidados,
  List<Convite> convites,
  Evento evento,
) {
  bool continuar = true;

  while (continuar) {
    // Recalculada a cada volta do menu, porque a lista muda durante o uso.
    final convitesDoEvento = convites.where((c) => c.evento == evento).toList();

    print('\n=== Gerenciador de Convites (${evento.nomeEvento}) ===');
    print('1 - Convidar pessoa já cadastrada');
    print('2 - Cadastrar nova pessoa e convidar');
    print('3 - Confirmar/Recusar convite');
    print('4 - Listar convites do evento');
    print('5 - Sair');

    String opcao = stdin.readLineSync() ?? '';

    switch (opcao) {
      case '1':
        if (convidados.isEmpty) {
          print(
            'Nenhum convidado cadastrado ainda. Use a opção 2 para cadastrar e convidar.',
          );
          break;
        }

        // Só mostra quem ainda NÃO foi convidado para este evento.
        final disponiveis = convidados
            .where((c) => !convitesDoEvento.any((cv) => cv.convidado == c))
            .toList();

        if (disponiveis.isEmpty) {
          print(
            'Todos os convidados cadastrados já foram convidados para este evento.',
          );
          break;
        }

        print('Convidados disponíveis:');
        for (var c in disponiveis) {
          print('${c.id} - ${c.nome}');
        }
        print('Digite o ID do convidado a convidar: ');
        int? idConvidado = int.tryParse(stdin.readLineSync() ?? '');

        Convidado? convidadoEscolhido;
        for (var c in disponiveis) {
          if (c.id == idConvidado) {
            convidadoEscolhido = c;
            break;
          }
        }

        if (convidadoEscolhido == null) {
          print('Convidado não encontrado entre os disponíveis.');
          break;
        }

        var novoConvite = Convite(
          evento: evento,
          convidado: convidadoEscolhido,
        );
        convites.add(novoConvite);
        print('Convite criado com sucesso! ${novoConvite.obterDados()}');
        break;

      case '2':
        var novoConvidado = Convidado();
        novoConvidado.cadastrar();
        convidados.add(novoConvidado);

        var conviteNovo = Convite(evento: evento, convidado: novoConvidado);
        convites.add(conviteNovo);
        print('Convidado cadastrado e convidado para o evento!');
        print(conviteNovo.obterDados());
        break;

      case '3':
        if (convitesDoEvento.isEmpty) {
          print('Nenhum convite criado para este evento ainda.');
          break;
        }

        for (var c in convitesDoEvento) {
          print(c.obterDados());
        }
        print('Digite o ID do convite: ');
        int? idConvite = int.tryParse(stdin.readLineSync() ?? '');

        Convite? conviteEscolhido;
        for (var c in convitesDoEvento) {
          if (c.id == idConvite) {
            conviteEscolhido = c;
            break;
          }
        }

        if (conviteEscolhido == null) {
          print('Convite não encontrado neste evento.');
          break;
        }

        print('1 - Confirmar   2 - Recusar');
        String resposta = stdin.readLineSync() ?? '';
        if (resposta == '1') {
          conviteEscolhido.status = StatusConfirmacao.confirmado;
          print('Convite confirmado.');
        } else if (resposta == '2') {
          conviteEscolhido.status = StatusConfirmacao.recusado;
          print('Convite recusado.');
        } else {
          print('Opção inválida.');
        }
        break;

      case '4':
        if (convitesDoEvento.isEmpty) {
          print('Nenhum convite criado para este evento ainda.');
        } else {
          for (var c in convitesDoEvento) {
            print(c.obterDados());
          }
          int confirmados = convitesDoEvento
              .where((c) => c.status == StatusConfirmacao.confirmado)
              .length;
          int pendentes = convitesDoEvento
              .where((c) => c.status == StatusConfirmacao.pendente)
              .length;
          int recusados = convitesDoEvento
              .where((c) => c.status == StatusConfirmacao.recusado)
              .length;
          print(
            'Total: ${convitesDoEvento.length} | Confirmados: $confirmados | '
            'Pendentes: $pendentes | Recusados: $recusados',
          );
        }
        break;

      case '5':
        print('Saindo do gerenciador de convites...');
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
