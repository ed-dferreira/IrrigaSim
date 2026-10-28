import 'dart:math';

import 'package:irrigasim/shared/irrigacao/services/units_service.dart';

/// Origem dos parâmetros de infiltração.
enum OrigemParametrosInfiltracao { ensaio, modelo, valorInformado }

/// Resultado do ajuste da curva de infiltração.
class ParametrosInfiltracao {
  final double coeficiente;
  final double expoente;
  final double baseLog;
  final double? r2;
  final OrigemParametrosInfiltracao origem;
  final String unidadeCoeficiente;

  const ParametrosInfiltracao({
    required this.coeficiente,
    required this.expoente,
    this.baseLog = 10,
    this.r2,
    required this.origem,
    required this.unidadeCoeficiente,
  });

  /// As chaves `k`, `n` e `unidade_k` são parte do formato persistido.
  Map<String, dynamic> toMap() {
    return {
      'k': coeficiente,
      'n': expoente,
      'base_log': baseLog,
      'r2': r2,
      'origem': origem.name,
      'unidade_k': unidadeCoeficiente,
    };
  }

  factory ParametrosInfiltracao.fromMap(Map<String, dynamic> map) {
    return ParametrosInfiltracao(
      coeficiente: (map['k'] as num?)?.toDouble() ?? 0,
      expoente: (map['n'] as num?)?.toDouble() ?? 0,
      baseLog: (map['base_log'] as num?)?.toDouble() ?? 10,
      r2: (map['r2'] as num?)?.toDouble(),
      origem: OrigemParametrosInfiltracao.values.firstWhere(
        (o) => o.name == map['origem'],
        orElse: () => OrigemParametrosInfiltracao.valorInformado,
      ),
      unidadeCoeficiente: map['unidade_k'] as String? ?? 'mm/h',
    );
  }

  @override
  String toString() =>
      'ParametrosInfiltracao(coeficiente=$coeficiente, expoente=$expoente, '
      'base=$baseLog, origem=$origem)';
}

/// Ponto de infiltração medido em ensaio.
class PontoInfiltracaoMedido {
  final double tempoMin;

  /// Taxa de infiltração instantânea, em mm/h.
  final double taxaMmHora;

  const PontoInfiltracaoMedido({
    required this.tempoMin,
    required this.taxaMmHora,
  });

  /// A chave `volume_mm` é parte do formato persistido.
  Map<String, dynamic> toMap() {
    return {'tempo_min': tempoMin, 'volume_mm': taxaMmHora};
  }

  factory PontoInfiltracaoMedido.fromMap(Map<String, dynamic> map) {
    return PontoInfiltracaoMedido(
      tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
      taxaMmHora: (map['volume_mm'] as num?)?.toDouble() ?? 0,
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
class ModeloInfiltracao {
  const ModeloInfiltracao._();

  /// Ajusta a curva de infiltração a partir de pontos medidos usando
  /// regressão logarítmica (base 10).
  ///
  /// Equação: `log10(VI) = log10(K) + n * log10(T)`
  ///
  /// [pontos] — Lista de taxas medidas (tempo em minutos, VI em mm/h).
  /// Exclui pontos com T=0 da regressão.
  ///
  /// Retorna os parâmetros K, n e o coeficiente R².
  static ParametrosInfiltracao ajustarCurva(
    List<PontoInfiltracaoMedido> pontos,
  ) {
    final invalidos = pontos.where(
      (p) =>
          !p.tempoMin.isFinite ||
          !p.taxaMmHora.isFinite ||
          p.tempoMin < 0 ||
          p.taxaMmHora < 0 ||
          (p.tempoMin == 0 && p.taxaMmHora != 0) ||
          (p.tempoMin > 0 && p.taxaMmHora <= 0),
    );
    if (invalidos.isNotEmpty) {
      throw ArgumentError(
        'Pontos de regressão devem ter T > 0 e VI > 0; apenas (0, 0) '
        'pode representar o início do ensaio.',
      );
    }

    // O ponto inicial (0, 0) é preservado no ensaio, mas não tem logaritmo.
    final validos = pontos
        .where((p) => p.tempoMin > 0 && p.taxaMmHora > 0)
        .toList();

    if (validos.length < 2) {
      throw ArgumentError(
        'Necessário pelo menos 2 pontos válidos (T > 0 e VI > 0). '
        'Recebidos: ${validos.length} de ${pontos.length}',
      );
    }
    final tempos = validos.map((point) => point.tempoMin).toSet();
    if (tempos.length != validos.length) {
      throw ArgumentError('Cada observação válida deve ter um tempo distinto.');
    }
    for (var i = 1; i < validos.length; i++) {
      if (validos[i].tempoMin <= validos[i - 1].tempoMin) {
        throw ArgumentError('Ordene as observações por tempo crescente.');
      }
    }

    // Regressão linear em escala log10
    // log10(VI) = log10(K) + n * log10(T)
    // y = a + b * x
    final quantidade = validos.length;
    double somaX = 0, somaY = 0, somaXY = 0, somaX2 = 0;

    for (final p in validos) {
      final logT = log(p.tempoMin) / ln10; // log10
      final logVI = log(p.taxaMmHora) / ln10; // log10
      somaX += logT;
      somaY += logVI;
      somaXY += logT * logVI;
      somaX2 += logT * logT;
    }

    final mediaX = somaX / quantidade;
    final mediaY = somaY / quantidade;

    final denominador = somaX2 - quantidade * mediaX * mediaX;
    if (denominador.abs() < 1e-15) {
      throw ArgumentError(
        'Denominador da regressão é zero. Verifique os pontos do ensaio.',
      );
    }

    // n (coeficiente angular) = slope
    final expoente = (somaXY - quantidade * mediaX * mediaY) / denominador;

    // log10(K) = intercept
    final logK = mediaY - expoente * mediaX;
    final coeficiente = pow(10, logK).toDouble();
    if (!coeficiente.isFinite || coeficiente <= 0) {
      throw ArgumentError(
        'O ajuste resultou em coeficiente K fora do domínio numérico.',
      );
    }

    // Coeficiente de determinação R²
    double ssRes = 0, ssTot = 0;
    for (final p in validos) {
      final logT = log(p.tempoMin) / ln10;
      final logVI = log(p.taxaMmHora) / ln10;
      final predito = logK + expoente * logT;
      ssRes += (logVI - predito) * (logVI - predito);
      ssTot += (logVI - mediaY) * (logVI - mediaY);
    }
    final r2 = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    return ParametrosInfiltracao(
      coeficiente: coeficiente,
      expoente: expoente,
      baseLog: 10,
      r2: r2,
      origem: OrigemParametrosInfiltracao.ensaio,
      unidadeCoeficiente: 'mm/h',
    );
  }

  /// Calcula a taxa de infiltração instantânea (VI) em um dado tempo.
  ///
  /// Equação: `VI = K * T^n`
  ///
  /// [tempoMin] — Tempo em minutos.
  /// [parametros] — Parâmetros K e n da curva.
  static double taxaInfiltracao({
    required double tempoMin,
    required ParametrosInfiltracao parametros,
  }) {
    if (!parametros.coeficiente.isFinite ||
        !parametros.expoente.isFinite ||
        parametros.coeficiente <= 0) {
      throw const FormatException(
        'VI exige coeficiente positivo e expoente finito.',
      );
    }
    if (!tempoMin.isFinite || tempoMin < 0) {
      throw const FormatException(
        'Tempo de infiltração fora do domínio (T ≥ 0).',
      );
    }
    if (tempoMin == 0 && parametros.expoente < 0) {
      throw const FormatException(
        'VI singular em T = 0 para expoente negativo.',
      );
    }
    if (tempoMin == 0 && parametros.expoente > 0) return 0;
    return parametros.coeficiente * pow(tempoMin, parametros.expoente);
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
    required ParametrosInfiltracao parametros,
  }) {
    if (!tempoMin.isFinite || tempoMin < 0) {
      throw const FormatException(
        'Tempo de infiltração fora do domínio (T ≥ 0).',
      );
    }
    if (!parametros.coeficiente.isFinite ||
        !parametros.expoente.isFinite ||
        parametros.coeficiente <= 0 ||
        parametros.expoente <= -1) {
      throw const FormatException(
        'Curva de infiltração acumulada fora do domínio (K > 0, n > −1).',
      );
    }
    if (tempoMin == 0) return 0;

    final expoenteAcumulado = parametros.expoente + 1;
    // I = [K / (60 * (n+1))] * T^(n+1)
    // Fator 60 converte K de mm/h para mm/min
    return (parametros.coeficiente / (60 * expoenteAcumulado)) *
        pow(tempoMin, expoenteAcumulado);
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
    if (!qEntradaLs.isFinite || !qSaidaLs.isFinite || !areaM2.isFinite) {
      throw ArgumentError('Vazões e área do ensaio devem ser valores finitos.');
    }
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
  static List<String> validarParametros(ParametrosInfiltracao parametros) {
    final erros = <String>[];

    if (parametros.coeficiente <= 0) {
      erros.add('K deve ser positivo (${parametros.coeficiente})');
    }
    if (parametros.expoente <= -1) {
      erros.add('n deve ser maior que -1 (n=${parametros.expoente})');
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

    final invalidos = pontos.where(
      (p) =>
          !p.tempoMin.isFinite ||
          !p.taxaMmHora.isFinite ||
          p.tempoMin < 0 ||
          p.taxaMmHora < 0,
    );
    if (invalidos.isNotEmpty) {
      erros.add(
        '${invalidos.length} ponto(s) com tempo ou taxa negativa '
        '(excluídos da regressão)',
      );
    }

    for (var i = 1; i < pontos.length; i++) {
      if (pontos[i].tempoMin <= pontos[i - 1].tempoMin) {
        erros.add('Tempos devem ser estritamente crescentes e únicos.');
        break;
      }
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
