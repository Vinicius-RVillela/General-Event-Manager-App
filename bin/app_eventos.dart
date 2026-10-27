import 'package:app_eventos/banco.dart';
import 'package:app_eventos/consultas_banco.dart';
import 'package:app_eventos/economia_insumos.dart';
import 'package:app_eventos/estatisticas_evento.dart';
import 'package:app_eventos/exibir_evento.dart';
import 'package:app_eventos/gerenciador_convidados.dart';
import 'package:app_eventos/gerenciamentoCheckin.dart';
import 'package:app_eventos/gerenciamentoConvites.dart';
import 'package:app_eventos/gerenciamentoEventos.dart';
import 'package:app_eventos/login.dart';
import 'package:app_eventos/validacao.dart';

Future<void> main() async {
  try {
    await banco.conectar();
  } catch (e) {
    print('Não foi possível conectar ao MySQL: $e');
    print('Confira ConfigBanco em lib/banco.dart (host, porta, usuário, senha, banco).');
    return;
  }

  try {
    final org = await executarLogin();
    if (org == null) return;

    // Carrega do banco tudo que existe (de todos os organizadores).
    final dados = await banco.carregarTudo();
    final eventos = dados.eventos;
    final convidados = dados.convidados;
    final convites = dados.convites;
    final checkins = dados.checkins;
    org.eventoGerenciado = eventos.isNotEmpty ? eventos.first : null;

    bool continuar = true;
    while (continuar) {
      print('\n=== MENU PRINCIPAL ===');
      print('Organizador: ${org.nome} | Evento ativo: ${org.eventoGerenciado?.nomeEvento ?? 'nenhum'}');
      print('1 - Gerenciar convidados');
      print('2 - Gerenciar convites');
      print('3 - Gerenciar check-in');
      print('4 - Sair');
      print('5 - Ver estatísticas');
      print('6 - Gerenciar eventos');
      print('7 - Consultar tabelas do banco');
      print('8 - Exibir evento (todas as informações do banco)');
      print('9 - Ver estatística após novo check-in');
      print('10 - Economia de insumos (evento ativo)');

      String opcao = lerLinha().trim();

      switch (opcao) {
        case '1':
          await gerenciarConvidados(convidados, convites, checkins);
          break;

        case '2':
          if (org.eventoGerenciado == null) {
            print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
          } else {
            await gerenciarConvites(convidados, convites, checkins, org.eventoGerenciado!);
          }
          break;

        case '3':
          if (org.eventoGerenciado == null) {
            print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
          } else {
            await gerenciarCheckin(convites, checkins, org.eventoGerenciado!);
          }
          break;

        case '4':
          continuar = false;
          break;

        case '5':
          final eventoAtivo = org.eventoGerenciado;
          if (eventoAtivo == null) {
            print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
            break;
          }
          final convitesDoEvento = convites.where((c) => c.evento == eventoAtivo).toList();
          final checkinsDoEvento =
              checkins.where((chk) => chk.convite.evento == eventoAtivo).toList();
          _imprimirEstatisticas(
            'Estatísticas de ${eventoAtivo.nomeEvento}',
            calcularEstatisticas(convitesDoEvento, checkinsDoEvento),
          );
          break;

        case '6':
          await gerenciarEventos(org, eventos);
          break;

        case '7':
          await consultarBanco();
          break;

        case '8':
          await exibirEventoPorEscolha(eventos, org.eventoGerenciado);
          break;

        case '9':
          final eventoAtivo = org.eventoGerenciado;
          if (eventoAtivo == null) {
            print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
            break;
          }
          final convitesDoEvento = convites.where((c) => c.evento == eventoAtivo).toList();
          final checkinsDoEvento =
              checkins.where((chk) => chk.convite.evento == eventoAtivo).toList();
          final agora = calcularEstatisticas(convitesDoEvento, checkinsDoEvento);
          _imprimirEstatisticas(
            'Estatísticas após novo check-in: ${eventoAtivo.nomeEvento}',
            agora,
          );

          final antes = estatisticasAntesDoRecheckin(eventoAtivo);
          if (antes == null) {
            print('(Nenhum refazer de check-in neste evento nesta sessão, '
                'então não há comparação.)');
          } else {
            _imprimirEstatisticas('Antes do último refazer de check-in', antes);
            print('Diferença em check-ins: ${agora.totalCheckins - antes.totalCheckins}');
            print('Diferença na presença: '
                '${(agora.percentualPresenca - antes.percentualPresenca).toStringAsFixed(1)} '
                'pontos percentuais');
          }
          break;

        case '10':
          final eventoAtivo = org.eventoGerenciado;
          if (eventoAtivo == null) {
            print('Nenhum evento ativo. Crie ou escolha um evento na opção 6.');
            break;
          }
          mostrarEconomiaInsumos(eventoAtivo, convites, checkins);
          break;

        default:
          print('Opção inválida.');
      }
    }

    if (org.idSessao != null) {
      await banco.encerrarSessao(org.idSessao!);
    }
    print('Sessão encerrada. Até logo!');
  } catch (e) {
    print('Erro inesperado: $e');
  } finally {
    await banco.desconectar();
  }
}

void _imprimirEstatisticas(String titulo, EstatisticasEvento s) {
  print('--- $titulo ---');
  print('Total de convites: ${s.totalConvites}');
  print('Confirmados: ${s.totalConfirmados} (${s.percentualConfirmados.toStringAsFixed(1)}%)');
  print('Check-ins: ${s.totalCheckins} (${s.percentualPresenca.toStringAsFixed(1)}% dos confirmados)');
}