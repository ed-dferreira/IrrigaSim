import 'dart:math';

import 'package:irrigasim/models/irrigation_project.dart';

/// Resultado do ajuste da curva de avanço.
class AdvanceCurveResult {
  final double k;
  final double b;
  final MetodoAjusteAvanco metodo;
  final double? r2;
  final List<PontoEnsaio> pontosOriginais;

  const AdvanceCurveResult({
    required this.k,
    required this.b,
    required this.metodo,
    this.r2,
    required this.pontosOriginais,
  });

  Map<String, dynamic> toMap() {
    return {
      'k': k,
      'b': b,
      'metodo': metodo.name,
      'r2': r2,
      'pontos_originais': pontosOriginais.map((p) => p.toMap()).toList(),
    };
  }

  factory AdvanceCurveResult.fromMap(Map<String, dynamic> map) {
    return AdvanceCurveResult(
      k: (map['k'] as num?)?.toDouble() ?? 0,
      b: (map['b'] as num?)?.toDouble() ?? 0,
      metodo: MetodoAjusteAvanco.values.firstWhere(
        (m) => m.name == map['metodo'],
        orElse: () => MetodoAjusteAvanco.doisPontos,
      ),
      r2: (map['r2'] as num?)?.toDouble(),
      pontosOriginais:
          (map['pontos_originais'] as List<dynamic>?)
              ?.map((p) => PontoEnsaio.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Calcula o tempo de avanço em uma distância qualquer.
///
/// Equação: `Tx = k * x^b`
///
/// Onde:
/// - Tx = tempo de avanço (min)
/// - x = distância (m)
/// - k, b = parâmetros da curva
class AdvanceCurveModel {
  const AdvanceCurveModel._();

  /// Ajusta a curva de avanço pelo método dos dois pontos.
  ///
  /// Equações:
  /// ```
  /// b = [ln(T0.5x) - ln(Tx)] / ln(0.5)
  /// k = Tx / x^b
  /// ```
  ///
  /// [distanciaM] — Distância do primeiro ponto (m)
  /// [tempoMin] — Tempo do primeiro ponto (min)
  /// [distanciaMetadeM] — Distância do segundo ponto (metade da primeira)
  /// [tempoMetadeMin] — Tempo na metade da distância (min)
  /// [pontos] — Todos os pontos medidos (para preservar)
  static AdvanceCurveResult ajustarDoisPontos({
    required double distanciaM,
    required double tempoMin,
    required double distanciaMetadeM,
    required double tempoMetadeMin,
    required List<PontoEnsaio> pontos,
  }) {
    // Validações §6
    if (distanciaM <= 0) {
      throw ArgumentError('Distância deve ser positiva ($distanciaM m)');
    }
    if (tempoMin <= 0) {
      throw ArgumentError('Tempo deve ser positivo ($tempoMin min)');
    }
    if (distanciaMetadeM <= 0) {
      throw ArgumentError(
        'Distância na metade deve ser positiva ($distanciaMetadeM m)',
      );
    }
    if (tempoMetadeMin <= 0) {
      throw ArgumentError(
        'Tempo na metade deve ser positivo ($tempoMetadeMin min)',
      );
    }
    if (distanciaMetadeM >= distanciaM) {
      throw ArgumentError(
        'Distância na metade ($distanciaMetadeM) deve ser menor '
        'que a distância total ($distanciaM)',
      );
    }
    if ((distanciaMetadeM * 2 - distanciaM).abs() > 1e-9) {
      throw ArgumentError(
        'A distância intermediária deve ser exatamente metade da distância total',
      );
    }

    // b = [ln(T0.5x) - ln(Tx)] / ln(0.5)
    final b = (log(tempoMetadeMin) - log(tempoMin)) / log(0.5);

    if (!b.isFinite || b <= 0) {
      throw ArgumentError('Os dados não formam uma curva válida. b=$b');
    }

    // k = Tx / x^b
    final k = tempoMin / pow(distanciaM, b);

    return AdvanceCurveResult(
      k: k,
      b: b,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: pontos,
    );
  }

  /// Ajusta a curva de avanço por mínimos quadrados (regressão log-log).
  ///
  /// Equação: `ln(T) = ln(k) + b * ln(x)`
  ///
  /// [pontos] — Lista de pontos medidos (distância > 0, tempo > 0)
  static AdvanceCurveResult ajustarMinimosQuadrados(List<PontoEnsaio> pontos) {
    // Filtrar pontos válidos: x > 0 e T > 0
    final validos = pontos
        .where((p) => p.distanciaM > 0 && p.tempoMin > 0)
        .toList();

    if (validos.length < 2) {
      throw ArgumentError(
        'Necessário pelo menos 2 pontos válidos (x > 0 e T > 0). '
        'Recebidos: ${validos.length} de ${pontos.length}',
      );
    }

    // Regressão linear em escala log: ln(T) = ln(k) + b * ln(x)
    // y = a + b * x
    final n = validos.length;
    double somaX = 0, somaY = 0, somaXY = 0, somaX2 = 0;

    for (final p in validos) {
      final logX = log(p.distanciaM);
      final logT = log(p.tempoMin);
      somaX += logX;
      somaY += logT;
      somaXY += logX * logT;
      somaX2 += logX * logX;
    }

    final mediaX = somaX / n;
    final mediaY = somaY / n;

    final denominador = somaX2 - n * mediaX * mediaX;
    if (denominador.abs() < 1e-15) {
      throw ArgumentError(
        'Denominador da regressão é zero. Verifique os pontos do ensaio.',
      );
    }

    // b (coeficiente angular)
    final b = (somaXY - n * mediaX * mediaY) / denominador;

    // ln(k) = intercept
    final lnK = mediaY - b * mediaX;
    final k = exp(lnK);

    // Coeficiente de determinação R²
    double ssRes = 0, ssTot = 0;
    for (final p in validos) {
      final logX = log(p.distanciaM);
      final logT = log(p.tempoMin);
      final predito = lnK + b * logX;
      ssRes += (logT - predito) * (logT - predito);
      ssTot += (logT - mediaY) * (logT - mediaY);
    }
    final r2 = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    return AdvanceCurveResult(
      k: k,
      b: b,
      metodo: MetodoAjusteAvanco.minimosQuadrados,
      r2: r2,
      pontosOriginais: pontos,
    );
  }

  /// Calcula o tempo de avanço em uma distância.
  ///
  /// Equação: `Tx = k * x^b`
  static double tempoAvanco({
    required double distanciaM,
    required AdvanceCurveResult parametros,
  }) {
    if (distanciaM <= 0) return 0;
    return parametros.k * pow(distanciaM, parametros.b);
  }

  /// Calcula a distância alcançada em um determinado tempo.
  ///
  /// Equação inversa: `x = (T / k)^(1/b)`
  static double distanciaEmTempo({
    required double tempoMin,
    required AdvanceCurveResult parametros,
  }) {
    if (tempoMin <= 0 || parametros.k <= 0 || parametros.b == 0) return 0;
    return pow(tempoMin / parametros.k, 1 / parametros.b).toDouble();
  }

  /// Gera pontos para a curva de avanço (para gráficos).
  static List<AdvancePoint> gerarCurva({
    required double comprimentoM,
    required AdvanceCurveResult parametros,
    int amostras = 20,
  }) {
    final pontos = <AdvancePoint>[];
    for (var i = 0; i <= amostras; i++) {
      final distancia = comprimentoM * i / amostras;
      final tempo = distancia == 0
          ? 0.0
          : parametros.k * pow(distancia, parametros.b);
      pontos.add(AdvancePoint(distancia, tempo));
    }
    return pontos;
  }

  /// Valida os pontos de ensaio de avanço.
  static List<String> validarPontos(List<PontoEnsaio> pontos) {
    final erros = <String>[];

    if (pontos.length < 2) {
      erros.add('Necessário pelo menos 2 pontos');
    }

    final invalidos = pontos.where((p) => p.distanciaM < 0 || p.tempoMin < 0);
    if (invalidos.isNotEmpty) {
      erros.add('${invalidos.length} ponto(s) com distância ou tempo negativo');
    }

    final zerosInvalidos = pontos.where(
      (p) => (p.distanciaM == 0) != (p.tempoMin == 0),
    );
    if (zerosInvalidos.isNotEmpty) {
      erros.add('O ponto de origem deve ser (0, 0)');
    }

    // Verificar ordem crescente de distâncias
    for (int i = 1; i < pontos.length; i++) {
      if (pontos[i].distanciaM < pontos[i - 1].distanciaM) {
        erros.add('Distâncias não estão em ordem crescente no ponto ${i + 1}');
        break;
      }
    }

    // Verificar tempos não decrescentes
    for (int i = 1; i < pontos.length; i++) {
      if (pontos[i].tempoMin < pontos[i - 1].tempoMin) {
        erros.add(
          'Tempo de avanço diminuiu na distância ${pontos[i].distanciaM}m '
          '(de ${pontos[i - 1].tempoMin} para ${pontos[i].tempoMin} min)',
        );
      }
    }

    return erros;
  }

  /// Verifica se dois conjuntos de parâmetros são compatíveis.
  static bool saoCompativeis(
    AdvanceCurveResult a,
    AdvanceCurveResult b, {
    double toleranciaK = 0.1,
    double toleranciaB = 0.1,
  }) {
    final diffK = (a.k - b.k).abs() / max(a.k, 0.0001);
    final diffB = (a.b - b.b).abs() / max(a.b.abs(), 0.0001);
    return diffK < toleranciaK && diffB < toleranciaB;
  }
}

/// Ponto na curva de avanço (distância, tempo).
class AdvancePoint {
  final double distanciaM;
  final double tempoMin;

  const AdvancePoint(this.distanciaM, this.tempoMin);

  Map<String, dynamic> toMap() {
    return {'distancia_m': distanciaM, 'tempo_min': tempoMin};
  }

  factory AdvancePoint.fromMap(Map<String, dynamic> map) {
    return AdvancePoint(
      (map['distancia_m'] as num?)?.toDouble() ?? 0,
      (map['tempo_min'] as num?)?.toDouble() ?? 0,
    );
  }
}
