import 'usuario.dart';
import 'validacao.dart';

bool _idadeValida(int idade) => idade >= 0 && idade <= 130;

class Convidado extends Usuario {
  int? _idade;
  String? _assento;

  Convidado({
    super.idBanco,
    super.nome,
    super.email,
    super.telefone,
    int? idade,
    String? assento,
  })  : _idade = idade,
        _assento = assento;

  Convidado.doBanco({
    required int idBanco,
    required String nome,
    required String email,
    String? telefone,
    int? idade,
    String? assento,
  })  : _idade = idade,
        _assento = assento,
        super(idBanco: idBanco, nome: nome, email: email, telefone: telefone);

  int? get idade => _idade;

  set idade(int? valor) {
    if (valor != null && !_idadeValida(valor)) {
      throw ArgumentError('Idade inválida: $valor');
    }
    _idade = valor;
  }

  String? get assento => _assento;

  set assento(String? valor) => _assento = valor?.trim();

  void cadastrar() {
    nome = lerTextoNaoVazio('Digite o nome do convidado: ');
    email = lerEmailValido('Digite o email do convidado: ');
    telefone = lerTextoOpcional('Digite o telefone do convidado (Enter para pular): ');
    print('Digite a idade do convidado (Enter para pular): ');
    final idadeDigitada = int.tryParse(lerLinha().trim());
    idade = idadeDigitada != null && _idadeValida(idadeDigitada) ? idadeDigitada : null;
    assento = lerTextoOpcional('Digite o assento, ex: A12 (Enter para pular): ');
  }

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
    final idadeNova = int.tryParse(novaIdade);

    print('Assento atual: ${assento ?? '-'}');
    final novoAssento = lerLinha().trim();

    return Convidado(
      idBanco: idBanco,
      nome: novoNome.isEmpty ? nome : novoNome,
      email: novoEmail,
      telefone: novoTelefone.isEmpty ? telefone : novoTelefone,
      idade: novaIdade.isEmpty
          ? idade
          : (idadeNova != null && _idadeValida(idadeNova) ? idadeNova : idade),
      assento: novoAssento.isEmpty ? assento : novoAssento,
    );
  }

  @override
  String obterDados() {
    return 'ID: $idBanco | Nome: $nome | Email: ${email ?? '-'} | '
        'Telefone: ${telefone ?? '-'} | Idade: ${idade ?? '-'} | '
        'Assento: ${assento ?? '-'}';
  }
}
