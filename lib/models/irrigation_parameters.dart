import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/models/faixas/border_project.dart';

import 'sulcos/field_measurements.dart';

enum MetodoIrrigacao { sulco, faixa, inundacao }

enum TipoInundacao { intermitente, permanente }

enum TexturaSolo { muitoFina, fina, media, grossa, muitoGrossa }

enum ManejoSulco { constante, reduzida, surtir }

extension ManejoSulcoExtension on ManejoSulco {
  String get displayName => switch (this) {
    ManejoSulco.constante => 'Vazão constante',
    ManejoSulco.reduzida => 'Vazão reduzida após avanço',
    ManejoSulco.surtir => 'Surtirção (surge flow)',
  };

  String get descricao => switch (this) {
    ManejoSulco.constante => 'Vazão uniforme do início ao fim. Simples, mas pode causar perdas por percolação no início.',
    ManejoSulco.reduzida => 'Reduz a vazão quando a água atinge o final. Diminui escoamento superficial (§43).',
    ManejoSulco.surtir => 'Alterna períodos de aplicação e pausa; requer calibração específica para cálculo.',
  };
}

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
  final BorderProject? projetoFaixa;
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
  final TipoSulco? tipoSulco;
  final double tempoAvancoMetadeMin;
  final double tempoAvancoFinalMin;
  final double? coeficienteAvancoK;
  final double? expoenteAvancoB;
  final double? distanciaReferenciaAvancoM;
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

  // ---- Campos específicos de irrigação por sulcos ----
  final ManejoSulco manejoSulco;
  final double vazaoReduzidaLs;
  final double tempoMudancaMin;
  final double cicloSurtirMin;
  final double jornadaDiariaH;
  final int periodoIrrigacaoDias;
  final double tempoMudancaParcelaMin;
  final double perdasConducaoLs;
  final double precipitacaoEfetivaMmDia;
  final String nomeCultura;
  final double kc;
  final double espacamentoFileirasM;
  final double espacamentoPlantasM;
  final double? larguraSulcoM;
  final double? profundidadeSulcoM;
  final MetodoCurvaAvanco metodoCurvaAvanco;
  final bool usarEnsaioAvanco;
  final List<MedicaoAvanco> medicoesAvanco;
  final OrigemCurvaInfiltracao origemCurvaInfiltracao;
  final double distanciaEnsaioInfiltracaoM;
  final double espacamentoEnsaioInfiltracaoM;
  final List<MedicaoEntradaSaida> medicoesEntradaSaida;
  final HipoteseRecessao hipoteseRecessao;
  final List<MedicaoRecessao> medicoesRecessao;

  const IrrigationParameters({
    this.projetoFaixa,
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
    this.tipoSulco,
    this.tempoAvancoMetadeMin = 20,
    this.tempoAvancoFinalMin = 60,
    this.coeficienteAvancoK,
    this.expoenteAvancoB,
    this.distanciaReferenciaAvancoM,
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
    this.manejoSulco = ManejoSulco.constante,
    this.vazaoReduzidaLs = 0,
    this.tempoMudancaMin = 0,
    this.cicloSurtirMin = 0,
    this.jornadaDiariaH = 24,
    this.periodoIrrigacaoDias = 10,
    this.tempoMudancaParcelaMin = 30,
    this.perdasConducaoLs = 0,
    this.precipitacaoEfetivaMmDia = 0,
    this.nomeCultura = '',
    this.kc = 1.0,
    this.espacamentoFileirasM = 0.9,
    this.espacamentoPlantasM = 0.15,
    this.larguraSulcoM,
    this.profundidadeSulcoM,
    this.metodoCurvaAvanco = MetodoCurvaAvanco.doisPontos,
    this.usarEnsaioAvanco = false,
    this.medicoesAvanco = const [],
    this.origemCurvaInfiltracao =
        OrigemCurvaInfiltracao.equacaoAcumuladaInformada,
    this.distanciaEnsaioInfiltracaoM = 0,
    this.espacamentoEnsaioInfiltracaoM = 0,
    this.medicoesEntradaSaida = const [],
    this.hipoteseRecessao = HipoteseRecessao.desprezada,
    this.medicoesRecessao = const [],
  });

  IrrigationParameters copyWith({
    BorderProject? projetoFaixa,
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
    TipoSulco? tipoSulco,
    double? tempoAvancoMetadeMin,
    double? tempoAvancoFinalMin,
    double? coeficienteAvancoK,
    double? expoenteAvancoB,
    double? distanciaReferenciaAvancoM,
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
    ManejoSulco? manejoSulco,
    double? vazaoReduzidaLs,
    double? tempoMudancaMin,
    double? cicloSurtirMin,
    double? jornadaDiariaH,
    int? periodoIrrigacaoDias,
    double? tempoMudancaParcelaMin,
    double? perdasConducaoLs,
    double? precipitacaoEfetivaMmDia,
    String? nomeCultura,
    double? kc,
    double? espacamentoFileirasM,
    double? espacamentoPlantasM,
    double? larguraSulcoM,
    double? profundidadeSulcoM,
    MetodoCurvaAvanco? metodoCurvaAvanco,
    bool? usarEnsaioAvanco,
    List<MedicaoAvanco>? medicoesAvanco,
    OrigemCurvaInfiltracao? origemCurvaInfiltracao,
    double? distanciaEnsaioInfiltracaoM,
    double? espacamentoEnsaioInfiltracaoM,
    List<MedicaoEntradaSaida>? medicoesEntradaSaida,
    HipoteseRecessao? hipoteseRecessao,
    List<MedicaoRecessao>? medicoesRecessao,
  }) {
    return IrrigationParameters(
      projetoFaixa: projetoFaixa ?? this.projetoFaixa,
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
      tipoSulco: tipoSulco ?? this.tipoSulco,
      tempoAvancoMetadeMin: tempoAvancoMetadeMin ?? this.tempoAvancoMetadeMin,
      tempoAvancoFinalMin: tempoAvancoFinalMin ?? this.tempoAvancoFinalMin,
      coeficienteAvancoK: coeficienteAvancoK ?? this.coeficienteAvancoK,
      expoenteAvancoB: expoenteAvancoB ?? this.expoenteAvancoB,
      distanciaReferenciaAvancoM:
          distanciaReferenciaAvancoM ?? this.distanciaReferenciaAvancoM,
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
      manejoSulco: manejoSulco ?? this.manejoSulco,
      vazaoReduzidaLs: vazaoReduzidaLs ?? this.vazaoReduzidaLs,
      tempoMudancaMin: tempoMudancaMin ?? this.tempoMudancaMin,
      cicloSurtirMin: cicloSurtirMin ?? this.cicloSurtirMin,
      jornadaDiariaH: jornadaDiariaH ?? this.jornadaDiariaH,
      periodoIrrigacaoDias: periodoIrrigacaoDias ?? this.periodoIrrigacaoDias,
      tempoMudancaParcelaMin:
          tempoMudancaParcelaMin ?? this.tempoMudancaParcelaMin,
      perdasConducaoLs: perdasConducaoLs ?? this.perdasConducaoLs,
      precipitacaoEfetivaMmDia:
          precipitacaoEfetivaMmDia ?? this.precipitacaoEfetivaMmDia,
      nomeCultura: nomeCultura ?? this.nomeCultura,
      kc: kc ?? this.kc,
      espacamentoFileirasM: espacamentoFileirasM ?? this.espacamentoFileirasM,
      espacamentoPlantasM: espacamentoPlantasM ?? this.espacamentoPlantasM,
      larguraSulcoM: larguraSulcoM ?? this.larguraSulcoM,
      profundidadeSulcoM: profundidadeSulcoM ?? this.profundidadeSulcoM,
      metodoCurvaAvanco: metodoCurvaAvanco ?? this.metodoCurvaAvanco,
      usarEnsaioAvanco: usarEnsaioAvanco ?? this.usarEnsaioAvanco,
      medicoesAvanco: medicoesAvanco ?? this.medicoesAvanco,
      origemCurvaInfiltracao:
          origemCurvaInfiltracao ?? this.origemCurvaInfiltracao,
      distanciaEnsaioInfiltracaoM:
          distanciaEnsaioInfiltracaoM ?? this.distanciaEnsaioInfiltracaoM,
      espacamentoEnsaioInfiltracaoM:
          espacamentoEnsaioInfiltracaoM ?? this.espacamentoEnsaioInfiltracaoM,
      medicoesEntradaSaida: medicoesEntradaSaida ?? this.medicoesEntradaSaida,
      hipoteseRecessao: hipoteseRecessao ?? this.hipoteseRecessao,
      medicoesRecessao: medicoesRecessao ?? this.medicoesRecessao,
    );
  }
}
