import 'usuario.dart';
import 'validacao.dart';

/// Pessoa convidada. Tabela convidado.
class Convidado extends Usuario {
  int? idade;
  String? assento;

  Convidado({
    super.idBanco,
    super.nome,
    super.email,
    super.telefone,
    this.idade,
    this.assento,
  });

  /// Pergunta os dados no terminal. Nome e email são obrigatórios.
  void cadastrar() {
    nome = lerTextoNaoVazio('Digite o nome do convidado: ');
    email = lerEmailValido('Digite o email do convidado: ');
    telefone = lerTextoOpcional('Digite o telefone do convidado (Enter para pular): ');
    print('Digite a idade do convidado (Enter para pular): ');
    idade = int.tryParse(lerLinha().trim());
    assento = lerTextoOpcional('Digite o assento, ex: A12 (Enter para pular): ');
  }

  /// Pergunta os novos dados. Enter mantém o valor atual de cada campo.
  /// Devolve uma CÓPIA com as alterações; quem chama grava no banco.
  Convidado editarNoTerminal() {
    print('Deixe em branco para manter o valor atual.');

    print('Nome atual: $nome');
    final novoNome = lerLinha().trim();

    String? novoEmail = email;
    while (true) {
      print('Email atual: ${email ?? '-'}');
      final entrada = lerLinha().trim();
      if (entrada.isEmpty) break;
      if (emailValido(entrada)) {
        novoEmail = entrada;
        break;
      }
      print('Email inválido. Tente novamente ou deixe em branco.');
    }

    print('Telefone atual: ${telefone ?? '-'}');
    final novoTelefone = lerLinha().trim();

    print('Idade atual: ${idade ?? '-'}');
    final novaIdade = lerLinha().trim();

    print('Assento atual: ${assento ?? '-'}');
    final novoAssento = lerLinha().trim();

    return Convidado(
      idBanco: idBanco,
      nome: novoNome.isEmpty ? nome : novoNome,
      email: novoEmail,
      telefone: novoTelefone.isEmpty ? telefone : novoTelefone,
      idade: novaIdade.isEmpty ? idade : (int.tryParse(novaIdade) ?? idade),
      assento: novoAssento.isEmpty ? assento : novoAssento,
    );
  }

  String obterDados() {
    return 'ID: $idBanco | Nome: $nome | Email: ${email ?? '-'} | '
        'Telefone: ${telefone ?? '-'} | Idade: ${idade ?? '-'} | '
        'Assento: ${assento ?? '-'}';
  }
}
