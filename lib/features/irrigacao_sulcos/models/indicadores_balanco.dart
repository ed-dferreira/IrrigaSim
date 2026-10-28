/// Indicadores didáticos da aula e balanço espacial no domínio `[0, L]`.
///
/// As lâminas são médias por trapézios em estacas igualmente espaçadas, em mm.
/// Os percentuais de eficiência e perda são expressos em %.
class IndicadoresBalancoSulco {
  const IndicadoresBalancoSulco({
    required this.eficienciaAplicacaoSlidePercentual,
    required this.eficienciaAplicacaoIntegralPercentual,
    required this.perdaPercolacaoIntegralPercentual,
    required this.perdaEscoamentoIntegralPercentual,
    required this.laminaMediaInfiltradaMm,
    required this.laminaUtilMm,
    required this.laminaPercoladaMm,
    required this.laminaEscoadaMm,
    required this.deficitMm,
    this.perdaPercolacaoSlidePercentual,
  });

  /// Ea do slide: lâmina infiltrada no final sobre a lâmina aplicada.
  final double eficienciaAplicacaoSlidePercentual;

  /// Pp do slide: excesso da lâmina média sobre a requerida.
  ///
  /// `null` quando a lâmina média não supera a requerida (não há percolação).
  final double? perdaPercolacaoSlidePercentual;

  /// Ea integral: lâmina útil sobre a lâmina aplicada.
  final double eficienciaAplicacaoIntegralPercentual;

  /// Pp integral: lâmina percolada sobre a lâmina aplicada.
  final double perdaPercolacaoIntegralPercentual;

  /// Pe integral: lâmina escoada sobre a lâmina aplicada.
  final double perdaEscoamentoIntegralPercentual;

  final double laminaMediaInfiltradaMm;
  final double laminaUtilMm;
  final double laminaPercoladaMm;
  final double laminaEscoadaMm;

  /// Lâmina faltante para atender à requerida; zero quando não há déficit.
  final double deficitMm;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'eficiencia_aplicacao_slide_percentual': eficienciaAplicacaoSlidePercentual,
    'perda_percolacao_slide_percentual': perdaPercolacaoSlidePercentual,
    'eficiencia_aplicacao_integral_percentual':
        eficienciaAplicacaoIntegralPercentual,
    'perda_percolacao_integral_percentual': perdaPercolacaoIntegralPercentual,
    'perda_escoamento_integral_percentual': perdaEscoamentoIntegralPercentual,
    'lamina_media_infiltrada_mm': laminaMediaInfiltradaMm,
    'lamina_util_mm': laminaUtilMm,
    'lamina_percolada_mm': laminaPercoladaMm,
    'lamina_escoada_mm': laminaEscoadaMm,
    'deficit_mm': deficitMm,
  };

  factory IndicadoresBalancoSulco.fromMap(Map<String, dynamic> map) {
    /// Aceita as chaves antigas em camelCase de cenários já salvos.
    double? numero(String chave, [String? chaveLegada]) {
      final valor =
          map[chave] ?? (chaveLegada == null ? null : map[chaveLegada]);
      return (valor as num?)?.toDouble();
    }

    double obrigatorio(String chave, String chaveLegada) =>
        numero(chave, chaveLegada) ??
        (throw FormatException(
          'Indicadores de balanço sem o campo obrigatório "$chave".',
        ));

    return IndicadoresBalancoSulco(
      eficienciaAplicacaoSlidePercentual: obrigatorio(
        'eficiencia_aplicacao_slide_percentual',
        'eficienciaAplicacaoSlidePercentual',
      ),
      perdaPercolacaoSlidePercentual: numero(
        'perda_percolacao_slide_percentual',
        'perdaPercolacaoSlidePercentual',
      ),
      eficienciaAplicacaoIntegralPercentual: obrigatorio(
        'eficiencia_aplicacao_integral_percentual',
        'eficienciaAplicacaoIntegralPercentual',
      ),
      perdaPercolacaoIntegralPercentual: obrigatorio(
        'perda_percolacao_integral_percentual',
        'perdaPercolacaoIntegralPercentual',
      ),
      perdaEscoamentoIntegralPercentual: obrigatorio(
        'perda_escoamento_integral_percentual',
        'perdaEscoamentoIntegralPercentual',
      ),
      laminaMediaInfiltradaMm: obrigatorio(
        'lamina_media_infiltrada_mm',
        'laminaInfiltradaMm',
      ),
      laminaUtilMm: obrigatorio('lamina_util_mm', 'laminaUtilMm'),
      laminaPercoladaMm: obrigatorio(
        'lamina_percolada_mm',
        'laminaPercoladaMm',
      ),
      laminaEscoadaMm: obrigatorio('lamina_escoada_mm', 'laminaEscoadaMm'),
      deficitMm: obrigatorio('deficit_mm', 'deficitMm'),
    );
  }
}
