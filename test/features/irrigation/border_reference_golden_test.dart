// Regressão dourada da Etapa 7 contra docs/Pacote_faixas/faixas.
// Fonte: extração §§8.3–8.5 e resultados_referencia.json (reconstrução interna,
// não gabarito oficial da professora).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_numeric.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';

const pacote = 'docs/Pacote_faixas/faixas';

Map<String, dynamic> lerJson(String nome) =>
    jsonDecode(File('$pacote/$nome').readAsStringSync())
        as Map<String, dynamic>;

double numero(Object? valor) => (valor as num).toDouble();

BorderProject cenarioProjeto(Map<String, dynamic> cenario, {int? nSegmentos}) =>
    BorderProject(
      comprimentoM: 400,
      larguraM: 1,
      desnivelLongitudinalM: 0.4,
      baseLongitudinalM: 400,
      desnivelTransversalM: 0,
      baseTransversalM: 1,
      rugosidadeN: 0.04,
      vazaoUnitariaLsM: 0.2 / 0.06,
      irnMm: 56,
      k: numero(cenario['k']),
      a: numero(cenario['a']),
      vibMMin: numero(cenario['VIB_m_min']),
      numerico: BorderNumericConfig(
        nSegmentos: nSegmentos ?? BorderProject.nSegmentosPadrao,
      ),
    );

List<BorderProfilePoint> perfilConstante(double z, {double l = 100}) => [
  for (var i = 0; i <= 10; i++)
    BorderProfilePoint(l * i / 10, 0, 0, 0, z),
];

void main() {
  const solver = BorderHydraulics();
  final referencia = lerJson('resultados_referencia.json');
  final tolerancias = Map<String, dynamic>.from(
    referencia['tolerancias_comparacao_sugeridas'] as Map,
  );
  final tolTempos = numero(tolerancias['tempos_min']);
  final tolLaminas = numero(tolerancias['laminas_m']);
  final tolEficiencias = numero(tolerancias['eficiencias_pontos_percentuais']);
  final cenarios =
      (referencia['cenarios'] as List).cast<Map<String, dynamic>>();

  group('Etapa 7 · regressão dourada §8.4', () {
    for (final cenario in cenarios) {
      final nome = cenario['nome'] as String;
      final esperado = Map<String, dynamic>.from(
        cenario['resultados'] as Map,
      );

      test('$nome reproduz resultados_referencia.json', () {
        final projeto = cenarioProjeto(cenario);
        expect(projeto.nSegmentos, BorderProject.nSegmentosPadrao);
        final r = solver.dimensionar(projeto);
        expect(r.perfil.length, projeto.nSegmentos + 1);

        expect(r.t0Min, closeTo(numero(esperado['t0']), tolTempos));
        expect(r.y0M, closeTo(numero(esperado['y0']), tolLaminas));
        // Adimensionais r e σz: tolerância própria mais estrita que a de
        // lâmina do pacote, sem relaxamento em relação à referência.
        expect(r.r, closeTo(numero(esperado['r']), 1e-9));
        expect(r.sigmaZ, closeTo(numero(esperado['sigma_z']), 1e-9));
        expect(r.taMetadeMin, closeTo(numero(esperado['ta_meio']), tolTempos));
        expect(r.taFinalMin, closeTo(numero(esperado['ta']), tolTempos));
        expect(r.tdMin, closeTo(numero(esperado['td']), tolTempos));
        expect(r.trFinalMin, closeTo(numero(esperado['tr']), tolTempos));
        expect(r.tiMin, closeTo(numero(esperado['ti']), tolTempos));
        expect(r.qfM3MinM, closeTo(numero(esperado['qf']), tolLaminas));

        expect(
          r.volumeEntradaM3M,
          closeTo(numero(esperado['volume_aplicado_unitario']), tolLaminas),
        );
        expect(
          r.volumeUtilM3M + r.volumePercoladoM3M,
          closeTo(numero(esperado['volume_infiltrado_unitario']), tolLaminas),
        );
        expect(
          r.volumeUtilM3M,
          closeTo(numero(esperado['volume_util_unitario']), tolLaminas),
        );
        expect(
          r.volumePercoladoM3M,
          closeTo(numero(esperado['volume_percolado_unitario']), tolLaminas),
        );
        expect(
          r.volumeEscoadoM3M,
          closeTo(numero(esperado['volume_escoado_unitario']), tolLaminas),
        );

        expect(r.ea, closeTo(numero(esperado['Ea']), tolEficiencias));
        expect(r.er, closeTo(numero(esperado['Er']), tolEficiencias));
        expect(r.pp, closeTo(numero(esperado['Pp']), tolEficiencias));
        expect(r.pe, closeTo(numero(esperado['Pe']), tolEficiencias));

        // Identidades: Vinfiltrado = Vutil + Vpercolado e
        // IRN·L = Vutil + Vdeficit; sem déficit, Ea = Er = 100 − Pp − Pe.
        expect(r.ea + r.pp + r.pe, closeTo(100, tolEficiencias));
        expect(
          r.volumeUtilM3M + r.volumeDeficitM3M,
          closeTo(numero(projeto.irnEfetivaMm) / 1000 * 400, tolLaminas),
        );
      });

      test('$nome confere perfil com perfil_$nome.csv', () {
        final r = solver.dimensionar(cenarioProjeto(cenario));
        final linhas =
            File('$pacote/perfil_$nome.csv')
                .readAsLinesSync()
                .skip(1)
                .where((linha) => linha.trim().isNotEmpty)
                .toList();
        expect(r.perfil.length, linhas.length);
        var xMax = 0.0, avancoMax = 0.0, recessaoMax = 0.0;
        var oportunidadeMax = 0.0, infiltracaoMax = 0.0;
        for (var i = 0; i < linhas.length; i++) {
          final campos = linhas[i].split(',').map(double.parse).toList();
          final ponto = r.perfil[i];
          xMax = math.max(xMax, (ponto.xM - campos[0]).abs());
          avancoMax = math.max(avancoMax, (ponto.avancoMin - campos[1]).abs());
          recessaoMax = math.max(recessaoMax, (ponto.recessaoMin - campos[2]).abs());
          oportunidadeMax = math.max(
            oportunidadeMax,
            (ponto.oportunidadeMin - campos[3]).abs(),
          );
          infiltracaoMax = math.max(
            infiltracaoMax,
            (ponto.infiltracaoM - campos[4]).abs(),
          );
        }
        expect(xMax, lessThan(1e-9), reason: 'x do perfil $nome');
        expect(avancoMax, lessThan(tolTempos), reason: 'avanço $nome');
        expect(recessaoMax, lessThan(tolTempos), reason: 'recessão $nome');
        expect(oportunidadeMax, lessThan(tolTempos), reason: 'τ $nome');
        expect(infiltracaoMax, lessThan(tolLaminas), reason: 'I(x) $nome');
      });
    }

    test('refinamento de quadratura |Pe(1000)−Pe(2000)| < 1e-4', () {
      final cenario = cenarios.first;
      final grosso = solver.dimensionar(
        cenarioProjeto(cenario, nSegmentos: 1000),
      );
      final fino = solver.dimensionar(
        cenarioProjeto(cenario, nSegmentos: 2000),
      );
      expect((grosso.pe - fino.pe).abs(), lessThan(1e-4));
      expect(grosso.perfil.length, 1001);
      expect(fino.perfil.length, 2001);
    });
  });

  group('Etapa 7 · casos artificiais §8.5', () {
    test('perfil constante I=IRN → Ea=Er=100%, Pp=Pe=0', () {
      final v = BorderHydraulics.integrarPerfil(perfilConstante(0.05), 0.05);
      expect(v.utilM3M, closeTo(5, 1e-12));
      expect(v.percoladoM3M, closeTo(0, 1e-12));
      expect(v.deficitM3M, closeTo(0, 1e-12));
      const entrada = 5.0;
      expect(100 * v.utilM3M / entrada, closeTo(100, 1e-9));
      expect(100 * v.utilM3M / 5, closeTo(100, 1e-9));
      expect(100 * v.percoladoM3M / entrada, closeTo(0, 1e-9));
      expect(100 * (entrada - v.utilM3M - v.percoladoM3M) / entrada, closeTo(0, 1e-9));
    });

    test('perfil constante I=0,06 → Ea=62,5 Er=100 Pp=12,5 Pe=25', () {
      final v = BorderHydraulics.integrarPerfil(perfilConstante(0.06), 0.05);
      const entrada = 8.0;
      expect(v.utilM3M, closeTo(5, 1e-12));
      expect(v.percoladoM3M, closeTo(1, 1e-12));
      expect(v.deficitM3M, closeTo(0, 1e-12));
      final escoado = entrada - v.utilM3M - v.percoladoM3M;
      expect(escoado, closeTo(2, 1e-12));
      expect(100 * v.utilM3M / entrada, closeTo(62.5, 1e-9));
      expect(100 * v.utilM3M / 5, closeTo(100, 1e-9));
      expect(100 * v.percoladoM3M / entrada, closeTo(12.5, 1e-9));
      expect(100 * escoado / entrada, closeTo(25, 1e-9));
    });

    test('perfil constante I=0,03 → Ea=Er=60 Pp=0 Pe=40', () {
      final v = BorderHydraulics.integrarPerfil(perfilConstante(0.03), 0.05);
      const entrada = 5.0;
      expect(v.utilM3M, closeTo(3, 1e-12));
      expect(v.percoladoM3M, closeTo(0, 1e-12));
      expect(v.deficitM3M, closeTo(2, 1e-12));
      final escoado = entrada - v.utilM3M - v.percoladoM3M;
      expect(100 * v.utilM3M / entrada, closeTo(60, 1e-9));
      expect(100 * v.utilM3M / 5, closeTo(60, 1e-9));
      expect(100 * v.percoladoM3M / entrada, closeTo(0, 1e-9));
      expect(100 * escoado / entrada, closeTo(40, 1e-9));
      expect(v.utilM3M + v.deficitM3M, closeTo(0.05 * 100, 1e-12));
    });

    test('perfil linear [0,04;0,06;0,08] → Vi=6 com identidades', () {
      final perfil = [
        const BorderProfilePoint(0, 0, 0, 0, 0.04),
        const BorderProfilePoint(50, 0, 0, 0, 0.06),
        const BorderProfilePoint(100, 0, 0, 0, 0.08),
      ];
      final v = BorderHydraulics.integrarPerfil(perfil, 0.05);
      expect(v.utilM3M + v.percoladoM3M, closeTo(6, 1e-12));
      expect(v.utilM3M + v.deficitM3M, closeTo(5, 1e-12));
    });

    test('VIB=0 ainda tem oportunidade (§8.5)', () {
      final esperado = math.pow(0.056 / 0.0035, 1 / 0.47).toDouble();
      expect(
        solver.oportunidade(0.056, 0.0035, 0.47, 0),
        closeTo(esperado, 1e-7),
      );
      expect(
        BorderHydraulics.infiltracao(esperado, 0.0035, 0.47, 0),
        closeTo(0.056, 1e-9),
      );
    });

    test('depleção ajustada para t0 com q=0,4 m³/min/m (§8.5)', () {
      final r = solver.dimensionar(
        cenarioProjeto(cenarios.first).copyWith(
          vazaoUnitariaLsM: 0.4 / 0.06,
        ),
      );
      expect(r.tdMin, closeTo(r.t0Min, 1e-6));
      expect(r.perfil.first.infiltracaoM, closeTo(0.056, 1e-8));
      expect(
        r.perfil.map((p) => p.infiltracaoM).reduce(math.min),
        greaterThanOrEqualTo(0.056 - 1e-10),
      );
      expect(r.tiMin, greaterThanOrEqualTo(r.taFinalMin));
      expect(r.ea + r.pp + r.pe, closeTo(100, 1e-4));
    });

    test('I(100 min) e conversão 0,05 L/s/m → 0,003 m³/min/m (§8.3)', () {
      expect(
        BorderHydraulics.infiltracao(100, .0035, .47, .00011),
        closeTo(0.04148372564846282, 1e-12),
      );
      expect(
        BorderHydraulics.infiltracao(100, .0034, .45, .00010),
        closeTo(0.03700715998062557, 1e-12),
      );
      expect(BorderHydraulics.paraM3MinM(0.05), closeTo(0.003, 1e-15));
      expect(BorderHydraulics.paraM3MinM(10 / 3), closeTo(0.2, 1e-15));
      // Identidade IRN·L = Vutil + Vdeficit no cenário de referência.
      final r = solver.dimensionar(cenarioProjeto(cenarios.first));
      expect(
        r.volumeUtilM3M + r.volumeDeficitM3M,
        closeTo(0.056 * 400, tolLaminas),
      );
    });
  });

  group('Etapa 7 · matriz de domínio inválido §8.5', () {
    final base = cenarioProjeto(cenarios.first);

    test('IRN ≤ 0, entradas não positivas e dados não finitos', () {
      expect(
        () => solver.oportunidade(0, .0035, .47, .00011),
        throwsFormatException,
      );
      expect(
        () => solver.oportunidade(-.01, .0035, .47, .00011),
        throwsFormatException,
      );
      expect(
        () => solver.oportunidade(double.nan, .0035, .47, .00011),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(irnMm: 0)),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(comprimentoM: 0)),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(vazaoUnitariaLsM: 0)),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(rugosidadeN: 0)),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(k: double.nan)),
        throwsFormatException,
      );
      expect(
        () => solver.dimensionar(base.copyWith(a: double.infinity)),
        throwsFormatException,
      );
    });

    test('S0 = 0 bloqueia o ramo de declive', () {
      expect(
        () => solver.dimensionar(base.copyWith(desnivelLongitudinalM: 0)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('declive longitudinal positivo'),
          ),
        ),
      );
    });

    test('qf ≤ 0 rejeita o modelo de recessão', () {
      expect(
        () => solver.dimensionar(base.copyWith(vazaoUnitariaLsM: 0.05 / 0.06)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('qf'),
          ),
        ),
      );
    });

    test('corte com ti ≤ 0 ou ti < ta é fora do domínio', () {
      // Rugosidade maior alonga a depleção e o corte cai antes do fim do
      // avanço, sem que qf ou td ≤ ta dispare antes.
      expect(
        () => solver.dimensionar(base.copyWith(rugosidadeN: 0.1)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('Corte anterior'),
          ),
        ),
      );
    });

    test('td ≤ ta rejeita a depleção', () {
      expect(
        () => solver.dimensionar(
          base.copyWith(rugosidadeN: 0.2, comprimentoM: 800,
              desnivelLongitudinalM: 0.8),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('td ≤ ta'),
          ),
        ),
      );
    });

    test('τ < 0 é rejeitada sem módulo', () {
      expect(
        () => BorderHydraulics.montarPerfil(
          comprimentoM: 400,
          taFinalMin: 500,
          r: 0.7,
          tdMin: 10,
          trFinalMin: 20,
          segmentos: 10,
          k: .0035,
          a: .47,
          vib: .00011,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('Oportunidade local negativa'),
          ),
        ),
      );
    });

    test('contagens fracionárias e n_segmentos < 2', () {
      expect(
        () => solver.dimensionar(
          base.copyWith(numerico: const BorderNumericConfig(nSegmentos: 1)),
        ),
        throwsFormatException,
      );
      expect(
        () => BorderProject.fromMap(const {'nSegmentos': 2000.5}),
        throwsFormatException,
      );
      expect(
        () => BorderProject.fromMap(const {'faixasSimultaneas': 12.5}),
        throwsFormatException,
      );
      expect(
        () => BorderProject.fromMap(const {'periodoDias': 7.5}),
        throwsFormatException,
      );
    });
  });
}
