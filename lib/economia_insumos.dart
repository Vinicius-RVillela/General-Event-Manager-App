import 'Checkin.dart';
import 'Convite.dart';
import 'Evento.dart';

/// Valores da planilha (aba RelatorioPosEvento). Ajuste aqui se mudar a base.
const double consumoPorPessoaKg = 0.4; // ConsumoMedioPorPessoaKg
const double margemPlanejamento = 0.15; // MargemPlanejamento
const double custoPorKg = 45.0; // CustoPorKg

/// Resultado do cálculo de insumos (comida) de um evento.
class EconomiaInsumos {
  final int cadastrados;
  final int confirmados;
  final int presentes;
  final double planejadoSobreCadastradosKg;
  final double planejadoSobreConfirmadosKg;
  final double consumidoKg;
  final double desperdicioKg;
  final double economiaKg;
  final double economiaReais;
  final double desperdicioReais;

  const EconomiaInsumos({
    required this.cadastrados,
    required this.confirmados,
    required this.presentes,
    required this.planejadoSobreCadastradosKg,
    required this.planejadoSobreConfirmadosKg,
    required this.consumidoKg,
    required this.desperdicioKg,
    required this.economiaKg,
    required this.economiaReais,
    required this.desperdicioReais,
  });
}

/// Calcula a economia de insumos do evento, pelas mesmas fórmulas da planilha:
/// planejado = pessoas × consumo × (1 + margem)
/// Economia = planejar com TODOS os cadastrados menos planejar só com os CONFIRMADOS.
EconomiaInsumos calcularEconomiaInsumos(
  Evento evento,
  List<Convite> convites,
  List<Checkin> checkins,
) {
  final doEvento = convites.where((cv) => cv.evento == evento).toList();
  final cadastrados = doEvento.length;
  final confirmados =
      doEvento.where((cv) => cv.status == StatusConfirmacao.confirmado).length;
  final presentes =
      checkins.where((chk) => chk.convite.evento == evento && chk.presente).length;

  final fator = consumoPorPessoaKg * (1 + margemPlanejamento);
  final planejadoCadastrados = cadastrados * fator;
  final planejadoConfirmados = confirmados * fator;
  final consumido = presentes * consumoPorPessoaKg;
  final desperdicio = planejadoConfirmados - consumido;
  final economia = planejadoCadastrados - planejadoConfirmados;

  return EconomiaInsumos(
    cadastrados: cadastrados,
    confirmados: confirmados,
    presentes: presentes,
    planejadoSobreCadastradosKg: planejadoCadastrados,
    planejadoSobreConfirmadosKg: planejadoConfirmados,
    consumidoKg: consumido,
    desperdicioKg: desperdicio,
    economiaKg: economia,
    economiaReais: economia * custoPorKg,
    desperdicioReais: desperdicio * custoPorKg,
  );
}

/// Mostra a economia de insumos do evento no terminal.
void mostrarEconomiaInsumos(
  Evento evento,
  List<Convite> convites,
  List<Checkin> checkins,
) {
  final e = calcularEconomiaInsumos(evento, convites, checkins);
  String kg(double v) => '${v.toStringAsFixed(2)} kg';
  String reais(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  print('\n--- Economia de insumos: ${evento.nomeEvento} ---');
  print('Cadastrados: ${e.cadastrados} | Confirmados: ${e.confirmados} | '
      'Presentes: ${e.presentes}');
  print('Comida planejada com todos os cadastrados: ${kg(e.planejadoSobreCadastradosKg)}');
  print('Comida planejada com os confirmados:       ${kg(e.planejadoSobreConfirmadosKg)}');
  print('ECONOMIA (não preparar para quem não confirmou): '
      '${kg(e.economiaKg)} = ${reais(e.economiaReais)}');
  print('');
  print('Comida realmente consumida (presentes):    ${kg(e.consumidoKg)}');
  print('Desperdício real (planejado - consumido):  ${kg(e.desperdicioKg)} = '
      '${reais(e.desperdicioReais)}');
  print('Premissas: ${consumoPorPessoaKg}kg por pessoa, margem de '
      '${(margemPlanejamento * 100).toStringAsFixed(0)}%, custo R\$ '
      '${custoPorKg.toStringAsFixed(2)}/kg.');
}
