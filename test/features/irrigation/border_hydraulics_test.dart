import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_numeric.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';

void main() {
  const solver = BorderHydraulics();
  test('oportunidade e vazão mínima do exemplo reconstruído', () {
    expect(
      solver.oportunidade(.056, .0035, .47, .00011),
      closeTo(161.71965439, .001),
    );
    expect(
      solver.oportunidade(.056, .0034, .45, .00010),
      closeTo(195.13612259, .001),
    );
    expect(
      BorderHydraulics.vazaoMinimaM3MinM(400, .001, .04) / .06,
      closeTo(1.8815552078, .00001),
    );
    expect(BorderHydraulics.hartLiteral(.001), closeTo(1.883197895, .00001));
    expect(
      BorderHydraulics.hartLiteral(.001, coberturaTotal: true),
      closeTo(3.76639579, .00001),
    );
  });

  test('primeira e terceira irrigação mantêm balanço e domínios separados', () {
    const base = BorderProject(
      comprimentoM: 400,
      larguraM: 10,
      desnivelLongitudinalM: .4,
      baseLongitudinalM: 400,
      desnivelTransversalM: 0,
      baseTransversalM: 10,
      rugosidadeN: .04,
      vazaoUnitariaLsM: 10 / 3,
      irnMm: 56,
      k: .0035,
      a: .47,
      vibMMin: .00011,
    );
    final first = solver.dimensionar(base);
    final third = solver.dimensionar(
      base.copyWith(k: .0034, a: .45, vibMMin: .00010),
    );
    expect(first.taFinalMin, closeTo(122.19072, .05));
    expect(third.taFinalMin, closeTo(112.15363, .05));
    expect(first.ea, closeTo(63.23364, .15));
    expect(third.ea, closeTo(58.23181, .15));
    for (final r in [first, third]) {
      expect(r.taMetadeMin, lessThan(r.taFinalMin));
      expect(r.tiMin, greaterThanOrEqualTo(r.taFinalMin));
      expect(r.ea + r.pp + r.pe, closeTo(100, .00001));
      expect(
        r.volumeEntradaTotalM3,
        closeTo(
          r.volumeUtilTotalM3 +
              r.volumePercoladoTotalM3 +
              r.volumeEscoadoTotalM3,
          .00001,
        ),
      );
      expect(r.residualAvancoM3M, lessThan(.00001));
    }
  });

  test('faixa em nível, fechada e dados inválidos não executam', () {
    expect(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(desnivelLongitudinalM: 0),
      ),
      throwsFormatException,
    );
    expect(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(
          jusante: CondicaoJusanteFaixa.fechada,
        ),
      ),
      throwsFormatException,
    );
    expect(
      () =>
          solver.dimensionar(BorderProject.ilustrativo.copyWith(a: double.nan)),
      throwsFormatException,
    );
  });

  test('exemplo ilustrativo inicial oferece candidato executável', () {
    final result = solver.dimensionar(BorderProject.ilustrativo);
    expect(result.ea, isPositive);
    // Sem altura do dique e sem hn a verificação geométrica fica pendente.
    expect(result.status, BorderStatus.entradaInvalida);
    expect(
      result.avisos.map((notice) => notice.status),
      contains(BorderStatus.entradaInvalida),
    );
    final approved = solver.dimensionar(
      BorderProject.ilustrativo.copyWith(
        alturaDiqueM: .1,
        laminaSuperficialM: .1,
      ),
    );
    expect(approved.status, BorderStatus.avisoOrientativo);
    expect(
      approved.avisos.every(
        (notice) => notice.status == BorderStatus.avisoOrientativo,
      ),
      isTrue,
    );
  });

  test('falhas de domínio e convergência carregam código canônico e página', () {
    Object? capturar(void Function() acao) {
      try {
        acao();
        return null;
      } on FormatException catch (e) {
        return e;
      }
    }

    final nivel = capturar(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(desnivelLongitudinalM: 0),
      ),
    );
    expect(nivel, isA<BorderModelException>());
    expect((nivel! as BorderModelException).status, BorderStatus.foraDoDominio);
    expect((nivel as BorderModelException).codigo, 'fora_do_dominio');

    final fechada = capturar(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(
          jusante: CondicaoJusanteFaixa.fechada,
        ),
      ),
    );
    expect((fechada! as BorderModelException).status, BorderStatus.foraDoDominio);

    final reuso = capturar(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(manejo: ManejoFaixa.reuso),
      ),
    );
    expect(
      (reuso! as BorderModelException).status,
      BorderStatus.modeloNaoImplementado,
    );

    final naoFinito = capturar(
      () => solver.dimensionar(BorderProject.ilustrativo.copyWith(a: double.nan)),
    );
    expect(
      (naoFinito! as BorderModelException).status,
      BorderStatus.entradaInvalida,
    );

    // Versão de expoentes fora da implementada: modelo não implementado.
    final expoentes = capturar(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(
          numerico: const BorderNumericConfig(
            versaoExpoentesRecessao: 'p63',
          ),
        ),
      ),
    );
    expect(
      (expoentes! as BorderModelException).status,
      BorderStatus.modeloNaoImplementado,
    );
    // Método de integração desconhecido: entrada inválida.
    final metodo = capturar(
      () => solver.dimensionar(
        BorderProject.ilustrativo.copyWith(
          numerico: const BorderNumericConfig(metodoIntegracao: 'rk4'),
        ),
      ),
    );
    expect(
      (metodo! as BorderModelException).status,
      BorderStatus.entradaInvalida,
    );
    expect(BorderProject.ilustrativo.impedimento, isNull);
    expect(
      BorderProject.ilustrativo
          .copyWith(jusante: CondicaoJusanteFaixa.fechada)
          .impedimento!
          .codigo,
      'fora_do_dominio',
    );
  });

  test('método de integração declarado troca a quadratura sem quebrar balanço', () {
    final base = BorderProject.ilustrativo.copyWith(
      alturaDiqueM: .1,
      laminaSuperficialM: .1,
    );
    final cruzamento = solver.dimensionar(base);
    final simples = solver.dimensionar(
      base.copyWith(
        numerico: const BorderNumericConfig(metodoIntegracao: 'trapezios'),
      ),
    );
    expect(simples.numerico.metodoIntegracao, 'trapezios');
    expect(simples.perfil.length, cruzamento.perfil.length);
    expect(simples.ea + simples.pp + simples.pe, closeTo(100, 1e-6));
    expect(
      simples.volumeUtilM3M + simples.volumeDeficitM3M,
      closeTo(0.056 * 400, 1e-7),
    );
  });
}
