import 'dart:math' as math;

import 'border_result.dart';

class BorderStake {
  final double xM, avancoMin;
  final double? recessaoMin;
  const BorderStake(this.xM, this.avancoMin, {this.recessaoMin});

  Map<String, dynamic> toMap() => {
    'xM': xM,
    'avancoMin': avancoMin,
    'recessaoMin': recessaoMin,
  };
  factory BorderStake.fromMap(Map<String, dynamic> map) => BorderStake(
    (map['xM'] as num).toDouble(),
    (map['avancoMin'] as num).toDouble(),
    recessaoMin: (map['recessaoMin'] as num?)?.toDouble(),
  );
}

class BorderTerrainPoint {
  final double xM, cotaM;
  const BorderTerrainPoint(this.xM, this.cotaM);
  Map<String, double> toMap() => {'xM': xM, 'cotaM': cotaM};
  factory BorderTerrainPoint.fromMap(Map<String, dynamic> map) =>
      BorderTerrainPoint(
        (map['xM'] as num).toDouble(),
        (map['cotaM'] as num).toDouble(),
      );
}

class BorderMeasuredAdvance {
  final List<BorderStake> stakes;
  final double p, r, rmseMin;
  const BorderMeasuredAdvance(this.stakes, this.p, this.r, this.rmseMin);

  double arrival(double x) {
    if (x < 0 || x > stakes.last.xM) {
      throw const BorderModelException(
        BorderStatus.foraDoDominio,
        'Extrapolação de ensaio fora das estacas.',
        pagina: 'pp. 45, 57–62',
      );
    }
    if (x == 0) return 0;
    return math.pow(x / p, 1 / r).toDouble();
  }
}
