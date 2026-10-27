import 'banco.dart';
import 'validacao.dart';

/// Menu de consulta somente leitura às tabelas do banco.
Future<void> consultarBanco() async {
  final tabelas = consultasLeitura.keys.toList();

  while (true) {
    print('\n=== Consultar banco (somente leitura) ===');
    for (int i = 0; i < tabelas.length; i++) {
      print('${i + 1} - ${tabelas[i]}');
    }
    print('0 - Voltar');

    int? opcao = int.tryParse(lerLinha().trim());
    if (opcao == 0) return;
    if (opcao == null || opcao < 1 || opcao > tabelas.length) {
      print('Opção inválida.');
      continue;
    }

    final tabela = tabelas[opcao - 1];
    try {
      final linhas = await banco.consultarTabela(tabela);
      print('\n--- $tabela (${linhas.length} registro(s)) ---');
      for (final linha in linhas) {
        print(linha.entries.map((e) => '${e.key}: ${e.value ?? '-'}').join(' | '));
      }
    } catch (e) {
      print('Erro ao consultar $tabela: $e');
    }
  }
}
