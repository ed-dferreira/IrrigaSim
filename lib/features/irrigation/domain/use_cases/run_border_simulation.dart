import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';
import 'package:irrigasim/features/irrigation/domain/services/surface_irrigation_math.dart';

class RunBorderSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );
    final qMaxM3MinM = 0.01059 * pow(params.declividade, -0.75);
    final qMaxLpsM = qMaxM3MinM * 1000 / 60;
    final qMinM3MinM =
        0.000357 *
        params.comprimento *
        sqrt(params.declividade) /
        params.manningN;
    final qMinLpsM = qMinM3MinM * 1000 / 60;
    final requiredDepthM = params.laminaRequerida / 1000;
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final fraction = i / 20;
      final distance = params.comprimento * fraction;
      final recession =
          params.instanteRecessaoInicioMin +
          (params.instanteRecessaoFinalMin - params.instanteRecessaoInicioMin) *
              fraction;
      final opportunity = recession - advance.timeAt(distance);
      if (opportunity <= 0) {
        throw const FormatException(
          'A recessão deve ocorrer depois da passagem da frente de avanço em toda a faixa.',
        );
      }
      profile.add(
        SurfaceIrrigationMath.infiltrationM(
          opportunity,
          params.k,
          params.a,
          params.vib,
        ),
      );
    }
    final appliedDepthM =
        params.vazao * params.tempoAplicacao * 60 / params.comprimento / 1000;
    final balance = SurfaceIrrigationMath.balance(
      profileM: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
    );
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final flowWarning = params.vazao > qMaxLpsM
        ? 'A vazão unitária excede o limite não erosivo.'
        : params.vazao < qMinLpsM
        ? 'A vazão unitária é inferior ao limite mínimo de avanço.'
        : params.declividadeTransversal > 0.001
        ? 'A declividade transversal está acima de 0,1%; revise o nivelamento da faixa.'
        : null;

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
      alertaVazaoExcedida: flowWarning,
      resumoTextual:
          'O tempo de oportunidade foi obtido pela diferença entre recessão e avanço em cada posição. '
          'O perfil foi integrado pela regra trapezoidal.',
      metricas: {
        'Vazão unitária adotada': params.vazao,
        'Vazão unitária mínima': qMinLpsM,
        'Vazão unitária máxima': qMaxLpsM,
        'Vazão total da faixa': params.vazao * params.larguraOuEspacamento,
        'Tempo de avanço': params.tempoAvancoFinalMin,
        'Instante de recessão no início': params.instanteRecessaoInicioMin,
        'Instante de recessão no final': params.instanteRecessaoFinalMin,
        'Tempo de aplicação': params.tempoAplicacao,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': balance.distributionEfficiency,
        'Resíduo do balanço': balance.residualPercent,
      },
      unidadesMetricas: const {
        'Vazão unitária adotada': 'L/s/m',
        'Vazão unitária mínima': 'L/s/m',
        'Vazão unitária máxima': 'L/s/m',
        'Vazão total da faixa': 'L/s',
        'Tempo de avanço': 'min',
        'Instante de recessão no início': 'min',
        'Instante de recessão no final': 'min',
        'Tempo de aplicação': 'min',
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
        params.tempoAplicacao <= 0 ||
        params.manningN <= 0) {
      throw const FormatException(
        'Revise geometria, vazão, tempo e rugosidade da faixa.',
      );
    }
    if (params.declividade < 0.002 || params.declividade > 0.06) {
      throw const FormatException(
        'Para faixas, a declividade longitudinal deve ficar entre 0,2% e 6%.',
      );
    }
    if (params.instanteRecessaoFinalMin <= params.instanteRecessaoInicioMin) {
      throw const FormatException(
        'A recessão final deve ocorrer depois da recessão inicial.',
      );
    }
  }
}
