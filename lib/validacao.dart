import 'dart:io';

/// Lê uma linha do terminal. Se a entrada for fechada (Ctrl+D / fim do stdin),
/// encerra o programa em vez de ficar repetindo perguntas para sempre.
String lerLinha() {
  final linha = stdin.readLineSync();
  if (linha == null) {
    print('\nEntrada encerrada. Saindo do programa.');
    exit(0);
  }
  return linha;
}

/// Verifica se um nome é válido: não vazio e dentro de um tamanho razoável.
bool nomeValido(String nome) {
  final texto = nome.trim();
  return texto.isNotEmpty && texto.length <= 100;
}

/// Verifica se um CPF é válido, incluindo os dígitos verificadores.
bool cpfValido(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  if (digitos.length != 11) return false;
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

/// Verifica se o email tem um formato básico (ex: nome@dominio.com).
bool emailValido(String email) {
  return RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email.trim());
}

/// Verifica se dia/mês/ano formam uma data que realmente existe.
bool dataValida(int dia, int mes, int ano) {
  if (ano < 1900 || ano > 2200 || mes < 1 || mes > 12 || dia < 1) return false;
  final data = DateTime(ano, mes, dia);
  return data.year == ano && data.month == mes && data.day == dia;
}

/// Converte um texto "dd/mm/aaaa" em DateTime. Devolve null se for inválido.
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

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// Mostra uma data no formato brasileiro dd/mm/aaaa.
String formatarData(DateTime? data) {
  if (data == null) return 'não informada';
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';
}

/// Mostra data e hora no formato dd/mm/aaaa HH:MM.
String formatarDataHora(DateTime data) =>
    '${formatarData(data)} ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

/// Pergunta o nome repetidamente até receber um valor válido.
String lerNomeValido(String mensagem) {
  while (true) {
    print(mensagem);
    final entrada = lerLinha();
    if (nomeValido(entrada)) return entrada.trim();
    print('Nome inválido — não pode ser vazio. Tente novamente.');
  }
}

/// Pergunta o CPF repetidamente até receber um valor válido.
String lerCpfValido(String mensagem) {
  while (true) {
    print(mensagem);
    final entrada = lerLinha();
    if (cpfValido(entrada)) return entrada.trim();
    print('CPF inválido. Digite os 11 números do CPF. Tente novamente.');
  }
}

/// Pergunta o email repetidamente até receber um valor válido.
String lerEmailValido(String mensagem) {
  while (true) {
    print(mensagem);
    final entrada = lerLinha();
    if (emailValido(entrada)) return entrada.trim();
    print('Email inválido. Tente novamente.');
  }
}

/// Pergunta a data repetidamente até receber uma data real no formato dd/mm/aaaa.
DateTime lerDataValida(String mensagem) {
  while (true) {
    print(mensagem);
    final data = converterData(lerLinha());
    if (data != null) return data;
    print('Data inválida. Use o formato dd/mm/aaaa com uma data que exista.');
  }
}

/// Pergunta um texto repetidamente até receber algo que não seja vazio.
String lerTextoNaoVazio(String mensagem) {
  while (true) {
    print(mensagem);
    final entrada = lerLinha().trim();
    if (entrada.isNotEmpty) return entrada;
    print('Este campo não pode ficar vazio. Tente novamente.');
  }
}

/// Pergunta um texto opcional: Enter em branco devolve null.
String? lerTextoOpcional(String mensagem) {
  print(mensagem);
  final entrada = lerLinha().trim();
  return entrada.isEmpty ? null : entrada;
}
