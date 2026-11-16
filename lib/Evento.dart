import 'HistoricoEvento.dart';
import 'Mesa.dart';
import 'Registro.dart';
import 'usuario.dart' show normalizar;
import 'validacao.dart';

String _textoObrigatorio(String valor, String campo) {
  final limpo = valor.trim();
  if (limpo.isEmpty) {
    throw ArgumentError('O $campo não pode ficar vazio.');
  }
  return limpo;
}

class Evento extends Registro {
  String _nomeEvento;
  DateTime _dataEvento;
  String _descricao;
  String? _localEvento;
  String _tipodeevento;
  String? _nomeOrganizador;
  HistoricoEvento? _historicoEvento;
  Mesa? _mesaPadrao;
  int? _limiteConvidados; // null = sem limite de vagas

  Evento({
    super.idBanco,
    required String nomeEvento,
    required DateTime dataEvento,
    required String descricao,
    String? localEvento,
    required String tipodeevento,
    String? nomeOrganizador,
    HistoricoEvento? historicoEvento,
    Mesa? mesaPadrao,
    int? limiteConvidados,
  })  : _nomeEvento = _textoObrigatorio(nomeEvento, 'nome do evento'),
        _dataEvento = dataEvento,
        _descricao = descricao.trim(),
        _localEvento = localEvento?.trim(),
        _tipodeevento = _textoObrigatorio(tipodeevento, 'tipo do evento'),
        _nomeOrganizador = nomeOrganizador,
        _historicoEvento = historicoEvento,
        _mesaPadrao = mesaPadrao,
        _limiteConvidados = _limiteValido(limiteConvidados);

  Evento.doBanco({
    required int idBanco,
    required String nomeEvento,
    required DateTime dataEvento,
    required String descricao,
    String? localEvento,
    required String tipodeevento,
    String? nomeOrganizador,
    HistoricoEvento? historicoEvento,
    Mesa? mesaPadrao,
    int? limiteConvidados,
  }) : this(
          idBanco: idBanco,
          nomeEvento: nomeEvento,
          dataEvento: dataEvento,
          descricao: descricao,
          localEvento: localEvento,
          tipodeevento: tipodeevento,
          nomeOrganizador: nomeOrganizador,
          historicoEvento: historicoEvento,
          mesaPadrao: mesaPadrao,
          limiteConvidados: limiteConvidados,
        );

  String get nomeEvento => _nomeEvento;

  set nomeEvento(String valor) => _nomeEvento = _textoObrigatorio(valor, 'nome do evento');

  DateTime get dataEvento => _dataEvento;

  set dataEvento(DateTime valor) => _dataEvento = valor;

  String get descricao => _descricao;

  set descricao(String valor) => _descricao = valor.trim();

  String? get localEvento => _localEvento;

  set localEvento(String? valor) => _localEvento = valor?.trim();

  String get tipodeevento => _tipodeevento;

  set tipodeevento(String valor) => _tipodeevento = _textoObrigatorio(valor, 'tipo do evento');

  String? get nomeOrganizador => _nomeOrganizador;

  set nomeOrganizador(String? valor) => _nomeOrganizador = valor;

  HistoricoEvento? get historicoEvento => _historicoEvento;

  set historicoEvento(HistoricoEvento? valor) => _historicoEvento = valor;

  Mesa? get mesaPadrao => _mesaPadrao;

  set mesaPadrao(Mesa? valor) => _mesaPadrao = valor;

  /// Máximo de convites ativos (não recusados). null = evento sem limite.
  /// Pode mudar quando o evento cresce: é só usar o setter.
  int? get limiteConvidados => _limiteConvidados;

  set limiteConvidados(int? valor) => _limiteConvidados = _limiteValido(valor);

  /// O limite precisa ser pelo menos 1 (ou null, para "sem limite").
  static int? _limiteValido(int? valor) {
    if (valor != null && valor < 1) {
      throw ArgumentError('O limite de convidados precisa ser pelo menos 1: $valor');
    }
    return valor;
  }

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

  @override
  String obterDados() {
    return 'ID: $idBanco | Nome: $nomeEvento | Tipo: $tipodeevento | '
        'Data: ${formatarData(dataEvento)} | Local: ${localEvento ?? '-'} | '
        'Organizador: ${nomeOrganizador ?? '-'} | Descrição: $descricao';
  }
}

final List<String> _tiposEvento = [
  'Casamento',
  'Evento Corporativo',
  'Aniversario',
];

List<String> obterTiposEventoDisponiveis() => List.unmodifiable(_tiposEvento);

void registrarTipoEvento(String tipo) {
  final existe = _tiposEvento.any((t) => normalizar(t) == normalizar(tipo));
  if (!existe) _tiposEvento.add(tipo);
}

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
