import 'endereco.dart';
import 'Evento.dart';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';

class Usuario {
  static int _proximoId = 1;
  static final Random _sorteio = Random();
  static final Set<String> _codigosJaUsados = {};

  late final int id;
  late final String _codigoUnico;

  String? nome;
  String? cpf;
  String? email;
  String? telefone;
  int? idade;
  Endereco? endereco;
  Evento? eventoGerenciado;

  // A senha NUNCA é guardada em texto puro — só o hash (bcrypt) fica em memória.
  late String _senhaHash;

  Usuario({
    this.nome,
    this.cpf,
    this.email,
    this.telefone,
    this.idade,
    this.endereco,
    this.eventoGerenciado,
    String? senhaInicial,
  }) {
    id = _proximoId++;
    _codigoUnico = _gerarCodigoUnico();
    _senhaHash = BCrypt.hashpw(
      senhaInicial ?? _gerarSenhaTemporaria(),
      BCrypt.gensalt(),
    );
  }

  String get codigoUnico => _codigoUnico;

  static String _gerarCodigoUnico() {
    String codigo;
    do {
      codigo = (100000 + _sorteio.nextInt(900000)).toString(); // 6 dígitos: 100000 a 999999
    } while (_codigosJaUsados.contains(codigo));
    _codigosJaUsados.add(codigo);
    return codigo;
  }

  static String _gerarSenhaTemporaria() {
    final aleatorio = 100000 + (DateTime.now().microsecondsSinceEpoch % 900000);
    return aleatorio.toString();
  }

  /// Define ou troca a senha do usuário.
  /// Internamente, só o hash bcrypt é armazenado — a senha em si nunca fica salva.
  void definirSenhaInicial(String novaSenha) {
    _senhaHash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());
  }

  /// Verifica se a senha digitada confere com o hash armazenado.
  /// Importante: a senha NÃO passa por normalizar() — numa senha, acentos e
  /// maiúsculas/minúsculas importam, diferente de um nome usado em busca.
  bool senhaConfere(String tentativa) {
    return BCrypt.checkpw(tentativa, _senhaHash);
  }

  bool redefinirSenha(String nomeConfirma, String cpfConfirma, String novaSenha) {
    if (nomeConfirma == nome && cpfConfirma == cpf) {
      _senhaHash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());
      return true;
    }
    return false;
  }
}

/// Usado apenas para comparar NOMES (ex: busca de convidado) — nunca para senhas.
String normalizar(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  String resultado = texto.toLowerCase();
  for (int i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
  }
  return resultado;
}
