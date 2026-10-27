import 'Convite.dart';
import 'validacao.dart';

/// Espelho da tabela checkin.
class Checkin {
  int? idBanco;
  DateTime dataHora;
  bool presente;
  final Convite convite;

  Checkin({
    this.idBanco,
    DateTime? dataHora,
    this.presente = true,
    required this.convite,
  }) : dataHora = dataHora ?? DateTime.now();

  String obterDados() {
    return 'Check-in #$idBanco | Convidado: ${convite.convidado.nome} | '
        'Presente: ${presente ? 'Sim' : 'Não'} | Horário: ${formatarDataHora(dataHora)}';
  }
}
