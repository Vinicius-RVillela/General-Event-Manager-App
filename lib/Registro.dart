abstract class Registro {
  int? _idBanco;

  Registro({int? idBanco}) : _idBanco = idBanco;

  int? get idBanco => _idBanco;

  set idBanco(int? valor) => _idBanco = valor;

  String obterDados();

  @override
  String toString() => obterDados();
}
