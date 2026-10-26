// Regressão dourada da irrigação por inundação contra
// docs/Pacote_Inundacao. Fonte: Aula 8 — Irrigação por Inundação,
// Prof.ª Chaiane Guerra da Conceição, UNIPAMPA.
//
// Tolerações: resultados_referencia.json é comparado com tolerância 1e-5
// (não há chave de tolerâncias no pacote). A regra 2/3 da p. 20 é dourada
// exata: 15 cm → 10 cm; 0,25% → 40 m; 0,05% → 200 m.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/border_result.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_math.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_tables.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/rice_volumes_service.dart';

const pacote = 'docs/Pacote_Inundacao';
const tolerancia = 1e-5;

Map<String, dynamic> lerJson(String nome) =>
    jsonDecode(File('$pacote/$nome').readAsStringSync())
        as Map<String, dynamic>;

double numero(Object? valor) => (valor as num).toDouble();

Infiltracao solo(Map<String, dynamic> curva) => Infiltracao(
  numero(curva['k']),
  numero(curva['a']),
  numero(curva['vib_m_min']),
);

void perto(
  String nome,
  double atual,
  double esperado, [
  double tol = tolerancia,
]) {
  expect(atual.isFinite, isTrue, reason: '$nome não é finito');
  expect(atual, closeTo(esperado, tol), reason: nome);
}

void rejeita(String nome, void Function() acao) {
  expect(
    acao,
    throwsA(anyOf(isA<ArgumentError>(), isA<StateError>())),
    reason: '$nome deveria ser rejeitado',
  );
}

void main() {
  final pacoteJson = lerJson('resultados_referencia.json');
  final resultados = Map<String, dynamic>.from(pacoteJson['resultados'] as Map);
  final dados = lerJson('dados_extraidos.json');
  final intermitente = Map<String, dynamic>.from(dados['intermitente'] as Map);

  group(
    'golden · dimensionamento intermitente (resultados_referencia.json)',
    () {
      for (final nome in ['primeira', 'terceira']) {
        test('$nome reproduz q0, r, y0, ta, ti e Ea (tol 1e-5)', () {
          final esperado = Map<String, dynamic>.from(resultados[nome] as Map);
          final curva = Map<String, dynamic>.from(intermitente[nome] as Map);
          final d = dimensionar(
            solo(curva),
            l: numero(intermitente['comprimento_m']),
            n: numero(intermitente['manning_n']),
            irn: numero(intermitente['irn_mm']) / 1000,
            vmax: numero(intermitente['vmax_m_min']),
          );
          perto('$nome q0', d.q0M3MinM, numero(esperado['q0_m3_min_m']));
          perto('$nome r', d.r, numero(esperado['r']));
          perto('$nome y0', d.y0M, numero(esperado['y0_m']));
          perto('$nome ta', d.taMin, numero(esperado['ta_min']));
          perto('$nome ti', d.tiMin, numero(esperado['ti_min']));
          perto(
            '$nome Ea',
            d.eficienciaPercent,
            numero(esperado['eficiencia_percent']),
          );
        });
      }

      test('Q0 = Q0max e corte mínimo ti = ta no exemplo da aula', () {
        final d = dimensionar(
          solo(Map<String, dynamic>.from(intermitente['primeira'] as Map)),
          l: 200,
          n: 0.04,
          irn: 0.056,
          vmax: 8,
        );
        perto('Q0max (p. 54)', vazaoMaxima(8, 0.04, 200), d.q0M3MinM);
        expect(d.tiMin, d.taMin);
        // S0 = y0/X auditável (G10) e resíduo do balanço < 1e-7 m³/m.
        perto('S0 = y0/L', d.s0, d.y0M / 200);
        expect(d.residualBalancoM3M, lessThan(1e-7));
      });

      test('contínua p. 73 reproduz Qe e Qm (fator 0,116)', () {
        final esperado = Map<String, dynamic>.from(
          resultados['continua_slide_73'] as Map,
        );
        final c = Map<String, dynamic>.from(dados['continua'] as Map);
        final tr = turnoRega(
          numero(c['dta_mm_cm']),
          numero(c['f']),
          numero(c['z_cm']),
          numero(c['et_mm_dia']),
        );
        final fluxos = continua(
          porosidade: numero(c['porosidade']),
          zMm: numero(c['z_cm']) * 10,
          laminaMm: numero(c['lamina_mm']),
          etMmDia: numero(c['et_mm_dia']),
          kMmDia: numero(c['k0_mm_dia']),
          areaHa: numero(c['area_ha']),
          turnoDias: tr,
        );
        perto('Qe L/s', fluxos.qeLS, numero(esperado['qe_l_s']));
        perto('Qm L/s', fluxos.qmLS, numero(esperado['qm_l_s']));
      });
    },
  );

  group('golden · arroz p. 84 (solução parcial, lacunas preservadas)', () {
    final esperado = Map<String, dynamic>.from(
      pacoteJson['arroz_pagina_84_parcial'] as Map,
    );
    final arroz = Map<String, dynamic>.from(dados['arroz'] as Map);
    final service = const RiceVolumesService();

    test('porosidade PT e umidade de saturação Us', () {
      final r = service.solucaoPagina84();
      perto('PT', r.pt, numero(esperado['porosidade']), 1e-9);
      perto('Us', r.us, numero(esperado['us_gravimetrica']), 1e-9);
      perto(
        'PT = 1 − Ds/Dp',
        r.pt,
        1 - numero(arroz['ds_g_cm3']) / numero(arroz['dp_g_cm3']),
        1e-12,
      );
    });

    test('V1 = 3169,811321 − 7500·Ua (coeficientes dourados)', () {
      const ua = 0.1;
      final r = service.solucaoPagina84(uaGravimetrica: ua);
      final coef = numero(esperado['v1_coeficiente_ua_gravimetrica']);
      final constante = numero(esperado['v1_constante_m3_ha']);
      expect(coef, -7500);
      perto('constante de V1', r.v1M3Ha! - coef * ua, constante, 1e-6);
      final v1Esperado = constante + coef * ua;
      perto('V1(Ua=0,1)', r.v1M3Ha!, v1Esperado, 1e-6);
    });

    test('V2, V3 e V4 independentes de Ua', () {
      final r = service.solucaoPagina84();
      perto('V2', r.v2M3Ha, numero(esperado['v2_m3_ha']), 1e-9);
      perto('V3', r.v3M3Ha, numero(esperado['v3_m3_ha']), 1e-9);
      perto('V4', r.v4M3Ha, numero(esperado['v4_m3_ha']), 1e-9);
    });

    test('MS e V5 proporcionais à massa do saco', () {
      const massa = 60.0;
      final r = service.solucaoPagina84(uaGravimetrica: 0, massaSacoKg: massa);
      perto(
        'MS = 947,43 · massa',
        r.materiaSecaTotalKgHa!,
        numero(esperado['ms_total_coef_massa_saco']) * massa,
        1e-6,
      );
      perto(
        'V5 = 378,972 · massa',
        r.v5M3Ha!,
        numero(esperado['v5_coef_massa_saco']) * massa,
        1e-6,
      );
    });

    test('lacunas da p. 84 viram null e constam em dadosAusentes (G4)', () {
      final r = service.solucaoPagina84();
      expect(r.v1M3Ha, isNull);
      expect(r.v5M3Ha, isNull);
      expect(r.vtM3Ha, isNull);
      expect(r.materiaSecaTotalKgHa, isNull);
      expect(r.q1M3S, isNull);
      expect(r.q2M3S, isNull);
      expect(r.dadosAusentes, isNotEmpty);
      expect(
        r.dadosAusentes.join(' '),
        allOf(contains('Ua'), contains('massa do saco'), contains('Q1')),
      );
      // Q1/Q2 aparecem assim que área e tempos são informados (G4).
      final completo = service.solucaoPagina84(
        uaGravimetrica: 0.2,
        massaSacoKg: 60,
        areaHa: 1,
        tdDias: 10,
        trDias: 10,
      );
      expect(completo.q1M3S, isNotNull);
      expect(completo.q2M3S, isNotNull);
      expect(completo.vtM3Ha, isNotNull);
    });
  });

  group('golden · perfis CSV (parser de 3 colunas)', () {
    for (final arquivo in ['perfil_primeira', 'perfil_terceira']) {
      test(
        '$arquivo: tx = ta (x/L)^(1/r) e lâmina I(ta−tx)+0,8 y0+Q0(ti−ta)/L',
        () {
          final curvaNome = arquivo == 'perfil_primeira'
              ? 'primeira'
              : 'terceira';
          final curva = Map<String, dynamic>.from(
            intermitente[curvaNome] as Map,
          );
          final d = dimensionar(
            solo(curva),
            l: 200,
            n: 0.04,
            irn: 0.056,
            vmax: 8,
          );
          final infil = solo(curva);
          final linhas = File('$pacote/$arquivo.csv')
              .readAsLinesSync()
              .skip(1)
              .where((linha) => linha.trim().isNotEmpty)
              .toList();
          expect(linhas.length, 41, reason: 'grade de 5 m em L = 200 m (G7)');
          final laminaEntrada = infiltracaoInicio(
            infil,
            d.taMin,
            d.tiMin,
            d.y0M,
            d.q0M3MinM,
            200,
          );
          for (final linha in linhas) {
            final campos = linha.split(',');
            expect(campos.length, 3, reason: 'parser de 3 colunas');
            final x = double.parse(campos[0]);
            final tx = double.parse(campos[1]);
            final laminaMm = double.parse(campos[2]);
            final txEsperado = d.taMin * math.pow(x / 200, 1 / d.r).toDouble();
            final laminaEsperadaM =
                laminaEntrada -
                infil.acumulada(d.taMin) +
                infil.acumulada(d.taMin - txEsperado);
            perto('tx em x=$x', tx, txEsperado, 1e-6);
            perto('lâmina em x=$x', laminaMm, laminaEsperadaM * 1000, 1e-6);
          }
        },
      );
    }

    test('x = 0 coincide com infiltracaoInicio (p. 47)', () {
      final linha = File('$pacote/perfil_primeira.csv')
          .readAsLinesSync()[1]
          .split(',');
      expect(double.parse(linha[0]), 0);
      expect(double.parse(linha[1]), 0);
      final curva = Map<String, dynamic>.from(intermitente['primeira'] as Map);
      final infil = solo(curva);
      final d = dimensionar(infil, l: 200, n: 0.04, irn: 0.056, vmax: 8);
      final i0 = infiltracaoInicio(
        infil,
        d.taMin,
        d.tiMin,
        d.y0M,
        d.q0M3MinM,
        200,
      );
      perto('I0 (mm)', double.parse(linha[2]), i0 * 1000, 1e-6);
      expect(i0, greaterThan(0.8 * d.y0M), reason: 'I(ta) + 0,8·y0 (p. 47)');
    });
  });

  group('golden · porte integral de testar_referencia.dart', () {
    final primeira = Infiltracao(0.0035, 0.47, 0.00011);

    test('infiltração acumulada', () {
      perto('t=0', primeira.acumulada(0), 0, 1e-15);
      perto('t=1', primeira.acumulada(1), 0.00361, 1e-12);
    });

    test('dimensionamento, eficiência e corte mínimo', () {
      final p = dimensionar(primeira);
      final t = dimensionar(Infiltracao(0.0034, 0.45, 0.00010));
      perto('Q0 máximo', p.q0M3MinM, 0.8728887470978953, 1e-12);
      perto('avanço primeira', p.taMin, 22.029325408391216);
      perto('avanço terceira', t.taMin, 21.795724239885672);
      perto('Ea primeira', p.eficienciaPercent, 58.24490344811151);
      perto('Ea terceira', t.eficienciaPercent, 58.869157882385934);
      perto('corte mínimo no avanço', p.tiMin, p.taMin, 1e-12);
    });

    test('contínua e turno de rega', () {
      final c = continua(
        porosidade: 0.5,
        zMm: 500,
        laminaMm: 150,
        etMmDia: 7.2,
        kMmDia: 7,
        areaHa: 20,
        turnoDias: 2 * 0.5 * 50 / 7.2,
      );
      perto('enchimento L/s', c.qeLS, 166.576);
      perto('manutenção L/s', c.qmLS, 32.944);
      perto('TR com Z em cm', turnoRega(2, 0.5, 50, 7.2), 6.944444444444445);
    });

    test('volumes do arroz sintéticos (unidades, não o enunciado)', () {
      final v = volumesArroz(
        ds: 1,
        dp: 2,
        ua: 0.5,
        pci: 0.5,
        h: 0.1,
        evaporacaoDia: 0.01,
        ksatDia: 0.001,
        periodoDias: 10,
        materiaSecaKgHa: 1000,
      );
      perto('solo já saturado', v.v1M3Ha, 0, 1e-9);
      perto('formação', v.v2M3Ha, 1000, 1e-9);
      perto('evaporação', v.v3M3Ha, 1000, 1e-9);
      perto('infiltração', v.v4M3Ha, 120, 1e-9);
      perto('matéria seca', v.v5M3Ha, 400, 1e-9);
      perto('volume total', v.vtM3Ha, 2520, 1e-9);
      perto('m³/s', vazaoVolume(86400, 1, 1), 1, 1e-12);
      perto(
        'matéria seca total',
        materiaSecaTotal(10, 50, 0.2, 0.4),
        1000,
        1e-9,
      );
    });

    test('fórmulas auxiliares das páginas 16, 17, 45, 70 e 72', () {
      perto('Henderson (p. 17)', areaHenderson(100, 10), 1000, 1e-12);
      perto(
        'tabela solo argiloso (p. 16)',
        areaGuiaSolo('argiloso', 20),
        0.08,
        1e-12,
      );
      perto(
        'declividade da água (p. 45)',
        declividadeLiquida(0.1, 100),
        0.001,
        1e-15,
      );
      perto('eficiência condução (p. 70)', eficienciaRazao(80, 100), 80, 1e-12);
      perto(
        'lâmina aplicada mm (p. 72)',
        laminaAplicada(1, 1, 1000),
        3.6,
        1e-12,
      );
      perto(
        'infiltração no início (p. 47)',
        infiltracaoInicio(primeira, 20, 30, 0.1, 0.5, 200),
        primeira.acumulada(20) + 0.08 + 0.5 * 10 / 200,
        1e-12,
      );
    });

    test('Newton ≡ bisseção (<1e-5 min)', () {
      final p = dimensionar(primeira);
      final x = tempoNaDistancia(200, p.q0M3MinM, 0.04, primeira, p.r);
      final newton = tempoNaDistanciaNewton(
        200,
        p.q0M3MinM,
        0.04,
        primeira,
        p.r,
      );
      perto('Newton = bisseção', newton, x);
      expect((newton - x).abs(), lessThan(1e-5));
      // Independência do chute inicial: outro ponto da curva.
      final meio = tempoNaDistancia(100, p.q0M3MinM, 0.04, primeira, p.r);
      final newtonMeio = tempoNaDistanciaNewton(
        100,
        p.q0M3MinM,
        0.04,
        primeira,
        p.r,
      );
      perto('Newton no meio', newtonMeio, meio);
    });

    test('planejamento em parcelas (pp. 61–62)', () {
      final op = parcelas(
        areaTotalM2: 80000,
        comprimentoM: 200,
        tabuleirosPorParcela: 2,
        q0M3MinM: 0.5,
        tiMin: 30,
        mudancaMin: 10,
        jornadaMinDia: 480,
        periodoDias: 1,
      );
      perto('parcelas por dia', op.npdInteiro.toDouble(), 12, 1e-12);
      perto('tabuleiros totais', op.ntt.toDouble(), 24, 1e-12);
      perto('Q total L/s', op.qTotalLS, 277.77777777777777, 1e-9);
      perto('TPP = ti + tm', op.tppMin, 40, 1e-12);
      expect(diqueComporta(0.2, 0.1, 0.05), isTrue);
      expect(diqueComporta(0.12, 0.1, 0.05), isFalse);
    });

    test('matriz de rejeição do domínio', () {
      rejeita('tempo negativo', () => primeira.acumulada(-1));
      rejeita(
        'vazão insuficiente',
        () => tempoNaDistancia(200, 0.001, 0.04, primeira, 0.7),
      );
      rejeita('vazão erosiva', () => dimensionar(primeira, vazao: 2));
      rejeita('NaN', () => Infiltracao(double.nan, 0.47, 0.00011));
      rejeita('dias zero', () => vazaoVolume(1, 1, 0));
      rejeita('eficiência >100%', () => eficienciaRazao(101, 100));
      rejeita('a fora de (0,1)', () => Infiltracao(0.0035, 1, 0.00011));
      rejeita(
        'jornada insuficiente',
        () => parcelas(
          areaTotalM2: 100,
          comprimentoM: 10,
          tabuleirosPorParcela: 1,
          q0M3MinM: 0.1,
          tiMin: 60,
          mudancaMin: 0,
          jornadaMinDia: 30,
          periodoDias: 1,
        ),
      );
      rejeita(
        'Ua acima da saturação',
        () => volumesArroz(
          ds: 1,
          dp: 2,
          ua: 5,
          pci: 0.5,
          h: 0.1,
          evaporacaoDia: 0,
          ksatDia: 0,
          periodoDias: 1,
          materiaSecaKgHa: 0,
        ),
      );
      rejeita('texto de solo ausente', () => areaGuiaSolo('vulcânico', 10));
    });
  });

  group('golden · regra 2/3 do desnível admissível (p. 20, G1)', () {
    test('lâmina de 15 cm admite 10 cm de desnível', () {
      perto('2/3 de 15 cm', desnivelAdmissivel(0.15), 0.10, 1e-12);
      perto(
        'lâmina média (Li+Lf)/2',
        laminaMediaPlanalto(0.10, 0.20),
        0.15,
        1e-12,
      );
    });

    test('0,25% → 40 m e 0,05% → 200 m, por direção', () {
      perto('0,25%', comprimentoMaximoPorDesnivel(0.15, 0.0025), 40, 1e-9);
      perto('0,05%', comprimentoMaximoPorDesnivel(0.15, 0.0005), 200, 1e-9);
    });
  });

  group('golden · paridade das tabelas com dados_extraidos.json', () {
    test('guia da p. 16 completo (4 texturas, base 10 L/s)', () {
      final tabela = Map<String, dynamic>.from(
        dados['tabela_pagina_16'] as Map,
      );
      expect(
        BasinReferenceTables.guiaSolo.length,
        (tabela['area_ha'] as Map).length,
      );
      for (final row in BasinReferenceTables.guiaSolo) {
        expect(
          row.areaHaBase,
          closeTo(numero(tabela['area_ha'][row.chaveJson]), 1e-12),
          reason: row.chaveJson,
        );
        expect(row.status, BorderStatus.avisoOrientativo);
      }
      expect(numero(tabela['vazao_base_l_s']), BasinSoilGuideRow.vazaoBaseLs);
      expect(
        const BasinReferenceTables().areaSugerida('franco_argiloso', 20),
        closeTo(0.06, 1e-12),
      );
      expect(const BasinReferenceTables().guia('vulcânico'), isNull);
    });

    test('Henderson p. 17 preserva o fator 100', () {
      final henderson = Map<String, dynamic>.from(
        dados['henderson_pagina_17'] as Map,
      );
      expect(henderson['formula'], contains('100'));
      expect(BasinHendersonReference.formula, contains('100'));
      expect(BasinHendersonReference.area(1, 1), 100);
      expect(henderson['natureza'], contains('fator 100 preservado'));
      expect(BasinHendersonReference.natureza, contains('fator 100'));
      expect(BasinHendersonReference.pagina, 17);
    });

    test('Booher p. 38: 49 células, 2 suspeitas (Ø30/7,5 e Ø30/10)', () {
      final booher = Map<String, dynamic>.from(
        dados['tabela_booher_pagina_38'] as Map,
      );
      final diametros = (booher['diametro_cm'] as List).map(numero).toList();
      final cargas = (booher['carga_cm'] as List).map(numero).toList();
      final valores = (booher['vazao_l_s'] as List)
          .map((linha) => (linha as List).map(numero).toList())
          .toList();
      expect(diametros, BasinReferenceTables.diametrosCm);
      expect(cargas, BasinReferenceTables.cargasCm);
      final tabela = const BasinReferenceTables();
      var suspeitas = 0;
      for (var i = 0; i < diametros.length; i++) {
        for (var j = 0; j < cargas.length; j++) {
          final cell = tabela.booher(diametros[i], cargas[j])!;
          expect(
            cell.impressoLs,
            closeTo(valores[i][j], 1e-12),
            reason: 'Ø ${diametros[i]} × ${cargas[j]}',
          );
          final suspeita = cell.status == BorderStatus.dadoFonteSuspeito;
          if (suspeita) suspeitas++;
          expect(tabela.sugestao(diametros[i], cargas[j]) == null, suspeita);
        }
      }
      expect(suspeitas, 2);
      final listadas = (booher['celulas_suspeitas'] as List)
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
      expect(
        listadas
            .map((c) => (numero(c['diametro_cm']), numero(c['carga_cm'])))
            .toSet(),
        basinBooherCelulasSuspeitas.toSet(),
      );
      expect(tabela.booher(16, 10), isNull);
      expect(tabela.sugestao(15, 10), isNotNull);
      expect(BasinBooherCell.pagina, 38);
    });

    test('presets da Aula 8 (pp. 63, 73 e 84) batem com o JSON (G5)', () {
      final p = BasinReferenceTables.intermitenteAula8;
      final primeira = Map<String, dynamic>.from(
        intermitente['primeira'] as Map,
      );
      final terceira = Map<String, dynamic>.from(
        intermitente['terceira'] as Map,
      );
      expect(p.k, numero(primeira['k']));
      expect(p.a, numero(primeira['a']));
      expect(p.vibMMin, numero(primeira['vib_m_min']));
      expect(p.kTerceira, numero(terceira['k']));
      expect(p.aTerceira, numero(terceira['a']));
      expect(p.vibTerceiraMMin, numero(terceira['vib_m_min']));
      expect(p.comprimentoM, numero(intermitente['comprimento_m']));
      expect(p.larguraAreaM, numero(intermitente['largura_area_m']));
      expect(p.declividade, numero(intermitente['declividade']));
      expect(p.manningN, numero(intermitente['manning_n']));
      expect(p.rho1, numero(intermitente['rho1']));
      expect(p.rho2, numero(intermitente['rho2']));
      expect(p.irnMm, numero(intermitente['irn_mm']));
      expect(p.etMmDia, numero(intermitente['et_mm_dia']));
      expect(p.vmaxMMin, numero(intermitente['vmax_m_min']));
      expect(p.vazaoTotalLs, numero(intermitente['qt_l_s']));
      expect(
        p.intervaloDias,
        (intermitente['intervalo_disponibilidade_dias'] as num).toInt(),
      );

      final c = BasinReferenceTables.continuaAula8;
      final continuaJson = Map<String, dynamic>.from(dados['continua'] as Map);
      expect(c.areaHa, numero(continuaJson['area_ha']));
      expect(c.dtaMmCm, numero(continuaJson['dta_mm_cm']));
      expect(c.porosidade, numero(continuaJson['porosidade']));
      expect(c.zCm, numero(continuaJson['z_cm']));
      expect(c.k0MmDia, numero(continuaJson['k0_mm_dia']));
      expect(c.etMmDia, numero(continuaJson['et_mm_dia']));
      expect(c.laminaMm, numero(continuaJson['lamina_mm']));
      expect(c.f, numero(continuaJson['f']));
      expect(c.profundidadeCamadaMm, numero(continuaJson['z_cm']) * 10);

      final a = BasinReferenceTables.arrozAula8;
      final arroz = Map<String, dynamic>.from(dados['arroz'] as Map);
      expect(a.dsGcm3, numero(arroz['ds_g_cm3']));
      expect(a.dpGcm3, numero(arroz['dp_g_cm3']));
      expect(a.pciM, numero(arroz['pci_cm']) / 100);
      expect(a.alturaLaminaM, numero(arroz['h_cm']) / 100);
      expect(a.ksatMDia, numero(arroz['ksat_m_dia']));
      expect(a.evaporacaoMmDia, numero(arroz['evaporacao_tanque_mm_dia']));
      expect(a.periodoDias, numero(arroz['periodo_dias']));
      expect(a.produtividadeSacosHa, numero(arroz['produtividade_sacos_ha']));
      expect(a.umidadeGraos, numero(arroz['umidade_graos']));
      expect(a.indiceColheita, numero(arroz['indice_colheita']));
      // Dados faltantes preservados como null, nunca presumidos.
      expect(arroz['ua'], isNull);
      expect(arroz['massa_saco_kg'], isNull);
      expect(a.uaGravimetrica, isNull);
      expect(a.massaSacoKg, isNull);
      expect(a.areaHa, isNull);
      expect(a.tdDias, isNull);
      expect(a.trDias, isNull);

      expect(BasinPresetIntermitente.pagina, 63);
      expect(BasinPresetContinua.pagina, 73);
      expect(BasinPresetArroz.pagina, 84);
      expect((dados['observacoes'] as List).length, 7);
    });
  });
}
