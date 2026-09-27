import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/irrigation_project.dart';
import 'package:irrigasim/services/simulation/advance_curve_model.dart';
import 'package:irrigasim/services/simulation/depth_performance.dart';
import 'package:irrigasim/services/simulation/flow_management.dart';
import 'package:irrigasim/services/simulation/infiltration_model.dart';
import 'package:irrigasim/services/simulation/lamina_requerida.dart';
import 'package:irrigasim/services/simulation/length_selector.dart';
import 'package:irrigasim/services/simulation/operational_planning.dart';
import 'package:irrigasim/services/simulation/opportunity_time.dart';
import 'package:irrigasim/services/simulation/run_furrow_simulation.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

void main() {
  group('documented domain regressions', () {
    test(
      'controller calculates corn IRN and irrigation interval from demand',
      () {
        final controller = ParametersController();

        controller.updateField(campo: 'evapotranspiracaoMmDia', valor: '4');

        expect(controller.state.laminaRequerida, closeTo(42, 1e-9));
        expect(
          controller.state.laminaRequeridaResultado?.turnoCalculadoDias,
          closeTo(10.5, 1e-9),
        );
      },
    );

    test('controller recalculates irrigation interval when Pef changes', () {
      final controller = ParametersController();
      controller.updateField(campo: 'evapotranspiracaoMmDia', valor: '4');

      controller.updateField(campo: 'precipitacaoEfetivaMmDia', valor: '1');

      expect(
        controller.state.laminaRequeridaResultado?.demandaLiquidaMmDia,
        closeTo(3, 1e-9),
      );
      expect(
        controller.state.laminaRequeridaResultado?.turnoCalculadoDias,
        closeTo(14, 1e-9),
      );
    });

    test('uses the documented C/a table and applies 1.1 only to Qr', () {
      final qmax = FlowManagement.calcularVazaoMaxima(
        declividadePercent: 0.5,
        textura: TexturaSolo.media,
      );
      final withoutFactor = FlowManagement.calcularVazaoReduzida(
        f0MmH: 7.9,
        comprimentoM: 200,
        espacamentoM: 1,
      );
      final withFactor = FlowManagement.calcularVazaoReduzida(
        f0MmH: 7.9,
        comprimentoM: 200,
        espacamentoM: 1,
        fator11: 1.1,
      );

      expect(qmax.qmaxLs, closeTo(1.02, 0.01));
      expect(withoutFactor.vazaoReduzidaLs, closeTo(0.4388888889, 1e-9));
      expect(withFactor.vazaoReduzidaLs, closeTo(0.4827777778, 1e-9));
    });

    test('derives cutoff from final opportunity time', () {
      final points = const [AdvancePoint(0, 0), AdvancePoint(200, 90)];
      final result = OpportunityTime.calcularTempoIrrigacao(
        tempoOportunidadeMin: 130,
        tempoAvancoMin: 90,
        pontosAvanco: points,
      );

      expect(result.tempoTotalMin, 220);
      expect(result.pontos.last.tempoCorteMin, 220);
      expect(result.pontos.last.tempoMin, 130);
    });

    test('performance uses Lf for Ea and direct Pe/Pp formulas', () {
      final result = DepthPerformance.calcularDesempenho(
        perfilInfiltrado: const [31.2, 30],
        laminaRequerida: 30,
        laminaAplicada: 60,
      );

      expect(result.laminaMediaInfiltrada, closeTo(30.6, 1e-9));
      expect(result.eficienciaAplicacao, closeTo(50, 1e-9));
      expect(result.perdaPercolacao, closeTo(1, 1e-9));
      expect(result.perdaEscoamento, closeTo(49, 1e-9));
      expect(
        () => DepthPerformance.laminaComReducao(
          tempoTotalMin: 60,
          tempoReducaoMin: 61,
          vazaoInicialLs: 1,
          vazaoReduzidaLs: .5,
          espacamentoM: 1,
          comprimentoM: 100,
        ),
        throwsArgumentError,
      );
    });

    test('wet perimeter uses the submerged sides, not squared lengths', () {
      const geometry = GeometriaSulco(
        forma: FormaSulco.v,
        larguraSuperiorM: .2,
        profundidadeM: .1,
        espacamentoM: 1,
      );
      expect(geometry.perimetroMolhadoM, closeTo(0.2828427125, 1e-9));
    });

    test('two-point source example requires an actual half distance', () {
      final curve = AdvanceCurveModel.ajustarDoisPontos(
        distanciaM: 120,
        tempoMin: 58,
        distanciaMetadeM: 60,
        tempoMetadeMin: 22,
        pontos: const [
          PontoEnsaio(distanciaM: 0, tempoMin: 0),
          PontoEnsaio(distanciaM: 60, tempoMin: 22),
          PontoEnsaio(distanciaM: 120, tempoMin: 58),
        ],
      );

      expect(curve.b, closeTo(1.3985493764902743, 1e-12));
      expect(curve.k, closeTo(0.07171175618605942, 1e-12));
      expect(curve.pontosOriginais.first.distanciaM, 0);
      expect(
        () => AdvanceCurveModel.ajustarDoisPontos(
          distanciaM: 120,
          tempoMin: 58,
          distanciaMetadeM: 50,
          tempoMetadeMin: 22,
          pontos: const [],
        ),
        throwsArgumentError,
      );
    });

    test('VI is a rate and is not differentiated a second time', () {
      const parameters = InfiltrationParameters(
        k: 35.203016822389664,
        n: -0.31077526032565167,
        origem: OrigemParametros.ensaio,
        unidadeK: 'mm/h',
      );
      expect(
        InfiltrationModel.taxaInfiltracao(tempoMin: 60, parametros: parameters),
        closeTo(
          InfiltrationModel.vi(tempoMin: 60, parametros: parameters),
          1e-12,
        ),
      );
    });

    test(
      'does not select a rejected length and validates operational inputs',
      () {
        const advance = AdvanceCurveResult(
          k: .1,
          b: 1.2,
          metodo: MetodoAjusteAvanco.doisPontos,
          pontosOriginais: [],
        );
        const infiltration = InfiltrationParameters(
          k: 35,
          n: -.3,
          origem: OrigemParametros.ensaio,
          unidadeK: 'mm/h',
        );
        final selection = LengthSelector.selecionar(
          comprimentosCandidatos: const [100, 200],
          parametrosAvanco: advance,
          parametrosInfiltracao: infiltration,
          vazaoLs: 2,
          espacamentoM: 1,
          declividadePercent: .5,
          tempoAplicacaoMin: 130,
        );

        expect(selection.comprimentoEscolhidoM, isNull);
        expect(selection.avaliacoes.every((item) => !item.aprovado), isTrue);
        expect(
          () => OperationalPlanning.calcular(
            areaTotalM2: 1000,
            comprimentoSulcoM: 100,
            espacamentoM: 1,
            pi: 0,
            tempoAplicacaoH: 2,
            tempoMudancaH: 0,
            tempoDiarioDisponivelH: 8,
            vazaoInicialLs: 1,
          ),
          throwsArgumentError,
        );
      },
    );

    test('furrow reduction uses Ta at qi and To at qr', () {
      final result = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: .005,
          larguraOuEspacamento: .9,
          k: 2.83,
          a: .554,
          vib: .0001,
          vazao: 1,
          vazaoReduzidaLs: .5,
          manejoSulco: ManejoSulco.reduzida,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // [(90 * 1) + (130 * .5)] / (200 * .9) * 60 = 51.666... mm.
      expect(result.metricas['Lâmina aplicada'], closeTo(51.6666666667, 1e-9));
    });

    test('reduction delay extends the initial-flow period after advance', () {
      final result = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: .005,
          larguraOuEspacamento: .9,
          k: 2.83,
          a: .554,
          vib: .0001,
          vazao: 1,
          vazaoReduzidaLs: .5,
          tempoMudancaMin: 30,
          manejoSulco: ManejoSulco.reduzida,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // [(120 * 1) + (100 * .5)] / (200 * .9) * 60 = 56.666... mm.
      expect(result.metricas['Lâmina aplicada'], closeTo(56.6666666667, 1e-9));
      expect(result.metricas['Tempo de mudança'], 120);
    });

    test(
      'furrow reports conduction efficiency and spatial adequacy degree',
      () {
        final result = RunFurrowSimulation()(
          const IrrigationParameters(
            comprimento: 200,
            declividade: .005,
            larguraOuEspacamento: .9,
            k: 2.83,
            a: .554,
            vib: .0001,
            vazao: 1,
            perdasConducaoLs: .25,
            tempoAplicacao: 130,
            laminaRequerida: 42,
            tempoAvancoMetadeMin: 35,
            tempoAvancoFinalMin: 90,
          ),
        );

        final expectedAdequacy =
            result.perfilLongitudinal
                .map((depth) => depth < .042 ? depth / .042 : 1.0)
                .reduce((sum, value) => sum + value) /
            result.perfilLongitudinal.length *
            100;

        expect(result.metricas['Eficiência de condução'], closeTo(80, 1e-9));
        expect(
          result.metricas['Grau de adequação'],
          closeTo(expectedAdequacy, 1e-9),
        );
        expect(result.unidadesMetricas['Eficiência de condução'], '%');
        expect(result.unidadesMetricas['Grau de adequação'], '%');
      },
    );

    test('furrow conduction efficiency is 100 percent without losses', () {
      final result = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: .005,
          larguraOuEspacamento: .9,
          k: 2.83,
          a: .554,
          vib: .0001,
          vazao: 1,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(result.metricas['Eficiência de condução'], 100);
    });

    test('rejects unphysical or unsupported calculation inputs', () {
      const base = IrrigationParameters(
        comprimento: 200,
        declividade: .005,
        larguraOuEspacamento: .9,
        k: 2.83,
        a: .554,
        vib: .0001,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      );

      expect(
        () => RunFurrowSimulation()(
          base.copyWith(manejoSulco: ManejoSulco.reduzida, vazaoReduzidaLs: 0),
        ),
        throwsFormatException,
      );
      expect(
        () => RunFurrowSimulation()(
          base.copyWith(manejoSulco: ManejoSulco.surtir),
        ),
        throwsFormatException,
      );
      expect(
        () => RunFurrowSimulation()(
          base.copyWith(
            manejoSulco: ManejoSulco.reduzida,
            vazaoReduzidaLs: .5,
            tempoMudancaMin: 131,
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => LaminaRequeridaCalculator.calcular(
          uccPercentual: 15,
          upmpPercentual: 15,
          densidadeGcm3: 1.4,
          profundidadeRaizesCm: 40,
          fracaoAguaDisponivel: .5,
          demandaLiquidaMmDia: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => InfiltrationModel.ajustarCurva(const [
          PontoInfiltracaoMedido(tempoMin: 0, volumeMm: 0),
          PontoInfiltracaoMedido(tempoMin: 10, volumeMm: 0),
          PontoInfiltracaoMedido(tempoMin: 20, volumeMm: 5),
        ]),
        throwsArgumentError,
      );
    });
  });
}
