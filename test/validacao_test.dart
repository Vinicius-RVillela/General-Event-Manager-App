import 'package:test/test.dart';
import 'package:app_eventos/validacao.dart';

void main() {
  group('nomeValido', () {
    test('nome normal é válido', () {
      expect(nomeValido('Vinicius'), true);
    });

    test('nome vazio é inválido', () {
      expect(nomeValido(''), false);
    });

    test('nome só com espaços é inválido', () {
      expect(nomeValido('   '), false);
    });

    test('nome muito longo (acima de 100 caracteres) é inválido', () {
      String nomeGigante = 'A' * 101;
      expect(nomeValido(nomeGigante), false);
    });

    test('nome no limite de 100 caracteres é válido', () {
      String nomeNoLimite = 'A' * 100;
      expect(nomeValido(nomeNoLimite), true);
    });
  });

  group('cpfValido — CPFs reais (matematicamente válidos)', () {
    test('CPF válido com pontuação é aceito', () {
      expect(cpfValido('529.982.247-25'), true);
    });

    test('CPF válido sem pontuação é aceito', () {
      expect(cpfValido('52998224725'), true);
    });
  });

  group('cpfValido — rejeita CPFs inválidos', () {
    test('CPF com dígito verificador errado é rejeitado', () {
      // Mesmo número do CPF válido acima, mas com o último dígito trocado.
      expect(cpfValido('529.982.247-26'), false);
    });

    test('CPF com menos de 11 dígitos é rejeitado', () {
      expect(cpfValido('123456789'), false);
    });

    test('CPF com mais de 11 dígitos é rejeitado', () {
      expect(cpfValido('123456789012'), false);
    });

    test('CPF vazio é rejeitado', () {
      expect(cpfValido(''), false);
    });

    test('sequência repetida (111.111.111-11) é rejeitada', () {
      // Tem 11 dígitos e passaria na conta dos verificadores,
      // mas não é um CPF real — por isso tem checagem própria.
      expect(cpfValido('111.111.111-11'), false);
    });

    test('sequência repetida de zeros (000.000.000-00) é rejeitada', () {
      expect(cpfValido('000.000.000-00'), false);
    });

    test('texto que não é número é rejeitado', () {
      expect(cpfValido('abc.def.ghi-jk'), false);
    });
  });
}
