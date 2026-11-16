import 'Convite.dart';
import 'Evento.dart';
import 'ListaEspera.dart';

/// Cálculo das vagas de um evento, feito AQUI no código (e não pela VIEW do banco).
///
/// Convite "ativo" = qualquer convite que não foi recusado (pendente ou confirmado),
/// porque ele ainda ocupa um lugar no evento.
class VagasEvento {
  final int? limite; // null = sem limite
  final int convitesAtivos;
  final int pessoasNaFila;

  VagasEvento({required this.limite, required this.convitesAtivos, required this.pessoasNaFila});

  /// Faz a conta a partir das listas que o programa já tem na memória.
  factory VagasEvento.calcular(
    Evento evento,
    List<Convite> convites,
    List<ItemListaEspera> fila,
  ) {
    final ativos = convites
        .where((c) => c.evento == evento && c.status != StatusConfirmacao.recusado)
        .length;
    final naFila = fila.where((item) => item.evento == evento).length;
    return VagasEvento(limite: evento.limiteConvidados, convitesAtivos: ativos, pessoasNaFila: naFila);
  }

  bool get temLimite => limite != null;

  /// Quantas vagas sobram. Sem limite, não faz sentido falar em vagas (null).
  /// Nunca fica negativo: se o limite baixou abaixo dos convites, mostra 0.
  int? get vagasLivres {
    final l = limite;
    if (l == null) return null;
    final sobra = l - convitesAtivos;
    return sobra < 0 ? 0 : sobra;
  }

  /// O evento está lotado quando tem limite e não sobra vaga.
  bool get lotado => temLimite && vagasLivres == 0;

  /// Quantas pessoas da fila cabem agora (o menor entre vagas livres e tamanho da fila).
  int get cabemDaFila {
    final v = vagasLivres;
    if (v == null) return pessoasNaFila; // sem limite: todos cabem
    return v < pessoasNaFila ? v : pessoasNaFila;
  }

  String resumo() {
    final linhaLimite = temLimite ? '$limite' : 'sem limite';
    final linhaVagas = temLimite ? '$vagasLivres' : '-';
    return 'Limite: $linhaLimite | Convites ativos: $convitesAtivos | '
        'Vagas livres: $linhaVagas | Na fila: $pessoasNaFila'
        '${lotado ? ' | EVENTO LOTADO' : ''}';
  }
}
