import 'Convite.dart';
import 'Checkin.dart';

/// Resultado das contas de um evento: quantos convites, quantos confirmaram
/// e quantos realmente compareceram (check-in).
class EstatisticasEvento {
  final int totalConvites;
  final int totalConfirmados;
  final int totalCheckins;
  final double percentualConfirmados; // % dos convites que foram confirmados
  final double percentualPresenca; // % dos confirmados que fizeram check-in

  const EstatisticasEvento({
    required this.totalConvites,
    required this.totalConfirmados,
    required this.totalCheckins,
    required this.percentualConfirmados,
    required this.percentualPresenca,
  });
}

/// Calcula as estatísticas a partir das listas recebidas.
/// Passe apenas os convites e check-ins do evento que quer analisar
/// (o main.dart já faz esse filtro pelo evento ativo).
EstatisticasEvento calcularEstatisticas(List<Convite> convites, List<Checkin> checkins) {
  final totalConvites = convites.length;
  final totalConfirmados =
      convites.where((c) => c.status == StatusConfirmacao.confirmado).length;
  final totalCheckins = checkins.where((chk) => chk.presente == true).length;

  // Evita divisão por zero quando ainda não há convites ou confirmados.
  final percentualConfirmados =
      totalConvites == 0 ? 0.0 : (totalConfirmados / totalConvites) * 100;
  final percentualPresenca =
      totalConfirmados == 0 ? 0.0 : (totalCheckins / totalConfirmados) * 100;

  return EstatisticasEvento(
    totalConvites: totalConvites,
    totalConfirmados: totalConfirmados,
    totalCheckins: totalCheckins,
    percentualConfirmados: percentualConfirmados,
    percentualPresenca: percentualPresenca,
  );
}
