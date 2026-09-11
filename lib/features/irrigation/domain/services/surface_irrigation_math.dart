import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';

class AdvanceCurve {
  const AdvanceCurve({
    required this.coefficient,
    required this.exponent,
    required this.points,
  });

  final double coefficient;
  final double exponent;
  final List<PontoGrafico> points;

  double timeAt(double distanceM) =>
      distanceM <= 0 ? 0 : coefficient * pow(distanceM, exponent);
}

class WaterBalanceResult {
  const WaterBalanceResult({
    required this.appliedDepthM,
    required this.meanInfiltratedDepthM,
    required this.applicationEfficiency,
    required this.requirementEfficiency,
    required this.distributionEfficiency,
    required this.deepPercolationPercent,
    required this.runoffPercent,
    required this.residualPercent,
  });

  final double appliedDepthM;
  final double meanInfiltratedDepthM;
  final double applicationEfficiency;
  final double requirementEfficiency;
  final double distributionEfficiency;
  final double deepPercolationPercent;
  final double runoffPercent;
  final double residualPercent;
}

class SurfaceIrrigationMath {
  const SurfaceIrrigationMath._();

  static AdvanceCurve fitAdvanceCurve({
    required double lengthM,
    required double halfTimeMin,
    required double endTimeMin,
    int samples = 20,
  }) {
    if (lengthM <= 0 || halfTimeMin <= 0 || endTimeMin <= halfTimeMin) {
      throw const FormatException(
        'O avanço na metade deve ser positivo e menor que o avanço final.',
      );
    }
    final exponent = (log(halfTimeMin) - log(endTimeMin)) / log(0.5);
    if (!exponent.isFinite || exponent <= 0) {
      throw const FormatException(
        'Os dados de avanço não formam uma curva válida.',
      );
    }
    final coefficient = endTimeMin / pow(lengthM, exponent);
    final points = <PontoGrafico>[];
    for (var i = 0; i <= samples; i++) {
      final distance = lengthM * i / samples;
      final time = distance == 0
          ? 0.0
          : coefficient * pow(distance, exponent).toDouble();
      points.add(PontoGrafico(time, distance));
    }
    return AdvanceCurve(
      coefficient: coefficient,
      exponent: exponent,
      points: points,
    );
  }

  /// Kostiakov–Lewis com tempo em minutos e lâmina acumulada em metros.
  static double infiltrationM(
    double opportunityMin,
    double kMMinA,
    double exponent,
    double basicRateMMin,
  ) {
    if (opportunityMin <= 0) return 0;
    return kMMinA * pow(opportunityMin, exponent) +
        basicRateMMin * opportunityMin;
  }

  static double solveOpportunityTimeMin({
    required double targetDepthM,
    required double kMMinA,
    required double exponent,
    required double basicRateMMin,
  }) {
    if (targetDepthM <= 0 || kMMinA < 0 || basicRateMMin < 0) {
      throw const FormatException(
        'Revise a lâmina e os parâmetros de infiltração.',
      );
    }
    if (exponent <= 0 || exponent >= 1) {
      throw const FormatException(
        'O expoente de Kostiakov deve estar entre 0 e 1.',
      );
    }
    var lower = 0.0;
    var upper = 1.0;
    while (infiltrationM(upper, kMMinA, exponent, basicRateMMin) <
        targetDepthM) {
      upper *= 2;
      if (upper > 100000) {
        throw const FormatException(
          'Não foi possível convergir para o tempo de oportunidade.',
        );
      }
    }
    var iterations = 0;
    while (iterations < 100) {
      final middle = (lower + upper) / 2;
      final residual =
          infiltrationM(middle, kMMinA, exponent, basicRateMMin) - targetDepthM;
      if (residual.abs() < 0.0000001) return middle;
      if (residual > 0) {
        upper = middle;
      } else {
        lower = middle;
      }
      iterations++;
    }
    return (lower + upper) / 2;
  }

  static double trapezoidalMean(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    var weighted = (values.first + values.last) / 2;
    for (var i = 1; i < values.length - 1; i++) {
      weighted += values[i];
    }
    return weighted / (values.length - 1);
  }

  static WaterBalanceResult balance({
    required List<double> profileM,
    required double requiredDepthM,
    required double appliedDepthM,
  }) {
    if (profileM.isEmpty || requiredDepthM <= 0 || appliedDepthM <= 0) {
      throw const FormatException(
        'Não há dados suficientes para fechar o balanço hídrico.',
      );
    }
    final infiltrated = trapezoidalMean(profileM);
    final useful = trapezoidalMean(
      profileM.map((depth) => min(depth, requiredDepthM)).toList(),
    );
    final percolated = trapezoidalMean(
      profileM.map((depth) => max(0.0, depth - requiredDepthM)).toList(),
    );
    final runoff = max(0.0, appliedDepthM - infiltrated);
    final deficit = max(0.0, infiltrated - appliedDepthM);
    final residualPercent = deficit / appliedDepthM * 100;
    if (residualPercent > 1) {
      throw FormatException(
        'O perfil infiltrado exige ${residualPercent.toStringAsFixed(1)}% mais água que o volume aplicado. Revise vazão e tempos.',
      );
    }
    double percent(double depth) => (depth / appliedDepthM * 100).clamp(0, 100);
    return WaterBalanceResult(
      appliedDepthM: appliedDepthM,
      meanInfiltratedDepthM: infiltrated,
      applicationEfficiency: percent(useful),
      requirementEfficiency: (useful / requiredDepthM * 100)
          .clamp(0, 100)
          .toDouble(),
      distributionEfficiency:
          (profileM.last / max(infiltrated, 0.000000001) * 100)
              .clamp(0, 100)
              .toDouble(),
      deepPercolationPercent: percent(percolated),
      runoffPercent: percent(runoff),
      residualPercent: residualPercent,
    );
  }
}
