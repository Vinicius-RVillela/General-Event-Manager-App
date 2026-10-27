import 'banco.dart';
import 'Evento.dart';
import 'validacao.dart';

/// Lista os eventos e mostra TODAS as informações do escolhido, direto do banco.
Future<void> exibirEventoPorEscolha(List<Evento> eventos, Evento? ativo) async {
  if (eventos.isEmpty) {
    print('Nenhum evento cadastrado.');
    return;
  }

  for (var e in eventos) {
    final marcador = identical(e, ativo) ? '*' : ' ';
    print('$marcador ${e.idBanco} - ${e.nomeEvento}');
  }
  print('Digite o ID do evento (Enter para usar o evento ativo): ');
  final entrada = lerLinha().trim();

  Evento? escolhido = ativo;
  if (entrada.isNotEmpty) {
    final id = int.tryParse(entrada);
    escolhido = null;
    for (var e in eventos) {
      if (e.idBanco == id) {
        escolhido = e;
        break;
      }
    }
  }

  if (escolhido == null) {
    print('Evento não encontrado.');
    return;
  }
  await exibirEventoCompleto(escolhido);
}

/// Mostra todas as colunas de cada tabela ligada ao evento.
Future<void> exibirEventoCompleto(Evento evento) async {
  final id = evento.idBanco;
  if (id == null) {
    print('Este evento ainda não tem id no banco.');
    return;
  }

  final dados = await banco.buscarDetalhesEvento(id);
  _secao('EVENTO (tabela evento)', dados['evento']!);
  _secao('HISTÓRICO (tabela historico_evento)', dados['historico']!);
  _secao('MESAS (tabela mesa)', dados['mesas']!);
  _secao('CONVITES + CONVIDADOS (tabelas convite e convidado)', dados['convites']!);
  _secao('CHECK-INS (tabela checkin)', dados['checkins']!);
}

void _secao(String titulo, List<Map<String, String?>> linhas) {
  print('\n=== $titulo: ${linhas.length} registro(s) ===');
  if (linhas.isEmpty) {
    print('(nenhum registro)');
    return;
  }
  for (final linha in linhas) {
    print(linha.entries.map((e) => '${e.key}: ${e.value ?? '-'}').join(' | '));
  }
}
