import 'dart:io';

/// Verifica se um nome é válido: não vazio e dentro de um tamanho razoável.
bool nomeValido(String nome) {
  final texto = nome.trim();
  return texto.isNotEmpty && texto.length <= 100;
}

/// Verifica se um CPF é válido, incluindo os dígitos verificadores
/// (algoritmo oficial), não só a quantidade de números.
bool cpfValido(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  if (digitos.length != 11) return false;

  // Rejeita sequências repetidas (ex: 111.111.111-11) — têm 11 dígitos
  // e passariam na conta dos verificadores, mas não são CPFs reais.
  if (RegExp(r'^(\d)\1*$').hasMatch(digitos)) return false;

  List<int> nums = digitos.split('').map(int.parse).toList();

  int calcularDigito(List<int> base, int pesoInicial) {
    int soma = 0;
    for (int i = 0; i < base.length; i++) {
      soma += base[i] * (pesoInicial - i);
    }
    int resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  int primeiroDigito = calcularDigito(nums.sublist(0, 9), 10);
  int segundoDigito = calcularDigito(nums.sublist(0, 10), 11);

  return primeiroDigito == nums[9] && segundoDigito == nums[10];
}

/// Pergunta o nome repetidamente até receber um valor válido.
String lerNomeValido(String mensagem) {
  while (true) {
    print(mensagem);
    String? entrada = stdin.readLineSync();
    if (entrada != null && nomeValido(entrada)) {
      return entrada.trim();
    }
    print('Nome inválido — não pode ser vazio. Tente novamente.');
  }
}

/// Pergunta o CPF repetidamente até receber um valor válido.
String lerCpfValido(String mensagem) {
  while (true) {
    print(mensagem);
    String? entrada = stdin.readLineSync();
    if (entrada != null && cpfValido(entrada)) {
      return entrada.trim();
    }
    print('CPF inválido. Digite os 11 números do CPF (com ou sem pontuação). Tente novamente.');
  }
}
