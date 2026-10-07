import 'package:irrigasim/models/irrigation_parameters.dart';

import 'border_agronomy.dart';
import 'border_measurements.dart';
import 'border_numeric.dart';
import 'border_result.dart';

enum CondicaoJusanteFaixa { aberta, fechada }

enum CoberturaFaixa { soloExposto, culturaInstalada, coberturaTotal }

enum OrigemIrnFaixa { informada, calculada }

enum ManejoFaixa { vazaoConstante, vazaoReduzida, reuso }

enum CenarioInfiltracaoFaixa { primeira, terceira, informado }

class BorderInfiltrationScenario {
  final double? k, a, vibMMin;
  const BorderInfiltrationScenario({this.k, this.a, this.vibMMin});
  Map<String, dynamic> toMap() => {'k': k, 'a': a, 'vibMMin': vibMMin};
  factory BorderInfiltrationScenario.fromMap(Map<String, dynamic> map) =>
      BorderInfiltrationScenario(
        k: (map['k'] as num?)?.toDouble(),
        a: (map['a'] as num?)?.toDouble(),
        vibMMin: (map['vibMMin'] as num?)?.toDouble(),
      );
}

class BorderAlternativeRecord {
  final double comprimentoM, vazaoLsM;
  final double? eficienciaPercentual, erPercentual, ppPercentual, pePercentual;
  final double? demandaLs;
  final double? gradeMenorLsM, gradeMaiorLsM, gradePassoLsM;
  final String? objetivo;
  final String? motivoRejeicao;
  final bool selecionada;

  /// Código canônico da rejeição (null para candidata viável/antiga).
  final BorderStatus? status;
  const BorderAlternativeRecord(
    this.comprimentoM,
    this.vazaoLsM,
    this.eficienciaPercentual,
    this.motivoRejeicao, [
    this.status,
  ]) : erPercentual = null,
       ppPercentual = null,
       pePercentual = null,
       demandaLs = null,
       gradeMenorLsM = null,
       gradeMaiorLsM = null,
       gradePassoLsM = null,
       objetivo = null,
       selecionada = false;
  const BorderAlternativeRecord.withMetrics(
    this.comprimentoM,
    this.vazaoLsM,
    this.eficienciaPercentual,
    this.motivoRejeicao, {
    this.status,
    this.erPercentual,
    this.ppPercentual,
    this.pePercentual,
    this.demandaLs,
    this.gradeMenorLsM,
    this.gradeMaiorLsM,
    this.gradePassoLsM,
    this.objetivo,
    this.selecionada = false,
  });
  Map<String, dynamic> toMap() => {
    'comprimentoM': comprimentoM,
    'vazaoLsM': vazaoLsM,
    'eficienciaPercentual': eficienciaPercentual,
    'motivoRejeicao': motivoRejeicao,
    'status': status?.codigo,
    'erPercentual': erPercentual,
    'ppPercentual': ppPercentual,
    'pePercentual': pePercentual,
    'demandaLs': demandaLs,
    'gradeMenorLsM': gradeMenorLsM,
    'gradeMaiorLsM': gradeMaiorLsM,
    'gradePassoLsM': gradePassoLsM,
    'objetivo': objetivo,
    'selecionada': selecionada,
  };
  factory BorderAlternativeRecord.fromMap(Map<String, dynamic> data) =>
      BorderAlternativeRecord(
        (data['comprimentoM'] as num).toDouble(),
        (data['vazaoLsM'] as num).toDouble(),
        (data['eficienciaPercentual'] as num?)?.toDouble(),
        data['motivoRejeicao'] as String?,
        data['status'] == null
            ? null
            : BorderStatus.deNome(data['status'] as String?),
      ).copyWithMetrics(
        erPercentual: (data['erPercentual'] as num?)?.toDouble(),
        ppPercentual: (data['ppPercentual'] as num?)?.toDouble(),
        pePercentual: (data['pePercentual'] as num?)?.toDouble(),
        demandaLs: (data['demandaLs'] as num?)?.toDouble(),
        gradeMenorLsM: (data['gradeMenorLsM'] as num?)?.toDouble(),
        gradeMaiorLsM: (data['gradeMaiorLsM'] as num?)?.toDouble(),
        gradePassoLsM: (data['gradePassoLsM'] as num?)?.toDouble(),
        objetivo: data['objetivo'] as String?,
        selecionada: data['selecionada'] == true,
      );

  BorderAlternativeRecord copyWithMetrics({
    double? erPercentual,
    double? ppPercentual,
    double? pePercentual,
    double? demandaLs,
    double? gradeMenorLsM,
    double? gradeMaiorLsM,
    double? gradePassoLsM,
    String? objetivo,
    bool? selecionada,
  }) => BorderAlternativeRecord.withMetrics(
    comprimentoM,
    vazaoLsM,
    eficienciaPercentual,
    motivoRejeicao,
    status: status,
    erPercentual: erPercentual ?? this.erPercentual,
    ppPercentual: ppPercentual ?? this.ppPercentual,
    pePercentual: pePercentual ?? this.pePercentual,
    demandaLs: demandaLs ?? this.demandaLs,
    gradeMenorLsM: gradeMenorLsM ?? this.gradeMenorLsM,
    gradeMaiorLsM: gradeMaiorLsM ?? this.gradeMaiorLsM,
    gradePassoLsM: gradePassoLsM ?? this.gradePassoLsM,
    objetivo: objetivo ?? this.objetivo,
    selecionada: selecionada ?? this.selecionada,
  );
}

/// Entradas de projeto; valores nulos representam dados ainda não informados.
/// Comprimentos e lâminas em m (IRN em mm), tempos em min e q0 em L/s/m.
class BorderProject {
  static const versaoAtual = 1;

  /// Segmentos do perfil longitudinal; o pacote de referência usa 2000.
  static const nSegmentosPadrao = BorderNumericConfig.nSegmentosPadrao;
  final int versao;

  /// Grupo numérico declarado (tolerâncias, iterações, segmentos, versão dos
  /// expoentes da recessão e método de integração).
  final BorderNumericConfig numerico;
  final bool legado;
  final CondicaoJusanteFaixa jusante;
  final CoberturaFaixa cobertura;
  final ManejoFaixa manejo;
  final CenarioInfiltracaoFaixa cenarioInfiltracao;
  final BorderInfiltrationScenario? dadosPrimeira, dadosTerceira;
  final OrigemIrnFaixa origemIrn;
  final TexturaSolo? textura;
  final BorderAgronomy? agronomia;
  final List<BorderStake> estacas;
  final List<BorderTerrainPoint> perfilLongitudinal;
  final String? dataEnsaioIso, referenciaRelogioEnsaio, observacoesEnsaio;
  final double? corteEnsaioMin;
  final double? comprimentoAreaM, larguraAreaM, comprimentoM, larguraM;
  final double? desnivelLongitudinalM, baseLongitudinalM;
  final double? desnivelTransversalM, baseTransversalM;
  final double? alturaDiqueM, laminaSuperficialM;
  final double? fracaoCortePlanejada;
  final double? k, a, vibMMin, rugosidadeN, vazaoUnitariaLsM, irnMm;
  final double? rho1F02, rho2F02, vmaxF02;
  final String? unidadeVmaxF02;
  final double? rInicial, vazaoDisponivelLs;
  final double? jornadaHoras, janelaFornecimentoHorasDia, mudancaMin;
  final double? inicioFornecimentoH;
  final int? periodoDias, faixasSimultaneas;
  final List<int> diasFornecimento;
  final List<BorderAlternativeRecord> alternativas;
  final double? dispositivoDiametroCm, dispositivoCargaCm;
  final String? cultura;
  final String? tipoDique;
  final String? orientacaoArea;
  final double? areaUtilM2;

  /// Apenas em registros rápidos antigos; nunca controla o corte dimensionado.
  final double? tempoAplicacaoLegadoMin;

  const BorderProject({
    this.versao = versaoAtual,
    this.numerico = BorderNumericConfig.padrao,
    this.legado = false,
    this.jusante = CondicaoJusanteFaixa.aberta,
    this.cobertura = CoberturaFaixa.soloExposto,
    this.manejo = ManejoFaixa.vazaoConstante,
    this.cenarioInfiltracao = CenarioInfiltracaoFaixa.informado,
    this.dadosPrimeira,
    this.dadosTerceira,
    this.origemIrn = OrigemIrnFaixa.informada,
    this.textura,
    this.agronomia,
    this.estacas = const [],
    this.perfilLongitudinal = const [],
    this.dataEnsaioIso,
    this.referenciaRelogioEnsaio,
    this.observacoesEnsaio,
    this.corteEnsaioMin,
    this.comprimentoAreaM,
    this.larguraAreaM,
    this.comprimentoM,
    this.larguraM,
    this.desnivelLongitudinalM,
    this.baseLongitudinalM,
    this.desnivelTransversalM,
    this.baseTransversalM,
    this.alturaDiqueM,
    this.laminaSuperficialM,
    this.fracaoCortePlanejada,
    this.k,
    this.a,
    this.vibMMin,
    this.rugosidadeN,
    this.rho1F02,
    this.rho2F02,
    this.vmaxF02,
    this.unidadeVmaxF02,
    this.vazaoUnitariaLsM,
    this.irnMm,
    this.rInicial,
    this.vazaoDisponivelLs,
    this.jornadaHoras,
    this.janelaFornecimentoHorasDia,
    this.inicioFornecimentoH,
    this.mudancaMin,
    this.periodoDias,
    this.faixasSimultaneas,
    this.diasFornecimento = const [],
    this.alternativas = const [],
    this.dispositivoDiametroCm,
    this.dispositivoCargaCm,
    this.cultura,
    this.tipoDique,
    this.orientacaoArea,
    this.areaUtilM2,
    this.tempoAplicacaoLegadoMin,
  });

  /// Exemplo apenas ilustrativo, não representa dimensionamento recomendado.
  static const ilustrativo = BorderProject(
    cenarioInfiltracao: CenarioInfiltracaoFaixa.terceira,
    comprimentoAreaM: 400,
    larguraAreaM: 100,
    comprimentoM: 400,
    larguraM: 10,
    desnivelLongitudinalM: 0.8,
    baseLongitudinalM: 400,
    desnivelTransversalM: 0,
    baseTransversalM: 10,
    k: 0.0034,
    a: 0.45,
    vibMMin: 0.0001,
    rugosidadeN: 0.04,
    vazaoUnitariaLsM: 3.33,
    irnMm: 56,
    rInicial: 0.66,
  );

  /// Conveniência: segmentos do perfil pedidos pelo projeto.
  int get nSegmentos => numerico.nSegmentos;

  double? get declividadeLongitudinal =>
      baseLongitudinalM != null && baseLongitudinalM! > 0
      ? (desnivelLongitudinalM ?? 0) / baseLongitudinalM!
      : null;
  double? get declividadeTransversal =>
      baseTransversalM != null && baseTransversalM! > 0
      ? (desnivelTransversalM ?? 0) / baseTransversalM!
      : null;
  double? get vazaoFaixaLs => vazaoUnitariaLsM != null && larguraM != null
      ? vazaoUnitariaLsM! * larguraM!
      : null;

  /// Primeiro impedimento do modelo com código canônico §10.3 e, quando a
  /// fonte dita a exigência, a página correspondente.
  BorderNotice? get impedimento {
    final optionalPositive = <(String, double?)>[
      ('altura real do dique', alturaDiqueM),
      ('hn superficial', laminaSuperficialM),
      ('oferta de água Qt', vazaoDisponivelLs),
      ('jornada TDF', jornadaHoras),
      ('janela de fornecimento', janelaFornecimentoHorasDia),
      ('período PI', periodoDias?.toDouble()),
      ('número de faixas simultâneas NFP', faixasSimultaneas?.toDouble()),
      ('comprimento da área', comprimentoAreaM),
      ('largura da área', larguraAreaM),
      ('área útil', areaUtilM2),
      ('ρ1 da F02', rho1F02),
      ('ρ2 da F02', rho2F02),
      ('Vmax da F02', vmaxF02),
    ];
    for (final entry in optionalPositive) {
      final value = entry.$2;
      if (value != null && (!value.isFinite || value <= 0)) {
        return BorderNotice(
          BorderStatus.entradaInvalida,
          '${entry.$1} deve ser finito e positivo quando informado.',
        );
      }
    }
    if (areaUtilM2 != null &&
        comprimentoAreaM != null &&
        larguraAreaM != null &&
        areaUtilM2! > comprimentoAreaM! * larguraAreaM! + 1e-6) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Área útil não pode exceder a área bruta informada.',
      );
    }
    if (rho2F02 == 2) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'ρ2 da F02 não pode ser 2 na forma transcrita.',
        pagina: 'p. 53',
      );
    }
    if (mudancaMin != null && (!mudancaMin!.isFinite || mudancaMin! < 0)) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Tempo de mudança deve ser finito e não negativo.',
      );
    }
    if (inicioFornecimentoH != null &&
        (!inicioFornecimentoH!.isFinite ||
            inicioFornecimentoH! < 0 ||
            inicioFornecimentoH! >= 24)) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Início do fornecimento deve estar entre 0 e 24 h.',
      );
    }
    if (inicioFornecimentoH != null &&
        janelaFornecimentoHorasDia != null &&
        inicioFornecimentoH! + janelaFornecimentoHorasDia! > 24) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'A janela de fornecimento não pode ultrapassar o dia civil.',
      );
    }
    if (diasFornecimento.toSet().length != diasFornecimento.length ||
        diasFornecimento.any(
          (day) => day < 1 || (periodoDias != null && day > periodoDias!),
        )) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Dias de fornecimento devem ser distintos e estar dentro do PI.',
      );
    }
    if (dataEnsaioIso != null && DateTime.tryParse(dataEnsaioIso!) == null) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Data do ensaio deve usar formato ISO (AAAA-MM-DD).',
      );
    }
    if (perfilLongitudinal.isNotEmpty) {
      if (declividadeLongitudinal == null ||
          !declividadeLongitudinal!.isFinite ||
          declividadeLongitudinal! <= 0) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'Perfil topográfico longitudinal requer S0 médio positivo informado.',
        );
      }
      if (comprimentoAreaM == null ||
          perfilLongitudinal.length < 2 ||
          perfilLongitudinal.first.xM != 0 ||
          (perfilLongitudinal.last.xM - comprimentoAreaM!).abs() > 1e-6 ||
          perfilLongitudinal.any(
            (point) => !point.xM.isFinite || !point.cotaM.isFinite,
          ) ||
          List.generate(perfilLongitudinal.length - 1, (i) => i).any(
            (i) => perfilLongitudinal[i + 1].xM <= perfilLongitudinal[i].xM,
          )) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'Perfil longitudinal requer estacas crescentes, iniciando em 0 e terminando no comprimento total da área.',
        );
      }
      final directions = <int>{};
      final segmentSlopes = <double>[];
      for (var i = 0; i < perfilLongitudinal.length - 1; i++) {
        final left = perfilLongitudinal[i], right = perfilLongitudinal[i + 1];
        final delta = left.cotaM - right.cotaM;
        directions.add(delta.sign.toInt());
        segmentSlopes.add(delta.abs() / (right.xM - left.xM));
      }
      if (directions.length != 1 || directions.single == 0) {
        return const BorderNotice(
          BorderStatus.modeloNaoImplementado,
          'Perfil com inversão de declive ou trecho plano não é representado pelo modelo de declive único.',
          pagina: 'p. 12',
        );
      }
      if (segmentSlopes.any(
        (slope) => (slope - declividadeLongitudinal!).abs() > 1e-6,
      )) {
        return const BorderNotice(
          BorderStatus.modeloNaoImplementado,
          'Perfil longitudinal variável/terminal plano exige modelo por trechos; o motor usa S0 único.',
          pagina: 'p. 12',
        );
      }
    }
    if (origemIrn == OrigemIrnFaixa.calculada && agronomia?.irnMm == null) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'IRN calculada requer dados agronômicos completos.',
      );
    }
    if (jusante != CondicaoJusanteFaixa.aberta) {
      return const BorderNotice(
        BorderStatus.foraDoDominio,
        'Faixa fechada ainda não possui modelo de simulação.',
        pagina: '§2.1, pp. 2–11',
      );
    }
    if (manejo != ManejoFaixa.vazaoConstante) {
      return const BorderNotice(
        BorderStatus.modeloNaoImplementado,
        'Redução de vazão e reuso ainda não são simuláveis.',
        pagina: '§2.1, pp. 2–11',
      );
    }
    if (fracaoCortePlanejada != null) {
      if (!fracaoCortePlanejada!.isFinite ||
          fracaoCortePlanejada! < 2 / 3 ||
          fracaoCortePlanejada! > .75) {
        return const BorderNotice(
          BorderStatus.entradaInvalida,
          'A referência de corte precoce deve estar entre 2/3 e 3/4 de L.',
          pagina: 'p. 21',
        );
      }
      return const BorderNotice(
        BorderStatus.modeloNaoImplementado,
        'Corte antes do avanço completo requer modelar a água armazenada e o avanço restante; regra condicional não aplicada automaticamente.',
        pagina: 'pp. 21, 28–29, 64',
      );
    }
    if (declividadeLongitudinal == null ||
        !declividadeLongitudinal!.isFinite ||
        declividadeLongitudinal! <= 0) {
      return const BorderNotice(
        BorderStatus.foraDoDominio,
        'O modelo requer declive longitudinal positivo (S0 > 0).',
        pagina: 'pp. 53–55',
      );
    }
    if (declividadeTransversal == null ||
        !declividadeTransversal!.isFinite ||
        desnivelTransversalM == null) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Informe desnível e base de medida transversal (St).',
      );
    }
    if (comprimentoM == null ||
        comprimentoM! <= 0 ||
        larguraM == null ||
        larguraM! <= 0) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Informe comprimento e largura da faixa.',
      );
    }
    if (k == null ||
        k! <= 0 ||
        a == null ||
        a! <= 0 ||
        a! >= 1 ||
        vibMMin == null ||
        vibMMin! < 0) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Informe k > 0, 0 < a < 1 e VIB ≥ 0.',
        pagina: 'pp. 47, 56',
      );
    }
    if (irnEfetivaMm == null ||
        irnEfetivaMm! <= 0 ||
        vazaoUnitariaLsM == null ||
        vazaoUnitariaLsM! <= 0 ||
        rugosidadeN == null ||
        rugosidadeN! <= 0) {
      return const BorderNotice(
        BorderStatus.entradaInvalida,
        'Informe IRN, vazão unitária e rugosidade positivos.',
      );
    }
    final numeroInvalido = numerico.impedimento;
    if (numeroInvalido != null) {
      return BorderNotice(
        numerico.versaoExpoentesImplementada
            ? BorderStatus.entradaInvalida
            : BorderStatus.modeloNaoImplementado,
        numeroInvalido,
      );
    }
    return null;
  }

  String? get impedimentoModelo => impedimento?.mensagem;

  double? get irnEfetivaMm =>
      origemIrn == OrigemIrnFaixa.informada ? irnMm : agronomia?.irnMm;

  BorderProject copyWith({
    CondicaoJusanteFaixa? jusante,
    CoberturaFaixa? cobertura,
    ManejoFaixa? manejo,
    CenarioInfiltracaoFaixa? cenarioInfiltracao,
    BorderInfiltrationScenario? dadosPrimeira,
    BorderInfiltrationScenario? dadosTerceira,
    OrigemIrnFaixa? origemIrn,
    TexturaSolo? textura,
    BorderAgronomy? agronomia,
    List<BorderStake>? estacas,
    List<BorderTerrainPoint>? perfilLongitudinal,
    String? dataEnsaioIso,
    String? referenciaRelogioEnsaio,
    String? observacoesEnsaio,
    double? corteEnsaioMin,
    double? comprimentoAreaM,
    double? larguraAreaM,
    double? comprimentoM,
    double? larguraM,
    double? desnivelLongitudinalM,
    double? baseLongitudinalM,
    double? desnivelTransversalM,
    double? baseTransversalM,
    double? alturaDiqueM,
    double? laminaSuperficialM,
    double? fracaoCortePlanejada,
    double? k,
    double? a,
    double? vibMMin,
    double? rugosidadeN,
    double? rho1F02,
    double? rho2F02,
    double? vmaxF02,
    String? unidadeVmaxF02,
    double? vazaoUnitariaLsM,
    double? irnMm,
    double? rInicial,
    double? vazaoDisponivelLs,
    double? jornadaHoras,
    double? janelaFornecimentoHorasDia,
    double? inicioFornecimentoH,
    double? mudancaMin,
    int? periodoDias,
    int? faixasSimultaneas,
    BorderNumericConfig? numerico,
    List<int>? diasFornecimento,
    List<BorderAlternativeRecord>? alternativas,
    double? dispositivoDiametroCm,
    double? dispositivoCargaCm,
    String? cultura,
    String? tipoDique,
    String? orientacaoArea,
    double? areaUtilM2,
  }) => BorderProject(
    versao: versao,
    numerico: numerico ?? this.numerico,
    legado: legado,
    jusante: jusante ?? this.jusante,
    cobertura: cobertura ?? this.cobertura,
    manejo: manejo ?? this.manejo,
    cenarioInfiltracao: cenarioInfiltracao ?? this.cenarioInfiltracao,
    dadosPrimeira: dadosPrimeira ?? this.dadosPrimeira,
    dadosTerceira: dadosTerceira ?? this.dadosTerceira,
    origemIrn: origemIrn ?? this.origemIrn,
    textura: textura ?? this.textura,
    agronomia: agronomia ?? this.agronomia,
    estacas: estacas ?? this.estacas,
    perfilLongitudinal: perfilLongitudinal ?? this.perfilLongitudinal,
    dataEnsaioIso: dataEnsaioIso ?? this.dataEnsaioIso,
    referenciaRelogioEnsaio:
        referenciaRelogioEnsaio ?? this.referenciaRelogioEnsaio,
    observacoesEnsaio: observacoesEnsaio ?? this.observacoesEnsaio,
    corteEnsaioMin: corteEnsaioMin ?? this.corteEnsaioMin,
    comprimentoAreaM: comprimentoAreaM ?? this.comprimentoAreaM,
    larguraAreaM: larguraAreaM ?? this.larguraAreaM,
    comprimentoM: comprimentoM ?? this.comprimentoM,
    larguraM: larguraM ?? this.larguraM,
    desnivelLongitudinalM: desnivelLongitudinalM ?? this.desnivelLongitudinalM,
    baseLongitudinalM: baseLongitudinalM ?? this.baseLongitudinalM,
    desnivelTransversalM: desnivelTransversalM ?? this.desnivelTransversalM,
    baseTransversalM: baseTransversalM ?? this.baseTransversalM,
    alturaDiqueM: alturaDiqueM ?? this.alturaDiqueM,
    laminaSuperficialM: laminaSuperficialM ?? this.laminaSuperficialM,
    fracaoCortePlanejada: fracaoCortePlanejada ?? this.fracaoCortePlanejada,
    k: k ?? this.k,
    a: a ?? this.a,
    vibMMin: vibMMin ?? this.vibMMin,
    rugosidadeN: rugosidadeN ?? this.rugosidadeN,
    rho1F02: rho1F02 ?? this.rho1F02,
    rho2F02: rho2F02 ?? this.rho2F02,
    vmaxF02: vmaxF02 ?? this.vmaxF02,
    unidadeVmaxF02: unidadeVmaxF02 ?? this.unidadeVmaxF02,
    vazaoUnitariaLsM: vazaoUnitariaLsM ?? this.vazaoUnitariaLsM,
    irnMm: irnMm ?? this.irnMm,
    rInicial: rInicial ?? this.rInicial,
    vazaoDisponivelLs: vazaoDisponivelLs ?? this.vazaoDisponivelLs,
    jornadaHoras: jornadaHoras ?? this.jornadaHoras,
    janelaFornecimentoHorasDia:
        janelaFornecimentoHorasDia ?? this.janelaFornecimentoHorasDia,
    inicioFornecimentoH: inicioFornecimentoH ?? this.inicioFornecimentoH,
    mudancaMin: mudancaMin ?? this.mudancaMin,
    periodoDias: periodoDias ?? this.periodoDias,
    faixasSimultaneas: faixasSimultaneas ?? this.faixasSimultaneas,
    diasFornecimento: diasFornecimento ?? this.diasFornecimento,
    alternativas: alternativas ?? this.alternativas,
    dispositivoDiametroCm: dispositivoDiametroCm ?? this.dispositivoDiametroCm,
    dispositivoCargaCm: dispositivoCargaCm ?? this.dispositivoCargaCm,
    cultura: cultura ?? this.cultura,
    tipoDique: tipoDique ?? this.tipoDique,
    orientacaoArea: orientacaoArea ?? this.orientacaoArea,
    areaUtilM2: areaUtilM2 ?? this.areaUtilM2,
    tempoAplicacaoLegadoMin: tempoAplicacaoLegadoMin,
  );

  Map<String, dynamic> toMap() => {
    'versao': versao,
    'numerico': numerico.toMap(),
    'legado': legado,
    'jusante': jusante.name,
    'cobertura': cobertura.name,
    'manejo': manejo.name,
    'cenarioInfiltracao': cenarioInfiltracao.name,
    'dadosPrimeira': dadosPrimeira?.toMap(),
    'dadosTerceira': dadosTerceira?.toMap(),
    'origemIrn': origemIrn.name,
    'textura': textura?.name,
    'agronomia': agronomia?.toMap(),
    'estacas': estacas.map((s) => s.toMap()).toList(),
    'perfilLongitudinal': perfilLongitudinal.map((p) => p.toMap()).toList(),
    'dataEnsaioIso': dataEnsaioIso,
    'referenciaRelogioEnsaio': referenciaRelogioEnsaio,
    'observacoesEnsaio': observacoesEnsaio,
    'corteEnsaioMin': corteEnsaioMin,
    'comprimentoAreaM': comprimentoAreaM,
    'larguraAreaM': larguraAreaM,
    'comprimentoM': comprimentoM,
    'larguraM': larguraM,
    'desnivelLongitudinalM': desnivelLongitudinalM,
    'baseLongitudinalM': baseLongitudinalM,
    'desnivelTransversalM': desnivelTransversalM,
    'baseTransversalM': baseTransversalM,
    'alturaDiqueM': alturaDiqueM,
    'laminaSuperficialM': laminaSuperficialM,
    'fracaoCortePlanejada': fracaoCortePlanejada,
    'k': k,
    'a': a,
    'vibMMin': vibMMin,
    'rugosidadeN': rugosidadeN,
    'rho1F02': rho1F02,
    'rho2F02': rho2F02,
    'vmaxF02': vmaxF02,
    'unidadeVmaxF02': unidadeVmaxF02,
    'vazaoUnitariaLsM': vazaoUnitariaLsM,
    'irnMm': irnMm,
    'rInicial': rInicial,
    'vazaoDisponivelLs': vazaoDisponivelLs,
    'jornadaHoras': jornadaHoras,
    'janelaFornecimentoHorasDia': janelaFornecimentoHorasDia,
    'inicioFornecimentoH': inicioFornecimentoH,
    'mudancaMin': mudancaMin,
    'periodoDias': periodoDias,
    'faixasSimultaneas': faixasSimultaneas,
    'diasFornecimento': diasFornecimento,
    'alternativas': alternativas.map((a) => a.toMap()).toList(),
    'dispositivoDiametroCm': dispositivoDiametroCm,
    'dispositivoCargaCm': dispositivoCargaCm,
    'cultura': cultura,
    'tipoDique': tipoDique,
    'orientacaoArea': orientacaoArea,
    'areaUtilM2': areaUtilM2,
    'tempoAplicacaoLegadoMin': tempoAplicacaoLegadoMin,
  };

  factory BorderProject.fromMap(Map<String, dynamic> map) {
    double? n(String key) => (map[key] as num?)?.toDouble();
    int? inteiro(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is! num || value != value.roundToDouble()) {
        throw FormatException('$key deve ser inteiro.');
      }
      return value.toInt();
    }

    T choice<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((v) => v.name == map[key]).firstOrNull ?? fallback;
    return BorderProject(
      versao: (map['versao'] as num?)?.toInt() ?? versaoAtual,
      numerico: BorderNumericConfig.fromMap(
        map['numerico'] is Map
            ? Map<String, dynamic>.from(map['numerico'] as Map)
            : map,
      ),
      legado: map['legado'] == true,
      jusante: choice(
        CondicaoJusanteFaixa.values,
        'jusante',
        CondicaoJusanteFaixa.aberta,
      ),
      cobertura: choice(
        CoberturaFaixa.values,
        'cobertura',
        CoberturaFaixa.soloExposto,
      ),
      manejo: choice(ManejoFaixa.values, 'manejo', ManejoFaixa.vazaoConstante),
      cenarioInfiltracao: choice(
        CenarioInfiltracaoFaixa.values,
        'cenarioInfiltracao',
        CenarioInfiltracaoFaixa.informado,
      ),
      dadosPrimeira: map['dadosPrimeira'] is Map
          ? BorderInfiltrationScenario.fromMap(
              Map<String, dynamic>.from(map['dadosPrimeira'] as Map),
            )
          : null,
      dadosTerceira: map['dadosTerceira'] is Map
          ? BorderInfiltrationScenario.fromMap(
              Map<String, dynamic>.from(map['dadosTerceira'] as Map),
            )
          : null,
      origemIrn: choice(
        OrigemIrnFaixa.values,
        'origemIrn',
        OrigemIrnFaixa.informada,
      ),
      textura: TexturaSolo.values
          .where((e) => e.name == map['textura'])
          .firstOrNull,
      agronomia: map['agronomia'] is Map
          ? BorderAgronomy.fromMap(
              Map<String, dynamic>.from(map['agronomia'] as Map),
            )
          : null,
      estacas:
          (map['estacas'] as List<dynamic>?)
              ?.map(
                (e) => BorderStake.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      perfilLongitudinal:
          (map['perfilLongitudinal'] as List?)
              ?.map(
                (item) => BorderTerrainPoint.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
      dataEnsaioIso: map['dataEnsaioIso'] as String?,
      referenciaRelogioEnsaio: map['referenciaRelogioEnsaio'] as String?,
      observacoesEnsaio: map['observacoesEnsaio'] as String?,
      corteEnsaioMin: n('corteEnsaioMin'),
      comprimentoAreaM: n('comprimentoAreaM'),
      larguraAreaM: n('larguraAreaM'),
      comprimentoM: n('comprimentoM'),
      larguraM: n('larguraM'),
      desnivelLongitudinalM: n('desnivelLongitudinalM'),
      baseLongitudinalM: n('baseLongitudinalM'),
      desnivelTransversalM: n('desnivelTransversalM'),
      baseTransversalM: n('baseTransversalM'),
      alturaDiqueM: n('alturaDiqueM'),
      laminaSuperficialM: n('laminaSuperficialM'),
      fracaoCortePlanejada: n('fracaoCortePlanejada'),
      k: n('k'),
      a: n('a'),
      vibMMin: n('vibMMin'),
      rugosidadeN: n('rugosidadeN'),
      rho1F02: n('rho1F02'),
      rho2F02: n('rho2F02'),
      vmaxF02: n('vmaxF02'),
      unidadeVmaxF02: map['unidadeVmaxF02'] as String?,
      vazaoUnitariaLsM: n('vazaoUnitariaLsM'),
      irnMm: n('irnMm'),
      rInicial: n('rInicial'),
      vazaoDisponivelLs: n('vazaoDisponivelLs'),
      jornadaHoras: n('jornadaHoras'),
      janelaFornecimentoHorasDia: n('janelaFornecimentoHorasDia'),
      inicioFornecimentoH: n('inicioFornecimentoH'),
      mudancaMin: n('mudancaMin'),
      periodoDias: inteiro('periodoDias'),
      faixasSimultaneas: inteiro('faixasSimultaneas'),
      diasFornecimento:
          (map['diasFornecimento'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      alternativas:
          (map['alternativas'] as List?)
              ?.map(
                (e) => BorderAlternativeRecord.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      dispositivoDiametroCm: n('dispositivoDiametroCm'),
      dispositivoCargaCm: n('dispositivoCargaCm'),
      cultura: map['cultura'] as String?,
      tipoDique: map['tipoDique'] as String?,
      orientacaoArea: map['orientacaoArea'] as String?,
      areaUtilM2: n('areaUtilM2'),
      tempoAplicacaoLegadoMin: n('tempoAplicacaoLegadoMin'),
    );
  }

  factory BorderProject.fromLegacy(IrrigationParameters params) =>
      BorderProject(
        versao: 0,
        legado: true,
        comprimentoM: params.comprimento,
        larguraM: params.larguraOuEspacamento,
        desnivelLongitudinalM: params.declividade * params.comprimento,
        baseLongitudinalM: params.comprimento,
        desnivelTransversalM:
            params.declividadeTransversal * params.larguraOuEspacamento,
        baseTransversalM: params.larguraOuEspacamento,
        k: params.k,
        a: params.a,
        vibMMin: params.vib,
        rugosidadeN: params.manningN,
        vazaoUnitariaLsM: params.vazao,
        irnMm: params.laminaRequerida,
        rInicial: params.sigmaZ,
        tempoAplicacaoLegadoMin: params.tempoAplicacao,
      );

  IrrigationParameters toCompatParameters() => IrrigationParameters(
    projetoFaixa: this,
    comprimento: comprimentoM!,
    declividade: declividadeLongitudinal!,
    declividadeTransversal: declividadeTransversal ?? 0,
    larguraOuEspacamento: larguraM!,
    k: k!,
    a: a!,
    vib: vibMMin!,
    vazao: vazaoUnitariaLsM!,
    tempoAplicacao: tempoAplicacaoLegadoMin ?? 0,
    laminaRequerida: irnEfetivaMm!,
    manningN: rugosidadeN!,
    sigmaZ: rInicial ?? 0.7,
    vazaoDisponivelLps: vazaoDisponivelLs ?? 0,
    nomeCultura: cultura ?? '',
  );
}
