import 'dart:math' as math;

import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/services/blaney_criddle.dart';
import 'package:irrigasim/shared/irrigacao/services/lamina_requerida.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/curva_infiltracao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/ensaios_sulco.dart'
    show PontoEnsaioAvanco;
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';

enum OrigemAvanco { estimativa, ensaio }

class EstadoParametrosSulco {
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
  final MetodoAjusteAvanco metodoCurvaAvanco;
  final List<PontoEnsaioAvanco> pontosEnsaioAvanco;
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
  final double areaHectares;
  final double evapotranspiracaoMmDia;
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
  final Map<String, ProvenienciaDado> origemEntradasSulco;
  final CurvaInfiltracao? curvaInfiltracaoSulco;
  final double? etoMmDia;
  final double? temperaturaMediaC;
  final double? latitudeGraus;
  final int? mesReferencia;
  final OrigemChuva origemChuva;
  final MetodoEtc metodoEtc;
  final double? decliveEncostaPercent;
  final String? orientacaoSulco;
  final ProvenienciaDado provenienciaGeometria;
  final bool dimensionarComprimentoCriddle;
  final double vazaoReduzidaLs;
  final OrigemVazaoReduzida origemVazaoReduzida;
  final bool fator11Vib;
  final double? vazaoEnsaioAvancoLs;
  final String? condicoesEnsaioAvanco;
  final EnsaioErosao? ensaioErosao;
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

  const EstadoParametrosSulco({
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
    this.metodoCurvaAvanco = MetodoAjusteAvanco.doisPontos,
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
    this.areaHectares = 2,
    this.evapotranspiracaoMmDia = 7.2,
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
    this.origemChuva = OrigemChuva.efetiva,
    this.metodoEtc = MetodoEtc.adotada,
    this.decliveEncostaPercent,
    this.orientacaoSulco,
    this.provenienciaGeometria = ProvenienciaDado.ilustrativo,
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
    MetodoEtc.adotada => evapotranspiracaoMmDia,
    MetodoEtc.etoVezesKc => (etoMmDia ?? 0) * kc,
    MetodoEtc.blaneyCriddle => (etoBlaneyCriddle ?? 0) * kc,
  };

  double get declividadeTransversal => distanciaTransversalM > 0
      ? desnivelTransversalM / distanciaTransversalM
      : 0;

  EntradasProjeto get entradasSulco {
    double? valor(String nome, double atual) =>
        origemEntradasSulco[nome] == ProvenienciaDado.naoInformado
        ? null
        : atual;
    final curva =
        origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada
        ? curvaInfiltracaoSulco
        : null;
    return EntradasProjeto(
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
      provenienciaGeometria: provenienciaGeometria,
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
          nome: origemEntradasSulco[nome] ?? ProvenienciaDado.ilustrativo,
        if (etoMmDia != null)
          'etoMmDia':
              origemEntradasSulco['etoMmDia'] ?? ProvenienciaDado.informado,
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

  EstadoParametrosSulco copyWith({
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
    MetodoAjusteAvanco? metodoCurvaAvanco,
    List<PontoEnsaioAvanco>? pontosEnsaioAvanco,
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
    double? areaHectares,
    double? evapotranspiracaoMmDia,
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
    bool limparLaminaRequeridaResultado = false,
    bool? projetoSulcoLegado,
    Map<String, ProvenienciaDado>? origemEntradasSulco,
    CurvaInfiltracao? curvaInfiltracaoSulco,
    bool limparCurvaInfiltracaoSulco = false,
    double? etoMmDia,
    bool limparEtoMmDia = false,
    double? temperaturaMediaC,
    bool limparTemperaturaMediaC = false,
    double? latitudeGraus,
    bool limparLatitudeGraus = false,
    int? mesReferencia,
    OrigemChuva? origemChuva,
    MetodoEtc? metodoEtc,
    double? decliveEncostaPercent,
    bool limparDecliveEncostaPercent = false,
    String? orientacaoSulco,
    ProvenienciaDado? provenienciaGeometria,
    bool? dimensionarComprimentoCriddle,
    double? vazaoReduzidaLs,
    OrigemVazaoReduzida? origemVazaoReduzida,
    bool? fator11Vib,
    double? vazaoEnsaioAvancoLs,
    String? condicoesEnsaioAvanco,
    EnsaioErosao? ensaioErosao,
    bool limparEnsaioErosao = false,
    double? jornadaDiariaH,
    int? periodoIrrigacaoDias,
    double? tempoMudancaParcelaMin,
    double? perdasConducaoLs,
    ManejoSulco? manejoSulco,
    double? tempoMudancaMin,
    double? cicloSurtirMin,
    double? larguraSulcoM,
    double? profundidadeSulcoM,
    bool limparLarguraSulcoM = false,
    bool limparProfundidadeSulcoM = false,
    SimulationResult? resultado,
    bool? executando,
    String? erro,
    String? mensagemPlanejamento,
  }) {
    return EstadoParametrosSulco(
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
      areaHectares: areaHectares ?? this.areaHectares,
      evapotranspiracaoMmDia:
          evapotranspiracaoMmDia ?? this.evapotranspiracaoMmDia,
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
      laminaRequeridaResultado: limparLaminaRequeridaResultado
          ? null
          : laminaRequeridaResultado ?? this.laminaRequeridaResultado,
      projetoSulcoLegado: projetoSulcoLegado ?? this.projetoSulcoLegado,
      origemEntradasSulco: origemEntradasSulco ?? this.origemEntradasSulco,
      curvaInfiltracaoSulco: limparCurvaInfiltracaoSulco
          ? null
          : curvaInfiltracaoSulco ?? this.curvaInfiltracaoSulco,
      etoMmDia: limparEtoMmDia ? null : etoMmDia ?? this.etoMmDia,
      temperaturaMediaC: limparTemperaturaMediaC
          ? null
          : temperaturaMediaC ?? this.temperaturaMediaC,
      latitudeGraus: limparLatitudeGraus
          ? null
          : latitudeGraus ?? this.latitudeGraus,
      mesReferencia: mesReferencia ?? this.mesReferencia,
      origemChuva: origemChuva ?? this.origemChuva,
      metodoEtc: metodoEtc ?? this.metodoEtc,
      decliveEncostaPercent: limparDecliveEncostaPercent
          ? null
          : decliveEncostaPercent ?? this.decliveEncostaPercent,
      orientacaoSulco: orientacaoSulco ?? this.orientacaoSulco,
      provenienciaGeometria:
          provenienciaGeometria ?? this.provenienciaGeometria,
      dimensionarComprimentoCriddle:
          dimensionarComprimentoCriddle ?? this.dimensionarComprimentoCriddle,
      vazaoReduzidaLs: vazaoReduzidaLs ?? this.vazaoReduzidaLs,
      origemVazaoReduzida: origemVazaoReduzida ?? this.origemVazaoReduzida,
      fator11Vib: fator11Vib ?? this.fator11Vib,
      vazaoEnsaioAvancoLs: vazaoEnsaioAvancoLs ?? this.vazaoEnsaioAvancoLs,
      condicoesEnsaioAvanco:
          condicoesEnsaioAvanco ?? this.condicoesEnsaioAvanco,
      ensaioErosao: limparEnsaioErosao
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
      larguraSulcoM: limparLarguraSulcoM
          ? null
          : larguraSulcoM ?? this.larguraSulcoM,
      profundidadeSulcoM: limparProfundidadeSulcoM
          ? null
          : profundidadeSulcoM ?? this.profundidadeSulcoM,
      resultado: resultado,
      executando: executando ?? this.executando,
      erro: erro,
      mensagemPlanejamento: mensagemPlanejamento,
    );
  }

  IrrigationParameters paraParametrosIrrigacao() {
    final curva = projetoSulcoLegado ? null : entradasSulco.curvaInfiltracao;
    final convertida = curva?.parametrosAcumulados();
    return IrrigationParameters(
      entradasProjeto: projetoSulcoLegado ? null : entradasSulco,
      comprimento: comprimento,
      declividade: declividade,
      declividadeTransversal: declividadeTransversal,
      larguraOuEspacamento: larguraOuEspacamento,
      k: convertida?.coeficiente ?? k,
      a: convertida?.expoente ?? a,
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
      areaHectares: areaHectares,
      evapotranspiracaoMmDia: evapotranspiracaoCulturaMmDia,
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
