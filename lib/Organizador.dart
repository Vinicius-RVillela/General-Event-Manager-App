import 'Evento.dart';
import 'usuario.dart';

class Organizador extends Usuario {
  Evento? _eventoGerenciado;
  int? _idSessao;

  Organizador({super.idBanco, super.nome, super.email, super.telefone});

  Organizador.doBanco({
    required int idBanco,
    required String nome,
    required String email,
    String? telefone,
  }) : super(idBanco: idBanco, nome: nome, email: email, telefone: telefone);

  // IDs no banco: 1000 = Administrador, 1005 = admine.
  static const Set<int> _idsAdministradores = {1000, 1005};

  bool get ehAdministrador =>
      idBanco != null && _idsAdministradores.contains(idBanco);

  Evento? get eventoGerenciado => _eventoGerenciado;

  set eventoGerenciado(Evento? valor) => _eventoGerenciado = valor;

  int? get idSessao => _idSessao;

  set idSessao(int? valor) => _idSessao = valor;

  @override
  String obterDados() {
    return 'ID: $idBanco | Organizador: $nome | Email: ${email ?? '-'}';
  }
}