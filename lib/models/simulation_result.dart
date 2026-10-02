import 'package:irrigasim/services/simulation/operational_planning.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

class PontoGrafico {
  final double x;
  final double y;
  const PontoGrafico(this.x, this.y);
}

class SimulationResult {
  final BorderResult? borderResult;
  final double eficiencia;
  final double eficienciaRequerimento;
  final double cuc;
  final double du;

  final double laminaMedia;
  final double laminaRequerida;

  final double tempoAvanco;

  final double perdaPercolacao;
  final double perdaEscoamento;

  final List<PontoGrafico> curvaAvanco;
  final List<PontoGrafico> curvaOportunidade;
  final List<double> perfilLongitudinal;

  final String resumoTextual;
  final String? alertaVazaoExcedida;
  final Map<String, double> metricas;
  final Map<String, String> unidadesMetricas;

  /// Tempos hidráulicos em minutos; nulos indicam que não foram calculados.
  final double? tempoOportunidadeFinalMin;
  final double? tempoFornecimentoMin;
  final double? laminainfiltradaInicioMm;
  final double? laminainfiltradaFinalMm;
  final double? laminainfiltradaMediaMm;
  final double? laminaAplicadaMediaMm;
  final double? eficienciaDistribuicaoEd;
  final double? adequacaoUtilGa;
  final String? origemCurvaAvanco;
  final String? metodoCurvaAvanco;
  final String? origemCurvaInfiltracao;
  final String? hipoteseRecessao;
  final bool extrapolouAvanco;
  final PlanejamentoOperacionalResultado? planejamentoOperacional;

  const SimulationResult({
    this.borderResult,
    required this.eficiencia,
    required this.eficienciaRequerimento,
    required this.cuc,
    required this.du,
    required this.laminaMedia,
    required this.laminaRequerida,
    required this.tempoAvanco,
    required this.perdaPercolacao,
    required this.perdaEscoamento,
    required this.curvaAvanco,
    this.curvaOportunidade = const [],
    required this.perfilLongitudinal,
    required this.resumoTextual,
    this.alertaVazaoExcedida,
    this.metricas = const {},
    this.unidadesMetricas = const {},
    this.tempoOportunidadeFinalMin,
    this.tempoFornecimentoMin,
    this.laminainfiltradaInicioMm,
    this.laminainfiltradaFinalMm,
    this.laminainfiltradaMediaMm,
    this.laminaAplicadaMediaMm,
    this.eficienciaDistribuicaoEd,
    this.adequacaoUtilGa,
    this.origemCurvaAvanco,
    this.metodoCurvaAvanco,
    this.origemCurvaInfiltracao,
    this.hipoteseRecessao,
    this.extrapolouAvanco = false,
    this.planejamentoOperacional,
  });

  SimulationResult comPlanejamentoOperacional(
    PlanejamentoOperacionalResultado planejamento,
  ) => SimulationResult(
    borderResult: borderResult,
    eficiencia: eficiencia,
    eficienciaRequerimento: eficienciaRequerimento,
    cuc: cuc,
    du: du,
    laminaMedia: laminaMedia,
    laminaRequerida: laminaRequerida,
    tempoAvanco: tempoAvanco,
    perdaPercolacao: perdaPercolacao,
    perdaEscoamento: perdaEscoamento,
    curvaAvanco: curvaAvanco,
    curvaOportunidade: curvaOportunidade,
    perfilLongitudinal: perfilLongitudinal,
    resumoTextual: resumoTextual,
    alertaVazaoExcedida: alertaVazaoExcedida,
    metricas: metricas,
    unidadesMetricas: unidadesMetricas,
    tempoOportunidadeFinalMin: tempoOportunidadeFinalMin,
    tempoFornecimentoMin: tempoFornecimentoMin,
    laminainfiltradaInicioMm: laminainfiltradaInicioMm,
    laminainfiltradaFinalMm: laminainfiltradaFinalMm,
    laminainfiltradaMediaMm: laminainfiltradaMediaMm,
    laminaAplicadaMediaMm: laminaAplicadaMediaMm,
    eficienciaDistribuicaoEd: eficienciaDistribuicaoEd,
    adequacaoUtilGa: adequacaoUtilGa,
    origemCurvaAvanco: origemCurvaAvanco,
    metodoCurvaAvanco: metodoCurvaAvanco,
    origemCurvaInfiltracao: origemCurvaInfiltracao,
    hipoteseRecessao: hipoteseRecessao,
    extrapolouAvanco: extrapolouAvanco,
    planejamentoOperacional: planejamento,
  );

  String get classificacaoEa => _classificarEa(eficiencia);
  String get classificacaoCuc => _classificarCuc(cuc);
  String get classificacaoDu => _classificarDu(du);

  static String _classificarEa(double ea) {
    if (ea >= 85) return 'Excelente';
    if (ea >= 75) return 'Bom';
    if (ea >= 65) return 'Regular';
    return 'Ruim';
  }

  static String _classificarCuc(double cuc) {
    if (cuc >= 90) return 'Excelente';
    if (cuc >= 80) return 'Bom';
    if (cuc >= 70) return 'Regular';
    return 'Ruim';
  }

  static String _classificarDu(double du) {
    if (du >= 85) return 'Excelente';
    if (du >= 75) return 'Bom';
    if (du >= 65) return 'Regular';
    return 'Ruim';
  }
}
