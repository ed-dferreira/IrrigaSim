import 'nucleo_referencia.dart';

void perto(String nome, double atual, double esperado, [double tolerancia = 1e-5]) {
  if (!atual.isFinite || (atual - esperado).abs() > tolerancia) {
    throw StateError('$nome: $atual, esperado $esperado');
  }
}
void rejeita(String nome, void Function() acao) {
  try { acao(); } on ArgumentError { return; } on StateError { return; }
  throw StateError('$nome: entrada inválida não foi rejeitada');
}
void main() {
  final primeira = Infiltracao(0.0035, 0.47, 0.00011);
  perto('infiltração no instante zero', primeira.acumulada(0), 0);
  perto('infiltração em um minuto', primeira.acumulada(1), 0.00361);
  final p = dimensionar(primeira);
  final t = dimensionar(Infiltracao(0.0034, 0.45, 0.00010));
  perto('Q0 máximo', p['q0_m3_min_m']!, 0.8728887470978953);
  perto('avanço primeira', p['ta_min']!, 22.029325408391216);
  perto('avanço terceira', t['ta_min']!, 21.795724239885672);
  perto('Ea primeira', p['eficiencia_percent']!, 58.24490344811151);
  perto('Ea terceira', t['eficiencia_percent']!, 58.869157882385934);
  perto('corte mínimo no avanço', p['ti_min']!, p['ta_min']!);
  final c = continua(porosidade: 0.5, zMm: 500, laminaMm: 150,
    etMmDia: 7.2, kMmDia: 7, areaHa: 20, turnoDias: 2 * 0.5 * 50 / 7.2);
  perto('enchimento L/s', c['qe_l_s']!, 166.576);
  perto('manutenção L/s', c['qm_l_s']!, 32.944);
  // Caso sintético para testar unidades; não preenche lacunas do slide 84.
  final v = volumesArroz(ds: 1, dp: 2, ua: 0.5, pci: 0.5, h: 0.1,
    evaporacaoDia: 0.01, ksatDia: 0.001, periodoDias: 10, materiaSecaKgHa: 1000);
  perto('solo já saturado', v['v1_m3_ha']!, 0);
  perto('formação', v['v2_m3_ha']!, 1000);
  perto('evaporação', v['v3_m3_ha']!, 1000);
  perto('infiltração', v['v4_m3_ha']!, 120);
  perto('matéria seca', v['v5_m3_ha']!, 400);
  perto('volume total', v['vt_m3_ha']!, 2520);
  perto('m³/s', vazaoVolume(86400, 1, 1), 1);
  rejeita('tempo negativo', () { primeira.acumulada(-1); });
  rejeita('vazão insuficiente', () { tempoNaDistancia(200, 0.001, 0.04, primeira, 0.7); });
  rejeita('vazão erosiva', () { dimensionar(primeira, vazao: 2); });
  rejeita('NaN', () { Infiltracao(double.nan, 0.47, 0.00011); });
  rejeita('dias zero', () { vazaoVolume(1, 1, 0); });
  perto('Henderson', areaHenderson(100, 10), 1000);
  perto('tabela solo argiloso', areaGuiaSolo('argiloso', 20), 0.08);
  perto('declividade da água', declividadeLiquida(0.1, 100), 0.001);
  perto('Newton e bisseção', tempoNaDistanciaNewton(200, p['q0_m3_min_m']!,
    0.04, primeira, p['r']!), p['ta_min']!);
  perto('TR com Z em cm', turnoRega(2, 0.5, 50, 7.2), 6.944444444444445);
  perto('eficiência condução', eficienciaRazao(80, 100), 80);
  perto('lâmina aplicada mm', laminaAplicada(1, 1, 1000), 3.6);
  perto('matéria seca sintética', materiaSecaTotal(10, 50, 0.2, 0.4), 1000);
  // Caso operacional sintético: não atribuir estes valores ao slide 63.
  final op = parcelas(areaTotalM2: 80000, comprimentoM: 200,
    tabuleirosPorParcela: 2, q0M3MinM: 0.5, tiMin: 30,
    mudancaMin: 10, jornadaMinDia: 480, periodoDias: 1);
  perto('parcelas por dia', op['npd_inteiro']!, 12);
  perto('tabuleiros totais', op['ntt']!, 24);
  perto('Q total L/s', op['q_total_l_s']!, 277.77777777777777);
  if (!diqueComporta(0.2, 0.1, 0.05) || diqueComporta(0.12, 0.1, 0.05)) {
    throw StateError('Verificação da margem do dique falhou');
  }
  rejeita('eficiência >100%', () { eficienciaRazao(101, 100); });
  rejeita('jornada insuficiente', () { parcelas(areaTotalM2: 100,
    comprimentoM: 10, tabuleirosPorParcela: 1, q0M3MinM: 0.1,
    tiMin: 60, mudancaMin: 0, jornadaMinDia: 30, periodoDias: 1); });
  print('Todos os testes passaram.');
}
