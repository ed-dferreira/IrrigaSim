import 'dart:math' as math;

import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

import 'border_hydraulics.dart';

class BorderTrialResult {
  final BorderMeasuredAdvance advance;
  final List<BorderProfilePoint> profile;
  final double? entradaM3M, utilM3M, percoladoM3M, escoadoM3M, deficitM3M;
  final List<BorderNotice> avisos;
  const BorderTrialResult(
    this.advance,
    this.profile,
    this.entradaM3M,
    this.utilM3M,
    this.percoladoM3M,
    this.escoadoM3M,
    this.deficitM3M, {
    this.avisos = const [],
  });
  double? get ea => entradaM3M == null || utilM3M == null
      ? null
      : 100 * utilM3M! / entradaM3M!;

  BorderStatus get status =>
      BorderStatus.pior(avisos.map((notice) => notice.status));
}

class BorderFieldTrial {
  const BorderFieldTrial();

  BorderMeasuredAdvance fit(List<BorderStake> points) {
    if (points.length < 3 ||
        points.first.xM != 0 ||
        points.first.avancoMin != 0) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Informe a origem (0,0) e ao menos duas estacas medidas.',
      );
    }
    for (var i = 1; i < points.length; i++) {
      final p = points[i], prev = points[i - 1];
      if (!p.xM.isFinite ||
          !p.avancoMin.isFinite ||
          p.xM <= prev.xM ||
          p.avancoMin <= prev.avancoMin ||
          (p.recessaoMin != null &&
              (!p.recessaoMin!.isFinite || p.recessaoMin! <= p.avancoMin))) {
        throw const BorderModelException(
          BorderStatus.entradaInvalida,
          'Estacas devem ter distâncias e instantes crescentes; recessão posterior ao avanço.',
        );
      }
    }
    final samples = points.skip(1).toList();
    final xs = samples.map((p) => math.log(p.avancoMin)).toList();
    final ys = samples.map((p) => math.log(p.xM)).toList();
    final n = xs.length;
    final sx = xs.reduce((a, b) => a + b), sy = ys.reduce((a, b) => a + b);
    final sxx = xs.map((x) => x * x).reduce((a, b) => a + b);
    final sxy = List.generate(n, (i) => xs[i] * ys[i]).reduce((a, b) => a + b);
    final den = n * sxx - sx * sx;
    if (den.abs() < 1e-12) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Estacas insuficientes para ajustar o avanço.',
      );
    }
    final r = (n * sxy - sx * sy) / den, p = math.exp((sy - r * sx) / n);
    if (!r.isFinite || r <= 0 || !p.isFinite || p <= 0) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Curva de avanço inválida.',
      );
    }
    final rmse = math.sqrt(
      samples
              .map((point) {
                final err = math.pow(point.xM / p, 1 / r) - point.avancoMin;
                return err * err;
              })
              .reduce((a, b) => a + b) /
          n,
    );
    return BorderMeasuredAdvance(List.unmodifiable(points), p, r, rmse);
  }

  BorderTrialResult evaluate(
    BorderProject project,
    List<BorderStake> stakes, {
    double? cutoffMin,
  }) {
    final advance = fit(stakes);
    if (project.comprimentoM == null ||
        stakes.last.xM != project.comprimentoM) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'A última estaca deve coincidir com L; não extrapolar medições.',
      );
    }
    final recessionAvailable = stakes.every((s) => s.recessaoMin != null);
    final agronomiaDisponivel =
        project.irnEfetivaMm != null &&
        project.k != null &&
        project.a != null &&
        project.vibMMin != null;
    final avisos = <BorderNotice>[
      if (!recessionAvailable)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Ensaio sem recessão: exibidos apenas os indicadores de avanço.',
          pagina: 'p. 45',
        ),
      if (!agronomiaDisponivel)
        const BorderNotice(
          BorderStatus.entradaInvalida,
          'Ensaio sem IRN ou parâmetros de infiltração: volumes não calculados.',
          pagina: 'pp. 47, 56',
        ),
      if (cutoffMin == null || project.vazaoUnitariaLsM == null)
        const BorderNotice(
          BorderStatus.avisoOrientativo,
          'Sem corte e vazão do ensaio: volumes e Ea não são calculados.',
          pagina: 'p. 45',
        ),
    ];
    if (!recessionAvailable || !agronomiaDisponivel) {
      return BorderTrialResult(
        advance,
        const [],
        null,
        null,
        null,
        null,
        null,
        avisos: avisos,
      );
    }
    if (project.a! <= 0 ||
        project.a! >= 1 ||
        project.k! <= 0 ||
        project.vibMMin! < 0) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Infiltração do ensaio inválida.',
        pagina: 'pp. 47, 56',
      );
    }
    final profile = <BorderProfilePoint>[];
    final length = project.comprimentoM!;
    var interval = 0;
    for (var i = 0; i <= 400; i++) {
      final x = length * i / 400;
      while (interval < stakes.length - 2 && x > stakes[interval + 1].xM) {
        interval++;
      }
      final left = stakes[interval], right = stakes[interval + 1];
      final portion = (x - left.xM) / (right.xM - left.xM);
      // Avanço calculado pela curva ajustada; recessão interpolada entre estacas medidas.
      final arrival = advance.arrival(x);
      final recession =
          left.recessaoMin! +
          (right.recessaoMin! - left.recessaoMin!) * portion;
      final opportunity = recession - arrival;
      if (opportunity < 0 || !opportunity.isFinite) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Ensaio: oportunidade local negativa entre estacas.',
          pagina: 'pp. 45, 68',
        );
      }
      profile.add(
        BorderProfilePoint(
          x,
          arrival,
          recession,
          opportunity,
          BorderHydraulics.infiltracao(
            opportunity,
            project.k!,
            project.a!,
            project.vibMMin!,
          ),
        ),
      );
    }
    double? input;
    if (cutoffMin != null && project.vazaoUnitariaLsM != null) {
      if (!cutoffMin.isFinite ||
          cutoffMin <= 0 ||
          project.vazaoUnitariaLsM! <= 0) {
        throw const BorderModelException(
          BorderStatus.entradaInvalida,
          'Corte e vazão medidos devem ser positivos.',
        );
      }
      input = cutoffMin * project.vazaoUnitariaLsM! * .06;
    }
    final irn = project.irnEfetivaMm! / 1000;
    var useful = 0.0, percolated = 0.0, deficit = 0.0;
    for (var i = 1; i < profile.length; i++) {
      final prev = profile[i - 1], curr = profile[i];
      final z0 = prev.infiltracaoM, z1 = curr.infiltracaoM;
      final cross = (irn - z0) / (z1 - z0);
      final cuts = cross.isFinite && cross > 0 && cross < 1
          ? [0.0, cross, 1.0]
          : [0.0, 1.0];
      for (var j = 1; j < cuts.length; j++) {
        final a = cuts[j - 1], b = cuts[j], dx = (curr.xM - prev.xM) * (b - a);
        final za = z0 + (z1 - z0) * a, zb = z0 + (z1 - z0) * b;
        useful += dx * (math.min(za, irn) + math.min(zb, irn)) / 2;
        percolated += dx * (math.max(za - irn, 0) + math.max(zb - irn, 0)) / 2;
        deficit += dx * (math.max(irn - za, 0) + math.max(irn - zb, 0)) / 2;
      }
    }
    final runoff = input == null ? null : input - useful - percolated;
    if (runoff != null && runoff < -1e-7 * input!) {
      throw const BorderModelException(
        BorderStatus.balancoInconsistente,
        'Balanço medido inconsistente.',
        pagina: 'pp. 46–47',
      );
    }
    return BorderTrialResult(
      advance,
      profile,
      input,
      useful,
      percolated,
      runoff,
      deficit,
      avisos: avisos,
    );
  }
}
