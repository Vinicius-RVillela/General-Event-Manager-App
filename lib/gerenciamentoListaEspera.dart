import 'banco.dart';
import 'Checkin.dart';
import 'Convite.dart';
import 'convidado.dart';
import 'Evento.dart';
import 'ListaEspera.dart';
import 'vagas_evento.dart';
import 'validacao.dart';

// =====================================================================
// LISTA DE ESPERA pelo terminal.
//
// Toda a REGRA fica aqui no código:
//   - quem pode entrar na fila e em qual posição;
//   - o cálculo de vagas (classe VagasEvento);
//   - quem ganha a vaga quando ela abre (o 1º da fila);
//   - o histórico de quem saiu da fila (promovido ou removido).
// O banco só GUARDA os dados.
//
// Qualquer usuário logado (administrador ou organizador) pode usar,
// porque a fila faz parte da organização do evento.
// =====================================================================

Future<void> gerenciarListaEspera(
  List<Convidado> convidados,
  List<Convite> convites,
  List<Checkin> checkins,
  Evento evento,
) async {
  bool continuar = true;

  while (continuar) {
    // Lê a fila de novo a cada volta: assim ela está sempre atualizada.
    final fila = await banco.carregarListaEspera(evento, convidados);
    final vagas = VagasEvento.calcular(evento, convites, fila);

    print('\nLista de espera (${evento.nomeEvento})');
    print(vagas.resumo());
    print('1 - Ver a fila e as vagas');
    print('2 - Definir ou alterar o limite de vagas');
    print('3 - Colocar pessoa na fila');
    print('4 - Promover da fila (dar as vagas livres)');
    print('5 - Remover pessoa da fila');
    print('6 - Ver histórico da fila');
    print('7 - Voltar');

    final opcao = lerLinha().trim();

    switch (opcao) {
      case '1':
        _mostrarFila(fila, vagas);
        break;

      case '2':
        await _alterarLimite(evento, vagas);
        break;

      case '3':
        await _colocarNaFilaInterativo(evento, convidados, convites, fila, vagas);
        break;

      case '4':
        await _promoverInterativo(evento, convites, checkins, fila, vagas);
        break;

      case '5':
        await _removerInterativo(fila);
        break;

      case '6':
        await _mostrarHistorico(evento);
        break;

      case '7':
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}

// ---------------------------------------------------------------------
// Funções usadas também pelo Gerenciador de convites
// ---------------------------------------------------------------------

/// Calcula as vagas do evento agora (lê a fila do banco e conta os convites).
Future<VagasEvento> vagasDoEvento(
  Evento evento,
  List<Convidado> convidados,
  List<Convite> convites,
) async {
  final fila = await banco.carregarListaEspera(evento, convidados);
  return VagasEvento.calcular(evento, convites, fila);
}

/// Ids dos convidados que estão na fila deste evento.
Future<Set<int?>> idsNaFila(Evento evento, List<Convidado> convidados) async {
  final fila = await banco.carregarListaEspera(evento, convidados);
  return fila.map((item) => item.convidado.idBanco).toSet();
}

/// Coloca a pessoa no FIM da fila. A posição é calculada aqui no código.
/// Devolve o item criado, ou null se não deu para colocar.
Future<ItemListaEspera?> colocarNaFila(
  Evento evento,
  Convidado convidado,
  List<Convidado> convidados,
  List<Convite> convites,
) async {
  final fila = await banco.carregarListaEspera(evento, convidados);

  // Regra 1: quem já tem convite neste evento não entra na fila.
  final jaConvidado = convites.any((c) => c.evento == evento && c.convidado == convidado);
  if (jaConvidado) {
    print('${convidado.nome} já tem convite para este evento.');
    return null;
  }
  // Regra 2: a mesma pessoa não pode estar duas vezes na fila.
  if (fila.any((item) => item.convidado == convidado)) {
    print('${convidado.nome} já está na fila deste evento.');
    return null;
  }

  // Regra 3: entra no fim da fila (maior posição + 1).
  int ultima = 0;
  for (final item in fila) {
    if (item.posicao > ultima) ultima = item.posicao;
  }
  final novo = ItemListaEspera(evento: evento, convidado: convidado, posicao: ultima + 1);

  try {
    await banco.adicionarListaEspera(novo);
  } catch (e) {
    print('Erro ao colocar na fila: $e');
    return null;
  }
  print('${convidado.nome} entrou na lista de espera na posição ${novo.posicao}.');
  return novo;
}

/// Quando abre uma vaga (alguém recusou), oferece a vaga ao 1º da fila.
/// Devolve true se alguém foi promovido.
Future<bool> oferecerVagaAoPrimeiro(
  Evento evento,
  List<Convidado> convidados,
  List<Convite> convites,
  List<Checkin> checkins,
) async {
  final fila = await banco.carregarListaEspera(evento, convidados);
  if (fila.isEmpty) return false;
  final vagas = VagasEvento.calcular(evento, convites, fila);
  if (vagas.cabemDaFila == 0) return false;

  final primeiro = fila.first;
  print('Abriu uma vaga! ${primeiro.convidado.nome} é o 1º da lista de espera.');
  if (!_sim('Dar a vaga para ${primeiro.convidado.nome}? (s/n)')) return false;
  return await _promover(primeiro, fila, convites, checkins);
}

// ---------------------------------------------------------------------
// Opções do menu
// ---------------------------------------------------------------------

void _mostrarFila(List<ItemListaEspera> fila, VagasEvento vagas) {
  print('--- Vagas ---');
  print(vagas.resumo());
  if (!vagas.temLimite) {
    print('Este evento não tem limite. Use a opção 2 para definir um.');
  }
  print('--- Fila (ordem de chegada) ---');
  if (fila.isEmpty) {
    print('Ninguém na fila.');
    return;
  }
  for (final item in fila) {
    print(item.obterDados());
  }
  if (vagas.cabemDaFila > 0) {
    print('${vagas.cabemDaFila} pessoa(s) da fila cabem agora. Use a opção 4.');
  }
}

Future<void> _alterarLimite(Evento evento, VagasEvento vagas) async {
  print('Limite atual: ${vagas.temLimite ? vagas.limite : 'sem limite'} '
      '(convites ativos: ${vagas.convitesAtivos})');
  print('Digite o novo limite (0 = sem limite): ');
  final novo = int.tryParse(lerLinha().trim());
  if (novo == null || novo < 0) {
    print('Valor inválido. Digite um número inteiro (0 = sem limite).');
    return;
  }
  final limite = novo == 0 ? null : novo;

  if (limite != null && limite < vagas.convitesAtivos) {
    print('Atenção: o evento já tem ${vagas.convitesAtivos} convites ativos, mais que $limite. '
        'Ninguém é desconvidado, mas não entram convites novos até sobrar vaga.');
    if (!_sim('Salvar mesmo assim? (s/n)')) return;
  }

  try {
    await banco.definirLimiteConvidados(evento, limite);
  } catch (e) {
    print('Erro ao salvar o limite: $e');
    return;
  }
  evento.limiteConvidados = limite;
  print(limite == null ? 'Evento agora está sem limite.' : 'Limite alterado para $limite.');

  // O limite aumentou e tem gente esperando? Avisa.
  final antes = vagas.vagasLivres ?? 0;
  final depois = limite == null ? null : (limite - vagas.convitesAtivos);
  if (vagas.pessoasNaFila > 0 && (depois == null || depois > antes)) {
    print('Abriram vagas e há ${vagas.pessoasNaFila} pessoa(s) na fila. '
        'Use a opção 4 para promover.');
  }
}

Future<void> _colocarNaFilaInterativo(
  Evento evento,
  List<Convidado> convidados,
  List<Convite> convites,
  List<ItemListaEspera> fila,
  VagasEvento vagas,
) async {
  final naFila = fila.map((item) => item.convidado).toSet();
  final disponiveis = convidados
      .where((c) =>
          !naFila.contains(c) &&
          !convites.any((cv) => cv.evento == evento && cv.convidado == c))
      .toList();
  if (disponiveis.isEmpty) {
    print('Não há convidados disponíveis: todos já foram convidados ou já estão na fila.');
    return;
  }

  if (!vagas.lotado) {
    if (vagas.temLimite) {
      print('Ainda há ${vagas.vagasLivres} vaga(s): a pessoa poderia ser convidada direto '
          '(menu 2 - Gerenciar convites).');
    } else {
      print('Este evento não tem limite de vagas: a pessoa poderia ser convidada direto.');
    }
    if (!_sim('Colocar na fila mesmo assim? (s/n)')) return;
  }

  print('Convidados disponíveis:');
  for (final c in disponiveis) {
    print('${c.idBanco} - ${c.nome}');
  }
  print('Digite o ID do convidado: ');
  final id = int.tryParse(lerLinha().trim());
  Convidado? escolhido;
  for (final c in disponiveis) {
    if (c.idBanco == id) {
      escolhido = c;
      break;
    }
  }
  if (escolhido == null) {
    print('Convidado não encontrado entre os disponíveis.');
    return;
  }
  await colocarNaFila(evento, escolhido, convidados, convites);
}

Future<void> _promoverInterativo(
  Evento evento,
  List<Convite> convites,
  List<Checkin> checkins,
  List<ItemListaEspera> fila,
  VagasEvento vagas,
) async {
  if (fila.isEmpty) {
    print('Ninguém na fila.');
    return;
  }

  int quantos;
  if (!vagas.temLimite) {
    // Sem limite: promove só o primeiro, se o usuário quiser.
    print('Evento sem limite de vagas.');
    if (!_sim('Dar convite para ${fila.first.convidado.nome} (1º da fila)? (s/n)')) return;
    quantos = 1;
  } else {
    quantos = vagas.cabemDaFila;
    if (quantos == 0) {
      print('Não há vagas livres (${vagas.convitesAtivos} de ${vagas.limite}). '
          'Aumente o limite (opção 2) ou espere alguém recusar o convite.');
      return;
    }
    print('Há ${vagas.vagasLivres} vaga(s) livre(s). '
        'Os $quantos primeiro(s) da fila vão ganhar convite:');
    for (final item in fila.take(quantos)) {
      print('  ${item.obterDados()}');
    }
    if (!_sim('Confirmar? (s/n)')) return;
  }

  // Promove sempre o 1º da fila, um de cada vez (a fila é relida a cada vez).
  int promovidos = 0;
  var atual = fila;
  for (int i = 0; i < quantos && atual.isNotEmpty; i++) {
    final ok = await _promover(atual.first, atual, convites, checkins);
    if (!ok) break;
    promovidos++;
    atual = await banco.carregarListaEspera(evento, atual.map((e) => e.convidado).toList());
  }
  print('$promovidos pessoa(s) saíram da fila e receberam convite.');
}

Future<void> _removerInterativo(List<ItemListaEspera> fila) async {
  if (fila.isEmpty) {
    print('Ninguém na fila.');
    return;
  }
  for (final item in fila) {
    print(item.obterDados());
  }
  print('Digite a POSIÇÃO de quem vai sair da fila: ');
  final posicao = int.tryParse(lerLinha().trim());
  ItemListaEspera? escolhido;
  for (final item in fila) {
    if (item.posicao == posicao) {
      escolhido = item;
      break;
    }
  }
  if (escolhido == null) {
    print('Posição não encontrada na fila.');
    return;
  }
  if (!_sim('Tirar ${escolhido.convidado.nome} da fila? (s/n)')) return;

  final restantes = _renumerar(fila, escolhido);
  try {
    await banco.removerDaListaEspera(escolhido, restantes);
  } catch (e) {
    print('Erro ao remover da fila. Nada foi alterado. Detalhe: $e');
    return;
  }
  print('${escolhido.convidado.nome} saiu da fila. Quem estava atrás subiu uma posição.');
}

Future<void> _mostrarHistorico(Evento evento) async {
  final linhas = await banco.historicoListaEspera(evento);
  print('--- Histórico da lista de espera ---');
  if (linhas.isEmpty) {
    print('Ninguém saiu da fila deste evento ainda.');
    return;
  }
  int promovidos = 0;
  for (final l in linhas) {
    final motivo = l['motivo'] == 'promovido' ? 'ganhou a vaga' : 'foi removido(a)';
    if (l['motivo'] == 'promovido') promovidos++;
    print('${l['saiu_em']} | ${l['nome'] ?? '(convidado apagado)'} | '
        'estava em ${l['posicao']}º | $motivo');
  }
  // Mais um cálculo feito no código: quanto da fila virou convite.
  final taxa = promovidos * 100 / linhas.length;
  print('Total: ${linhas.length} | Ganharam vaga: $promovidos '
      '(${taxa.toStringAsFixed(1)}%)');
}

// ---------------------------------------------------------------------
// Ajudantes
// ---------------------------------------------------------------------

/// Dá a vaga para o item: cria o convite, registra no histórico e tira da fila.
Future<bool> _promover(
  ItemListaEspera item,
  List<ItemListaEspera> fila,
  List<Convite> convites,
  List<Checkin> checkins,
) async {
  final convite = Convite(evento: item.evento, convidado: item.convidado);
  final restantes = _renumerar(fila, item);
  try {
    await banco.promoverDaListaEspera(item, convite, restantes);
  } catch (e) {
    print('Erro ao promover ${item.convidado.nome}. Nada foi gravado. Detalhe: $e');
    return false;
  }
  convites.add(convite);
  await banco.sincronizarHistorico(item.evento, convites, checkins);
  print('${item.convidado.nome} saiu da fila e recebeu o convite #${convite.idBanco}.');
  return true;
}

/// Tira [saindo] da fila e devolve só quem precisa mudar de posição,
/// já com a posição nova (1, 2, 3... sem buracos).
List<ItemListaEspera> _renumerar(List<ItemListaEspera> fila, ItemListaEspera saindo) {
  final mudaram = <ItemListaEspera>[];
  int posicao = 1;
  for (final item in fila) {
    if (item == saindo) continue;
    if (item.posicao != posicao) {
      item.posicao = posicao;
      mudaram.add(item);
    }
    posicao++;
  }
  return mudaram;
}

bool _sim(String pergunta) {
  print(pergunta);
  final r = lerLinha().trim().toLowerCase();
  return r == 's' || r == 'sim';
}
