import 'dart:convert';
import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

import 'Checkin.dart';
import 'Convite.dart';
import 'HistoricoEvento.dart';
import 'Mesa.dart';
import 'Organizador.dart';
import 'Evento.dart';
import 'ListaEspera.dart';
import 'convidado.dart';

class ConfigBanco {
  static String host = 'localhost';
  static int port = 3306;
  static String usuario = 'root';
  static String senha = 'root';
  static String nomeBanco = 'mydb';

  static void carregar() {
    final arquivo = File('config.json');
    if (arquivo.existsSync()) {
      final json = jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
      host = json['host']?.toString() ?? host;
      port = int.tryParse('${json['port'] ?? ''}') ?? port;
      usuario = json['usuario']?.toString() ?? usuario;
      senha = json['senha']?.toString() ?? senha;
      nomeBanco = json['nomeBanco']?.toString() ?? nomeBanco;
    }
    final env = Platform.environment;
    host = env['DB_HOST'] ?? host;
    port = int.tryParse(env['DB_PORT'] ?? '') ?? port;
    usuario = env['DB_USER'] ?? usuario;
    senha = env['DB_PASSWORD'] ?? senha;
    nomeBanco = env['DB_NAME'] ?? nomeBanco;
  }
}

const Map<String, String> consultasLeitura = {
  'usuario':
      'SELECT id_usuario AS id, nome, email, telefone, ativo FROM usuario ORDER BY id_usuario',
  'evento':
      'SELECT idevento AS id, nome, data_evento, local_evento, tipo_evento, '
      'organizador_id_organizador AS organizador FROM evento ORDER BY idevento',
  'convidado':
      'SELECT idconvidado AS id, nome, email, telefone, idade, assento '
      'FROM convidado ORDER BY idconvidado',
  'convite':
      'SELECT idconvite AS id, status_confirmacao AS status, evento_idevento AS evento, '
      'convidado_idconvidado AS convidado, mesa_numero_mesa AS mesa '
      'FROM convite ORDER BY idconvite',
  'checkin':
      'SELECT idcheckin AS id, data_hora, presente, convite_idconvite AS convite '
      'FROM checkin ORDER BY idcheckin',
  'mesa':
      'SELECT idmesa AS id, numero_mesa AS numero, capacidade, evento_idevento AS evento '
      'FROM mesa ORDER BY idmesa',
  'historico_evento':
      'SELECT idhistorico_evento AS id, total_convidados, total_presentes, '
      'taxa_comparecimento AS taxa FROM historico_evento ORDER BY idhistorico_evento',
  'login_registro':
      'SELECT idlogin_registro AS id, email_informado AS email, sucesso, data_hora, '
      'usuario_id_usuario AS organizador FROM login_registro '
      'ORDER BY idlogin_registro DESC LIMIT 200',
  'sessao_login':
      'SELECT idsessao AS id, inicio, fim, usuario_id_usuario AS organizador '
      'FROM sessao_login ORDER BY idsessao DESC LIMIT 200',
  'lista_espera':
      'SELECT idlista_espera AS id, evento_idevento AS evento, '
      'convidado_idconvidado AS convidado, posicao, criado_em '
      'FROM lista_espera ORDER BY evento_idevento, posicao',
  'historico_lista_espera':
      'SELECT idhistorico_lista_espera AS id, evento_idevento AS evento, '
      'convidado_idconvidado AS convidado, posicao, entrou_em, saiu_em, motivo '
      'FROM historico_lista_espera ORDER BY saiu_em DESC LIMIT 200',
};

final BancoDeDados banco = BancoDeDados();

class DadosCarregados {
  final List<Evento> eventos;
  final List<Convidado> convidados;
  final List<Convite> convites;
  final List<Checkin> checkins;

  DadosCarregados({
    required this.eventos,
    required this.convidados,
    required this.convites,
    required this.checkins,
  });
}

int _int(String? valor) => int.parse(valor!);
int? _intOpt(String? valor) => valor == null ? null : int.parse(valor);

class BancoDeDados {
  MySQLConnection? _conexao;

  Future<void> conectar() async {
    final conn = await MySQLConnection.createConnection(
      host: ConfigBanco.host,
      port: ConfigBanco.port,
      userName: ConfigBanco.usuario,
      password: ConfigBanco.senha,
      databaseName: ConfigBanco.nomeBanco,
      secure: false,
    );
    await conn.connect();
    _conexao = conn;
    // Avisa a trigger tg_saiu_da_fila que ESTE programa grava o histórico da
    // lista de espera sozinho. A variável vale só para esta conexão; outros
    // programas (como o app com API) continuam com a trigger como reserva.
    await conn.execute('SET @historico_pelo_codigo = 1');
  }

  Future<void> desconectar() async {
    await _conexao?.close();
    _conexao = null;
  }

  Future<void> ping() async {
    await _conn.execute('SELECT 1');
  }

  MySQLConnection get _conn {
    final c = _conexao;
    if (c == null) {
      throw StateError('Banco não conectado. Chame conectar() antes.');
    }
    return c;
  }

  Future<T> _transacao<T>(Future<T> Function() operacao) async {
    await _executar('START TRANSACTION');
    try {
      final resultado = await operacao();
      await _executar('COMMIT');
      return resultado;
    } catch (_) {
      await _executar('ROLLBACK');
      rethrow;
    }
  }

  Future<int> _inserir(String sql, Map<String, dynamic> params) async {
    final resultado = await _conn.execute(sql, params);
    return resultado.lastInsertID.toInt();
  }

  Future<void> _executar(String sql, [Map<String, dynamic>? params]) async {
    if (params == null) {
      await _conn.execute(sql);
    } else {
      await _conn.execute(sql, params);
    }
  }

  Future<List<Map<String, String?>>> _consultar(
    String sql,
    Map<String, dynamic> params,
  ) async {
    final resultado = await _conn.execute(sql, params);
    return resultado.rows.map((linha) => linha.assoc()).toList();
  }

  Future<List<Map<String, String?>>> consultarTabela(String tabela) {
    final sql = consultasLeitura[tabela];
    if (sql == null) {
      throw ArgumentError('Tabela não permitida para consulta: $tabela');
    }
    return _consultar(sql, {});
  }

  String _dataSql(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${dois(d.month)}-${dois(d.day)} '
        '${dois(d.hour)}:${dois(d.minute)}:${dois(d.second)}';
  }

  Future<Map<String, String?>?> buscarOrganizadorPorEmail(String email) async {
    final linhas = await _consultar(
      'SELECT id_usuario AS id, nome, email, telefone, senha_hash '
      'FROM usuario WHERE email = :email AND ativo = 1 LIMIT 1',
      {'email': email},
    );
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<int> segundosDeBloqueio(String email) async {
    await _executar(
      'DELETE FROM bloqueio_login WHERE email = :email AND bloqueado_ate <= NOW()',
      {'email': email},
    );
    final linhas = await _consultar(
      'SELECT GREATEST(TIMESTAMPDIFF(SECOND, NOW(), bloqueado_ate), 0) AS restante '
      'FROM bloqueio_login WHERE email = :email',
      {'email': email},
    );
    return linhas.isEmpty ? 0 : _int(linhas.first['restante']);
  }

  Future<void> bloquearLogin(String email, int segundos) {
    return _transacao(() async {
      await _executar(
        'DELETE FROM bloqueio_login WHERE email = :email',
        {'email': email},
      );
      await _executar(
        'INSERT INTO bloqueio_login (email, bloqueado_ate) '
        'VALUES (:email, NOW() + INTERVAL $segundos SECOND)',
        {'email': email},
      );
    });
  }

  Future<void> liberarLogin(String email) {
    return _executar(
      'DELETE FROM bloqueio_login WHERE email = :email',
      {'email': email},
    );
  }

  Future<void> registrarTentativa(
    String email, {
    required bool sucesso,
    int? idOrganizador,
  }) {
    return _executar(
      'INSERT INTO login_registro (email_informado, sucesso, data_hora, '
      'usuario_id_usuario) VALUES (:email, :sucesso, NOW(), :org)',
      {
        'email': email,
        'sucesso': sucesso ? 1 : 0,
        'org': idOrganizador,
      },
    );
  }

  Future<int> iniciarSessao(int idOrganizador) {
    return _inserir(
      'INSERT INTO sessao_login (inicio, usuario_id_usuario) '
      'VALUES (NOW(), :org)',
      {'org': idOrganizador},
    );
  }

  Future<void> encerrarSessao(int idSessao) {
    return _executar(
      'UPDATE sessao_login SET fim = NOW() WHERE idsessao = :id AND fim IS NULL',
      {'id': idSessao},
    );
  }

  Future<void> trocarSenha(int idOrganizador, String hash) {
    return _transacao(() async {
      await _executar(
        'UPDATE usuario SET senha_hash = :hash WHERE id_usuario = :id',
        {'hash': hash, 'id': idOrganizador},
      );
      await _executar(
        'INSERT INTO troca_senha (data_hora, usuario_id_usuario) '
        'VALUES (NOW(), :id)',
        {'id': idOrganizador},
      );
      await _executar(
        'DELETE FROM bloqueio_login WHERE email = '
        '(SELECT email FROM usuario WHERE id_usuario = :id)',
        {'id': idOrganizador},
      );
    });
  }

  Future<int> cadastrarOrganizador({
    required String nome,
    required String email,
    String? telefone,
    required String hash,
  }) {
    return _inserir(
      'INSERT INTO usuario (nome, email, telefone, senha_hash) '
      'VALUES (:nome, :email, :telefone, :hash)',
      {
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'hash': hash,
      },
    );
  }

  Future<void> salvarEventoCompleto(Organizador org, Evento evento) {
    return _transacao(() async {
      final idHistorico = await _inserir(
        'INSERT INTO historico_evento '
        '(total_convidados, total_presentes, taxa_comparecimento) '
        'VALUES (0, 0, 0.00)',
        {},
      );
      evento.historicoEvento = HistoricoEvento(idBanco: idHistorico);

      evento.idBanco = await _inserir(
        'INSERT INTO evento (nome, data_evento, local_evento, DESCRICAO, '
        'tipo_evento, organizador_id_organizador, historico_evento_idhistorico_evento) '
        'VALUES (:nome, :data, :local, :descricao, :tipo, :org, :historico)',
        {
          'nome': evento.nomeEvento,
          'data': _dataSql(evento.dataEvento),
          'local': evento.localEvento,
          'descricao': evento.descricao,
          'tipo': evento.tipodeevento,
          'org': org.idBanco,
          'historico': idHistorico,
        },
      );
      evento.nomeOrganizador = org.nome;

      await garantirMesaPadrao(evento);
    });
  }

  Future<void> garantirMesaPadrao(Evento evento) async {
    if (evento.mesaPadrao?.idBanco != null) return;

    final mesa = Mesa(numeroMesa: 'Geral', capacidade: 0);
    mesa.idBanco = await _inserir(
      'INSERT INTO mesa (numero_mesa, capacidade, evento_idevento) '
      'VALUES (:numero, :capacidade, :evento)',
      {
        'numero': mesa.numeroMesa,
        'capacidade': mesa.capacidade,
        'evento': evento.idBanco,
      },
    );
    evento.mesaPadrao = mesa;
  }

  Future<void> salvarConvidado(Convidado convidado) async {
    convidado.idBanco = await _inserir(
      'INSERT INTO convidado (nome, email, telefone, idade, assento) '
      'VALUES (:nome, :email, :telefone, :idade, :assento)',
      {
        'nome': convidado.nome,
        'email': convidado.email,
        'telefone': convidado.telefone,
        'idade': convidado.idade,
        'assento': convidado.assento,
      },
    );
  }

  Future<void> cadastrarConvidadoEConvite(Convidado convidado, Convite convite) {
    return _transacao(() async {
      await salvarConvidado(convidado);
      await salvarConvite(convite);
    });
  }

  Future<void> removerConvidado(Convidado convidado) {
    final id = convidado.idBanco;
    if (id == null) return Future.value();

    return _transacao(() async {
      // Se a pessoa estava em alguma fila, registra a saída antes de apagar.
      await _tirarDaFilaEmMassa('convidado_idconvidado = :id', {'id': id});
      await _executar(
        'DELETE FROM checkin WHERE convite_idconvite IN '
        '(SELECT idconvite FROM convite WHERE convidado_idconvidado = :id)',
        {'id': id},
      );
      await _executar(
        'DELETE FROM convite WHERE convidado_idconvidado = :id',
        {'id': id},
      );
      await _executar(
        'DELETE FROM convidado WHERE idconvidado = :id',
        {'id': id},
      );
    });
  }

  Future<void> salvarConvite(Convite convite) async {
    await garantirMesaPadrao(convite.evento);
    final mesa = convite.evento.mesaPadrao!;

    convite.idBanco = await _inserir(
      'INSERT INTO convite (status_confirmacao, evento_idevento, mesa_idmesa, '
      'mesa_numero_mesa, convidado_idconvidado) '
      'VALUES (:status, :evento, :mesa, :numero, :convidado)',
      {
        'status': convite.status.name,
        'evento': convite.evento.idBanco,
        'mesa': mesa.idBanco,
        'numero': mesa.numeroMesa,
        'convidado': convite.convidado.idBanco,
      },
    );
  }

  Future<void> atualizarStatusConvite(Convite convite, StatusConfirmacao status) {
    return _executar(
      'UPDATE convite SET status_confirmacao = :status WHERE idconvite = :id',
      {'status': status.name, 'id': convite.idBanco},
    );
  }

  Future<void> salvarCheckin(Checkin checkin) async {
    checkin.idBanco = await _inserir(
      'INSERT INTO checkin (data_hora, presente, convite_idconvite) '
      'VALUES (:dataHora, :presente, :convite)',
      {
        'dataHora': _dataSql(checkin.dataHora),
        'presente': checkin.presente ? 1 : 0,
        'convite': checkin.convite.idBanco,
      },
    );
  }

  Future<void> sincronizarHistorico(
    Evento evento,
    List<Convite> convites,
    List<Checkin> checkins,
  ) async {
    final historico = evento.historicoEvento;
    if (historico == null || historico.idBanco == null) return;

    final convitesDoEvento = convites.where((c) => c.evento == evento).toList();
    final confirmados = convitesDoEvento
        .where((c) => c.status == StatusConfirmacao.confirmado)
        .length;
    final presentes = checkins
        .where((chk) => chk.convite.evento == evento && chk.presente)
        .length;
    final taxa = confirmados == 0 ? 0.0 : presentes / confirmados * 100;

    historico.totalConvidados = convitesDoEvento.length;
    historico.totalPresentes = presentes;
    historico.taxaComparecimento = taxa;

    try {
      await _executar(
        'UPDATE historico_evento SET total_convidados = :total, '
        'total_presentes = :presentes, taxa_comparecimento = :taxa '
        'WHERE idhistorico_evento = :id',
        {
          'total': convitesDoEvento.length,
          'presentes': presentes,
          'taxa': taxa.toStringAsFixed(2),
          'id': historico.idBanco,
        },
      );
    } catch (e) {
      print('Aviso: não foi possível atualizar o histórico no banco: $e');
    }
  }

  Future<DadosCarregados> carregarTudo() async {
    final convidados = <Convidado>[];
    final convidadosPorId = <int, Convidado>{};
    final linhasConvidados = await _consultar(
      'SELECT idconvidado AS id, nome, email, telefone, idade, assento '
      'FROM convidado ORDER BY idconvidado',
      {},
    );
    for (final l in linhasConvidados) {
      final c = Convidado.doBanco(
        idBanco: _int(l['id']),
        nome: l['nome'] ?? '',
        email: l['email'] ?? '',
        telefone: l['telefone'],
        idade: _intOpt(l['idade']),
        assento: l['assento'],
      );
      convidados.add(c);
      convidadosPorId[c.idBanco!] = c;
    }

    final eventos = <Evento>[];
    final eventosPorId = <int, Evento>{};
    final linhasEventos = await _consultar(
      'SELECT e.idevento AS id, e.nome AS nome, e.data_evento AS data, '
      'e.local_evento AS local, e.DESCRICAO AS descricao, e.tipo_evento AS tipo, '
      'e.limite_convidados AS limite, '
      'o.nome AS organizador, '
      'h.idhistorico_evento AS idhistorico, h.total_convidados AS total_convidados, '
      'h.total_presentes AS total_presentes, h.taxa_comparecimento AS taxa, '
      'm.idmesa AS idmesa, m.numero_mesa AS numero_mesa, m.capacidade AS capacidade '
      'FROM evento e '
      'JOIN usuario o ON o.id_usuario = e.organizador_id_organizador '
      'JOIN historico_evento h ON h.idhistorico_evento = e.historico_evento_idhistorico_evento '
      "LEFT JOIN mesa m ON m.evento_idevento = e.idevento AND m.numero_mesa = 'Geral' "
      'ORDER BY e.idevento',
      {},
    );
    for (final l in linhasEventos) {
      final id = _int(l['id']);
      if (eventosPorId.containsKey(id)) continue;
      final tipo = l['tipo'] ?? 'Sem tipo';
      final evento = Evento.doBanco(
        idBanco: id,
        nomeEvento: l['nome'] ?? '',
        dataEvento: DateTime.parse(l['data']!),
        descricao: l['descricao'] ?? '',
        localEvento: l['local'],
        tipodeevento: tipo,
        nomeOrganizador: l['organizador'],
        limiteConvidados: _intOpt(l['limite']),
        historicoEvento: HistoricoEvento(
          idBanco: _int(l['idhistorico']),
          totalConvidados: _int(l['total_convidados']),
          totalPresentes: int.parse(l['total_presentes'] ?? '0'),
          taxaComparecimento: double.parse(l['taxa'] ?? '0'),
        ),
        mesaPadrao: l['idmesa'] == null
            ? null
            : Mesa(
                idBanco: _int(l['idmesa']),
                numeroMesa: l['numero_mesa'] ?? 'Geral',
                capacidade: _int(l['capacidade']),
              ),
      );
      eventos.add(evento);
      eventosPorId[id] = evento;
      registrarTipoEvento(tipo);
    }

    final convites = <Convite>[];
    final convitesPorId = <int, Convite>{};
    final linhasConvites = await _consultar(
      'SELECT cv.idconvite AS id, cv.status_confirmacao AS status, '
      'cv.evento_idevento AS evento, cv.convidado_idconvidado AS convidado '
      'FROM convite cv ORDER BY cv.idconvite',
      {},
    );
    for (final l in linhasConvites) {
      final evento = eventosPorId[_int(l['evento'])];
      final convidado = convidadosPorId[_int(l['convidado'])];
      if (evento == null || convidado == null) continue;
      final convite = Convite.doBanco(
        idBanco: _int(l['id']),
        status: statusDeTexto(l['status'] ?? 'pendente'),
        evento: evento,
        convidado: convidado,
      );
      convites.add(convite);
      convitesPorId[convite.idBanco!] = convite;
    }

    final checkins = <Checkin>[];
    final linhasCheckins = await _consultar(
      'SELECT ch.idcheckin AS id, ch.data_hora AS data, ch.presente AS presente, '
      'ch.convite_idconvite AS convite FROM checkin ch ORDER BY ch.idcheckin',
      {},
    );
    for (final l in linhasCheckins) {
      final convite = convitesPorId[_int(l['convite'])];
      if (convite == null) continue;
      checkins.add(Checkin.doBanco(
        idBanco: _int(l['id']),
        dataHora: DateTime.parse(l['data']!),
        presente: l['presente'] == '1',
        convite: convite,
      ));
    }

    return DadosCarregados(
      eventos: eventos,
      convidados: convidados,
      convites: convites,
      checkins: checkins,
    );
  }

  Future<void> atualizarConvidado(Convidado c) {
    return _executar(
      'UPDATE convidado SET nome = :nome, email = :email, telefone = :telefone, '
      'idade = :idade, assento = :assento WHERE idconvidado = :id',
      {
        'nome': c.nome,
        'email': c.email,
        'telefone': c.telefone,
        'idade': c.idade,
        'assento': c.assento,
        'id': c.idBanco,
      },
    );
  }

  Future<void> apagarCheckinsDoEvento(Evento evento) {
    return _executar(
      'DELETE FROM checkin WHERE convite_idconvite IN '
      '(SELECT idconvite FROM convite WHERE evento_idevento = :id)',
      {'id': evento.idBanco},
    );
  }

  Future<void> excluirEvento(Evento evento) {
    final id = evento.idBanco;
    if (id == null) return Future.value();

    return _transacao(() async {
      final linhas = await _consultar(
        'SELECT historico_evento_idhistorico_evento AS h FROM evento '
        'WHERE idevento = :id',
        {'id': id},
      );
      final idHistorico = linhas.isEmpty ? null : _intOpt(linhas.first['h']);

      // A fila do evento sai junto, mas fica registrada no histórico.
      await _tirarDaFilaEmMassa('evento_idevento = :id', {'id': id});

      await _executar(
        'DELETE FROM checkin WHERE convite_idconvite IN '
        '(SELECT idconvite FROM convite WHERE evento_idevento = :id)',
        {'id': id},
      );
      await _executar(
        'DELETE FROM convite WHERE evento_idevento = :id',
        {'id': id},
      );
      await _executar(
        'DELETE FROM calculo_especializado WHERE evento_idevento = :id',
        {'id': id},
      );
      await _executar(
        'DELETE FROM mesa WHERE evento_idevento = :id',
        {'id': id},
      );
      await _executar(
        'DELETE FROM evento WHERE idevento = :id',
        {'id': id},
      );
      if (idHistorico != null) {
        await _executar(
          'DELETE FROM historico_evento WHERE idhistorico_evento = :h '
          'AND NOT EXISTS (SELECT 1 FROM evento '
          'WHERE historico_evento_idhistorico_evento = :h2)',
          {'h': idHistorico, 'h2': idHistorico},
        );
      }
    });
  }

  // ---------------------------------------------------------------
  // LISTA DE ESPERA (a regra fica no código; o banco só guarda)
  // ---------------------------------------------------------------

  /// Muda o limite de vagas do evento. null = sem limite.
  Future<void> definirLimiteConvidados(Evento evento, int? limite) {
    return _executar(
      'UPDATE evento SET limite_convidados = :limite WHERE idevento = :id',
      {'limite': limite, 'id': evento.idBanco},
    );
  }

  /// Lê a fila de um evento, já em ordem. Monta os objetos usando os
  /// convidados que o programa já tem na memória.
  Future<List<ItemListaEspera>> carregarListaEspera(
    Evento evento,
    List<Convidado> convidados,
  ) async {
    final porId = {for (final c in convidados) c.idBanco: c};
    final linhas = await _consultar(
      'SELECT idlista_espera AS id, convidado_idconvidado AS convidado, posicao, criado_em '
      'FROM lista_espera WHERE evento_idevento = :evento '
      'ORDER BY posicao, idlista_espera',
      {'evento': evento.idBanco},
    );
    final fila = <ItemListaEspera>[];
    for (final l in linhas) {
      final convidado = porId[_int(l['convidado'])];
      if (convidado == null) continue;
      fila.add(ItemListaEspera.doBanco(
        idBanco: _int(l['id']),
        evento: evento,
        convidado: convidado,
        posicao: _int(l['posicao']),
        criadoEm: DateTime.parse(l['criado_em']!),
      ));
    }
    return fila;
  }

  /// Grava uma pessoa nova no fim da fila (a posição já vem calculada pelo código).
  Future<void> adicionarListaEspera(ItemListaEspera item) async {
    item.idBanco = await _inserir(
      'INSERT INTO lista_espera (evento_idevento, convidado_idconvidado, posicao, criado_em) '
      'VALUES (:evento, :convidado, :posicao, :criado)',
      {
        'evento': item.evento.idBanco,
        'convidado': item.convidado.idBanco,
        'posicao': item.posicao,
        'criado': _dataSql(item.criadoEm),
      },
    );
  }

  /// Tira a pessoa da fila (sem dar vaga): grava o histórico, apaga e
  /// renumera quem estava atrás. Tudo numa transação.
  Future<void> removerDaListaEspera(ItemListaEspera item, List<ItemListaEspera> restantes) {
    return _transacao(() async {
      await _saidaDaFila(item, MotivoSaidaFila.removido, restantes);
    });
  }

  /// Dá a vaga para a pessoa: cria o convite, grava o histórico, tira da fila
  /// e renumera o resto. Se qualquer passo falhar, nada é gravado (ROLLBACK).
  Future<void> promoverDaListaEspera(
    ItemListaEspera item,
    Convite convite,
    List<ItemListaEspera> restantes,
  ) {
    return _transacao(() async {
      await salvarConvite(convite);
      await _saidaDaFila(item, MotivoSaidaFila.promovido, restantes);
    });
  }

  Future<void> _saidaDaFila(
    ItemListaEspera item,
    MotivoSaidaFila motivo,
    List<ItemListaEspera> restantes,
  ) async {
    await _executar(
      'INSERT INTO historico_lista_espera '
      '(evento_idevento, convidado_idconvidado, posicao, entrou_em, saiu_em, motivo) '
      'VALUES (:evento, :convidado, :posicao, :entrou, NOW(), :motivo)',
      {
        'evento': item.evento.idBanco,
        'convidado': item.convidado.idBanco,
        'posicao': item.posicao,
        'entrou': _dataSql(item.criadoEm),
        'motivo': motivo.name,
      },
    );
    await _executar(
      'DELETE FROM lista_espera WHERE idlista_espera = :id',
      {'id': item.idBanco},
    );
    for (final r in restantes) {
      await _executar(
        'UPDATE lista_espera SET posicao = :posicao WHERE idlista_espera = :id',
        {'posicao': r.posicao, 'id': r.idBanco},
      );
    }
  }

  /// Tira da fila várias pessoas de uma vez (quando um convidado ou um evento é
  /// apagado), registrando todas no histórico como "removido".
  Future<void> _tirarDaFilaEmMassa(String condicao, Map<String, dynamic> params) async {
    await _executar(
      'INSERT INTO historico_lista_espera '
      '(evento_idevento, convidado_idconvidado, posicao, entrou_em, saiu_em, motivo) '
      "SELECT evento_idevento, convidado_idconvidado, posicao, criado_em, NOW(), 'removido' "
      'FROM lista_espera WHERE $condicao',
      params,
    );
    await _executar('DELETE FROM lista_espera WHERE $condicao', params);
  }

  /// Quem já passou pela fila deste evento, do mais recente para o mais antigo.
  Future<List<Map<String, String?>>> historicoListaEspera(Evento evento) {
    return _consultar(
      'SELECT h.saiu_em, h.posicao, h.motivo, c.nome '
      'FROM historico_lista_espera h '
      'LEFT JOIN convidado c ON c.idconvidado = h.convidado_idconvidado '
      'WHERE h.evento_idevento = :evento ORDER BY h.saiu_em DESC, h.idhistorico_lista_espera DESC',
      {'evento': evento.idBanco},
    );
  }

  Future<Map<String, List<Map<String, String?>>>> buscarDetalhesEvento(
    int idEvento,
  ) async {
    return {
      'evento': await _consultar(
        'SELECT * FROM evento WHERE idevento = :id',
        {'id': idEvento},
      ),
      'historico': await _consultar(
        'SELECT h.* FROM historico_evento h '
        'JOIN evento e ON e.historico_evento_idhistorico_evento = h.idhistorico_evento '
        'WHERE e.idevento = :id',
        {'id': idEvento},
      ),
      'mesas': await _consultar(
        'SELECT * FROM mesa WHERE evento_idevento = :id ORDER BY idmesa',
        {'id': idEvento},
      ),
      'convites': await _consultar(
        'SELECT cv.*, c.nome, c.email, c.telefone, c.idade, c.assento '
        'FROM convite cv JOIN convidado c ON c.idconvidado = cv.convidado_idconvidado '
        'WHERE cv.evento_idevento = :id ORDER BY c.nome',
        {'id': idEvento},
      ),
      'checkins': await _consultar(
        'SELECT ch.*, cv.idconvite, c.nome AS convidado '
        'FROM checkin ch '
        'JOIN convite cv ON cv.idconvite = ch.convite_idconvite '
        'JOIN convidado c ON c.idconvidado = cv.convidado_idconvidado '
        'WHERE cv.evento_idevento = :id ORDER BY ch.data_hora',
        {'id': idEvento},
      ),
    };
  }
}