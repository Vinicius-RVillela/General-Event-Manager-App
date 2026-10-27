import 'package:test/test.dart';
import 'package:app_eventos/seguranca.dart';
import 'package:app_eventos/usuario.dart';

void main() {
  group('Senha (bcrypt)', () {
    test('senha correta confere', () {
      final hash = gerarHashSenha('minhaSenha123');
      expect(senhaConfere('minhaSenha123', hash), true);
    });

    test('senha errada não confere', () {
      final hash = gerarHashSenha('minhaSenha123');
      expect(senhaConfere('senhaErrada', hash), false);
    });

    test('diferença de maiúscula/minúscula NÃO confere', () {
      final hash = gerarHashSenha('Senha123');
      expect(senhaConfere('senha123', hash), false);
    });

    test('o hash nunca é a senha em texto puro', () {
      final hash = gerarHashSenha('segredo');
      expect(hash.contains('segredo'), false);
    });

    test('hash malformado é tratado como senha errada', () {
      expect(senhaConfere('qualquer', 'nao-e-um-hash'), false);
    });
  });

  group('Comparação de nomes (normalizar)', () {
    test('ignora acentos e maiúsculas', () {
      expect(normalizar('José Ação'), normalizar('jose acao'));
    });
  });
}
