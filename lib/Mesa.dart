import 'Registro.dart';

class Mesa extends Registro {
  String _numeroMesa;
  int _capacidade;

  Mesa({super.idBanco, String numeroMesa = 'Geral', int capacidade = 0})
      : _numeroMesa = numeroMesa,
        _capacidade = capacidade;

  String get numeroMesa => _numeroMesa;

  set numeroMesa(String valor) => _numeroMesa = valor.trim();

  int get capacidade => _capacidade;

  set capacidade(int valor) {
    if (valor < 0) {
      throw ArgumentError('A capacidade não pode ser negativa: $valor');
    }
    _capacidade = valor;
  }

  @override
  String obterDados() => 'Mesa: $numeroMesa | Capacidade: $capacidade';
}
