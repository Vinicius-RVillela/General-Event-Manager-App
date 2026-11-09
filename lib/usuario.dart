import 'Registro.dart';
import 'validacao.dart';

abstract class Usuario extends Registro {
  String? _nome;
  String? _email;
  String? _telefone;

  Usuario({super.idBanco, String? nome, String? email, String? telefone})
      : _nome = nome,
        _email = email,
        _telefone = telefone;

  String? get nome => _nome;

  set nome(String? valor) {
    if (valor != null && valor.trim().isEmpty) {
      throw ArgumentError('O nome não pode ficar vazio.');
    }
    _nome = valor?.trim();
  }

  String? get email => _email;

  set email(String? valor) {
    if (valor != null && valor != 'admin' && !emailValido(valor.trim())) {
      throw ArgumentError('Email inválido: $valor');
    }
    _email = valor?.trim();
  }

  String? get telefone => _telefone;

  set telefone(String? valor) => _telefone = valor?.trim();
}

String normalizar(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  String resultado = texto.toLowerCase();
  for (int i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
  }
  return resultado;
}
