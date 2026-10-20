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

/// Verifica se dia/mês/ano formam uma data que realmente existe.
/// O DateTime do Dart "corrige" datas impossíveis sem avisar
/// (ex: 31/02/2026 vira 03/03/2026), então conferimos se nada mudou.
bool dataValida(int dia, int mes, int ano) {
  if (ano < 1900 || ano > 2200 || mes < 1 || mes > 12 || dia < 1) return false;
  final data = DateTime(ano, mes, dia);
  return data.year == ano && data.month == mes && data.day == dia;
}

/// Converte um texto "dd/mm/aaaa" em DateTime.
/// Devolve null se o texto não estiver no formato ou a data não existir.
DateTime? converterData(String texto) {
  final partes = texto.trim().split('/');
  if (partes.length != 3) return null;

  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null) return null;

  if (!dataValida(dia, mes, ano)) return null;
  return DateTime(ano, mes, dia);
}

/// Mostra uma data no formato brasileiro dd/mm/aaaa.
String formatarData(DateTime? data) {
  if (data == null) return 'não informada';
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
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
    print(
      'CPF inválido. Digite os 11 números do CPF (com ou sem pontuação). Tente novamente.',
    );
  }
}

/// Pergunta a data repetidamente até receber uma data real no formato dd/mm/aaaa.
DateTime lerDataValida(String mensagem) {
  while (true) {
    print(mensagem);
    String? entrada = stdin.readLineSync();
    if (entrada != null) {
      final data = converterData(entrada);
      if (data != null) return data;
    }
    print(
      'Data inválida. Use o formato dd/mm/aaaa com uma data que exista. Tente novamente.',
    );
  }
}

/// Pergunta um texto repetidamente até receber algo que não seja vazio.
/// Usado para nome de tipo de evento, descrição, etc.
String lerTextoNaoVazio(String mensagem) {
  while (true) {
    print(mensagem);
    String? entrada = stdin.readLineSync();
    if (entrada != null && entrada.trim().isNotEmpty) {
      return entrada.trim();
    }
    print('Este campo não pode ficar vazio. Tente novamente.');
  }
}
