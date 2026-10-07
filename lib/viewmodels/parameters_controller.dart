import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/viewmodels/faixas/border_simulation_coordinator.dart';
import 'package:irrigasim/viewmodels/sulcos/furrow_simulation_coordinator.dart';
import 'package:irrigasim/viewmodels/inundacao/basin_simulation_coordinator.dart';
import 'package:irrigasim/services/simulation/lamina_requerida.dart';
import 'package:irrigasim/services/simulation/blaney_criddle.dart';
import 'package:irrigasim/services/simulation/sulcos/flow_management.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart'
    show MetodoAjusteAvanco, PontoEnsaio;
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/curva_infiltracao_sulco.dart';
import 'package:irrigasim/models/sulcos/entradas_projeto_sulco.dart';
import 'package:irrigasim/services/simulation/sulcos/advance_curve_model.dart';

enum OrigemAvanco { estimativa, ensaio }

class ParametersState {
  final MetodoIrrigacao metodo;
  final TipoSulco? tipoSulco;
  final double comprimento;
  final double desnivelM;
  final double distanciaHorizontalM;
  final double desnivelTransversalM;
  final double distanciaTransversalM;
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
  final double? coeficienteAvancoKInformado;
  final double? expoenteAvancoBInformado;
  final double distanciaReferenciaAvancoM;
  final double comprimentoMaximoTerrenoM;
  final OrigemAvanco origemAvanco;
  final MetodoCurvaAvanco metodoCurvaAvanco;
  final List<PontoEnsaio> pontosEnsaioAvanco;
  final OrigemCurvaInfiltracao origemCurvaInfiltracao;
  final double distanciaEnsaioInfiltracaoM;
  final double espacamentoEnsaioInfiltracaoM;
  final List<MedicaoEntradaSaida> medicoesEntradaSaida;
  final HipoteseRecessao hipoteseRecessao;
  final List<MedicaoRecessao> medicoesRecessao;
  final double distanciaEnsaioIntermediariaM;
  final double tempoEnsaioIntermediarioMin;
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
  final String nomeCultura;
  final double kc;
  final double espacamentoFileirasM;
  final double espacamentoPlantasM;
  final double precipitacaoEfetivaMmDia;
  final double uccPercentual;
  final double upmpPercentual;
  final double densidadeAparenteGcm3;
  final double profundidadeRaizesCm;
  final double fracaoAguaDisponivel;
  final LaminaRequeridaResultado? laminaRequeridaResultado;
  final bool projetoSulcoLegado;
  final Map<String, ProvenienciaSulco> origemEntradasSulco;
  final CurvaInfiltracaoSulco? curvaInfiltracaoSulco;
  final double? etoMmDia;
  final double? temperaturaMediaC;
  final double? latitudeGraus;
  final int? mesReferencia;
  final OrigemChuvaSulco origemChuva;
  final MetodoEtcSulco metodoEtc;
  final double? decliveEncostaPercent;
  final String? orientacaoSulco;
  final ProvenienciaSulco origemGeometria;
  final bool dimensionarComprimentoCriddle;
  final double vazaoReduzidaLs;
  final OrigemVazaoReduzida origemVazaoReduzida;
  final bool fator11Vib;
  final double? vazaoEnsaioAvancoLs;
  final String? condicoesEnsaioAvanco;
  final EnsaioErosaoSulco? ensaioErosao;
  final double jornadaDiariaH;
  final int periodoIrrigacaoDias;
  final double tempoMudancaParcelaMin;
  final double perdasConducaoLs;
  final ManejoSulco manejoSulco;
  final double tempoMudancaMin;
  final double cicloSurtirMin;
  final double? larguraSulcoM;
  final double? profundidadeSulcoM;
  final SimulationResult? resultado;
  final bool executando;
  final String? erro;
  final String? mensagemPlanejamento;

  const ParametersState({
    this.metodo = MetodoIrrigacao.sulco,
    this.tipoSulco,
    this.comprimento = 200,
    this.desnivelM = 1,
    this.distanciaHorizontalM = 200,
    this.desnivelTransversalM = 0,
    this.distanciaTransversalM = 10,
    this.larguraOuEspacamento = 0.9,
    this.k = 2.83,
    this.a = 0.554,
    this.vib = 0.0001,
    this.vazao = 1,
    this.tempoAplicacao = 130,
    this.laminaRequerida = 42,
    this.manningN = 0.015,
    this.sigmaZ = 0.4,
    this.texturaSolo = TexturaSolo.media,
    this.tempoAvancoMetadeMin = 35,
    this.tempoAvancoFinalMin = 90,
    this.coeficienteAvancoKInformado = 0.0659064448778603,
    this.expoenteAvancoBInformado = 1.3625700793847084,
    this.distanciaReferenciaAvancoM = 200,
    this.comprimentoMaximoTerrenoM = 200,
    this.origemAvanco = OrigemAvanco.estimativa,
    this.metodoCurvaAvanco = MetodoCurvaAvanco.doisPontos,
    this.pontosEnsaioAvanco = const [],
    this.origemCurvaInfiltracao =
        OrigemCurvaInfiltracao.equacaoAcumuladaInformada,
    this.distanciaEnsaioInfiltracaoM = 100,
    this.espacamentoEnsaioInfiltracaoM = 0.9,
    this.medicoesEntradaSaida = const [],
    this.hipoteseRecessao = HipoteseRecessao.desprezada,
    this.medicoesRecessao = const [],
    this.distanciaEnsaioIntermediariaM = 100,
    this.tempoEnsaioIntermediarioMin = 35,
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
    this.nomeCultura = '',
    this.kc = 1.0,
    this.espacamentoFileirasM = 0.9,
    this.espacamentoPlantasM = 0.25,
    this.precipitacaoEfetivaMmDia = 0,
    this.uccPercentual = 30,
    this.upmpPercentual = 15,
    this.densidadeAparenteGcm3 = 1.4,
    this.profundidadeRaizesCm = 40,
    this.fracaoAguaDisponivel = 0.5,
    this.laminaRequeridaResultado,
    this.projetoSulcoLegado = false,
    this.origemEntradasSulco = const {},
    this.curvaInfiltracaoSulco,
    this.etoMmDia,
    this.temperaturaMediaC,
    this.latitudeGraus,
    this.mesReferencia,
    this.origemChuva = OrigemChuvaSulco.efetiva,
    this.metodoEtc = MetodoEtcSulco.adotada,
    this.decliveEncostaPercent,
    this.orientacaoSulco,
    this.origemGeometria = ProvenienciaSulco.ilustrativo,
    this.dimensionarComprimentoCriddle = false,
    this.vazaoReduzidaLs = 0,
    this.origemVazaoReduzida = OrigemVazaoReduzida.taxaFinalDaCurva,
    this.fator11Vib = false,
    this.vazaoEnsaioAvancoLs,
    this.condicoesEnsaioAvanco,
    this.ensaioErosao,
    this.jornadaDiariaH = 24,
    this.periodoIrrigacaoDias = 10,
    this.tempoMudancaParcelaMin = 30,
    this.perdasConducaoLs = 0,
    this.manejoSulco = ManejoSulco.constante,
    this.tempoMudancaMin = 0,
    this.cicloSurtirMin = 30,
    this.larguraSulcoM,
    this.profundidadeSulcoM,
    this.resultado,
    this.executando = false,
    this.erro,
    this.mensagemPlanejamento,
  });

  double get declividade =>
      distanciaHorizontalM > 0 ? desnivelM / distanciaHorizontalM : 0;

  double? get etoBlaneyCriddle {
    if (temperaturaMediaC == null ||
        latitudeGraus == null ||
        mesReferencia == null) {
      return null;
    }
    try {
      return BlaneyCriddle.etoMmDia(
        temperaturaMediaC: temperaturaMediaC!,
        latitudeGraus: latitudeGraus!,
        mes: mesReferencia!,
      );
    } on ArgumentError {
      return null;
    }
  }

  double get evapotranspiracaoCulturaMmDia => switch (metodoEtc) {
    MetodoEtcSulco.adotada => evapotranspiracaoMmDia,
    MetodoEtcSulco.etoVezesKc => (etoMmDia ?? 0) * kc,
    MetodoEtcSulco.blaneyCriddle => (etoBlaneyCriddle ?? 0) * kc,
  };

  double get declividadeTransversal => distanciaTransversalM > 0
      ? desnivelTransversalM / distanciaTransversalM
      : 0;

  EntradasProjetoSulco get entradasSulco {
    double? valor(String nome, double atual) =>
        origemEntradasSulco[nome] == ProvenienciaSulco.naoInformado
        ? null
        : atual;
    final curva =
        origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada
        ? curvaInfiltracaoSulco
        : null;
    return EntradasProjetoSulco(
      uccPercentual: valor('uccPercentual', uccPercentual),
      upmpPercentual: valor('upmpPercentual', upmpPercentual),
      densidadeAparenteGcm3: valor(
        'densidadeAparenteGcm3',
        densidadeAparenteGcm3,
      ),
      profundidadeRadicularCm: valor(
        'profundidadeRaizesCm',
        profundidadeRaizesCm,
      ),
      fracaoDisponivel: valor('fracaoAguaDisponivel', fracaoAguaDisponivel),
      etcAdotadaMmDia: valor('evapotranspiracaoMmDia', evapotranspiracaoMmDia),
      etoMmDia: etoMmDia,
      temperaturaMediaC: temperaturaMediaC,
      latitudeGraus: latitudeGraus,
      mesReferencia: mesReferencia,
      kc: valor('kc', kc),
      precipitacaoMmDia: valor(
        'precipitacaoEfetivaMmDia',
        precipitacaoEfetivaMmDia,
      ),
      origemChuva: origemChuva,
      metodoEtc: metodoEtc,
      desnivelLongitudinalM: desnivelM,
      baseLongitudinalM: distanciaHorizontalM,
      decliveEncostaPercent: decliveEncostaPercent,
      orientacaoSulco: orientacaoSulco,
      origemGeometria: origemGeometria,
      dimensionarComprimentoCriddle: dimensionarComprimentoCriddle,
      origens: {
        for (final nome in [
          'uccPercentual',
          'upmpPercentual',
          'densidadeAparenteGcm3',
          'profundidadeRaizesCm',
          'fracaoAguaDisponivel',
          'evapotranspiracaoMmDia',
          'kc',
          'precipitacaoEfetivaMmDia',
        ])
          nome: origemEntradasSulco[nome] ?? ProvenienciaSulco.ilustrativo,
        if (etoMmDia != null)
          'etoMmDia':
              origemEntradasSulco['etoMmDia'] ?? ProvenienciaSulco.informado,
      },
      curvaInfiltracao: curva,
    );
  }

  double get expoenteAvancoB =>
      expoenteAvancoBInformado ??
      (tempoAvancoMetadeMin > 0 && tempoAvancoFinalMin > tempoAvancoMetadeMin
          ? (math.log(tempoAvancoMetadeMin / tempoAvancoFinalMin) / math.ln2) *
                -1
          : 1.3625700793847084);

  double get coeficienteAvancoK =>
      coeficienteAvancoKInformado ??
      (comprimento > 0 && tempoAvancoFinalMin > 0
          ? tempoAvancoFinalMin / math.pow(comprimento, expoenteAvancoB)
          : 0.0659064448778603);

  ParametersState copyWith({
    MetodoIrrigacao? metodo,
    TipoSulco? tipoSulco,
    double? comprimento,
    double? desnivelM,
    double? distanciaHorizontalM,
    double? desnivelTransversalM,
    double? distanciaTransversalM,
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
    double? coeficienteAvancoKInformado,
    double? expoenteAvancoBInformado,
    double? distanciaReferenciaAvancoM,
    double? comprimentoMaximoTerrenoM,
    OrigemAvanco? origemAvanco,
    MetodoCurvaAvanco? metodoCurvaAvanco,
    List<PontoEnsaio>? pontosEnsaioAvanco,
    OrigemCurvaInfiltracao? origemCurvaInfiltracao,
    double? distanciaEnsaioInfiltracaoM,
    double? espacamentoEnsaioInfiltracaoM,
    List<MedicaoEntradaSaida>? medicoesEntradaSaida,
    HipoteseRecessao? hipoteseRecessao,
    List<MedicaoRecessao>? medicoesRecessao,
    double? distanciaEnsaioIntermediariaM,
    double? tempoEnsaioIntermediarioMin,
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
    String? nomeCultura,
    double? kc,
    double? espacamentoFileirasM,
    double? espacamentoPlantasM,
    double? precipitacaoEfetivaMmDia,
    double? uccPercentual,
    double? upmpPercentual,
    double? densidadeAparenteGcm3,
    double? profundidadeRaizesCm,
    double? fracaoAguaDisponivel,
    LaminaRequeridaResultado? laminaRequeridaResultado,
    bool clearLaminaRequeridaResultado = false,
    bool? projetoSulcoLegado,
    Map<String, ProvenienciaSulco>? origemEntradasSulco,
    CurvaInfiltracaoSulco? curvaInfiltracaoSulco,
    bool clearCurvaInfiltracaoSulco = false,
    double? etoMmDia,
    bool clearEtoMmDia = false,
    double? temperaturaMediaC,
    bool clearTemperaturaMediaC = false,
    double? latitudeGraus,
    bool clearLatitudeGraus = false,
    int? mesReferencia,
    OrigemChuvaSulco? origemChuva,
    MetodoEtcSulco? metodoEtc,
    double? decliveEncostaPercent,
    bool clearDecliveEncostaPercent = false,
    String? orientacaoSulco,
    ProvenienciaSulco? origemGeometria,
    bool? dimensionarComprimentoCriddle,
    double? vazaoReduzidaLs,
    OrigemVazaoReduzida? origemVazaoReduzida,
    bool? fator11Vib,
    double? vazaoEnsaioAvancoLs,
    String? condicoesEnsaioAvanco,
    EnsaioErosaoSulco? ensaioErosao,
    bool clearEnsaioErosao = false,
    double? jornadaDiariaH,
    int? periodoIrrigacaoDias,
    double? tempoMudancaParcelaMin,
    double? perdasConducaoLs,
    ManejoSulco? manejoSulco,
    double? tempoMudancaMin,
    double? cicloSurtirMin,
    double? larguraSulcoM,
    double? profundidadeSulcoM,
    bool clearLarguraSulcoM = false,
    bool clearProfundidadeSulcoM = false,
    SimulationResult? resultado,
    bool? executando,
    String? erro,
    String? mensagemPlanejamento,
  }) {
    return ParametersState(
      metodo: metodo ?? this.metodo,
      tipoSulco: tipoSulco ?? this.tipoSulco,
      comprimento: comprimento ?? this.comprimento,
      desnivelM: desnivelM ?? this.desnivelM,
      distanciaHorizontalM: distanciaHorizontalM ?? this.distanciaHorizontalM,
      desnivelTransversalM: desnivelTransversalM ?? this.desnivelTransversalM,
      distanciaTransversalM:
          distanciaTransversalM ?? this.distanciaTransversalM,
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
      coeficienteAvancoKInformado:
          coeficienteAvancoKInformado ?? this.coeficienteAvancoKInformado,
      expoenteAvancoBInformado:
          expoenteAvancoBInformado ?? this.expoenteAvancoBInformado,
      distanciaReferenciaAvancoM:
          distanciaReferenciaAvancoM ?? this.distanciaReferenciaAvancoM,
      comprimentoMaximoTerrenoM:
          comprimentoMaximoTerrenoM ?? this.comprimentoMaximoTerrenoM,
      origemAvanco: origemAvanco ?? this.origemAvanco,
      metodoCurvaAvanco: metodoCurvaAvanco ?? this.metodoCurvaAvanco,
      pontosEnsaioAvanco: pontosEnsaioAvanco ?? this.pontosEnsaioAvanco,
      origemCurvaInfiltracao:
          origemCurvaInfiltracao ?? this.origemCurvaInfiltracao,
      distanciaEnsaioInfiltracaoM:
          distanciaEnsaioInfiltracaoM ?? this.distanciaEnsaioInfiltracaoM,
      espacamentoEnsaioInfiltracaoM:
          espacamentoEnsaioInfiltracaoM ?? this.espacamentoEnsaioInfiltracaoM,
      medicoesEntradaSaida: medicoesEntradaSaida ?? this.medicoesEntradaSaida,
      hipoteseRecessao: hipoteseRecessao ?? this.hipoteseRecessao,
      medicoesRecessao: medicoesRecessao ?? this.medicoesRecessao,
      distanciaEnsaioIntermediariaM:
          distanciaEnsaioIntermediariaM ?? this.distanciaEnsaioIntermediariaM,
      tempoEnsaioIntermediarioMin:
          tempoEnsaioIntermediarioMin ?? this.tempoEnsaioIntermediarioMin,
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
      nomeCultura: nomeCultura ?? this.nomeCultura,
      kc: kc ?? this.kc,
      espacamentoFileirasM: espacamentoFileirasM ?? this.espacamentoFileirasM,
      espacamentoPlantasM: espacamentoPlantasM ?? this.espacamentoPlantasM,
      precipitacaoEfetivaMmDia:
          precipitacaoEfetivaMmDia ?? this.precipitacaoEfetivaMmDia,
      uccPercentual: uccPercentual ?? this.uccPercentual,
      upmpPercentual: upmpPercentual ?? this.upmpPercentual,
      densidadeAparenteGcm3:
          densidadeAparenteGcm3 ?? this.densidadeAparenteGcm3,
      profundidadeRaizesCm: profundidadeRaizesCm ?? this.profundidadeRaizesCm,
      fracaoAguaDisponivel: fracaoAguaDisponivel ?? this.fracaoAguaDisponivel,
      laminaRequeridaResultado: clearLaminaRequeridaResultado
          ? null
          : laminaRequeridaResultado ?? this.laminaRequeridaResultado,
      projetoSulcoLegado: projetoSulcoLegado ?? this.projetoSulcoLegado,
      origemEntradasSulco: origemEntradasSulco ?? this.origemEntradasSulco,
      curvaInfiltracaoSulco: clearCurvaInfiltracaoSulco
          ? null
          : curvaInfiltracaoSulco ?? this.curvaInfiltracaoSulco,
      etoMmDia: clearEtoMmDia ? null : etoMmDia ?? this.etoMmDia,
      temperaturaMediaC: clearTemperaturaMediaC
          ? null
          : temperaturaMediaC ?? this.temperaturaMediaC,
      latitudeGraus: clearLatitudeGraus
          ? null
          : latitudeGraus ?? this.latitudeGraus,
      mesReferencia: mesReferencia ?? this.mesReferencia,
      origemChuva: origemChuva ?? this.origemChuva,
      metodoEtc: metodoEtc ?? this.metodoEtc,
      decliveEncostaPercent: clearDecliveEncostaPercent
          ? null
          : decliveEncostaPercent ?? this.decliveEncostaPercent,
      orientacaoSulco: orientacaoSulco ?? this.orientacaoSulco,
      origemGeometria: origemGeometria ?? this.origemGeometria,
      dimensionarComprimentoCriddle:
          dimensionarComprimentoCriddle ?? this.dimensionarComprimentoCriddle,
      vazaoReduzidaLs: vazaoReduzidaLs ?? this.vazaoReduzidaLs,
      origemVazaoReduzida: origemVazaoReduzida ?? this.origemVazaoReduzida,
      fator11Vib: fator11Vib ?? this.fator11Vib,
      vazaoEnsaioAvancoLs: vazaoEnsaioAvancoLs ?? this.vazaoEnsaioAvancoLs,
      condicoesEnsaioAvanco:
          condicoesEnsaioAvanco ?? this.condicoesEnsaioAvanco,
      ensaioErosao: clearEnsaioErosao
          ? null
          : ensaioErosao ?? this.ensaioErosao,
      jornadaDiariaH: jornadaDiariaH ?? this.jornadaDiariaH,
      periodoIrrigacaoDias: periodoIrrigacaoDias ?? this.periodoIrrigacaoDias,
      tempoMudancaParcelaMin:
          tempoMudancaParcelaMin ?? this.tempoMudancaParcelaMin,
      perdasConducaoLs: perdasConducaoLs ?? this.perdasConducaoLs,
      manejoSulco: manejoSulco ?? this.manejoSulco,
      tempoMudancaMin: tempoMudancaMin ?? this.tempoMudancaMin,
      cicloSurtirMin: cicloSurtirMin ?? this.cicloSurtirMin,
      larguraSulcoM: clearLarguraSulcoM
          ? null
          : larguraSulcoM ?? this.larguraSulcoM,
      profundidadeSulcoM: clearProfundidadeSulcoM
          ? null
          : profundidadeSulcoM ?? this.profundidadeSulcoM,
      resultado: resultado,
      executando: executando ?? this.executando,
      erro: erro,
      mensagemPlanejamento: mensagemPlanejamento,
    );
  }

  IrrigationParameters toIrrigationParameters() {
    final curva = metodo == MetodoIrrigacao.sulco && !projetoSulcoLegado
        ? entradasSulco.curvaInfiltracao
        : null;
    final convertida = curva?.acumuladaMm();
    return IrrigationParameters(
      entradasProjetoSulco:
          metodo == MetodoIrrigacao.sulco && !projetoSulcoLegado
          ? entradasSulco
          : null,
      projetoFaixa: metodo == MetodoIrrigacao.faixa
          ? BorderProject(
              versao: 0,
              legado: true,
              comprimentoM: comprimento,
              larguraM: larguraOuEspacamento,
              desnivelLongitudinalM: desnivelM,
              baseLongitudinalM: distanciaHorizontalM,
              desnivelTransversalM: desnivelTransversalM,
              baseTransversalM: distanciaTransversalM,
              k: k,
              a: a,
              vibMMin: vib,
              vazaoUnitariaLsM: vazao,
              irnMm: laminaRequerida,
              rugosidadeN: manningN,
              rInicial: sigmaZ,
              tempoAplicacaoLegadoMin: tempoAplicacao,
            )
          : null,
      comprimento: comprimento,
      declividade: declividade,
      declividadeTransversal: declividadeTransversal,
      larguraOuEspacamento: larguraOuEspacamento,
      k: convertida?.k ?? k,
      a: convertida?.a ?? a,
      vib: vib,
      vazao: vazao,
      tempoAplicacao: tempoAplicacao,
      laminaRequerida: laminaRequerida,
      manningN: manningN,
      sigmaZ: sigmaZ,
      texturaSolo: texturaSolo,
      tipoSulco: tipoSulco,
      tempoAvancoMetadeMin: tempoAvancoMetadeMin,
      tempoAvancoFinalMin: tempoAvancoFinalMin,
      coeficienteAvancoK: origemAvanco == OrigemAvanco.estimativa
          ? coeficienteAvancoK
          : null,
      expoenteAvancoB: origemAvanco == OrigemAvanco.estimativa
          ? expoenteAvancoB
          : null,
      distanciaReferenciaAvancoM: distanciaReferenciaAvancoM,
      instanteRecessaoInicioMin: instanteRecessaoInicioMin,
      instanteRecessaoFinalMin: instanteRecessaoFinalMin,
      tipoInundacao: tipoInundacao,
      areaHectares: areaHectares,
      porosidade: porosidade,
      profundidadeCamadaMm: profundidadeCamadaMm,
      condutividadeHidraulicaMmDia: condutividadeHidraulicaMmDia,
      dtaMmCm: dtaMmCm,
      fatorDisponibilidade: fatorDisponibilidade,
      evapotranspiracaoMmDia: evapotranspiracaoCulturaMmDia,
      laminaSuperficialMm: laminaSuperficialMm,
      vazaoDisponivelLps: vazaoDisponivelLps,
      manejoSulco: manejoSulco,
      vazaoReduzidaLs: vazaoReduzidaLs,
      origemVazaoReduzida: origemVazaoReduzida,
      fator11Vib: fator11Vib,
      vazaoEnsaioAvancoLs: vazaoEnsaioAvancoLs,
      condicoesEnsaioAvanco: condicoesEnsaioAvanco,
      ensaioErosao: ensaioErosao,
      tempoMudancaMin: tempoMudancaMin,
      cicloSurtirMin: cicloSurtirMin,
      jornadaDiariaH: jornadaDiariaH,
      periodoIrrigacaoDias: periodoIrrigacaoDias,
      tempoMudancaParcelaMin: tempoMudancaParcelaMin,
      perdasConducaoLs: perdasConducaoLs,
      precipitacaoEfetivaMmDia: precipitacaoEfetivaMmDia,
      nomeCultura: nomeCultura,
      kc: kc,
      espacamentoFileirasM: espacamentoFileirasM,
      espacamentoPlantasM: espacamentoPlantasM,
      larguraSulcoM: larguraSulcoM,
      profundidadeSulcoM: profundidadeSulcoM,
      metodoCurvaAvanco: metodoCurvaAvanco,
      usarEnsaioAvanco: origemAvanco == OrigemAvanco.ensaio,
      medicoesAvanco: pontosEnsaioAvanco
          .map(
            (point) => MedicaoAvanco(
              distanciaM: point.distanciaM,
              tempoMin: point.tempoMin,
            ),
          )
          .toList(),
      origemCurvaInfiltracao: origemCurvaInfiltracao,
      distanciaEnsaioInfiltracaoM: distanciaEnsaioInfiltracaoM,
      espacamentoEnsaioInfiltracaoM: espacamentoEnsaioInfiltracaoM,
      medicoesEntradaSaida: medicoesEntradaSaida,
      hipoteseRecessao: hipoteseRecessao,
      medicoesRecessao: medicoesRecessao,
    );
  }
}

class ParametersController extends StateNotifier<ParametersState> {
  ParametersController() : super(_recalcularLamina(const ParametersState()));

  static ParametersState _recalcularLamina(ParametersState current) {
    if (current.metodo == MetodoIrrigacao.faixa) return current;
    final entradas = current.entradasSulco;
    if (current.metodo == MetodoIrrigacao.sulco &&
        !entradas.podeRecalcularIrrigacao) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
    final etoCalculada = current.metodoEtc == MetodoEtcSulco.blaneyCriddle
        ? _etoBlaneyCriddle(current)
        : current.etoMmDia;
    if (current.metodoEtc == MetodoEtcSulco.blaneyCriddle &&
        etoCalculada == null) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
    final etc = current.evapotranspiracaoCulturaMmDia;
    final demandaLiquida = etc - current.precipitacaoEfetivaMmDia;
    if (demandaLiquida <= 0) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }

    try {
      final resultado = LaminaRequeridaCalculator.calcular(
        uccPercentual: current.uccPercentual,
        upmpPercentual: current.upmpPercentual,
        densidadeGcm3: current.densidadeAparenteGcm3,
        profundidadeRaizesCm: current.profundidadeRaizesCm,
        fracaoAguaDisponivel: current.fracaoAguaDisponivel,
        demandaLiquidaMmDia: demandaLiquida,
        etoMmDia: etoCalculada,
        etcMmDia: etc,
        precipitacaoEfetivaMmDia: current.precipitacaoEfetivaMmDia,
      );
      return current.copyWith(
        laminaRequerida: resultado.irnMm,
        laminaRequeridaResultado: resultado,
      );
    } on ArgumentError {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
  }

  static double? _etoBlaneyCriddle(ParametersState state) {
    final temperatura = state.temperaturaMediaC;
    final latitude = state.latitudeGraus;
    final mes = state.mesReferencia;
    if (temperatura == null || latitude == null || mes == null) return null;
    try {
      return BlaneyCriddle.etoMmDia(
        temperaturaMediaC: temperatura,
        latitudeGraus: latitude,
        mes: mes,
      );
    } on ArgumentError {
      return null;
    }
  }

  void _redimensionarCriddleSeSelecionado() {
    if (!state.dimensionarComprimentoCriddle) return;
    if (state.laminaRequeridaResultado == null) {
      if (state.origemGeometria == ProvenienciaSulco.calculado) {
        state = state.copyWith(
          origemGeometria: ProvenienciaSulco.naoInformado,
          mensagemPlanejamento: null,
        );
      }
      return;
    }
    dimensionarComprimentoCriddle();
  }

  void setMetodo(MetodoIrrigacao metodo) {
    final next = switch (metodo) {
      MetodoIrrigacao.sulco => ParametersState(
        metodo: metodo,
        comprimento: 200,
        desnivelM: 1,
        distanciaHorizontalM: 200,
        larguraOuEspacamento: 0.9,
        k: 2.83,
        a: 0.554,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      ),
      MetodoIrrigacao.faixa => ParametersState(
        metodo: metodo,
        comprimento: 400,
        desnivelM: 0.8,
        distanciaHorizontalM: 400,
        larguraOuEspacamento: 10,
        k: 0.0034,
        a: 0.45,
        vib: 0.0001,
        vazao: 3.33,
        laminaRequerida: 56,
        manningN: 0.04,
        sigmaZ: 0.66,
      ),
      MetodoIrrigacao.inundacao => ParametersState(
        metodo: metodo,
        comprimento: 100,
        desnivelM: 0.05,
        distanciaHorizontalM: 100,
        larguraOuEspacamento: 20,
        distanciaTransversalM: 20,
        vazao: 100,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 45,
      ),
    };
    state = _recalcularLamina(next);
  }

  void setTipoSulco(TipoSulco tipo) {
    final defaults = _getDefaultsForTipoSulco(tipo);
    final b =
        (math.log(
          defaults.tempoAvancoMetadeMin / defaults.tempoAvancoFinalMin,
        ) /
        math.log(0.5));
    final k = defaults.tempoAvancoFinalMin / math.pow(defaults.comprimento, b);
    state = _recalcularLamina(
      state.copyWith(
        tipoSulco: tipo,
        comprimento: defaults.comprimento,
        larguraOuEspacamento: defaults.larguraOuEspacamento,
        vazao: defaults.vazao,
        tempoAplicacao: defaults.tempoAplicacao,
        laminaRequerida: defaults.laminaRequerida,
        tempoAvancoMetadeMin: defaults.tempoAvancoMetadeMin,
        tempoAvancoFinalMin: defaults.tempoAvancoFinalMin,
        coeficienteAvancoKInformado: k,
        expoenteAvancoBInformado: b,
        distanciaReferenciaAvancoM: defaults.comprimento,
      ),
    );
  }

  ParametersState _getDefaultsForTipoSulco(TipoSulco tipo) {
    return switch (tipo) {
      TipoSulco.sulcos_comuns => const ParametersState(
        comprimento: 200,
        larguraOuEspacamento: 0.9,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      ),
      TipoSulco.sulcos_contorno => const ParametersState(
        comprimento: 110,
        larguraOuEspacamento: 0.9,
        vazao: 0.8,
        tempoAplicacao: 120,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 25,
        tempoAvancoFinalMin: 70,
      ),
      TipoSulco.sulcos_corrugados => const ParametersState(
        comprimento: 100,
        larguraOuEspacamento: 0.6,
        vazao: 0.3,
        tempoAplicacao: 90,
        laminaRequerida: 30,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 45,
      ),
      TipoSulco.sulcos_nivel_tabuleiros => const ParametersState(
        comprimento: 80,
        larguraOuEspacamento: 1.0,
        vazao: 0.5,
        tempoAplicacao: 100,
        laminaRequerida: 50,
        tempoAvancoMetadeMin: 20,
        tempoAvancoFinalMin: 60,
      ),
      TipoSulco.sulcos_nivel_fechados => const ParametersState(
        comprimento: 50,
        larguraOuEspacamento: 1.2,
        vazao: 0.6,
        tempoAplicacao: 80,
        laminaRequerida: 45,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 40,
      ),
      TipoSulco.sulcos_em_zigue_zague => const ParametersState(
        comprimento: 100,
        larguraOuEspacamento: 0.8,
        vazao: 0.7,
        tempoAplicacao: 110,
        laminaRequerida: 40,
        tempoAvancoMetadeMin: 20,
        tempoAvancoFinalMin: 55,
      ),
    };
  }

  void setTipoInundacao(TipoInundacao tipo) {
    state = state.copyWith(tipoInundacao: tipo);
  }

  void loadFromParams(IrrigationParameters params) {
    final projeto = params.entradasProjetoSulco;
    // Cenários legados preservam a inclinação, não recuperam uma base medida.
    final distancia = projeto?.baseLongitudinalM ?? 100.0;
    final distanciaReferenciaAvanco =
        params.distanciaReferenciaAvancoM ?? params.comprimento;
    final bAvanco =
        params.expoenteAvancoB ??
        (params.tempoAvancoMetadeMin > 0 && params.tempoAvancoFinalMin > 0
            ? -math.log(
                    params.tempoAvancoMetadeMin / params.tempoAvancoFinalMin,
                  ) /
                  math.ln2
            : 1.3625700793847084);
    final kAvanco =
        params.coeficienteAvancoK ??
        (params.comprimento > 0
            ? params.tempoAvancoFinalMin / math.pow(params.comprimento, bAvanco)
            : 0.0659064448778603);
    final pontosAvanco = params.medicoesAvanco
        .map(
          (point) => PontoEnsaio(
            distanciaM: point.distanciaM,
            tempoMin: point.tempoMin,
          ),
        )
        .toList();
    final desnivel =
        projeto?.desnivelLongitudinalM ?? params.declividade * distancia;
    ProvenienciaSulco origem(String key, double? value) =>
        projeto?.origens[key] ??
        (value == null
            ? ProvenienciaSulco.naoInformado
            : ProvenienciaSulco.informado);
    final origens = <String, ProvenienciaSulco>{
      'uccPercentual': origem('uccPercentual', projeto?.uccPercentual),
      'upmpPercentual': origem('upmpPercentual', projeto?.upmpPercentual),
      'densidadeAparenteGcm3': origem(
        'densidadeAparenteGcm3',
        projeto?.densidadeAparenteGcm3,
      ),
      'profundidadeRaizesCm': origem(
        'profundidadeRaizesCm',
        projeto?.profundidadeRadicularCm,
      ),
      'fracaoAguaDisponivel': origem(
        'fracaoAguaDisponivel',
        projeto?.fracaoDisponivel,
      ),
      'evapotranspiracaoMmDia': origem(
        'evapotranspiracaoMmDia',
        projeto?.etcAdotadaMmDia,
      ),
      'kc': origem('kc', projeto?.kc),
      'precipitacaoEfetivaMmDia': origem(
        'precipitacaoEfetivaMmDia',
        projeto?.precipitacaoMmDia,
      ),
      'k': origem('k', projeto?.curvaInfiltracao?.coeficiente),
      'a': origem('a', projeto?.curvaInfiltracao?.expoente),
    };
    final distanciaTransversal = 10.0;
    state = _recalcularLamina(
      state.copyWith(
        comprimento: params.comprimento,
        desnivelM: desnivel,
        distanciaHorizontalM: distancia,
        desnivelTransversalM:
            params.declividadeTransversal * distanciaTransversal,
        distanciaTransversalM: distanciaTransversal,
        larguraOuEspacamento: params.larguraOuEspacamento,
        k: params.k,
        a: params.a,
        projetoSulcoLegado: projeto == null,
        origemEntradasSulco: origens,
        curvaInfiltracaoSulco: projeto?.curvaInfiltracao,
        clearCurvaInfiltracaoSulco: projeto?.curvaInfiltracao == null,
        etoMmDia: projeto?.etoMmDia,
        clearEtoMmDia: projeto?.etoMmDia == null,
        temperaturaMediaC: projeto?.temperaturaMediaC,
        clearTemperaturaMediaC: projeto?.temperaturaMediaC == null,
        latitudeGraus: projeto?.latitudeGraus,
        clearLatitudeGraus: projeto?.latitudeGraus == null,
        mesReferencia: projeto?.mesReferencia,
        origemChuva: projeto?.origemChuva ?? OrigemChuvaSulco.naoInformada,
        metodoEtc: projeto?.metodoEtc ?? MetodoEtcSulco.adotada,
        decliveEncostaPercent: projeto?.decliveEncostaPercent,
        clearDecliveEncostaPercent: projeto?.decliveEncostaPercent == null,
        orientacaoSulco: projeto?.orientacaoSulco ?? '',
        origemGeometria:
            projeto?.origemGeometria ?? ProvenienciaSulco.naoInformado,
        dimensionarComprimentoCriddle:
            projeto?.dimensionarComprimentoCriddle == true ||
            projeto?.origemGeometria == ProvenienciaSulco.calculado,
        vib: params.vib,
        vazao: params.vazao,
        tempoAplicacao: params.tempoAplicacao,
        laminaRequerida: params.laminaRequerida,
        uccPercentual: projeto?.uccPercentual ?? state.uccPercentual,
        upmpPercentual: projeto?.upmpPercentual ?? state.upmpPercentual,
        densidadeAparenteGcm3:
            projeto?.densidadeAparenteGcm3 ?? state.densidadeAparenteGcm3,
        profundidadeRaizesCm:
            projeto?.profundidadeRadicularCm ?? state.profundidadeRaizesCm,
        fracaoAguaDisponivel:
            projeto?.fracaoDisponivel ?? state.fracaoAguaDisponivel,
        manningN: params.manningN,
        sigmaZ: params.sigmaZ,
        texturaSolo: params.texturaSolo,
        tipoSulco: params.tipoSulco,
        tempoAvancoMetadeMin: params.tempoAvancoMetadeMin,
        tempoAvancoFinalMin: params.tempoAvancoFinalMin,
        coeficienteAvancoKInformado: kAvanco,
        expoenteAvancoBInformado: bAvanco,
        distanciaReferenciaAvancoM: distanciaReferenciaAvanco,
        instanteRecessaoInicioMin: params.instanteRecessaoInicioMin,
        instanteRecessaoFinalMin: params.instanteRecessaoFinalMin,
        tipoInundacao: params.tipoInundacao,
        areaHectares: params.areaHectares,
        porosidade: params.porosidade,
        profundidadeCamadaMm: params.profundidadeCamadaMm,
        condutividadeHidraulicaMmDia: params.condutividadeHidraulicaMmDia,
        dtaMmCm: params.dtaMmCm,
        fatorDisponibilidade: params.fatorDisponibilidade,
        evapotranspiracaoMmDia:
            projeto?.etcAdotadaMmDia ?? params.evapotranspiracaoMmDia,
        laminaSuperficialMm: params.laminaSuperficialMm,
        vazaoDisponivelLps: params.vazaoDisponivelLps,
        manejoSulco: params.manejoSulco,
        vazaoReduzidaLs: params.vazaoReduzidaLs,
        tempoMudancaMin: params.tempoMudancaMin,
        cicloSurtirMin: params.cicloSurtirMin,
        jornadaDiariaH: params.jornadaDiariaH,
        periodoIrrigacaoDias: params.periodoIrrigacaoDias,
        tempoMudancaParcelaMin: params.tempoMudancaParcelaMin,
        perdasConducaoLs: params.perdasConducaoLs,
        precipitacaoEfetivaMmDia:
            projeto?.precipitacaoMmDia ?? params.precipitacaoEfetivaMmDia,
        nomeCultura: params.nomeCultura,
        kc: projeto?.kc ?? params.kc,
        espacamentoFileirasM: params.espacamentoFileirasM,
        espacamentoPlantasM: params.espacamentoPlantasM,
        larguraSulcoM: params.larguraSulcoM,
        profundidadeSulcoM: params.profundidadeSulcoM,
        origemCurvaInfiltracao: params.origemCurvaInfiltracao,
        distanciaEnsaioInfiltracaoM: params.distanciaEnsaioInfiltracaoM,
        espacamentoEnsaioInfiltracaoM: params.espacamentoEnsaioInfiltracaoM,
        medicoesEntradaSaida: params.medicoesEntradaSaida,
        hipoteseRecessao: params.hipoteseRecessao,
        medicoesRecessao: params.medicoesRecessao,
        pontosEnsaioAvanco: pontosAvanco,
        metodoCurvaAvanco: params.metodoCurvaAvanco,
        origemAvanco: params.usarEnsaioAvanco
            ? OrigemAvanco.ensaio
            : OrigemAvanco.estimativa,
        origemVazaoReduzida: params.origemVazaoReduzida,
        fator11Vib: params.fator11Vib,
        vazaoEnsaioAvancoLs: params.vazaoEnsaioAvancoLs,
        condicoesEnsaioAvanco: params.condicoesEnsaioAvanco ?? '',
        ensaioErosao: params.ensaioErosao,
        clearEnsaioErosao: params.ensaioErosao == null,
      ),
    );
  }

  void updateField({String? campo, String? valor}) {
    if (campo == null || valor == null) return;
    final atualCurva =
        state.curvaInfiltracaoSulco ?? state.entradasSulco.curvaInfiltracao;
    if ({
          'curvaEspacamentoM',
          'curvaVibMmHora',
          'curvaTempoMin',
          'curvaTempoMax',
        }.contains(campo) &&
        atualCurva != null) {
      final number = double.tryParse(valor.replaceAll(',', '.'));
      final nova = switch (campo) {
        'curvaEspacamentoM' => atualCurva.copyWith(
          espacamentoConversaoM: number,
          clearEspacamento: number == null,
        ),
        'curvaVibMmHora' => atualCurva.copyWith(
          vibMmHora: number,
          clearVib: number == null,
        ),
        'curvaTempoMin' => atualCurva.copyWith(
          tempoMinCalibrado: number,
          clearTempoMin: number == null,
        ),
        _ => atualCurva.copyWith(
          tempoMaxCalibrado: number,
          clearTempoMax: number == null,
        ),
      };
      state = state.copyWith(
        curvaInfiltracaoSulco: nova,
        projetoSulcoLegado: false,
      );
      _redimensionarCriddleSeSelecionado();
      return;
    }
    if ({
      'etoMmDia',
      'decliveEncostaPercent',
      'temperaturaMediaC',
      'latitudeGraus',
    }.contains(campo)) {
      final number = double.tryParse(valor.replaceAll(',', '.'));
      state = switch (campo) {
        'etoMmDia' => state.copyWith(
          etoMmDia: number,
          clearEtoMmDia: number == null,
          projetoSulcoLegado: false,
          origemEntradasSulco: {
            ...state.origemEntradasSulco,
            'etoMmDia': number == null
                ? ProvenienciaSulco.naoInformado
                : ProvenienciaSulco.informado,
          },
        ),
        'temperaturaMediaC' => state.copyWith(
          temperaturaMediaC: number,
          clearTemperaturaMediaC: number == null,
          projetoSulcoLegado: false,
        ),
        'latitudeGraus' => state.copyWith(
          latitudeGraus: number,
          clearLatitudeGraus: number == null,
          projetoSulcoLegado: false,
        ),
        _ => state.copyWith(
          decliveEncostaPercent: number,
          clearDecliveEncostaPercent: number == null,
          projetoSulcoLegado: false,
        ),
      };
      if (campo != 'decliveEncostaPercent') {
        state = _recalcularLamina(state);
        _redimensionarCriddleSeSelecionado();
      }
      return;
    }
    if (campo == 'larguraSulcoM' || campo == 'profundidadeSulcoM') {
      final parsedOptional = double.tryParse(valor.replaceAll(',', '.'));
      state = campo == 'larguraSulcoM'
          ? state.copyWith(
              larguraSulcoM: parsedOptional,
              clearLarguraSulcoM: parsedOptional == null,
            )
          : state.copyWith(
              profundidadeSulcoM: parsedOptional,
              clearProfundidadeSulcoM: parsedOptional == null,
            );
      return;
    }
    final parsed = double.tryParse(valor.replaceAll(',', '.'));
    if (parsed == null) return;

    var recalcularLamina = false;
    final comprimentoAnterior = state.comprimento;
    switch (campo) {
      case 'comprimento':
        state = state.copyWith(
          comprimento: parsed,
          origemGeometria: ProvenienciaSulco.medido,
          dimensionarComprimentoCriddle: false,
        );
      case 'distanciaReferenciaAvancoM':
        state = state.copyWith(distanciaReferenciaAvancoM: parsed);
      case 'desnivelM':
        state = state.copyWith(desnivelM: parsed);
      case 'distanciaHorizontalM':
        state = state.copyWith(distanciaHorizontalM: parsed);
      case 'desnivelTransversalM':
        state = state.copyWith(desnivelTransversalM: parsed);
      case 'distanciaTransversalM':
        state = state.copyWith(distanciaTransversalM: parsed);
      case 'larguraOuEspacamento':
        state = state.copyWith(larguraOuEspacamento: parsed);
      case 'k':
        state = state.copyWith(k: parsed);
        if (atualCurva?.tipo == TipoCurvaInfiltracaoSulco.acumulada &&
            atualCurva?.base == BaseInfiltracaoSulco.milimetros) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva!.copyWith(
              coeficiente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'a':
        state = state.copyWith(a: parsed);
        if (atualCurva?.tipo == TipoCurvaInfiltracaoSulco.acumulada &&
            atualCurva?.base == BaseInfiltracaoSulco.milimetros) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva!.copyWith(
              expoente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'curvaCoeficiente':
        if (atualCurva != null) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva.copyWith(
              coeficiente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'curvaExpoente':
        if (atualCurva != null) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva.copyWith(
              expoente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'vib':
        state = state.copyWith(vib: parsed);
      case 'vazao':
        state = state.copyWith(vazao: parsed);
      case 'tempoAplicacao':
        state = state.copyWith(tempoAplicacao: parsed);
      case 'manningN':
        state = state.copyWith(manningN: parsed);
      case 'sigmaZ':
        state = state.copyWith(sigmaZ: parsed);
      case 'tempoAvancoMetadeMin':
        state = state.copyWith(tempoAvancoMetadeMin: parsed);
      case 'tempoAvancoFinalMin':
        state = state.copyWith(tempoAvancoFinalMin: parsed);
      case 'coeficienteAvancoK':
        state = state.copyWith(coeficienteAvancoKInformado: parsed);
      case 'expoenteAvancoB':
        state = state.copyWith(
          coeficienteAvancoKInformado: state.coeficienteAvancoK,
          expoenteAvancoBInformado: parsed,
        );
      case 'comprimentoMaximoTerrenoM':
        state = state.copyWith(comprimentoMaximoTerrenoM: parsed);
      case 'distanciaEnsaioIntermediariaM':
        state = state.copyWith(distanciaEnsaioIntermediariaM: parsed);
      case 'tempoEnsaioIntermediarioMin':
        state = state.copyWith(tempoEnsaioIntermediarioMin: parsed);
      case 'distanciaEnsaioInfiltracaoM':
        state = state.copyWith(distanciaEnsaioInfiltracaoM: parsed);
      case 'espacamentoEnsaioInfiltracaoM':
        state = state.copyWith(espacamentoEnsaioInfiltracaoM: parsed);
      case 'instanteRecessaoInicioMin':
        state = state.copyWith(instanteRecessaoInicioMin: parsed);
      case 'instanteRecessaoFinalMin':
        state = state.copyWith(instanteRecessaoFinalMin: parsed);
      case 'areaHectares':
        state = state.copyWith(areaHectares: parsed);
      case 'porosidade':
        state = state.copyWith(porosidade: parsed);
      case 'profundidadeCamadaMm':
        state = state.copyWith(profundidadeCamadaMm: parsed);
      case 'condutividadeHidraulicaMmDia':
        state = state.copyWith(condutividadeHidraulicaMmDia: parsed);
      case 'dtaMmCm':
        state = state.copyWith(dtaMmCm: parsed);
      case 'fatorDisponibilidade':
        state = state.copyWith(fatorDisponibilidade: parsed);
      case 'evapotranspiracaoMmDia':
        state = state.copyWith(evapotranspiracaoMmDia: parsed);
        recalcularLamina = true;
      case 'laminaSuperficialMm':
        state = state.copyWith(laminaSuperficialMm: parsed);
      case 'vazaoDisponivelLps':
        state = state.copyWith(vazaoDisponivelLps: parsed);
      case 'kc':
        state = state.copyWith(kc: parsed);
        if (state.metodoEtc == MetodoEtcSulco.etoVezesKc ||
            state.metodoEtc == MetodoEtcSulco.blaneyCriddle) {
          recalcularLamina = true;
        }
      case 'espacamentoFileirasM':
        state = state.copyWith(espacamentoFileirasM: parsed);
      case 'espacamentoPlantasM':
        state = state.copyWith(espacamentoPlantasM: parsed);
      case 'precipitacaoEfetivaMmDia':
        state = state.copyWith(precipitacaoEfetivaMmDia: parsed);
        recalcularLamina = true;
      case 'uccPercentual':
        state = state.copyWith(uccPercentual: parsed);
        recalcularLamina = true;
      case 'upmpPercentual':
        state = state.copyWith(upmpPercentual: parsed);
        recalcularLamina = true;
      case 'densidadeAparenteGcm3':
        state = state.copyWith(densidadeAparenteGcm3: parsed);
        recalcularLamina = true;
      case 'profundidadeRaizesCm':
        state = state.copyWith(profundidadeRaizesCm: parsed);
        recalcularLamina = true;
      case 'fracaoAguaDisponivel':
        state = state.copyWith(fracaoAguaDisponivel: parsed);
        recalcularLamina = true;
      case 'vazaoReduzidaLs':
        state = state.copyWith(vazaoReduzidaLs: parsed);
      case 'vazaoEnsaioAvancoLs':
        state = state.copyWith(vazaoEnsaioAvancoLs: parsed);
      case 'jornadaDiariaH':
        state = state.copyWith(jornadaDiariaH: parsed);
      case 'periodoIrrigacaoDias':
        if (parsed != parsed.truncateToDouble()) return;
        state = state.copyWith(periodoIrrigacaoDias: parsed.toInt());
      case 'tempoMudancaParcelaMin':
        state = state.copyWith(tempoMudancaParcelaMin: parsed);
      case 'perdasConducaoLs':
        state = state.copyWith(perdasConducaoLs: parsed);
      case 'tempoMudancaMin':
        state = state.copyWith(tempoMudancaMin: parsed);
      case 'cicloSurtirMin':
        state = state.copyWith(cicloSurtirMin: parsed);
    }
    const tracked = {
      'uccPercentual',
      'upmpPercentual',
      'densidadeAparenteGcm3',
      'profundidadeRaizesCm',
      'fracaoAguaDisponivel',
      'evapotranspiracaoMmDia',
      'precipitacaoEfetivaMmDia',
      'kc',
      'k',
      'a',
    };
    if (state.metodo == MetodoIrrigacao.sulco && tracked.contains(campo)) {
      state = state.copyWith(
        projetoSulcoLegado: false,
        origemEntradasSulco: {
          ...state.origemEntradasSulco,
          campo: ProvenienciaSulco.informado,
        },
        origemChuva: campo == 'precipitacaoEfetivaMmDia'
            ? OrigemChuvaSulco.efetiva
            : null,
      );
    }
    if (state.metodo == MetodoIrrigacao.sulco &&
        (campo == 'k' || campo == 'a') &&
        atualCurva == null &&
        state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada) {
      state = state.copyWith(
        curvaInfiltracaoSulco: CurvaInfiltracaoSulco(
          tipo: TipoCurvaInfiltracaoSulco.acumulada,
          base: BaseInfiltracaoSulco.milimetros,
          coeficiente: state.k,
          expoente: state.a,
          proveniencia: ProvenienciaSulco.informado,
        ),
      );
    }
    if (campo == 'comprimento' ||
        campo == 'coeficienteAvancoK' ||
        campo == 'expoenteAvancoB') {
      if (campo == 'comprimento' &&
          (state.distanciaReferenciaAvancoM - comprimentoAnterior).abs() <
              1e-9) {
        state = state.copyWith(distanciaReferenciaAvancoM: state.comprimento);
      }
      state = _sincronizarAvancoEstimado(state);
    }
    if (recalcularLamina) {
      state = _recalcularLamina(state);
    }
    _redimensionarCriddleSeSelecionado();
  }

  ParametersState _sincronizarAvancoEstimado(ParametersState source) {
    if (source.origemAvanco != OrigemAvanco.estimativa ||
        source.comprimento <= 0 ||
        source.coeficienteAvancoK <= 0 ||
        source.expoenteAvancoB <= 0) {
      return source;
    }
    final curve = AdvanceCurveResult(
      k: source.coeficienteAvancoK,
      b: source.expoenteAvancoB,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: const [],
    );
    return source.copyWith(
      tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento / 2,
        parametros: curve,
      ),
      tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento,
        parametros: curve,
      ),
    );
  }

  void setTexturaSolo(TexturaSolo textura) {
    state = state.copyWith(texturaSolo: textura);
  }

  void setNomeCultura(String nome) {
    state = state.copyWith(nomeCultura: nome);
  }

  void setManejoSulco(ManejoSulco manejo) {
    state = state.copyWith(manejoSulco: manejo);
  }

  void setOrigemVazaoReduzida(OrigemVazaoReduzida origem) =>
      state = state.copyWith(
        origemVazaoReduzida: origem,
        vazaoReduzidaLs: origem == OrigemVazaoReduzida.informada
            ? state.vazaoReduzidaLs
            : 0,
      );

  void setFator11Vib(bool value) => state = state.copyWith(fator11Vib: value);

  void setCondicoesEnsaioAvanco(String value) {
    state = state.copyWith(condicoesEnsaioAvanco: value);
    _redimensionarCriddleSeSelecionado();
  }

  void setEnsaioErosao(EnsaioErosaoSulco? value) => state = state.copyWith(
    ensaioErosao: value,
    clearEnsaioErosao: value == null,
  );

  void setOrigemAvanco(OrigemAvanco origem) {
    state = _sincronizarAvancoEstimado(
      state.copyWith(origemAvanco: origem, mensagemPlanejamento: null),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setPontosEnsaioAvanco(List<PontoEnsaio> pontos) {
    state = state.copyWith(pontosEnsaioAvanco: List.unmodifiable(pontos));
    _redimensionarCriddleSeSelecionado();
  }

  void setMetodoCurvaAvanco(MetodoCurvaAvanco method) {
    state = state.copyWith(metodoCurvaAvanco: method);
    _redimensionarCriddleSeSelecionado();
  }

  void setOrigemCurvaInfiltracao(OrigemCurvaInfiltracao origem) {
    state = state.copyWith(origemCurvaInfiltracao: origem);
    _redimensionarCriddleSeSelecionado();
  }

  void setMetodoEtc(MetodoEtcSulco metodo) {
    state = _recalcularLamina(
      state.copyWith(metodoEtc: metodo, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setMesReferencia(int mes) {
    state = _recalcularLamina(
      state.copyWith(mesReferencia: mes, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setOrigemChuva(OrigemChuvaSulco origem) {
    state = _recalcularLamina(
      state.copyWith(origemChuva: origem, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setOrientacaoSulco(String value) =>
      state = state.copyWith(orientacaoSulco: value, projetoSulcoLegado: false);

  void setOrigemGeometria(ProvenienciaSulco origem) => state = state.copyWith(
    origemGeometria: origem,
    dimensionarComprimentoCriddle: false,
    projetoSulcoLegado: false,
  );

  void setDimensionarComprimentoCriddle(bool ativo) {
    state = state.copyWith(
      dimensionarComprimentoCriddle: ativo,
      origemGeometria: ativo ? state.origemGeometria : ProvenienciaSulco.medido,
      mensagemPlanejamento: null,
    );
    _redimensionarCriddleSeSelecionado();
  }

  void configurarCurvaInfiltracao({
    TipoCurvaInfiltracaoSulco? tipo,
    BaseInfiltracaoSulco? base,
  }) {
    final curva =
        state.curvaInfiltracaoSulco ??
        state.entradasSulco.curvaInfiltracao ??
        CurvaInfiltracaoSulco(
          tipo: TipoCurvaInfiltracaoSulco.acumulada,
          base: BaseInfiltracaoSulco.milimetros,
          coeficiente: state.k,
          expoente: state.a,
          proveniencia: ProvenienciaSulco.ilustrativo,
        );
    state = state.copyWith(
      curvaInfiltracaoSulco: curva.copyWith(
        tipo: tipo,
        base: base,
        proveniencia: ProvenienciaSulco.informado,
        clearEspacamento: base == BaseInfiltracaoSulco.litrosPorMetro,
      ),
      projetoSulcoLegado: false,
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setDataCurvaInfiltracao(DateTime? data) {
    final curva = state.entradasSulco.curvaInfiltracao;
    if (curva != null) {
      state = state.copyWith(
        curvaInfiltracaoSulco: curva.copyWith(
          dataEnsaio: data,
          clearData: data == null,
        ),
        projetoSulcoLegado: false,
      );
      _redimensionarCriddleSeSelecionado();
    }
  }

  void setMedicoesEntradaSaida(List<MedicaoEntradaSaida> points) {
    state = state.copyWith(medicoesEntradaSaida: List.unmodifiable(points));
    _redimensionarCriddleSeSelecionado();
  }

  void setHipoteseRecessao(HipoteseRecessao hipotese) {
    state = state.copyWith(hipoteseRecessao: hipotese);
    _redimensionarCriddleSeSelecionado();
  }

  void setMedicoesRecessao(List<MedicaoRecessao> points) {
    state = state.copyWith(medicoesRecessao: List.unmodifiable(points));
    _redimensionarCriddleSeSelecionado();
  }

  String? validarEnsaio() {
    if (state.metodo != MetodoIrrigacao.sulco) return null;
    if (state.origemAvanco == OrigemAvanco.estimativa) {
      if (!state.coeficienteAvancoK.isFinite ||
          state.coeficienteAvancoK <= 0 ||
          !state.expoenteAvancoB.isFinite ||
          state.expoenteAvancoB <= 0 ||
          !state.distanciaReferenciaAvancoM.isFinite ||
          state.distanciaReferenciaAvancoM <= 0) {
        return 'Informe k, X e b positivos para Tx = k·xᵇ.';
      }
      return null;
    }
    if (state.pontosEnsaioAvanco.length < 3) {
      return 'Informe pelo menos duas estacas medidas, além da origem automática.';
    }
    final erros = AdvanceCurveModel.validarPontos(state.pontosEnsaioAvanco);
    if (erros.isNotEmpty) return erros.join('; ');
    if (state.vazaoEnsaioAvancoLs == null ||
        !state.vazaoEnsaioAvancoLs!.isFinite ||
        state.vazaoEnsaioAvancoLs! <= 0 ||
        state.condicoesEnsaioAvanco?.trim().isEmpty != false) {
      return 'Informe vazão e condições do ensaio de avanço medido.';
    }
    if ((state.vazaoEnsaioAvancoLs! - state.vazao).abs() > 1e-8) {
      return 'A vazão do ensaio de avanço difere da vazão de projeto; faça novo ensaio.';
    }
    try {
      _curvaAvancoDaOrigem(state);
      return null;
    } on ArgumentError catch (error) {
      return error.message.toString();
    }
  }

  AdvanceCurveResult _curvaAvancoDaOrigem(ParametersState source) {
    if (source.origemAvanco == OrigemAvanco.ensaio) {
      return source.metodoCurvaAvanco == MetodoCurvaAvanco.minimosQuadrados
          ? AdvanceCurveModel.ajustarMinimosQuadrados(source.pontosEnsaioAvanco)
          : AdvanceCurveModel.ajustarDoisPontosPorEstacas(
              source.pontosEnsaioAvanco,
            );
    }
    if (source.coeficienteAvancoK <= 0 ||
        source.expoenteAvancoB <= 0 ||
        !source.coeficienteAvancoK.isFinite ||
        !source.expoenteAvancoB.isFinite) {
      throw ArgumentError('k e b da curva de avanço devem ser positivos.');
    }
    return AdvanceCurveResult(
      k: source.coeficienteAvancoK,
      b: source.expoenteAvancoB,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: const [],
    );
  }

  /// Dimensiona o sulco pela regra prática de Criddle: Ta(L) = To / 4.
  /// To vem da inversa da curva acumulada para a IRN; a curva de avanço
  /// ajustada ao ensaio é invertida e limitada ao domínio das estacas medidas.
  void dimensionarComprimentoCriddle() {
    if (state.metodo != MetodoIrrigacao.sulco) return;
    if (!state.dimensionarComprimentoCriddle) {
      state = state.copyWith(dimensionarComprimentoCriddle: true);
    }
    try {
      final irn =
          state.laminaRequeridaResultado?.irnMm ?? state.laminaRequerida;
      if (!irn.isFinite || irn <= 0) {
        throw const FormatException('Informe uma IRN positiva.');
      }

      final infiltracao =
          state.curvaInfiltracaoSulco?.acumuladaMm() ??
          (k: state.k, a: state.a);
      if (!infiltracao.k.isFinite ||
          infiltracao.k <= 0 ||
          !infiltracao.a.isFinite ||
          infiltracao.a <= 0) {
        throw const FormatException(
          'Informe uma curva de infiltração acumulada válida para calcular To.',
        );
      }
      final to = math.pow(irn / infiltracao.k, 1 / infiltracao.a).toDouble();
      if (!to.isFinite || to <= 0) {
        throw const FormatException('Não foi possível calcular To pela IRN.');
      }
      final avisoInfiltracao = state.curvaInfiltracaoSulco
          ?.avisoParaOportunidade(to, menorTempoMin: to);
      final taAlvo = to / 4;
      double comprimento;
      AdvanceCurveResult? curva;
      if (state.origemAvanco == OrigemAvanco.ensaio) {
        final erroEnsaio = validarEnsaio();
        if (erroEnsaio != null) throw FormatException(erroEnsaio);
        final pontos = [...state.pontosEnsaioAvanco]
          ..sort((a, b) => a.distanciaM.compareTo(b.distanciaM));
        if (taAlvo > pontos.last.tempoMin) {
          throw FormatException(
            'Ta alvo (${taAlvo.toStringAsFixed(2)} min) excede o último tempo '
            'medido (${pontos.last.tempoMin.toStringAsFixed(2)} min); '
            'o ensaio não cobre o comprimento necessário.',
          );
        }
        final curvaMedida = _curvaAvancoDaOrigem(state);
        comprimento = AdvanceCurveModel.distanciaEmTempo(
          tempoMin: taAlvo,
          parametros: curvaMedida,
        );
        if (comprimento < pontos.first.distanciaM ||
            comprimento > pontos.last.distanciaM) {
          throw const FormatException(
            'O comprimento calculado fica fora do intervalo coberto pelas estacas.',
          );
        }
      } else {
        curva = _curvaAvancoDaOrigem(state);
        comprimento = AdvanceCurveModel.distanciaEmTempo(
          tempoMin: taAlvo,
          parametros: curva,
        );
      }
      if (!comprimento.isFinite || comprimento <= 0) {
        throw const FormatException('O comprimento calculado não é válido.');
      }
      if (comprimento > state.comprimentoMaximoTerrenoM) {
        throw FormatException(
          'Criddle resulta em ${comprimento.toStringAsFixed(1)} m, acima do '
          'limite informado para o terreno (${state.comprimentoMaximoTerrenoM.toStringAsFixed(1)} m). '
          'Ajuste o limite ou escolha outro critério; nenhum comprimento foi alterado.',
        );
      }
      final advance = state.origemAvanco == OrigemAvanco.ensaio
          ? _curvaAvancoDaOrigem(state)
          : curva!;
      final avancoMetade = AdvanceCurveModel.tempoAvanco(
        distanciaM: comprimento / 2,
        parametros: advance,
      );
      final avancoFinal = state.origemAvanco == OrigemAvanco.ensaio
          ? taAlvo
          : AdvanceCurveModel.tempoAvanco(
              distanciaM: comprimento,
              parametros: advance,
            );
      state = state.copyWith(
        comprimento: comprimento,
        origemGeometria: ProvenienciaSulco.calculado,
        tempoAplicacao: to,
        tempoAvancoMetadeMin: avancoMetade,
        tempoAvancoFinalMin: avancoFinal,
        distanciaReferenciaAvancoM: comprimento,
        distanciaEnsaioIntermediariaM: comprimento / 2,
        tempoEnsaioIntermediarioMin: avancoMetade,
        mensagemPlanejamento:
            'Comprimento dimensionado pela regra prática de Criddle: '
            'IRN=${irn.toStringAsFixed(2)} mm, To=${to.toStringAsFixed(2)} min, '
            'Ta alvo=To/4=${taAlvo.toStringAsFixed(2)} min e '
            'L=${comprimento.toStringAsFixed(2)} m. '
            'Confirme depois erosão, eficiência, domínio do ensaio e operação.'
            '${avisoInfiltracao == null ? '' : ' Aviso: $avisoInfiltracao'}',
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        origemGeometria: state.dimensionarComprimentoCriddle
            ? ProvenienciaSulco.naoInformado
            : null,
        mensagemPlanejamento: error.message.toString(),
      );
    } on ArgumentError catch (error) {
      state = state.copyWith(
        origemGeometria: state.dimensionarComprimentoCriddle
            ? ProvenienciaSulco.naoInformado
            : null,
        mensagemPlanejamento: error.message.toString(),
      );
    }
  }

  ParametersState _stateComAvancoDaOrigem(ParametersState source) {
    final curve = _curvaAvancoDaOrigem(source);
    return source.copyWith(
      tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento / 2,
        parametros: curve,
      ),
      tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento,
        parametros: curve,
      ),
    );
  }

  void recomendarMaiorComprimento() {
    if (state.metodo != MetodoIrrigacao.sulco) {
      state = state.copyWith(
        mensagemPlanejamento:
            'A recomendação automática está disponível para sulcos.',
      );
      return;
    }
    final erroEnsaio = validarEnsaio();
    if (erroEnsaio != null) {
      state = state.copyWith(mensagemPlanejamento: erroEnsaio);
      return;
    }

    try {
      final declividadePercent = state.declividade * 100;
      final tipo = state.tipoSulco ?? TipoSulco.sulcos_comuns;
      if (!tipo.suportaEscoamentoTerminal) {
        state = state.copyWith(
          mensagemPlanejamento: tipo.motivoSemSuporteTerminal,
        );
        return;
      }
      final qmax = declividadePercent > 0
          ? FlowManagement.calcularVazaoMaxima(
              declividadePercent: declividadePercent,
              textura: state.texturaSolo,
            ).qmaxLs
          : double.infinity;

      final base = _stateComAvancoDaOrigem(state);
      final curve = _curvaAvancoDaOrigem(base);
      ParametersState? recomendado;
      final avaliacoes = <String>[];
      final comprimentos = <double>[];
      for (
        var comprimento = 50.0;
        comprimento <= state.comprimentoMaximoTerrenoM;
        comprimento += 50
      ) {
        comprimentos.add(comprimento);
      }
      if (state.comprimentoMaximoTerrenoM >= 50 &&
          !comprimentos.contains(state.comprimentoMaximoTerrenoM)) {
        comprimentos.add(state.comprimentoMaximoTerrenoM);
      }
      comprimentos.sort();
      for (final comprimento in comprimentos) {
        if (state.origemAvanco == OrigemAvanco.ensaio &&
            comprimento > state.pontosEnsaioAvanco.last.distanciaM) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: sem validação — ensaio cobre apenas '
            '${state.pontosEnsaioAvanco.last.distanciaM.toStringAsFixed(0)} m; '
            'extrapolação não é aprovada.',
          );
          continue;
        }
        final declividadeFaixa = TipoSulcoInfo.getInfo(tipo).declividade;
        final faixa = declividadeFaixa.classificar(declividadePercent);
        if (faixa == FaixaDeclividade.fora) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — declividade '
            '${declividadePercent.toStringAsFixed(3)}% fora da faixa usável '
            '(${declividadeFaixa.faixaUsavelLabel}).',
          );
          continue;
        }
        if (state.vazao > qmax) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — '
            'Q=${state.vazao.toStringAsFixed(2)} L/s excede '
            'qmax=${qmax.toStringAsFixed(2)} L/s.',
          );
          continue;
        }
        final candidato = base.copyWith(
          comprimento: comprimento,
          distanciaEnsaioIntermediariaM:
              state.origemAvanco == OrigemAvanco.ensaio &&
                  state.metodoCurvaAvanco == MetodoCurvaAvanco.doisPontos
              ? comprimento / 2
              : null,
          tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
            distanciaM: comprimento / 2,
            parametros: curve,
          ),
          tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
            distanciaM: comprimento,
            parametros: curve,
          ),
          tempoEnsaioIntermediarioMin: state.origemAvanco == OrigemAvanco.ensaio
              ? AdvanceCurveModel.tempoAvanco(
                  distanciaM: state.distanciaEnsaioIntermediariaM,
                  parametros: curve,
                )
              : null,
        );
        try {
          final resultado = const FurrowSimulationCoordinator().simular(
            candidato.toIrrigationParameters(),
          );
          final aprovado =
              (resultado.balancoSulco?.eaIntegral ?? resultado.eficiencia) >=
                  60 &&
              resultado.alertaVazaoExcedida == null &&
              resultado.alertaInfiltracao == null &&
              !resultado.extrapolouAvanco &&
              (resultado.planejamentoOperacional?.agendaViavel ?? true) &&
              (resultado.planejamentoOperacional?.vazaoDisponivelSuficiente ??
                  true);
          final alertas = <String>[
            if ((resultado.eficienciaDistribuicaoEd ?? 100) < 70)
              'Ed abaixo da referência de 70% (indicativa)',
            if (resultado.perdaPercolacao > 15) 'Pp elevada (>15%)',
            if (resultado.perdaEscoamento > 10) 'Pe elevada (>10%)',
            if (faixa == FaixaDeclividade.usavel)
              'declividade fora do aconselhável',
            if (resultado.extrapolouAvanco) 'curva de avanço extrapolada',
            ?resultado.alertaInfiltracao,
            if (resultado.planejamentoOperacional?.agendaViavel == false ||
                resultado.planejamentoOperacional?.vazaoDisponivelSuficiente ==
                    false)
              'operação ou oferta de água inviável',
          ];
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: '
            '${aprovado ? 'candidato segundo hipóteses' : 'reprovado'} — '
            'Ta=${resultado.tempoAvanco.toStringAsFixed(1)} min, '
            'Ea integral=${(resultado.balancoSulco?.eaIntegral ?? resultado.eficiencia).toStringAsFixed(1)}% '
            '(mín. 60%), '
            'Ed=${(resultado.eficienciaDistribuicaoEd ?? 0).toStringAsFixed(1)}%, '
            'Pp=${resultado.perdaPercolacao.toStringAsFixed(1)}%, '
            'Pe=${resultado.perdaEscoamento.toStringAsFixed(1)}%, '
            'Q=${state.vazao.toStringAsFixed(2)} / '
            'qmax=${qmax.toStringAsFixed(2)} L/s'
            '${alertas.isEmpty ? '' : '; alertas: ${alertas.join(', ')}'}.',
          );
          if (aprovado) {
            recomendado = candidato;
          }
        } catch (error) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — ${error.toString().replaceFirst('FormatException: ', '')}',
          );
        }
      }
      final relatorio =
          'Avaliação de comprimentos (critérios: declividade usável, '
          'Q ≤ qmax, Ea integral ≥ 60%, cobertura do ensaio e operação):\n${avaliacoes.join('\n')}';
      if (recomendado == null) {
        state = state.copyWith(
          mensagemPlanejamento:
              'Nenhum comprimento atende aos critérios com os dados disponíveis.\n$relatorio',
        );
        return;
      }
      state = recomendado.copyWith(
        mensagemPlanejamento:
            'Maior candidato segundo as hipóteses: ${recomendado.comprimento.toStringAsFixed(0)} m.\n$relatorio',
      );
    } on FormatException catch (e) {
      state = state.copyWith(mensagemPlanejamento: e.message.toString());
    } catch (_) {
      state = state.copyWith(
        mensagemPlanejamento: 'Não foi possível avaliar os dados informados.',
      );
    }
  }

  double calcularDeclividade() {
    return state.declividade;
  }

  Future<void> executarSimulacao() async {
    if (state.metodo == MetodoIrrigacao.faixa) {
      final impedimento = state
          .toIrrigationParameters()
          .projetoFaixa!
          .impedimentoModelo;
      if (impedimento != null) {
        state = state.copyWith(erro: impedimento);
        return;
      }
    }
    final erroEnsaio = validarEnsaio();
    if (erroEnsaio != null) {
      state = state.copyWith(erro: erroEnsaio);
      return;
    }
    state = state.copyWith(executando: true, erro: null);
    try {
      final selectedCurve = state.metodo == MetodoIrrigacao.sulco
          ? _curvaAvancoDaOrigem(state)
          : null;
      final params = _stateComAvancoDaOrigem(state).toIrrigationParameters();
      final resultado = switch (state.metodo) {
        MetodoIrrigacao.faixa => const BorderSimulationCoordinator().executar(
          params,
        ),
        MetodoIrrigacao.sulco => const FurrowSimulationCoordinator().executar(
          params,
          curvaAvanco: selectedCurve,
        ),
        MetodoIrrigacao.inundacao =>
          const BasinSimulationCoordinator().executar(params),
      };
      state = state.copyWith(resultado: resultado, executando: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), executando: false);
    }
  }
}

/// Mantém a escolha durante a navegação. Com `autoDispose`, o estado podia ser
/// recriado como Sulco entre o toque no cartão e a abertura do formulário.
final parametersProvider =
    StateNotifierProvider<ParametersController, ParametersState>((ref) {
      return ParametersController();
    });
