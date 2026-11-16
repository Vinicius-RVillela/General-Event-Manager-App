import 'Evento.dart';
import 'Registro.dart';
import 'convidado.dart';
import 'validacao.dart';

/// Por que a pessoa saiu da fila (vai para a tabela historico_lista_espera).
enum MotivoSaidaFila { promovido, removido }

/// Uma pessoa esperando vaga em um evento. Espelho da tabela lista_espera.
///
/// Herda de Registro (como Convite, Checkin e Mesa): ganha o idBanco e é
/// obrigada a implementar obterDados() — isso é polimorfismo.
class ItemListaEspera extends Registro {
  final Evento _evento;
  final Convidado _convidado;
  int _posicao;
  final DateTime _criadoEm;

  ItemListaEspera({
    super.idBanco,
    required Evento evento,
    required Convidado convidado,
    required int posicao,
    DateTime? criadoEm,
  })  : _evento = evento,
        _convidado = convidado,
        _posicao = _posicaoValida(posicao),
        _criadoEm = criadoEm ?? DateTime.now();

  ItemListaEspera.doBanco({
    required int idBanco,
    required Evento evento,
    required Convidado convidado,
    required int posicao,
    required DateTime criadoEm,
  }) : this(
          idBanco: idBanco,
          evento: evento,
          convidado: convidado,
          posicao: posicao,
          criadoEm: criadoEm,
        );

  Evento get evento => _evento;

  Convidado get convidado => _convidado;

  int get posicao => _posicao;

  set posicao(int valor) => _posicao = _posicaoValida(valor);

  DateTime get criadoEm => _criadoEm;

  static int _posicaoValida(int valor) {
    if (valor < 1) {
      throw ArgumentError('A posição na fila começa em 1: $valor');
    }
    return valor;
  }

  @override
  String obterDados() {
    return '$_posicaoº | ${_convidado.nome} (id ${_convidado.idBanco}) | '
        'na fila desde ${formatarDataHora(_criadoEm)}';
  }
}
