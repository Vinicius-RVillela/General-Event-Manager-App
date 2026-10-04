class HistoricoEvento {
  static int _proximoId = 1;
  late int id;
  int? totalConvidados;
  int? totalPresentes;
  double? totalEstimadoPessoas;
  double? custoEstimadoPorPessoa;
  double? totalConsumidoInsumosEvento;

  HistoricoEvento() {
    id = _proximoId++;
  }
}