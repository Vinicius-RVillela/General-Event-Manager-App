import 'dart:io';
import 'usuario.dart';

class Convidado extends Usuario {
  String? assento;

  void cadastrar() {
    print('Digite o nome do convidado: ');
    nome = stdin.readLineSync();

    print('Digite o email do convidado: ');
    email = stdin.readLineSync();

    print('Digite o telefone do convidado: ');
    telefone = stdin.readLineSync();

    print('Digite a idade do convidado: ');
    idade = int.tryParse(stdin.readLineSync() ?? '');

    print('Digite o número do assento do convidado - definido por letra e número: ');
    assento = stdin.readLineSync();
  }

  String obterDados() {
    return 'ID: $id | Nome: $nome | Email: $email | Telefone: $telefone | Idade: $idade | Assento: $assento';
  }
}