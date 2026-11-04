import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/planejamento_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/volumes_arroz.dart';


/// Planejamento em parcelas da Aula 8 (pp. 61–62), anexado ao resultado.
class AnexoParcelas implements AnexoSimulacao {
  const AnexoParcelas({
    required this.tppMin,
    required this.npdTeorico,
    required this.npdInteiro,
    required this.appM2,
    required this.larguraTabuleiroM,
    required this.tabuleirosPorParcela,
    required this.ntt,
    required this.qTotalLS,
  });

  final double tppMin;
  final double npdTeorico;
  final int npdInteiro;
  final double appM2;
  final double larguraTabuleiroM;
  final int tabuleirosPorParcela;
  final int ntt;
  final double qTotalLS;

  @override
  Map<String, Object?> toMap() => {
    'tpp_min': tppMin,
    'npd_teorico': npdTeorico,
    'npd_inteiro': npdInteiro,
    'app_m2': appM2,
    'largura_tabuleiro_m': larguraTabuleiroM,
    'tabuleiros_por_parcela': tabuleirosPorParcela,
    'ntt': ntt,
    'q_total_l_s': qTotalLS,
  };

  factory AnexoParcelas.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    double numero(String chave) => (map[chave] as num).toDouble();
    return AnexoParcelas(
      tppMin: numero('tpp_min'),
      npdTeorico: numero('npd_teorico'),
      npdInteiro: (map['npd_inteiro'] as num).toInt(),
      appM2: numero('app_m2'),
      larguraTabuleiroM: numero('largura_tabuleiro_m'),
      tabuleirosPorParcela: (map['tabuleiros_por_parcela'] as num).toInt(),
      ntt: (map['ntt'] as num).toInt(),
      qTotalLS: numero('q_total_l_s'),
    );
  }
}

/// Melhor vazão entre candidatas explícitas (p. 60). Não afirma ótimo
/// global: registra o candidato escolhido e o motivo da escolha.
class AnexoSelecaoVazao implements AnexoSimulacao {
  const AnexoSelecaoVazao({
    required this.vazaoEscolhidaLs,
    required this.q0M3MinM,
    required this.eficienciaPercent,
    required this.candidatasAvaliadas,
    required this.candidatasRejeitadas,
  });

  final double vazaoEscolhidaLs;
  final double q0M3MinM;
  final double eficienciaPercent;
  final int candidatasAvaliadas;
  final int candidatasRejeitadas;

  @override
  Map<String, Object?> toMap() => {
    'vazao_escolhida_l_s': vazaoEscolhidaLs,
    'q0_m3_min_m': q0M3MinM,
    'eficiencia_percent': eficienciaPercent,
    'candidatas_avaliadas': candidatasAvaliadas,
    'candidatas_rejeitadas': candidatasRejeitadas,
  };

  factory AnexoSelecaoVazao.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AnexoSelecaoVazao(
      vazaoEscolhidaLs: (map['vazao_escolhida_l_s'] as num).toDouble(),
      q0M3MinM: (map['q0_m3_min_m'] as num).toDouble(),
      eficienciaPercent: (map['eficiencia_percent'] as num).toDouble(),
      candidatasAvaliadas: (map['candidatas_avaliadas'] as num).toInt(),
      candidatasRejeitadas: (map['candidatas_rejeitadas'] as num).toInt(),
    );
  }
}

/// Volumes de água do arroz (Aula 8, pp. 74–84) anexados ao resultado,
/// preservando as lacunas do enunciado (G4): nada que a fonte não informa é
/// presumido, e os campos ausentes seguem declarados em
/// [ResultadoVolumesArroz.dadosAusentes].
class AnexoVolumesArroz implements AnexoSimulacao {
  const AnexoVolumesArroz(this.volumes, {this.pagina = 84});

  final ResultadoVolumesArroz volumes;

  /// Página do enunciado de referência dos volumes.
  final int pagina;

  @override
  Map<String, Object?> toMap() => {'pagina': pagina, ...volumes.toMap()};

  factory AnexoVolumesArroz.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AnexoVolumesArroz(
      ResultadoVolumesArroz.fromMap(map),
      pagina: (map['pagina'] as num?)?.toInt() ?? 84,
    );
  }
}

/// Chaves persistidas dos anexos da inundação (parte do JSON salvo).
const chaveAnexoParcelas = 'planejamentoParcelas';
const chaveAnexoSelecaoVazao = 'selecaoVazao';
const chaveAnexoVolumesArroz = 'volumesArroz';
const chaveAnexoChecagemOperacional = 'checagemOperacional';

extension AnexosInundacaoEmSimulacao on SimulationResult {
  AnexoParcelas? get planejamentoParcelas =>
      anexos[chaveAnexoParcelas] as AnexoParcelas?;

  AnexoSelecaoVazao? get selecaoVazao =>
      anexos[chaveAnexoSelecaoVazao] as AnexoSelecaoVazao?;

  AnexoVolumesArroz? get volumesArroz =>
      anexos[chaveAnexoVolumesArroz] as AnexoVolumesArroz?;

  ChecagemOperacional? get checagemOperacional =>
      anexos[chaveAnexoChecagemOperacional] as ChecagemOperacional?;

  /// Anexa os resultados tipados da inundação e mescla métricas extras,
  /// preservando todos os campos já calculados pelo simulador do regime.
  /// [alertaInfiltracao] substitui o alerta quando informado.
  SimulationResult comAnexosInundacao({
    AnexoParcelas? parcelas,
    AnexoSelecaoVazao? selecao,
    AnexoVolumesArroz? volumes,
    ChecagemOperacional? checagem,
    Map<String, double> metricasExtras = const {},
    Map<String, String> unidadesExtras = const {},
    String? alertaInfiltracao,
    String? alertaVazaoExcedida,
  }) => SimulationResult(
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
    anexos: {
      ...anexos,
      chaveAnexoParcelas: ?(parcelas ?? planejamentoParcelas),
      chaveAnexoSelecaoVazao: ?(selecao ?? selecaoVazao),
      chaveAnexoVolumesArroz: ?(volumes ?? volumesArroz),
      chaveAnexoChecagemOperacional: ?(checagem ?? checagemOperacional),
    },
  );
}
