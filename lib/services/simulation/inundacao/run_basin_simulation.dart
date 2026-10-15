import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';

import '../performance_indicators.dart';
import '../surface_irrigation_math.dart';
import 'basin_reference_math.dart';

/// Inundação intermitente pela referência da Aula 8.
///
/// Semântica de vazão: [IrrigationParameters.vazao] é a vazão **total** em
/// L/s. A hidráulica é resolvida por unidade de largura
/// (Q0 = vazão total · 60/1000 / largura, em m³/(min·m)) e as grandezas
/// totais voltam multiplicadas pela largura do tabuleiro.
class RunBasinSimulation {
  /// Vmax adotado na aula, m/min.
  static const double _vmaxMMin = 8.0;

  /// Passo da grade de perfil em metros: L = 200 m gera 41 pontos (G7).
  static const double _passoPerfilM = 5.0;

  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final lengthM = params.comprimento;
    final widthM = params.larguraOuEspacamento;
    final areaM2 = lengthM * widthM;
    final requiredDepthM = params.laminaRequerida / 1000;
    final q0M3MinM = params.vazao * 60 / 1000 / widthM;
    final q0MaxM3MinM = vazaoMaxima(_vmaxMMin, params.manningN, lengthM);
    final q0MaxLpsTotal = q0MaxM3MinM * widthM * 1000 / 60;
    final solo = Infiltracao(params.k, params.a, params.vib);
    final dim = _dimensionar(
      solo,
      lengthM: lengthM,
      n: params.manningN,
      irn: requiredDepthM,
      q0M3MinM: q0M3MinM,
      rInicial: params.projetoInundacao?.rInicial ?? 0.7,
    );
    final taMin = dim.taMin;
    final tiMin = dim.tiMin;
    final y0M = dim.y0M;
    final r = dim.r;

    // Perfil: tx = ta (x/L)^(1/r) e lâmina I(ta−tx) + 0,80 y0 +
    // Q0(ti−ta)/L; em x = 0 a fórmula coincide com infiltracaoInicio (p. 47).
    final laminaEntrada = infiltracaoInicio(
      solo,
      taMin,
      tiMin,
      y0M,
      q0M3MinM,
      lengthM,
    );
    final avanco = AdvanceCurve(
      coefficient: taMin / pow(lengthM, 1 / r),
      exponent: 1 / r,
      points: const [],
    );
    final segmentos = max(1, (lengthM / _passoPerfilM).ceil());
    final iEntrada = solo.acumulada(taMin);
    final profile = <double>[];
    final curvaAvanco = <PontoGrafico>[];
    for (var i = 0; i <= segmentos; i++) {
      final distance = lengthM * i / segmentos;
      final tx = avanco.timeAt(distance);
      profile.add(laminaEntrada - iEntrada + solo.acumulada(taMin - tx));
      curvaAvanco.add(PontoGrafico(tx, distance));
    }

    final laminaMediaM = _trapezoidalMean(profile);
    final appliedDepthM = q0M3MinM * tiMin / lengthM;
    final appliedVolumeM3 = q0M3MinM * tiMin * widthM;
    // Ea = 100 IRN L/(Q0 ti), em porcentagem.
    final applicationEfficiency = dim.eficienciaPercent;
    final deepPercolationPercent =
        ((laminaMediaM - requiredDepthM) / appliedDepthM) * 100;
    final runoffPercent = 100 - applicationEfficiency - deepPercolationPercent;
    final adjustedRunoff = runoffPercent < 0 ? 0.0 : runoffPercent;
    final adjustedPercolation = 100 - applicationEfficiency - adjustedRunoff;
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final flowWarning = params.vazao > q0MaxLpsTotal
        ? 'A vazão total excede a vazão não erosiva total (Q0max × largura).'
        : null;

    return SimulationResult(
      eficiencia: applicationEfficiency,
      eficienciaRequerimento: (profile.last / requiredDepthM * 100)
          .clamp(0, 100)
          .toDouble(),
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: laminaMediaM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: taMin,
      perdaPercolacao: adjustedPercolation,
      perdaEscoamento: adjustedRunoff,
      curvaAvanco: curvaAvanco,
      perfilLongitudinal: profile,
      alertaVazaoExcedida: flowWarning,
      resumoTextual:
          'Inundação intermitente pela referência da Aula 8: hidráulica por '
          'unidade de largura (Q0 em m³/(min·m)), avanço por bisseção com '
          'expoente 3/13 e ti = max[ta,(IRN−0,80 y0)L/Q0+ta].',
      metricas: {
        'Área do tabuleiro': areaM2,
        'Vazão total': params.vazao,
        'Vazão total máxima': q0MaxLpsTotal,
        'Vazão unitária Q0': q0M3MinM,
        'Vazão unitária máxima Q0max': q0MaxM3MinM,
        'Tempo de oportunidade': tiMin,
        'Tempo de avanço': taMin,
        'Fim da depleção': tiMin,
        'Tempo de irrigação': tiMin,
        'Profundidade normal y0': y0M * 1000,
        'Expoente do avanço': r,
        'Declividade da superfície líquida S0': dim.s0,
        'Resíduo do balanço': dim.residualBalancoM3M,
        'Infiltração no início I0': laminaEntrada * 1000,
        'Volume infiltrado': laminaMediaM * areaM2,
        'Volume aplicado': appliedVolumeM3,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': laminaMediaM * 1000,
        'Balanço - Aproveitado': applicationEfficiency,
        'Balanço - Percolação': adjustedPercolation,
        'Balanço - Escoamento': adjustedRunoff,
        'Lâmina útil': applicationEfficiency / 100 * appliedDepthM * 1000,
        'Lâmina percolada': adjustedPercolation / 100 * appliedDepthM * 1000,
        'Lâmina escoada': adjustedRunoff / 100 * appliedDepthM * 1000,
        'Déficit de lâmina': max(
          0.0,
          requiredDepthM * 1000 -
              applicationEfficiency / 100 * appliedDepthM * 1000,
        ),
      },
      unidadesMetricas: const {
        'Área do tabuleiro': 'm²',
        'Vazão total': 'L/s',
        'Vazão total máxima': 'L/s',
        'Vazão unitária Q0': 'm³/(min·m)',
        'Vazão unitária máxima Q0max': 'm³/(min·m)',
        'Tempo de oportunidade': 'min',
        'Tempo de avanço': 'min',
        'Fim da depleção': 'min',
        'Tempo de irrigação': 'min',
        'Profundidade normal y0': 'mm',
        'Expoente do avanço': 'adimensional',
        'Declividade da superfície líquida S0': 'adimensional',
        'Resíduo do balanço': 'm³/m',
        'Infiltração no início I0': 'mm',
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

  /// Executa o núcleo da referência e converte erros de domínio
  /// (ArgumentError/StateError) em [FormatException] amigável.
  BasinDimensioningResult _dimensionar(
    Infiltracao solo, {
    required double lengthM,
    required double n,
    required double irn,
    required double q0M3MinM,
    double rInicial = 0.7,
  }) {
    try {
      return dimensionar(
        solo,
        l: lengthM,
        n: n,
        irn: irn,
        vmax: _vmaxMMin,
        vazao: q0M3MinM,
        rInicial: rInicial,
        exigirVazaoNaoErosiva: false,
      );
    } on ArgumentError catch (e) {
      throw FormatException('Dimensionamento da inundação: ${e.message}');
    } on StateError catch (e) {
      throw FormatException('Dimensionamento da inundação: ${e.message}');
    }
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
        params.laminaRequerida <= 0 ||
        params.manningN <= 0 ||
        params.k <= 0 ||
        !(params.a > 0 && params.a < 1)) {
      throw const FormatException(
        'Revise dimensões, vazão, lâmina requerida e curva de infiltração '
        '(0 < a < 1).',
      );
    }
    // G9: a declividade é validada também no regime permanente.
    if (params.declividade >= 0.02) {
      throw const FormatException(
        'A inundação exige declividade longitudinal inferior a 2%.',
      );
    }
  }
}
