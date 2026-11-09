import 'Convite.dart';
import 'Checkin.dart';

class EstatisticasEvento {
  final int totalConvites;
  final int totalConfirmados;
  final int totalCheckins;
  final double percentualConfirmados;
  final double percentualPresenca;

  const EstatisticasEvento({
    required this.totalConvites,
    required this.totalConfirmados,
    required this.totalCheckins,
    required this.percentualConfirmados,
    required this.percentualPresenca,
  });
}

EstatisticasEvento calcularEstatisticas(List<Convite> convites, List<Checkin> checkins) {
  final totalConvites = convites.length;
  final totalConfirmados =
      convites.where((c) => c.status == StatusConfirmacao.confirmado).length;
  final totalCheckins = checkins.where((chk) => chk.presente == true).length;

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
