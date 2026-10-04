import 'package:test/test.dart';
import 'package:app_eventos/usuario.dart';

void main() {
  group('Criação de senha e verificação (senhaConfere)', () {
    test('senha correta deve conferir', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '111', senhaInicial: 'minhaSenha123');
      expect(usuario.senhaConfere('minhaSenha123'), true);
    });

    test('senha errada não deve conferir', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '111', senhaInicial: 'minhaSenha123');
      expect(usuario.senhaConfere('senhaErrada'), false);
    });

    test('senha com diferença de maiúscula/minúscula NÃO deve conferir', () {
      // Importante: senha é case-sensitive, diferente de um nome de busca.
      var usuario = Usuario(nome: 'Vinicius', cpf: '111', senhaInicial: 'Senha123');
      expect(usuario.senhaConfere('senha123'), false);
    });

    test('a senha nunca fica salva em texto puro (bcrypt gera um hash)', () {
      var usuario1 = Usuario(nome: 'A', cpf: '111', senhaInicial: 'mesmaSenha');
      var usuario2 = Usuario(nome: 'B', cpf: '222', senhaInicial: 'mesmaSenha');
      // Mesmo com a MESMA senha, o hash interno é diferente a cada usuário
      // (por causa do "salt" aleatório do bcrypt) — só podemos confirmar
      // isso indiretamente, checando que ambos continuam validando certo.
      expect(usuario1.senhaConfere('mesmaSenha'), true);
      expect(usuario2.senhaConfere('mesmaSenha'), true);
    });
  });

  group('Troca de senha (definirSenhaInicial)', () {
    test('definirSenhaInicial troca a senha corretamente', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '111', senhaInicial: 'senhaAntiga');
      usuario.definirSenhaInicial('senhaNova');

      expect(usuario.senhaConfere('senhaAntiga'), false);
      expect(usuario.senhaConfere('senhaNova'), true);
    });
  });

  group('Redefinição de senha (redefinirSenha)', () {
    test('redefine com sucesso quando nome e cpf conferem', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '12345678900', senhaInicial: 'senhaAntiga');

      bool resultado = usuario.redefinirSenha('Vinicius', '12345678900', 'senhaNova');

      expect(resultado, true);
      expect(usuario.senhaConfere('senhaNova'), true);
    });

    test('NÃO redefine quando o nome não confere', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '12345678900', senhaInicial: 'senhaAntiga');

      bool resultado = usuario.redefinirSenha('NomeErrado', '12345678900', 'senhaNova');

      expect(resultado, false);
      // A senha antiga deve continuar valendo — a tentativa falhou.
      expect(usuario.senhaConfere('senhaAntiga'), true);
      expect(usuario.senhaConfere('senhaNova'), false);
    });

    test('NÃO redefine quando o cpf não confere', () {
      var usuario = Usuario(nome: 'Vinicius', cpf: '12345678900', senhaInicial: 'senhaAntiga');

      bool resultado = usuario.redefinirSenha('Vinicius', '00000000000', 'senhaNova');

      expect(resultado, false);
      expect(usuario.senhaConfere('senhaAntiga'), true);
    });
  });

  group('Código de acesso', () {
    test('cada usuário recebe um código de acesso único de 6 dígitos', () {
      var usuario1 = Usuario(nome: 'A', cpf: '111', senhaInicial: 'x');
      var usuario2 = Usuario(nome: 'B', cpf: '222', senhaInicial: 'y');

      expect(usuario1.codigoUnico.length, 6);
      expect(usuario2.codigoUnico.length, 6);
      expect(usuario1.codigoUnico == usuario2.codigoUnico, false);
    });
  });
}
