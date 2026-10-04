import 'Evento.dart';

class Mesa {
  static int _proximoId = 1;
  late int id;
  String? numeroMesa;
  int? capacidade;
  Evento? evento;

  Mesa() {
    id = _proximoId++;
  }
}