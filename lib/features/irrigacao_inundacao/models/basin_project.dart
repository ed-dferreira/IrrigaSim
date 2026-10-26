// Projeto de irrigação por inundação — contrato versionado (Fase 6 e
// Fase 1 do plano de cultura/clima/operacao). Espelha
// lib/models/faixas/border_project.dart: campos imutáveis, validação
// tipada ([BorderNotice]), serialização toMap/fromMap, migração fromLegacy e
// ponte para [IrrigationParameters] (toCompatParameters). As regras G1–G9 do
// plano docs/Plano_implementacao_inundacao.md e as lacunas G12–G16 do plano
// docs/Plano_implementacao_bacia_cultura_clima_operacao.md são validações do
// modelo, não apenas avisos de interface.
//
// Referência didática: Aula 8 — Irrigação por Inundação, Prof.ª Chaiane
// Guerra da Conceição, UNIPAMPA (docs/Pacote_Inundacao).
import 'package:irrigasim/shared/irrigacao/models/comum/adaptadores_superficie.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/shared/irrigacao/models/validacao_superficie.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_agronomy.dart';
import 'package:irrigasim/shared/irrigacao/services/blaney_criddle.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_math.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_tables.dart';

/// Cenário de infiltração trabalhado no projeto (duas curvas da aula).
enum CenarioInfiltracaoBasin { primeira, terceira, informado }

extension CenarioInfiltracaoBasinExtension on CenarioInfiltracaoBasin {
  String get displayName => switch (this) {
    CenarioInfiltracaoBasin.primeira => 'Primeira irrigação',
    CenarioInfiltracaoBasin.terceira => 'Terceira irrigação',
    CenarioInfiltracaoBasin.informado => 'Valores informados',
  };

  static CenarioInfiltracaoBasin fromString(String? value) =>
      CenarioInfiltracaoBasin.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CenarioInfiltracaoBasin.primeira,
      );
}

/// Origem da lâmina requerida (IRN) usada no balanço do intermitente (G14).
enum OrigemIrnBasin { informada, calculada }

extension OrigemIrnBasinExtension on OrigemIrnBasin {
  String get displayName => switch (this) {
    OrigemIrnBasin.informada => 'IRN informada',
    OrigemIrnBasin.calculada => 'IRN calculada',
  };

  static OrigemIrnBasin fromString(String? value) =>
      OrigemIrnBasin.values.firstWhere(
        (item) => item.name == value,
        orElse: () => OrigemIrnBasin.informada,
      );
}

/// Curva de infiltração armazenada (k, a, VIB) para comparar cenários.
class BasinInfiltrationScenario {
  const BasinInfiltrationScenario({this.k, this.a, this.vibMMin});

  final double? k;
  final double? a;
  final double? vibMMin;

  Map<String, Object?> toMap() => {'k': k, 'a': a, 'vib_m_min': vibMMin};

  factory BasinInfiltrationScenario.fromMap(Object? data) {
    if (data is! Map) return const BasinInfiltrationScenario();
    final map = Map<String, dynamic>.from(data);
    double? numero(String chave) {
      final valor = map[chave];
      return valor is num ? valor.toDouble() : null;
    }

    return BasinInfiltrationScenario(
      k: numero('k'),
      a: numero('a'),
      vibMMin: numero('vib_m_min'),
    );
  }
}

/// Projeto de inundação versionado. Campos nulos significam "não informado";
/// a serialização nunca inventa valores ausentes (G4).
class BasinProject {
  static const versaoAtual = 2;

  /// Limites do tabuleiro (G2): de 1 m² a 5 ha.
  static const double areaTabuleiroMinimaM2 = 1;
  static const double areaTabuleiroMaximaM2 = 50000;

  /// Taipa: base de 0,60 a 1,80 m (G2).
  static const double baseDiqueMinimaM = 0.60;
  static const double baseDiqueMaximaM = 1.80;

  /// Taipa: altura de 0,60 a 0,80 m (G2).
  static const double alturaDiqueMinimaM = 0.60;
  static const double alturaDiqueMaximaM = 0.80;

  /// Margem livre de 0,05 a 0,20 m acima da lâmina (G2).
  static const double margemLivreMinimaM = 0.05;
  static const double margemLivreMaximaM = 0.20;

  /// Declividade máxima admitida pela aula (G9): < 2%.
  static const double declividadeMaxima = 0.02;

  /// Vmax adotado na aula, m/min.
  static const double vmaxMMinPadrao = 8.0;

  /// Ponto de partida padrão do expoente r do avanço (núcleo da aula).
  static const double rInicialPadrao = 0.7;

  final int versao;
  final bool legado;
  final TipoInundacao regime;
  final CenarioInfiltracaoBasin cenarioInfiltracao;
  final BasinInfiltrationScenario? dadosPrimeira, dadosTerceira;

  // ---- Solo e infiltração ----
  final double? k, a, vibMMin, rugosidadeN;
  final TexturaSolo? texturaSolo;

  // ---- Área e geometria ----
  final double? comprimentoAreaM, larguraAreaM;
  final double? comprimentoM, larguraM;
  final double? areaUtilM2;
  final String? cultura;

  // ---- Cultura e sistema radicular (etapa 5) ----
  /// Insumos de solo/raízes/Kc; [cultura] continua no campo legado acima e é
  /// espelhada em [BasinAgronomy.cultura] pelo controller.
  final BasinAgronomy? agronomia;

  // ---- Clima e demanda (etapa 6) ----
  final MetodoEtc metodoEtc;
  final OrigemChuva origemChuva;

  /// Origem da IRN usada no balanço: informada (padrão, faixas) ou calculada
  /// pela agronomia (G14: a informada prevalece e as duas podem coexistir).
  final OrigemIrnBasin origemIrn;
  final double? etoMmDia, precipitacaoEfetivaMmDia;
  final double? temperaturaMediaC, latitudeGraus;
  final int? mesReferencia;

  /// Declividade longitudinal do tabuleiro, m/m (ex.: 0,0025 = 0,25%).
  final double? declividade;

  final double? alturaDiqueM, baseDiqueM, margemLivreM;

  // ---- Auditoria (G6): ρ1, ρ2 e Vmax de F02, nunca em cálculo ----
  final double? rho1F02, rho2F02, vmaxF02;

  // ---- Regime intermitente ----
  final double? laminaRequeridaMm;
  final double? etIntermitenteMmDia;
  final int? intervaloDias;
  final double? vazaoTotalLs;
  final double vmaxMMin;
  final List<double> candidatasVazaoLs;

  /// Lâmina inicial (Li) e final (Lf) mantidas no tabuleiro, mm; quando
  /// ambas informadas, a lâmina média Lm segue (Li + Lf)/2 (p. 34–35).
  final double? laminaInicialMm, laminaFinalMm;

  /// Ponto de partida da iteração do expoente r do avanço (núcleo usa 0,7).
  final double rInicial;

  // ---- Regime permanente (contínuo) ----
  final double? areaHectares;
  final double? porosidade;
  final double? profundidadeCamadaMm;
  final double? condutividadeHidraulicaMmDia;
  final double? dtaMmCm;
  final double? fatorDisponibilidade;
  final double? evapotranspiracaoMmDia;
  final double? laminaSuperficialMm;
  final double? vazaoDisponivelLps;

  // ---- Volumes do arroz (pp. 74–84, G4: lacunas ficam null) ----
  final double? dsGcm3, dpGcm3, pciM, alturaLaminaRiceM;
  final double? evaporacaoTanqueMmDia, ksatMDia, periodoArrozDias;
  final double? produtividadeSacosHa, umidadeGraos, indiceColheita;
  final double? uaGravimetrica, massaSacoKg;
  final double? areaArrozHa, tdDias, trDias;

  // ---- Operação ----
  final double jornadaHoras;
  final double mudancaParcelaMin;
  final int periodoDias;
  final int tabuleirosPorParcela;

  const BasinProject({
    this.versao = versaoAtual,
    this.legado = false,
    this.regime = TipoInundacao.intermitente,
    this.cenarioInfiltracao = CenarioInfiltracaoBasin.primeira,
    this.dadosPrimeira,
    this.dadosTerceira,
    this.k,
    this.a,
    this.vibMMin,
    this.rugosidadeN,
    this.texturaSolo,
    this.comprimentoAreaM,
    this.larguraAreaM,
    this.comprimentoM,
    this.larguraM,
    this.areaUtilM2,
    this.cultura,
    this.agronomia,
    this.metodoEtc = MetodoEtc.adotada,
    this.origemChuva = OrigemChuva.naoInformada,
    this.origemIrn = OrigemIrnBasin.informada,
    this.etoMmDia,
    this.precipitacaoEfetivaMmDia,
    this.temperaturaMediaC,
    this.latitudeGraus,
    this.mesReferencia,
    this.declividade,
    this.alturaDiqueM,
    this.baseDiqueM,
    this.margemLivreM,
    this.rho1F02,
    this.rho2F02,
    this.vmaxF02,
    this.laminaRequeridaMm,
    this.etIntermitenteMmDia,
    this.intervaloDias,
    this.vazaoTotalLs,
    this.vmaxMMin = vmaxMMinPadrao,
    this.candidatasVazaoLs = const [],
    this.laminaInicialMm,
    this.laminaFinalMm,
    this.rInicial = rInicialPadrao,
    this.areaHectares,
    this.porosidade,
    this.profundidadeCamadaMm,
    this.condutividadeHidraulicaMmDia,
    this.dtaMmCm,
    this.fatorDisponibilidade,
    this.evapotranspiracaoMmDia,
    this.laminaSuperficialMm,
    this.vazaoDisponivelLps,
    this.dsGcm3,
    this.dpGcm3,
    this.pciM,
    this.alturaLaminaRiceM,
    this.evaporacaoTanqueMmDia,
    this.ksatMDia,
    this.periodoArrozDias,
    this.produtividadeSacosHa,
    this.umidadeGraos,
    this.indiceColheita,
    this.uaGravimetrica,
    this.massaSacoKg,
    this.areaArrozHa,
    this.tdDias,
    this.trDias,
    this.jornadaHoras = 24,
    this.mudancaParcelaMin = 0,
    this.periodoDias = 10,
    this.tabuleirosPorParcela = 1,
  });

  /// Exemplo da Aula 8 — intermitente (p. 63), com as duas curvas de
  /// infiltração e os ρ1/ρ2 de auditoria (G6).
  factory BasinProject.exemploAula8Intermitente() {
    final p = BasinReferenceTables.intermitenteAula8;
    return BasinProject(
      regime: TipoInundacao.intermitente,
      cenarioInfiltracao: CenarioInfiltracaoBasin.primeira,
      dadosPrimeira: BasinInfiltrationScenario(
        k: p.k,
        a: p.a,
        vibMMin: p.vibMMin,
      ),
      dadosTerceira: BasinInfiltrationScenario(
        k: p.kTerceira,
        a: p.aTerceira,
        vibMMin: p.vibTerceiraMMin,
      ),
      k: p.k,
      a: p.a,
      vibMMin: p.vibMMin,
      rugosidadeN: p.manningN,
      comprimentoAreaM: p.larguraAreaM,
      larguraAreaM: p.comprimentoM,
      comprimentoM: p.comprimentoM,
      larguraM: 20.0,
      declividade: p.declividade,
      alturaDiqueM: 0.7,
      baseDiqueM: 1.2,
      margemLivreM: 0.1,
      rho1F02: p.rho1,
      rho2F02: p.rho2,
      vmaxF02: p.vmaxMMin,
      laminaRequeridaMm: p.irnMm,
      etIntermitenteMmDia: p.etMmDia,
      intervaloDias: p.intervaloDias,
      // G16: a p. 63 não divulga os insumos de solo/planta que "propiciaram
      // IRN 56 mm e ET 8 mm/dia"; estes valores didáticos reproduzem
      // exatamente 56 mm ((30−20)/10 · 1,4 · 50 · 0,8) e TR = 56/8 = 7 dias,
      // mas a IRN efetiva continua sendo a informada de referência.
      agronomia: const BasinAgronomy(
        uccPercentual: 30,
        upmpPercentual: 20,
        densidadeGcm3: 1.4,
        profundidadeRaizesCm: 50,
        fracaoDisponivel: 0.8,
      ),
      metodoEtc: MetodoEtc.adotada,
      origemIrn: OrigemIrnBasin.informada,
      origemChuva: OrigemChuva.efetiva,
      precipitacaoEfetivaMmDia: 0,
      // 400 L/s é a disponibilidade da fonte; a hidráulica parte de Q0max.
      vazaoDisponivelLps: p.vazaoTotalLs,
      vmaxMMin: p.vmaxMMin,
      periodoDias: p.intervaloDias,
      tabuleirosPorParcela: 1,
    );
  }

  /// Exemplo da Aula 8 — permanente/contínuo (p. 73) com volumes do arroz
  /// (p. 84, lacunas preservadas).
  factory BasinProject.exemploAula8Permanente() {
    final c = BasinReferenceTables.continuaAula8;
    final arroz = BasinReferenceTables.arrozAula8;
    return BasinProject(
      regime: TipoInundacao.permanente,
      cenarioInfiltracao: CenarioInfiltracaoBasin.informado,
      metodoEtc: MetodoEtc.adotada,
      comprimentoM: 100,
      larguraM: 50,
      larguraAreaM: 100,
      alturaDiqueM: 0.7,
      baseDiqueM: 1.2,
      margemLivreM: 0.1,
      areaHectares: c.areaHa,
      porosidade: c.porosidade,
      profundidadeCamadaMm: c.profundidadeCamadaMm,
      condutividadeHidraulicaMmDia: c.k0MmDia,
      dtaMmCm: c.dtaMmCm,
      fatorDisponibilidade: c.f,
      evapotranspiracaoMmDia: c.etMmDia,
      laminaSuperficialMm: c.laminaMm,
      vazaoDisponivelLps: 36,
      dsGcm3: arroz.dsGcm3,
      dpGcm3: arroz.dpGcm3,
      pciM: arroz.pciM,
      alturaLaminaRiceM: arroz.alturaLaminaM,
      evaporacaoTanqueMmDia: arroz.evaporacaoMmDia,
      ksatMDia: arroz.ksatMDia,
      periodoArrozDias: arroz.periodoDias,
      produtividadeSacosHa: arroz.produtividadeSacosHa,
      umidadeGraos: arroz.umidadeGraos,
      indiceColheita: arroz.indiceColheita,
      // G4: Ua e massa do saco não constam do enunciado (p. 84).
      uaGravimetrica: null,
      massaSacoKg: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Getters derivados (não persistem).
  // ---------------------------------------------------------------------------

  /// Área do tabuleiro L × largura, m².
  double? get areaTabuleiroM2 => comprimentoM != null && larguraM != null
      ? comprimentoM! * larguraM!
      : null;

  double? get areaTabuleiroHa =>
      areaTabuleiroM2 == null ? null : areaTabuleiroM2! / 10000;

  /// Área total da unidade (faixa da aula), m², quando declarada.
  double? get areaTotalM2 => comprimentoAreaM != null && larguraAreaM != null
      ? comprimentoAreaM! * larguraAreaM!
      : null;

  /// Lâmina média mantida no planalto, Lm, pela convenção do regime. No
  /// intermitente, Li e Lf informadas prevalecem sobre a IRN (p. 34–35) e a
  /// IRN efetiva (informada ou calculada, G14) é a de referência.
  double? get laminaMediaPlanaltoM => regime == TipoInundacao.permanente
      ? (laminaSuperficialMm == null ? null : laminaSuperficialMm! / 1000)
      : (laminaInicialMm != null && laminaFinalMm != null
            ? laminaMediaPlanalto(
                laminaInicialMm! / 1000,
                laminaFinalMm! / 1000,
              )
            : (irnEfetivaMm == null ? null : irnEfetivaMm! / 1000));

  /// Regra 2/3 (G1): desnível admissível Δz ≤ 2 Lm/3.
  double? get desnivelAdmissivelM => laminaMediaPlanaltoM == null
      ? null
      : desnivelAdmissivel(laminaMediaPlanaltoM!);

  /// Desnível real do tabuleiro, Δz = declividade × L.
  double? get desnivelRealM => declividade == null || comprimentoM == null
      ? null
      : declividade! * comprimentoM!;

  /// Comprimento máximo isolado pela regra 2/3 (p. 20).
  double? get comprimentoMaximoDesnivelM =>
      laminaMediaPlanaltoM == null || declividade == null || declividade! <= 0
      ? null
      : comprimentoMaximoPorDesnivel(laminaMediaPlanaltoM!, declividade!);

  /// Vazão não erosiva total, L/s (Q0max × largura).
  double? get q0MaxLsTotal {
    if (comprimentoM == null || larguraM == null || rugosidadeN == null) {
      return null;
    }
    final q0Max = vazaoMaxima(vmaxMMin, rugosidadeN!, comprimentoM!);
    return q0Max * larguraM! * 1000 / 60;
  }

  /// Vazão total aplicada no intermitente, L/s: a informada ou, sem
  /// informação, a vazão não erosiva máxima (comportamento da aula).
  double? get vazaoAplicadaLs {
    if (regime == TipoInundacao.intermitente) {
      return vazaoTotalLs ?? q0MaxLsTotal;
    }
    return vazaoTotalLs ?? vazaoDisponivelLps;
  }

  /// Curva de infiltração ativa pela convenção do cenário.
  BasinInfiltrationScenario? get cenarioAtivo => switch (cenarioInfiltracao) {
    CenarioInfiltracaoBasin.primeira => dadosPrimeira,
    CenarioInfiltracaoBasin.terceira => dadosTerceira,
    CenarioInfiltracaoBasin.informado => BasinInfiltrationScenario(
      k: k,
      a: a,
      vibMMin: vibMMin,
    ),
  };

  // ---------------------------------------------------------------------------
  // Derivações de clima e demanda (Fase 1; G4: ausente nunca vira zero).
  // ---------------------------------------------------------------------------

  /// ETo diária por Blaney–Criddle quando há temperatura, latitude e mês;
  /// null quando falta insumo ou o cálculo é inválido.
  double? get etoBlaneyCriddleMmDia {
    final temperatura = temperaturaMediaC;
    final latitude = latitudeGraus;
    final mes = mesReferencia;
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

  /// ETc pela convenção do método escolhido (espelho de
  /// `parameters_controller.evapotranspiracaoCulturaMmDia`, sem fabricar 0):
  /// adotada lê o campo do regime; ETo×Kc e Blaney-Criddle usam a agronomia.
  double? get etcMmDia => switch (metodoEtc) {
    MetodoEtc.adotada =>
      regime == TipoInundacao.intermitente
          ? (etIntermitenteMmDia ?? evapotranspiracaoMmDia)
          : (evapotranspiracaoMmDia ?? etIntermitenteMmDia),
    MetodoEtc.etoVezesKc =>
      etoMmDia == null || agronomia?.kc == null
          ? null
          : etoMmDia! * agronomia!.kc!,
    MetodoEtc.blaneyCriddle =>
      etoBlaneyCriddleMmDia == null || agronomia?.kc == null
          ? null
          : etoBlaneyCriddleMmDia! * agronomia!.kc!,
  };

  /// Pef que efetivamente abate a demanda: chuva registrada como provável é
  /// observada, não convertida em precipitação efetiva, e não dá crédito.
  double? get precipitacaoEfetivaEfetivaMmDia =>
      origemChuva == OrigemChuva.provavel ? 0 : precipitacaoEfetivaMmDia;

  /// IRN calculada (mm) a partir da agronomia e da demanda climática;
  /// null quando falta insumo ou a demanda não é positiva.
  double? get irnCalculadaMm {
    final base = agronomia;
    final etc = etcMmDia;
    final pef = precipitacaoEfetivaEfetivaMmDia;
    if (base == null || etc == null || pef == null) return null;
    return base.irnMm(etcMmDia: etc, precipitacaoEfetivaMmDia: pef);
  }

  /// IRN efetiva do balanço: a informada prevalece sobre a calculada (G14,
  /// padrão faixas). No permanente não há IRN de balanço (G8).
  double? get irnEfetivaMm => regime == TipoInundacao.permanente
      ? null
      : (origemIrn == OrigemIrnBasin.informada
            ? laminaRequeridaMm
            : irnCalculadaMm);

  /// Turno de rega pela IRN: TR = IRN/(ETc − Pef), dias (p. 63/73). null
  /// quando falta IRN, ETc, Pef ou a demanda líquida não é positiva.
  double? get turnoRegaIrnDias {
    final irn = irnEfetivaMm;
    final etc = etcMmDia;
    final pef = precipitacaoEfetivaEfetivaMmDia;
    if (irn == null || etc == null || pef == null) return null;
    final demanda = etc - pef;
    if (!demanda.isFinite || demanda <= 0) return null;
    return irn / demanda;
  }

  /// Cultura efetiva: a agronomia (etapa 5) espelha o campo legado.
  String? get culturaEfetiva => agronomia?.cultura ?? cultura;

  /// Compatibilidade com a camada comum de identificação/área/ensaio.
  BaseIrrigacao get baseComum =>
      toCompatParameters().baseComumPara(MetodoIrrigacao.inundacao);

  /// Compatibilidade com o envelope legado usado pelo coordenaador.
  factory BasinProject.fromParameters(IrrigationParameters p) =>
      p.projetoInundacao ?? BasinProject.fromLegacy(p);

  // ---------------------------------------------------------------------------
  // Validação tipada (G1–G9).
  // ---------------------------------------------------------------------------

  BorderNotice? get impedimento {
    BorderNotice? positivo(double? valor, String rotulo, {String? pagina}) =>
        valor == null
        ? null
        : (!valor.isFinite || valor <= 0)
        ? BorderNotice(
            BorderStatus.entradaInvalida,
            '$rotulo precisa ser maior que zero.',
            pagina: pagina,
          )
        : null;

    // Geometria do tabuleiro (G2).
    if (comprimentoM == null || larguraM == null) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Informe o comprimento e a largura do tabuleiro.',
      );
    }
    final area = areaTabuleiroM2!;
    if (area < areaTabuleiroMinimaM2 || area > areaTabuleiroMaximaM2) {
      return BorderNotice(
        BorderStatus.entradaInvalida,
        'A área do tabuleiro (L × largura) deve ficar entre '
        '${areaTabuleiroMinimaM2.toStringAsFixed(0)} m² e '
        '${(areaTabuleiroMaximaM2 / 10000).toStringAsFixed(0)} ha.',
      );
    }
    for (final (valor, rotulo) in [
      (comprimentoM, 'comprimento do tabuleiro'),
      (larguraM, 'largura do tabuleiro'),
    ]) {
      final aviso = positivo(valor, rotulo);
      if (aviso != null) return aviso;
    }

    // Solo e infiltração.
    for (final (valor, rotulo) in [
      (k, 'k da infiltração'),
      (vibMMin, 'VIB'),
      (rugosidadeN, 'rugosidade de Manning'),
    ]) {
      final aviso = positivo(valor, rotulo);
      if (aviso != null) return aviso;
    }
    if (a != null && (!a!.isFinite || a! <= 0 || a! >= 1)) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'O expoente a da infiltração deve estar em (0,1).',
      );
    }

    // Declividade (G9) e regra 2/3 (G1).
    if (declividade != null) {
      if (!declividade!.isFinite || declividade! < 0) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'A declividade deve ser um valor não negativo em m/m.',
        );
      }
      if (declividade! >= declividadeMaxima) {
        return const BorderNotice(
          BorderStatus.foraDoDominio,
          'A inundação exige declividade longitudinal inferior a 2%.',
          pagina: 'p. 20',
        );
      }
      if (desnivelAdmissivelM != null &&
          desnivelRealM != null &&
          desnivelRealM! > desnivelAdmissivelM! * (1 + 1e-9)) {
        return BorderNotice(
          BorderStatus.foraDoDominio,
          'A regra 2/3 limita o desnível do tabuleiro a '
          '${(desnivelAdmissivelM! * 100).toStringAsFixed(1)} cm '
          '(2/3 da lâmina média); o desnível real é '
          '${(desnivelRealM! * 100).toStringAsFixed(1)} cm.',
          pagina: 'p. 20',
        );
      }
    }

    // Taipa e margem livre (G2).
    if (alturaDiqueM != null &&
        (alturaDiqueM! < alturaDiqueMinimaM ||
            alturaDiqueM! > alturaDiqueMaximaM)) {
      return BorderNotice(
        BorderStatus.entradaInvalida,
        'A altura da taipa deve ficar entre '
        '${alturaDiqueMinimaM.toStringAsFixed(2)} e '
        '${alturaDiqueMaximaM.toStringAsFixed(2)} m.',
        pagina: 'p. 35',
      );
    }
    if (baseDiqueM != null &&
        (baseDiqueM! < baseDiqueMinimaM || baseDiqueM! > baseDiqueMaximaM)) {
      return BorderNotice(
        BorderStatus.entradaInvalida,
        'A base da taipa deve ficar entre '
        '${baseDiqueMinimaM.toStringAsFixed(2)} e '
        '${baseDiqueMaximaM.toStringAsFixed(2)} m.',
        pagina: 'p. 35',
      );
    }
    if (margemLivreM != null &&
        (margemLivreM! < margemLivreMinimaM ||
            margemLivreM! > margemLivreMaximaM)) {
      return BorderNotice(
        BorderStatus.entradaInvalida,
        'A margem livre deve ficar entre '
        '${margemLivreMinimaM.toStringAsFixed(2)} e '
        '${margemLivreMaximaM.toStringAsFixed(2)} m.',
        pagina: 'p. 35',
      );
    }

    // Clima e demanda (G13): ETc e Pef fora de domínio bloqueiam.
    final etcClima = etcMmDia;
    if (etcClima != null && (!etcClima.isFinite || etcClima <= 0)) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'A evapotranspiração da cultura (ETc) precisa ser maior que zero.',
      );
    }
    final pefClima = precipitacaoEfetivaEfetivaMmDia;
    if (etcClima != null && pefClima != null && pefClima > etcClima) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'A precipitação efetiva não pode superar a ETc da cultura.',
      );
    }

    if (regime == TipoInundacao.intermitente) {
      for (final (valor, rotulo) in [
        (irnEfetivaMm, 'lâmina requerida (IRN)'),
        (vazaoAplicadaLs, 'vazão total'),
        (rInicial, 'expoente r inicial'),
        (laminaInicialMm, 'lâmina inicial (Li)'),
        (laminaFinalMm, 'lâmina final (Lf)'),
      ]) {
        final aviso = positivo(valor, rotulo);
        if (aviso != null) return aviso;
      }
      // G14: IRN calculada precisa dos insumos completos para existir.
      if (origemIrn == OrigemIrnBasin.calculada && irnEfetivaMm == null) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'A IRN calculada precisa dos dados agronômicos e climáticos '
          'completos (UCC, UPMP, Ds, raízes, fração, ETc e precipitação '
          'efetiva).',
        );
      }
      // G12: intervalo de rega menor que o turno de rega pela IRN (p. 63).
      final trIrn = turnoRegaIrnDias;
      if (intervaloDias != null && trIrn != null && intervaloDias! < trIrn) {
        return BorderNotice(
          BorderStatus.avisoOrientativo,
          'O intervalo entre irrigações ($intervaloDias dias) é menor que o '
          'turno de rega pela IRN (${trIrn.toStringAsFixed(1)} dias); a aula '
          'usa intervalo ≥ IRN/(ETc − Pef).',
          pagina: 'p. 63',
        );
      }
      final maxima = q0MaxLsTotal;
      if (maxima != null &&
          vazaoAplicadaLs != null &&
          vazaoAplicadaLs! > maxima * (1 + 1e-9)) {
        return BorderNotice(
          BorderStatus.avisoOrientativo,
          'A vazão total informada supera a vazão não erosiva '
          '(${maxima.toStringAsFixed(1)} L/s); a aula recomenda usar Q0max.',
          pagina: 'p. 54',
        );
      }
      // G3: a geometria precisa caber na área declarada da unidade.
      final areaDeclarada =
          areaTotalM2 ??
          areaUtilM2 ??
          (areaHectares == null ? null : areaHectares! * 10000);
      if (areaTabuleiroM2 != null &&
          areaDeclarada != null &&
          areaDeclarada > 0) {
        if (areaTabuleiroM2! > areaDeclarada * (1 + 1e-9)) {
          return const BorderNotice(
            BorderStatus.avisoOrientativo,
            'O comprimento × largura do tabuleiro supera a área declarada '
            'da unidade; confira a geometria planejada.',
            pagina: 'p. 73',
          );
        }
      }
    } else {
      for (final (valor, rotulo) in [
        (areaHectares, 'área irrigada'),
        (profundidadeCamadaMm, 'profundidade da camada'),
        (condutividadeHidraulicaMmDia, 'condutividade hidráulica K0'),
        (dtaMmCm, 'disponibilidade total de água (DTA)'),
        (etcMmDia, 'evapotranspiração'),
        (laminaSuperficialMm, 'lâmina superficial'),
        (vazaoDisponivelLps, 'vazão disponível'),
      ]) {
        final aviso = positivo(valor, rotulo);
        if (aviso != null) return aviso;
      }
      if (porosidade != null && (porosidade! <= 0 || porosidade! > 1)) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'A porosidade deve estar entre 0 e 1.',
        );
      }
      if (fatorDisponibilidade != null &&
          (fatorDisponibilidade! <= 0 || fatorDisponibilidade! > 1)) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'O fator de disponibilidade deve estar entre 0 e 1.',
        );
      }
    }

    return null;
  }

  String? get impedimentoModelo => impedimento?.mensagem;

  // ---------------------------------------------------------------------------
  // Serialização.
  // ---------------------------------------------------------------------------

  BasinProject copyWith({
    int? versao,
    TipoInundacao? regime,
    CenarioInfiltracaoBasin? cenarioInfiltracao,
    BasinInfiltrationScenario? dadosPrimeira,
    BasinInfiltrationScenario? dadosTerceira,
    bool clearDadosCenarios = false,
    double? k,
    double? a,
    double? vibMMin,
    double? rugosidadeN,
    TexturaSolo? texturaSolo,
    double? comprimentoAreaM,
    double? larguraAreaM,
    double? comprimentoM,
    double? larguraM,
    double? areaUtilM2,
    String? cultura,
    BasinAgronomy? agronomia,
    MetodoEtc? metodoEtc,
    OrigemChuva? origemChuva,
    OrigemIrnBasin? origemIrn,
    double? etoMmDia,
    double? precipitacaoEfetivaMmDia,
    double? temperaturaMediaC,
    double? latitudeGraus,
    int? mesReferencia,
    double? declividade,
    double? alturaDiqueM,
    double? baseDiqueM,
    double? margemLivreM,
    double? rho1F02,
    double? rho2F02,
    double? vmaxF02,
    double? laminaRequeridaMm,
    double? etIntermitenteMmDia,
    int? intervaloDias,
    double? vazaoTotalLs,
    double? vmaxMMin,
    List<double>? candidatasVazaoLs,
    double? laminaInicialMm,
    double? laminaFinalMm,
    double? rInicial,
    double? areaHectares,
    double? porosidade,
    double? profundidadeCamadaMm,
    double? condutividadeHidraulicaMmDia,
    double? dtaMmCm,
    double? fatorDisponibilidade,
    double? evapotranspiracaoMmDia,
    double? laminaSuperficialMm,
    double? vazaoDisponivelLps,
    double? dsGcm3,
    double? dpGcm3,
    double? pciM,
    double? alturaLaminaRiceM,
    double? evaporacaoTanqueMmDia,
    double? ksatMDia,
    double? periodoArrozDias,
    double? produtividadeSacosHa,
    double? umidadeGraos,
    double? indiceColheita,
    double? uaGravimetrica,
    double? massaSacoKg,
    double? areaArrozHa,
    double? tdDias,
    double? trDias,
    double? jornadaHoras,
    double? mudancaParcelaMin,
    int? periodoDias,
    int? tabuleirosPorParcela,
  }) {
    return BasinProject(
      versao: versao ?? this.versao,
      legado: legado,
      regime: regime ?? this.regime,
      cenarioInfiltracao: cenarioInfiltracao ?? this.cenarioInfiltracao,
      dadosPrimeira: clearDadosCenarios
          ? null
          : dadosPrimeira ?? this.dadosPrimeira,
      dadosTerceira: clearDadosCenarios
          ? null
          : dadosTerceira ?? this.dadosTerceira,
      k: k ?? this.k,
      a: a ?? this.a,
      vibMMin: vibMMin ?? this.vibMMin,
      rugosidadeN: rugosidadeN ?? this.rugosidadeN,
      texturaSolo: texturaSolo ?? this.texturaSolo,
      comprimentoAreaM: comprimentoAreaM ?? this.comprimentoAreaM,
      larguraAreaM: larguraAreaM ?? this.larguraAreaM,
      comprimentoM: comprimentoM ?? this.comprimentoM,
      larguraM: larguraM ?? this.larguraM,
      areaUtilM2: areaUtilM2 ?? this.areaUtilM2,
      cultura: cultura ?? this.cultura,
      agronomia: agronomia ?? this.agronomia,
      metodoEtc: metodoEtc ?? this.metodoEtc,
      origemChuva: origemChuva ?? this.origemChuva,
      origemIrn: origemIrn ?? this.origemIrn,
      etoMmDia: etoMmDia ?? this.etoMmDia,
      precipitacaoEfetivaMmDia:
          precipitacaoEfetivaMmDia ?? this.precipitacaoEfetivaMmDia,
      temperaturaMediaC: temperaturaMediaC ?? this.temperaturaMediaC,
      latitudeGraus: latitudeGraus ?? this.latitudeGraus,
      mesReferencia: mesReferencia ?? this.mesReferencia,
      declividade: declividade ?? this.declividade,
      alturaDiqueM: alturaDiqueM ?? this.alturaDiqueM,
      baseDiqueM: baseDiqueM ?? this.baseDiqueM,
      margemLivreM: margemLivreM ?? this.margemLivreM,
      rho1F02: rho1F02 ?? this.rho1F02,
      rho2F02: rho2F02 ?? this.rho2F02,
      vmaxF02: vmaxF02 ?? this.vmaxF02,
      laminaRequeridaMm: laminaRequeridaMm ?? this.laminaRequeridaMm,
      etIntermitenteMmDia: etIntermitenteMmDia ?? this.etIntermitenteMmDia,
      intervaloDias: intervaloDias ?? this.intervaloDias,
      vazaoTotalLs: vazaoTotalLs ?? this.vazaoTotalLs,
      vmaxMMin: vmaxMMin ?? this.vmaxMMin,
      candidatasVazaoLs: candidatasVazaoLs ?? this.candidatasVazaoLs,
      laminaInicialMm: laminaInicialMm ?? this.laminaInicialMm,
      laminaFinalMm: laminaFinalMm ?? this.laminaFinalMm,
      rInicial: rInicial ?? this.rInicial,
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
      dsGcm3: dsGcm3 ?? this.dsGcm3,
      dpGcm3: dpGcm3 ?? this.dpGcm3,
      pciM: pciM ?? this.pciM,
      alturaLaminaRiceM: alturaLaminaRiceM ?? this.alturaLaminaRiceM,
      evaporacaoTanqueMmDia:
          evaporacaoTanqueMmDia ?? this.evaporacaoTanqueMmDia,
      ksatMDia: ksatMDia ?? this.ksatMDia,
      periodoArrozDias: periodoArrozDias ?? this.periodoArrozDias,
      produtividadeSacosHa: produtividadeSacosHa ?? this.produtividadeSacosHa,
      umidadeGraos: umidadeGraos ?? this.umidadeGraos,
      indiceColheita: indiceColheita ?? this.indiceColheita,
      uaGravimetrica: uaGravimetrica ?? this.uaGravimetrica,
      massaSacoKg: massaSacoKg ?? this.massaSacoKg,
      areaArrozHa: areaArrozHa ?? this.areaArrozHa,
      tdDias: tdDias ?? this.tdDias,
      trDias: trDias ?? this.trDias,
      jornadaHoras: jornadaHoras ?? this.jornadaHoras,
      mudancaParcelaMin: mudancaParcelaMin ?? this.mudancaParcelaMin,
      periodoDias: periodoDias ?? this.periodoDias,
      tabuleirosPorParcela: tabuleirosPorParcela ?? this.tabuleirosPorParcela,
    );
  }

  Map<String, Object?> toMap() => {
    'versao': versao,
    'legado': legado,
    'regime': regime.name,
    'cenario_infiltracao': cenarioInfiltracao.name,
    'dados_primeira': dadosPrimeira?.toMap(),
    'dados_terceira': dadosTerceira?.toMap(),
    'k': k,
    'a': a,
    'vib_m_min': vibMMin,
    'rugosidade_n': rugosidadeN,
    'textura_solo': texturaSolo?.name,
    'comprimento_area_m': comprimentoAreaM,
    'largura_area_m': larguraAreaM,
    'comprimento_m': comprimentoM,
    'largura_m': larguraM,
    'area_util_m2': areaUtilM2,
    'cultura': cultura,
    'agronomia': agronomia?.toMap(),
    'metodo_etc': metodoEtc.name,
    'origem_chuva': origemChuva.name,
    'origem_irn': origemIrn.name,
    'eto_mm_dia': etoMmDia,
    'precipitacao_efetiva_mm_dia': precipitacaoEfetivaMmDia,
    'temperatura_media_c': temperaturaMediaC,
    'latitude_graus': latitudeGraus,
    'mes_referencia': mesReferencia,
    'declividade': declividade,
    'altura_dique_m': alturaDiqueM,
    'base_dique_m': baseDiqueM,
    'margem_livre_m': margemLivreM,
    'rho1_f02': rho1F02,
    'rho2_f02': rho2F02,
    'vmax_f02': vmaxF02,
    'lamina_requerida_mm': laminaRequeridaMm,
    'et_intermitente_mm_dia': etIntermitenteMmDia,
    'intervalo_dias': intervaloDias,
    'vazao_total_l_s': vazaoTotalLs,
    'vmax_m_min': vmaxMMin,
    'candidatas_vazao_l_s': candidatasVazaoLs,
    'lamina_inicial_mm': laminaInicialMm,
    'lamina_final_mm': laminaFinalMm,
    'r_inicial': rInicial,
    'area_hectares': areaHectares,
    'porosidade': porosidade,
    'profundidade_camada_mm': profundidadeCamadaMm,
    'condutividade_hidraulica_mm_dia': condutividadeHidraulicaMmDia,
    'dta_mm_cm': dtaMmCm,
    'fator_disponibilidade': fatorDisponibilidade,
    'evapotranspiracao_mm_dia': evapotranspiracaoMmDia,
    'lamina_superficial_mm': laminaSuperficialMm,
    'vazao_disponivel_l_s': vazaoDisponivelLps,
    'ds_g_cm3': dsGcm3,
    'dp_g_cm3': dpGcm3,
    'pci_m': pciM,
    'altura_lamina_rice_m': alturaLaminaRiceM,
    'evaporacao_tanque_mm_dia': evaporacaoTanqueMmDia,
    'ksat_m_dia': ksatMDia,
    'periodo_arroz_dias': periodoArrozDias,
    'produtividade_sacos_ha': produtividadeSacosHa,
    'umidade_graos': umidadeGraos,
    'indice_colheita': indiceColheita,
    'ua_gravimetrica': uaGravimetrica,
    'massa_saco_kg': massaSacoKg,
    'area_arroz_ha': areaArrozHa,
    'td_dias': tdDias,
    'tr_dias': trDias,
    'jornada_horas': jornadaHoras,
    'mudanca_parcela_min': mudancaParcelaMin,
    'periodo_dias': periodoDias,
    'tabuleiros_por_parcela': tabuleirosPorParcela,
  };

  factory BasinProject.fromMap(Object? data) {
    if (data is! Map) {
      throw const FormatException('Projeto de inundação em formato inválido.');
    }
    final map = Map<String, dynamic>.from(data);
    double? numero(String chave) {
      final valor = map[chave];
      return valor is num ? valor.toDouble() : null;
    }

    int inteiro(String chave, int padrao) {
      final valor = map[chave];
      if (valor is int) return valor;
      if (valor is num) return valor.toInt();
      if (valor is String) {
        final parsed = int.tryParse(valor);
        if (parsed != null) return parsed;
        throw FormatException('Contagem inválida em $chave.');
      }
      return padrao;
    }

    List<double> lista(String chave) {
      final valor = map[chave];
      if (valor is! List) return const [];
      return valor.whereType<num>().map((item) => item.toDouble()).toList();
    }

    final versao = inteiro('versao', versaoAtual);
    return BasinProject(
      versao: versao,
      legado: map['legado'] == true,
      regime: TipoInundacaoExtension.fromString(map['regime'] as String?),
      cenarioInfiltracao: CenarioInfiltracaoBasinExtension.fromString(
        map['cenario_infiltracao'] as String?,
      ),
      dadosPrimeira: map['dados_primeira'] is Map
          ? BasinInfiltrationScenario.fromMap(map['dados_primeira'])
          : null,
      dadosTerceira: map['dados_terceira'] is Map
          ? BasinInfiltrationScenario.fromMap(map['dados_terceira'])
          : null,
      k: numero('k'),
      a: numero('a'),
      vibMMin: numero('vib_m_min'),
      rugosidadeN: numero('rugosidade_n'),
      texturaSolo: map['textura_solo'] is String
          ? TexturaSoloExtension.fromString(map['textura_solo'] as String?)
          : null,
      comprimentoAreaM: numero('comprimento_area_m'),
      larguraAreaM: numero('largura_area_m'),
      comprimentoM: numero('comprimento_m'),
      larguraM: numero('largura_m'),
      areaUtilM2: numero('area_util_m2'),
      cultura: map['cultura'] as String?,
      agronomia: map['agronomia'] is Map
          ? BasinAgronomy.fromMap(map['agronomia'])
          : null,
      metodoEtc: MetodoEtc.values.firstWhere(
        (item) => item.name == map['metodo_etc'],
        orElse: () => MetodoEtc.adotada,
      ),
      origemChuva: OrigemChuva.values.firstWhere(
        (item) => item.name == map['origem_chuva'],
        orElse: () => OrigemChuva.naoInformada,
      ),
      origemIrn: OrigemIrnBasinExtension.fromString(
        map['origem_irn'] as String?,
      ),
      etoMmDia: numero('eto_mm_dia'),
      precipitacaoEfetivaMmDia: numero('precipitacao_efetiva_mm_dia'),
      temperaturaMediaC: numero('temperatura_media_c'),
      latitudeGraus: numero('latitude_graus'),
      mesReferencia: map['mes_referencia'] is num
          ? (map['mes_referencia'] as num).toInt()
          : null,
      declividade: numero('declividade'),
      alturaDiqueM: numero('altura_dique_m'),
      baseDiqueM: numero('base_dique_m'),
      margemLivreM: numero('margem_livre_m'),
      rho1F02: numero('rho1_f02'),
      rho2F02: numero('rho2_f02'),
      vmaxF02: numero('vmax_f02'),
      laminaRequeridaMm: numero('lamina_requerida_mm'),
      etIntermitenteMmDia: numero('et_intermitente_mm_dia'),
      intervaloDias: map['intervalo_dias'] is num
          ? (map['intervalo_dias'] as num).toInt()
          : null,
      vazaoTotalLs: numero('vazao_total_l_s'),
      vmaxMMin: numero('vmax_m_min') ?? vmaxMMinPadrao,
      candidatasVazaoLs: lista('candidatas_vazao_l_s'),
      laminaInicialMm: numero('lamina_inicial_mm'),
      laminaFinalMm: numero('lamina_final_mm'),
      rInicial: numero('r_inicial') ?? rInicialPadrao,
      areaHectares: numero('area_hectares'),
      porosidade: numero('porosidade'),
      profundidadeCamadaMm: numero('profundidade_camada_mm'),
      condutividadeHidraulicaMmDia: numero('condutividade_hidraulica_mm_dia'),
      dtaMmCm: numero('dta_mm_cm'),
      fatorDisponibilidade: numero('fator_disponibilidade'),
      evapotranspiracaoMmDia: numero('evapotranspiracao_mm_dia'),
      laminaSuperficialMm: numero('lamina_superficial_mm'),
      vazaoDisponivelLps: numero('vazao_disponivel_l_s'),
      dsGcm3: numero('ds_g_cm3'),
      dpGcm3: numero('dp_g_cm3'),
      pciM: numero('pci_m'),
      alturaLaminaRiceM: numero('altura_lamina_rice_m'),
      evaporacaoTanqueMmDia: numero('evaporacao_tanque_mm_dia'),
      ksatMDia: numero('ksat_m_dia'),
      periodoArrozDias: numero('periodo_arroz_dias'),
      produtividadeSacosHa: numero('produtividade_sacos_ha'),
      umidadeGraos: numero('umidade_graos'),
      indiceColheita: numero('indice_colheita'),
      uaGravimetrica: numero('ua_gravimetrica'),
      massaSacoKg: numero('massa_saco_kg'),
      areaArrozHa: numero('area_arroz_ha'),
      tdDias: numero('td_dias'),
      trDias: numero('tr_dias'),
      jornadaHoras: numero('jornada_horas') ?? 24,
      mudancaParcelaMin: numero('mudanca_parcela_min') ?? 0,
      periodoDias: inteiro('periodo_dias', 10),
      tabuleirosPorParcela: inteiro('tabuleiros_por_parcela', 1),
    );
  }

  /// Registros antigos sem o contrato versionado viram projeto legado
  /// (versão 0) montado a partir dos campos planos dos parâmetros; nada é
  /// fabricado para campos que os parâmetros não trazem.
  factory BasinProject.fromLegacy(IrrigationParameters params) => BasinProject(
    versao: 0,
    legado: true,
    regime: params.tipoInundacao,
    comprimentoAreaM: params.comprimento,
    larguraAreaM: params.larguraOuEspacamento,
    comprimentoM: params.comprimento,
    larguraM: params.larguraOuEspacamento,
    declividade: params.declividade,
    k: params.k,
    a: params.a,
    vibMMin: params.vib,
    rugosidadeN: params.manningN,
    vazaoTotalLs: params.vazao,
    laminaRequeridaMm: params.laminaRequerida,
    areaHectares: params.areaHectares,
    porosidade: params.porosidade,
    profundidadeCamadaMm: params.profundidadeCamadaMm,
    condutividadeHidraulicaMmDia: params.condutividadeHidraulicaMmDia,
    dtaMmCm: params.dtaMmCm,
    fatorDisponibilidade: params.fatorDisponibilidade,
    evapotranspiracaoMmDia: params.evapotranspiracaoMmDia,
    laminaSuperficialMm: params.laminaSuperficialMm,
    vazaoDisponivelLps: params.vazaoDisponivelLps,
    jornadaHoras: params.jornadaDiariaH,
    mudancaParcelaMin: params.tempoMudancaParcelaMin,
    periodoDias: params.periodoIrrigacaoDias,
  );

  /// Ponte para a camada de parâmetros usada pelos simuladores. Os campos
  /// obrigatórios são os que os validadores do wizard já exigiram; o regime
  /// permanente não usa k/a/VIB, então caem em defaults inertes. Clima e IRN
  /// materializam os getters derivados (Fase 5): ausente nunca vira zero, os
  /// defaults finais são apenas o porto legado para execução.
  IrrigationParameters toCompatParameters() => IrrigationParameters(
    projetoInundacao: this,
    tipoInundacao: regime,
    comprimento: comprimentoM ?? 100,
    declividade: declividade ?? 0,
    larguraOuEspacamento: larguraM ?? 20,
    k: k ?? 0.5,
    a: a ?? 0.5,
    vib: vibMMin ?? 0.0002,
    vazao: vazaoAplicadaLs ?? vazaoDisponivelLps ?? 0,
    tempoAplicacao: 0,
    laminaRequerida:
        irnEfetivaMm ?? laminaRequeridaMm ?? laminaSuperficialMm ?? 0,
    manningN: rugosidadeN ?? 0.04,
    texturaSolo: texturaSolo ?? TexturaSolo.media,
    areaHectares:
        areaHectares ??
        (areaUtilM2 != null
            ? areaUtilM2! / 10000
            : (areaTabuleiroM2 != null ? areaTabuleiroM2! / 10000 : 2)),
    porosidade: porosidade ?? 0.5,
    profundidadeCamadaMm: profundidadeCamadaMm ?? 500,
    condutividadeHidraulicaMmDia: condutividadeHidraulicaMmDia ?? 7,
    dtaMmCm: dtaMmCm ?? 2,
    fatorDisponibilidade: fatorDisponibilidade ?? 0.5,
    evapotranspiracaoMmDia:
        etcMmDia ?? evapotranspiracaoMmDia ?? etIntermitenteMmDia ?? 7.2,
    laminaSuperficialMm: laminaSuperficialMm ?? 150,
    vazaoDisponivelLps: vazaoDisponivelLps ?? vazaoTotalLs ?? 36,
    jornadaDiariaH: jornadaHoras,
    tempoMudancaParcelaMin: mudancaParcelaMin,
    periodoIrrigacaoDias: periodoDias,
  );
}
