import 'package:bcrypt/bcrypt.dart';

String gerarHashSenha(String senha) => BCrypt.hashpw(senha, BCrypt.gensalt());

bool senhaConfere(String senha, String hash) {
  try {
    return BCrypt.checkpw(senha, hash);
  } catch (_) {
    return false;
  }
}
