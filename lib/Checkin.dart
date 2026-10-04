import 'Convite.dart';

class Checkin {
  static int _proximoId = 1;
  late int id;
  DateTime? dataHora;
  bool? presente;
  Convite? convite;

  Checkin({this.dataHora, this.presente, this.convite}) {
    id = _proximoId++;
  }

  String obterDados() {
    String status = presente == true ? 'Sim' : 'Não';
    return 'Check-in #$id | Convidado: ${convite?.convidado?.nome} | Presente: $status | Horário: $dataHora';
  }
}