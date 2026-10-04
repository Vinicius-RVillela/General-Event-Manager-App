import 'dart:io';
import 'usuario.dart';
import 'Evento.dart';

Future<Usuario?> executarLogin() async {
  print('Digite seu nome: ');
  String nome = stdin.readLineSync()!;
  print('Digite seu cpf: ');
  String cpf = stdin.readLineSync()!;

  String? tipoEvento = escolherTipoEvento();
  if (tipoEvento == null) {
    print('Login cancelado.');
    return null;
  }

  var evento = Evento(tipodeevento: tipoEvento);
  evento.cadastrarEvento();

  var usuario = Usuario(nome: nome, cpf: cpf, eventoGerenciado: evento);

  print('Cadastre sua senha de acesso: ');
  String senhaCriada = stdin.readLineSync()!;
  usuario.definirSenhaInicial(senhaCriada);

  print('Seu código de acesso é: ${usuario.codigoUnico}');
  print('Guarde esse código, ele será solicitado no login.');

  const int tentativasMaximas = 3;
  bool acessoLiberado = false;

  for (int tentativa = 1; tentativa <= tentativasMaximas; tentativa++) {
    print('Digite seu código de acesso (tentativa $tentativa de $tentativasMaximas): ');
    String codigoDigitado = stdin.readLineSync()!;
    print('Digite sua senha (tentativa $tentativa de $tentativasMaximas): ');
    String senhaDigitada = stdin.readLineSync()!;

    if (codigoDigitado == usuario.codigoUnico && usuario.senhaConfere(senhaDigitada)) {
      acessoLiberado = true;
      break;
    } else {
      print('Código ou senha incorretos.');
      // Atraso progressivo: dificulta tentativas automatizadas (força bruta).
      await Future.delayed(Duration(seconds: tentativa * 2));
    }
  }

  if (!acessoLiberado) {
    print('Deseja redefinir a senha ou tentar uma última vez?');
    print('1 - Redefinir senha  \n 2 - Tentar mais uma vez');
    String opcao = stdin.readLineSync()!;

    switch (opcao) {
      case '1':
        print('Para confirmar sua identidade, digite seu nome: ');
        String nomeConfirma = stdin.readLineSync()!;
        print('Digite seu cpf: ');
        String cpfConfirma = stdin.readLineSync()!;
        print('Digite a nova senha: ');
        String novaSenha = stdin.readLineSync()!;

        bool identidadeConfirmada =
            usuario.redefinirSenha(nomeConfirma, cpfConfirma, novaSenha);

        if (identidadeConfirmada) {
          print('Senha redefinida com sucesso! Faça login novamente.');
          print('Digite seu nome novamente: ');
          String nomeFinal = stdin.readLineSync()!;
          print('Digite seu código de acesso: ');
          String codigoFinal = stdin.readLineSync()!;
          print('Digite sua senha: ');
          String senhaFinal = stdin.readLineSync()!;
          if (nomeFinal == usuario.nome &&
              codigoFinal == usuario.codigoUnico &&
              usuario.senhaConfere(senhaFinal)) {
            acessoLiberado = true;
          } else {
            print('Nome, código ou senha incorretos.');
          }
        } else {
          print('Nome ou CPF não conferem. Redefinição negada.');
        }
        break;

      case '2':
        print('Última tentativa - digite seu código de acesso: ');
        String ultimoCodigo = stdin.readLineSync()!;
        print('Última tentativa - digite sua senha: ');
        String ultimaSenha = stdin.readLineSync()!;
        if (ultimoCodigo == usuario.codigoUnico && usuario.senhaConfere(ultimaSenha)) {
          acessoLiberado = true;
        } else {
          print('Código ou senha incorretos.');
        }
        break;

      default:
        print('Opção inválida.');
    }
  }

  if (acessoLiberado) {
    print('Acesso permitido! Seja bem-vindo, ${usuario.nome}.');
    print('Você está gerenciando: ${usuario.eventoGerenciado?.obterDadosEvento()}');
    return usuario;
  } else {
    print('Número máximo de tentativas excedido. Acesso bloqueado.');
    return null;
  }
}
