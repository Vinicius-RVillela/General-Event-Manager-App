import 'banco.dart';
import 'Checkin.dart';
import 'Convite.dart';
import 'convidado.dart';
import 'validacao.dart';

/// Menu de convidados. Cadastrar, editar e remover gravam no banco.
Future<void> gerenciarConvidados(
  List<Convidado> convidados,
  List<Convite> convites,
  List<Checkin> checkins,
) async {
  bool continuar = true;

  while (continuar) {
    print('\nGerenciador de convidados');
    print('1 - Cadastrar');
    print('2 - Remover');
    print('3 - Listar todos');
    print('4 - Buscar convidado');
    print('5 - Editar convidado (mantém convites e check-ins)');
    print('6 - Voltar');

    String opcao = lerLinha().trim();

    switch (opcao) {
      case '1':
        var novo = Convidado();
        novo.cadastrar();
        try {
          await banco.salvarConvidado(novo);
        } catch (e) {
          print('Erro ao salvar convidado no banco: $e');
          break;
        }
        convidados.add(novo);
        print('Convidado salvo no banco com sucesso!');
        break;

      case '2':
        print('Digite o ID do convidado que será removido: ');
        int? id = int.tryParse(lerLinha().trim());
        if (id == null) {
          print('ID inválido.');
          break;
        }

        Convidado? encontrado;
        for (var c in convidados) {
          if (c.idBanco == id) {
            encontrado = c;
            break;
          }
        }
        if (encontrado == null) {
          print('Convidado não encontrado.');
          break;
        }

        final alvo = encontrado;
        print('Deseja remover ${alvo.nome}? Ele também sairá de todos os eventos. (Sim/Não)');
        if (lerLinha().trim() != 'Sim') {
          print('Remoção cancelada.');
          break;
        }

        // Eventos que perdem convites com essa remoção, para recalcular o histórico.
        final afetados = convites
            .where((cv) => cv.convidado == alvo)
            .map((cv) => cv.evento)
            .toSet();

        try {
          await banco.removerConvidado(alvo);
        } catch (e) {
          print('Erro ao remover do banco. Nada foi alterado. Detalhe: $e');
          break;
        }

        convites.removeWhere((cv) => cv.convidado == alvo);
        checkins.removeWhere((chk) => chk.convite.convidado == alvo);
        convidados.remove(alvo);
        for (final evento in afetados) {
          await banco.sincronizarHistorico(evento, convites, checkins);
        }
        print('Convidado removido com sucesso.');
        break;

      case '3':
        if (convidados.isEmpty) {
          print('Nenhum convidado cadastrado.');
        } else {
          for (var c in convidados) {
            print(c.obterDados());
          }
        }
        break;

      case '4':
        print('Digite o ID do convidado que deseja buscar: ');
        int? id = int.tryParse(lerLinha().trim());
        if (id == null) {
          print('ID inválido.');
          break;
        }

        Convidado? achado;
        for (var c in convidados) {
          if (c.idBanco == id) {
            achado = c;
            break;
          }
        }
        if (achado == null) {
          print('Convidado não encontrado.');
        } else {
          print('--- Convidado encontrado ---');
          print(achado.obterDados());
        }
        break;

      case '5':
        print('Digite o ID do convidado que será editado: ');
        int? idEditar = int.tryParse(lerLinha().trim());

        Convidado? paraEditar;
        for (var c in convidados) {
          if (c.idBanco == idEditar) {
            paraEditar = c;
            break;
          }
        }
        if (paraEditar == null) {
          print('Convidado não encontrado.');
          break;
        }

        final original = paraEditar;
        final alterado = original.editarNoTerminal();
        try {
          await banco.atualizarConvidado(alterado);
        } catch (e) {
          print('Erro ao atualizar no banco. Nada foi alterado. Detalhe: $e');
          break;
        }
        original.nome = alterado.nome;
        original.email = alterado.email;
        original.telefone = alterado.telefone;
        original.idade = alterado.idade;
        original.assento = alterado.assento;
        print('Dados atualizados: ${original.obterDados()}');
        break;

      case '6':
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
