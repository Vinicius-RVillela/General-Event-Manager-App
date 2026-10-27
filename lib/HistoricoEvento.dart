/// Espelho da tabela historico_evento.
class HistoricoEvento {
  int? idBanco;
  int totalConvidados;
  int totalPresentes;
  double taxaComparecimento;

  HistoricoEvento({
    this.idBanco,
    this.totalConvidados = 0,
    this.totalPresentes = 0,
    this.taxaComparecimento = 0.0,
  });
}
