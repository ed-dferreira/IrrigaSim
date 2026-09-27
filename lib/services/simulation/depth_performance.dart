import 'dart:math';

import 'package:irrigasim/services/simulation/performance_indicators.dart';

/// Limites configuráveis para classificação de desempenho.
class LimitesDesempenho {
  final double eaMinimaAceitavel;
  final double eaIdeal;
  final double ppLimite;
  final double peLimite;

  const LimitesDesempenho({
    this.eaMinimaAceitavel = 60,
    this.eaIdeal = 75,
    this.ppLimite = 15,
    this.peLimite = 10,
  });

  static const defaults = LimitesDesempenho();
}

/// Resultado do cálculo de lâmina aplicada.
class LaminaAplicadaResultado {
  final double laminaAplicadaMm;
  final double laminaMinimaMm;
  final double laminaMaximaMm;
  final double laminaMediaMm;
  final double tempoTotalMin;
  final double vazaoLs;
  final bool usouReducao;

  const LaminaAplicadaResultado({
    required this.laminaAplicadaMm,
    required this.laminaMinimaMm,
    required this.laminaMaximaMm,
    required this.laminaMediaMm,
    required this.tempoTotalMin,
    required this.vazaoLs,
    required this.usouReducao,
  });

  Map<String, dynamic> toMap() {
    return {
      'lamina_aplicada_mm': laminaAplicadaMm,
      'lamina_minima_mm': laminaMinimaMm,
      'lamina_maxima_mm': laminaMaximaMm,
      'lamina_media_mm': laminaMediaMm,
      'tempo_total_min': tempoTotalMin,
      'vazao_ls': vazaoLs,
      'usou_reducao': usouReducao,
    };
  }
}

/// Resultado do cálculo de eficiência e desempenho.
class DesempenhoResultado {
  final double eficienciaAplicacao;
  final double eficienciaDistribuicao;
  final double eficienciaConducao;
  final double eficienciaAdequacao;
  final double perdaPercolacao;
  final double perdaEscoamento;
  final double laminaMediaInfiltrada;
  final double laminaAplicada;
  final double laminaRequerida;
  final String classificacaoEa;
  final String classificacaoCuc;
  final String classificacaoDu;

  const DesempenhoResultado({
    required this.eficienciaAplicacao,
    required this.eficienciaDistribuicao,
    required this.eficienciaConducao,
    required this.eficienciaAdequacao,
    required this.perdaPercolacao,
    required this.perdaEscoamento,
    required this.laminaMediaInfiltrada,
    required this.laminaAplicada,
    required this.laminaRequerida,
    required this.classificacaoEa,
    required this.classificacaoCuc,
    required this.classificacaoDu,
  });

  Map<String, dynamic> toMap() {
    return {
      'eficiencia_aplicacao': eficienciaAplicacao,
      'eficiencia_distribuicao': eficienciaDistribuicao,
      'eficiencia_conducao': eficienciaConducao,
      'eficiencia_adequacao': eficienciaAdequacao,
      'perda_percolacao': perdaPercolacao,
      'perda_escoamento': perdaEscoamento,
      'lamina_media_infiltrada': laminaMediaInfiltrada,
      'lamina_aplicada': laminaAplicada,
      'lamina_requerida': laminaRequerida,
      'classificacao_ea': classificacaoEa,
      'classificacao_cuc': classificacaoCuc,
      'classificacao_du': classificacaoDu,
    };
  }
}

/// Calcula lâminas e parâmetros de desempenho.
///
/// Referências: §38 e §45 do documento de implementação.
class DepthPerformance {
  const DepthPerformance._();

  /// Calcula a lâmina aplicada com vazão constante.
  ///
  /// Equação: `Lm = (Tt * qc / (C * L)) * 3600`
  ///
  /// Onde:
  /// - Tt = tempo total de aplicação (min)
  /// - qc = vazão constante (L/s)
  /// - C = espaçamento entre sulcos (m)
  /// - L = comprimento do sulco (m)
  static double laminaConstante({
    required double tempoTotalMin,
    required double vazaoLs,
    required double espacamentoM,
    required double comprimentoM,
  }) {
    if (comprimentoM <= 0 || espacamentoM <= 0) {
      throw ArgumentError('Comprimento e espaçamento devem ser positivos');
    }
    if (tempoTotalMin < 0 || vazaoLs < 0) {
      throw ArgumentError('Tempo total e vazão não podem ser negativos');
    }

    // Lm = (Tt * qc / (C * L)) * 3600
    // Converter L/s para m³/min: L/s * 60 / 1000 = L/min / 1000
    final volumeM3 = (vazaoLs * tempoTotalMin * 60) / 1000;
    final areaM2 = comprimentoM * espacamentoM;
    final laminaM = volumeM3 / areaM2;
    final laminaMm = laminaM * 1000;

    return laminaMm;
  }

  /// Calcula a lâmina aplicada com redução de vazão.
  ///
  /// Equação: `Lm = [((Tt-Tr)*qi) + (Tr*qr)] / (C*L) * 3600`
  ///
  /// Onde:
  /// - Tt = tempo total (min)
  /// - Tr = tempo de redução (min)
  /// - qi = vazão inicial (L/s)
  /// - qr = vazão reduzida (L/s)
  /// - C = espaçamento (m)
  /// - L = comprimento (m)
  static double laminaComReducao({
    required double tempoTotalMin,
    required double tempoReducaoMin,
    required double vazaoInicialLs,
    required double vazaoReduzidaLs,
    required double espacamentoM,
    required double comprimentoM,
  }) {
    if (comprimentoM <= 0 || espacamentoM <= 0) {
      throw ArgumentError('Comprimento e espaçamento devem ser positivos');
    }
    if (tempoTotalMin < 0 ||
        tempoReducaoMin < 0 ||
        tempoReducaoMin > tempoTotalMin ||
        vazaoInicialLs < 0 ||
        vazaoReduzidaLs < 0) {
      throw ArgumentError(
        'Tempos e vazões devem ser não negativos e Tt deve ser >= Tr',
      );
    }
    if (vazaoReduzidaLs > vazaoInicialLs) {
      throw ArgumentError(
        'Vazão reduzida ($vazaoReduzidaLs) não pode ser maior '
        'que a inicial ($vazaoInicialLs)',
      );
    }

    // Tempo com vazão inicial
    final tempoInicial = tempoTotalMin - tempoReducaoMin;

    // Volume total em L/s*min convertido para m³
    final volumeLsMin =
        (tempoInicial * vazaoInicialLs) + (tempoReducaoMin * vazaoReduzidaLs);
    final volumeM3 = (volumeLsMin * 60) / 1000;

    final areaM2 = comprimentoM * espacamentoM;
    final laminaM = volumeM3 / areaM2;
    final laminaMm = laminaM * 1000;

    return laminaMm;
  }

  /// Calcula todas as eficiências e perdas.
  ///
  /// [perfilInfiltrado] — Lâmina infiltrada por estaca (mm)
  /// [laminaRequerida] — Lâmina requerida (mm)
  /// [laminaAplicada] — Lâmina aplicada (mm)
  /// [limites] — Limites para classificação
  static DesempenhoResultado calcularDesempenho({
    required List<double> perfilInfiltrado,
    required double laminaRequerida,
    required double laminaAplicada,
    LimitesDesempenho limites = LimitesDesempenho.defaults,
  }) {
    if (perfilInfiltrado.isEmpty) {
      throw ArgumentError('Perfil infiltrado não pode estar vazio');
    }
    if (laminaRequerida < 0 ||
        laminaAplicada <= 0 ||
        perfilInfiltrado.any((lamina) => lamina < 0)) {
      throw ArgumentError(
        'Lâminas infiltradas e requerida devem ser não negativas; lâmina aplicada deve ser positiva',
      );
    }

    // Lâmina média infiltrada
    final laminaMediaInfiltrada =
        perfilInfiltrado.reduce((a, b) => a + b) / perfilInfiltrado.length;

    // Eficiência de aplicação (Ea) = Lf / Lm * 100
    final laminaFinal = perfilInfiltrado.last;
    final eficienciaAplicacao = (laminaFinal / laminaAplicada) * 100;

    // Eficiência de distribuição (Ed) = Lf / ((Li + Lf) / 2) * 100
    final laminaInicial = perfilInfiltrado.first;
    final mediaGeometrica = (laminaInicial + laminaFinal) / 2;
    final eficienciaDistribuicao = mediaGeometrica > 0
        ? (laminaFinal / mediaGeometrica * 100)
        : 0.0;

    // Eficiência de condução (Ec) = Va / Vd * 100
    // Simplificação: assume perda de condução zero se não informada
    final eficienciaConducao = 100.0;

    // Eficiência de adequação (GA) = lâmina infiltrada útil / lâmina requerida * 100
    final laminaUtil =
        perfilInfiltrado
            .map((l) => min(l, laminaRequerida))
            .reduce((a, b) => a + b) /
        perfilInfiltrado.length;
    final eficienciaAdequacao = laminaRequerida > 0
        ? (laminaUtil / laminaRequerida * 100)
        : 0.0;

    // Perdas
    // Percolação: Pp = [(Lmi - LL) / Lm] * 100
    final perdaPercolacao = PerformanceIndicators.calcularPerdaPercolacao(
      laminaMediaInfiltrada,
      laminaRequerida,
      laminaAplicada,
    );

    // Escoamento: Pe = [(Lm - Lmi) / Lm] * 100
    final perdaEscoamento =
        ((laminaAplicada - laminaMediaInfiltrada) / laminaAplicada) * 100;

    // CUC e DU
    final cuc = PerformanceIndicators.calcularCuc(perfilInfiltrado);
    final du = PerformanceIndicators.calcularDu(perfilInfiltrado);

    return DesempenhoResultado(
      eficienciaAplicacao: eficienciaAplicacao,
      eficienciaDistribuicao: eficienciaDistribuicao,
      eficienciaConducao: eficienciaConducao,
      eficienciaAdequacao: eficienciaAdequacao,
      perdaPercolacao: perdaPercolacao,
      perdaEscoamento: perdaEscoamento,
      laminaMediaInfiltrada: laminaMediaInfiltrada,
      laminaAplicada: laminaAplicada,
      laminaRequerida: laminaRequerida,
      classificacaoEa: PerformanceIndicators.classificarEa(eficienciaAplicacao),
      classificacaoCuc: PerformanceIndicators.classificarCuc(cuc),
      classificacaoDu: PerformanceIndicators.classificarDu(du),
    );
  }

  /// Gera diagnóstico automático baseado nos indicadores (§41).
  static List<String> diagnosticar({
    required DesempenhoResultado desempenho,
    LimitesDesempenho limites = LimitesDesempenho.defaults,
  }) {
    final diagnosticos = <String>[];

    // Verificar Ea
    if (desempenho.eficienciaAplicacao < limites.eaMinimaAceitavel) {
      diagnosticos.add(
        'Eficiência de aplicação (${desempenho.eficienciaAplicacao.toStringAsFixed(1)}%) '
        'abaixo do mínimo aceitável (${limites.eaMinimaAceitavel}%). '
        'Considere aumentar vazão ou reduzir comprimento.',
      );
    }

    // Verificar percolação
    if (desempenho.perdaPercolacao > limites.ppLimite) {
      diagnosticos.add(
        'Perda por percolação (${desempenho.perdaPercolacao.toStringAsFixed(1)}%) '
        'excede o limite (${limites.ppLimite}%). '
        'Considere reduzir tempo de aplicação ou aumentar vazão.',
      );
    }

    // Verificar escoamento
    if (desempenho.perdaEscoamento > limites.peLimite) {
      diagnosticos.add(
        'Perda por escoamento (${desempenho.perdaEscoamento.toStringAsFixed(1)}%) '
        'excede o limite (${limites.peLimite}%). '
        'Considere reduzir vazão ou aumentar tempo de corte.',
      );
    }

    // Verificar uniformidade
    if (desempenho.eficienciaDistribuicao < 75) {
      diagnosticos.add(
        'Distribuição (${desempenho.eficienciaDistribuicao.toStringAsFixed(1)}%) '
        'pode estar inadequada. Verifique uniformidade do solo e topografia.',
      );
    }

    return diagnosticos;
  }
}
