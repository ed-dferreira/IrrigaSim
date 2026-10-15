// Agronomia da bacia (Fase 6 do plano de cultura/clima): paridade de IRN com
// LaminaRequeridaCalculator (mesmos casos de faixas), derivação de ETc/IRN
// pelo método escolhido, precedência informada > calculada (G14) e carga de
// cenários v1 sem fabricar dado ausente (G4).
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/comum/clima_demanda.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/inundacao/basin_agronomy.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/services/simulation/lamina_requerida.dart';

/// Casos de referência (idênticos aos de faixas/sulcos).
const _casos = <({Map<String, double> insumos, double etc, double pef})>[
  (
    insumos: {
      'uccPercentual': 30,
      'upmpPercentual': 15,
      'densidadeGcm3': 1.4,
      'profundidadeRaizesCm': 40,
      'fracaoDisponivel': .5,
    },
    etc: 7.2,
    pef: 0,
  ),
  (
    insumos: {
      'uccPercentual': 30.5,
      'upmpPercentual': 18,
      'densidadeGcm3': 1.12,
      'profundidadeRaizesCm': 50,
      'fracaoDisponivel': 0.6,
    },
    etc: 7,
    pef: 3,
  ),
  (
    insumos: {
      'uccPercentual': 30,
      'upmpPercentual': 20,
      'densidadeGcm3': 1.4,
      'profundidadeRaizesCm': 50,
      'fracaoDisponivel': 0.8,
    },
    etc: 8,
    pef: 0,
  ),
];

BasinAgronomy _agronomia(Map<String, double> insumos, {String? cultura}) =>
    BasinAgronomy(
      cultura: cultura,
      kc: insumos['kc'],
      uccPercentual: insumos['uccPercentual'],
      upmpPercentual: insumos['upmpPercentual'],
      densidadeGcm3: insumos['densidadeGcm3'],
      profundidadeRaizesCm: insumos['profundidadeRaizesCm'],
      fracaoDisponivel: insumos['fracaoDisponivel'],
    );

void main() {
  group('paridade com LaminaRequeridaCalculator', () {
    for (final caso in _casos) {
      test('IRN ${caso.insumos} igual à calculadora', () {
        final esperado = LaminaRequeridaCalculator.calcular(
          uccPercentual: caso.insumos['uccPercentual']!,
          upmpPercentual: caso.insumos['upmpPercentual']!,
          densidadeGcm3: caso.insumos['densidadeGcm3']!,
          profundidadeRaizesCm: caso.insumos['profundidadeRaizesCm']!,
          fracaoAguaDisponivel: caso.insumos['fracaoDisponivel']!,
          demandaLiquidaMmDia: caso.etc - caso.pef,
          etcMmDia: caso.etc,
          precipitacaoEfetivaMmDia: caso.pef,
        ).irnMm;
        final obtido = _agronomia(caso.insumos)
            .irnMm(etcMmDia: caso.etc, precipitacaoEfetivaMmDia: caso.pef);
        expect(obtido, closeTo(esperado, 1e-9));
      });
    }

    test('UCC = UPMP não calcula IRN (ArgumentError vira null)', () {
      final agronomia = const BasinAgronomy(
        uccPercentual: 15,
        upmpPercentual: 15,
        densidadeGcm3: 1.4,
        profundidadeRaizesCm: 40,
        fracaoDisponivel: .5,
      );
      expect(agronomia.irnMm(etcMmDia: 4, precipitacaoEfetivaMmDia: 0), isNull);
    });

    test('insumo ausente deixa a IRN pendente, nunca zera (G4)', () {
      final incompleta = const BasinAgronomy(
        uccPercentual: 30,
        upmpPercentual: 15,
        densidadeGcm3: 1.4,
      );
      expect(incompleta.completa, isFalse);
      expect(
        incompleta.irnMm(etcMmDia: 7, precipitacaoEfetivaMmDia: 0),
        isNull,
      );
    });

    test('demanda líquida não positiva não calcula IRN', () {
      final agronomia = _agronomia(_casos.last.insumos);
      expect(agronomia.irnMm(etcMmDia: 8, precipitacaoEfetivaMmDia: 8), isNull);
      expect(agronomia.irnMm(etcMmDia: 8, precipitacaoEfetivaMmDia: 9), isNull);
    });
  });

  group('derivações do projeto (método ETc e origem da IRN)', () {
    test('preset Aula 8: IRN informada 56 mm, ETc 8 e TR 7 dias (G16)', () {
      final p = BasinProject.exemploAula8Intermitente();
      expect(p.metodoEtc, MetodoEtc.adotada);
      expect(p.origemIrn, OrigemIrnBasin.informada);
      expect(p.origemChuva, OrigemChuva.efetiva);
      expect(p.etcMmDia, 8);
      expect(p.irnCalculadaMm, closeTo(56, 1e-9));
      expect(p.irnEfetivaMm, 56);
      expect(p.turnoRegaIrnDias, closeTo(7, 1e-9));
      expect(p.impedimento, isNull);
    });

    test('IRN informada prevalece; a calculada continua auditável (G14)', () {
      final base = BasinProject.exemploAula8Intermitente().copyWith(
        laminaRequeridaMm: 50,
      );
      expect(base.irnEfetivaMm, 50);
      expect(base.irnCalculadaMm, closeTo(56, 1e-9));
      expect(base.laminaMediaPlanaltoM, closeTo(0.05, 1e-12));
      expect(base.toCompatParameters().laminaRequerida, 50);

      final calculada = base.copyWith(origemIrn: OrigemIrnBasin.calculada);
      expect(calculada.irnEfetivaMm, closeTo(56, 1e-9));
      expect(calculada.toCompatParameters().laminaRequerida, closeTo(56, 1e-9));
    });

    test('IRN calculada sem insumos fica pendente e bloqueia (G14)', () {
      final projeto = BasinProject.exemploAula8Intermitente().copyWith(
        origemIrn: OrigemIrnBasin.calculada,
        agronomia: const BasinAgronomy(),
      );
      expect(projeto.irnEfetivaMm, isNull);
      expect(projeto.impedimento?.status, BorderStatus.entradaInvalida);
      expect(projeto.impedimentoModelo, contains('IRN calculada'));
    });

    test('chuva provável não abate a demanda (origem da chuva)', () {
      final projeto = BasinProject.exemploAula8Intermitente().copyWith(
        origemChuva: OrigemChuva.provavel,
      );
      expect(projeto.precipitacaoEfetivaMmDia, 0);
      expect(projeto.precipitacaoEfetivaEfetivaMmDia, 0);
      final comChuva = projeto.copyWith(precipitacaoEfetivaMmDia: 3);
      expect(comChuva.precipitacaoEfetivaEfetivaMmDia, 0);
      expect(
        comChuva.turnoRegaIrnDias,
        closeTo(56 / 8, 1e-9),
        reason: 'chuva provável registrada não vira crédito de Pef',
      );
    });

    test('ETo×Kc e Blaney–Criddle derivam ETc pela agronomia', () {
      final base = BasinProject.exemploAula8Intermitente().copyWith(
        agronomia: BasinAgronomy(
          cultura: 'Milho',
          kc: 1.2,
          uccPercentual: 30,
          upmpPercentual: 15,
          densidadeGcm3: 1.4,
          profundidadeRaizesCm: 40,
          fracaoDisponivel: .5,
        ),
        etoMmDia: 6,
      );
      expect(
        base.copyWith(metodoEtc: MetodoEtc.etoVezesKc).etcMmDia,
        closeTo(7.2, 1e-9),
      );

      final blaney = base.copyWith(
        metodoEtc: MetodoEtc.blaneyCriddle,
        temperaturaMediaC: 22,
        latitudeGraus: -30,
        mesReferencia: 10,
      );
      expect(blaney.etoBlaneyCriddleMmDia, isNotNull);
      expect(
        blaney.etcMmDia,
        closeTo(blaney.etoBlaneyCriddleMmDia! * 1.2, 1e-9),
      );

      final semInsumo = base.copyWith(
        metodoEtc: MetodoEtc.blaneyCriddle,
        temperaturaMediaC: null,
      );
      expect(semInsumo.etcMmDia, isNull);
      expect(semInsumo.etoBlaneyCriddleMmDia, isNull);
    });
  });

  group('serialização v2 e carga de v1', () {
    test('roundtrip toMap/fromMap é identidade no v2', () {
      final p = BasinProject.exemploAula8Intermitente();
      final loaded = BasinProject.fromMap(p.toMap());
      expect(loaded.versao, 2);
      expect(loaded.agronomia?.toMap(), p.agronomia?.toMap());
      expect(loaded.metodoEtc, p.metodoEtc);
      expect(loaded.origemChuva, p.origemChuva);
      expect(loaded.origemIrn, p.origemIrn);
      expect(loaded.precipitacaoEfetivaMmDia, p.precipitacaoEfetivaMmDia);
      expect(loaded.toMap(), p.toMap());
    });

    test('mapa v1 sem as chaves novas carrega com defaults (G4)', () {
      final v1 = BasinProject.exemploAula8Intermitente().toMap()
        ..remove('agronomia')
        ..remove('metodo_etc')
        ..remove('origem_chuva')
        ..remove('origem_irn')
        ..remove('precipitacao_efetiva_mm_dia')
        ..['versao'] = 1;
      final loaded = BasinProject.fromMap(v1);
      expect(loaded.versao, 1);
      expect(loaded.agronomia, isNull);
      expect(loaded.metodoEtc, MetodoEtc.adotada);
      expect(loaded.origemChuva, OrigemChuva.naoInformada);
      expect(loaded.origemIrn, OrigemIrnBasin.informada);
      expect(loaded.precipitacaoEfetivaMmDia, isNull);
      expect(loaded.irnEfetivaMm, 56);
      expect(loaded.culturaEfetiva, loaded.cultura);
    });
  });
}
