import 'dart:math';

import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';
import 'package:irrigasim/features/irrigation/services/simulation/performance_indicators.dart';
import 'package:irrigasim/features/irrigation/services/simulation/surface_irrigation_math.dart';

class RunBasinSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    const velocityMaxMMin = 8.0;
    const hydraulicP1 = 1.0;
    const hydraulicP2 = 3.3;
    final slope = params.declividade;
    final lengthM = params.comprimento;
    final widthM = params.larguraOuEspacamento;
    final areaM2 = lengthM * widthM;
    final flowM3Min = params.vazao * 60 / 1000;
    final qMaxM3MinM = pow(
      (pow(velocityMaxMMin, hydraulicP2) *
              pow(params.manningN, 2) *
              lengthM) /
          3600,
      3 / 7,
    ).toDouble();
    final qMaxLpsM = qMaxM3MinM * 1000 / 60;
    final inletAreaM2 = pow(
      (pow(flowM3Min, 2) * pow(params.manningN, 2) * lengthM) / 3600,
      3 / 13,
    ).toDouble();
    final requiredDepthM = params.laminaRequerida / 1000;
    final opportunityMin = _solveOpportunityTime(
      targetDepthM: requiredDepthM,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
    );
    final advance = _solveAdvance(
      flowM3Min: flowM3Min,
      lengthM: lengthM,
      slope: slope,
      manningN: params.manningN,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
      inletAreaM2: inletAreaM2,
      initialR: params.sigmaZ,
      hydraulicP1: hydraulicP1,
      hydraulicP2: hydraulicP2,
    );
    final depletionMin = _solveDepletion(
      initialTimeMin: advance.timeAt(lengthM) + opportunityMin,
      advanceTimeMin: advance.timeAt(lengthM),
      flowM3Min: flowM3Min,
      lengthM: lengthM,
      slope: slope,
      manningN: params.manningN,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
    );
    final irrigationTimeMin =
        depletionMin - inletAreaM2 * lengthM / (2 * flowM3Min);
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = lengthM * i / 20;
      final advanceTime = distance == 0 ? 0.0 : advance.timeAt(distance);
      final recessionTime =
          depletionMin +
          (advance.timeAt(lengthM) + opportunityMin - depletionMin) *
              distance /
              lengthM;
      profile.add(
        SurfaceIrrigationMath.infiltrationM(
          recessionTime - advanceTime,
          params.k,
          params.a,
          params.vib,
        ),
      );
    }
    final infiltratedDepthM = SurfaceIrrigationMath.trapezoidalMean(profile);
    final applicationEfficiency =
        requiredDepthM * lengthM / (flowM3Min * irrigationTimeMin) * 100;
    final deepPercolationPercent =
        ((infiltratedDepthM - requiredDepthM) *
                lengthM /
                (flowM3Min * irrigationTimeMin) *
                100)
            .clamp(0, 100)
            .toDouble();
    final runoffPercent = (100 - applicationEfficiency - deepPercolationPercent)
        .clamp(0, 100)
        .toDouble();
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final flowWarning = params.vazao > qMaxLpsM
        ? 'A vazão total excede o limite não erosivo para a bacia.'
        : null;

    return SimulationResult(
      eficiencia: applicationEfficiency,
      eficienciaRequerimento: (profile.last / requiredDepthM * 100)
          .clamp(0, 100)
          .toDouble(),
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: infiltratedDepthM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: advance.timeAt(lengthM),
      perdaPercolacao: deepPercolationPercent,
      perdaEscoamento: runoffPercent,
      curvaAvanco: [
        for (var i = 0; i <= 20; i++)
          PontoGrafico(
            advance.timeAt(lengthM * i / 20),
            lengthM * i / 20,
          ),
      ],
      perfilLongitudinal: profile,
      alertaVazaoExcedida: flowWarning,
      resumoTextual: 'Cálculo conforme a planilha de referência: Newton-Raphson para avanço e depleção, inundação intermitente.',
      metricas: {
        'Área do tabuleiro': areaM2,
        'Vazão total': params.vazao,
        'Vazão total máxima': qMaxLpsM,
        'Tempo de oportunidade': opportunityMin,
        'Tempo de avanço': advance.timeAt(lengthM),
        'Fim da depleção': depletionMin,
        'Tempo de irrigação': irrigationTimeMin,
        'Profundidade na entrada': inletAreaM2,
        'Expoente do avanço': advance.exponent,
        'Volume infiltrado': infiltratedDepthM * areaM2,
        'Volume aplicado': flowM3Min * irrigationTimeMin,
        'Lâmina aplicada': (flowM3Min * irrigationTimeMin / areaM2) * 1000,
        'Lâmina média infiltrada': infiltratedDepthM * 1000,
      },
      unidadesMetricas: const {
        'Área do tabuleiro': 'm²',
        'Vazão total': 'L/s',
        'Vazão total máxima': 'L/s',
        'Tempo de oportunidade': 'min',
        'Tempo de avanço': 'min',
        'Tempo de depleção': 'min',
        'Tempo de irrigação': 'min',
        'Profundidade na entrada': 'm',
        'Expoente do avanço': '',
        'Lâmina média infiltrada': 'mm',
        'Eficiência de distribuição': '%',
        'Resíduo do balanço': '%',
      },
    );
  }

  AdvanceCurve _solveAdvance({
    required double flowM3Min,
    required double lengthM,
    required double slope,
    required double manningN,
    required double k,
    required double exponent,
    required double basicRate,
    required double inletAreaM2,
    required double initialR,
    required double hydraulicP1,
    required double hydraulicP2,
  }) {
    final sigma =
        (exponent + initialR * (1 - exponent) + 1) /
        ((1 + exponent) * (1 + initialR));
    final finalAdvance = _solveAdvanceTime(
      initialTime: 5 * inletAreaM2 * lengthM / flowM3Min,
      flowM3Min: flowM3Min,
      inletAreaM2: inletAreaM2,
      lengthM: lengthM,
      sigma: sigma,
      k: k,
      exponent: exponent,
      basicRate: basicRate,
      r: initialR,
    );
    final midAdvance = _solveAdvanceTime(
      initialTime: 5 * inletAreaM2 * (lengthM / 2) / flowM3Min,
      flowM3Min: flowM3Min,
      inletAreaM2: inletAreaM2,
      lengthM: lengthM / 2,
      sigma: sigma,
      k: k,
      exponent: exponent,
      basicRate: basicRate,
      r: initialR,
    );
    final r = log(2) / (log(finalAdvance) - log(midAdvance));
    final coefficient = finalAdvance / pow(lengthM, 1 / r);
    return AdvanceCurve(
      coefficient: coefficient,
      exponent: 1 / r,
      points: const [],
    );
  }

  double _solveAdvanceTime({
    required double initialTime,
    required double flowM3Min,
    required double inletAreaM2,
    required double lengthM,
    required double sigma,
    required double k,
    required double exponent,
    required double basicRate,
    required double r,
  }) {
    var time = initialTime;
    for (var iteration = 0; iteration < 100; iteration++) {
      final residual =
          flowM3Min * time -
          0.77 * inletAreaM2 * lengthM -
          sigma * k * pow(time, exponent) * lengthM -
          basicRate * time * lengthM / (1 + r);
      final derivative =
          flowM3Min -
          sigma * exponent * k * lengthM / pow(time, 1 - exponent) -
          basicRate * lengthM / (1 + r);
      final next = time - residual / derivative;
      if (next <= 0 || !next.isFinite) {
        throw const FormatException(
          'Não foi possível convergir o tempo de avanço.',
        );
      }
      if ((next - time).abs() < 0.000001) return next;
      time = next;
    }
    return time;
  }

  double _solveOpportunityTime({
    required double targetDepthM,
    required double k,
    required double exponent,
    required double basicRate,
  }) {
    var time = 100.0;
    for (var iteration = 0; iteration < 2; iteration++) {
      time -=
          (k * pow(time, exponent) + basicRate * time - targetDepthM) /
          (k * exponent * pow(time, exponent - 1) + basicRate);
    }
    return time;
  }

  double _solveDepletion({
    required double initialTimeMin,
    required double advanceTimeMin,
    required double flowM3Min,
    required double lengthM,
    required double slope,
    required double manningN,
    required double k,
    required double exponent,
    required double basicRate,
  }) {
    if (slope < 1e-10) return initialTimeMin;
    var time = initialTimeMin;
    for (var iteration = 0; iteration < 4; iteration++) {
      final averageRate =
          0.5 *
              exponent *
              k *
              (pow(time, exponent - 1) +
                  pow(time - advanceTimeMin, exponent - 1)) +
          basicRate;
      final storage =
          pow(
            ((flowM3Min - averageRate * lengthM) *
                manningN /
                (60 * sqrt(slope))),
            0.6,
          ).toDouble() /
          lengthM;
      final next =
          initialTimeMin -
          0.095 *
              pow(manningN, 0.47565) *
              pow(storage, 0.2072) *
              pow(lengthM, 0.6829) /
              (pow(averageRate, 0.5243) * pow(slope, 0.2378));
      time = next;
    }
    return time;
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
    if (params.declividade >= 0.02) {
      throw const FormatException(
        'A inundação exige declividade longitudinal inferior a 2%.',
      );
    }
  }
}
