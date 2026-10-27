import 'package:bcrypt/bcrypt.dart';

/// Gera o hash bcrypt de uma senha. Só o hash vai para o banco.
String gerarHashSenha(String senha) => BCrypt.hashpw(senha, BCrypt.gensalt());

/// Confere uma senha digitada contra o hash guardado no banco.
/// Hash malformado é tratado como senha errada, sem derrubar o programa.
bool senhaConfere(String senha, String hash) {
  try {
    return BCrypt.checkpw(senha, hash);
  } catch (_) {
    return false;
  }
}
