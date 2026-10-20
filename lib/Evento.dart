import 'dart:io';

import 'Organizador.dart';
import 'HistoricoEvento.dart';
import './endereco.dart';
import 'usuario.dart' show normalizar;
import 'validacao.dart';

class Evento {
  static int _proximoId = 1;
  late final int id;
  String? nomeEvento;
  DateTime? dataEvento;
  String? descricao;
  Organizador? organizador;
  HistoricoEvento? historicoEvento;
  Endereco? enderecoevento;
  String? tipodeevento;

  Evento({
    this.nomeEvento,
    this.dataEvento,
    this.descricao,
    this.organizador,
    this.historicoEvento,
    this.enderecoevento,
    this.tipodeevento,
  }) {
    id = _proximoId++;
  }

  /// Pergunta os dados básicos do evento no terminal e preenche este objeto.
  /// Nome, data e descrição são obrigatórios: o programa repete a pergunta
  /// até receber um valor válido (a data precisa existir de verdade).
  void cadastrarEvento() {
    nomeEvento = lerTextoNaoVazio('Digite o nome do evento: ');
    dataEvento = lerDataValida(
      'Digite a data do evento (formato dd/mm/aaaa): ',
    );
    descricao = lerTextoNaoVazio('Digite uma descrição para o evento: ');
  }

  String obterDadosEvento() {
    return 'ID: $id | Nome: $nomeEvento | Tipo: $tipodeevento | Data: ${formatarData(dataEvento)} | Descrição: $descricao';
  }
}

// -----------------------------------------------------------------
// MOCK: lista de tipos de evento em memória. Os três primeiros já
// vêm prontos; os outros são criados pelo usuário durante o uso.
// Quando integrar o MySQL, troque só o CORPO das funções abaixo:
//   - obterTiposEventoDisponiveis -> SELECT nome FROM tipos_evento;
//   - criarTipoEvento             -> INSERT INTO tipos_evento (nome) ...
// e o resto do programa continua funcionando igual.
// -----------------------------------------------------------------
final List<String> _tiposEvento = [
  'Casamento',
  'Evento Corporativo',
  'Aniversario',
];

List<String> obterTiposEventoDisponiveis() {
  return List.unmodifiable(_tiposEvento);
}

/// Pergunta o nome de um novo tipo de evento e o adiciona à lista.
/// Se o tipo já existir (ignorando maiúsculas e acentos), não duplica:
/// avisa e devolve o tipo que já estava cadastrado.
String criarTipoEvento() {
  String nome = lerTextoNaoVazio('Digite o nome do novo tipo de evento: ');

  for (var tipo in _tiposEvento) {
    if (normalizar(tipo) == normalizar(nome)) {
      print('O tipo "$tipo" já existe — vamos usar ele.');
      return tipo;
    }
  }

  _tiposEvento.add(nome);
  print('Tipo de evento "$nome" criado com sucesso!');
  return nome;
}

/// Mostra o menu de tipos de evento e devolve o tipo escolhido.
/// O menu inclui a opção de criar um tipo novo, que já devolve o tipo criado.
/// Devolve null se o usuário escolher "Sair".
String? escolherTipoEvento() {
  while (true) {
    List<String> tipos = obterTiposEventoDisponiveis();

    print('Escolha o tipo de evento que deseja gerir:');
    for (int i = 0; i < tipos.length; i++) {
      print('${i + 1} - ${tipos[i]}');
    }
    print('${tipos.length + 1} - Criar novo tipo de evento');
    print('${tipos.length + 2} - Sair');

    int? opcao = int.tryParse(stdin.readLineSync() ?? '');

    if (opcao == null || opcao < 1 || opcao > tipos.length + 2) {
      print('Opção inválida.');
      continue; // pergunta de novo, em vez de cancelar tudo
    }

    if (opcao <= tipos.length) {
      return tipos[opcao - 1];
    }

    if (opcao == tipos.length + 1) {
      return criarTipoEvento();
    }

    return null; // Sair
  }
}
