import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'performance_indicators.dart';
import 'surface_irrigation_math.dart';

class RunBorderSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    const velocityMaxMMin = 8.0;
    const hydraulicP1 = 1.0;
    const hydraulicP2 = 3.3;
    final slope = params.declividade;
    final flowM3MinM = params.vazao * 60 / 1000;
    final qMaxM3MinM = pow(
      pow(velocityMaxMMin, hydraulicP2) *
          pow(params.manningN, 2) /
          (3600 * slope * hydraulicP1),
      1 / (hydraulicP2 - 2),
    ).toDouble();
    final qMaxLpsM = qMaxM3MinM * 1000 / 60;
    final opportunityMin = _solveSheetOpportunityTime(
      targetDepthM: params.laminaRequerida / 1000,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
    );
    final advance = _solveAdvance(
      flowM3MinM: flowM3MinM,
      lengthM: params.comprimento,
      slope: slope,
      manningN: params.manningN,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
      initialR: params.sigmaZ,
      hydraulicP1: hydraulicP1,
      hydraulicP2: hydraulicP2,
    );
    final inletDepthM = pow(
      (pow(flowM3MinM, 2) * pow(params.manningN, 2)) / (3600 * slope),
      0.3,
    ).toDouble();
    final depletionMin = _solveDepletion(
      initialTimeMin: advance.timeAt(params.comprimento) + opportunityMin,
      advanceTimeMin: advance.timeAt(params.comprimento),
      flowM3MinM: flowM3MinM,
      lengthM: params.comprimento,
      slope: slope,
      manningN: params.manningN,
      k: params.k,
      exponent: params.a,
      basicRate: params.vib,
    );
    final irrigationTimeMin =
        depletionMin - inletDepthM * params.comprimento / (2 * flowM3MinM);
    final profile = <double>[];
    for (var i = 0; i <= 10; i++) {
      final distance = params.comprimento * i / 10;
      final advanceTime = distance == 0 ? 0.0 : advance.timeAt(distance);
      final recessionTime =
          depletionMin +
          (advance.timeAt(params.comprimento) + opportunityMin - depletionMin) *
              distance /
              params.comprimento;
      profile.add(
        SurfaceIrrigationMath.infiltrationM(
          recessionTime - advanceTime,
          params.k,
          params.a,
          params.vib,
        ),
      );
    }
    final requiredDepthM = params.laminaRequerida / 1000;
    final infiltratedDepthM = SurfaceIrrigationMath.trapezoidalMean(profile);
    final applicationEfficiency =
        requiredDepthM *
        params.comprimento /
        (flowM3MinM * irrigationTimeMin) *
        100;
    final deepPercolationPercent =
        ((infiltratedDepthM - requiredDepthM) *
                params.comprimento /
                (flowM3MinM * irrigationTimeMin) *
                100)
            .clamp(0, 100)
            .toDouble();
    final runoffPercent = (100 - applicationEfficiency - deepPercolationPercent)
        .clamp(0, 100)
        .toDouble();
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final flowWarning = params.vazao > qMaxLpsM
        ? 'A vazão unitária excede o limite não erosivo.'
        : params.declividadeTransversal > 0.001
        ? 'A declividade transversal está acima de 0,1%; revise o nivelamento da faixa.'
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
      tempoAvanco: advance.timeAt(params.comprimento),
      perdaPercolacao: deepPercolationPercent,
      perdaEscoamento: runoffPercent,
      curvaAvanco: [
        for (var i = 0; i <= 20; i++)
          PontoGrafico(
            advance.timeAt(params.comprimento * i / 20),
            params.comprimento * i / 20,
          ),
      ],
      perfilLongitudinal: profile,
      alertaVazaoExcedida: flowWarning,
      resumoTextual: 'Cálculo conforme a planilha de referência: Newton-Raphson para avanço e depleção.',
      metricas: {
        'Vazão unitária adotada': params.vazao,
        'Vazão unitária máxima': qMaxLpsM,
        'Tempo de oportunidade': opportunityMin,
        'Tempo de avanço': advance.timeAt(params.comprimento),
        'Tempo de depleção': depletionMin,
        'Tempo de irrigação': irrigationTimeMin,
        'Profundidade na entrada': inletDepthM,
        'Expoente do avanço': advance.exponent,
        'Vazão total da faixa': params.vazao * params.larguraOuEspacamento,
        'Lâmina média infiltrada': infiltratedDepthM * 1000,
        'Balanço - Aproveitado': applicationEfficiency,
        'Balanço - Percolação': deepPercolationPercent,
        'Balanço - Escoamento': runoffPercent,
        'Lâmina aplicada':
            (flowM3MinM * irrigationTimeMin / params.comprimento) * 1000,
        'Lâmina útil':
            applicationEfficiency / 100 *
            (flowM3MinM * irrigationTimeMin / params.comprimento) *
            1000,
        'Lâmina percolada':
            deepPercolationPercent / 100 *
            (flowM3MinM * irrigationTimeMin / params.comprimento) *
            1000,
        'Lâmina escoada':
            runoffPercent / 100 *
            (flowM3MinM * irrigationTimeMin / params.comprimento) *
            1000,
        'Déficit de lâmina':
            max(
              0.0,
              requiredDepthM * 1000 -
                  applicationEfficiency / 100 *
                      (flowM3MinM * irrigationTimeMin / params.comprimento) *
                      1000,
            ),
      },
      unidadesMetricas: const {
        'Vazão unitária adotada': 'L/s/m',
        'Vazão unitária máxima': 'L/s/m',
        'Tempo de oportunidade': 'min',
        'Tempo de avanço': 'min',
        'Tempo de depleção': 'min',
        'Tempo de irrigação': 'min',
        'Profundidade na entrada': 'm',
        'Expoente do avanço': '',
        'Vazão total da faixa': 'L/s',
        'Lâmina média infiltrada': 'mm',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina aplicada': 'mm',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
      },
    );
  }

  AdvanceCurve _solveAdvance({
    required double flowM3MinM,
    required double lengthM,
    required double slope,
    required double manningN,
    required double k,
    required double exponent,
    required double basicRate,
    required double initialR,
    required double hydraulicP1,
    required double hydraulicP2,
  }) {
    final areaAtInlet = pow(
      (pow(flowM3MinM, 2) * pow(manningN, 2)) / (slope * hydraulicP1 * 3600),
      1 / hydraulicP2,
    ).toDouble();
    final sigma =
        (exponent + initialR * (1 - exponent) + 1) /
        ((1 + exponent) * (1 + initialR));
    final finalAdvance = _solveAdvanceTime(
      initialTime: 5 * areaAtInlet * lengthM / flowM3MinM,
      flowM3MinM: flowM3MinM,
      areaAtInlet: areaAtInlet,
      lengthM: lengthM,
      sigma: sigma,
      k: k,
      exponent: exponent,
      basicRate: basicRate,
      r: initialR,
    );
    final midAdvance = _solveAdvanceTime(
      initialTime: 5 * areaAtInlet * (lengthM / 2) / flowM3MinM,
      flowM3MinM: flowM3MinM,
      areaAtInlet: areaAtInlet,
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
    required double flowM3MinM,
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
          flowM3MinM * time -
          0.77 * areaAtInlet * lengthM -
          sigma * k * pow(time, exponent) * lengthM -
          basicRate * time * lengthM / (1 + r);
      final derivative =
          flowM3MinM -
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

  double _solveSheetOpportunityTime({
    required double targetDepthM,
    required double k,
    required double exponent,
    required double basicRate,
  }) {
    // The source worksheet starts at 100 min and applies two Newton steps.
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
    required double flowM3MinM,
    required double lengthM,
    required double slope,
    required double manningN,
    required double k,
    required double exponent,
    required double basicRate,
  }) {
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
            ((flowM3MinM - averageRate * lengthM) *
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
        params.manningN <= 0 ||
        params.k <= 0 ||
        params.a <= 0 ||
        params.a >= 1 ||
        params.vib < 0) {
      throw const FormatException(
        'Revise geometria, vazão e infiltração da faixa.',
      );
    }
    if (params.declividade <= 0) {
      throw const FormatException(
        'A declividade longitudinal deve ser positiva.',
      );
    }
  }
}
