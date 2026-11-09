import 'Registro.dart';

class HistoricoEvento extends Registro {
  int _totalConvidados;
  int _totalPresentes;
  double _taxaComparecimento;

  HistoricoEvento({
    super.idBanco,
    int totalConvidados = 0,
    int totalPresentes = 0,
    double taxaComparecimento = 0.0,
  })  : _totalConvidados = totalConvidados,
        _totalPresentes = totalPresentes,
        _taxaComparecimento = taxaComparecimento;

  int get totalConvidados => _totalConvidados;

  set totalConvidados(int valor) => _totalConvidados = valor;

  int get totalPresentes => _totalPresentes;

  set totalPresentes(int valor) => _totalPresentes = valor;

  double get taxaComparecimento => _taxaComparecimento;

  set taxaComparecimento(double valor) => _taxaComparecimento = valor;

  @override
  String obterDados() {
    return 'Convidados: $totalConvidados | Presentes: $totalPresentes | '
        'Taxa de comparecimento: $taxaComparecimento';
  }
}
