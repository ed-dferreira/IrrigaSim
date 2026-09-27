import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';

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
    if (declividadePercent <= 0) {
      throw ArgumentError('Declividade deve ser maior que zero');
    }

    final params =
        _parametrosErosao[textura] ?? const ParametrosErosao(c: 0.631, a: 0.35);

    // qmax = C / S0^a  (§30: S0 em %)
    var qmax = params.c / pow(declividadePercent, params.a);

    // Fórmula simplificada: qmax = 0.631 / S0
    final qmaxSimplificada = 0.631 / declividadePercent;

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
    if (f0MmH < 0) {
      throw ArgumentError('Taxa de infiltração básica não pode ser negativa');
    }
    if (comprimentoM <= 0) {
      throw ArgumentError('Comprimento deve ser positivo');
    }
    if (espacamentoM <= 0) {
      throw ArgumentError('Espaçamento deve ser positivo');
    }
    if (fator11 < 1.0 || fator11 > 1.1) {
      throw ArgumentError('Fator deve estar entre 1.0 e 1.1');
    }

    // O fator configurável pertence somente à estimativa de Qr (§43).
    final qReduzida = (f0MmH * comprimentoM * espacamentoM * fator11) / 3600;

    return VazaoReduzidaResultado(
      vazaoReduzidaLs: qReduzida,
      fatorAplicado: fator11 != 1.0 ? fator11 : null,
      formulaUtilizada: fator11 != 1.0
          ? 'Qr = (f0 × L × E × $fator11) / 3600'
          : 'Qr = (f0 × L × E) / 3600 (§43.2)',
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
