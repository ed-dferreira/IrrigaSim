import 'dart:math' as math;

import 'package:irrigasim/models/faixas/border_numeric.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

class BorderHydraulics {
  const BorderHydraulics();

  static double infiltracao(double t, double k, double a, double vib) =>
      t == 0 ? 0 : k * math.pow(t, a) + vib * t;

  static double vazaoMinimaM3MinM(double length, double slope, double n) =>
      0.000357 * length * math.sqrt(slope) / n;

  /// Fronteira de unidades: q0 informada em L/s/m entra no núcleo em m³/min/m.
  static double paraM3MinM(double vazaoLsM) => vazaoLsM * 0.06;

  static double hartLiteral(double slope, {bool coberturaTotal = false}) =>
      0.01059 * math.pow(slope, -0.75) * (coberturaTotal ? 2 : 1);

  /// Raiz crescente, com bisseção salvaguardada. Nunca avalia derivada em zero.
  double _root(
    double Function(double) f,
    double Function(double) derivative,
    double initial,
    BorderNumericConfig numerico,
    String step, {
    required String? pagina,
    List<double>? history,
  }) {
    var lo = 0.0;
    var hi = math.max(initial, 1.0);
    for (var i = 0; i < numerico.maxIteracoes && f(hi) < 0; i++) {
      hi *= 2;
      if (!hi.isFinite || hi > 1e12) {
        throw BorderModelException(
          BorderStatus.foraDoDominio,
          '$step: raiz fora do domínio.',
          pagina: pagina,
        );
      }
    }
    if (f(hi) < 0) {
      throw BorderModelException(
        BorderStatus.foraDoDominio,
        '$step: não há raiz positiva.',
        pagina: pagina,
      );
    }
    var x = (lo + hi) / 2;
    for (var i = 0; i < numerico.maxIteracoes; i++) {
      final residual = f(x);
      history?.add(x);
      if (residual.abs() <= numerico.toleranciaResiduo &&
          (hi - lo) <= 1e-5 * math.max(1, x)) {
        return x;
      }
      if (residual > 0) {
        hi = x;
      } else {
        lo = x;
      }
      final d = derivative(x);
      final candidate = d.isFinite && d > 0 ? x - residual / d : double.nan;
      x = candidate.isFinite && candidate > lo && candidate < hi
          ? candidate
          : (lo + hi) / 2;
    }
    throw BorderModelException(
      BorderStatus.semConvergencia,
      '$step: sem convergência.',
      pagina: pagina,
    );
  }

  double oportunidade(
    double irnM,
    double k,
    double a,
    double vib, {
    BorderNumericConfig numerico = BorderNumericConfig.padrao,
    List<double>? history,
  }) {
    if (!irnM.isFinite || irnM <= 0) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'IRN deve ser finita e positiva.',
      );
    }
    return _root(
      (t) => infiltracao(t, k, a, vib) - irnM,
      (t) => k * a * math.pow(t, a - 1) + vib,
      100,
      numerico,
      'Oportunidade',
      pagina: 'pp. 47, 56',
      history: history,
    );
  }

  /// Perfil τ/I por fração uniforme do comprimento; τ<0 é rejeitado, não
  /// convertido em módulo.
  static List<BorderProfilePoint> montarPerfil({
    required double comprimentoM,
    required double taFinalMin,
    required double r,
    required double tdMin,
    required double trFinalMin,
    required int segmentos,
    required double k,
    required double a,
    required double vib,
  }) {
    if (segmentos < 2) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'n_segmentos deve ser pelo menos 2.',
      );
    }
    final perfil = <BorderProfilePoint>[];
    for (var i = 0; i <= segmentos; i++) {
      final x = comprimentoM * i / segmentos;
      final fraction = x / comprimentoM;
      final avanco = fraction == 0
          ? 0.0
          : taFinalMin * math.pow(fraction, 1 / r);
      final recessao = tdMin + (trFinalMin - tdMin) * fraction;
      final tau = recessao - avanco;
      if (tau < 0 || !tau.isFinite) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Oportunidade local negativa.',
          pagina: 'pp. 45, 68',
        );
      }
      perfil.add(
        BorderProfilePoint(
          x,
          avanco,
          recessao,
          tau,
          infiltracao(tau, k, a, vib),
        ),
      );
    }
    return perfil;
  }

  /// Volume infiltrado (por metro de largura) repartido em útil, percolado e
  /// déficit. O método padrão insere o cruzamento da IRN antes dos trapézios
  /// (F23/F24); `trapezios` integra os segmentos sem esse ponto de divisão.
  static BorderVolumes integrarPerfil(
    List<BorderProfilePoint> perfil,
    double irnM, {
    String metodo = BorderNumericConfig.metodoIntegracaoPadrao,
  }) {
    if (!BorderNumericConfig.metodosIntegracao.contains(metodo)) {
      throw BorderModelException(
        BorderStatus.entradaInvalida,
        'Método de integração desconhecido: $metodo.',
      );
    }
    var util = 0.0, perc = 0.0, deficit = 0.0, adequado = 0.0;
    var infiltradoAdequado = 0.0, infiltradoDeficitario = 0.0;
    for (var i = 0; i < perfil.length - 1; i++) {
      final left = perfil[i], right = perfil[i + 1];
      final dx = right.xM - left.xM;
      final z0 = left.infiltracaoM, z1 = right.infiltracaoM;
      if (z0 >= irnM && z1 >= irnM) {
        adequado += dx;
      } else if ((z0 >= irnM) != (z1 >= irnM) && z1 != z0) {
        adequado += dx * (irnM - z0).abs() / (z1 - z0).abs();
      }
      final cross = (irnM - z0) / (z1 - z0);
      final regionalSplits = cross > 0 && cross < 1 && cross.isFinite
          ? [0.0, cross, 1.0]
          : [0.0, 1.0];
      for (var j = 0; j < regionalSplits.length - 1; j++) {
        final f0 = regionalSplits[j], f1 = regionalSplits[j + 1];
        final zA = z0 + (z1 - z0) * f0, zB = z0 + (z1 - z0) * f1;
        final width = dx * (f1 - f0);
        final regional = width * (zA + zB) / 2;
        if ((zA + zB) / 2 >= irnM) {
          infiltradoAdequado += regional;
        } else {
          infiltradoDeficitario += regional;
        }
      }
      final splits =
          (metodo == BorderNumericConfig.metodoIntegracaoPadrao &&
              cross > 0 &&
              cross < 1 &&
              cross.isFinite)
          ? [0.0, cross, 1.0]
          : [0.0, 1.0];
      for (var j = 0; j < splits.length - 1; j++) {
        final f0 = splits[j], f1 = splits[j + 1];
        final zA = z0 + (z1 - z0) * f0, zB = z0 + (z1 - z0) * f1;
        final width = dx * (f1 - f0);
        util += width * (math.min(zA, irnM) + math.min(zB, irnM)) / 2;
        perc += width * (math.max(zA - irnM, 0) + math.max(zB - irnM, 0)) / 2;
        deficit +=
            width * (math.max(irnM - zA, 0) + math.max(irnM - zB, 0)) / 2;
      }
    }
    return BorderVolumes(
      util,
      perc,
      deficit,
      adequado,
      infiltradoAdequado,
      infiltradoDeficitario,
    );
  }

  BorderResult dimensionar(BorderProject p) {
    final impedimento = p.impedimento;
    if (impedimento != null) {
      throw BorderModelException(
        impedimento.status,
        impedimento.mensagem,
        pagina: impedimento.pagina,
      );
    }
    final numerico = p.numerico;
    final l = p.comprimentoM!, w = p.larguraM!, s = p.declividadeLongitudinal!;
    final n = p.rugosidadeN!, k = p.k!, a = p.a!, vib = p.vibMMin!;
    final q = paraM3MinM(p.vazaoUnitariaLsM!), irn = p.irnEfetivaMm! / 1000;
    final segmentos = numerico.nSegmentos;
    final values = [l, w, s, n, k, a, vib, q, irn, p.rInicial ?? 0.7];
    if (values.any((v) => !v.isFinite)) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Entradas não finitas.',
      );
    }
    final historyT0 = <double>[], historyR = <double>[], historyTd = <double>[];
    final t0 = oportunidade(
      irn,
      k,
      a,
      vib,
      numerico: numerico,
      history: historyT0,
    );
    final y0 = math.pow(q * q * n * n / (3600 * s), 0.3).toDouble();
    var r = p.rInicial ?? 0.7;
    if (r <= 0) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'r inicial deve ser positivo.',
      );
    }
    var sigma = 0.0, tm = 0.0, ta = 0.0, converged = false;
    for (var i = 0; i < numerico.maxIteracoes; i++) {
      sigma = (a + r * (1 - a) + 1) / ((1 + a) * (1 + r));
      double solve(double x) {
        final linear = q - vib * x / (1 + r);
        if (linear <= 0) {
          throw BorderModelException(
            BorderStatus.foraDoDominio,
            'Avanço: q0 insuficiente para X=${x.toStringAsFixed(1)} m.',
            pagina: 'pp. 45, 57–62',
          );
        }
        final storage = 0.77 * y0 * x;
        return _root(
          (t) => linear * t - storage - sigma * k * math.pow(t, a) * x,
          (t) => linear - sigma * k * a * math.pow(t, a - 1) * x,
          5 * y0 * x / q,
          numerico,
          'Avanço em X=${x.toStringAsFixed(1)} m',
          pagina: 'pp. 45, 57–62',
        );
      }

      tm = solve(l / 2);
      ta = solve(l);
      final calculated = math.ln2 / math.log(ta / tm);
      historyR.add(calculated);
      if (!calculated.isFinite || calculated <= 0) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Avanço: expoente fora do domínio.',
          pagina: 'p. 58',
        );
      }
      if ((calculated - r).abs() < numerico.toleranciaPasso) {
        r = calculated;
        converged = true;
        break;
      }
      r = calculated;
    }
    if (!converged) {
      throw const BorderModelException(
        BorderStatus.semConvergencia,
        'Avanço: sem convergência de r.',
        pagina: 'p. 58',
      );
    }
    sigma = (a + r * (1 - a) + 1) / ((1 + a) * (1 + r));
    final residualAvanco =
        (q * ta -
                0.77 * y0 * l -
                sigma * k * math.pow(ta, a) * l -
                vib * ta * l / (1 + r))
            .abs();
    final alvo = t0 + ta;
    double vim(double td) {
      if (td <= ta) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Depleção: td ≤ ta.',
          pagina: 'pp. 43–45, 62–66',
        );
      }
      return a * k / 2 * (math.pow(td, a - 1) + math.pow(td - ta, a - 1)) + vib;
    }

    double qFinal(double td) {
      final qf = q - vim(td) * l;
      if (qf <= 0 || !qf.isFinite) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Depleção: qf ≤ 0.',
          pagina: 'p. 44',
        );
      }
      return qf;
    }

    double duracao(double td) {
      final rate = vim(td), qf = qFinal(td);
      final yf = math.pow(qf * n / (60 * math.sqrt(s)), 0.6).toDouble();
      final sy = yf / l;
      // Expoentes da p.43 (E10): numerico.versaoExpoentesRecessao fixa a
      // versão e nenhuma outra entra aqui.
      return 0.095 *
          math.pow(n, 0.47565) *
          math.pow(sy, 0.20725) *
          math.pow(l, 0.6829) /
          (math.pow(rate, 0.52435) * math.pow(s, 0.237825));
    }

    var td = alvo;
    for (var i = 0; i < numerico.maxIteracoes; i++) {
      final next = alvo - duracao(td);
      historyTd.add(next);
      if (next <= ta) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Depleção: td ≤ ta.',
          pagina: 'pp. 43–45, 62–66',
        );
      }
      if ((next - td).abs() < numerico.toleranciaPasso) {
        td = next;
        break;
      }
      td = (next + td) / 2;
      if (i == numerico.maxIteracoes - 1) {
        throw const BorderModelException(
          BorderStatus.semConvergencia,
          'Depleção: sem convergência.',
          pagina: 'p. 66',
        );
      }
    }
    // Rearranjo da p.66 quando a depleção convergir antes da lâmina alvo.
    if (td < t0) td = t0;
    final qf = qFinal(td), delta = duracao(td), tr = td + delta;
    final ti = td - y0 * l / (2 * q);
    if (ti <= 0 || ti < ta - 1e-7) {
      throw const BorderModelException(
        BorderStatus.foraDoDominio,
        'Corte anterior ao avanço completo: fora do domínio do modelo.',
        pagina: 'p. 64',
      );
    }
    final perfil = montarPerfil(
      comprimentoM: l,
      taFinalMin: ta,
      r: r,
      tdMin: td,
      trFinalMin: tr,
      segmentos: segmentos,
      k: k,
      a: a,
      vib: vib,
    );
    final volumes = integrarPerfil(
      perfil,
      irn,
      metodo: numerico.metodoIntegracao,
    );
    final util = volumes.utilM3M,
        perc = volumes.percoladoM3M,
        deficit = volumes.deficitM3M;
    final entrada = q * ti, runoff = entrada - util - perc;
    if (runoff < -1e-7 * entrada || !runoff.isFinite) {
      throw const BorderModelException(
        BorderStatus.balancoInconsistente,
        'Balanço inconsistente: infiltração excede entrada.',
        pagina: 'pp. 46–47',
      );
    }
    final avisos = <BorderNotice>[
      if (l < 50 || l > 400)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Comprimento fora da faixa usual de 50–400 m.',
          pagina: 'p. 18',
        ),
      if (w < 4 || w > 20)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Largura fora da faixa usual de 4–20 m.',
          pagina: 'p. 19',
        ),
      if (s < 0.002 || s > 0.06)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Declive fora da faixa usual de 0,2–6%.',
          pagina: 'p. 12',
        ),
      if (s > 0.03)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Declive >3%: aula recomenda dois sulcos transversais no início e aproximadamente três adicionais equidistantes; construção não modelada.',
          pagina: 'p. 15',
        ),
      if (q < vazaoMinimaM3MinM(l, s, n))
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'q0 abaixo da recomendação F03.',
          pagina: 'pp. 53–55',
        ),
      const BorderNotice(
        BorderStatus.avisoOrientativo,
        'Hart F01 é reprodução literal de unidade empírica por confirmar; F04 depende de qmax confirmado.',
        pagina: 'p. 53',
      ),
      if (p.alturaDiqueM == null)
        const BorderNotice(
          BorderStatus.entradaInvalida,
          'Altura real do dique não informada.',
          pagina: 'p. 23',
        ),
      if (p.alturaDiqueM != null &&
          (!p.alturaDiqueM!.isFinite || p.alturaDiqueM! <= 0))
        const BorderNotice(
          BorderStatus.entradaInvalida,
          'Altura real do dique deve ser finita e positiva.',
          pagina: 'p. 23',
        ),
      if (p.alturaDiqueM != null && y0 > p.alturaDiqueM!)
        const BorderNotice(
          BorderStatus.foraDoDominio,
          'Profundidade na entrada excede a altura do dique.',
          pagina: 'p. 55',
        ),
      if (p.laminaSuperficialM == null)
        const BorderNotice(
          BorderStatus.entradaInvalida,
          'Lâmina superficial hn não informada; largura não verificada.',
          pagina: 'p. 13',
        ),
      if (p.laminaSuperficialM != null &&
          (!p.laminaSuperficialM!.isFinite || p.laminaSuperficialM! <= 0))
        const BorderNotice(
          BorderStatus.entradaInvalida,
          'Lâmina superficial hn deve ser finita e positiva.',
          pagina: 'pp. 13, 19',
        ),
      if (p.laminaSuperficialM != null &&
          p.declividadeTransversal != null &&
          p.declividadeTransversal!.abs() * w > .4 * p.laminaSuperficialM!)
        const BorderNotice(
          BorderStatus.foraDoDominio,
          'Desnível transversal excede 0,4 hn.',
          pagina: 'pp. 13, 19',
        ),
    ];
    return BorderResult(
      t0Min: t0,
      taMetadeMin: tm,
      taFinalMin: ta,
      tiMin: ti,
      tdMin: td,
      trFinalMin: tr,
      y0M: y0,
      r: r,
      sigmaZ: sigma,
      qfM3MinM: qf,
      residualOportunidadeM: (infiltracao(t0, k, a, vib) - irn).abs(),
      residualAvancoM3M: residualAvanco,
      residualRecessaoMin: (tr - td - delta).abs(),
      volumeEntradaM3M: entrada,
      volumeUtilM3M: util,
      volumePercoladoM3M: perc,
      volumeEscoadoM3M: runoff,
      volumeDeficitM3M: deficit,
      comprimentoAdequadoM: volumes.comprimentoAdequadoM,
      volumeAdequadoM3M: volumes.infiltradoAdequadoM3M,
      volumeDeficitarioM3M: volumes.infiltradoDeficitarioM3M,
      infiltracaoFinalM: infiltracao(tr - ta, k, a, vib),
      ea: 100 * util / entrada,
      er: 100 * util / (irn * l),
      pp: 100 * perc / entrada,
      pe: 100 * runoff / entrada,
      larguraM: w,
      perfil: perfil,
      status: BorderStatus.pior(avisos.map((notice) => notice.status)),
      avisos: avisos,
      numerico: numerico,
      convergencia: BorderConvergenceHistory(
        opportunityMin: historyT0,
        advanceExponent: historyR,
        recessionEndMin: historyTd,
      ),
    );
  }
}
