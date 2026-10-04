class Endereco {
  static int _proximoId = 1;
  late int id;
String? rua;
int? numero;
String? bairro;
String? cep;
String? cidade;
String? estado;
String? pais;

Endereco(this.rua, this.numero, this.bairro, this.cep, this.cidade, this.estado, this.pais)
{
  id = _proximoId++;

    
}}