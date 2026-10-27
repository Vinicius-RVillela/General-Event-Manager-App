import 'package:app_eventos/banco.dart';
import 'package:app_eventos/login.dart';
import 'package:app_eventos/seguranca.dart';
import 'package:app_eventos/validacao.dart';

/// Utilitário para criar um organizador (acesso ao sistema).
/// Rode no terminal:  dart run bin/cadastrar_usuario.dart
Future<void> main() async {
  try {
    await banco.conectar();
  } catch (e) {
    print('Não foi possível conectar ao MySQL: $e');
    print('Confira ConfigBanco em lib/banco.dart (host, porta, usuário, senha, banco).');
    return;
  }

  try {
    final nome = lerNomeValido('Nome do organizador: ');
    final email = lerEmailValido('Email: ');

    if (await banco.buscarOrganizadorPorEmail(email) != null) {
      print('Já existe um organizador ativo com este email. Nada foi criado.');
      return;
    }

    print('Senha (mínimo $minimoCaracteresSenha caracteres): ');
    final senha = lerSenhaOculta();
    if (senha.length < minimoCaracteresSenha) {
      print('Senha muito curta. Nada foi criado.');
      return;
    }

    final telefone = lerTextoOpcional('Telefone (Enter para pular): ');
    final id = await banco.cadastrarOrganizador(
      nome: nome,
      email: email,
      telefone: telefone,
      hash: gerarHashSenha(senha),
    );
    print('Organizador criado com id $id. Já pode fazer login.');
  } catch (e) {
    print('Erro ao cadastrar: $e');
  } finally {
    await banco.desconectar();
  }
}
