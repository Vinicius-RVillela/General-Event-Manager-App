/// Espelho da tabela mesa. Cada evento tem uma mesa padrão "Geral".
class Mesa {
  int? idBanco;
  String numeroMesa;
  int capacidade;

  Mesa({this.idBanco, this.numeroMesa = 'Geral', this.capacidade = 0});
}
