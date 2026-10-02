import 'package:irrigasim/services/simulation/lamina_requerida.dart';

class BorderAgronomy {
  final double? uccPercentual, upmpPercentual, densidadeGcm3;
  final double? profundidadeRaizesCm, fracaoDisponivel;
  final double? evapotranspiracaoMmDia, precipitacaoEfetivaMmDia;

  const BorderAgronomy({
    this.uccPercentual,
    this.upmpPercentual,
    this.densidadeGcm3,
    this.profundidadeRaizesCm,
    this.fracaoDisponivel,
    this.evapotranspiracaoMmDia,
    this.precipitacaoEfetivaMmDia,
  });

  double? get irnMm {
    if (uccPercentual == null ||
        upmpPercentual == null ||
        densidadeGcm3 == null ||
        profundidadeRaizesCm == null ||
        fracaoDisponivel == null ||
        evapotranspiracaoMmDia == null ||
        precipitacaoEfetivaMmDia == null) {
      return null;
    }
    try {
      return LaminaRequeridaCalculator.calcular(
        uccPercentual: uccPercentual!,
        upmpPercentual: upmpPercentual!,
        densidadeGcm3: densidadeGcm3!,
        profundidadeRaizesCm: profundidadeRaizesCm!,
        fracaoAguaDisponivel: fracaoDisponivel!,
        demandaLiquidaMmDia:
            evapotranspiracaoMmDia! - precipitacaoEfetivaMmDia!,
        etcMmDia: evapotranspiracaoMmDia!,
        precipitacaoEfetivaMmDia: precipitacaoEfetivaMmDia!,
      ).irnMm;
    } on ArgumentError {
      return null;
    }
  }

  BorderAgronomy withValue(String field, double value) => BorderAgronomy(
    uccPercentual: field == 'uccPercentual' ? value : uccPercentual,
    upmpPercentual: field == 'upmpPercentual' ? value : upmpPercentual,
    densidadeGcm3: field == 'densidadeGcm3' ? value : densidadeGcm3,
    profundidadeRaizesCm: field == 'profundidadeRaizesCm'
        ? value
        : profundidadeRaizesCm,
    fracaoDisponivel: field == 'fracaoDisponivel' ? value : fracaoDisponivel,
    evapotranspiracaoMmDia: field == 'evapotranspiracaoMmDia'
        ? value
        : evapotranspiracaoMmDia,
    precipitacaoEfetivaMmDia: field == 'precipitacaoEfetivaMmDia'
        ? value
        : precipitacaoEfetivaMmDia,
  );

  Map<String, dynamic> toMap() => {
    'uccPercentual': uccPercentual,
    'upmpPercentual': upmpPercentual,
    'densidadeGcm3': densidadeGcm3,
    'profundidadeRaizesCm': profundidadeRaizesCm,
    'fracaoDisponivel': fracaoDisponivel,
    'evapotranspiracaoMmDia': evapotranspiracaoMmDia,
    'precipitacaoEfetivaMmDia': precipitacaoEfetivaMmDia,
  };

  factory BorderAgronomy.fromMap(Map<String, dynamic> map) {
    double? n(String key) => (map[key] as num?)?.toDouble();
    return BorderAgronomy(
      uccPercentual: n('uccPercentual'),
      upmpPercentual: n('upmpPercentual'),
      densidadeGcm3: n('densidadeGcm3'),
      profundidadeRaizesCm: n('profundidadeRaizesCm'),
      fracaoDisponivel: n('fracaoDisponivel'),
      evapotranspiracaoMmDia: n('evapotranspiracaoMmDia'),
      precipitacaoEfetivaMmDia: n('precipitacaoEfetivaMmDia'),
    );
  }
}
