/// Referência numérica da Aula 6, sem dependências externas.
/// Tempo em min, distâncias em m, vazões por sulco em L/s e lâminas em mm.
/// Modelo empírico com recessão desprezada; não hidrodinâmico.
import 'dart:math' as math;

void _positivo(String nome, num v) {
  if (!v.isFinite || v <= 0)
    throw ArgumentError('$nome deve ser finito e positivo');
}

void _naoNegativo(String nome, num v) {
  if (!v.isFinite || v < 0)
    throw ArgumentError('$nome deve ser finito e não negativo');
}

Map<String, double> doisPontos(double x1, double t1, double x2, double t2) {
  for (final e in {'x1': x1, 't1': t1, 'x2': x2, 't2': t2}.entries) {
    _positivo(e.key, e.value);
  }
  if (x2 <= x1 || t2 <= t1) throw ArgumentError('Avanço exige x2>x1 e t2>t1');
  final b = math.log(t2 / t1) / math.log(x2 / x1);
  return {'k': t2 / math.pow(x2, b), 'b': b};
}

Map<String, Object?> ajustarPotencia(List<double> xs, List<double> ys) {
  if (xs.length != ys.length || xs.length < 2)
    throw ArgumentError('Fornecer pares suficientes');
  for (final v in xs) {
    _positivo('x para log', v);
  }
  for (final v in ys) {
    _positivo('y para log', v);
  }
  final x = xs.map((v) => math.log(v) / math.ln10).toList();
  final y = ys.map((v) => math.log(v) / math.ln10).toList();
  final n = x.length;
  final xm = x.reduce((a, b) => a + b) / n;
  final ym = y.reduce((a, b) => a + b) / n;
  final sxx = x.fold(0.0, (s, v) => s + math.pow(v - xm, 2));
  if (sxx <= 0) throw ArgumentError('Abscissas iguais');
  var sxy = 0.0;
  var err = 0.0;
  var total = 0.0;
  var sumXY = 0.0;
  var sumX2 = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (x[i] - xm) * (y[i] - ym);
    sumXY += x[i] * y[i];
    sumX2 += x[i] * x[i];
  }
  final b = sxy / sxx;
  final intercept = ym - b * xm;
  for (var i = 0; i < n; i++) {
    err += math.pow(y[i] - (intercept + b * x[i]), 2);
    total += math.pow(y[i] - ym, 2);
  }
  return {
    'k': math.pow(10, intercept),
    'b': b,
    'intercepto_log10': intercept,
    'N': n,
    'R2_log': total == 0 ? null : 1 - err / total,
    'soma_log_x': x.reduce((a, b) => a + b),
    'soma_log_y': y.reduce((a, b) => a + b),
    'soma_xy': sumXY,
    'soma_x2': sumX2,
  };
}

List<double> coefAcumulado(
  double kVi,
  double expoenteVi, {
  String baseTaxa = 'mm_h',
}) {
  _positivo('K_vi', kVi);
  if (!expoenteVi.isFinite || expoenteVi <= -1)
    throw ArgumentError('Integral desde zero exige expoente > -1');
  if (baseTaxa != 'mm_h' && baseTaxa != 'L_min_m')
    throw ArgumentError('Base de taxa desconhecida');
  final divisor = baseTaxa == 'mm_h' ? 60.0 : 1.0;
  return [kVi / (divisor * (expoenteVi + 1)), expoenteVi + 1];
}

double infiltracao(double t, double k, double a) {
  _naoNegativo('oportunidade', t);
  _positivo('k', k);
  _positivo('a', a);
  return k * math.pow(t, a);
}

double oportunidade(double lamina, double k, double a) {
  _positivo('lamina', lamina);
  _positivo('k', k);
  _positivo('a', a);
  return math.pow(lamina / k, 1 / a).toDouble();
}

double qmax(double declivePercent, {double c = .631, double a = 1}) {
  _positivo('declive em %', declivePercent);
  _positivo('C', c);
  _positivo('a', a);
  return c / math.pow(declivePercent, a);
}

double irnGravimetrica(
  double uccPercent,
  double upmpPercent,
  double dsGCm3,
  double zCm,
  double f,
) {
  _naoNegativo('UPMP', upmpPercent);
  if (!uccPercent.isFinite || uccPercent <= upmpPercent)
    throw ArgumentError('UCC deve superar UPMP');
  _positivo('densidade', dsGCm3);
  _positivo('z', zCm);
  if (!f.isFinite || f <= 0 || f > 1) throw ArgumentError('f fora de (0,1]');
  return (uccPercent - upmpPercent) / 10 * dsGCm3 * zCm * f;
}

double turno(double craMm, double etcMmDia, [double chuvaEfetivaMmDia = 0]) {
  _positivo('CRA', craMm);
  _naoNegativo('ETc', etcMmDia);
  _naoNegativo('chuva efetiva', chuvaEfetivaMmDia);
  final demanda = etcMmDia - chuvaEfetivaMmDia;
  if (demanda <= 0)
    throw ArgumentError('Sem demanda líquida positiva; TR não aplicável');
  return craMm / demanda;
}

double laminaAplicada(
  List<(double, double)> etapas,
  double comprimento,
  double espacamento,
) {
  _positivo('L', comprimento);
  _positivo('E', espacamento);
  if (etapas.isEmpty) throw ArgumentError('Hidrograma vazio');
  var volume = 0.0;
  for (final (duracao, q) in etapas) {
    _positivo('duracao', duracao);
    _naoNegativo('q', q);
    volume += duracao * q;
  }
  return 60 * volume / (comprimento * espacamento);
}

double interpolar(List<double> xs, List<double> ys, double x) {
  if (xs.length != ys.length || xs.length < 2)
    throw ArgumentError('Pares insuficientes');
  if ([...xs, ...ys, x].any((v) => !v.isFinite))
    throw ArgumentError('Valor não finito');
  for (var i = 1; i < xs.length; i++) {
    if (xs[i] <= xs[i - 1]) throw ArgumentError('x deve crescer');
  }
  if (x < xs.first || x > xs.last)
    throw ArgumentError('Extrapolação não permitida');
  for (var i = 0; i < xs.length - 1; i++) {
    if (x <= xs[i + 1])
      return ys[i] + (ys[i + 1] - ys[i]) * (x - xs[i]) / (xs[i + 1] - xs[i]);
  }
  return ys.last;
}

double integrar(List<double> xs, List<double> ys) {
  if (xs.length != ys.length || xs.length < 2)
    throw ArgumentError('Pares insuficientes');
  if ([...xs, ...ys].any((v) => !v.isFinite))
    throw ArgumentError('Valor não finito');
  var total = 0.0;
  for (var i = 0; i < xs.length - 1; i++) {
    if (xs[i + 1] <= xs[i]) throw ArgumentError('x deve crescer');
    total += (xs[i + 1] - xs[i]) * (ys[i] + ys[i + 1]) / 2;
  }
  return total;
}

Map<String, Object> vazaoInfiltrada(
  List<double> xs,
  List<double> ta,
  double tInst, {
  double kVi = 1.411,
  double nVi = -.446,
}) {
  _positivo('K_vi', kVi);
  if (xs.length != ta.length) throw ArgumentError('Tamanhos diferentes');
  if (ta.any((t) => tInst <= t))
    throw ArgumentError('Oportunidades devem ser positivas');
  final taxas = ta.map((t) => kVi * math.pow(tInst - t, nVi)).toList();
  final total = integrar(xs, taxas);
  return {
    'taxas_L_min_m': taxas,
    'total_L_min': total,
    'total_L_s': total / 60,
  };
}

Map<String, double> indicadoresSlide(
  double li,
  double lf,
  double lm,
  double ll,
) {
  for (final e in {'Li': li, 'Lf': lf, 'Lm': lm, 'LL': ll}.entries) {
    _positivo(e.key, e.value);
  }
  final lmi = (li + lf) / 2;
  return {
    'Lmi': lmi,
    'Ed': 100 * lf / lmi,
    'Ea': 100 * lf / lm,
    'Pp': 100 * (lmi - ll) / lm,
    'Pe': 100 * (lm - lmi) / lm,
  };
}

Map<String, Object> avaliarPerfil(
  List<double> xs,
  List<double> laminas,
  double espacamento,
  double ll,
  double lm,
) {
  _positivo('E', espacamento);
  _positivo('LL', ll);
  _positivo('Lm', lm);
  if (laminas.any((z) => !z.isFinite || z < 0))
    throw ArgumentError('lamina deve ser finita e não negativa');
  if (xs.length != laminas.length) throw ArgumentError('Tamanhos diferentes');
  final comprimento = xs.last - xs.first;
  _positivo('comprimento', comprimento);
  final media = integrar(xs, laminas) / comprimento;
  final util =
      integrar(xs, laminas.map((z) => math.min(z, ll)).toList()) / comprimento;
  final percolada = media - util, deficit = ll - util, escoada = lm - media;
  final fator = espacamento * comprimento / 1000;
  return {
    'status': escoada >= -1e-8 ? 'valido_no_modelo' : 'balanco_inconsistente',
    'Lmi_mm': media,
    'lamina_util_mm': util,
    'lamina_percolada_mm': percolada,
    'deficit_mm': deficit,
    'lamina_escoada_mm': escoada,
    'Ea_integral': 100 * util / lm,
    'Er': 100 * util / ll,
    'Pp_integral': 100 * percolada / lm,
    'Pe_integral': 100 * escoada / lm,
    'volume_aplicado_m3': lm * fator,
    'volume_util_m3': util * fator,
    'volume_percolado_m3': percolada * fator,
    'volume_escoado_m3': escoada * fator,
  };
}

List<Map<String, double>> perfilRecessaoDesprezada(
  List<double> xs,
  List<double> temposAvanco,
  double tCorte,
  double kMm,
  double a,
) {
  if (xs.length != temposAvanco.length)
    throw ArgumentError('Tamanhos diferentes');
  return [
    for (var i = 0; i < xs.length; i++)
      {
        'x_m': xs[i],
        'ta_min': temposAvanco[i],
        'oportunidade_min': tCorte - temposAvanco[i],
        'infiltracao_mm': infiltracao(tCorte - temposAvanco[i], kMm, a),
      },
  ];
}

Map<String, num> organizar(
  double lt,
  double wt,
  double l,
  double e,
  double piDias,
  double tiMin,
  double tmudMin,
  double tdfMin,
  double qLs, {
  double perdasLs = 0,
}) {
  for (final entry in {
    'Lt': lt,
    'Wt': wt,
    'L': l,
    'E': e,
    'PI': piDias,
    'ti': tiMin,
    'TDF': tdfMin,
    'q': qLs,
  }.entries) {
    _positivo(entry.key, entry.value);
  }
  _naoNegativo('tmud', tmudMin);
  _naoNegativo('perdas', perdasLs);
  if ((lt / l - (lt / l).round()).abs() > 1e-8 ||
      (wt / e - (wt / e).round()).abs() > 1e-8)
    throw ArgumentError('Dimensões não fecham contagens inteiras');
  if (piDias != piDias.toInt())
    throw ArgumentError('Este cronograma usa dias inteiros');
  final nts = (lt / l).round() * (wt / e).round(), tip = tiMin + tmudMin;
  final npd = (tdfMin / tip).floor();
  if (npd < 1) throw ArgumentError('Nenhuma parcela completa cabe na jornada');
  final nsp = (nts / (piDias * npd)).ceil(), baterias = (nts / nsp).ceil();
  return {
    'NTS': nts,
    'NSD_medio': nts / piDias,
    'TIP_min': tip,
    'NPD_continuo': tdfMin / tip,
    'NPD_inteiro': npd,
    'NSP': nsp,
    'baterias_total': baterias,
    'dias_necessarios': (baterias / npd).ceil(),
    'Qprojeto_L_s': nsp * qLs + perdasLs,
  };
}
