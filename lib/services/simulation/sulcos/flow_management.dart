import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';

/// Parâmetros da fórmula qmax = C / S0^a por textura do solo.
class ParametrosErosao {
  final double c;
  final double a;

  const ParametrosErosao({required this.c, required this.a});
}

/// Resultado do cálculo de vazão não erosiva.
class VazaoNaoErosivaResultado {
  final double qmaxLs;
  final double? qmaxSimplificadaLs;
  final double declividadePercent;
  final TexturaSolo textura;
  final String formulaUtilizada;

  const VazaoNaoErosivaResultado({
    required this.qmaxLs,
    this.qmaxSimplificadaLs,
    required this.declividadePercent,
    required this.textura,
    required this.formulaUtilizada,
  });

  Map<String, dynamic> toMap() {
    return {
      'qmax_ls': qmaxLs,
      'qmax_simplificada_ls': qmaxSimplificadaLs,
      'declividade_percent': declividadePercent,
      'textura': textura.name,
      'formula_utilizada': formulaUtilizada,
    };
  }
}

/// Resultado do cálculo de vazão reduzida.
class VazaoReduzidaResultado {
  final double vazaoReduzidaLs;
  final double? fatorAplicado;
  final String formulaUtilizada;

  const VazaoReduzidaResultado({
    required this.vazaoReduzidaLs,
    this.fatorAplicado,
    required this.formulaUtilizada,
  });

  Map<String, dynamic> toMap() {
    return {
      'vazao_reduzida_ls': vazaoReduzidaLs,
      'fator_aplicado': fatorAplicado,
      'formula_utilizada': formulaUtilizada,
    };
  }
}

/// Gerencia vazão não erosiva e redução de vazão.
///
/// Referências: §30 e §43 do documento de implementação.
class FlowManagement {
  const FlowManagement._();

  /// Tabela de parâmetros C e a por textura do solo (§30.2).
  ///
  /// Fórmula: `qmax = C / S0^a`
  /// Onde S0 é a declividade em porcentagem.
  static const Map<TexturaSolo, ParametrosErosao> _parametrosErosao = {
    TexturaSolo.muitoFina: ParametrosErosao(c: 0.892, a: 0.937),
    TexturaSolo.fina: ParametrosErosao(c: 0.988, a: 0.550),
    TexturaSolo.media: ParametrosErosao(c: 0.613, a: 0.733),
    TexturaSolo.grossa: ParametrosErosao(c: 0.644, a: 0.704),
    TexturaSolo.muitoGrossa: ParametrosErosao(c: 0.665, a: 0.548),
  };

  /// Calcula a vazão máxima não erosiva (§30).
  ///
  /// Equação: `qmax = C / S0^a`
  ///
  /// [declividadePercent] — Declividade em %
  /// [textura] — Textura do solo
  static VazaoNaoErosivaResultado calcularVazaoMaxima({
    required double declividadePercent,
    required TexturaSolo textura,
  }) {
    if (!declividadePercent.isFinite || declividadePercent <= 0) {
      throw ArgumentError('Declividade deve ser maior que zero');
    }

    final params =
        _parametrosErosao[textura] ?? const ParametrosErosao(c: 0.631, a: 0.35);

    // qmax = C / S0^a  (§30: S0 em %)
    var qmax = params.c / pow(declividadePercent, params.a);

    // Fórmula simplificada: qmax = 0.631 / S0
    final qmaxSimplificada = 0.631 / declividadePercent;
    if (!qmax.isFinite || !qmaxSimplificada.isFinite) {
      throw ArgumentError(
        'Declividade fora do domínio numérico da vazão não erosiva.',
      );
    }

    return VazaoNaoErosivaResultado(
      qmaxLs: qmax,
      qmaxSimplificadaLs: qmaxSimplificada,
      declividadePercent: declividadePercent,
      textura: textura,
      formulaUtilizada: 'qmax = C / S0^a (§30; S0 em %)',
    );
  }

  /// Calcula a vazão reduzida (§43.2).
  ///
  /// Equação: `Qr = (f0 * L * E) / 3600`
  ///
  /// Onde:
  /// - f0 = taxa de infiltração básica (mm/h)
  /// - L = comprimento do sulco (m)
  /// - E = espaçamento entre sulcos (m)
  /// - Fator 1.1 é configurável (default 1.0)
  static VazaoReduzidaResultado calcularVazaoReduzida({
    required double f0MmH,
    required double comprimentoM,
    required double espacamentoM,
    double fator11 = 1.0,
  }) {
    if (!f0MmH.isFinite || f0MmH < 0) {
      throw ArgumentError('Taxa de infiltração básica não pode ser negativa');
    }
    if (!comprimentoM.isFinite || comprimentoM <= 0) {
      throw ArgumentError('Comprimento deve ser positivo');
    }
    if (!espacamentoM.isFinite || espacamentoM <= 0) {
      throw ArgumentError('Espaçamento deve ser positivo');
    }
    if (!fator11.isFinite || fator11 < 1.0 || fator11 > 1.1) {
      throw ArgumentError('Fator deve estar entre 1.0 e 1.1');
    }

    // O fator configurável pertence somente à estimativa de Qr (§43).
    final qReduzida = (f0MmH * comprimentoM * espacamentoM * fator11) / 3600;
    if (!qReduzida.isFinite) {
      throw ArgumentError('Vazão reduzida fora do domínio numérico.');
    }

    return VazaoReduzidaResultado(
      vazaoReduzidaLs: qReduzida,
      fatorAplicado: fator11 != 1.0 ? fator11 : null,
      formulaUtilizada: fator11 != 1.0
          ? 'Qr = (f0 × L × E × $fator11) / 3600'
          : 'Qr = (f0 × L × E) / 3600 (§43.2)',
    );
  }

  /// Estima Qr pela derivada da lâmina acumulada I = k·t^a no fim da
  /// oportunidade. k está em mm/min^a e o tempo em minutos.
  static VazaoReduzidaResultado estimarVazaoReduzidaDaCurva({
    required double coeficienteAcumuladoMmMinA,
    required double expoenteAcumulado,
    required double oportunidadeFinalMin,
    required double comprimentoM,
    required double espacamentoM,
    double fator = 1.0,
  }) {
    if (!coeficienteAcumuladoMmMinA.isFinite ||
        !expoenteAcumulado.isFinite ||
        !oportunidadeFinalMin.isFinite ||
        coeficienteAcumuladoMmMinA <= 0 ||
        expoenteAcumulado <= 0 ||
        oportunidadeFinalMin <= 0) {
      throw ArgumentError(
        'Curva de infiltração e oportunidade devem ser positivas',
      );
    }
    final taxaFinalMmH =
        60 *
        coeficienteAcumuladoMmMinA *
        expoenteAcumulado *
        pow(oportunidadeFinalMin, expoenteAcumulado - 1);
    final result = calcularVazaoReduzida(
      f0MmH: taxaFinalMmH,
      comprimentoM: comprimentoM,
      espacamentoM: espacamentoM,
      fator11: fator,
    );
    return VazaoReduzidaResultado(
      vazaoReduzidaLs: result.vazaoReduzidaLs,
      fatorAplicado: result.fatorAplicado,
      formulaUtilizada: 'Qr = VI(To) × L × E / 3600; VI(To) = dI/dt',
    );
  }

  /// F24 (p.96): integra a taxa instantânea ao longo de estacas medidas,
  /// sem extrapolar a curva para além do último ponto observado.
  static VazaoReduzidaResultado estimarSomatorioEspacial({
    required List<MedicaoAvanco> estacas,
    required double comprimentoM,
    required double espacamentoM,
    required double instanteMudancaMin,
    required double coeficienteAcumuladoMmMinA,
    required double expoenteAcumulado,
  }) {
    if (estacas.length < 2 ||
        estacas.first.distanciaM != 0 ||
        estacas.first.tempoMin != 0 ||
        estacas.last.distanciaM < comprimentoM ||
        !comprimentoM.isFinite ||
        comprimentoM <= 0 ||
        !espacamentoM.isFinite ||
        espacamentoM <= 0 ||
        !instanteMudancaMin.isFinite ||
        instanteMudancaMin <= 0 ||
        !coeficienteAcumuladoMmMinA.isFinite ||
        coeficienteAcumuladoMmMinA <= 0 ||
        !expoenteAcumulado.isFinite ||
        expoenteAcumulado <= 0) {
      throw const FormatException(
        'Somatório espacial exige estacas medidas de 0 m ao comprimento total e parâmetros positivos.',
      );
    }
    double? distanciaAnterior;
    double? tempoAnterior;
    var totalLMin = 0.0;
    for (final ponto in estacas) {
      if (!ponto.distanciaM.isFinite ||
          !ponto.tempoMin.isFinite ||
          ponto.distanciaM < 0 ||
          ponto.tempoMin < 0 ||
          (distanciaAnterior != null &&
              (ponto.distanciaM <= distanciaAnterior ||
                  ponto.tempoMin <= tempoAnterior!))) {
        throw const FormatException(
          'Estacas do somatório espacial devem crescer estritamente em distância e tempo.',
        );
      }
      if (ponto.distanciaM > comprimentoM) break;
      final oportunidade = instanteMudancaMin - ponto.tempoMin;
      if (oportunidade <= 0) {
        throw const FormatException(
          'Somatório espacial indefinido: a troca ocorre antes ou no instante do avanço em uma estaca.',
        );
      }
      final taxaLMinM =
          coeficienteAcumuladoMmMinA *
          expoenteAcumulado *
          pow(oportunidade, expoenteAcumulado - 1) *
          espacamentoM;
      if (!taxaLMinM.isFinite) {
        throw const FormatException(
          'Taxa do somatório espacial fora do domínio numérico.',
        );
      }
      if (distanciaAnterior != null) {
        final oportunidadeAnterior = instanteMudancaMin - tempoAnterior!;
        final taxaAnterior =
            coeficienteAcumuladoMmMinA *
            expoenteAcumulado *
            pow(oportunidadeAnterior, expoenteAcumulado - 1) *
            espacamentoM;
        totalLMin +=
            (taxaAnterior + taxaLMinM) /
            2 *
            (ponto.distanciaM - distanciaAnterior);
      }
      distanciaAnterior = ponto.distanciaM;
      tempoAnterior = ponto.tempoMin;
    }
    if (distanciaAnterior != comprimentoM) {
      throw const FormatException(
        'Somatório espacial exige estaca exatamente no comprimento escolhido.',
      );
    }
    if (!totalLMin.isFinite || totalLMin <= 0) {
      throw const FormatException(
        'Somatório espacial fora do domínio numérico.',
      );
    }
    return VazaoReduzidaResultado(
      vazaoReduzidaLs: totalLMin / 60,
      formulaUtilizada: 'F24 (p.96): trapézios da VI(x)·E ao longo de 0–L',
    );
  }

  /// Avalia se uma vazão é erosiva.
  ///
  /// Retorna [null] se não houver problema, ou uma string com o alerta.
  static String? avaliarVazao({
    required double vazaoAplicadaLs,
    required double qmaxLs,
    required double? vazaoReduzidaLs,
  }) {
    if (vazaoAplicadaLs > qmaxLs) {
      return 'VAZÃO EROSIVA: ${vazaoAplicadaLs.toStringAsFixed(2)} L/s '
          'excede o limite não erosivo (${qmaxLs.toStringAsFixed(2)} L/s). '
          'Considere reduzir a vazão.';
    }

    if (vazaoReduzidaLs != null && vazaoAplicadaLs < vazaoReduzidaLs) {
      return 'Vazão abaixo da faixa operacional '
          '(${vazaoAplicadaLs.toStringAsFixed(2)} < ${vazaoReduzidaLs.toStringAsFixed(2)} L/s). '
          'Avanço pode ser muito lento.';
    }

    return null;
  }

  /// Retorna os parâmetros de erosão para uma textura.
  static ParametrosErosao? getParametros(TexturaSolo textura) {
    return _parametrosErosao[textura];
  }
}
