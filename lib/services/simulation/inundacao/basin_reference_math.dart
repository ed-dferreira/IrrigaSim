// Porte literal de docs/Pacote_Inundacao/nucleo_referencia.dart.
// Fonte: Aula 8 — Irrigação por Inundação, Prof.ª Chaiane Guerra da
// Conceição, UNIPAMPA. Sem dependências externas; unidades explícitas.
//
// Convenções da referência: tempo em minutos no avanço; Q0 em m³/(min·m);
// lâminas e distâncias em metros; VIB em m/min; Vmax em m/min; n de Manning.
// Erros de domínio são ArgumentError/StateError; a camada de simulação os
// converte em FormatException amigável para a interface.
import 'dart:math' as math;

double pot(double x, double p) => math.pow(x, p).toDouble();

void positivo(double x, String nome) {
  if (!x.isFinite || x <= 0) {
    throw ArgumentError('$nome deve ser finito e > 0');
  }
}

void naoNegativo(double x, String nome) {
  if (!x.isFinite || x < 0) {
    throw ArgumentError('$nome deve ser finito e >= 0');
  }
}

/// Lei de infiltração de Kostiakov acumulada: I(t) = k t^a + VIB t.
/// I em m, t em min; k em m/min^a, VIB em m/min.
class Infiltracao {
  Infiltracao(this.k, this.a, this.vib) {
    positivo(k, 'k');
    naoNegativo(vib, 'VIB');
    if (!a.isFinite || a <= 0 || a >= 1) {
      throw ArgumentError('Exige 0 < a < 1');
    }
  }

  final double k;
  final double a;
  final double vib;

  double acumulada(double t) {
    naoNegativo(t, 'tempo');
    return k * pot(t, a) + vib * t;
  }
}

/// Q0 máximo não erosivo (slide 54). Q0 em m³/(min·m).
double vazaoMaxima(double vmax, double n, double l) {
  positivo(vmax, 'Vmax');
  positivo(n, 'n');
  positivo(l, 'L');
  return pot(pot(vmax, 13 / 3) * n * n * l / 3600, 3 / 7);
}

/// Profundidade normal na entrada. Expoente exato 3/13 (slide 58); o 0,23
/// do slide 46 é arredondamento e não é usado aqui.
double profundidade(double q, double n, double x) {
  positivo(q, 'Q0');
  positivo(n, 'n');
  naoNegativo(x, 'x');
  return pot(q * q * n * n * x / 3600, 3 / 13);
}

double sigmaZ(double a, double r) =>
    (a + r * (1 - a) + 1) / ((1 + a) * (1 + r));

/// Tempo até a distância x pela bisseção (rotina principal da referência).
/// A mesma equação de balanço dos slides 55–59; o intervalo limitado
/// substitui Newton para impedir tempos negativos na iteração.
double tempoNaDistancia(
  double x,
  double q,
  double n,
  Infiltracao solo,
  double r,
) {
  positivo(x, 'x');
  positivo(q, 'Q0');
  positivo(n, 'n');
  positivo(r, 'r');
  final saldo = q - solo.vib * x / (1 + r);
  if (saldo <= 0) {
    throw StateError('Vazão insuficiente para atingir a distância');
  }
  final armazenamento = 0.77 * profundidade(q, n, x) * x;
  final coef = sigmaZ(solo.a, r) * solo.k * x;
  double f(double t) => saldo * t - armazenamento - coef * pot(t, solo.a);
  var baixo = 0.0, alto = 1.0;
  var passos = 0;
  while (f(alto) < 0 && passos++ < 200) {
    alto *= 2;
  }
  if (!alto.isFinite || f(alto) < 0) {
    throw StateError('Raiz não delimitada');
  }
  for (var i = 0; i < 200; i++) {
    final meio = (baixo + alto) / 2;
    if (f(meio) > 0) {
      alto = meio;
    } else {
      baixo = meio;
    }
    if (alto - baixo < 1e-9 * math.max(1.0, alto)) {
      return (alto + baixo) / 2;
    }
  }
  throw StateError('Bisseção não convergiu');
}

/// Newton-Raphson literal (p. 57) como alternativa à bisseção. Retorna erro
/// se a iteração sair do domínio; não mascara não convergência.
double tempoNaDistanciaNewton(
  double x,
  double q,
  double n,
  Infiltracao solo,
  double r,
) {
  positivo(x, 'x');
  positivo(q, 'Q0');
  positivo(n, 'n');
  positivo(r, 'r');
  final a0 = profundidade(q, n, x);
  final sigma = sigmaZ(solo.a, r);
  final saldo = q - solo.vib * x / (1 + r);
  if (saldo <= 0) {
    throw StateError('Vazão insuficiente');
  }
  var t = 5 * a0 * x / q;
  for (var i = 0; i < 200; i++) {
    final f = saldo * t - 0.77 * a0 * x - sigma * solo.k * x * pot(t, solo.a);
    final derivada = saldo - sigma * solo.a * solo.k * x / pot(t, 1 - solo.a);
    if (!derivada.isFinite || derivada.abs() < 1e-14) {
      throw StateError('Derivada nula');
    }
    final correcao = f / derivada;
    final novo = t - correcao;
    if (!novo.isFinite || novo <= 0) {
      throw StateError('Newton saiu do domínio');
    }
    if (correcao.abs() < 1e-9 * math.max(1.0, novo)) {
      return novo;
    }
    t = novo;
  }
  throw StateError('Newton não convergiu');
}

/// Resultado do dimensionamento intermitente por unidade de largura.
class BasinDimensioningResult {
  const BasinDimensioningResult({
    required this.q0M3MinM,
    required this.r,
    required this.y0M,
    required this.taMin,
    required this.tiMin,
    required this.eficienciaPercent,
    required this.residualBalancoM3M,
    required this.s0,
  });

  /// Vazão por unidade de largura, m³/(min·m).
  final double q0M3MinM;

  /// Expoente da lei de avanço tx = ta (x/L)^(1/r).
  final double r;

  /// Profundidade normal na entrada, m.
  final double y0M;

  /// Tempo de avanço até L, min.
  final double taMin;

  /// Tempo de oportunidade no fim do tabuleiro, min (máx[ta, …]).
  final double tiMin;

  /// Eficiência de aplicação Ea = 100 IRN L/(Q0 ti), %.
  final double eficienciaPercent;

  /// |Q0 ta − 0,77 y0 L − σz k ta^a L − VIB ta L/(1+r)|, em m³/m (G10).
  final double residualBalancoM3M;

  /// Declividade da superfície líquida S0 = y0/L, adimensional (G10).
  final double s0;

  Map<String, double> toMap() => {
    'q0_m3_min_m': q0M3MinM,
    'r': r,
    'y0_m': y0M,
    'ta_min': taMin,
    'ti_min': tiMin,
    'eficiencia_percent': eficienciaPercent,
    'residual_balanco_m3_m': residualBalancoM3M,
    's0': s0,
  };
}

/// Dimensionamento intermitente: iteração de r, ti = max[ta,(IRN−0,8y0)L/Q0+ta]
/// e Ea = 100 IRN L/(Q0 ti). Bloqueia Q0 acima da vazão não erosiva, salvo
/// quando [exigirVazaoNaoErosiva] é falso: nesse caso a rotina de simulação
/// avalia a vazão informada e reporta o excesso como alerta de interface.
BasinDimensioningResult dimensionar(
  Infiltracao solo, {
  double l = 200,
  double n = 0.040,
  double irn = 0.056,
  double vmax = 8,
  double? vazao,
  double rInicial = 0.7,
  bool exigirVazaoNaoErosiva = true,
}) {
  positivo(l, 'L');
  positivo(n, 'n');
  positivo(irn, 'IRN');
  positivo(vmax, 'Vmax');
  positivo(rInicial, 'r inicial');
  final qmax = vazaoMaxima(vmax, n, l);
  final q = vazao ?? qmax;
  positivo(q, 'Q0');
  if (exigirVazaoNaoErosiva && q > qmax * (1 + 1e-9)) {
    throw ArgumentError('Q0 supera a vazão não erosiva');
  }
  var r = rInicial, ta = 0.0;
  var convergiu = false;
  for (var i = 0; i < 200; i++) {
    ta = tempoNaDistancia(l, q, n, solo, r);
    final metade = tempoNaDistancia(l / 2, q, n, solo, r);
    final novo = math.log(2) / math.log(ta / metade);
    if (!novo.isFinite || novo <= 0) {
      throw StateError('Expoente r inválido');
    }
    if ((novo - r).abs() < 1e-9) {
      r = novo;
      convergiu = true;
      break;
    }
    r = novo;
  }
  if (!convergiu) {
    throw StateError('A atualização de r não convergiu');
  }
  ta = tempoNaDistancia(l, q, n, solo, r);
  final y = profundidade(q, n, l);
  final ti = math.max(ta, (irn - 0.8 * y) * l / q + ta);
  final saldo = q - solo.vib * l / (1 + r);
  final residual =
      (saldo * ta -
              0.77 * y * l -
              sigmaZ(solo.a, r) * solo.k * pot(ta, solo.a) * l)
          .abs();
  return BasinDimensioningResult(
    q0M3MinM: q,
    r: r,
    y0M: y,
    taMin: ta,
    tiMin: ti,
    eficienciaPercent: irn * l / (q * ti) * 100,
    residualBalancoM3M: residual,
    s0: y / l,
  );
}

/// Resultado do regime contínuo (slides 67–68).
class BasinContinuaResult {
  const BasinContinuaResult({required this.qeLS, required this.qmLS});

  /// Vazão de enchimento, L/s.
  final double qeLS;

  /// Vazão de manutenção, L/s.
  final double qmLS;

  Map<String, double> toMap() => {'qe_l_s': qeLS, 'qm_l_s': qmLS};
}

/// Qe e Qm do regime contínuo. Z em mm; ET e K0 em mm/dia; área em ha.
/// Mantém o fator arredondado 0,116 utilizado na aula.
BasinContinuaResult continua({
  required double porosidade,
  required double zMm,
  required double laminaMm,
  required double etMmDia,
  required double kMmDia,
  required double areaHa,
  required double turnoDias,
}) {
  if (!porosidade.isFinite || porosidade <= 0 || porosidade > 1) {
    throw ArgumentError('Porosidade deve estar entre 0 e 1');
  }
  positivo(zMm, 'Z');
  positivo(areaHa, 'área');
  positivo(turnoDias, 'TR');
  naoNegativo(laminaMm, 'lâmina');
  naoNegativo(etMmDia, 'ET');
  naoNegativo(kMmDia, 'K0');
  return BasinContinuaResult(
    qeLS:
        0.116 *
        (porosidade * zMm + laminaMm + (etMmDia + kMmDia) * turnoDias) *
        areaHa /
        turnoDias,
    qmLS: 0.116 * (etMmDia + kMmDia) * areaHa,
  );
}

/// Turno de rega (p. 67). DTA em mm/cm e Z em cm, como na fonte.
double turnoRega(double dtaMmCm, double f, double zCm, double etMmDia) {
  positivo(dtaMmCm, 'DTA');
  positivo(zCm, 'Z');
  positivo(etMmDia, 'ET');
  if (!f.isFinite || f <= 0 || f > 1) {
    throw ArgumentError('Exige 0 < f <= 1');
  }
  return dtaMmCm * f * zCm / etMmDia;
}

/// Volumes de água do arroz (slides 76–80), em m³/ha. Ua gravimétrica;
/// densidades em g/cm³; comprimentos em m.
class RiceVolumesResult {
  const RiceVolumesResult({
    required this.pt,
    required this.us,
    required this.v1M3Ha,
    required this.v2M3Ha,
    required this.v3M3Ha,
    required this.v4M3Ha,
    required this.v5M3Ha,
    required this.vtM3Ha,
  });

  /// Porosidade total PT = 1 − Ds/Dp.
  final double pt;

  /// Umidade de saturação gravimétrica Us = PT/Ds.
  final double us;

  final double v1M3Ha;
  final double v2M3Ha;
  final double v3M3Ha;
  final double v4M3Ha;
  final double v5M3Ha;
  final double vtM3Ha;

  Map<String, double> toMap() => {
    'pt': pt,
    'us': us,
    'v1_m3_ha': v1M3Ha,
    'v2_m3_ha': v2M3Ha,
    'v3_m3_ha': v3M3Ha,
    'v4_m3_ha': v4M3Ha,
    'v5_m3_ha': v5M3Ha,
    'vt_m3_ha': vtM3Ha,
  };
}

RiceVolumesResult volumesArroz({
  required double ds,
  required double dp,
  required double ua,
  required double pci,
  required double h,
  required double evaporacaoDia,
  required double ksatDia,
  required double periodoDias,
  required double materiaSecaKgHa,
}) {
  positivo(ds, 'Ds');
  positivo(dp, 'Dp');
  positivo(pci, 'PCI');
  positivo(periodoDias, 'período');
  naoNegativo(h, 'h');
  naoNegativo(ua, 'Ua');
  naoNegativo(evaporacaoDia, 'evaporação');
  naoNegativo(ksatDia, 'Ksat');
  naoNegativo(materiaSecaKgHa, 'matéria seca');
  if (ds >= dp) {
    throw ArgumentError('Ds deve ser menor que Dp');
  }
  final pt = 1 - ds / dp, us = pt / ds;
  if (ua > us) {
    throw ArgumentError('Ua supera a saturação');
  }
  final v1 = (us - ua) * pci * 10000 * ds;
  final v2 = h * 10000, v3 = evaporacaoDia * periodoDias * 10000;
  final v4 = ksatDia * (h + pci) / pci * periodoDias * 10000;
  final v5 = 0.4 * materiaSecaKgHa;
  return RiceVolumesResult(
    pt: pt,
    us: us,
    v1M3Ha: v1,
    v2M3Ha: v2,
    v3M3Ha: v3,
    v4M3Ha: v4,
    v5M3Ha: v5,
    vtM3Ha: v1 + v2 + v3 + v4 + v5,
  );
}

/// Vazão média para aplicar um volume em um número de dias (slides 82–83).
/// Resultado em m³/s; multiplicar por 1000 para L/s.
double vazaoVolume(double volumeM3Ha, double areaHa, double dias) {
  naoNegativo(volumeM3Ha, 'volume');
  positivo(areaHa, 'área');
  positivo(dias, 'dias');
  return volumeM3Ha * areaHa / (dias * 86400);
}

/// Razão em porcentagem (p. 70 e 72). As entradas devem referir-se ao
/// mesmo período.
double eficienciaRazao(double util, double aplicado) {
  naoNegativo(util, 'quantidade útil');
  positivo(aplicado, 'quantidade aplicada');
  if (util > aplicado) {
    throw ArgumentError('Quantidade útil supera a aplicada');
  }
  return 100 * util / aplicado;
}

/// Lâmina aplicada em mm: 3600 Q ti / A com Q em L/s, ti em h, A em m².
double laminaAplicada(double qLitrosSegundo, double horas, double areaM2) {
  naoNegativo(qLitrosSegundo, 'Qm');
  naoNegativo(horas, 'ti');
  positivo(areaM2, 'área');
  return 3600 * qLitrosSegundo * horas / areaM2;
}

/// Matéria seca total a partir da produção em sacos/ha (p. 84): transformação
/// derivada que requer a massa do saco explícita.
double materiaSecaTotal(
  double sacosHa,
  double kgPorSaco,
  double umidadeGraos,
  double indiceColheita,
) {
  naoNegativo(sacosHa, 'produção');
  positivo(kgPorSaco, 'massa do saco');
  if (!umidadeGraos.isFinite ||
      umidadeGraos < 0 ||
      umidadeGraos >= 1 ||
      !indiceColheita.isFinite ||
      indiceColheita <= 0 ||
      indiceColheita > 1) {
    throw ArgumentError('Umidade em [0,1) e índice de colheita em (0,1]');
  }
  return sacosHa * kgPorSaco * (1 - umidadeGraos) / indiceColheita;
}

/// Relação empírica de Henderson (p. 17): A = 100 Q/VIB. A em m², Q em
/// m³/h e VIB em mm/h. O fator 100 é o da aula e não deve ser substituído
/// pelo fator de conversão volumétrica 1000.
double areaHenderson(double qM3Hora, double vibMmHora) {
  positivo(qM3Hora, 'Q em m³/h');
  positivo(vibMmHora, 'VIB em mm/h');
  return 100 * qM3Hora / vibMmHora;
}

/// Guia de área por vazão (p. 16), em ha. É um guia, e não substituto do
/// dimensionamento hidráulico.
double areaGuiaSolo(String solo, double qLitrosSegundo) {
  const fatores = {
    'arenoso': 0.01,
    'franco-arenoso': 0.02,
    'franco-argiloso': 0.03,
    'argiloso': 0.04,
  };
  positivo(qLitrosSegundo, 'Q em L/s');
  final fator = fatores[solo];
  if (fator == null) {
    throw ArgumentError('Tipo de solo ausente da tabela');
  }
  return fator * qLitrosSegundo / 10; // ha
}

/// Declividade da superfície líquida (p. 45), mesmo com solo nivelado.
double declividadeLiquida(double y0, double x) {
  naoNegativo(y0, 'y0');
  positivo(x, 'X');
  return y0 / x;
}

/// Infiltração final no início do tabuleiro (p. 47–50):
/// I0 = k ta^a + VIB ta + 0,80 y0 + Q0(ti−ta)/L.
double infiltracaoInicio(
  Infiltracao solo,
  double ta,
  double ti,
  double y0,
  double q0,
  double comprimento,
) {
  naoNegativo(ta, 'ta');
  naoNegativo(ti, 'ti');
  naoNegativo(y0, 'y0');
  positivo(q0, 'Q0');
  positivo(comprimento, 'L');
  if (ti < ta) {
    throw ArgumentError('ti deve ser >= ta');
  }
  return solo.acumulada(ta) + 0.8 * y0 + q0 * (ti - ta) / comprimento;
}

/// Compara profundidade na entrada + margem com a altura útil da taipa
/// (p. 35 e 54).
bool diqueComporta(double alturaM, double y0M, double margemM) {
  positivo(alturaM, 'altura');
  naoNegativo(y0M, 'y0');
  naoNegativo(margemM, 'margem');
  return y0M + margemM <= alturaM;
}

/// Lâmina média mantida no tabuleiro, Lm = (Li + Lf)/2 (figura p. 34–35).
double laminaMediaPlanalto(double liM, double lfM) {
  naoNegativo(liM, 'Li');
  naoNegativo(lfM, 'Lf');
  return (liM + lfM) / 2;
}

/// Regra 2/3 do desnível admissível (p. 15, 20 e 34–35): Δz ≤ 2 Lm/3.
/// Exemplo da p. 20: lâmina de 15 cm admite 10 cm de desnível.
double desnivelAdmissivel(double laminaMediaM) {
  naoNegativo(laminaMediaM, 'lâmina média');
  return 2 * laminaMediaM / 3;
}

/// Comprimento máximo isolado para uma declividade dada, pela regra 2/3:
/// L = Δz_admissível/S. Exemplos da p. 20: 0,25% → 40 m; 0,05% → 200 m.
/// Os limites são considerados separadamente em cada direção; se os dois
/// declives se acumularem entre cantos opostos, confira o desnível total.
double comprimentoMaximoPorDesnivel(double laminaMediaM, double declividade) {
  positivo(declividade, 'declividade');
  return desnivelAdmissivel(laminaMediaM) / declividade;
}

/// Planejamento em parcelas (p. 61–62). Usa comprimentoM em vez do ambíguo
/// L da legenda do slide 61. PI aqui é o número de dias para atender a área,
/// não os 100 dias do arroz.
class ParcelasResult {
  const ParcelasResult({
    required this.tppMin,
    required this.npdTeorico,
    required this.npdInteiro,
    required this.appM2,
    required this.larguraTabuleiroM,
    required this.ntt,
    required this.qTotalM3Min,
    required this.qTotalLS,
  });

  /// Tempo por parcela TPP = ti + tm, min.
  final double tppMin;

  /// NPD teórico = TDF/TPP.
  final double npdTeorico;

  /// Parcelas por dia que cabem integralmente na jornada (parte inteira).
  final int npdInteiro;

  /// Área por parcela APP = Atotal/(NPD PI), m².
  final double appM2;

  /// Largura do tabuleiro W0 = APP/(NTP L), m.
  final double larguraTabuleiroM;

  /// Número total de tabuleiros NTT = NTP · NPD · PI.
  final int ntt;

  /// Vazão total Q = W0 · NTP · Q0, m³/min.
  final double qTotalM3Min;

  /// Vazão total em L/s.
  final double qTotalLS;

  Map<String, double> toMap() => {
    'tpp_min': tppMin,
    'npd_teorico': npdTeorico,
    'npd_inteiro': npdInteiro.toDouble(),
    'app_m2': appM2,
    'largura_tabuleiro_m': larguraTabuleiroM,
    'ntt': ntt.toDouble(),
    'q_total_m3_min': qTotalM3Min,
    'q_total_l_s': qTotalLS,
  };
}

ParcelasResult parcelas({
  required double areaTotalM2,
  required double comprimentoM,
  required int tabuleirosPorParcela,
  required double q0M3MinM,
  required double tiMin,
  required double mudancaMin,
  required double jornadaMinDia,
  required int periodoDias,
}) {
  positivo(areaTotalM2, 'área');
  positivo(comprimentoM, 'comprimento');
  positivo(q0M3MinM, 'Q0');
  positivo(tiMin, 'ti');
  naoNegativo(mudancaMin, 'tm');
  positivo(jornadaMinDia, 'jornada');
  if (tabuleirosPorParcela <= 0 || periodoDias <= 0) {
    throw ArgumentError('Contagens > 0');
  }
  final tpp = tiMin + mudancaMin;
  // Parte inteira: apenas parcelas que cabem integralmente na jornada.
  final npd = (jornadaMinDia / tpp).floor();
  if (npd < 1) {
    throw StateError('Nenhuma parcela cabe na jornada');
  }
  final app = areaTotalM2 / (npd * periodoDias);
  final w = app / (tabuleirosPorParcela * comprimentoM);
  final q = w * tabuleirosPorParcela * q0M3MinM;
  return ParcelasResult(
    tppMin: tpp,
    npdTeorico: jornadaMinDia / tpp,
    npdInteiro: npd,
    appM2: app,
    larguraTabuleiroM: w,
    ntt: tabuleirosPorParcela * npd * periodoDias,
    qTotalM3Min: q,
    qTotalLS: q * 1000 / 60,
  );
}

/// Melhor resultado entre candidatos explícitos (p. 60), sem afirmar ótimo
/// global. Verifica vazão não erosiva, altura do dique com margem e
/// eficiência ≤ 100%.
BasinDimensioningResult selecionarMelhorVazao(
  Infiltracao solo,
  List<double> candidatos, {
  double l = 200,
  double n = 0.04,
  double irn = 0.056,
  double vmax = 8,
  double rInicial = 0.7,
  required double alturaDiqueM,
  required double margemLivreM,
}) {
  positivo(alturaDiqueM, 'altura');
  naoNegativo(margemLivreM, 'margem');
  if (candidatos.isEmpty) {
    throw ArgumentError('Lista de candidatos vazia');
  }
  final maximo = vazaoMaxima(vmax, n, l);
  BasinDimensioningResult? melhor;
  for (final q in candidatos) {
    positivo(q, 'candidato Q0');
    if (q > maximo) {
      continue;
    }
    BasinDimensioningResult atual;
    try {
      atual = dimensionar(
        solo,
        l: l,
        n: n,
        irn: irn,
        vmax: vmax,
        vazao: q,
        rInicial: rInicial,
      );
    } on StateError {
      continue;
    }
    if (!diqueComporta(alturaDiqueM, atual.y0M, margemLivreM)) {
      continue;
    }
    if (atual.eficienciaPercent > 100) {
      continue;
    }
    if (melhor == null || atual.eficienciaPercent > melhor.eficienciaPercent) {
      melhor = atual;
    }
  }
  if (melhor == null) {
    throw StateError('Nenhum candidato viável');
  }
  return melhor;
}
