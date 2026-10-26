import 'dart:math' as math;

/// O tempo da lei potencial é sempre em minutos. VIB é informação separada,
/// nunca um termo adicionado automaticamente à curva ajustada.
enum TipoCurvaInfiltracaoSulco { taxa, acumulada }

enum BaseInfiltracaoSulco { milimetros, litrosPorMetro }

enum ProvenienciaSulco {
  naoInformado,
  ilustrativo,
  informado,
  medido,
  calculado,
}

class CurvaInfiltracaoSulco {
  const CurvaInfiltracaoSulco({
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

  final TipoCurvaInfiltracaoSulco tipo;
  final BaseInfiltracaoSulco base;
  final double coeficiente;
  final double expoente;
  final double? espacamentoConversaoM;
  final double? vibMmHora;
  final DateTime? dataEnsaio;
  final double? tempoMinCalibrado;
  final double? tempoMaxCalibrado;
  final ProvenienciaSulco proveniencia;

  CurvaInfiltracaoSulco copyWith({
    TipoCurvaInfiltracaoSulco? tipo,
    BaseInfiltracaoSulco? base,
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
    ProvenienciaSulco? proveniencia,
  }) => CurvaInfiltracaoSulco(
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

  String get unidadeCoeficiente => switch ((tipo, base)) {
    (TipoCurvaInfiltracaoSulco.taxa, BaseInfiltracaoSulco.milimetros) =>
      'mm/h·min^(-n)',
    (TipoCurvaInfiltracaoSulco.taxa, BaseInfiltracaoSulco.litrosPorMetro) =>
      'L/min/m·min^(-n)',
    (TipoCurvaInfiltracaoSulco.acumulada, BaseInfiltracaoSulco.milimetros) =>
      'mm/min^a',
    (
      TipoCurvaInfiltracaoSulco.acumulada,
      BaseInfiltracaoSulco.litrosPorMetro,
    ) =>
      'L/m/min^a',
  };

  void validar() {
    if (!coeficiente.isFinite ||
        coeficiente <= 0 ||
        !expoente.isFinite ||
        (tipo == TipoCurvaInfiltracaoSulco.taxa && expoente <= -1) ||
        (tipo == TipoCurvaInfiltracaoSulco.acumulada && expoente <= 0) ||
        (vibMmHora != null && (!vibMmHora!.isFinite || vibMmHora! <= 0)) ||
        (tempoMinCalibrado != null &&
            (!tempoMinCalibrado!.isFinite || tempoMinCalibrado! < 0)) ||
        (tempoMaxCalibrado != null &&
            (!tempoMaxCalibrado!.isFinite || tempoMaxCalibrado! <= 0)) ||
        (tempoMinCalibrado != null &&
            tempoMaxCalibrado != null &&
            tempoMinCalibrado! >= tempoMaxCalibrado!)) {
      throw const FormatException(
        'Curva de infiltração: coeficientes ou intervalo temporal fora do domínio.',
      );
    }
    if (base == BaseInfiltracaoSulco.litrosPorMetro &&
        (espacamentoConversaoM == null ||
            !espacamentoConversaoM!.isFinite ||
            espacamentoConversaoM! <= 0)) {
      throw const FormatException(
        'Curva em L/min/m ou L/m requer o espaçamento E medido usado na conversão.',
      );
    }
  }

  /// Retorna (k, a) da lei acumulada I(mm)=k·T^a. Não soma VIB·T.
  ({double k, double a}) acumuladaMm() {
    validar();
    final fator = base == BaseInfiltracaoSulco.milimetros
        ? 1.0
        : 1 / espacamentoConversaoM!;
    final a = tipo == TipoCurvaInfiltracaoSulco.taxa ? expoente + 1 : expoente;
    final k = tipo == TipoCurvaInfiltracaoSulco.taxa
        ? coeficiente *
              fator *
              (base == BaseInfiltracaoSulco.milimetros ? 1 / 60 : 1) /
              a
        : coeficiente * fator;
    if (!k.isFinite || k <= 0) {
      throw const FormatException(
        'Curva de infiltração extrapola o domínio numérico.',
      );
    }
    return (k: k, a: a);
  }

  double taxaMmHora(double tempoMin) {
    validar();
    if (!tempoMin.isFinite || tempoMin <= 0) {
      throw const FormatException(
        'VI exige tempo positivo (singular em T=0 para expoente negativo).',
      );
    }
    final curva = acumuladaMm();
    return 60 * curva.k * curva.a * math.pow(tempoMin, curva.a - 1);
  }

  /// Primeiro instante em que VI passa a ser menor que a VIB, se ocorrer.
  double? cruzamentoVibMin() {
    if (vibMmHora == null) return null;
    final curva = acumuladaMm();
    final n = curva.a - 1;
    if (n == 0) return taxaMmHora(1) < vibMmHora! ? 0 : null;
    if (n > 0) return null; // taxa crescente não cruza de cima para baixo
    final cruzamento = math
        .pow(vibMmHora! / (60 * curva.k * curva.a), 1 / n)
        .toDouble();
    return cruzamento.isFinite && cruzamento >= 0 ? cruzamento : null;
  }

  String? avisoParaOportunidade(double maiorTempoMin, {double? menorTempoMin}) {
    final avisos = <String>[];
    if (!maiorTempoMin.isFinite || maiorTempoMin < 0) {
      throw const FormatException(
        'Oportunidade fora do domínio da infiltração.',
      );
    }
    if (tempoMinCalibrado != null &&
            (menorTempoMin == null || menorTempoMin < tempoMinCalibrado!) ||
        tempoMaxCalibrado != null && maiorTempoMin > tempoMaxCalibrado!) {
      avisos.add(
        'Perfil fora do intervalo temporal calibrado; resultado apenas formal.',
      );
    }
    final cruzamento = cruzamentoVibMin();
    if (cruzamento != null &&
        maiorTempoMin > cruzamento &&
        taxaMmHora(maiorTempoMin) < vibMmHora!) {
      avisos.add(
        'VI cai abaixo da VIB (${vibMmHora!.toStringAsFixed(2)} mm/h) '
        'após ${cruzamento.toStringAsFixed(3)} min; resultado apenas formal '
        '(Aula 6, p.101). Escolha outra calibração/modelo.',
      );
    }
    return avisos.isEmpty ? null : avisos.join(' ');
  }

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

  factory CurvaInfiltracaoSulco.fromMap(Map<String, dynamic> map) =>
      CurvaInfiltracaoSulco(
        tipo: TipoCurvaInfiltracaoSulco.values.byName(map['tipo'] as String),
        base: BaseInfiltracaoSulco.values.byName(map['base'] as String),
        coeficiente: (map['coeficiente'] as num).toDouble(),
        expoente: (map['expoente'] as num).toDouble(),
        espacamentoConversaoM: (map['espacamento_conversao_m'] as num?)
            ?.toDouble(),
        vibMmHora: (map['vib_mm_h'] as num?)?.toDouble(),
        dataEnsaio: DateTime.tryParse(map['data_ensaio'] as String? ?? ''),
        tempoMinCalibrado: (map['tempo_min_calibrado'] as num?)?.toDouble(),
        tempoMaxCalibrado: (map['tempo_max_calibrado'] as num?)?.toDouble(),
        proveniencia: ProvenienciaSulco.values.byName(
          map['proveniencia'] as String,
        ),
      );
}
