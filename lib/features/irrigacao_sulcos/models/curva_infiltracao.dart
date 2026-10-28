import 'dart:math' as math;

import 'proveniencia_dado.dart';

/// Forma como a curva de infiltração foi informada.
enum TipoCurvaInfiltracao {
  /// Taxa instantânea: `VI = C · T^n`, com `VI` em mm/h ou L/min/m.
  taxa,

  /// Lâmina acumulada: `I = C · T^a`, com `I` em mm ou L/m.
  acumulada,
}

/// Base física do coeficiente da curva.
enum BaseInfiltracao {
  /// Coeficiente em mm/h (taxa) ou mm (acumulada).
  milimetros,

  /// Coeficiente em L/min/m (taxa) ou L/m (acumulada).
  litrosPorMetro,
}

/// Curva de infiltração de um sulco.
///
/// O tempo é sempre interpretado em minutos. Quando a curva é do tipo
/// [TipoCurvaInfiltracao.taxa], ela é convertida internamente para a forma
/// acumulada `I(mm) = C · T^a` antes de ser usada no balanço:
///
/// ```text
/// a = n + 1
/// C = K / (60 · a)        (base mm/h)
/// C = K / (E · a)         (base L/min/m, E em m)
/// ```
///
/// `VIB` é um dado auxiliar de alerta; nunca é somada automaticamente à curva
/// ajustada. Essa separação evita contar a infiltração básica duas vezes.
class CurvaInfiltracao {
  const CurvaInfiltracao({
    required this.tipo,
    required this.base,
    required this.coeficiente,
    required this.expoente,
    required this.proveniencia,
    this.espacamentoConversaoM,
    this.vibMmHora,
    this.dataEnsaio,
    this.tempoMinCalibrado,
    this.tempoMaxCalibrado,
  });

  final TipoCurvaInfiltracao tipo;
  final BaseInfiltracao base;
  final double coeficiente;
  final double expoente;
  final ProvenienciaDado proveniencia;

  /// Espaçamento entre sulcos usado no ensaio.
  ///
  /// Obrigatório apenas para [BaseInfiltracao.litrosPorMetro], pois converte
  /// lâmina por metro linear em lâmina por área.
  final double? espacamentoConversaoM;

  /// Velocidade de infiltração básica opcional, em mm/h.
  final double? vibMmHora;

  final DateTime? dataEnsaio;

  /// Menor e maior tempos (min) cobertos pela calibração.
  final double? tempoMinCalibrado;
  final double? tempoMaxCalibrado;

  String get unidadeCoeficiente => switch ((tipo, base)) {
    (TipoCurvaInfiltracao.taxa, BaseInfiltracao.milimetros) => 'mm/h·min^(-n)',
    (TipoCurvaInfiltracao.taxa, BaseInfiltracao.litrosPorMetro) =>
      'L/min/m·min^(-n)',
    (TipoCurvaInfiltracao.acumulada, BaseInfiltracao.milimetros) => 'mm/min^a',
    (TipoCurvaInfiltracao.acumulada, BaseInfiltracao.litrosPorMetro) =>
      'L/m/min^a',
  };

  /// Garante que a curva pertence ao domínio físico usado pelos cálculos.
  void validar() {
    final coeficienteInvalido = !coeficiente.isFinite || coeficiente <= 0;
    final expoenteInvalido =
        !expoente.isFinite ||
        (tipo == TipoCurvaInfiltracao.taxa && expoente <= -1) ||
        (tipo == TipoCurvaInfiltracao.acumulada && expoente <= 0);
    final vibInvalida =
        vibMmHora != null && (!vibMmHora!.isFinite || vibMmHora! <= 0);
    final calibracaoInvalida =
        (tempoMinCalibrado != null &&
            (!tempoMinCalibrado!.isFinite || tempoMinCalibrado! < 0)) ||
        (tempoMaxCalibrado != null &&
            (!tempoMaxCalibrado!.isFinite || tempoMaxCalibrado! <= 0)) ||
        (tempoMinCalibrado != null &&
            tempoMaxCalibrado != null &&
            tempoMinCalibrado! >= tempoMaxCalibrado!);

    if (coeficienteInvalido ||
        expoenteInvalido ||
        vibInvalida ||
        calibracaoInvalida) {
      throw const FormatException(
        'Curva de infiltração: coeficientes ou intervalo temporal fora do domínio.',
      );
    }

    final exigeEspacamento = base == BaseInfiltracao.litrosPorMetro;
    final espacamentoInvalido =
        espacamentoConversaoM == null ||
        !espacamentoConversaoM!.isFinite ||
        espacamentoConversaoM! <= 0;
    if (exigeEspacamento && espacamentoInvalido) {
      throw const FormatException(
        'Curva em L/min/m ou L/m requer o espaçamento E medido usado na conversão.',
      );
    }
  }

  /// Converte a curva para a forma acumulada em milímetros.
  ///
  /// Retorna os parâmetros de `I(mm) = coeficiente · T^expoente`, com `T` em
  /// minutos. Não soma `VIB · T`; a VIB é um limite de alerta independente.
  ({double coeficiente, double expoente}) parametrosAcumulados() {
    validar();

    final fatorBase = base == BaseInfiltracao.milimetros
        ? 1.0
        : 1 / espacamentoConversaoM!;
    final expoenteAcumulado = tipo == TipoCurvaInfiltracao.taxa
        ? expoente + 1
        : expoente;
    final coeficienteAcumulado = tipo == TipoCurvaInfiltracao.taxa
        ? coeficiente *
              fatorBase *
              (base == BaseInfiltracao.milimetros ? 1 / 60 : 1) /
              expoenteAcumulado
        : coeficiente * fatorBase;

    if (!coeficienteAcumulado.isFinite ||
        coeficienteAcumulado <= 0 ||
        !expoenteAcumulado.isFinite ||
        expoenteAcumulado <= 0) {
      throw const FormatException(
        'Curva de infiltração extrapola o domínio numérico.',
      );
    }

    return (coeficiente: coeficienteAcumulado, expoente: expoenteAcumulado);
  }

  /// Taxa de infiltração instantânea em mm/h no instante [tempoMin].
  double taxaMmPorHora(double tempoMin) {
    validar();
    if (!tempoMin.isFinite || tempoMin <= 0) {
      throw const FormatException(
        'VI exige tempo positivo (singular em T=0 para expoente negativo).',
      );
    }
    final curva = parametrosAcumulados();
    return 60 *
        curva.coeficiente *
        curva.expoente *
        math.pow(tempoMin, curva.expoente - 1);
  }

  /// Primeiro instante em que a taxa cai abaixo da VIB, se isso ocorrer.
  ///
  /// Retorna `null` quando não há VIB informada, quando a taxa é crescente ou
  /// quando o cruzamento não tem solução no domínio.
  double? tempoCruzamentoVibMin() {
    if (vibMmHora == null) return null;

    final curva = parametrosAcumulados();
    final expoenteTaxa = curva.expoente - 1;
    if (expoenteTaxa == 0) {
      return taxaMmPorHora(1) < vibMmHora! ? 0 : null;
    }
    if (expoenteTaxa > 0) return null;

    final cruzamento = math
        .pow(
          vibMmHora! / (60 * curva.coeficiente * curva.expoente),
          1 / expoenteTaxa,
        )
        .toDouble();
    return cruzamento.isFinite && cruzamento >= 0 ? cruzamento : null;
  }

  /// Avisos não bloqueantes quando o perfil usa tempos fora da calibração ou
  /// quando a taxa calculada fica abaixo da VIB.
  String? avisoParaOportunidade(double maiorTempoMin, {double? menorTempoMin}) {
    if (!maiorTempoMin.isFinite || maiorTempoMin < 0) {
      throw const FormatException(
        'Oportunidade fora do domínio da infiltração.',
      );
    }

    final avisos = <String>[];
    final minimoForaDaCalibracao =
        tempoMinCalibrado != null &&
        (menorTempoMin == null || menorTempoMin < tempoMinCalibrado!);
    final maximoForaDaCalibracao =
        tempoMaxCalibrado != null && maiorTempoMin > tempoMaxCalibrado!;
    if (minimoForaDaCalibracao || maximoForaDaCalibracao) {
      avisos.add(
        'Perfil fora do intervalo temporal calibrado; resultado apenas formal.',
      );
    }

    final cruzamento = tempoCruzamentoVibMin();
    final taxaAbaixoDaVib =
        cruzamento != null &&
        maiorTempoMin > 0 &&
        maiorTempoMin > cruzamento &&
        taxaMmPorHora(maiorTempoMin) < vibMmHora!;
    if (taxaAbaixoDaVib) {
      avisos.add(
        'VI cai abaixo da VIB (${vibMmHora!.toStringAsFixed(2)} mm/h) '
        'após ${cruzamento.toStringAsFixed(3)} min; resultado apenas formal '
        '(Aula 6, p.101). Escolha outra calibração/modelo.',
      );
    }

    return avisos.isEmpty ? null : avisos.join(' ');
  }

  CurvaInfiltracao copyWith({
    TipoCurvaInfiltracao? tipo,
    BaseInfiltracao? base,
    double? coeficiente,
    double? expoente,
    double? espacamentoConversaoM,
    bool clearEspacamento = false,
    double? vibMmHora,
    bool clearVib = false,
    DateTime? dataEnsaio,
    bool clearData = false,
    double? tempoMinCalibrado,
    bool clearTempoMin = false,
    double? tempoMaxCalibrado,
    bool clearTempoMax = false,
    ProvenienciaDado? proveniencia,
  }) => CurvaInfiltracao(
    tipo: tipo ?? this.tipo,
    base: base ?? this.base,
    coeficiente: coeficiente ?? this.coeficiente,
    expoente: expoente ?? this.expoente,
    espacamentoConversaoM: clearEspacamento
        ? null
        : espacamentoConversaoM ?? this.espacamentoConversaoM,
    vibMmHora: clearVib ? null : vibMmHora ?? this.vibMmHora,
    dataEnsaio: clearData ? null : dataEnsaio ?? this.dataEnsaio,
    tempoMinCalibrado: clearTempoMin
        ? null
        : tempoMinCalibrado ?? this.tempoMinCalibrado,
    tempoMaxCalibrado: clearTempoMax
        ? null
        : tempoMaxCalibrado ?? this.tempoMaxCalibrado,
    proveniencia: proveniencia ?? this.proveniencia,
  );

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'tipo': tipo.name,
    'base': base.name,
    'coeficiente': coeficiente,
    'expoente': expoente,
    'unidade_coeficiente': unidadeCoeficiente,
    'espacamento_conversao_m': espacamentoConversaoM,
    'vib_mm_h': vibMmHora,
    'data_ensaio': dataEnsaio?.toIso8601String(),
    'tempo_min_calibrado': tempoMinCalibrado,
    'tempo_max_calibrado': tempoMaxCalibrado,
    'proveniencia': proveniencia.name,
  };

  factory CurvaInfiltracao.fromMap(Map<String, dynamic> map) =>
      CurvaInfiltracao(
        tipo: TipoCurvaInfiltracao.values.byName(map['tipo'] as String),
        base: BaseInfiltracao.values.byName(map['base'] as String),
        coeficiente: (map['coeficiente'] as num).toDouble(),
        expoente: (map['expoente'] as num).toDouble(),
        espacamentoConversaoM: (map['espacamento_conversao_m'] as num?)
            ?.toDouble(),
        vibMmHora: (map['vib_mm_h'] as num?)?.toDouble(),
        dataEnsaio: DateTime.tryParse(map['data_ensaio'] as String? ?? ''),
        tempoMinCalibrado: (map['tempo_min_calibrado'] as num?)?.toDouble(),
        tempoMaxCalibrado: (map['tempo_max_calibrado'] as num?)?.toDouble(),
        proveniencia: ProvenienciaDado.values.byName(
          map['proveniencia'] as String? ?? ProvenienciaDado.naoInformado.name,
        ),
      );
}
