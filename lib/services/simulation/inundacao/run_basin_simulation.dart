import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import '../performance_indicators.dart';
import '../surface_irrigation_math.dart';

class RunBasinSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    const velocityMaxMMin = 8.0;
    final lengthM = params.comprimento;
    final widthM = params.larguraOuEspacamento;
    final areaM2 = lengthM * widthM;
    final flowM3Min = params.vazao * 60 / 1000;
    final requiredDepthM = params.laminaRequerida / 1000;
    final a0 = pow(
      (pow(flowM3Min, 2) * pow(params.manningN, 2) * lengthM) / 3600,
      3.0 / 13,
    ).toDouble();
    final y0 = pow(
      (pow(flowM3Min, 2) * pow(params.manningN, 2) * lengthM) / 3600,
      0.23,
    ).toDouble();
    final qMaxM3MinM = pow(
      (pow(velocityMaxMMin, 3.3) * pow(params.manningN, 2) * lengthM) / 3600,
      3 / 7,
    ).toDouble();
    final qMaxLpsM = qMaxM3MinM * 1000 / 60;
    final advance = _solveAdvance(
      flowM3Min: flowM3Min,
      lengthM: lengthM,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
      initialR: params.sigmaZ,
      y0: a0,
    );
    final taTotal = advance.timeAt(lengthM);
    final r = advance.exponent;
    final opportunityMin =
        ((requiredDepthM * lengthM - 0.8 * y0 * lengthM) / flowM3Min) +
        taTotal;
    final irrigationTimeMin = opportunityMin;
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = lengthM * i / 20;
      final advanceTime = distance == 0 ? 0.0 : advance.timeAt(distance);
      profile.add(
        params.k * pow(advanceTime, params.a) +
            params.vib * advanceTime +
            0.8 * y0 +
            flowM3Min * (irrigationTimeMin - advanceTime) / lengthM,
      );
    }
    final infiltratedDepthM = _trapezoidalMean(profile);
    final appliedVolumeM3 = flowM3Min * irrigationTimeMin;
    final requiredVolumeM3 = requiredDepthM * lengthM;
    final infiltratedVolumeM3 = infiltratedDepthM * lengthM;
    final applicationEfficiency =
        (requiredVolumeM3 / appliedVolumeM3) * 100;
    final deepPercolationPercent =
        ((infiltratedVolumeM3 - requiredVolumeM3) / appliedVolumeM3) * 100;
    final runoffPercent = 100 - applicationEfficiency - deepPercolationPercent;
    final adjustedRunoff = runoffPercent < 0 ? 0.0 : runoffPercent;
    final adjustedPercolation = 100 - applicationEfficiency - adjustedRunoff;
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
      tempoAvanco: taTotal,
      perdaPercolacao: adjustedPercolation,
      perdaEscoamento: adjustedRunoff,
      curvaAvanco: [
        for (var i = 0; i <= 20; i++)
          PontoGrafico(
            advance.timeAt(lengthM * i / 20),
            lengthM * i / 20,
          ),
      ],
      perfilLongitudinal: profile,
      alertaVazaoExcedida: flowWarning,
      resumoTextual:
          'Cálculo conforme a planilha de referência: inundação intermitente com y0 de Manning.',
      metricas: {
        'Área do tabuleiro': areaM2,
        'Vazão total': params.vazao,
        'Vazão total máxima': qMaxLpsM,
        'Tempo de oportunidade': irrigationTimeMin,
        'Tempo de avanço': taTotal,
        'Fim da depleção': irrigationTimeMin,
        'Tempo de irrigação': irrigationTimeMin,
        'Profundidade normal y0': y0 * 1000,
        'Expoente do avanço': r,
        'Volume infiltrado': infiltratedDepthM * areaM2,
        'Volume aplicado': flowM3Min * irrigationTimeMin,
        'Lâmina aplicada':
            (flowM3Min * irrigationTimeMin / areaM2) * 1000,
        'Lâmina média infiltrada': infiltratedDepthM * 1000,
        'Balanço - Aproveitado': applicationEfficiency,
        'Balanço - Percolação': adjustedPercolation,
        'Balanço - Escoamento': adjustedRunoff,
        'Lâmina útil':
            applicationEfficiency / 100 *
            (flowM3Min * irrigationTimeMin / areaM2) *
            1000,
        'Lâmina percolada':
            adjustedPercolation / 100 *
            (flowM3Min * irrigationTimeMin / areaM2) *
            1000,
        'Lâmina escoada':
            adjustedRunoff / 100 *
            (flowM3Min * irrigationTimeMin / areaM2) *
            1000,
        'Déficit de lâmina':
            max(
              0.0,
              requiredDepthM * 1000 -
                  applicationEfficiency / 100 *
                      (flowM3Min * irrigationTimeMin / areaM2) *
                      1000,
            ),
      },
      unidadesMetricas: const {
        'Área do tabuleiro': 'm²',
        'Vazão total': 'L/s',
        'Vazão total máxima': 'L/s',
        'Tempo de oportunidade': 'min',
        'Tempo de avanço': 'min',
        'Fim da depleção': 'min',
        'Tempo de irrigação': 'min',
        'Profundidade normal y0': 'mm',
        'Expoente do avanço': '',
        'Volume infiltrado': 'm³',
        'Volume aplicado': 'm³',
        'Lâmina aplicada': 'mm',
        'Lâmina média infiltrada': 'mm',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
      },
    );
  }

  AdvanceCurve _solveAdvance({
    required double flowM3Min,
    required double lengthM,
    required double k,
    required double exponent,
    required double basicRate,
    required double initialR,
    required double y0,
  }) {
    final sigma =
        (exponent + initialR * (1 - exponent) + 1) /
        ((1 + exponent) * (1 + initialR));
    final finalAdvance = _solveAdvanceTime(
      initialTime: 5 * y0 * lengthM / flowM3Min,
      flowM3Min: flowM3Min,
      areaAtInlet: y0,
      lengthM: lengthM,
      sigma: sigma,
      k: k,
      exponent: exponent,
      basicRate: basicRate,
      r: initialR,
    );
    final midAdvance = _solveAdvanceTime(
      initialTime: 5 * y0 * (lengthM / 2) / flowM3Min,
      flowM3Min: flowM3Min,
      areaAtInlet: y0,
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
    required double areaAtInlet,
    required double lengthM,
    required double sigma,
    required double k,
    required double exponent,
    required double basicRate,
    required double r,
  }) {
    var time = initialTime;
    for (var iteration = 0; iteration < 200; iteration++) {
      final residual =
          flowM3Min * time -
          0.77 * areaAtInlet * lengthM -
          sigma * k * pow(time, exponent) * lengthM -
          basicRate * time * lengthM / (1 + r);
      final derivative =
          flowM3Min -
          sigma * exponent * k * lengthM / pow(time, 1 - exponent) -
          basicRate * lengthM / (1 + r);
      if (derivative.abs() < 1e-12) {
        final step = time * 0.5;
        time = time - step;
        continue;
      }
      var next = time - residual / derivative;
      if (next <= 0 || !next.isFinite) {
        next = time * 0.5;
      }
      if ((next - time).abs() < 0.000001) return next;
      time = next;
    }
    return time;
  }

  double _trapezoidalMean(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    var weighted = (values.first + values.last) / 2;
    for (var i = 1; i < values.length - 1; i++) {
      weighted += values[i];
    }
    return weighted / (values.length - 1);
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
