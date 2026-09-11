import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';
import 'package:irrigasim/features/irrigation/domain/services/surface_irrigation_math.dart';

class RunFurrowSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final slopePercent = params.declividade * 100;
    final texture = _textureCoefficients(params.texturaSolo);
    final maximumFlowLps = texture.$1 / pow(slopePercent, texture.$2);
    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );
    final requiredDepthM = params.laminaRequerida / 1000;
    final opportunityMin = SurfaceIrrigationMath.solveOpportunityTimeMin(
      targetDepthM: requiredDepthM,
      kMMinA: params.k,
      exponent: params.a,
      basicRateMMin: params.vib,
    );
    final applicationTimeMin = params.tempoAvancoFinalMin + opportunityMin;
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = params.comprimento * i / 20;
      final localOpportunity = applicationTimeMin - advance.timeAt(distance);
      profile.add(
        SurfaceIrrigationMath.infiltrationM(
          localOpportunity,
          params.k,
          params.a,
          params.vib,
        ),
      );
    }
    final appliedDepthM =
        (params.vazao * applicationTimeMin * 60) /
        (params.comprimento * params.larguraOuEspacamento) /
        1000;
    final balance = SurfaceIrrigationMath.balance(
      profileM: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
    );
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final exceedsFlow = params.vazao > maximumFlowLps;

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
      alertaVazaoExcedida: exceedsFlow
          ? 'A vazão adotada ultrapassa o limite não erosivo para ${params.texturaSolo.displayName.toLowerCase()}.'
          : null,
      resumoTextual:
          'O tempo de aplicação foi calculado como avanço + oportunidade. '
          'A vazão máxima segue o critério por textura do material técnico.',
      metricas: {
        'Vazão por sulco': params.vazao,
        'Vazão máxima não erosiva': maximumFlowLps,
        'Tempo de avanço': params.tempoAvancoFinalMin,
        'Tempo de oportunidade': opportunityMin,
        'Tempo de aplicação calculado': applicationTimeMin,
        'Expoente da curva de avanço': advance.exponent,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': balance.distributionEfficiency,
        'Resíduo do balanço': balance.residualPercent,
        'Declividade longitudinal': params.declividade,
      },
      unidadesMetricas: const {
        'Vazão por sulco': 'L/s',
        'Vazão máxima não erosiva': 'L/s',
        'Tempo de avanço': 'min',
        'Tempo de oportunidade': 'min',
        'Tempo de aplicação calculado': 'min',
        'Expoente da curva de avanço': '',
        'Lâmina aplicada': 'mm',
        'Lâmina média infiltrada': 'mm',
        'Eficiência de distribuição': '%',
        'Resíduo do balanço': '%',
        'Declividade longitudinal': 'm/m',
      },
    );
  }

  void _validate(IrrigationParameters params) {
    if (params.comprimento <= 0 ||
        params.larguraOuEspacamento <= 0 ||
        params.vazao <= 0 ||
        params.declividade <= 0 ||
        params.laminaRequerida <= 0) {
      throw const FormatException(
        'Revise geometria, declividade, vazão e lâmina requerida.',
      );
    }
    if (params.declividade < 0.0002 || params.declividade > 0.01) {
      throw const FormatException(
        'Para sulcos comuns, a declividade deve ficar entre 0,02% e 1,0%.',
      );
    }
  }

  (double, double) _textureCoefficients(TexturaSolo texture) =>
      switch (texture) {
        TexturaSolo.muitoFina => (0.892, 0.937),
        TexturaSolo.fina => (0.988, 0.550),
        TexturaSolo.media => (0.613, 0.733),
        TexturaSolo.grossa => (0.644, 0.704),
        TexturaSolo.muitoGrossa => (0.665, 0.548),
      };
}
