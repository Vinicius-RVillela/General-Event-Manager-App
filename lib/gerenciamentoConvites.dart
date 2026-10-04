import 'dart:io';
import 'convidado.dart';
import 'Convite.dart';
import 'Evento.dart';

/// Gerencia a criação e confirmação de convites, ligando um Convidado
/// já cadastrado ao Evento que o usuário logado está gerenciando.
///
/// MOCK: por enquanto os convites ficam em memória, na lista compartilhada
/// vinda do main.dart. Quando o MySQL entrar, cada opção do menu (criar,
/// confirmar, listar) vira uma consulta/insert no banco — a estrutura da
/// classe Convite já está pronta pra isso.
void gerenciarConvites(List<Convidado> convidados, List<Convite> convites, Evento evento) {
  bool continuar = true;

  while (continuar) {
    print('\n=== Gerenciador de Convites (${evento.nomeEvento}) ===');
    print('1 - Criar convite');
    print('2 - Confirmar/Recusar convite');
    print('3 - Listar convites');
    print('4 - Sair');

    String opcao = stdin.readLineSync()!;

    switch (opcao) {
      case '1':
        if (convidados.isEmpty) {
          print('Nenhum convidado cadastrado ainda. Cadastre um convidado primeiro.');
          break;
        }
        print('Convidados disponíveis:');
        for (var c in convidados) {
          print('${c.id} - ${c.nome}');
        }
        print('Digite o ID do convidado a convidar: ');
        int? idConvidado = int.tryParse(stdin.readLineSync()!);

        Convidado? convidadoEscolhido;
        for (var c in convidados) {
          if (c.id == idConvidado) {
            convidadoEscolhido = c;
            break;
          }
        }

        if (convidadoEscolhido == null) {
          print('Convidado não encontrado.');
          break;
        }

        var novoConvite = Convite(evento: evento, convidado: convidadoEscolhido);
        convites.add(novoConvite);
        print('Convite criado com sucesso! ${novoConvite.obterDados()}');
        break;

      case '2':
        if (convites.isEmpty) {
          print('Nenhum convite criado ainda.');
          break;
        }
        print('Digite o ID do convite: ');
        int? idConvite = int.tryParse(stdin.readLineSync()!);

        Convite? conviteEscolhido;
        for (var c in convites) {
          if (c.id == idConvite) {
            conviteEscolhido = c;
            break;
          }
        }

        if (conviteEscolhido == null) {
          print('Convite não encontrado.');
          break;
        }

        print('1 - Confirmar   2 - Recusar');
        String resposta = stdin.readLineSync()!;
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

      case '3':
        if (convites.isEmpty) {
          print('Nenhum convite criado ainda.');
        } else {
          for (var c in convites) {
            print(c.obterDados());
          }
        }
        break;

      case '4':
        print('Saindo do gerenciador de convites...');
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}