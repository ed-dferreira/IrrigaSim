import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/ensaios_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/geometria_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/modelo_curva_avanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/desempenho_lamina.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/manejo_vazao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/modelo_infiltracao.dart';
import 'package:irrigasim/shared/irrigacao/services/lamina_requerida.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/seletor_comprimento.dart';
import 'package:irrigasim/shared/irrigacao/services/operational_planning.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/tempo_oportunidade.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/simulador_sulcos.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

void main() {
  group('documented domain regressions', () {
    test(
      'controller calculates corn IRN and irrigation interval from demand',
      () {
        final controller = ControladorParametrosSulco();

        controller.atualizarCampo(campo: 'evapotranspiracaoMmDia', valor: '4');

        expect(controller.state.laminaRequerida, closeTo(42, 1e-9));
        expect(
          controller.state.laminaRequeridaResultado?.turnoCalculadoDias,
          closeTo(10.5, 1e-9),
        );
      },
    );

    test('controller recalculates irrigation interval when Pef changes', () {
      final controller = ControladorParametrosSulco();
      controller.atualizarCampo(campo: 'evapotranspiracaoMmDia', valor: '4');

      controller.atualizarCampo(campo: 'precipitacaoEfetivaMmDia', valor: '1');

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
      final qmax = ManejoVazao.calcularVazaoMaxima(
        declividadePercent: 0.5,
        textura: TexturaSolo.media,
      );
      final withoutFactor = ManejoVazao.calcularVazaoReduzida(
        f0MmH: 7.9,
        comprimentoM: 200,
        espacamentoM: 1,
      );
      final withFactor = ManejoVazao.calcularVazaoReduzida(
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
      final points = const [PontoAvanco(0, 0), PontoAvanco(200, 90)];
      final result = TempoOportunidade.calcularTempoIrrigacao(
        tempoOportunidadeMin: 130,
        tempoAvancoMin: 90,
        pontosAvanco: points,
      );

      expect(result.tempoTotalMin, 220);
      expect(result.pontos.last.tempoCorteMin, 220);
      expect(result.pontos.last.tempoMin, 130);
      expect(
        () => TempoOportunidade.calcularPonto(
          tempoCorteMin: 20,
          tempoAvancoMin: 25,
        ),
        throwsArgumentError,
      );
    });

    test('performance uses Lf for Ea and direct Pe/Pp formulas', () {
      final result = DesempenhoLamina.calcularDesempenho(
        perfilInfiltrado: const [31.2, 30],
        laminaRequerida: 30,
        laminaAplicada: 60,
      );

      expect(result.laminaMediaInfiltrada, closeTo(30.6, 1e-9));
      expect(result.eficienciaAplicacao, closeTo(50, 1e-9));
      expect(result.perdaPercolacao, closeTo(1, 1e-9));
      expect(result.perdaEscoamento, closeTo(49, 1e-9));
      expect(
        () => DesempenhoLamina.laminaComReducao(
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
      final curve = ModeloCurvaAvanco.ajustarDoisPontos(
        distanciaM: 120,
        tempoMin: 58,
        distanciaMetadeM: 60,
        tempoMetadeMin: 22,
        pontos: const [
          PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
          PontoEnsaioAvanco(distanciaM: 60, tempoMin: 22),
          PontoEnsaioAvanco(distanciaM: 120, tempoMin: 58),
        ],
      );

      expect(curve.expoente, closeTo(1.3985493764902743, 1e-12));
      expect(curve.coeficiente, closeTo(0.07171175618605942, 1e-12));
      expect(curve.pontosOriginais.first.distanciaM, 0);
      expect(
        () => ModeloCurvaAvanco.ajustarDoisPontos(
          distanciaM: 120,
          tempoMin: 58,
          distanciaMetadeM: 50,
          tempoMetadeMin: 22,
          pontos: const [],
        ),
        throwsArgumentError,
      );
    });

    test('two-point field method interpolates the unmeasured middle stake', () {
      final curve = ModeloCurvaAvanco.ajustarDoisPontosPorEstacas(const [
        PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
        PontoEnsaioAvanco(distanciaM: 50, tempoMin: 20),
        PontoEnsaioAvanco(distanciaM: 150, tempoMin: 60),
        PontoEnsaioAvanco(distanciaM: 200, tempoMin: 90),
      ]);

      expect(
        ModeloCurvaAvanco.tempoAvanco(distanciaM: 100, parametros: curve),
        closeTo(40, 1e-9),
      );
      expect(curve.coeficiente, greaterThan(0));
    });

    test(
      'two-point method matches the stakeholder k=0.095, b=1.30 example',
      () {
        const k = .095;
        const b = 1.3;
        final curve = ModeloCurvaAvanco.ajustarDoisPontosPorEstacas([
          PontoEnsaioAvanco(distanciaM: 50, tempoMin: k * math.pow(50, b)),
          PontoEnsaioAvanco(distanciaM: 100, tempoMin: k * math.pow(100, b)),
        ]);

        expect(curve.coeficiente, closeTo(k, 1e-12));
        expect(curve.expoente, closeTo(b, 1e-12));
      },
    );

    test('least-squares field method reproduces the stakeholder curve', () {
      final points = [25.0, 50.0, 75.0, 100.0]
          .map(
            (distance) => PontoEnsaioAvanco(
              distanciaM: distance,
              tempoMin: .011 * math.pow(distance, 1.65).toDouble(),
            ),
          )
          .toList();
      final curve = ModeloCurvaAvanco.ajustarMinimosQuadrados(points);

      expect(curve.coeficiente, closeTo(.011, 1e-12));
      expect(curve.expoente, closeTo(1.65, 1e-12));
    });

    test('estimated advance accepts direct k and b parameters', () {
      final result = SimuladorSulcos()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: .005,
          larguraOuEspacamento: .9,
          k: 2.83,
          a: .554,
          vib: .0001,
          vazao: .9,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
          coeficienteAvancoK: .095,
          expoenteAvancoB: 1.3,
          distanciaReferenciaAvancoM: 100,
        ),
      );

      expect(result.tempoAvanco, closeTo(.095 * math.pow(200, 1.3), 1e-9));
      expect(result.metricas['Coeficiente da curva de avanço'], .095);
      expect(result.metricas['Expoente da curva de avanço'], 1.3);
      expect(result.metricas['Distância X de referência'], 100);
      expect(
        result.metricas['Tempo Tx calculado em X'],
        closeTo(.095 * math.pow(100, 1.3), 1e-9),
      );
    });

    test('advance regression ignores only the measured origin before logs', () {
      const observations = [
        PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
        PontoEnsaioAvanco(distanciaM: 25, tempoMin: 10),
        PontoEnsaioAvanco(distanciaM: 50, tempoMin: 22),
        PontoEnsaioAvanco(distanciaM: 100, tempoMin: 48),
      ];
      final curve = ModeloCurvaAvanco.ajustarMinimosQuadrados(observations);

      expect(curve.pontosOriginais, observations);
      expect(curve.coeficiente, greaterThan(0));
      expect(curve.expoente, greaterThan(0));
      expect(
        ModeloCurvaAvanco.tempoAvanco(distanciaM: 100, parametros: curve),
        closeTo(48, 5),
      );
    });

    test(
      'controller sends the measured regression curve to furrow simulation',
      () async {
        final controller = ControladorParametrosSulco();
        controller.definirOrigemAvanco(OrigemAvanco.ensaio);
        controller.definirMetodoCurvaAvanco(MetodoAjusteAvanco.minimosQuadrados);
        controller.atualizarCampo(campo: 'vazaoEnsaioAvancoLs', valor: '1');
        controller.definirCondicoesEnsaioAvanco(
          'Solo médio, seção em V e orientação ensaiada',
        );
        controller.definirPontosEnsaioAvanco(const [
          PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
          PontoEnsaioAvanco(distanciaM: 50, tempoMin: 20),
          PontoEnsaioAvanco(distanciaM: 100, tempoMin: 43),
          PontoEnsaioAvanco(distanciaM: 200, tempoMin: 95),
        ]);

        await controller.executarSimulacao();

        expect(controller.state.erro, isNull);
        expect(controller.state.resultado?.tempoAvanco, isNot(90));
      },
    );

    test(
      'controller attaches typed parcel planning to furrow results',
      () async {
        final controller = ControladorParametrosSulco();

        await controller.executarSimulacao();

        final planning = controller.state.resultado?.planejamentoOperacional;
        expect(controller.state.erro, isNull);
        expect(planning, isNotNull);
        expect(planning!.tipH, greaterThan(0));
        expect(planning.npdOperacional, greaterThan(0));
        expect(planning.agendaViavel, isTrue);
      },
    );

    test(
      'estimated curve fields drive the controller simulation parameters',
      () {
        final controller = ControladorParametrosSulco();
        controller.atualizarCampo(campo: 'coeficienteAvancoK', valor: '.095');
        controller.atualizarCampo(campo: 'expoenteAvancoB', valor: '1.3');
        final params = controller.state.paraParametrosIrrigacao();

        expect(params.coeficienteAvancoK, .095);
        expect(params.expoenteAvancoB, 1.3);
        expect(
          controller.state.tempoAvancoFinalMin,
          closeTo(.095 * math.pow(controller.state.comprimento, 1.3), 1e-9),
        );
      },
    );

    test('inlet/outlet measurements drive the selected infiltration curve', () {
      final observations = List.generate(11, (index) {
        final time = (index + 1) * 10.0;
        final vi = 30 * math.pow(time, -0.3);
        return MedicaoEntradaSaida(
          tempoMin: time,
          vazaoEntradaLs: 1,
          vazaoSaidaLs: 1 - vi / 40,
        );
      });
      final result = SimuladorSulcos()(
        IrrigationParameters(
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
          origemCurvaInfiltracao: OrigemCurvaInfiltracao.ensaioEntradaSaida,
          distanciaEnsaioInfiltracaoM: 100,
          espacamentoEnsaioInfiltracaoM: .9,
          medicoesEntradaSaida: observations,
        ),
      );

      expect(result.perfilLongitudinal.last, greaterThan(0));
      expect(result.origemCurvaInfiltracao, 'ensaioEntradaSaida');
      expect(result.metricas['Coeficiente VI ajustado'], closeTo(30, 1e-8));
      expect(result.metricas['Expoente VI ajustado'], closeTo(-.3, 1e-8));
      expect(
        result.metricas['Coeficiente acumulado ajustado'],
        closeTo(30 / (60 * .7), 1e-8),
      );
      expect(result.metricas['Expoente acumulado ajustado'], closeTo(.7, 1e-8));
    });

    test(
      'measured recession changes local opportunity and rejects negative time',
      () {
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
          hipoteseRecessao: HipoteseRecessao.medidaPorEstaca,
          medicoesRecessao: [
            MedicaoRecessao(distanciaM: 0, instanteRecessaoMin: 230),
            MedicaoRecessao(distanciaM: 100, instanteRecessaoMin: 245),
            MedicaoRecessao(distanciaM: 200, instanteRecessaoMin: 270),
          ],
        );
        final measured = SimuladorSulcos()(base);
        final simplified = SimuladorSulcos()(
          base.copyWith(
            hipoteseRecessao: HipoteseRecessao.desprezada,
            medicoesRecessao: const [],
          ),
        );

        expect(
          measured.perfilLongitudinal[10],
          greaterThan(simplified.perfilLongitudinal[10]),
        );
        expect(measured.tempoOportunidadeFinalMin, 180);
        expect(
          () => SimuladorSulcos()(
            base.copyWith(
              medicoesRecessao: const [
                MedicaoRecessao(distanciaM: 0, instanteRecessaoMin: 30),
                MedicaoRecessao(distanciaM: 200, instanteRecessaoMin: 80),
              ],
            ),
          ),
          throwsFormatException,
        );
      },
    );

    test('VI is a rate and is not differentiated a second time', () {
      const parameters = ParametrosInfiltracao(
        coeficiente: 35.203016822389664,
        expoente: -0.31077526032565167,
        origem: OrigemParametrosInfiltracao.ensaio,
        unidadeCoeficiente: 'mm/h',
      );
      expect(
        ModeloInfiltracao.taxaInfiltracao(tempoMin: 60, parametros: parameters),
        closeTo(
          parameters.coeficiente * math.pow(60, parameters.expoente),
          1e-12,
        ),
      );
    });

    test(
      'does not select a rejected length and validates operational inputs',
      () {
        const advance = ResultadoCurvaAvanco(
          coeficiente: .1,
          expoente: 1.2,
          metodo: MetodoAjusteAvanco.doisPontos,
          pontosOriginais: [],
        );
        const infiltration = ParametrosInfiltracao(
          coeficiente: 35,
          expoente: -.3,
          origem: OrigemParametrosInfiltracao.ensaio,
          unidadeCoeficiente: 'mm/h',
        );
        final selection = SeletorComprimento.selecionar(
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
            periodoIrrigacaoDias: 0,
            tempoFornecimentoH: 2,
            tempoMudancaParcelaH: 0,
            jornadaDiariaH: 8,
            vazaoInicialLs: 1,
          ),
          throwsArgumentError,
        );
      },
    );

    test('furrow reduction uses Ta at qi and To at qr', () {
      final result = SimuladorSulcos()(
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

    test(
      'closed, level and zig-zag furrows are blocked by open-flow engine',
      () {
        const base = IrrigationParameters(
          comprimento: 100,
          declividade: .001,
          larguraOuEspacamento: 1,
          k: .1,
          a: .5,
          vib: 0,
          vazao: .2,
          tempoAplicacao: 100,
          laminaRequerida: 20,
          tempoAvancoMetadeMin: 20,
          tempoAvancoFinalMin: 50,
        );
        for (final tipo in [
          TipoSulco.sulcos_nivel_tabuleiros,
          TipoSulco.sulcos_nivel_fechados,
          TipoSulco.sulcos_em_zigue_zague,
        ]) {
          expect(
            () => SimuladorSulcos()(base.copyWith(tipoSulco: tipo)),
            throwsFormatException,
            reason: tipo.displayName,
          );
        }
      },
    );

    test('length selector uses mm dimension and type slope constraints', () {
      const advance = ResultadoCurvaAvanco(
        coeficiente: .1,
        expoente: 1.2,
        metodo: MetodoAjusteAvanco.doisPontos,
        pontosOriginais: [],
      );
      const infiltration = ParametrosInfiltracao(
        coeficiente: 60,
        expoente: 0,
        origem: OrigemParametrosInfiltracao.valorInformado,
        unidadeCoeficiente: 'mm/h',
      );
      final valid = SeletorComprimento.selecionar(
        comprimentosCandidatos: const [100],
        parametrosAvanco: advance,
        parametrosInfiltracao: infiltration,
        vazaoLs: .5,
        espacamentoM: 1,
        declividadePercent: .1,
        tempoAplicacaoMin: 100,
      );
      expect(valid.comprimentoEscolhidoM, 100);
      expect(valid.avaliacoes.single.eficienciaEstimada, 100);

      final unsupported = SeletorComprimento.selecionar(
        comprimentosCandidatos: const [100],
        parametrosAvanco: advance,
        parametrosInfiltracao: infiltration,
        vazaoLs: .5,
        espacamentoM: 1,
        declividadePercent: .1,
        tempoAplicacaoMin: 100,
        tipo: TipoSulco.sulcos_nivel_fechados,
      );
      expect(unsupported.comprimentoEscolhidoM, isNull);
      expect(
        unsupported.avaliacoes.single.motivo,
        contains('não têm escoamento'),
      );
    });

    test('operational planning covers 600 furrows in ten days', () {
      final plan = OperationalPlanning.calcular(
        areaTotalM2: 600 * 200,
        comprimentoSulcoM: 200,
        espacamentoM: 1,
        periodoIrrigacaoDias: 10,
        tempoFornecimentoH: 220 / 60,
        tempoMudancaParcelaH: .5,
        jornadaDiariaH: 14,
        vazaoInicialLs: 1,
        vazaoDisponivelLs: 20,
      );

      expect(plan.ntsOperacional, 600);
      expect(plan.nsdOperacional, 60);
      expect(plan.tipH, closeTo(4.1666666667, 1e-9));
      expect(plan.npdOperacional, 3);
      expect(plan.nspOperacional, 20);
      expect(plan.qProjetoOperacional, 20);
      expect(plan.diasNecessariosOperacional, 10);
      expect(plan.agendaViavel, isTrue);
      expect(plan.vazaoDisponivelSuficiente, isTrue);
    });

    test('operation is infeasible when one parcel exceeds the workday', () {
      final plan = OperationalPlanning.calcular(
        areaTotalM2: 10000,
        comprimentoSulcoM: 100,
        espacamentoM: 1,
        periodoIrrigacaoDias: 10,
        tempoFornecimentoH: 9,
        tempoMudancaParcelaH: .5,
        jornadaDiariaH: 8,
        vazaoInicialLs: 1,
      );

      expect(plan.npdOperacional, 0);
      expect(plan.agendaViavel, isFalse);
      expect(plan.motivoInviabilidade, contains('excede a jornada'));
    });

    test('reduction delay extends the initial-flow period after advance', () {
      final result = SimuladorSulcos()(
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
      expect(result.metricas['Tempo com vazão inicial'], 120);
      expect(result.metricas['Tempo com vazão reduzida'], 100);
      expect(
        result.metricas['Tempo com vazão inicial']! +
            result.metricas['Tempo com vazão reduzida']!,
        220,
      );
    });

    test(
      'furrow reports conduction efficiency and spatial adequacy degree',
      () {
        final result = SimuladorSulcos()(
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

        final usefulProfile = result.perfilLongitudinal
            .map((depth) => depth < .042 ? depth : .042)
            .toList();
        final expectedAdequacy =
            ((usefulProfile.first + usefulProfile.last) / 2 +
                usefulProfile
                    .skip(1)
                    .take(usefulProfile.length - 2)
                    .reduce((sum, value) => sum + value)) /
            (usefulProfile.length - 1) /
            .042 *
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
      final result = SimuladorSulcos()(
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

      final estimated = SimuladorSulcos()(
        base.copyWith(manejoSulco: ManejoSulco.reduzida, vazaoReduzidaLs: 0),
      );
      expect(
        estimated.metricas['Vazão reduzida estimada pela curva'],
        greaterThan(0),
      );
      expect(
        () => SimuladorSulcos()(base.copyWith(manejoSulco: ManejoSulco.surtir)),
        throwsFormatException,
      );
      expect(
        () => SimuladorSulcos()(
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
        () => ModeloInfiltracao.ajustarCurva(const [
          PontoInfiltracaoMedido(tempoMin: 0, taxaMmHora: 0),
          PontoInfiltracaoMedido(tempoMin: 10, taxaMmHora: 0),
          PontoInfiltracaoMedido(tempoMin: 20, taxaMmHora: 5),
        ]),
        throwsArgumentError,
      );
    });
  });
}
