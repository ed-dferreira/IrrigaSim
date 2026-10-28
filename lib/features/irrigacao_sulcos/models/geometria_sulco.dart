import 'dart:math' as math;

/// Forma da seção transversal do sulco.
///
/// Os nomes dos valores são persistidos nos cenários e não devem mudar.
enum FormaSulco { v, trapezoidal, retangular }

/// Geometria da seção transversal e do espaçamento entre sulcos.
class GeometriaSulco {
  const GeometriaSulco({
    required this.forma,
    this.larguraSuperiorM,
    this.profundidadeM,
    this.larguraBaseM,
    required this.espacamentoM,
  });

  final FormaSulco forma;

  /// Largura no topo do sulco, em metros.
  final double? larguraSuperiorM;

  /// Profundidade do canal (não a das raízes), em metros.
  final double? profundidadeM;

  /// Largura de fundo; usada apenas na seção trapezoidal.
  final double? larguraBaseM;

  /// Distância entre eixos de sulcos consecutivos, em metros.
  final double espacamentoM;

  /// Área molhada da seção, em m².
  ///
  /// Retorna `null` quando faltam as dimensões exigidas pela [forma].
  double? get areaSecaoM2 => switch (forma) {
    FormaSulco.retangular => _comLarguraEProfundidade(
      (largura, profundidade) => largura * profundidade,
    ),
    FormaSulco.v => _comLarguraEProfundidade(
      (largura, profundidade) => largura * profundidade / 2,
    ),
    FormaSulco.trapezoidal =>
      larguraSuperiorM == null || profundidadeM == null || larguraBaseM == null
          ? null
          : (larguraSuperiorM! + larguraBaseM!) / 2 * profundidadeM!,
  };

  /// Perímetro molhado da seção, em metros.
  ///
  /// Retorna `null` quando faltam as dimensões exigidas pela [forma].
  double? get perimetroMolhadoM => switch (forma) {
    FormaSulco.retangular => _comLarguraEProfundidade(
      (largura, profundidade) => largura + 2 * profundidade,
    ),
    FormaSulco.v => _comLarguraEProfundidade((largura, profundidade) {
      final semiLargura = largura / 2;
      final lado = math.sqrt(
        semiLargura * semiLargura + profundidade * profundidade,
      );
      return 2 * lado;
    }),
    FormaSulco.trapezoidal =>
      larguraSuperiorM == null || profundidadeM == null || larguraBaseM == null
          ? null
          : _perimetroTrapezoidal(
              larguraSuperiorM!,
              larguraBaseM!,
              profundidadeM!,
            ),
  };

  /// Raio hidráulico da seção, em metros.
  ///
  /// Retorna `null` quando a área ou o perímetro não puderem ser calculados.
  double? get raioHidraulicoM {
    final area = areaSecaoM2;
    final perimetro = perimetroMolhadoM;
    if (area == null || perimetro == null || perimetro == 0) return null;
    return area / perimetro;
  }

  /// Regra `E ≤ 2z` (p. 52), em que `z` é a profundidade das raízes.
  bool espacamentoValido(double profundidadeRadicularM) =>
      profundidadeRadicularM.isFinite &&
      profundidadeRadicularM > 0 &&
      espacamentoM.isFinite &&
      espacamentoM > 0 &&
      espacamentoM <= 2 * profundidadeRadicularM;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'forma': forma.name,
    'largura_superior_m': larguraSuperiorM,
    'profundidade_m': profundidadeM,
    'largura_base_m': larguraBaseM,
    'espacamento_m': espacamentoM,
  };

  factory GeometriaSulco.fromMap(Map<String, dynamic> map) => GeometriaSulco(
    forma: FormaSulco.values.firstWhere(
      (valor) => valor.name == map['forma'],
      orElse: () => FormaSulco.v,
    ),
    larguraSuperiorM: (map['largura_superior_m'] as num?)?.toDouble(),
    profundidadeM: (map['profundidade_m'] as num?)?.toDouble(),
    larguraBaseM: (map['largura_base_m'] as num?)?.toDouble(),
    espacamentoM: (map['espacamento_m'] as num?)?.toDouble() ?? 0,
  );

  double? _comLarguraEProfundidade(
    double Function(double largura, double profundidade) calcular,
  ) {
    final largura = larguraSuperiorM;
    final profundidade = profundidadeM;
    if (largura == null || profundidade == null) return null;
    return calcular(largura, profundidade);
  }

  static double _perimetroTrapezoidal(
    double larguraSuperior,
    double larguraBase,
    double profundidade,
  ) {
    final lado = (larguraSuperior - larguraBase) / 2;
    final comprimentoLado = math.sqrt(
      lado * lado + profundidade * profundidade,
    );
    return larguraBase + 2 * comprimentoLado;
  }
}
