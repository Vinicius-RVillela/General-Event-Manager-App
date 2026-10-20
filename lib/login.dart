import 'dart:io';

import 'usuario.dart';
import 'Evento.dart';
import 'validacao.dart';

/// Lê uma linha do terminal sem exibir o que está sendo digitado.
/// Usado sempre que o usuário digita uma senha, para que ela não
/// fique visível na tela para quem estiver por perto.
///
/// Nem todo terminal suporta desligar o "eco" (echoMode) — em alguns
/// terminais integrados de IDE isso pode lançar um erro. Por isso,
/// se o terminal não suportar, caímos de volta para a leitura normal
/// em vez de travar o programa.
String lerSenhaOculta() {
  try {
    stdin.echoMode = false; // desliga o "eco" do que é digitado
    String senha = stdin.readLineSync() ?? '';
    stdin.echoMode =
        true; // liga de volta, para o resto do programa funcionar normal
    print(''); // pula linha, já que o Enter também não aparece na tela
    return senha;
  } catch (_) {
    // Terminal não suporta ocultar a digitação — lê normalmente.
    return stdin.readLineSync() ?? '';
  }
}

Future<Usuario?> executarLogin() async {
  String nome = lerNomeValido('Digite seu nome: ');
  String cpf = lerCpfValido('Digite seu cpf: ');

  String? tipoEvento = escolherTipoEvento();
  if (tipoEvento == null) {
    print('Login cancelado.');
    return null;
  }

  var evento = Evento(tipodeevento: tipoEvento);
  evento.cadastrarEvento();

  var usuario = Usuario(nome: nome, cpf: cpf, eventoGerenciado: evento);

  print('Cadastre sua senha de acesso: ');
  String senhaCriada = lerSenhaOculta();
  usuario.definirSenhaInicial(senhaCriada);

  print('Seu código de acesso é: ${usuario.codigoUnico}');
  print('Guarde esse código, ele será solicitado no login.');

  const int tentativasMaximas = 3;
  bool acessoLiberado = false;

  for (int tentativa = 1; tentativa <= tentativasMaximas; tentativa++) {
    print(
      'Digite seu código de acesso (tentativa $tentativa de $tentativasMaximas): ',
    );
    String codigoDigitado = stdin.readLineSync()!;
    print('Digite sua senha (tentativa $tentativa de $tentativasMaximas): ');
    String senhaDigitada = lerSenhaOculta();

    if (codigoDigitado == usuario.codigoUnico &&
        usuario.senhaConfere(senhaDigitada)) {
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
        String nomeConfirma = lerNomeValido(
          'Para confirmar sua identidade, digite seu nome: ',
        );
        String cpfConfirma = lerCpfValido('Digite seu cpf: ');
        print('Digite a nova senha: ');
        String novaSenha = lerSenhaOculta();

        bool identidadeConfirmada = usuario.redefinirSenha(
          nomeConfirma,
          cpfConfirma,
          novaSenha,
        );

        if (identidadeConfirmada) {
          print('Senha redefinida com sucesso! Faça login novamente.');
          String nomeFinal = lerNomeValido('Digite seu nome novamente: ');
          print('Digite seu código de acesso: ');
          String codigoFinal = stdin.readLineSync()!;
          print('Digite sua senha: ');
          String senhaFinal = lerSenhaOculta();
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
        String ultimaSenha = lerSenhaOculta();
        if (ultimoCodigo == usuario.codigoUnico &&
            usuario.senhaConfere(ultimaSenha)) {
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
    print(
      'Você está gerenciando: ${usuario.eventoGerenciado?.obterDadosEvento()}',
    );
    return usuario;
  } else {
    print('Número máximo de tentativas excedido. Acesso bloqueado.');
    return null;
  }
}
