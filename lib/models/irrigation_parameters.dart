enum MetodoIrrigacao { sulco, faixa, inundacao }

enum TipoInundacao { intermitente, permanente }

enum TexturaSolo { muitoFina, fina, media, grossa, muitoGrossa }

extension TexturaSoloExtension on TexturaSolo {
  String get displayName => switch (this) {
    TexturaSolo.muitoFina => 'Muito fina',
    TexturaSolo.fina => 'Fina',
    TexturaSolo.media => 'Média',
    TexturaSolo.grossa => 'Grossa',
    TexturaSolo.muitoGrossa => 'Muito grossa',
  };

  static TexturaSolo fromString(String? value) => TexturaSolo.values.firstWhere(
    (item) => item.name == value,
    orElse: () => TexturaSolo.media,
  );
}

extension TipoInundacaoExtension on TipoInundacao {
  String get displayName => switch (this) {
    TipoInundacao.intermitente => 'Intermitente',
    TipoInundacao.permanente => 'Permanente',
  };

  static TipoInundacao fromString(String? value) =>
      TipoInundacao.values.firstWhere(
        (tipo) => tipo.name == value,
        orElse: () => TipoInundacao.intermitente,
      );
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
  final double declividadeTransversal;
  final double larguraOuEspacamento;

  final double k;
  final double a;
  final double vib;

  final double vazao;
  final double tempoAplicacao;
  final double laminaRequerida;

  final double manningN;
  final double sigmaZ;
  final TexturaSolo texturaSolo;
  final double tempoAvancoMetadeMin;
  final double tempoAvancoFinalMin;
  final double instanteRecessaoInicioMin;
  final double instanteRecessaoFinalMin;
  final TipoInundacao tipoInundacao;
  final double areaHectares;
  final double porosidade;
  final double profundidadeCamadaMm;
  final double condutividadeHidraulicaMmDia;
  final double dtaMmCm;
  final double fatorDisponibilidade;
  final double evapotranspiracaoMmDia;
  final double laminaSuperficialMm;
  final double vazaoDisponivelLps;

  const IrrigationParameters({
    required this.comprimento,
    required this.declividade,
    this.declividadeTransversal = 0,
    required this.larguraOuEspacamento,
    required this.k,
    required this.a,
    required this.vib,
    required this.vazao,
    required this.tempoAplicacao,
    required this.laminaRequerida,
    this.manningN = 0.015,
    this.sigmaZ = 0.4,
    this.texturaSolo = TexturaSolo.media,
    this.tempoAvancoMetadeMin = 20,
    this.tempoAvancoFinalMin = 60,
    this.instanteRecessaoInicioMin = 125,
    this.instanteRecessaoFinalMin = 180,
    this.tipoInundacao = TipoInundacao.intermitente,
    this.areaHectares = 2,
    this.porosidade = 0.5,
    this.profundidadeCamadaMm = 500,
    this.condutividadeHidraulicaMmDia = 7,
    this.dtaMmCm = 2,
    this.fatorDisponibilidade = 0.5,
    this.evapotranspiracaoMmDia = 7.2,
    this.laminaSuperficialMm = 150,
    this.vazaoDisponivelLps = 36,
  });

  IrrigationParameters copyWith({
    double? comprimento,
    double? declividade,
    double? declividadeTransversal,
    double? larguraOuEspacamento,
    double? k,
    double? a,
    double? vib,
    double? vazao,
    double? tempoAplicacao,
    double? laminaRequerida,
    double? manningN,
    double? sigmaZ,
    TexturaSolo? texturaSolo,
    double? tempoAvancoMetadeMin,
    double? tempoAvancoFinalMin,
    double? instanteRecessaoInicioMin,
    double? instanteRecessaoFinalMin,
    TipoInundacao? tipoInundacao,
    double? areaHectares,
    double? porosidade,
    double? profundidadeCamadaMm,
    double? condutividadeHidraulicaMmDia,
    double? dtaMmCm,
    double? fatorDisponibilidade,
    double? evapotranspiracaoMmDia,
    double? laminaSuperficialMm,
    double? vazaoDisponivelLps,
  }) {
    return IrrigationParameters(
      comprimento: comprimento ?? this.comprimento,
      declividade: declividade ?? this.declividade,
      declividadeTransversal:
          declividadeTransversal ?? this.declividadeTransversal,
      larguraOuEspacamento: larguraOuEspacamento ?? this.larguraOuEspacamento,
      k: k ?? this.k,
      a: a ?? this.a,
      vib: vib ?? this.vib,
      vazao: vazao ?? this.vazao,
      tempoAplicacao: tempoAplicacao ?? this.tempoAplicacao,
      laminaRequerida: laminaRequerida ?? this.laminaRequerida,
      manningN: manningN ?? this.manningN,
      sigmaZ: sigmaZ ?? this.sigmaZ,
      texturaSolo: texturaSolo ?? this.texturaSolo,
      tempoAvancoMetadeMin: tempoAvancoMetadeMin ?? this.tempoAvancoMetadeMin,
      tempoAvancoFinalMin: tempoAvancoFinalMin ?? this.tempoAvancoFinalMin,
      instanteRecessaoInicioMin:
          instanteRecessaoInicioMin ?? this.instanteRecessaoInicioMin,
      instanteRecessaoFinalMin:
          instanteRecessaoFinalMin ?? this.instanteRecessaoFinalMin,
      tipoInundacao: tipoInundacao ?? this.tipoInundacao,
      areaHectares: areaHectares ?? this.areaHectares,
      porosidade: porosidade ?? this.porosidade,
      profundidadeCamadaMm: profundidadeCamadaMm ?? this.profundidadeCamadaMm,
      condutividadeHidraulicaMmDia:
          condutividadeHidraulicaMmDia ?? this.condutividadeHidraulicaMmDia,
      dtaMmCm: dtaMmCm ?? this.dtaMmCm,
      fatorDisponibilidade: fatorDisponibilidade ?? this.fatorDisponibilidade,
      evapotranspiracaoMmDia:
          evapotranspiracaoMmDia ?? this.evapotranspiracaoMmDia,
      laminaSuperficialMm: laminaSuperficialMm ?? this.laminaSuperficialMm,
      vazaoDisponivelLps: vazaoDisponivelLps ?? this.vazaoDisponivelLps,
    );
  }
}
