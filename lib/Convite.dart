import 'Evento.dart';
import 'convidado.dart';

/// Status do convite. Os nomes batem com o ENUM do banco.
enum StatusConfirmacao { pendente, confirmado, recusado }

StatusConfirmacao statusDeTexto(String texto) {
  for (final s in StatusConfirmacao.values) {
    if (s.name == texto) return s;
  }
  return StatusConfirmacao.pendente;
}

/// Espelho da tabela convite.
class Convite {
  int? idBanco;
  StatusConfirmacao status;
  final Evento evento;
  final Convidado convidado;

  Convite({
    this.idBanco,
    this.status = StatusConfirmacao.pendente,
    required this.evento,
    required this.convidado,
  });

  String get statusTexto {
    switch (status) {
      case StatusConfirmacao.pendente:
        return 'Pendente';
      case StatusConfirmacao.confirmado:
        return 'Confirmado';
      case StatusConfirmacao.recusado:
        return 'Recusado';
    }
  }

  String obterDados() {
    return 'Convite #$idBanco | Convidado: ${convidado.nome} | '
        'Evento: ${evento.nomeEvento} | Status: $statusTexto';
  }
}
