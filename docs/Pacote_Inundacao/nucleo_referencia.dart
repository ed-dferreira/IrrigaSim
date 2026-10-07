// Referência didática: Aula 8, Irrigação por Inundação (UNIPAMPA).
// Sem dependências externas. Unidades explícitas; tempo em minutos no avanço.
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

double pot(double x, double p) => math.pow(x, p).toDouble();
void positivo(double x, String nome) {
  if (!x.isFinite || x <= 0) throw ArgumentError('$nome deve ser finito e > 0');
}
void naoNegativo(double x, String nome) {
  if (!x.isFinite || x < 0) throw ArgumentError('$nome deve ser finito e >= 0');
}

class Infiltracao {
  final double k, a, vib; // I em m, t em min; k em m/min^a, VIB em m/min.
  Infiltracao(this.k, this.a, this.vib) {
    positivo(k, 'k'); naoNegativo(vib, 'VIB');
    if (!a.isFinite || a <= 0 || a >= 1) throw ArgumentError('Exige 0 < a < 1');
  }
  double acumulada(double t) {
    naoNegativo(t, 'tempo'); return k * pot(t, a) + vib * t;
  }
}

// Q0 em m³/(min.m); Vmax em m/min; n de Manning; L em m. Slide 54.
double vazaoMaxima(double vmax, double n, double l) {
  positivo(vmax, 'Vmax'); positivo(n, 'n'); positivo(l, 'L');
  return pot(pot(vmax, 13 / 3) * n * n * l / 3600, 3 / 7);
}
// Expoente exato 3/13 (slide 58); 0,23 no slide 46 é arredondamento.
double profundidade(double q, double n, double x) {
  positivo(q, 'Q0'); positivo(n, 'n'); naoNegativo(x, 'x');
  return pot(q * q * n * n * x / 3600, 3 / 13);
}

double sigmaZ(double a, double r) => (a + r * (1 - a) + 1) / ((1 + a) * (1 + r));

// Mesma equação de balanço dos slides 55–59; bisseção com intervalo
// limitado substitui Newton para impedir tempos negativos na iteração.
double tempoNaDistancia(double x, double q, double n, Infiltracao solo, double r) {
  positivo(x, 'x'); positivo(q, 'Q0'); positivo(n, 'n'); positivo(r, 'r');
  final saldo = q - solo.vib * x / (1 + r);
  if (saldo <= 0) throw StateError('Vazão insuficiente para atingir a distância');
  final armazenamento = 0.77 * profundidade(q, n, x) * x;
  final coef = sigmaZ(solo.a, r) * solo.k * x;
  double f(double t) => saldo * t - armazenamento - coef * pot(t, solo.a);
  double baixo = 0, alto = 1;
  var passos = 0;
  while (f(alto) < 0 && passos++ < 200) { alto *= 2; }
  if (!alto.isFinite || f(alto) < 0) throw StateError('Raiz não delimitada');
  for (var i = 0; i < 200; i++) {
    final meio = (baixo + alto) / 2;
    if (f(meio) > 0) { alto = meio; } else { baixo = meio; }
    if (alto - baixo < 1e-9 * math.max(1.0, alto)) return (alto + baixo) / 2;
  }
  throw StateError('Bisseção não convergiu');
}

Map<String, double> dimensionar(Infiltracao solo, {
  double l = 200, double n = 0.040, double irn = 0.056,
  double vmax = 8, double? vazao,
}) {
  positivo(l, 'L'); positivo(n, 'n'); positivo(irn, 'IRN'); positivo(vmax, 'Vmax');
  final qmax = vazaoMaxima(vmax, n, l);
  final q = vazao ?? qmax;
  positivo(q, 'Q0');
  if (q > qmax * (1 + 1e-9)) throw ArgumentError('Q0 supera a vazão não erosiva');
  double r = 0.7, ta = 0;
  bool convergiu = false;
  for (var i = 0; i < 200; i++) {
    ta = tempoNaDistancia(l, q, n, solo, r);
    final metade = tempoNaDistancia(l / 2, q, n, solo, r);
    final novo = math.log(2) / math.log(ta / metade);
    if (!novo.isFinite || novo <= 0) throw StateError('Expoente r inválido');
    if ((novo - r).abs() < 1e-9) { r = novo; convergiu = true; break; }
    r = novo;
  }
  if (!convergiu) throw StateError('A atualização de r não convergiu');
  ta = tempoNaDistancia(l, q, n, solo, r);
  final y = profundidade(q, n, l);
  final ti = math.max(ta, (irn - 0.8 * y) * l / q + ta);
  return {'q0_m3_min_m': q, 'r': r, 'y0_m': y, 'ta_min': ta,
    'ti_min': ti, 'eficiencia_percent': irn * l / (q * ti) * 100};
}

// Slides 67–68. Z em mm; ET e K0 em mm/dia; área em ha.
// Mantém o fator arredondado 0,116 utilizado na aula.
Map<String, double> continua({required double porosidade, required double zMm,
  required double laminaMm, required double etMmDia, required double kMmDia,
  required double areaHa, required double turnoDias}) {
  if (!porosidade.isFinite || porosidade <= 0 || porosidade > 1) {
    throw ArgumentError('Porosidade deve estar entre 0 e 1');
  }
  positivo(zMm, 'Z'); positivo(areaHa, 'área'); positivo(turnoDias, 'TR');
  naoNegativo(laminaMm, 'lâmina'); naoNegativo(etMmDia, 'ET'); naoNegativo(kMmDia, 'K0');
  return {'qe_l_s': 0.116 * (porosidade * zMm + laminaMm +
    (etMmDia + kMmDia) * turnoDias) * areaHa / turnoDias,
    'qm_l_s': 0.116 * (etMmDia + kMmDia) * areaHa};
}

// Slides 76–80. Ua gravimétrica; densidades em g/cm³; comprimentos em m.
Map<String, double> volumesArroz({required double ds, required double dp,
  required double ua, required double pci, required double h,
  required double evaporacaoDia, required double ksatDia,
  required double periodoDias, required double materiaSecaKgHa}) {
  positivo(ds, 'Ds'); positivo(dp, 'Dp'); positivo(pci, 'PCI');
  positivo(periodoDias, 'período'); naoNegativo(h, 'h'); naoNegativo(ua, 'Ua');
  naoNegativo(evaporacaoDia, 'evaporação'); naoNegativo(ksatDia, 'Ksat');
  naoNegativo(materiaSecaKgHa, 'matéria seca');
  if (ds >= dp) throw ArgumentError('Ds deve ser menor que Dp');
  final pt = 1 - ds / dp, us = pt / ds;
  if (ua > us) throw ArgumentError('Ua supera a saturação');
  final v1 = (us - ua) * pci * 10000 * ds;
  final v2 = h * 10000, v3 = evaporacaoDia * periodoDias * 10000;
  final v4 = ksatDia * (h + pci) / pci * periodoDias * 10000;
  final v5 = 0.4 * materiaSecaKgHa;
  return {'v1_m3_ha': v1, 'v2_m3_ha': v2, 'v3_m3_ha': v3,
    'v4_m3_ha': v4, 'v5_m3_ha': v5, 'vt_m3_ha': v1 + v2 + v3 + v4 + v5};
}

// Slides 82–83. Resultado em m³/s; multiplicar por 1000 para L/s.
double vazaoVolume(double volumeM3Ha, double areaHa, double dias) {
  naoNegativo(volumeM3Ha, 'volume'); positivo(areaHa, 'área'); positivo(dias, 'dias');
  return volumeM3Ha * areaHa / (dias * 86400);
}

void main() {
  final resultado = {
    'primeira': dimensionar(Infiltracao(0.0035, 0.47, 0.00011)),
    'terceira': dimensionar(Infiltracao(0.0034, 0.45, 0.00010)),
    'continua_slide_73': continua(porosidade: 0.5, zMm: 500,
      laminaMm: 150, etMmDia: 7.2, kMmDia: 7, areaHa: 20,
      turnoDias: 2 * 0.5 * 50 / 7.2),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(resultado));
}

// Complementos da revisão página por página.
// p. 17: relação empírica de Henderson, transcrita com fator 100 da aula.
double areaHenderson(double qM3Hora, double vibMmHora) {
  positivo(qM3Hora, 'Q em m³/h'); positivo(vibMmHora, 'VIB em mm/h');
  return 100 * qM3Hora / vibMmHora;
}

// p. 16: guia, e não substituto do dimensionamento hidráulico.
double areaGuiaSolo(String solo, double qLitrosSegundo) {
  const fatores = {'arenoso': 0.01, 'franco-arenoso': 0.02,
    'franco-argiloso': 0.03, 'argiloso': 0.04};
  positivo(qLitrosSegundo, 'Q em L/s');
  final fator = fatores[solo];
  if (fator == null) throw ArgumentError('Tipo de solo ausente da tabela');
  return fator * qLitrosSegundo / 10; // ha
}

// p. 45: declividade da SUPERFÍCIE LÍQUIDA, mesmo com solo nivelado.
double declividadeLiquida(double y0, double x) {
  naoNegativo(y0, 'y0'); positivo(x, 'X'); return y0 / x;
}

// p. 47–50: infiltração final no início do tabuleiro.
double infiltracaoInicio(Infiltracao solo, double ta, double ti,
    double y0, double q0, double comprimento) {
  naoNegativo(ta, 'ta'); naoNegativo(ti, 'ti'); naoNegativo(y0, 'y0');
  positivo(q0, 'Q0'); positivo(comprimento, 'L');
  if (ti < ta) throw ArgumentError('ti deve ser >= ta');
  return solo.acumulada(ta) + 0.8 * y0 + q0 * (ti - ta) / comprimento;
}

// p. 35 e 54: compara profundidade na entrada + margem com a altura útil.
bool diqueComporta(double alturaM, double y0M, double margemM) {
  positivo(alturaM, 'altura'); naoNegativo(y0M, 'y0'); naoNegativo(margemM, 'margem');
  return y0M + margemM <= alturaM;
}

// p. 57: Newton-Raphson literal como alternativa à bisseção.
// Retorna erro se a iteração sair do domínio; não mascara não convergência.
double tempoNaDistanciaNewton(double x, double q, double n, Infiltracao solo, double r) {
  positivo(x, 'x'); positivo(q, 'Q0'); positivo(n, 'n'); positivo(r, 'r');
  final a0 = profundidade(q, n, x);
  final sigma = sigmaZ(solo.a, r);
  final saldo = q - solo.vib * x / (1 + r);
  if (saldo <= 0) throw StateError('Vazão insuficiente');
  double t = 5 * a0 * x / q;
  for (var i = 0; i < 200; i++) {
    final f = saldo * t - 0.77 * a0 * x - sigma * solo.k * x * pot(t, solo.a);
    final derivada = saldo - sigma * solo.a * solo.k * x / pot(t, 1 - solo.a);
    if (!derivada.isFinite || derivada.abs() < 1e-14) throw StateError('Derivada nula');
    final correcao = f / derivada;
    final novo = t - correcao;
    if (!novo.isFinite || novo <= 0) throw StateError('Newton saiu do domínio');
    if (correcao.abs() < 1e-9 * math.max(1.0, novo)) return novo;
    t = novo;
  }
  throw StateError('Newton não convergiu');
}

// p. 61–62. Usa comprimentoM em vez do ambíguo L da legenda do slide 61.
// PI aqui é o número de dias para atender a área, não os 100 dias do arroz.
Map<String, double> parcelas({required double areaTotalM2,
    required double comprimentoM, required int tabuleirosPorParcela,
    required double q0M3MinM, required double tiMin, required double mudancaMin,
    required double jornadaMinDia, required int periodoDias}) {
  positivo(areaTotalM2, 'área'); positivo(comprimentoM, 'comprimento');
  positivo(q0M3MinM, 'Q0'); positivo(tiMin, 'ti'); naoNegativo(mudancaMin, 'tm');
  positivo(jornadaMinDia, 'jornada');
  if (tabuleirosPorParcela <= 0 || periodoDias <= 0) throw ArgumentError('Contagens > 0');
  final tpp = tiMin + mudancaMin;
  // Parte inteira: apenas parcelas que cabem integralmente na jornada.
  final npd = (jornadaMinDia / tpp).floor();
  if (npd < 1) throw StateError('Nenhuma parcela cabe na jornada');
  final app = areaTotalM2 / (npd * periodoDias);
  final w = app / (tabuleirosPorParcela * comprimentoM);
  final q = w * tabuleirosPorParcela * q0M3MinM;
  return {'tpp_min': tpp, 'npd_teorico': jornadaMinDia / tpp,
    'npd_inteiro': npd.toDouble(), 'app_m2': app, 'largura_tabuleiro_m': w,
    'ntt': (tabuleirosPorParcela * npd * periodoDias).toDouble(),
    'q_total_m3_min': q, 'q_total_l_s': q * 1000 / 60};
}

// p. 67. Z em cm porque DTA é mm/cm.
double turnoRega(double dtaMmCm, double f, double zCm, double etMmDia) {
  positivo(dtaMmCm, 'DTA'); positivo(zCm, 'Z'); positivo(etMmDia, 'ET');
  if (!f.isFinite || f <= 0 || f > 1) throw ArgumentError('Exige 0 < f <= 1');
  return dtaMmCm * f * zCm / etMmDia;
}

// p. 70 e 72: razão em porcentagem; entradas devem referir-se ao mesmo período.
double eficienciaRazao(double util, double aplicado) {
  naoNegativo(util, 'quantidade útil'); positivo(aplicado, 'quantidade aplicada');
  if (util > aplicado) throw ArgumentError('Quantidade útil supera a aplicada');
  return 100 * util / aplicado;
}
double laminaAplicada(double qLitrosSegundo, double horas, double areaM2) {
  naoNegativo(qLitrosSegundo, 'Qm'); naoNegativo(horas, 'ti'); positivo(areaM2, 'área');
  return 3600 * qLitrosSegundo * horas / areaM2; // mm
}

// p. 84: transformação derivada, requer massa do saco explícita.
double materiaSecaTotal(double sacosHa, double kgPorSaco,
    double umidadeGraos, double indiceColheita) {
  naoNegativo(sacosHa, 'produção'); positivo(kgPorSaco, 'massa do saco');
  if (!umidadeGraos.isFinite || umidadeGraos < 0 || umidadeGraos >= 1 ||
      !indiceColheita.isFinite || indiceColheita <= 0 || indiceColheita > 1) {
    throw ArgumentError('Umidade em [0,1) e índice de colheita em (0,1]');
  }
  return sacosHa * kgPorSaco * (1 - umidadeGraos) / indiceColheita;
}

// p. 60: melhor resultado entre candidatos explícitos, sem afirmar ótimo global.
Map<String, double> selecionarMelhorVazao(Infiltracao solo, List<double> candidatos,
    {double l = 200, double n = 0.04, double irn = 0.056, double vmax = 8,
    required double alturaDiqueM, required double margemLivreM}) {
  positivo(alturaDiqueM, 'altura'); naoNegativo(margemLivreM, 'margem');
  if (candidatos.isEmpty) throw ArgumentError('Lista de candidatos vazia');
  final maximo = vazaoMaxima(vmax, n, l);
  Map<String, double>? melhor;
  for (final q in candidatos) {
    positivo(q, 'candidato Q0');
    if (q > maximo) continue;
    Map<String, double> atual;
    try { atual = dimensionar(solo, l: l, n: n, irn: irn, vmax: vmax, vazao: q); }
    on StateError { continue; }
    if (!diqueComporta(alturaDiqueM, atual['y0_m']!, margemLivreM)) continue;
    if (atual['eficiencia_percent']! > 100) continue;
    if (melhor == null || atual['eficiencia_percent']! > melhor['eficiencia_percent']!) {
      melhor = atual;
    }
  }
  if (melhor == null) throw StateError('Nenhum candidato viável');
  return melhor;
}
