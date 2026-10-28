/// Categoria de um alerta de projeto.
///
/// Os nomes dos valores são persistidos nos cenários e não devem mudar.
enum TipoAlerta {
  aviso,
  erro,
  info,
  erosao,
  eficienciaBaixa,
  perdaAlta,
  dadoPendente,
}

/// Alerta produzido durante a análise do projeto.
class AlertaSulco {
  const AlertaSulco({required this.tipo, required this.mensagem, this.dados});

  final TipoAlerta tipo;
  final String mensagem;

  /// Dados numéricos que contextualizam o alerta, quando houver.
  final Map<String, dynamic>? dados;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'tipo': tipo.name,
    'mensagem': mensagem,
    'dados': dados,
  };

  factory AlertaSulco.fromMap(Map<String, dynamic> map) => AlertaSulco(
    tipo: TipoAlerta.values.firstWhere(
      (valor) => valor.name == map['tipo'],
      orElse: () => TipoAlerta.aviso,
    ),
    mensagem: map['mensagem'] as String? ?? '',
    dados: map['dados'] is Map
        ? Map<String, dynamic>.from(map['dados'] as Map)
        : null,
  );
}

/// Tempos e lâmina calculados em uma estaca do perfil.
class DadosEstaca {
  const DadosEstaca({
    required this.distanciaM,
    this.tempoAvancoMin,
    this.tempoDeplecaoMin,
    this.tempoRecessoMin,
    this.tempoOportunidadeMin,
    this.laminaInfiltradaMm,
  });

  /// Distância da estaca ao início do sulco, em metros.
  final double distanciaM;

  final double? tempoAvancoMin;
  final double? tempoDeplecaoMin;
  final double? tempoRecessoMin;
  final double? tempoOportunidadeMin;
  final double? laminaInfiltradaMm;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'estaca_m': distanciaM,
    'tempo_avanco_min': tempoAvancoMin,
    'tempo_deplecao_min': tempoDeplecaoMin,
    'tempo_recesso_min': tempoRecessoMin,
    'tempo_oportunidade_min': tempoOportunidadeMin,
    'lamina_infiltrada_mm': laminaInfiltradaMm,
  };

  factory DadosEstaca.fromMap(Map<String, dynamic> map) => DadosEstaca(
    distanciaM: (map['estaca_m'] as num?)?.toDouble() ?? 0,
    tempoAvancoMin: (map['tempo_avanco_min'] as num?)?.toDouble(),
    tempoDeplecaoMin: (map['tempo_deplecao_min'] as num?)?.toDouble(),
    tempoRecessoMin: (map['tempo_recesso_min'] as num?)?.toDouble(),
    tempoOportunidadeMin: (map['tempo_oportunidade_min'] as num?)?.toDouble(),
    laminaInfiltradaMm: (map['lamina_infiltrada_mm'] as num?)?.toDouble(),
  );
}

/// Fase de reposição de água após o corte do fornecimento.
class FaseReposicao {
  const FaseReposicao({
    this.tempoCorteH,
    this.escoamentoReutilizado = false,
    this.instanteInicioEscoamentoFinalMin,
  });

  final double? tempoCorteH;
  final bool escoamentoReutilizado;
  final double? instanteInicioEscoamentoFinalMin;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'tempo_corte_h': tempoCorteH,
    'escoamento_reutilizado': escoamentoReutilizado,
    'instante_inicio_escoamento_final_min': instanteInicioEscoamentoFinalMin,
  };

  factory FaseReposicao.fromMap(Map<String, dynamic> map) => FaseReposicao(
    tempoCorteH: (map['tempo_corte_h'] as num?)?.toDouble(),
    escoamentoReutilizado: map['escoamento_reutilizado'] as bool? ?? false,
    instanteInicioEscoamentoFinalMin:
        (map['instante_inicio_escoamento_final_min'] as num?)?.toDouble(),
  );
}

/// Diagnóstico textual gerado a partir dos indicadores.
class DiagnosticoProjeto {
  const DiagnosticoProjeto({
    required this.classificacaoUniformidade,
    required this.classificacaoEficiencia,
    required this.causas,
    required this.acoesSugeridas,
  });

  final String classificacaoUniformidade;
  final String classificacaoEficiencia;
  final List<String> causas;
  final List<String> acoesSugeridas;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'classificacao_uniformidade': classificacaoUniformidade,
    'classificacao_eficiencia': classificacaoEficiencia,
    'causas': causas,
    'acoes_sugeridas': acoesSugeridas,
  };

  factory DiagnosticoProjeto.fromMap(Map<String, dynamic> map) =>
      DiagnosticoProjeto(
        classificacaoUniformidade:
            map['classificacao_uniformidade'] as String? ?? '',
        classificacaoEficiencia:
            map['classificacao_eficiencia'] as String? ?? '',
        causas:
            (map['causas'] as List<dynamic>?)
                ?.map((causa) => causa as String)
                .toList() ??
            const [],
        acoesSugeridas:
            (map['acoes_sugeridas'] as List<dynamic>?)
                ?.map((acao) => acao as String)
                .toList() ??
            const [],
      );
}

/// Resultados derivados do projeto de sulcos.
class ResultadosProjetoSulco {
  const ResultadosProjetoSulco({
    required this.irnMm,
    required this.turnoRegaCalculadoDias,
    required this.turnoRegaOperacionalDias,
    this.laminaMediaAplicadaMm,
    this.eficienciaAplicacaoPercentual,
    this.eficienciaDistribuicaoPercentual,
    this.perdaPercolacaoPercentual,
    this.perdaEscoamentoPercentual,
    this.diagnostico,
    this.dadosEstacas,
  });

  /// Irrigação real necessária, em mm.
  final double irnMm;

  final double turnoRegaCalculadoDias;
  final int turnoRegaOperacionalDias;
  final double? laminaMediaAplicadaMm;
  final double? eficienciaAplicacaoPercentual;
  final double? eficienciaDistribuicaoPercentual;
  final double? perdaPercolacaoPercentual;
  final double? perdaEscoamentoPercentual;
  final DiagnosticoProjeto? diagnostico;

  /// `null` quando o projeto não guardou o perfil por estaca.
  final List<DadosEstaca>? dadosEstacas;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'irn_mm': irnMm,
    'turno_rega_calculado_dias': turnoRegaCalculadoDias,
    'turno_rega_operacional_dias': turnoRegaOperacionalDias,
    'lamina_media_aplicada_mm': laminaMediaAplicadaMm,
    'eficiencia_aplicacao_percentual': eficienciaAplicacaoPercentual,
    'eficiencia_distribuicao_percentual': eficienciaDistribuicaoPercentual,
    'perda_percolacao_percentual': perdaPercolacaoPercentual,
    'perda_escoamento_percentual': perdaEscoamentoPercentual,
    'diagnostico': diagnostico?.toMap(),
    'dados_estacas': dadosEstacas?.map((estaca) => estaca.toMap()).toList(),
  };

  factory ResultadosProjetoSulco.fromMap(Map<String, dynamic> map) =>
      ResultadosProjetoSulco(
        irnMm: (map['irn_mm'] as num?)?.toDouble() ?? 0,
        turnoRegaCalculadoDias:
            (map['turno_rega_calculado_dias'] as num?)?.toDouble() ?? 0,
        turnoRegaOperacionalDias:
            (map['turno_rega_operacional_dias'] as num?)?.toInt() ?? 0,
        laminaMediaAplicadaMm: (map['lamina_media_aplicada_mm'] as num?)
            ?.toDouble(),
        eficienciaAplicacaoPercentual:
            (map['eficiencia_aplicacao_percentual'] as num?)?.toDouble(),
        eficienciaDistribuicaoPercentual:
            (map['eficiencia_distribuicao_percentual'] as num?)?.toDouble(),
        perdaPercolacaoPercentual: (map['perda_percolacao_percentual'] as num?)
            ?.toDouble(),
        perdaEscoamentoPercentual: (map['perda_escoamento_percentual'] as num?)
            ?.toDouble(),
        diagnostico: map['diagnostico'] is Map
            ? DiagnosticoProjeto.fromMap(
                Map<String, dynamic>.from(map['diagnostico'] as Map),
              )
            : null,
        dadosEstacas: map['dados_estacas'] is List
            ? (map['dados_estacas'] as List<dynamic>)
                  .map(
                    (estaca) => DadosEstaca.fromMap(
                      Map<String, dynamic>.from(estaca as Map),
                    ),
                  )
                  .toList()
            : null,
      );
}
