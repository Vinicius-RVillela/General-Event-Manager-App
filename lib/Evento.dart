import 'HistoricoEvento.dart';
import 'Mesa.dart';
import 'usuario.dart' show normalizar;
import 'validacao.dart';

/// Espelho da tabela evento, com seu histórico e sua mesa padrão.
class Evento {
  int? idBanco;
  String nomeEvento;
  DateTime dataEvento;
  String descricao;
  String? localEvento;
  String tipodeevento;
  String? nomeOrganizador; // quem criou o evento (para exibição)
  HistoricoEvento? historicoEvento;
  Mesa? mesaPadrao;

  Evento({
    this.idBanco,
    required this.nomeEvento,
    required this.dataEvento,
    required this.descricao,
    this.localEvento,
    required this.tipodeevento,
    this.nomeOrganizador,
    this.historicoEvento,
    this.mesaPadrao,
  });

  /// Pergunta os dados do evento no terminal e devolve um Evento ainda NÃO salvo.
  static Evento lerDoTerminal(String tipo) {
    final nome = lerTextoNaoVazio('Digite o nome do evento: ');
    final data = lerDataValida('Digite a data do evento (dd/mm/aaaa): ');
    final local = lerTextoOpcional('Digite o local do evento (Enter para pular): ');
    final descricao = lerTextoNaoVazio('Digite uma descrição para o evento: ');
    return Evento(
      nomeEvento: nome,
      dataEvento: data,
      localEvento: local,
      descricao: descricao,
      tipodeevento: tipo,
    );
  }

  String obterDadosEvento() {
    return 'ID: $idBanco | Nome: $nomeEvento | Tipo: $tipodeevento | '
        'Data: ${formatarData(dataEvento)} | Local: ${localEvento ?? '-'} | '
        'Organizador: ${nomeOrganizador ?? '-'} | Descrição: $descricao';
  }
}

// Tipos de evento: o padrão vem fixo; os criados pelo usuário e os que já
// existem no banco (coluna tipo_evento) são somados à lista.
final List<String> _tiposEvento = [
  'Casamento',
  'Evento Corporativo',
  'Aniversario',
];

List<String> obterTiposEventoDisponiveis() => List.unmodifiable(_tiposEvento);

/// Adiciona um tipo vindo do banco à lista, sem duplicar.
void registrarTipoEvento(String tipo) {
  final existe = _tiposEvento.any((t) => normalizar(t) == normalizar(tipo));
  if (!existe) _tiposEvento.add(tipo);
}

/// Pergunta o nome de um novo tipo. Se já existir, reaproveita o existente.
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

/// Mostra o menu de tipos e devolve o escolhido. Null se o usuário sair.
String? escolherTipoEvento() {
  while (true) {
    List<String> tipos = obterTiposEventoDisponiveis();

    print('Escolha o tipo de evento:');
    for (int i = 0; i < tipos.length; i++) {
      print('${i + 1} - ${tipos[i]}');
    }
    print('${tipos.length + 1} - Criar novo tipo de evento');
    print('${tipos.length + 2} - Sair');

    int? opcao = int.tryParse(lerLinha().trim());

    if (opcao == null || opcao < 1 || opcao > tipos.length + 2) {
      print('Opção inválida.');
      continue;
    }
    if (opcao <= tipos.length) return tipos[opcao - 1];
    if (opcao == tipos.length + 1) return criarTipoEvento();
    return null;
  }
}
