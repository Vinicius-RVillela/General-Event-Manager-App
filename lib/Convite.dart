import 'Evento.dart';
import 'Registro.dart';
import 'convidado.dart';

enum StatusConfirmacao { pendente, confirmado, recusado }

StatusConfirmacao statusDeTexto(String texto) {
  for (final s in StatusConfirmacao.values) {
    if (s.name == texto) return s;
  }
  return StatusConfirmacao.pendente;
}

class Convite extends Registro {
  StatusConfirmacao _status;
  final Evento _evento;
  final Convidado _convidado;

  Convite({
    super.idBanco,
    StatusConfirmacao status = StatusConfirmacao.pendente,
    required Evento evento,
    required Convidado convidado,
  })  : _status = status,
        _evento = evento,
        _convidado = convidado;

  Convite.doBanco({
    required int idBanco,
    required StatusConfirmacao status,
    required Evento evento,
    required Convidado convidado,
  }) : this(idBanco: idBanco, status: status, evento: evento, convidado: convidado);

  StatusConfirmacao get status => _status;

  set status(StatusConfirmacao valor) => _status = valor;

  Evento get evento => _evento;

  Convidado get convidado => _convidado;

  String get statusTexto {
    switch (_status) {
      case StatusConfirmacao.pendente:
        return 'Pendente';
      case StatusConfirmacao.confirmado:
        return 'Confirmado';
      case StatusConfirmacao.recusado:
        return 'Recusado';
    }
  }

  @override
  String obterDados() {
    return 'Convite #$idBanco | Convidado: ${_convidado.nome} | '
        'Evento: ${_evento.nomeEvento} | Status: $statusTexto';
  }
}
