import 'Evento.dart';
import 'usuario.dart';

/// Organizador logado. Existe na memória só depois de confirmado no banco.
class Organizador extends Usuario {
  Evento? eventoGerenciado;
  int? idSessao;

  Organizador({super.idBanco, super.nome, super.email, super.telefone});
}
