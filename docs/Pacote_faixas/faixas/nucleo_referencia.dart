/// Núcleo de referência da Aula 7; normalizações documentadas no pacote.
/// Unidades: m, min, vazão unitária m³/min/m e declividades decimais.
/// Faixa aberta em declive, vazão constante e recessão linear.
import 'dart:math' as math;

void _positivo(String nome, double valor) {
  if (!valor.isFinite || valor <= 0)
    throw ArgumentError('$nome deve ser finito e positivo');
}

void _solo(double k, double a, double vib) {
  _positivo('k', k);
  if (!a.isFinite || a <= 0 || a >= 1)
    throw ArgumentError('Este núcleo exige 0 < a < 1');
  if (!vib.isFinite || vib < 0)
    throw ArgumentError('VIB deve ser finita e não negativa');
}

double infiltracao(double t, double k, double a, double vib) {
  _solo(k, a, vib);
  if (!t.isFinite || t < 0)
    throw ArgumentError('Tempo de oportunidade negativo ou não finito');
  return k * math.pow(t, a) + vib * t;
}

double raizCrescente(double Function(double) f, {double tolerancia = 1e-11}) {
  var lo = 0.0, hi = 100.0;
  var limitado = false;
  for (var i = 0; i < 100; i++) {
    if (f(hi) >= 0) {
      limitado = true;
      break;
    }
    hi *= 2;
  }
  if (!limitado) throw ArgumentError('Não foi possível limitar a raiz');
  for (var i = 0; i < 200; i++) {
    final mid = (lo + hi) / 2;
    if (f(mid) > 0) {
      hi = mid;
    } else {
      lo = mid;
    }
    if (hi - lo <= tolerancia) return (hi + lo) / 2;
  }
  throw ArgumentError('Raiz sem convergência');
}

double oportunidade(double irn, double k, double a, double vib) {
  _positivo('IRN', irn);
  _solo(k, a, vib);
  return raizCrescente((t) => infiltracao(t, k, a, vib) - irn);
}

double oportunidadeNewton(double irn, double k, double a, double vib) {
  _positivo('IRN', irn);
  _solo(k, a, vib);
  var t = 100.0;
  for (var i = 0; i < 100; i++) {
    final residual = infiltracao(t, k, a, vib) - irn;
    final tn = t - residual / (k * a * math.pow(t, a - 1) + vib);
    if (!tn.isFinite || tn <= 0) return oportunidade(irn, k, a, vib);
    if ((tn - t).abs() < 1e-10) return tn;
    t = tn;
  }
  throw ArgumentError('Newton sem convergência');
}

double profundidade(double q, double n, double s0) {
  _positivo('q', q);
  _positivo('n', n);
  _positivo('S0', s0);
  return math.pow(q * q * n * n / (3600 * s0), .3).toDouble();
}

double hartLiteral(double s0, {bool coberturaTotal = false}) {
  _positivo('S0', s0);
  return .01059 * math.pow(s0, -.75) * (coberturaTotal ? 2 : 1);
}

double vazaoMinima(double l, double n, double s0) {
  _positivo('L', l);
  _positivo('n', n);
  _positivo('S0', s0);
  return .000357 * l * math.sqrt(s0) / n;
}

Map<String, double> avanco(
  double q,
  double l,
  double n,
  double s0,
  double k,
  double a,
  double vib,
) {
  _positivo('L', l);
  _solo(k, a, vib);
  final y = profundidade(q, n, s0);
  var r = .7;
  for (var iteration = 0; iteration < 200; iteration++) {
    final sigma = (a + r * (1 - a) + 1) / ((1 + a) * (1 + r));
    double calcular(double x) {
      final coef = q - vib * x / (1 + r);
      if (coef <= 0)
        throw ArgumentError('Balanço sem raiz positiva: vazão insuficiente');
      return raizCrescente(
        (t) => coef * t - .77 * y * x - sigma * k * math.pow(t, a) * x,
      );
    }

    final ta = calcular(l), tm = calcular(l / 2);
    if (!(ta > tm && tm > 0))
      throw ArgumentError('Tempos de avanço inconsistentes');
    final rn = math.ln2 / math.log(ta / tm);
    if ((rn - r).abs() < 1e-11) {
      return {
        'ta': ta,
        'ta_meio': tm,
        'r': rn,
        'p': l / math.pow(ta, rn),
        'sigma_z': sigma,
        'y0': y,
        'iteracoes_r': (iteration + 1).toDouble(),
      };
    }
    r = rn;
  }
  throw ArgumentError('Expoente r sem convergência');
}

List<double> duracaoRecessao(
  double td,
  double ta,
  double q,
  double l,
  double n,
  double s0,
  double k,
  double a,
  double vib,
) {
  if (td <= ta) throw ArgumentError('Modelo de VIM exige td > ta');
  final vim =
      a * k / 2 * (math.pow(td, a - 1) + math.pow(td - ta, a - 1)) + vib;
  final qf = q - vim * l;
  if (qf <= 0) throw ArgumentError('Modelo de recessão exige q - VIM*L > 0');
  final sy = math.pow(qf * n / (60 * math.sqrt(s0)), .6) / l;
  final duracao =
      .095 *
      math.pow(n, .47565) *
      math.pow(sy, .20725) *
      math.pow(l, .6829) /
      (math.pow(vim, .52435) * math.pow(s0, .237825));
  return [duracao, vim, sy, qf];
}

double trapezios(List<double> valores, double l) =>
    l /
    (valores.length - 1) *
    (valores.reduce((a, b) => a + b) - (valores.first + valores.last) / 2);

({Map<String, Object> resultado, List<Map<String, double>> perfil}) simular(
  double k,
  double a,
  double vib, {
  double irn = .056,
  double q = .2,
  double l = 400,
  double n = .04,
  double s0 = .001,
  int segmentos = 2000,
}) {
  if (segmentos < 2) throw ArgumentError('Usar pelo menos dois segmentos');
  final t0 = oportunidade(irn, k, a, vib);
  final av = avanco(q, l, n, s0, k, a, vib);
  final ta = av['ta']!, y = av['y0']!;
  var tr = t0 + ta, td = tr;
  var convergiu = false;
  for (var i = 0; i < 1000; i++) {
    final dt = duracaoRecessao(td, ta, q, l, n, s0, k, a, vib).first;
    final novo = tr - dt;
    if ((novo - td).abs() < 1e-9) {
      td = novo;
      convergiu = true;
      break;
    }
    td = novo;
  }
  if (!convergiu) throw ArgumentError('Depleção sem convergência');
  final ajustado = td < t0;
  if (ajustado) {
    td = t0;
    final dt = duracaoRecessao(td, ta, q, l, n, s0, k, a, vib).first;
    tr = td + dt;
  }
  final recessao = duracaoRecessao(td, ta, q, l, n, s0, k, a, vib);
  final vim = recessao[1], sy = recessao[2], qf = recessao[3];
  final ti = td - y * l / (2 * q);
  _positivo('tempo de corte', ti);
  if (ti < ta)
    throw ArgumentError('Corte antes do avanço completo: exige outro modelo');
  final perfil = <Map<String, double>>[];
  for (var i = 0; i <= segmentos; i++) {
    final x = l * i / segmentos;
    final tav = ta * math.pow(x / l, 1 / av['r']!);
    final trec = td + (tr - td) * x / l;
    final tau = trec - tav;
    if (tau < 0) throw ArgumentError('Recessão anterior ao avanço');
    perfil.add({
      'x_m': x,
      'avanco_min': tav,
      'recessao_min': trec,
      'oportunidade_min': tau,
      'infiltracao_m': infiltracao(tau, k, a, vib),
    });
  }
  final zs = perfil.map((p) => p['infiltracao_m']!).toList();
  final vin = q * ti, vi = trapezios(zs, l);
  final vu = trapezios(zs.map((z) => math.min(z, irn)).toList(), l);
  final vp = vi - vu, ve = vin - vi;
  if (ve < -1e-6)
    throw ArgumentError(
      'Infiltração excede volume aplicado; modelo inconsistente',
    );
  return (
    resultado: {
      ...av,
      't0': t0,
      'td': td,
      'tr': tr,
      'ti': ti,
      'VIM': vim,
      'Sy': sy,
      'qf': qf,
      'ajuste_td_para_t0': ajustado,
      'I_inicio': zs.first,
      'I_final': zs.last,
      'I_min': zs.reduce(math.min),
      'volume_aplicado_unitario': vin,
      'volume_infiltrado_unitario': vi,
      'volume_util_unitario': vu,
      'volume_percolado_unitario': vp,
      'volume_escoado_unitario': ve,
      'Ea': 100 * vu / vin,
      'Er': 100 * vu / (irn * l),
      'Pp': 100 * vp / vin,
      'Pe': 100 * ve / vin,
      'Ea_simplificada': 100 * irn * l / vin,
    },
    perfil: perfil,
  );
}
