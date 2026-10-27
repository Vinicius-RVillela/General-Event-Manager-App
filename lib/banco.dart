import 'package:mysql_client/mysql_client.dart';

import 'Checkin.dart';
import 'Convite.dart';
import 'HistoricoEvento.dart';
import 'Mesa.dart';
import 'Organizador.dart';
import 'Evento.dart';
import 'convidado.dart';

/// Dados de conexão com o MySQL. AJUSTE PARA O SEU AMBIENTE.
class ConfigBanco {
  static const String host = 'localhost';
  static const int port = 3306;
  static const String usuario = 'root';
  static const String senha = 'suasenha';
  static const String nomeBanco = 'mydb';
}

/// Consultas de leitura liberadas no menu "Consultar banco".
/// Só estas tabelas podem ser lidas. Senhas nunca são mostradas.
const Map<String, String> consultasLeitura = {
  'organizador':
      'SELECT id_organizador AS id, nome, email, telefone, ativo FROM organizador ORDER BY id_organizador',
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
      'organizador_id_organizador AS organizador FROM login_registro '
      'ORDER BY idlogin_registro DESC LIMIT 200',
  'sessao_login':
      'SELECT idsessao AS id, inicio, fim, organizador_id_organizador AS organizador '
      'FROM sessao_login ORDER BY idsessao DESC LIMIT 200',
};

/// Instância única usada pelo programa inteiro.
final BancoDeDados banco = BancoDeDados();

/// Tudo que existe no banco, já em objetos.
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

/// Todas as conversas com o MySQL ficam aqui.
/// Ações que gravam em mais de uma tabela usam transação: ou tudo é gravado,
/// ou nada é — assim não sobra registro pela metade.
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
  }

  Future<void> desconectar() async {
    await _conexao?.close();
    _conexao = null;
  }

  MySQLConnection get _conn {
    final c = _conexao;
    if (c == null) {
      throw StateError('Banco não conectado. Chame conectar() antes.');
    }
    return c;
  }

  // ---------------------------------------------------------------
  // Auxiliares
  // ---------------------------------------------------------------

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

  /// INSERT que devolve o id gerado pelo AUTO_INCREMENT.
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

  /// SELECT que devolve as linhas como mapas (coluna -> texto).
  Future<List<Map<String, String?>>> _consultar(
    String sql,
    Map<String, dynamic> params,
  ) async {
    final resultado = await _conn.execute(sql, params);
    return resultado.rows.map((linha) => linha.assoc()).toList();
  }

  /// Lê uma tabela da lista permitida. Nada digitado pelo usuário entra no SQL.
  Future<List<Map<String, String?>>> consultarTabela(String tabela) {
    final sql = consultasLeitura[tabela];
    if (sql == null) {
      throw ArgumentError('Tabela não permitida para consulta: $tabela');
    }
    return _consultar(sql, {});
  }

  /// Converte DateTime para o formato DATETIME do MySQL.
  String _dataSql(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${dois(d.month)}-${dois(d.day)} '
        '${dois(d.hour)}:${dois(d.minute)}:${dois(d.second)}';
  }

  // ---------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------

  /// Busca o organizador ativo pelo email. Null se não existir.
  Future<Map<String, String?>?> buscarOrganizadorPorEmail(String email) async {
    final linhas = await _consultar(
      'SELECT id_organizador AS id, nome, email, telefone, senha_hash '
      'FROM organizador WHERE email = :email AND ativo = 1 LIMIT 1',
      {'email': email},
    );
    return linhas.isEmpty ? null : linhas.first;
  }

  /// Quantos segundos faltam para o email poder tentar de novo (0 = liberado).
  /// Apaga o bloqueio já vencido, para não acumular registros inúteis.
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

  /// Bloqueia o email por [segundos], contados pelo relógio do próprio banco.
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

  /// Remove o bloqueio após um login bem-sucedido.
  Future<void> liberarLogin(String email) {
    return _executar(
      'DELETE FROM bloqueio_login WHERE email = :email',
      {'email': email},
    );
  }

  /// Registra toda tentativa de login (sucesso ou falha) no histórico.
  Future<void> registrarTentativa(
    String email, {
    required bool sucesso,
    int? idOrganizador,
  }) {
    return _executar(
      'INSERT INTO login_registro (email_informado, sucesso, data_hora, '
      'organizador_id_organizador) VALUES (:email, :sucesso, NOW(), :org)',
      {
        'email': email,
        'sucesso': sucesso ? 1 : 0,
        'org': idOrganizador,
      },
    );
  }

  Future<int> iniciarSessao(int idOrganizador) {
    return _inserir(
      'INSERT INTO sessao_login (inicio, organizador_id_organizador) '
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

  /// Substitui a senha do MESMO organizador (não cria usuário novo).
  Future<void> trocarSenha(int idOrganizador, String hash) {
    return _transacao(() async {
      await _executar(
        'UPDATE organizador SET senha_hash = :hash WHERE id_organizador = :id',
        {'hash': hash, 'id': idOrganizador},
      );
      await _executar(
        'INSERT INTO troca_senha (data_hora, organizador_id_organizador) '
        'VALUES (NOW(), :id)',
        {'id': idOrganizador},
      );
      await _executar(
        'DELETE FROM bloqueio_login WHERE email = '
        '(SELECT email FROM organizador WHERE id_organizador = :id)',
        {'id': idOrganizador},
      );
    });
  }

  /// Usado só pelo utilitário de cadastro (bin/cadastrar_usuario.dart).
  Future<int> cadastrarOrganizador({
    required String nome,
    required String email,
    String? telefone,
    required String hash,
  }) {
    return _inserir(
      'INSERT INTO organizador (nome, email, telefone, senha_hash) '
      'VALUES (:nome, :email, :telefone, :hash)',
      {
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'hash': hash,
      },
    );
  }

  // ---------------------------------------------------------------
  // EVENTO
  // ---------------------------------------------------------------

  /// Grava historico_evento, evento e a mesa padrão, tudo em uma transação.
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

  /// Cria a mesa "Geral" do evento, se ainda não existir.
  /// A tabela convite exige uma mesa, então todo evento precisa dela.
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

  // ---------------------------------------------------------------
  // CONVIDADO
  // ---------------------------------------------------------------

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

  /// Cadastra a pessoa e já a convida, em uma única transação.
  Future<void> cadastrarConvidadoEConvite(Convidado convidado, Convite convite) {
    return _transacao(() async {
      await salvarConvidado(convidado);
      await salvarConvite(convite);
    });
  }

  /// Remove o convidado com seus check-ins e convites, nessa ordem.
  Future<void> removerConvidado(Convidado convidado) {
    final id = convidado.idBanco;
    if (id == null) return Future.value();

    return _transacao(() async {
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

  // ---------------------------------------------------------------
  // CONVITE
  // ---------------------------------------------------------------

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

  // ---------------------------------------------------------------
  // CHECK-IN
  // ---------------------------------------------------------------

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

  // ---------------------------------------------------------------
  // HISTÓRICO
  // ---------------------------------------------------------------

  /// Recalcula os números do evento e grava em historico_evento.
  /// Taxa = % dos CONFIRMADOS que fizeram check-in (mesma conta da tela de estatísticas).
  /// Se falhar, só avisa: o histórico não deve derrubar a operação principal.
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

  // ---------------------------------------------------------------
  // CARREGAR TUDO AO ABRIR O PROGRAMA
  // ---------------------------------------------------------------

  /// Lê do banco TUDO que existe, de todos os organizadores.
  /// Assim qualquer organizador vê os mesmos eventos, convidados, convites e check-ins.
  Future<DadosCarregados> carregarTudo() async {
    // Convidados
    final convidados = <Convidado>[];
    final convidadosPorId = <int, Convidado>{};
    final linhasConvidados = await _consultar(
      'SELECT idconvidado AS id, nome, email, telefone, idade, assento '
      'FROM convidado ORDER BY idconvidado',
      {},
    );
    for (final l in linhasConvidados) {
      final c = Convidado(
        idBanco: _int(l['id']),
        nome: l['nome'],
        email: l['email'],
        telefone: l['telefone'],
        idade: _intOpt(l['idade']),
        assento: l['assento'],
      );
      convidados.add(c);
      convidadosPorId[c.idBanco!] = c;
    }

    // Eventos de todos os organizadores, com nome do organizador, histórico e mesa padrão.
    final eventos = <Evento>[];
    final eventosPorId = <int, Evento>{};
    final linhasEventos = await _consultar(
      'SELECT e.idevento AS id, e.nome AS nome, e.data_evento AS data, '
      'e.local_evento AS local, e.DESCRICAO AS descricao, e.tipo_evento AS tipo, '
      'o.nome AS organizador, '
      'h.idhistorico_evento AS idhistorico, h.total_convidados AS total_convidados, '
      'h.total_presentes AS total_presentes, h.taxa_comparecimento AS taxa, '
      'm.idmesa AS idmesa, m.numero_mesa AS numero_mesa, m.capacidade AS capacidade '
      'FROM evento e '
      'JOIN organizador o ON o.id_organizador = e.organizador_id_organizador '
      'JOIN historico_evento h ON h.idhistorico_evento = e.historico_evento_idhistorico_evento '
      "LEFT JOIN mesa m ON m.evento_idevento = e.idevento AND m.numero_mesa = 'Geral' "
      'ORDER BY e.idevento',
      {},
    );
    for (final l in linhasEventos) {
      final id = _int(l['id']);
      if (eventosPorId.containsKey(id)) continue; // mesa duplicada não repete evento
      final tipo = l['tipo'] ?? 'Sem tipo';
      final evento = Evento(
        idBanco: id,
        nomeEvento: l['nome'] ?? '',
        dataEvento: DateTime.parse(l['data']!),
        descricao: l['descricao'] ?? '',
        localEvento: l['local'],
        tipodeevento: tipo,
        nomeOrganizador: l['organizador'],
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

    // Convites de todos os eventos.
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
      final convite = Convite(
        idBanco: _int(l['id']),
        status: statusDeTexto(l['status'] ?? 'pendente'),
        evento: evento,
        convidado: convidado,
      );
      convites.add(convite);
      convitesPorId[convite.idBanco!] = convite;
    }

    // Check-ins de todos os convites.
    final checkins = <Checkin>[];
    final linhasCheckins = await _consultar(
      'SELECT ch.idcheckin AS id, ch.data_hora AS data, ch.presente AS presente, '
      'ch.convite_idconvite AS convite FROM checkin ch ORDER BY ch.idcheckin',
      {},
    );
    for (final l in linhasCheckins) {
      final convite = convitesPorId[_int(l['convite'])];
      if (convite == null) continue;
      checkins.add(Checkin(
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

  // ---------------------------------------------------------------
  // EDIÇÃO DE CONVIDADO (mantém convites e check-ins)
  // ---------------------------------------------------------------

  /// Atualiza os dados de um convidado existente.
  /// Convites e check-ins continuam ligados ao mesmo registro.
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

  // ---------------------------------------------------------------
  // REFAZER CHECK-IN
  // ---------------------------------------------------------------

  /// Apaga os check-ins de um evento. Convites continuam confirmados,
  /// então o check-in pode ser feito de novo.
  Future<void> apagarCheckinsDoEvento(Evento evento) {
    return _executar(
      'DELETE FROM checkin WHERE convite_idconvite IN '
      '(SELECT idconvite FROM convite WHERE evento_idevento = :id)',
      {'id': evento.idBanco},
    );
  }

  // ---------------------------------------------------------------
  // EXIBIR EVENTO COMPLETO (todas as colunas, tabela por tabela)
  // ---------------------------------------------------------------

  /// Lê todas as colunas das tabelas ligadas a um evento.
  /// Chaves: evento, historico, mesas, convites, checkins.
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
