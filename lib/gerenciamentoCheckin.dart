import 'banco.dart';
import 'Checkin.dart';
import 'Convite.dart';
import 'Evento.dart';
import 'estatisticas_evento.dart';
import 'validacao.dart';

/// Estatísticas do evento ANTES do último "refazer check-ins".
/// Fica só na memória desta execução; o banco guarda sempre o estado atual.
final Map<Evento, EstatisticasEvento> _antesDoRecheckin = {};

/// Estatísticas que existiam antes do último refazer, se houver nesta sessão.
EstatisticasEvento? estatisticasAntesDoRecheckin(Evento evento) =>
    _antesDoRecheckin[evento];

/// Check-in: só para convites CONFIRMADOS do evento ativo, uma vez por convite.
Future<void> gerenciarCheckin(
  List<Convite> convites,
  List<Checkin> checkins,
  Evento evento,
) async {
  bool continuar = true;

  while (continuar) {
    final confirmados = convites
        .where((cv) => cv.evento == evento && cv.status == StatusConfirmacao.confirmado)
        .toList();
    final checkinsDoEvento =
        checkins.where((chk) => chk.convite.evento == evento).toList();
    final aguardando = confirmados
        .where((cv) => !checkinsDoEvento.any((chk) => chk.convite == cv))
        .toList();

    print('\nGerenciador de check-in (${evento.nomeEvento})');
    print('Já chegaram: ${checkinsDoEvento.length} | Aguardando: ${aguardando.length}');
    print('1 - Fazer check-in');
    print('2 - Listar check-ins realizados');
    print('3 - Refazer check-ins deste evento (apaga os check-ins atuais)');
    print('4 - Voltar');

    String opcao = lerLinha().trim();

    switch (opcao) {
      case '1':
        if (confirmados.isEmpty) {
          print('Nenhum convite confirmado disponível neste evento.');
          break;
        }
        if (aguardando.isEmpty) {
          print('Todos os confirmados já fizeram check-in.');
          break;
        }

        print('Convidados aguardando check-in:');
        for (var cv in aguardando) {
          print('${cv.idBanco} - ${cv.convidado.nome}');
        }
        print('Digite o ID do convite para dar check-in: ');
        int? idConvite = int.tryParse(lerLinha().trim());

        Convite? escolhido;
        for (var cv in aguardando) {
          if (cv.idBanco == idConvite) {
            escolhido = cv;
            break;
          }
        }
        if (escolhido == null) {
          print('Convite não encontrado entre os que aguardam check-in.');
          break;
        }

        final checkin = Checkin(convite: escolhido);
        try {
          await banco.salvarCheckin(checkin);
        } catch (e) {
          print('Erro ao salvar check-in no banco: $e');
          break;
        }
        checkins.add(checkin);
        await banco.sincronizarHistorico(evento, convites, checkins);
        print('Check-in realizado! ${checkin.obterDados()}');
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
        if (checkinsDoEvento.isEmpty) {
          print('Este evento não tem check-ins para refazer.');
          break;
        }

        print('Isto apaga ${checkinsDoEvento.length} check-in(s) deste evento. '
            'Digite Sim para confirmar:');
        if (lerLinha().trim() != 'Sim') {
          print('Cancelado.');
          break;
        }

        final convitesDoEvento = convites.where((cv) => cv.evento == evento).toList();
        final antes = calcularEstatisticas(convitesDoEvento, checkinsDoEvento);
        try {
          await banco.apagarCheckinsDoEvento(evento);
        } catch (e) {
          print('Erro ao apagar check-ins no banco. Nada foi alterado. Detalhe: $e');
          break;
        }
        _antesDoRecheckin[evento] = antes;
        checkins.removeWhere((chk) => chk.convite.evento == evento);
        await banco.sincronizarHistorico(evento, convites, checkins);
        print('Check-ins apagados. Você pode fazer o check-in novamente.');
        break;

      case '4':
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}
