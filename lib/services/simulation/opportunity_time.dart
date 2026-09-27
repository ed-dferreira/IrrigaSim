import 'package:irrigasim/services/simulation/advance_curve_model.dart';
import 'package:irrigasim/services/simulation/infiltration_model.dart';

/// Resultado do cálculo de tempo de oportunidade para um ponto.
class TempoOportunidadeResultado {
  final double tempoMin;
  final double tempoCorteMin;
  final double tempoDeplecaoMin;
  final double tempoRecessoMin;
  final double tempoAvancoMin;
  final bool ehNegativo;

  const TempoOportunidadeResultado({
    required this.tempoMin,
    required this.tempoCorteMin,
    required this.tempoDeplecaoMin,
    required this.tempoRecessoMin,
    required this.tempoAvancoMin,
    required this.ehNegativo,
  });

  Map<String, dynamic> toMap() {
    return {
      'tempo_min': tempoMin,
      'tempo_corte_min': tempoCorteMin,
      'tempo_deplecao_min': tempoDeplecaoMin,
      'tempo_recesso_min': tempoRecessoMin,
      'tempo_avanco_min': tempoAvancoMin,
      'eh_negativo': ehNegativo,
    };
  }
}

/// Resultado do cálculo de tempo de irrigação.
class TempoIrrigacaoResultado {
  final double tempoOportunidadeMin;
  final double tempoAvancoMin;
  final double tempoTotalMin;
  final double tempoTotalH;
  final List<TempoOportunidadeResultado> pontos;

  const TempoIrrigacaoResultado({
    required this.tempoOportunidadeMin,
    required this.tempoAvancoMin,
    required this.tempoTotalMin,
    required this.tempoTotalH,
    required this.pontos,
  });

  Map<String, dynamic> toMap() {
    return {
      'tempo_oportunidade_min': tempoOportunidadeMin,
      'tempo_avanco_min': tempoAvancoMin,
      'tempo_total_min': tempoTotalMin,
      'tempo_total_h': tempoTotalH,
      'pontos': pontos.map((p) => p.toMap()).toList(),
    };
  }
}

/// Calcula o tempo de oportunidade e tempo de irrigação.
///
/// Referências: §26 do documento de implementação.
///
/// Fórmulas:
/// ```
/// To(i) = Tc + Td(i) + Trec(i) - Tx(i)
/// Ti = To + Ta
/// ```
///
/// Onde:
/// - To = tempo de oportunidade
/// - Tc = tempo de corte (corte do fornecimento de água)
/// - Td = tempo de depleção
/// - Trec = tempo de recesso
/// - Tx = tempo de avanço
class OpportunityTime {
  const OpportunityTime._();

  /// Calcula o tempo de oportunidade para um ponto específico.
  ///
  /// [tempoCorteMin] — Tempo de corte (min)
  /// [tempoDeplecaoMin] — Tempo de depleção (min)
  /// [tempoRecessoMin] — Tempo de recesso (min)
  /// [tempoAvancoMin] — Tempo de avanço no ponto (min)
  static TempoOportunidadeResultado calcularPonto({
    required double tempoCorteMin,
    double tempoDeplecaoMin = 0,
    double tempoRecessoMin = 0,
    required double tempoAvancoMin,
  }) {
    _validarTempos(
      tempoCorteMin: tempoCorteMin,
      tempoDeplecaoMin: tempoDeplecaoMin,
      tempoRecessoMin: tempoRecessoMin,
      tempoAvancoMin: tempoAvancoMin,
    );
    // To(i) = Tc + Td(i) + Trec(i) - Tx(i)
    final tempo =
        tempoCorteMin + tempoDeplecaoMin + tempoRecessoMin - tempoAvancoMin;

    return TempoOportunidadeResultado(
      tempoMin: tempo,
      tempoCorteMin: tempoCorteMin,
      tempoDeplecaoMin: tempoDeplecaoMin,
      tempoRecessoMin: tempoRecessoMin,
      tempoAvancoMin: tempoAvancoMin,
      ehNegativo: tempo < 0,
    );
  }

  /// Calcula o tempo de oportunidade para múltiplos pontos.
  ///
  /// [tempoCorteMin] — Tempo de corte (min)
  /// [tempoDeplecaoMin] — Tempo de depleção (min)
  /// [tempoRecessoMin] — Tempo de recesso (min)
  /// [pontosAvanco] — Lista de tempos de avanço por distância
  static List<TempoOportunidadeResultado> calcularPontos({
    required double tempoCorteMin,
    double tempoDeplecaoMin = 0,
    double tempoRecessoMin = 0,
    required List<AdvancePoint> pontosAvanco,
  }) {
    return pontosAvanco.map((ponto) {
      return calcularPonto(
        tempoCorteMin: tempoCorteMin,
        tempoDeplecaoMin: tempoDeplecaoMin,
        tempoRecessoMin: tempoRecessoMin,
        tempoAvancoMin: ponto.tempoMin,
      );
    }).toList();
  }

  /// Calcula o tempo de irrigação total.
  ///
  /// [tempoOportunidadeMin] — Tempo de oportunidade (min)
  /// [tempoAvancoMin] — Tempo de avanço final (min)
  static TempoIrrigacaoResultado calcularTempoIrrigacao({
    required double tempoOportunidadeMin,
    required double tempoAvancoMin,
    required List<AdvancePoint> pontosAvanco,
  }) {
    // Ti = To + Ta
    final tempoTotal = tempoOportunidadeMin + tempoAvancoMin;
    final tempoTotalH = tempoTotal / 60;

    if (tempoOportunidadeMin < 0 || tempoAvancoMin < 0) {
      throw ArgumentError(
        'Tempos de oportunidade e avanço não podem ser negativos',
      );
    }
    // No final do sulco, To = Tc - Ta. Portanto Tc = To + Ta.
    final tempoCorteMin = tempoOportunidadeMin + tempoAvancoMin;
    final pontos = pontosAvanco.map((ponto) {
      return calcularPonto(
        tempoCorteMin: tempoCorteMin,
        tempoAvancoMin: ponto.tempoMin,
      );
    }).toList();

    return TempoIrrigacaoResultado(
      tempoOportunidadeMin: tempoOportunidadeMin,
      tempoAvancoMin: tempoAvancoMin,
      tempoTotalMin: tempoTotal,
      tempoTotalH: tempoTotalH,
      pontos: pontos,
    );
  }

  /// Calcula a lâmina infiltrada em cada ponto dado o tempo de oportunidade.
  ///
  /// [pontosOportunidade] — Lista de tempos de oportunidade
  /// [parametrosInfiltracao] — Parâmetros de infiltração (K, n)
  static List<double> calcularLaminaPorPonto({
    required List<TempoOportunidadeResultado> pontosOportunidade,
    required InfiltrationParameters parametrosInfiltracao,
  }) {
    return pontosOportunidade.map((ponto) {
      if (ponto.tempoMin <= 0) return 0.0;
      return InfiltrationModel.infiltracaoAcumulada(
        tempoMin: ponto.tempoMin,
        parametros: parametrosInfiltracao,
      );
    }).toList();
  }

  /// Verifica se algum ponto tem tempo de oportunidade negativo.
  static bool verificarNegativos(List<TempoOportunidadeResultado> pontos) {
    return pontos.any((p) => p.ehNegativo);
  }

  /// Retorna os pontos com tempo negativo (para alertas).
  static List<TempoOportunidadeResultado> pontosNegativos(
    List<TempoOportunidadeResultado> pontos,
  ) {
    return pontos.where((p) => p.ehNegativo).toList();
  }

  /// Calcula o tempo mínimo de corte para evitar tempos negativos.
  ///
  /// O tempo de corte deve ser >= max(Tx) - Td - Trec
  static double tempoCorteMinimo({
    required double tempoDeplecaoMin,
    required double tempoRecessoMin,
    required double tempoAvancoMaximoMin,
  }) {
    if (tempoDeplecaoMin < 0 ||
        tempoRecessoMin < 0 ||
        tempoAvancoMaximoMin < 0) {
      throw ArgumentError('Tempos não podem ser negativos');
    }
    return tempoAvancoMaximoMin - tempoDeplecaoMin - tempoRecessoMin;
  }

  static void _validarTempos({
    required double tempoCorteMin,
    required double tempoDeplecaoMin,
    required double tempoRecessoMin,
    required double tempoAvancoMin,
  }) {
    if (tempoCorteMin < 0 ||
        tempoDeplecaoMin < 0 ||
        tempoRecessoMin < 0 ||
        tempoAvancoMin < 0) {
      throw ArgumentError('Tempos não podem ser negativos');
    }
  }
}
