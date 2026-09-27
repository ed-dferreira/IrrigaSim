import 'dart:math';

import 'package:irrigasim/services/units_service.dart';

/// Origem dos parâmetros de infiltração.
enum OrigemParametros { ensaio, modelo, valorInformado }

/// Resultado do ajuste da curva de infiltração.
class InfiltrationParameters {
  final double k;
  final double n;
  final double baseLog;
  final double? r2;
  final OrigemParametros origem;
  final String unidadeK;

  const InfiltrationParameters({
    required this.k,
    required this.n,
    this.baseLog = 10,
    this.r2,
    required this.origem,
    required this.unidadeK,
  });

  Map<String, dynamic> toMap() {
    return {
      'k': k,
      'n': n,
      'base_log': baseLog,
      'r2': r2,
      'origem': origem.name,
      'unidade_k': unidadeK,
    };
  }

  factory InfiltrationParameters.fromMap(Map<String, dynamic> map) {
    return InfiltrationParameters(
      k: (map['k'] as num?)?.toDouble() ?? 0,
      n: (map['n'] as num?)?.toDouble() ?? 0,
      baseLog: (map['base_log'] as num?)?.toDouble() ?? 10,
      r2: (map['r2'] as num?)?.toDouble(),
      origem: OrigemParametros.values.firstWhere(
        (o) => o.name == map['origem'],
        orElse: () => OrigemParametros.valorInformado,
      ),
      unidadeK: map['unidade_k'] as String? ?? 'mm/h',
    );
  }

  @override
  String toString() =>
      'InfiltrationParameters(k=$k, n=$n, base=$baseLog, origem=$origem)';
}

/// Ponto de infiltração medido em ensaio.
class PontoInfiltracaoMedido {
  final double tempoMin;
  final double volumeMm;

  const PontoInfiltracaoMedido({
    required this.tempoMin,
    required this.volumeMm,
  });

  Map<String, dynamic> toMap() {
    return {'tempo_min': tempoMin, 'volume_mm': volumeMm};
  }

  factory PontoInfiltracaoMedido.fromMap(Map<String, dynamic> map) {
    return PontoInfiltracaoMedido(
      tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
      volumeMm: (map['volume_mm'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Modelo potencial de taxa de infiltração para ensaios de entrada e saída.
///
/// Equações suportadas:
/// - Taxa instantânea: `VI = K * T^n` (mm/h)
/// - Infiltração acumulada: `I = [K / (60 * (n+1))] * T^(n+1)`
///
/// Referências: §25 do documento de implementação.
class InfiltrationModel {
  const InfiltrationModel._();

  /// Ajusta a curva de infiltração a partir de pontos medidos usando
  /// regressão logarítmica (base 10).
  ///
  /// Equação: `log10(VI) = log10(K) + n * log10(T)`
  ///
  /// [pontos] — Lista de taxas medidas (tempo em minutos, VI em mm/h).
  /// Exclui pontos com T=0 da regressão.
  ///
  /// Retorna os parâmetros K, n e o coeficiente R².
  static InfiltrationParameters ajustarCurva(
    List<PontoInfiltracaoMedido> pontos,
  ) {
    final invalidos = pontos.where(
      (p) =>
          p.tempoMin < 0 ||
          p.volumeMm < 0 ||
          (p.tempoMin == 0 && p.volumeMm != 0) ||
          (p.tempoMin > 0 && p.volumeMm <= 0),
    );
    if (invalidos.isNotEmpty) {
      throw ArgumentError(
        'Pontos de regressão devem ter T > 0 e VI > 0; apenas (0, 0) '
        'pode representar o início do ensaio.',
      );
    }

    // O ponto inicial (0, 0) é preservado no ensaio, mas não tem logaritmo.
    final validos = pontos
        .where((p) => p.tempoMin > 0 && p.volumeMm > 0)
        .toList();

    if (validos.length < 2) {
      throw ArgumentError(
        'Necessário pelo menos 2 pontos válidos (T > 0 e VI > 0). '
        'Recebidos: ${validos.length} de ${pontos.length}',
      );
    }

    // Regressão linear em escala log10
    // log10(VI) = log10(K) + n * log10(T)
    // y = a + b * x
    final n = validos.length;
    double somaX = 0, somaY = 0, somaXY = 0, somaX2 = 0;

    for (final p in validos) {
      final logT = log(p.tempoMin) / ln10; // log10
      final logVI = log(p.volumeMm) / ln10; // log10
      somaX += logT;
      somaY += logVI;
      somaXY += logT * logVI;
      somaX2 += logT * logT;
    }

    final mediaX = somaX / n;
    final mediaY = somaY / n;

    final denominador = somaX2 - n * mediaX * mediaX;
    if (denominador.abs() < 1e-15) {
      throw ArgumentError(
        'Denominador da regressão é zero. Verifique os pontos do ensaio.',
      );
    }

    // n (coeficiente angular) = slope
    final nCalc = (somaXY - n * mediaX * mediaY) / denominador;

    // log10(K) = intercept
    final logK = mediaY - nCalc * mediaX;
    final k = pow(10, logK).toDouble();

    // Coeficiente de determinação R²
    double ssRes = 0, ssTot = 0;
    for (final p in validos) {
      final logT = log(p.tempoMin) / ln10;
      final logVI = log(p.volumeMm) / ln10;
      final predito = logK + nCalc * logT;
      ssRes += (logVI - predito) * (logVI - predito);
      ssTot += (logVI - mediaY) * (logVI - mediaY);
    }
    final r2 = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    return InfiltrationParameters(
      k: k,
      n: nCalc,
      baseLog: 10,
      r2: r2,
      origem: OrigemParametros.ensaio,
      unidadeK: 'mm/h',
    );
  }

  /// Calcula a taxa de infiltração instantânea (VI) em um dado tempo.
  ///
  /// Equação: `VI = K * T^n`
  ///
  /// [tempoMin] — Tempo em minutos.
  /// [parametros] — Parâmetros K e n da curva.
  static double vi({
    required double tempoMin,
    required InfiltrationParameters parametros,
  }) {
    if (tempoMin <= 0) return 0;
    return parametros.k * pow(tempoMin, parametros.n);
  }

  /// Calcula a infiltração acumulada em um dado tempo.
  ///
  /// Equação: `I = [K / (60 * (n+1))] * T^(n+1)`
  ///
  /// Onde T está em minutos e I retorna em mm.
  ///
  /// IMPORTANTE: n+1 não pode ser zero.
  static double infiltracaoAcumulada({
    required double tempoMin,
    required InfiltrationParameters parametros,
  }) {
    if (tempoMin <= 0) return 0;

    final nMais1 = parametros.n + 1;
    if (nMais1.abs() < 1e-15) {
      throw ArgumentError(
        'n+1 não pode ser zero (n=${parametros.n}). '
        'Verifique os parâmetros de infiltração.',
      );
    }

    // I = [K / (60 * (n+1))] * T^(n+1)
    // Fator 60 converte K de mm/h para mm/min
    return (parametros.k / (60 * nMais1)) * pow(tempoMin, nMais1);
  }

  /// Alias semântico de [vi]. VI já é a taxa instantânea em mm/h; não deve
  /// ser derivada novamente.
  static double taxaInfiltracao({
    required double tempoMin,
    required InfiltrationParameters parametros,
  }) {
    if (tempoMin <= 0) return 0;
    return vi(tempoMin: tempoMin, parametros: parametros);
  }

  /// Calcula VI a partir de ensaio de entrada/saída.
  ///
  /// Equação: `VI(mm/h) = Qinfiltrada(L/s) * (3600 / area_m2)`
  ///
  /// [qEntradaLs] — Vazão de entrada (L/s)
  /// [qSaidaLs] — Vazão de saída (L/s)
  /// [areaM2] — Área do tanque de infiltração (m²)
  static double viEnsaioSaida({
    required double qEntradaLs,
    required double qSaidaLs,
    required double areaM2,
  }) {
    if (qEntradaLs < 0 || qSaidaLs < 0) {
      throw ArgumentError('Vazões de entrada e saída não podem ser negativas');
    }
    if (qSaidaLs > qEntradaLs) {
      throw ArgumentError(
        'Qsaída ($qSaidaLs L/s) não pode ser maior que Qentrada ($qEntradaLs L/s). '
        'Verifique os dados do ensaio.',
      );
    }

    final qInfiltrada = qEntradaLs - qSaidaLs;
    return UnitsService.lpsToMmH(qInfiltrada, areaM2);
  }

  /// Valida um conjunto de parâmetros de infiltração.
  static List<String> validarParametros(InfiltrationParameters parametros) {
    final erros = <String>[];

    if (parametros.k <= 0) {
      erros.add('K deve ser positivo (${parametros.k})');
    }
    if (parametros.n <= -1) {
      erros.add('n deve ser maior que -1 (n=${parametros.n})');
    }
    if (parametros.baseLog <= 0 || parametros.baseLog == 1) {
      erros.add('Base do logaritmo inválida (${parametros.baseLog})');
    }

    return erros;
  }

  /// Valida pontos de ensaio de infiltração.
  static List<String> validarPontos(List<PontoInfiltracaoMedido> pontos) {
    final erros = <String>[];

    if (pontos.length < 2) {
      erros.add('Necessário pelo menos 2 pontos válidos');
    }

    final invalidos = pontos.where((p) => p.tempoMin < 0 || p.volumeMm < 0);
    if (invalidos.isNotEmpty) {
      erros.add(
        '${invalidos.length} ponto(s) com tempo ou taxa negativa '
        '(excluídos da regressão)',
      );
    }

    // Verificar se tempos estão em ordem crescente
    for (int i = 1; i < pontos.length; i++) {
      if (pontos[i].tempoMin < pontos[i - 1].tempoMin) {
        erros.add('Tempos não estão em ordem crescente no ponto ${i + 1}');
        break;
      }
    }

    return erros;
  }
}
