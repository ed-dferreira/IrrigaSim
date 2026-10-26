/// Indicadores didáticos da aula e balanço espacial no domínio [0, L].
/// As lâminas são médias por trapézios em estacas igualmente espaçadas, em mm.
class IndicadoresBalancoSulco {
  const IndicadoresBalancoSulco({
    required this.eaSlide,
    required this.eaIntegral,
    required this.ppIntegral,
    required this.peIntegral,
    required this.laminaInfiltradaMm,
    required this.laminaUtilMm,
    required this.laminaPercoladaMm,
    required this.laminaEscoadaMm,
    required this.deficitMm,
    this.ppSlide,
  });

  final double eaSlide;
  final double? ppSlide;
  final double eaIntegral;
  final double ppIntegral;
  final double peIntegral;
  final double laminaInfiltradaMm;
  final double laminaUtilMm;
  final double laminaPercoladaMm;
  final double laminaEscoadaMm;
  final double deficitMm;

  Map<String, dynamic> toMap() => {
    'eaSlide': eaSlide,
    'ppSlide': ppSlide,
    'eaIntegral': eaIntegral,
    'ppIntegral': ppIntegral,
    'peIntegral': peIntegral,
    'laminaInfiltradaMm': laminaInfiltradaMm,
    'laminaUtilMm': laminaUtilMm,
    'laminaPercoladaMm': laminaPercoladaMm,
    'laminaEscoadaMm': laminaEscoadaMm,
    'deficitMm': deficitMm,
  };

  factory IndicadoresBalancoSulco.fromMap(Map<String, dynamic> map) {
    double numero(String key) => (map[key] as num).toDouble();
    return IndicadoresBalancoSulco(
      eaSlide: numero('eaSlide'),
      ppSlide: (map['ppSlide'] as num?)?.toDouble(),
      eaIntegral: numero('eaIntegral'),
      ppIntegral: numero('ppIntegral'),
      peIntegral: numero('peIntegral'),
      laminaInfiltradaMm: numero('laminaInfiltradaMm'),
      laminaUtilMm: numero('laminaUtilMm'),
      laminaPercoladaMm: numero('laminaPercoladaMm'),
      laminaEscoadaMm: numero('laminaEscoadaMm'),
      deficitMm: numero('deficitMm'),
    );
  }
}
