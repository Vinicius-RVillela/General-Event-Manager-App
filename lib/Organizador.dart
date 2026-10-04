import 'usuario.dart';

class Organizador extends Usuario {
  Organizador({
    super.nome,
    super.cpf,
    super.email,
    super.telefone,
    super.idade,
    super.endereco,
  });

  @override
  String toString() => 'Organizador #$id - $nome ($email)';
}