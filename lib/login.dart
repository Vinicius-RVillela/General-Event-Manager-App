import 'dart:io';

import 'banco.dart';
import 'Organizador.dart';
import 'seguranca.dart';
import 'usuario.dart';
import 'validacao.dart';

/// Regras do login (ajuste aqui se quiser):
const int tentativasIniciais = 3;
const int tentativasAposEspera = 2;
const int esperaSegundos = 60;
const int minimoCaracteresSenha = 6;

/// Lê a senha sem mostrar o que está sendo digitado.
String lerSenhaOculta() {
  bool ocultou = false;
  try {
    stdin.echoMode = false;
    ocultou = true;
  } catch (_) {
    // Terminal que não permite ocultar: lê normalmente.
  }
  final senha = lerLinha();
  if (ocultou) {
    try {
      stdin.echoMode = true;
    } catch (_) {}
    print('');
  }
  return senha;
}

/// Aceita o email normal ou o usuário especial "admin".
String lerEmailOuAdmin(String mensagem) {
  while (true) {
    print(mensagem);
    final entrada = lerLinha().trim();
    if (entrada == 'admin' || emailValido(entrada)) return entrada;
    print('Email inválido. Tente novamente.');
  }
}

/// Fluxo completo de login. Só ENTRA quem existir no banco com nome, email e
/// senha corretos. Nada é criado aqui: login só verifica e registra o acesso.
///
/// Ordem: 3 tentativas -> bloqueio de 1 minuto -> 2 tentativas
/// -> "esqueci a senha" (troca a senha do mesmo cadastro) -> volta ao login.
Future<Organizador?> executarLogin() async {
  while (true) {
    var org = await _rodada(tentativasIniciais, aplicarEspera: true);
    org ??= await _rodada(tentativasAposEspera, aplicarEspera: false);

    if (org != null) {
      org.idSessao = await banco.iniciarSessao(org.idBanco!);
      print('\nAcesso permitido! Seja bem-vindo, ${org.nome}.');
      return org;
    }

    print('\nVocê errou todas as tentativas.');
    final senhaTrocada = await _esqueciASenha();
    if (!senhaTrocada) {
      print('Login cancelado.');
      return null;
    }
    print('Senha atualizada. Faça login com a nova senha.');
  }
}

/// Uma rodada de tentativas. Devolve o organizador ao acertar, ou null.
Future<Organizador?> _rodada(int quantidade, {required bool aplicarEspera}) async {
  for (int i = 1; i <= quantidade; i++) {
    print('\nTentativa $i de $quantidade');
    final nome = lerNomeValido('Digite seu nome: ');
    final email = lerEmailOuAdmin('Digite seu email: ');
    print('Digite sua senha: ');
    final senha = lerSenhaOculta();

    // Se o email estiver bloqueado (até por outra execução), espera o tempo real que falta.
    final restante = await banco.segundosDeBloqueio(email);
    if (restante > 0) {
      print('Acesso bloqueado temporariamente. Aguarde $restante segundos.');
      await _esperar(restante);
    }

    final org = await _verificar(nome, email, senha);
    await banco.registrarTentativa(
      email,
      sucesso: org != null,
      idOrganizador: org?.idBanco,
    );

    if (org != null) {
      await banco.liberarLogin(email);
      return org;
    }

    print('Nome, email ou senha incorretos.');

    if (aplicarEspera && i == quantidade) {
      print('Você errou as $quantidade tentativas. Aguarde $esperaSegundos segundos.');
      await banco.bloquearLogin(email, esperaSegundos);
      await _esperar(esperaSegundos);
      print('Tempo de espera encerrado. Você tem $tentativasAposEspera tentativas.');
    }
  }
  return null;
}

/// Espera de verdade, mostrando a contagem a cada 15 segundos.
Future<void> _esperar(int segundos) async {
  for (int restante = segundos; restante > 0; restante--) {
    await Future.delayed(const Duration(seconds: 1));
    if (restante > 1 && restante % 15 == 0) {
      print('Faltam $restante segundos...');
    }
  }
}

/// Confere nome, email e senha contra o banco.
Future<Organizador?> _verificar(String nome, String email, String senha) async {
  final linha = await banco.buscarOrganizadorPorEmail(email);
  if (linha == null) return null;
  if (!_nomeConfere(linha['nome'], nome)) return null;

  final hash = linha['senha_hash'];
  if (hash == null || hash.isEmpty || !senhaConfere(senha, hash)) return null;

  return _paraOrganizador(linha);
}

/// Esqueci a senha: confere nome e email do cadastro e troca só a senha
/// desse mesmo registro. Nunca cria um usuário novo.
/// Devolve true se a senha foi trocada, false se o usuário desistiu.
Future<bool> _esqueciASenha() async {
  print('\n=== Esqueci minha senha ===');
  print('Para trocar a senha, confirme o nome e o email do cadastro.');

  Organizador? alvo;
  for (int i = 1; i <= 3 && alvo == null; i++) {
    final nome = lerNomeValido('Digite seu nome: ');
    final email = lerEmailOuAdmin('Digite seu email: ');
    alvo = await _verificarIdentidade(nome, email);
    if (alvo == null) {
      print('Nome ou email não conferem com o cadastro (tentativa $i de 3).');
    }
  }
  if (alvo == null) return false;

  print('Identidade confirmada. Digite a nova senha; ela substituirá a atual.');
  final novaSenha = _lerNovaSenha();
  await banco.trocarSenha(alvo.idBanco!, gerarHashSenha(novaSenha));
  return true;
}

/// Pede a nova senha duas vezes até as duas coincidirem e terem tamanho mínimo.
String _lerNovaSenha() {
  while (true) {
    print('Digite a nova senha (mínimo $minimoCaracteresSenha caracteres): ');
    final nova = lerSenhaOculta();
    if (nova.length < minimoCaracteresSenha) {
      print('Senha muito curta. Tente novamente.');
      continue;
    }
    print('Repita a nova senha: ');
    final repetida = lerSenhaOculta();
    if (nova != repetida) {
      print('As senhas não conferem. Tente novamente.');
      continue;
    }
    return nova;
  }
}

Future<Organizador?> _verificarIdentidade(String nome, String email) async {
  final linha = await banco.buscarOrganizadorPorEmail(email);
  if (linha == null || !_nomeConfere(linha['nome'], nome)) return null;
  return _paraOrganizador(linha);
}

bool _nomeConfere(String? nomeBanco, String nomeDigitado) {
  return nomeBanco != null &&
      normalizar(nomeBanco.trim()) == normalizar(nomeDigitado.trim());
}

Organizador _paraOrganizador(Map<String, String?> linha) {
  return Organizador(
    idBanco: int.parse(linha['id']!),
    nome: linha['nome'],
    email: linha['email'],
    telefone: linha['telefone'],
  );
}
