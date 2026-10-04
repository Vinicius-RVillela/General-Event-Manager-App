import 'dart:io';
import 'convidado.dart';

/// Executa o menu de gerenciamento de convidados.
void gerenciarConvidados(List<Convidado> convidados) {
  bool continuar = true;

  while (continuar) {
    print('\nSeja Bem-Vindo ao gerenciador de convidados!');
    print('Escolha uma opção abaixo:');
    print('1 - Cadastrar');
    print('2 - Remover');
    print('3 - Listar todos');
    print('4 - Buscar convidado');
    print('5 - Sair');

    String opcao = stdin.readLineSync()!;

    switch (opcao) {
      case '1':
        var novoConvidado = Convidado();
        novoConvidado.cadastrar();
        convidados.add(novoConvidado);
        print('Convidado cadastrado com sucesso!');
        break;

      case '2':
        print('Digite o ID do convidado que será removido: ');
        int? idParaRemover = int.tryParse(stdin.readLineSync()!);

        if (idParaRemover == null) {
          print('ID inválido.');
          break;
        }

        Convidado? encontrado;
        for (var c in convidados) {
          if (c.id == idParaRemover) {
            encontrado = c;
            break;
          }
        }

        if (encontrado == null) {
          print('Convidado não encontrado.');
        } else {
          print('Deseja remover ${encontrado.nome}? (Sim/Não)');
          String resposta = stdin.readLineSync()!;
          if (resposta == 'Sim') {
            convidados.remove(encontrado);
            print('Convidado removido com sucesso.');
          } else {
            print('Remoção cancelada.');
          }
        }
        break;

      case '3':
        if (convidados.isEmpty) {
          print('Nenhum convidado cadastrado.');
        } else {
          for (var c in convidados) {
            print(c.obterDados());
          }
        }
        break;

      case '4':
        print('Digite o ID do convidado que deseja buscar: ');
        int? idBusca = int.tryParse(stdin.readLineSync()!);

        if (idBusca == null) {
          print('ID inválido.');
          break;
        }

        Convidado? convidadoBuscado;
        for (var c in convidados) {
          if (c.id == idBusca) {
            convidadoBuscado = c;
            break;
          }
        }

        if (convidadoBuscado == null) {
          print('Convidado não encontrado.');
        } else {
          print('--- Convidado encontrado ---');
          print(convidadoBuscado.obterDados());
        }
        break;

      case '5':
        print('Saindo do gerenciador...');
        continuar = false;
        break;

      default:
        print('Opção inválida.');
    }
  }
}