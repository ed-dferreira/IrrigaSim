class PontoGrafico {
  final double x;
  final double y;
  const PontoGrafico(this.x, this.y);
}

class SimulationResult {
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
  final List<double> perfilLongitudinal;

  final String resumoTextual;
  final String? alertaVazaoExcedida;

  const SimulationResult({
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
    required this.perfilLongitudinal,
    required this.resumoTextual,
    this.alertaVazaoExcedida,
  });

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
