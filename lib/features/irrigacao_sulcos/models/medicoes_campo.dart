/// Método de ajuste da curva de avanço `Tx = k · x^b`.
///
/// Os nomes dos valores são persistidos nos cenários e não devem mudar.
enum MetodoAjusteAvanco {
  /// Ajuste por dois pontos (final e metade do comprimento).
  doisPontos,

  /// Regressão log-log sobre todas as estacas medidas.
  minimosQuadrados,
}

/// Origem da curva de infiltração usada no balanço.
enum OrigemCurvaInfiltracao {
  /// Equação acumulada digitada pelo usuário.
  equacaoAcumuladaInformada,

  /// Curva ajustada a partir de um ensaio de entrada/saída.
  ensaioEntradaSaida,
}

/// Hipótese adotada para a fase de recessão.
enum HipoteseRecessao {
  /// A recessão é ignorada; a oportunidade termina no corte.
  desprezada,

  /// A recessão é interpolada entre estacas medidas.
  medidaPorEstaca,
}

/// Ensaio de campo que verifica a ocorrência de erosão para uma vazão.
///
/// A vazão é em L/s e o resultado medido prevalece sobre o `qmax` empírico.
class EnsaioErosao {
  const EnsaioErosao({
    required this.vazaoLs,
    required this.condicoes,
    required this.erosaoObservada,
  });

  final double vazaoLs;

  /// Descrição do solo, seção e orientação usados no ensaio.
  final String condicoes;

  final bool erosaoObservada;

  Map<String, dynamic> toMap() => {
    'vazao_ls': vazaoLs,
    'condicoes': condicoes,
    'erosao_observada': erosaoObservada,
  };

  factory EnsaioErosao.fromMap(Map<String, dynamic> map) => EnsaioErosao(
    vazaoLs: (map['vazao_ls'] as num).toDouble(),
    condicoes: map['condicoes'] as String,
    erosaoObservada: map['erosao_observada'] as bool,
  );
}

/// Estaca medida durante o ensaio de avanço.
class MedicaoAvanco {
  const MedicaoAvanco({required this.distanciaM, required this.tempoMin});

  /// Distância percorrida pela frente de avanço, em metros.
  final double distanciaM;

  /// Instante em que a frente atingiu [distanciaM], em minutos.
  final double tempoMin;

  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'tempo_min': tempoMin,
  };

  factory MedicaoAvanco.fromMap(Map<String, dynamic> map) => MedicaoAvanco(
    distanciaM: (map['distancia_m'] as num).toDouble(),
    tempoMin: (map['tempo_min'] as num).toDouble(),
  );
}

/// Observação de vazão de entrada e saída durante o ensaio de infiltração.
class MedicaoEntradaSaida {
  const MedicaoEntradaSaida({
    required this.tempoMin,
    required this.vazaoEntradaLs,
    required this.vazaoSaidaLs,
  });

  final double tempoMin;
  final double vazaoEntradaLs;
  final double vazaoSaidaLs;

  /// Vazão efetivamente infiltrada, em L/s.
  double get vazaoInfiltradaLs => vazaoEntradaLs - vazaoSaidaLs;

  Map<String, dynamic> toMap() => {
    'tempo_min': tempoMin,
    'vazao_entrada_ls': vazaoEntradaLs,
    'vazao_saida_ls': vazaoSaidaLs,
  };

  factory MedicaoEntradaSaida.fromMap(Map<String, dynamic> map) =>
      MedicaoEntradaSaida(
        tempoMin: (map['tempo_min'] as num).toDouble(),
        vazaoEntradaLs: (map['vazao_entrada_ls'] as num).toDouble(),
        vazaoSaidaLs: (map['vazao_saida_ls'] as num).toDouble(),
      );
}

/// Estaca medida durante a fase de recessão.
class MedicaoRecessao {
  const MedicaoRecessao({
    required this.distanciaM,
    required this.instanteRecessaoMin,
  });

  final double distanciaM;

  /// Instante absoluto medido desde o início da aplicação, em minutos.
  final double instanteRecessaoMin;

  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'instante_recessao_min': instanteRecessaoMin,
  };

  factory MedicaoRecessao.fromMap(Map<String, dynamic> map) => MedicaoRecessao(
    distanciaM: (map['distancia_m'] as num).toDouble(),
    instanteRecessaoMin: (map['instante_recessao_min'] as num).toDouble(),
  );
}
