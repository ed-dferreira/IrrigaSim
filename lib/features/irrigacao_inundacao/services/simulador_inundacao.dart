import 'dart:math';

import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

import 'package:irrigasim/shared/irrigacao/services/performance_indicators.dart';
import 'package:irrigasim/shared/irrigacao/services/surface_irrigation_math.dart';

import 'nucleo_referencia_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';

/// Inundação intermitente pela referência da Aula 8.
///
/// Semântica de vazão: [IrrigationParameters.vazao] é a vazão **total** em
/// L/s. A hidráulica é resolvida por unidade de largura
/// (Q0 = vazão total · 60/1000 / largura, em m³/(min·m)) e as grandezas
/// totais voltam multiplicadas pela largura do tabuleiro.
class SimuladorInundacao {
  /// Vmax adotado na aula, m/min.
  static const double _vmaxMMin = 8.0;

  /// Passo da grade de perfil em metros: L = 200 m gera 41 pontos (G7).
  static const double _passoPerfilM = 5.0;

  SimulationResult call(IrrigationParameters params) {
    _validar(params);
    final comprimentoM = params.comprimento;
    final larguraM = params.larguraOuEspacamento;
    final areaM2 = comprimentoM * larguraM;
    final laminaRequeridaM = params.laminaRequerida / 1000;
    final q0M3MinM = params.vazao * 60 / 1000 / larguraM;
    final q0MaxM3MinM = vazaoNaoErosivaMaxima(_vmaxMMin, params.manningN, comprimentoM);
    final q0MaxLpsTotal = q0MaxM3MinM * larguraM * 1000 / 60;
    final solo = Infiltracao(params.k, params.a, params.vib);
    final dim = _dimensionar(
      solo,
      comprimentoM: comprimentoM,
      n: params.manningN,
      irn: laminaRequeridaM,
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
      comprimentoM,
    );
    final curvaAvancada = AdvanceCurve(
      coefficient: taMin / pow(comprimentoM, 1 / r),
      exponent: 1 / r,
      points: const [],
    );
    final segmentos = max(1, (comprimentoM / _passoPerfilM).ceil());
    final iEntrada = solo.acumulada(taMin);
    final perfil = <double>[];
    final curvaAvanco = <PontoGrafico>[];
    for (var i = 0; i <= segmentos; i++) {
      final distancia = comprimentoM * i / segmentos;
      final tx = curvaAvancada.timeAt(distancia);
      perfil.add(laminaEntrada - iEntrada + solo.acumulada(taMin - tx));
      curvaAvanco.add(PontoGrafico(tx, distancia));
    }

    final laminaMediaM = _mediaTrapezoidal(perfil);
    final appliedDepthM = q0M3MinM * tiMin / comprimentoM;
    final appliedVolumeM3 = q0M3MinM * tiMin * larguraM;
    // Ea = 100 IRN L/(Q0 ti), em porcentagem.
    final eficienciaAplicacao = dim.eficienciaPercent;
    final perdaPercolacaoPercent =
        ((laminaMediaM - laminaRequeridaM) / appliedDepthM) * 100;
    final escoamentoPercent = 100 - eficienciaAplicacao - perdaPercolacaoPercent;
    final adjustedRunoff = escoamentoPercent < 0 ? 0.0 : escoamentoPercent;
    final adjustedPercolation = 100 - eficienciaAplicacao - adjustedRunoff;
    final cuc = PerformanceIndicators.calcularCuc(perfil).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(perfil).clamp(0, 100);
    final alertaVazao = params.vazao > q0MaxLpsTotal
        ? 'A vazão total excede a vazão não erosiva total (Q0max × largura).'
        : null;

    return SimulationResult(
      eficiencia: eficienciaAplicacao,
      eficienciaRequerimento: (perfil.last / laminaRequeridaM * 100)
          .clamp(0, 100)
          .toDouble(),
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: laminaMediaM,
      laminaRequerida: laminaRequeridaM,
      tempoAvanco: taMin,
      perdaPercolacao: adjustedPercolation,
      perdaEscoamento: adjustedRunoff,
      curvaAvanco: curvaAvanco,
      perfilLongitudinal: perfil,
      alertaVazaoExcedida: alertaVazao,
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
        'Balanço - Aproveitado': eficienciaAplicacao,
        'Balanço - Percolação': adjustedPercolation,
        'Balanço - Escoamento': adjustedRunoff,
        'Lâmina útil': eficienciaAplicacao / 100 * appliedDepthM * 1000,
        'Lâmina percolada': adjustedPercolation / 100 * appliedDepthM * 1000,
        'Lâmina escoada': adjustedRunoff / 100 * appliedDepthM * 1000,
        'Déficit de lâmina': max(
          0.0,
          laminaRequeridaM * 1000 -
              eficienciaAplicacao / 100 * appliedDepthM * 1000,
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
  ResultadoDimensionamento _dimensionar(
    Infiltracao solo, {
    required double comprimentoM,
    required double n,
    required double irn,
    required double q0M3MinM,
    double rInicial = 0.7,
  }) {
    try {
      return dimensionar(
        solo,
        l: comprimentoM,
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

  double _mediaTrapezoidal(List<double> valores) {
    if (valores.isEmpty) return 0;
    if (valores.length == 1) return valores.first;
    var weighted = (valores.first + valores.last) / 2;
    for (var i = 1; i < valores.length - 1; i++) {
      weighted += valores[i];
    }
    return weighted / (valores.length - 1);
  }

  void _validar(IrrigationParameters params) {
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
