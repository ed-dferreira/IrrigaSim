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

class BorderAlternativeRecord {
  final double comprimentoM, vazaoLsM;
  final double? eficienciaPercentual;
  final String? motivoRejeicao;

  /// Código canônico da rejeição (null para candidata viável/antiga).
  final BorderStatus? status;
  const BorderAlternativeRecord(
    this.comprimentoM,
    this.vazaoLsM,
    this.eficienciaPercentual,
    this.motivoRejeicao, [
    this.status,
  ]);
  Map<String, dynamic> toMap() => {
    'comprimentoM': comprimentoM,
    'vazaoLsM': vazaoLsM,
    'eficienciaPercentual': eficienciaPercentual,
    'motivoRejeicao': motivoRejeicao,
    'status': status?.codigo,
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
  final OrigemIrnFaixa origemIrn;
  final TexturaSolo? textura;
  final BorderAgronomy? agronomia;
  final List<BorderStake> estacas;
  final double? corteEnsaioMin;
  final double? comprimentoAreaM, larguraAreaM, comprimentoM, larguraM;
  final double? desnivelLongitudinalM, baseLongitudinalM;
  final double? desnivelTransversalM, baseTransversalM;
  final double? alturaDiqueM, laminaSuperficialM;
  final double? k, a, vibMMin, rugosidadeN, vazaoUnitariaLsM, irnMm;
  final double? rInicial, vazaoDisponivelLs;
  final double? jornadaHoras, janelaFornecimentoHorasDia, mudancaMin;
  final double? inicioFornecimentoH;
  final int? periodoDias, faixasSimultaneas;
  final List<int> diasFornecimento;
  final List<BorderAlternativeRecord> alternativas;
  final String? cultura;

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
    this.origemIrn = OrigemIrnFaixa.informada,
    this.textura,
    this.agronomia,
    this.estacas = const [],
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
    this.k,
    this.a,
    this.vibMMin,
    this.rugosidadeN,
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
    this.cultura,
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
    OrigemIrnFaixa? origemIrn,
    TexturaSolo? textura,
    BorderAgronomy? agronomia,
    List<BorderStake>? estacas,
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
    double? k,
    double? a,
    double? vibMMin,
    double? rugosidadeN,
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
    String? cultura,
  }) => BorderProject(
    versao: versao,
    numerico: numerico ?? this.numerico,
    legado: legado,
    jusante: jusante ?? this.jusante,
    cobertura: cobertura ?? this.cobertura,
    manejo: manejo ?? this.manejo,
    cenarioInfiltracao: cenarioInfiltracao ?? this.cenarioInfiltracao,
    origemIrn: origemIrn ?? this.origemIrn,
    textura: textura ?? this.textura,
    agronomia: agronomia ?? this.agronomia,
    estacas: estacas ?? this.estacas,
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
    k: k ?? this.k,
    a: a ?? this.a,
    vibMMin: vibMMin ?? this.vibMMin,
    rugosidadeN: rugosidadeN ?? this.rugosidadeN,
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
    cultura: cultura ?? this.cultura,
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
    'origemIrn': origemIrn.name,
    'textura': textura?.name,
    'agronomia': agronomia?.toMap(),
    'estacas': estacas.map((s) => s.toMap()).toList(),
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
    'k': k,
    'a': a,
    'vibMMin': vibMMin,
    'rugosidadeN': rugosidadeN,
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
    'cultura': cultura,
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
      k: n('k'),
      a: n('a'),
      vibMMin: n('vibMMin'),
      rugosidadeN: n('rugosidadeN'),
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
      cultura: map['cultura'] as String?,
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
