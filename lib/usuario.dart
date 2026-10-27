/// Dados comuns de uma pessoa (organizador ou convidado).
/// idBanco é o id gerado pelo MySQL: só existe depois de gravado no banco.
class Usuario {
  int? idBanco;
  String? nome;
  String? email;
  String? telefone;

  Usuario({this.idBanco, this.nome, this.email, this.telefone});
}

/// Usado para comparar NOMES e tipos (ignora acentos e maiúsculas).
/// Nunca usar para senhas.
String normalizar(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  String resultado = texto.toLowerCase();
  for (int i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
  }
  return resultado;
}
