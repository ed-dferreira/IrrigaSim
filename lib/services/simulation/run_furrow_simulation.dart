import 'dart:math';

import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';
import 'package:irrigasim/features/irrigation/services/simulation/performance_indicators.dart';
import 'package:irrigasim/features/irrigation/services/simulation/surface_irrigation_math.dart';

class RunFurrowSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final slopePercent = params.declividade * 100;
    final maximumFlowLps = 0.631 / slopePercent;
    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );
    final requiredDepthM = params.laminaRequerida / 1000;
    final opportunityMin = params.tempoAplicacao;
    final applicationTimeMin = params.tempoAvancoFinalMin + opportunityMin;
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = params.comprimento * i / 20;
      final advanceTime = i == 20
          ? params.tempoAvancoFinalMin
          : advance.timeAt(distance);
      final localOpportunity = applicationTimeMin - advanceTime;
      profile.add(params.k / 1000 * pow(localOpportunity, params.a));
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
    final initialDepthM = profile.first;
    final applicationEfficiency = requiredDepthM / appliedDepthM * 100;
    final distributionEfficiency =
        requiredDepthM / ((initialDepthM + requiredDepthM) / 2) * 100;
    final runoffPercent =
        (100 - applicationEfficiency - balance.deepPercolationPercent)
            .clamp(0, 100)
            .toDouble();
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final exceedsFlow = params.vazao > maximumFlowLps;

    return SimulationResult(
      eficiencia: applicationEfficiency,
      eficienciaRequerimento: balance.requirementEfficiency,
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: balance.meanInfiltratedDepthM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: params.tempoAvancoFinalMin,
      perdaPercolacao: balance.deepPercolationPercent,
      perdaEscoamento: runoffPercent,
      curvaAvanco: advance.points,
      perfilLongitudinal: profile,
      alertaVazaoExcedida: exceedsFlow
          ? 'A vazão adotada ultrapassa o limite não erosivo para a declividade informada.'
          : null,
      resumoTextual:
          'Cálculo conforme a planilha de referência: Ti = Ta + To, '
          'infiltração acumulada = aI·To^n e qmáx = 0,631/S0.',
      metricas: {
        'Vazão por sulco': params.vazao,
        'Vazão máxima não erosiva': maximumFlowLps,
        'Tempo de avanço': params.tempoAvancoFinalMin,
        'Tempo de oportunidade': opportunityMin,
        'Tempo de aplicação calculado': applicationTimeMin,
        'Expoente da curva de avanço': advance.exponent,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': distributionEfficiency,
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
}
