import 'medicoes_campo.dart';

/// Estaca medida no ensaio de avanço.
///
/// A ordem dos campos segue a leitura natural do ensaio: distância percorrida
/// e instante em que a frente a atingiu.
class PontoEnsaioAvanco {
  const PontoEnsaioAvanco({required this.distanciaM, required this.tempoMin});

  final double distanciaM;
  final double tempoMin;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'tempo_min': tempoMin,
  };

  factory PontoEnsaioAvanco.fromMap(Map<String, dynamic> map) =>
      PontoEnsaioAvanco(
        distanciaM: (map['distancia_m'] as num?)?.toDouble() ?? 0,
        tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
      );
}

/// Parâmetros ajustados da curva de avanço `Tx = k · x^b`.
class ParametrosCurvaAvanco {
  const ParametrosCurvaAvanco({
    required this.coeficiente,
    required this.expoente,
    required this.metodo,
  });

  /// Coeficiente `k` da curva, em min/mᵇ.
  final double coeficiente;

  /// Expoente `b` da curva.
  final double expoente;

  final MetodoAjusteAvanco metodo;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'k': coeficiente,
    'b': expoente,
    'metodo': metodo.name,
  };

  factory ParametrosCurvaAvanco.fromMap(Map<String, dynamic> map) =>
      ParametrosCurvaAvanco(
        coeficiente: (map['k'] as num?)?.toDouble() ?? 0,
        expoente: (map['b'] as num?)?.toDouble() ?? 0,
        metodo: MetodoAjusteAvanco.values.firstWhere(
          (valor) => valor.name == map['metodo'],
          orElse: () => MetodoAjusteAvanco.doisPontos,
        ),
      );
}

/// Ensaio de avanço realizado no campo.
class EnsaioAvanco {
  const EnsaioAvanco({
    required this.pontos,
    required this.metodo,
    this.parametros,
    this.data,
  });

  final List<PontoEnsaioAvanco> pontos;
  final MetodoAjusteAvanco metodo;
  final ParametrosCurvaAvanco? parametros;
  final DateTime? data;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'pontos': pontos.map((ponto) => ponto.toMap()).toList(),
    'metodo': metodo.name,
    'parametros': parametros?.toMap(),
    'data': data?.toIso8601String(),
  };

  factory EnsaioAvanco.fromMap(Map<String, dynamic> map) => EnsaioAvanco(
    pontos:
        (map['pontos'] as List<dynamic>?)
            ?.map(
              (ponto) => PontoEnsaioAvanco.fromMap(
                Map<String, dynamic>.from(ponto as Map),
              ),
            )
            .toList() ??
        const [],
    metodo: MetodoAjusteAvanco.values.firstWhere(
      (valor) => valor.name == map['metodo'],
      orElse: () => MetodoAjusteAvanco.doisPontos,
    ),
    parametros: map['parametros'] is Map
        ? ParametrosCurvaAvanco.fromMap(
            Map<String, dynamic>.from(map['parametros'] as Map),
          )
        : null,
    data: map['data'] == null ? null : DateTime.tryParse(map['data'] as String),
  );
}

/// Par de tempo e lâmina acumulada medido no ensaio de infiltração.
class PontoInfiltracao {
  const PontoInfiltracao({
    required this.tempoMin,
    required this.laminaAcumuladaMm,
  });

  final double tempoMin;

  /// Lâmina infiltrada acumulada desde o início do ensaio, em mm.
  final double laminaAcumuladaMm;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'tempo_min': tempoMin,
    'volume_infiltrado_mm': laminaAcumuladaMm,
  };

  factory PontoInfiltracao.fromMap(Map<String, dynamic> map) =>
      PontoInfiltracao(
        tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
        laminaAcumuladaMm:
            (map['volume_infiltrado_mm'] as num?)?.toDouble() ?? 0,
      );
}

/// Parâmetros ajustados da curva de infiltração `VI = K · T^n`.
class ParametrosCurvaInfiltracao {
  const ParametrosCurvaInfiltracao({
    required this.coeficiente,
    required this.expoente,
    this.baseLogaritmo,
  });

  /// Coeficiente `K` da taxa instantânea, em mm/h·min⁻ⁿ.
  final double coeficiente;

  /// Expoente `n` da taxa instantânea.
  final double expoente;

  /// Base logarítmica usada no ajuste, quando registrada.
  final double? baseLogaritmo;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'k': coeficiente,
    'n': expoente,
    'base_log': baseLogaritmo,
  };

  factory ParametrosCurvaInfiltracao.fromMap(Map<String, dynamic> map) =>
      ParametrosCurvaInfiltracao(
        coeficiente: (map['k'] as num?)?.toDouble() ?? 0,
        expoente: (map['n'] as num?)?.toDouble() ?? 0,
        baseLogaritmo: (map['base_log'] as num?)?.toDouble(),
      );
}

/// Configuração adotada durante o ensaio de infiltração.
class ConfiguracaoEnsaioInfiltracao {
  const ConfiguracaoEnsaioInfiltracao({
    this.qEntradaLs,
    this.qSaidaLs,
    required this.unidadeVolume,
  });

  /// Vazões médias observadas no ensaio, em L/s.
  final double? qEntradaLs;
  final double? qSaidaLs;

  /// Unidade usada para registrar o volume infiltrado.
  final String unidadeVolume;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'q_entrada_ls': qEntradaLs,
    'q_saida_ls': qSaidaLs,
    'unidade_volume': unidadeVolume,
  };

  factory ConfiguracaoEnsaioInfiltracao.fromMap(Map<String, dynamic> map) =>
      ConfiguracaoEnsaioInfiltracao(
        qEntradaLs: (map['q_entrada_ls'] as num?)?.toDouble(),
        qSaidaLs: (map['q_saida_ls'] as num?)?.toDouble(),
        unidadeVolume: map['unidade_volume'] as String? ?? 'mm',
      );
}

/// Ensaio de infiltração realizado no campo.
class EnsaioInfiltracao {
  const EnsaioInfiltracao({
    required this.configuracao,
    required this.pontos,
    this.parametros,
    this.data,
  });

  final ConfiguracaoEnsaioInfiltracao configuracao;
  final List<PontoInfiltracao> pontos;
  final ParametrosCurvaInfiltracao? parametros;
  final DateTime? data;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'configuracao': configuracao.toMap(),
    'pontos': pontos.map((ponto) => ponto.toMap()).toList(),
    'parametros': parametros?.toMap(),
    'data': data?.toIso8601String(),
  };

  factory EnsaioInfiltracao.fromMap(Map<String, dynamic> map) =>
      EnsaioInfiltracao(
        configuracao: ConfiguracaoEnsaioInfiltracao.fromMap(
          map['configuracao'] is Map
              ? Map<String, dynamic>.from(map['configuracao'] as Map)
              : const {},
        ),
        pontos:
            (map['pontos'] as List<dynamic>?)
                ?.map(
                  (ponto) => PontoInfiltracao.fromMap(
                    Map<String, dynamic>.from(ponto as Map),
                  ),
                )
                .toList() ??
            const [],
        parametros: map['parametros'] is Map
            ? ParametrosCurvaInfiltracao.fromMap(
                Map<String, dynamic>.from(map['parametros'] as Map),
              )
            : null,
        data: map['data'] == null
            ? null
            : DateTime.tryParse(map['data'] as String),
      );
}
