import 'package:irrigasim/shared/irrigacao/services/operational_planning.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/border_result.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_annexes.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/indicadores_balanco.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_planning.dart';

class PontoGrafico {
  final double x;
  final double y;
  const PontoGrafico(this.x, this.y);
}

class SimulationResult {
  final BorderResult? borderResult;
  final IndicadoresBalancoSulco? balancoSulco;
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
  final String? alertaInfiltracao;
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

  /// Anexos da inundação (Fase 6): planejamento em parcelas, seleção entre
  /// vazões candidatas e volumes do arroz, nulos fora desse regime.
  final BasinParcelasAnexo? planejamentoParcelas;
  final BasinSelecaoVazaoAnexo? selecaoVazao;
  final BasinVolumesAnexo? volumesArroz;

  /// Checagem operacional obrigatória G3 (vazão e geometria), nula quando o
  /// simulador do regime não a calculou.
  final BasinChecagemOperacional? checagemOperacional;

  const SimulationResult({
    this.borderResult,
    this.balancoSulco,
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
    this.alertaInfiltracao,
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
    this.planejamentoParcelas,
    this.selecaoVazao,
    this.volumesArroz,
    this.checagemOperacional,
  });

  SimulationResult comPlanejamentoOperacional(
    PlanejamentoOperacionalResultado planejamento,
  ) => SimulationResult(
    borderResult: borderResult,
    balancoSulco: balancoSulco,
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
    alertaInfiltracao: alertaInfiltracao,
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
    planejamentoParcelas: planejamentoParcelas,
    selecaoVazao: selecaoVazao,
    volumesArroz: volumesArroz,
    checagemOperacional: checagemOperacional,
  );

  /// Anexa os resultados tipados da inundação e mescla métricas extras,
  /// preservando todos os campos já calculados pelo simulador do regime.
  /// [alertaInfiltracao] substitui o alerta quando informado.
  SimulationResult comAnexosInundacao({
    BasinParcelasAnexo? parcelas,
    BasinSelecaoVazaoAnexo? selecao,
    BasinVolumesAnexo? volumes,
    BasinChecagemOperacional? checagem,
    Map<String, double> metricasExtras = const {},
    Map<String, String> unidadesExtras = const {},
    String? alertaInfiltracao,
    String? alertaVazaoExcedida,
  }) => SimulationResult(
    borderResult: borderResult,
    balancoSulco: balancoSulco,
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
    alertaVazaoExcedida: alertaVazaoExcedida ?? this.alertaVazaoExcedida,
    alertaInfiltracao: alertaInfiltracao ?? this.alertaInfiltracao,
    metricas: {...metricas, ...metricasExtras},
    unidadesMetricas: {...unidadesMetricas, ...unidadesExtras},
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
    planejamentoOperacional: planejamentoOperacional,
    planejamentoParcelas: parcelas ?? planejamentoParcelas,
    selecaoVazao: selecao ?? selecaoVazao,
    volumesArroz: volumes ?? volumesArroz,
    checagemOperacional: checagem ?? checagemOperacional,
  );

  String get classificacaoEa => _classificarEa(eficiencia);
  String get classificacaoEaIntegral => _classificarEa(
    balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? eficiencia,
  );
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
