enum MetodoIrrigacao {
  sulco,
  faixa,
  inundacao,
}

extension MetodoIrrigacaoExtension on MetodoIrrigacao {
  String get displayName {
    switch (this) {
      case MetodoIrrigacao.sulco:
        return 'Sulco';
      case MetodoIrrigacao.faixa:
        return 'Faixa';
      case MetodoIrrigacao.inundacao:
        return 'Inundação';
    }
  }

  static MetodoIrrigacao fromString(String value) {
    return MetodoIrrigacao.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MetodoIrrigacao.sulco,
    );
  }
}

class IrrigationParameters {
  final double comprimento;
  final double declividade;
  final double larguraOuEspacamento;

  final double k;
  final double a;
  final double vib;

  final double vazao;
  final double tempoAplicacao;
  final double laminaRequerida;

  final double manningN;
  final double sigmaZ;

  const IrrigationParameters({
    required this.comprimento,
    required this.declividade,
    required this.larguraOuEspacamento,
    required this.k,
    required this.a,
    required this.vib,
    required this.vazao,
    required this.tempoAplicacao,
    required this.laminaRequerida,
    this.manningN = 0.015,
    this.sigmaZ = 0.4,
  });

  IrrigationParameters copyWith({
    double? comprimento,
    double? declividade,
    double? larguraOuEspacamento,
    double? k,
    double? a,
    double? vib,
    double? vazao,
    double? tempoAplicacao,
    double? laminaRequerida,
    double? manningN,
    double? sigmaZ,
  }) {
    return IrrigationParameters(
      comprimento: comprimento ?? this.comprimento,
      declividade: declividade ?? this.declividade,
      larguraOuEspacamento: larguraOuEspacamento ?? this.larguraOuEspacamento,
      k: k ?? this.k,
      a: a ?? this.a,
      vib: vib ?? this.vib,
      vazao: vazao ?? this.vazao,
      tempoAplicacao: tempoAplicacao ?? this.tempoAplicacao,
      laminaRequerida: laminaRequerida ?? this.laminaRequerida,
      manningN: manningN ?? this.manningN,
      sigmaZ: sigmaZ ?? this.sigmaZ,
    );
  }
}
