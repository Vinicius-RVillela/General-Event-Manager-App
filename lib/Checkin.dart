import 'Convite.dart';
import 'Registro.dart';
import 'validacao.dart';

class Checkin extends Registro {
  DateTime _dataHora;
  bool _presente;
  final Convite _convite;

  Checkin({
    super.idBanco,
    DateTime? dataHora,
    bool presente = true,
    required Convite convite,
  })  : _dataHora = dataHora ?? DateTime.now(),
        _presente = presente,
        _convite = convite;

  Checkin.doBanco({
    required int idBanco,
    required DateTime dataHora,
    required bool presente,
    required Convite convite,
  }) : this(idBanco: idBanco, dataHora: dataHora, presente: presente, convite: convite);

  DateTime get dataHora => _dataHora;

  set dataHora(DateTime valor) => _dataHora = valor;

  bool get presente => _presente;

  set presente(bool valor) => _presente = valor;

  Convite get convite => _convite;

  @override
  String obterDados() {
    return 'Check-in #$idBanco | Convidado: ${_convite.convidado.nome} | '
        'Presente: ${_presente ? 'Sim' : 'Não'} | Horário: ${formatarDataHora(_dataHora)}';
  }
}
