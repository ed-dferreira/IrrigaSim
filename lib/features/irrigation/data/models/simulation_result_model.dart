import '../../domain/entities/simulation_result.dart';

class SimulationResultModel {
  static Map<String, dynamic> toMap(SimulationResult result) {
    return {
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
      'perfilLongitudinal': result.perfilLongitudinal,
      'resumoTextual': result.resumoTextual,
      'alertaVazaoExcedida': result.alertaVazaoExcedida,
      'metricas': result.metricas,
      'unidadesMetricas': result.unidadesMetricas,
    };
  }

  static SimulationResult fromMap(Map<String, dynamic> map) {
    return SimulationResult(
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
    );
  }
}
