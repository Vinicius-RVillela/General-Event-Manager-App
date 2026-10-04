import 'dart:io';
import 'Organizador.dart';
import 'HistoricoEvento.dart';
import './endereco.dart';

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
  void cadastrarEvento() {
    print('Digite o nome do evento: ');
    nomeEvento = stdin.readLineSync();

    print('Digite a data do evento (formato dd/mm/aaaa): ');
    String? dataDigitada = stdin.readLineSync();
    if (dataDigitada != null && dataDigitada.contains('/')) {
      var partes = dataDigitada.split('/');
      if (partes.length == 3) {
        int? dia = int.tryParse(partes[0]);
        int? mes = int.tryParse(partes[1]);
        int? ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) {
          dataEvento = DateTime(ano, mes, dia);
        }
      }
    }
    if (dataEvento == null) {
      print('Data inválida ou não informada — deixada em branco.');
    }

    print('Digite uma descrição para o evento: ');
    descricao = stdin.readLineSync();
  }

  String obterDadosEvento() {
    return 'ID: $id | Nome: $nomeEvento | Tipo: $tipodeevento | Data: $dataEvento | Descrição: $descricao';
  }
}

// -----------------------------------------------------------------
// MOCK: dados de teste. Quando integrar o MySQL, troque só o CORPO
// desta função por uma consulta ao banco (ex: SELECT nome FROM
// tipos_evento;) e devolva os nomes encontrados nessa mesma lista.
// -----------------------------------------------------------------
List<String> obterTiposEventoDisponiveis() {
  return ['Casamento', 'Evento Corporativo', 'Aniversario'];
}

/// Mostra o menu de tipos de evento e devolve o tipo escolhido.
/// Devolve null se o usuário escolher "Sair".
String? escolherTipoEvento() {
  List<String> tipos = obterTiposEventoDisponiveis();

  print('Escolha o tipo de evento que deseja gerir:');
  for (int i = 0; i < tipos.length; i++) {
    print('${i + 1} - ${tipos[i]}');
  }
  print('${tipos.length + 1} - Sair');

  String opcaoDigitada = stdin.readLineSync()!;
  int? opcao = int.tryParse(opcaoDigitada);

  switch (opcao) {
    case 1:
      return tipos[0];
    case 2:
      return tipos[1];
    case 3:
      return tipos[2];
    case 4:
      return null; // Sair
    default:
      print('Opção inválida.');
      return null;
  }
}