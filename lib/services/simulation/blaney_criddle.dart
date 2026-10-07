import 'dart:math' as math;

/// Estimativa de ETo pelo método de Blaney–Criddle em base diária.
///
/// O fator [p] é obtido como a porcentagem das horas anuais de luz do dia
/// correspondente ao mês, a partir da latitude e do fotoperíodo do dia 15.
class BlaneyCriddle {
  const BlaneyCriddle._();

  static double etoMmDia({
    required double temperaturaMediaC,
    required double latitudeGraus,
    required int mes,
  }) {
    if (!temperaturaMediaC.isFinite || temperaturaMediaC < 0) {
      throw ArgumentError.value(
        temperaturaMediaC,
        'temperaturaMediaC',
        'deve ser finita e não negativa',
      );
    }
    if (!latitudeGraus.isFinite || latitudeGraus.abs() > 60) {
      throw ArgumentError.value(
        latitudeGraus,
        'latitudeGraus',
        'deve estar entre -60° e 60°',
      );
    }
    if (mes < 1 || mes > 12) {
      throw ArgumentError.value(mes, 'mes', 'deve estar entre 1 e 12');
    }

    final diasNoMes = DateTime(2024, mes + 1, 0).day;
    final horasDiaMes = _horasDeLuz(latitudeGraus, _diaDoAno(mes, 15));
    var horasLuzAnuais = 0.0;
    for (var mesAno = 1; mesAno <= 12; mesAno++) {
      final dias = DateTime(2024, mesAno + 1, 0).day;
      horasLuzAnuais +=
          _horasDeLuz(latitudeGraus, _diaDoAno(mesAno, 15)) * dias;
    }
    final pMensalPercentual = horasDiaMes * diasNoMes / horasLuzAnuais * 100;
    final etoMensal = pMensalPercentual * (0.457 * temperaturaMediaC + 8.128);
    return etoMensal / diasNoMes;
  }

  static int _diaDoAno(int mes, int dia) =>
      DateTime(2024, mes, dia).difference(DateTime(2024)).inDays + 1;

  static double _horasDeLuz(double latitudeGraus, int diaDoAno) {
    final latitude = latitudeGraus * math.pi / 180;
    final declinacao = 0.409 * math.sin(2 * math.pi * diaDoAno / 365 - 1.39);
    final cosenoAnguloHorario = -math.tan(latitude) * math.tan(declinacao);
    final anguloHorario = math.acos(cosenoAnguloHorario.clamp(-1.0, 1.0));
    return 24 * anguloHorario / math.pi;
  }
}
