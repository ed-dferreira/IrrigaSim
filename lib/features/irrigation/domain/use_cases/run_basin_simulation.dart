import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';
import 'package:irrigasim/features/irrigation/domain/services/surface_irrigation_math.dart';

class RunBasinSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final areaM2 = params.comprimento * params.larguraOuEspacamento;
    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );
    final requiredDepthM = params.laminaRequerida / 1000;
    final finalOpportunityMin = SurfaceIrrigationMath.solveOpportunityTimeMin(
      targetDepthM: requiredDepthM,
      kMMinA: params.k,
      exponent: params.a,
      basicRateMMin: params.vib,
    );
    final depletionEndMin = params.tempoAvancoFinalMin + finalOpportunityMin;
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = params.comprimento * i / 20;
      profile.add(
        SurfaceIrrigationMath.infiltrationM(
          depletionEndMin - advance.timeAt(distance),
          params.k,
          params.a,
          params.vib,
        ),
      );
    }
    final infiltratedDepthM = SurfaceIrrigationMath.trapezoidalMean(profile);
    final infiltrationVolumeM3 = infiltratedDepthM * areaM2;
    final durationForVolumeMin =
        infiltrationVolumeM3 / (params.vazao / 1000) / 60;
    final applicationTimeMin = max(
      params.tempoAvancoFinalMin,
      durationForVolumeMin,
    ).toDouble();
    final appliedDepthM =
        params.vazao * applicationTimeMin * 60 / areaM2 / 1000;
    final balance = SurfaceIrrigationMath.balance(
      profileM: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
    );
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final maxElevationDifferenceM = max(
      params.desnivelEquivalentLongitudinal,
      params.desnivelEquivalentTransversal,
    );

    return SimulationResult(
      eficiencia: balance.applicationEfficiency,
      eficienciaRequerimento: balance.requirementEfficiency,
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: balance.meanInfiltratedDepthM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: params.tempoAvancoFinalMin,
      perdaPercolacao: balance.deepPercolationPercent,
      perdaEscoamento: balance.runoffPercent,
      curvaAvanco: advance.points,
      perfilLongitudinal: profile,
      alertaVazaoExcedida: maxElevationDifferenceM > requiredDepthM * 2 / 3
          ? 'A diferença de nível supera 2/3 da lâmina requerida; revise o nivelamento do tabuleiro.'
          : null,
      resumoTextual: 'Modelo intermitente em uma direção, com recessão desprezível e depleção até atender a lâmina no final do tabuleiro.',
      metricas: {
        'Área do tabuleiro': areaM2,
        'Vazão total': params.vazao,
        'Tempo de avanço': params.tempoAvancoFinalMin,
        'Tempo de oportunidade no final': finalOpportunityMin,
        'Tempo de aplicação calculado': applicationTimeMin,
        'Fim da depleção': depletionEndMin,
        'Volume infiltrado': infiltrationVolumeM3,
        'Volume aplicado': appliedDepthM * areaM2,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': balance.distributionEfficiency,
        'Resíduo do balanço': balance.residualPercent,
      },
      unidadesMetricas: const {
        'Área do tabuleiro': 'm²',
        'Vazão total': 'L/s',
        'Tempo de avanço': 'min',
        'Tempo de oportunidade no final': 'min',
        'Tempo de aplicação calculado': 'min',
        'Fim da depleção': 'min',
        'Volume infiltrado': 'm³',
        'Volume aplicado': 'm³',
        'Lâmina aplicada': 'mm',
        'Lâmina média infiltrada': 'mm',
        'Eficiência de distribuição': '%',
        'Resíduo do balanço': '%',
      },
    );
  }

  void _validate(IrrigationParameters params) {
    if (params.comprimento <= 0 ||
        params.larguraOuEspacamento <= 0 ||
        params.vazao <= 0 ||
        params.laminaRequerida <= 0) {
      throw const FormatException(
        'Revise dimensões, vazão e lâmina requerida.',
      );
    }
    if (params.declividade >= 0.02 || params.declividadeTransversal >= 0.02) {
      throw const FormatException(
        'A inundação exige declividades longitudinal e transversal inferiores a 2%.',
      );
    }
  }
}

extension on IrrigationParameters {
  double get desnivelEquivalentLongitudinal => declividade * comprimento;
  double get desnivelEquivalentTransversal =>
      declividadeTransversal * larguraOuEspacamento;
}
