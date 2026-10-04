import 'convidado.dart';
import 'Evento.dart';
import 'Mesa.dart';

enum StatusConfirmacao { pendente, confirmado, recusado }

class Convite {
  static int _proximoId = 1;
  late int id;
  StatusConfirmacao status;
  Evento? evento;
  Mesa? mesa;
  Convidado? convidado;

  Convite({
    this.status = StatusConfirmacao.pendente,
    this.evento,
    this.mesa,
    this.convidado,
  }) {
    id = _proximoId++;
  }

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
    return 'Convite #$id | Convidado: ${convidado?.nome} | Evento: ${evento?.nomeEvento} | Status: $statusTexto';
  }
}