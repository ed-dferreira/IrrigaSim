enum MetodoCurvaAvanco { doisPontos, minimosQuadrados }

enum OrigemCurvaInfiltracao { equacaoAcumuladaInformada, ensaioEntradaSaida }

enum HipoteseRecessao { desprezada, medidaPorEstaca }

/// Registro de campo para o mesmo solo, seção e orientação do projeto.
/// A vazão é em L/s; o resultado medido prevalece sobre o qmax empírico.
class EnsaioErosaoSulco {
  const EnsaioErosaoSulco({
    required this.vazaoLs,
    required this.condicoes,
    required this.erosaoObservada,
  });

  final double vazaoLs;
  final String condicoes;
  final bool erosaoObservada;

  Map<String, dynamic> toMap() => {
    'vazao_ls': vazaoLs,
    'condicoes': condicoes,
    'erosao_observada': erosaoObservada,
  };

  factory EnsaioErosaoSulco.fromMap(Map<String, dynamic> map) =>
      EnsaioErosaoSulco(
        vazaoLs: (map['vazao_ls'] as num).toDouble(),
        condicoes: map['condicoes'] as String,
        erosaoObservada: map['erosao_observada'] as bool,
      );
}

class MedicaoAvanco {
  final double distanciaM;
  final double tempoMin;

  const MedicaoAvanco({required this.distanciaM, required this.tempoMin});

  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'tempo_min': tempoMin,
  };

  factory MedicaoAvanco.fromMap(Map<String, dynamic> map) => MedicaoAvanco(
    distanciaM: (map['distancia_m'] as num).toDouble(),
    tempoMin: (map['tempo_min'] as num).toDouble(),
  );
}

class MedicaoEntradaSaida {
  final double tempoMin;
  final double vazaoEntradaLs;
  final double vazaoSaidaLs;

  const MedicaoEntradaSaida({
    required this.tempoMin,
    required this.vazaoEntradaLs,
    required this.vazaoSaidaLs,
  });

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

class MedicaoRecessao {
  final double distanciaM;

  /// Instante absoluto medido desde o início da aplicação (min).
  final double instanteRecessaoMin;

  const MedicaoRecessao({
    required this.distanciaM,
    required this.instanteRecessaoMin,
  });

  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'instante_recessao_min': instanteRecessaoMin,
  };

  factory MedicaoRecessao.fromMap(Map<String, dynamic> map) => MedicaoRecessao(
    distanciaM: (map['distancia_m'] as num).toDouble(),
    instanteRecessaoMin: (map['instante_recessao_min'] as num).toDouble(),
  );
}
