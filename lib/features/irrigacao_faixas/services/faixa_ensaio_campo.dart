import 'dart:math' as math;

import 'package:irrigasim/features/irrigacao_faixas/models/faixa_medicoes.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';

import 'faixa_hidraulica.dart';

class BorderTrialResult {
  /// Ensaio medido: ajuste do avanço e perfil interpolado entre estacas.
  final BorderMeasuredAdvance avanco;
  final List<BorderProfilePoint> perfil;
  final double? entradaM3M, utilM3M, percoladoM3M, escoadoM3M, deficitM3M;
  final List<BorderNotice> avisos;
  const BorderTrialResult({
    required this.avanco,
    required this.perfil,
    required this.entradaM3M,
    required this.utilM3M,
    required this.percoladoM3M,
    required this.escoadoM3M,
    required this.deficitM3M,
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

  /// Ajusta x = p·t^r (§6.1) por mínimos quadrados em escala logarítmica.
  BorderMeasuredAdvance ajustar(List<BorderStake> points) {
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

  /// Avalia o ensaio: perfil τ/I, volumes por trapézios e Ea (§6.2–6.3).
  BorderTrialResult avaliar(
    BorderProject project,
    List<BorderStake> stakes, {
    double? cutoffMin,
  }) {
    final avanco = ajustar(stakes);
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
      for (var i = 1; i < stakes.length; i++)
        if ((stakes[i].xM - stakes[i - 1].xM) < 10 ||
            (stakes[i].xM - stakes[i - 1].xM) > 30)
          BorderNotice(
            BorderStatus.avisoOrientativo,
            'Espaçamento entre estacas ${stakes[i - 1].xM}–${stakes[i].xM} m fora da recomendação de 10–30 m.',
            pagina: 'pp. 33–41',
          ),
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
        avanco: avanco,
        perfil: const [],
        entradaM3M: null,
        utilM3M: null,
        percoladoM3M: null,
        escoadoM3M: null,
        deficitM3M: null,
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
    final perfil = <BorderProfilePoint>[];
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
      final chegada = avanco.arrival(x);
      final recessao =
          left.recessaoMin! +
          (right.recessaoMin! - left.recessaoMin!) * portion;
      final oportunidade = recessao - chegada;
      if (oportunidade < 0 || !oportunidade.isFinite) {
        throw const BorderModelException(
          BorderStatus.foraDoDominio,
          'Ensaio: oportunidade local negativa entre estacas.',
          pagina: 'pp. 45, 68',
        );
      }
      perfil.add(
        BorderProfilePoint(
          x,
          chegada,
          recessao,
          oportunidade,
          BorderHydraulics.infiltracao(
            oportunidade,
            project.k!,
            project.a!,
            project.vibMMin!,
          ),
        ),
      );
    }
    double? entrada;
    if (cutoffMin != null && project.vazaoUnitariaLsM != null) {
      if (!cutoffMin.isFinite ||
          cutoffMin <= 0 ||
          project.vazaoUnitariaLsM! <= 0) {
        throw const BorderModelException(
          BorderStatus.entradaInvalida,
          'Corte e vazão medidos devem ser positivos.',
        );
      }
      entrada = cutoffMin * project.vazaoUnitariaLsM! * .06;
    }
    final irn = project.irnEfetivaMm! / 1000;
    var util = 0.0, percolado = 0.0, deficit = 0.0;
    for (var i = 1; i < perfil.length; i++) {
      final prev = perfil[i - 1], curr = perfil[i];
      final z0 = prev.infiltracaoM, z1 = curr.infiltracaoM;
      final cross = (irn - z0) / (z1 - z0);
      final cuts = cross.isFinite && cross > 0 && cross < 1
          ? [0.0, cross, 1.0]
          : [0.0, 1.0];
      for (var j = 1; j < cuts.length; j++) {
        final a = cuts[j - 1], b = cuts[j], dx = (curr.xM - prev.xM) * (b - a);
        final za = z0 + (z1 - z0) * a, zb = z0 + (z1 - z0) * b;
        util += dx * (math.min(za, irn) + math.min(zb, irn)) / 2;
        percolado += dx * (math.max(za - irn, 0) + math.max(zb - irn, 0)) / 2;
        deficit += dx * (math.max(irn - za, 0) + math.max(irn - zb, 0)) / 2;
      }
    }
    final escoado = entrada == null ? null : entrada - util - percolado;
    if (escoado != null && escoado < -1e-7 * entrada!) {
      throw const BorderModelException(
        BorderStatus.balancoInconsistente,
        'Balanço medido inconsistente.',
        pagina: 'pp. 46–47',
      );
    }
    return BorderTrialResult(
      avanco: avanco,
      perfil: perfil,
      entradaM3M: entrada,
      utilM3M: util,
      percoladoM3M: percolado,
      escoadoM3M: escoado,
      deficitM3M: deficit,
      avisos: avisos,
    );
  }
}
