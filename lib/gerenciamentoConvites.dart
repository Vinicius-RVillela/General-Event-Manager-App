import 'banco.dart';
import 'Checkin.dart';
import 'Convite.dart';
import 'convidado.dart';
import 'Evento.dart';
import 'gerenciamentoListaEspera.dart';
import 'validacao.dart';

Future<void> gerenciarConvites(
  List<Convidado> convidados,
  List<Convite> convites,
  List<Checkin> checkins,
  Evento evento,
) async {
  bool continuar = true;

  while (continuar) {
    final convitesDoEvento = convites.where((cv) => cv.evento == evento).toList();

    print('\nGerenciador de convites (${evento.nomeEvento})');
    print('1 - Convidar pessoa já cadastrada');
    print('2 - Cadastrar nova pessoa e convidar');
    print('3 - Confirmar/Recusar convite');
    print('4 - Listar convites do evento');
    print('5 - Voltar');

    String opcao = lerLinha().trim();

    switch (opcao) {
      case '1':
        if (convidados.isEmpty) {
          print('Nenhum convidado cadastrado. Use a opção 2 para cadastrar e convidar.');
          break;
        }

        // Quem está na fila sai dela pela Lista de espera (menu 11), não por aqui.
        final naFila = await idsNaFila(evento, convidados);
        final disponiveis = convidados
            .where((c) =>
                !convitesDoEvento.any((cv) => cv.convidado == c) &&
                !naFila.contains(c.idBanco))
            .toList();
        if (disponiveis.isEmpty) {
          print('Todos os convidados já foram convidados ou estão na lista de espera.');
          break;
        }

        print('Convidados disponíveis:');
        for (var c in disponiveis) {
          print('${c.idBanco} - ${c.nome}');
        }
        print('Digite o ID do convidado a convidar: ');
        int? id = int.tryParse(lerLinha().trim());

        Convidado? escolhido;
        for (var c in disponiveis) {
          if (c.idBanco == id) {
            escolhido = c;
            break;
          }
        }
        if (escolhido == null) {
          print('Convidado não encontrado entre os disponíveis.');
          break;
        }

        // Evento lotado? Em vez de convidar, a pessoa vai para a fila.
        final vagas = await vagasDoEvento(evento, convidados, convites);
        if (vagas.lotado) {
          print('Evento lotado (${vagas.convitesAtivos} de ${vagas.limite} vagas).');
          print('Colocar ${escolhido.nome} na lista de espera? (s/n)');
          if (lerLinha().trim().toLowerCase().startsWith('s')) {
            await colocarNaFila(evento, escolhido, convidados, convites);
          }
          break;
        }

        final convite = Convite(evento: evento, convidado: escolhido);
        try {
          await banco.salvarConvite(convite);
        } catch (e) {
          print('Erro ao salvar convite no banco: $e');
          break;
        }
        convites.add(convite);
        await banco.sincronizarHistorico(evento, convites, checkins);
        print('Convite criado: ${convite.obterDados()}');
        break;

      case '2':
        final vagasAgora = await vagasDoEvento(evento, convidados, convites);
        if (vagasAgora.lotado) {
          print('Evento lotado (${vagasAgora.convitesAtivos} de ${vagasAgora.limite} vagas): '
              'a pessoa será cadastrada e colocada na lista de espera.');
          final pessoa = Convidado();
          pessoa.cadastrar();
          try {
            await banco.salvarConvidado(pessoa);
          } catch (e) {
            print('Erro ao salvar no banco. Nada foi gravado. Detalhe: $e');
            break;
          }
          convidados.add(pessoa);
          await colocarNaFila(evento, pessoa, convidados, convites);
          break;
        }
        var novo = Convidado();
        novo.cadastrar();
        final conviteNovo = Convite(evento: evento, convidado: novo);
        try {
          await banco.cadastrarConvidadoEConvite(novo, conviteNovo);
        } catch (e) {
          print('Erro ao salvar no banco. Nada foi gravado. Detalhe: $e');
          break;
        }
        convidados.add(novo);
        convites.add(conviteNovo);
        await banco.sincronizarHistorico(evento, convites, checkins);
        print('Pessoa cadastrada e convidada: ${conviteNovo.obterDados()}');
        break;

      case '3':
        if (convitesDoEvento.isEmpty) {
          print('Nenhum convite criado para este evento ainda.');
          break;
        }
        for (var cv in convitesDoEvento) {
          print(cv.obterDados());
        }
        print('Digite o ID do convite: ');
        int? idConvite = int.tryParse(lerLinha().trim());

        Convite? escolhidoConvite;
        for (var cv in convitesDoEvento) {
          if (cv.idBanco == idConvite) {
            escolhidoConvite = cv;
            break;
          }
        }
        if (escolhidoConvite == null) {
          print('Convite não encontrado neste evento.');
          break;
        }

        print('1 - Confirmar   2 - Recusar');
        String resposta = lerLinha().trim();
        final StatusConfirmacao novoStatus;
        if (resposta == '1') {
          novoStatus = StatusConfirmacao.confirmado;
        } else if (resposta == '2') {
          novoStatus = StatusConfirmacao.recusado;
        } else {
          print('Opção inválida.');
          break;
        }

        // Reativar um convite recusado ocupa uma vaga de novo.
        if (escolhidoConvite.status == StatusConfirmacao.recusado &&
            novoStatus == StatusConfirmacao.confirmado) {
          final vagas = await vagasDoEvento(evento, convidados, convites);
          if (vagas.lotado) {
            print('Evento lotado: não há vaga para reativar este convite. '
                'Aumente o limite na Lista de espera (menu 11).');
            break;
          }
        }

        final statusAntes = escolhidoConvite.status;
        try {
          await banco.atualizarStatusConvite(escolhidoConvite, novoStatus);
        } catch (e) {
          print('Erro ao atualizar convite no banco: $e');
          break;
        }
        escolhidoConvite.status = novoStatus;
        await banco.sincronizarHistorico(evento, convites, checkins);
        print(novoStatus == StatusConfirmacao.confirmado
            ? 'Convite confirmado.'
            : 'Convite recusado.');

        // Recusou agora? A vaga abriu: o código oferece ao 1º da fila.
        if (novoStatus == StatusConfirmacao.recusado &&
            statusAntes != StatusConfirmacao.recusado) {
          await oferecerVagaAoPrimeiro(evento, convidados, convites, checkins);
        }
        break;

      case '4':
        if (convitesDoEvento.isEmpty) {
          print('Nenhum convite criado para este evento ainda.');
          break;
        }
        for (var cv in convitesDoEvento) {
          print(cv.obterDados());
        }
        int confirmados = convitesDoEvento
            .where((cv) => cv.status == StatusConfirmacao.confirmado)
            .length;
        int pendentes = convitesDoEvento
            .where((cv) => cv.status == StatusConfirmacao.pendente)
            .length;
        int recusados = convitesDoEvento
            .where((cv) => cv.status == StatusConfirmacao.recusado)
            .length;
        print('Total: ${convitesDoEvento.length} | Confirmados: $confirmados | '
            'Pendentes: $pendentes | Recusados: $recusados');
        break;

      case '5':
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
