import 'simulation_result.dart';
import 'faixas/border_result.dart';

import 'package:irrigasim/services/simulation/operational_planning.dart';

class SimulationResultModel {
  static Map<String, dynamic> toMap(SimulationResult result) {
    return {
      if (result.borderResult != null)
        'resultadoFaixa': result.borderResult!.toMap(),
      'eficiencia': result.eficiencia,
      'eficienciaRequerimento': result.eficienciaRequerimento,
      'cuc': result.cuc,
      'du': result.du,
      'laminaMedia': result.laminaMedia,
      'laminaRequerida': result.laminaRequerida,
      'tempoAvanco': result.tempoAvanco,
      'perdaPercolacao': result.perdaPercolacao,
      'perdaEscoamento': result.perdaEscoamento,
      'curvaAvanco': result.curvaAvanco
          .map((p) => {'x': p.x, 'y': p.y})
          .toList(),
      'curvaOportunidade': result.curvaOportunidade
          .map((point) => {'x': point.x, 'y': point.y})
          .toList(),
      'perfilLongitudinal': result.perfilLongitudinal,
      'resumoTextual': result.resumoTextual,
      'alertaVazaoExcedida': result.alertaVazaoExcedida,
      'metricas': result.metricas,
      'unidadesMetricas': result.unidadesMetricas,
      'tempoOportunidadeFinalMin': result.tempoOportunidadeFinalMin,
      'tempoFornecimentoMin': result.tempoFornecimentoMin,
      'laminainfiltradaInicioMm': result.laminainfiltradaInicioMm,
      'laminainfiltradaFinalMm': result.laminainfiltradaFinalMm,
      'laminainfiltradaMediaMm': result.laminainfiltradaMediaMm,
      'laminaAplicadaMediaMm': result.laminaAplicadaMediaMm,
      'eficienciaDistribuicaoEd': result.eficienciaDistribuicaoEd,
      'adequacaoUtilGa': result.adequacaoUtilGa,
      'origemCurvaAvanco': result.origemCurvaAvanco,
      'metodoCurvaAvanco': result.metodoCurvaAvanco,
      'origemCurvaInfiltracao': result.origemCurvaInfiltracao,
      'hipoteseRecessao': result.hipoteseRecessao,
      'extrapolouAvanco': result.extrapolouAvanco,
      'planejamentoOperacional': result.planejamentoOperacional?.toMap(),
    };
  }

  static SimulationResult fromMap(Map<String, dynamic> map) {
    return SimulationResult(
      borderResult: map['resultadoFaixa'] is Map
          ? BorderResult.fromMap(
              Map<String, dynamic>.from(map['resultadoFaixa'] as Map),
            )
          : null,
      eficiencia: (map['eficiencia'] as num).toDouble(),
      eficienciaRequerimento: (map['eficienciaRequerimento'] as num).toDouble(),
      cuc: (map['cuc'] as num).toDouble(),
      du: (map['du'] as num).toDouble(),
      laminaMedia: (map['laminaMedia'] as num).toDouble(),
      laminaRequerida: (map['laminaRequerida'] as num).toDouble(),
      tempoAvanco: (map['tempoAvanco'] as num).toDouble(),
      perdaPercolacao: (map['perdaPercolacao'] as num).toDouble(),
      perdaEscoamento: (map['perdaEscoamento'] as num).toDouble(),
      curvaAvanco: (map['curvaAvanco'] as List)
          .map(
            (p) => PontoGrafico(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            ),
          )
          .toList(),
      curvaOportunidade:
          (map['curvaOportunidade'] as List<dynamic>?)
              ?.map(
                (point) => PontoGrafico(
                  (point['x'] as num).toDouble(),
                  (point['y'] as num).toDouble(),
                ),
              )
              .toList() ??
          const [],
      perfilLongitudinal: (map['perfilLongitudinal'] as List)
          .map((v) => (v as num).toDouble())
          .toList(),
      resumoTextual: map['resumoTextual'] ?? '',
      alertaVazaoExcedida: map['alertaVazaoExcedida'],
      metricas: (map['metricas'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      unidadesMetricas:
          (map['unidadesMetricas'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key, value.toString()),
          ),
      tempoOportunidadeFinalMin: (map['tempoOportunidadeFinalMin'] as num?)
          ?.toDouble(),
      tempoFornecimentoMin: (map['tempoFornecimentoMin'] as num?)?.toDouble(),
      laminainfiltradaInicioMm: (map['laminainfiltradaInicioMm'] as num?)
          ?.toDouble(),
      laminainfiltradaFinalMm: (map['laminainfiltradaFinalMm'] as num?)
          ?.toDouble(),
      laminainfiltradaMediaMm: (map['laminainfiltradaMediaMm'] as num?)
          ?.toDouble(),
      laminaAplicadaMediaMm: (map['laminaAplicadaMediaMm'] as num?)?.toDouble(),
      eficienciaDistribuicaoEd: (map['eficienciaDistribuicaoEd'] as num?)
          ?.toDouble(),
      adequacaoUtilGa: (map['adequacaoUtilGa'] as num?)?.toDouble(),
      origemCurvaAvanco: map['origemCurvaAvanco'] as String?,
      metodoCurvaAvanco: map['metodoCurvaAvanco'] as String?,
      origemCurvaInfiltracao: map['origemCurvaInfiltracao'] as String?,
      hipoteseRecessao: map['hipoteseRecessao'] as String?,
      extrapolouAvanco: map['extrapolouAvanco'] as bool? ?? false,
      planejamentoOperacional: map['planejamentoOperacional'] is Map
          ? PlanejamentoOperacionalResultado.fromMap(
              Map<String, dynamic>.from(map['planejamentoOperacional'] as Map),
            )
          : null,
    );
  }
}
