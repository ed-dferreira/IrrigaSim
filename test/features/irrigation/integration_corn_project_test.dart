import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';
import 'package:irrigasim/services/simulation/sulcos/advance_curve_model.dart';
import 'package:irrigasim/services/simulation/sulcos/depth_performance.dart';
import 'package:irrigasim/services/simulation/sulcos/flow_management.dart';
import 'package:irrigasim/services/simulation/sulcos/infiltration_model.dart';
import 'package:irrigasim/services/simulation/lamina_requerida.dart';
import 'package:irrigasim/services/simulation/sulcos/opportunity_time.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';

/// Valores de referência do §56 do documento.
///
/// Projeto resolvido: milho, UCC=30,5%, UPMP=18%, Ds=1,12 g/cm³,
/// raízes=50 cm, f=0,6, ETc=7 e Pef=3 mm/dia.
/// Curva de infiltração: k = 2,83 mm/min^n, n = 0,554.
/// Vazão = 1,5 L/s por sulco (reprovada por erosão)
/// Vazão reduzida = 0,75 L/s
void main() {
  group('Projeto resolvido de milho — lâmina requerida e turno de rega', () {
    test('IRN = 42 mm (§56.1)', () {
      final resultado = LaminaRequeridaCalculator.calcular(
        uccPercentual: 30.5,
        upmpPercentual: 18,
        densidadeGcm3: 1.12,
        profundidadeRaizesCm: 50,
        fracaoAguaDisponivel: 0.6,
        demandaLiquidaMmDia: 7 - 3,
      );

      // IRN = (0.305-0.18) * 10 * 1.12 * 50 * 0.6 = 42 mm
      expect(resultado.irnMm, closeTo(42, 0.001));
    });

    test('TR calculado = 10,5 dias (§56.2)', () {
      final resultado = LaminaRequeridaCalculator.calcular(
        uccPercentual: 30.5,
        upmpPercentual: 18,
        densidadeGcm3: 1.12,
        profundidadeRaizesCm: 50,
        fracaoAguaDisponivel: 0.6,
        demandaLiquidaMmDia: 7 - 3,
      );

      // TR = 42 / (ETc 7 - Pef 3) = 10.5 dias
      expect(resultado.turnoCalculadoDias, closeTo(10.5, 0.001));
    });

    test('valores intermediários do cálculo de IRN', () {
      final resultado = LaminaRequeridaCalculator.calcular(
        uccPercentual: 30.5,
        upmpPercentual: 18,
        densidadeGcm3: 1.12,
        profundidadeRaizesCm: 50,
        fracaoAguaDisponivel: 0.6,
        demandaLiquidaMmDia: 7 - 3,
      );

      expect(resultado.uccDecimal, closeTo(0.305, 1e-12));
      expect(resultado.upmpDecimal, closeTo(0.18, 1e-12));
      expect(resultado.faad, closeTo(0.125, 1e-12));
      expect(resultado.profundidadeCm, closeTo(50, 1e-12));
      expect(resultado.fatorCultura, closeTo(0.6, 1e-12));
    });
  });

  group('ISSUE-016 — Caso milho §56: vazão não erosiva', () {
    test('q = 1,5 L/s reprovado por erosão (§56.3)', () {
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(resultado.alertaVazaoExcedida, isNotNull);
      expect(resultado.alertaVazaoExcedida!, contains('ultrapassa'));
    });

    test('qmax calculada para textura média via RunFurrowSimulation (§56.3)', () {
      // RunFurrowSimulation usa FlowManagement: qmax = C / S0^a (textura média)
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // qmax = C / S0^a (textura média: C=0.613, a=0.733, S0=0.5%)
      // qmax ≈ 1.02 L/s
      expect(
        resultado.metricas['Vazão máxima não erosiva'],
        closeTo(1.02, 0.01),
      );
    });

    test('qmax por FlowManagement usa equação por textura (§30)', () {
      // FlowManagement: qmax = C / S0^a (S0 em %)
      // Textura média: C=0.613, a=0.733, S0=0.5%
      final erosao = FlowManagement.calcularVazaoMaxima(
        declividadePercent: 0.5,
        textura: TexturaSolo.media,
      );

      expect(erosao.qmaxLs, closeTo(1.02, 0.01));
      expect(erosao.textura, TexturaSolo.media);
    });
  });

  group('ISSUE-016 — Caso milho §56: vazão constante 200m', () {
    late dynamic resultado;

    setUp(() {
      // §56.9: valores de referência usam vazão de 1 L/s (não erosiva)
      // A vazão de 1,5 L/s é apenas para o teste de flag de erosão
      resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );
    });

    test('vazão máxima não erosiva ≈ 1,02 L/s (§30 — textura média)', () {
      expect(
        resultado.metricas['Vazão máxima não erosiva'],
        closeTo(1.02, 0.01),
      );
    });

    test('tempo de aplicação = 220 min (§56.9)', () {
      expect(
        resultado.metricas['Tempo de aplicação calculado'],
        closeTo(220, 1),
      );
    });

    test('lâmina aplicada recalculada = 73,333 mm (§56.9)', () {
      // Lâmina aplicada já está em mm no metricas
      final laminaMm = resultado.metricas['Lâmina aplicada'] as num;
      expect(laminaMm.toDouble(), closeTo(73.33333333333333, 1e-9));
    });

    test('Ea integral recalculada do perfil de 0 a L', () {
      expect(
        resultado.balancoSulco!.eaIntegral,
        closeTo(57.272687212695466, 0.002),
      );
    });

    test('balanço físico: Ea integral + Pp integral + Pe integral = 100%', () {
      final soma =
          resultado.balancoSulco!.eaIntegral +
          resultado.perdaPercolacao +
          resultado.perdaEscoamento;
      expect(soma, closeTo(100, 1e-8));
    });

    test('perfil longitudinal tem dados válidos', () {
      expect(resultado.perfilLongitudinal, isNotEmpty);
      expect(resultado.perfilLongitudinal.first, greaterThan(0));
      expect(resultado.perfilLongitudinal.last, greaterThan(0));
    });

    test('curva de avanço tem dados válidos', () {
      expect(resultado.curvaAvanco, isNotEmpty);
      expect(resultado.tempoAvanco, greaterThan(0));
    });
  });

  group('ISSUE-016 — Caso milho §56: infiltração', () {
    test('equação de infiltração §19: VI = K * T^n (dados em L/s)', () {
      // §19: ensaio entrada/saída com Qentrada=1 L/s, 100m, 1m espaçamento
      // VI(mm/h) = (Qentrada - Qsaida) * 36
      // Resultado esperado: K≈35.2, n≈-0.311
      final parametros = InfiltrationModel.ajustarCurva([
        // Dados convertidos de L/s para mm/h: VI = (1 - Qs) * 36
        const PontoInfiltracaoMedido(tempoMin: 2, volumeMm: 29.16),
        const PontoInfiltracaoMedido(tempoMin: 9, volumeMm: 18.00),
        const PontoInfiltracaoMedido(tempoMin: 19, volumeMm: 13.32),
        const PontoInfiltracaoMedido(tempoMin: 29, volumeMm: 12.24),
        const PontoInfiltracaoMedido(tempoMin: 49, volumeMm: 10.44),
        const PontoInfiltracaoMedido(tempoMin: 64, volumeMm: 9.72),
        const PontoInfiltracaoMedido(tempoMin: 79, volumeMm: 9.00),
        const PontoInfiltracaoMedido(tempoMin: 89, volumeMm: 8.64),
        const PontoInfiltracaoMedido(tempoMin: 101, volumeMm: 8.28),
        const PontoInfiltracaoMedido(tempoMin: 119, volumeMm: 7.92),
        const PontoInfiltracaoMedido(tempoMin: 149, volumeMm: 7.92),
      ]);

      // K ≈ 35.2 (mm/h)
      expect(parametros.k, closeTo(35.2, 1.0));
      // n ≈ -0.311
      expect(parametros.n, closeTo(-0.311, 0.05));
      // K positivo
      expect(parametros.k, greaterThan(0));
      // n negativo (infiltração decrescente)
      expect(parametros.n, lessThan(0));
    });

    test('infiltração acumulada é crescente', () {
      final parametros = InfiltrationModel.ajustarCurva([
        const PontoInfiltracaoMedido(tempoMin: 2, volumeMm: 29.16),
        const PontoInfiltracaoMedido(tempoMin: 9, volumeMm: 18.00),
        const PontoInfiltracaoMedido(tempoMin: 19, volumeMm: 13.32),
        const PontoInfiltracaoMedido(tempoMin: 49, volumeMm: 10.44),
        const PontoInfiltracaoMedido(tempoMin: 79, volumeMm: 9.00),
        const PontoInfiltracaoMedido(tempoMin: 149, volumeMm: 7.92),
      ]);

      final i10 = InfiltrationModel.infiltracaoAcumulada(
        tempoMin: 10,
        parametros: parametros,
      );
      final i40 = InfiltrationModel.infiltracaoAcumulada(
        tempoMin: 40,
        parametros: parametros,
      );
      final i80 = InfiltrationModel.infiltracaoAcumulada(
        tempoMin: 80,
        parametros: parametros,
      );

      expect(i40, greaterThan(i10));
      expect(i80, greaterThan(i40));
    });

    test('infiltração acumulada §22: I = [K/(60*(n+1))] * T^(n+1)', () {
      // Com K≈35.2, n≈-0.311:
      // n+1 = 0.689
      // K/(60*(n+1)) = 35.2/(60*0.689) ≈ 0.851
      // I(60min) ≈ 0.851 * 60^0.689 ≈ 0.851 * 14.77 ≈ 12.57 mm
      final parametros = InfiltrationModel.ajustarCurva([
        const PontoInfiltracaoMedido(tempoMin: 2, volumeMm: 29.16),
        const PontoInfiltracaoMedido(tempoMin: 9, volumeMm: 18.00),
        const PontoInfiltracaoMedido(tempoMin: 19, volumeMm: 13.32),
        const PontoInfiltracaoMedido(tempoMin: 49, volumeMm: 10.44),
        const PontoInfiltracaoMedido(tempoMin: 79, volumeMm: 9.00),
        const PontoInfiltracaoMedido(tempoMin: 149, volumeMm: 7.92),
      ]);

      final i60 = InfiltrationModel.infiltracaoAcumulada(
        tempoMin: 60,
        parametros: parametros,
      );

      // I(60) deve ser positivo e razoável
      expect(i60, greaterThan(5));
      expect(i60, lessThan(30));
    });
  });

  group('ISSUE-016 — Caso milho §56: avanço', () {
    test('ajuste dois pontos com dados §56.5', () {
      final resultado = AdvanceCurveModel.ajustarDoisPontos(
        distanciaM: 200,
        tempoMin: 90,
        distanciaMetadeM: 100,
        tempoMetadeMin: 35,
        pontos: const [
          PontoEnsaio(distanciaM: 100, tempoMin: 35),
          PontoEnsaio(distanciaM: 200, tempoMin: 90),
        ],
      );

      // b = [ln(35) - ln(90)] / ln(0.5) ≈ 1.3626
      expect(resultado.b, closeTo(1.3626, 0.01));
      // k = 90 / 200^1.3626 ≈ 0.0659
      expect(resultado.k, closeTo(0.0659, 0.001));
    });

    test('tempo de avanço no final do sulco (§56.6)', () {
      final curva = AdvanceCurveModel.ajustarDoisPontos(
        distanciaM: 200,
        tempoMin: 90,
        distanciaMetadeM: 100,
        tempoMetadeMin: 35,
        pontos: const [
          PontoEnsaio(distanciaM: 100, tempoMin: 35),
          PontoEnsaio(distanciaM: 200, tempoMin: 90),
        ],
      );

      final tempoFinal = AdvanceCurveModel.tempoAvanco(
        distanciaM: 200,
        parametros: curva,
      );
      expect(tempoFinal, closeTo(90, 1));
    });

    test('distância em 53 min (§56.7)', () {
      final curva = AdvanceCurveModel.ajustarDoisPontos(
        distanciaM: 200,
        tempoMin: 90,
        distanciaMetadeM: 100,
        tempoMetadeMin: 35,
        pontos: const [
          PontoEnsaio(distanciaM: 100, tempoMin: 35),
          PontoEnsaio(distanciaM: 200, tempoMin: 90),
        ],
      );

      final distancia = AdvanceCurveModel.distanciaEmTempo(
        tempoMin: 53,
        parametros: curva,
      );
      // x = (53/k)^(1/b) ≈ (53/0.119)^(1/1.365) ≈ 131 m
      expect(distancia, greaterThan(100));
      expect(distancia, lessThan(200));
    });
  });

  group('ISSUE-016 — Caso milho §56: comparação 100m vs 200m', () {
    test('100m: Ea < 200m (menor tempo de oportunidade)', () {
      final r100 = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 100,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 17.5,
          tempoAvancoFinalMin: 45,
        ),
      );

      expect(r100.eficiencia, greaterThan(0));
      expect(r100.eficiencia, lessThan(80));
    });

    test('200m: Ea ≈ 57% (§56.9)', () {
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(resultado.eficiencia, closeTo(57, 5));
    });

    test('200m produz maior Ea que 100m (mesma vazão)', () {
      final r100 = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 100,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 17.5,
          tempoAvancoFinalMin: 45,
        ),
      );

      final r200 = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(r200.eficiencia, greaterThan(r100.eficiencia));
    });
  });

  group('ISSUE-016 — Caso milho §56: redução de vazão', () {
    test('redução para 0,75 L/s melhora Ea (§56.10)', () {
      final resultadoReduzido = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 0.75,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // Com vazão reduzida, não deve haver alerta de erosão
      expect(resultadoReduzido.alertaVazaoExcedida, isNull);

      // Ea deve ser melhor que com vazão de 1.5 L/s
      final resultadoOriginal = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(
        resultadoReduzido.eficiencia,
        greaterThan(resultadoOriginal.eficiencia),
      );
    });

    test('vazão reduzida ≤ vazão original', () {
      final qReduzida = FlowManagement.calcularVazaoReduzida(
        f0MmH: 4,
        comprimentoM: 200,
        espacamentoM: 0.9,
      );

      expect(qReduzida.vazaoReduzidaLs, greaterThan(0));
      expect(qReduzida.vazaoReduzidaLs, lessThan(1.5));
    });
  });

  group('ISSUE-016 — Caso milho §56: tempo de oportunidade', () {
    test('To > 0 no final do sulco (§56.8)', () {
      final curva = AdvanceCurveModel.ajustarDoisPontos(
        distanciaM: 200,
        tempoMin: 90,
        distanciaMetadeM: 100,
        tempoMetadeMin: 35,
        pontos: const [
          PontoEnsaio(distanciaM: 100, tempoMin: 35),
          PontoEnsaio(distanciaM: 200, tempoMin: 90),
        ],
      );

      final pontosAvanco = AdvanceCurveModel.gerarCurva(
        comprimentoM: 200,
        parametros: curva,
        amostras: 10,
      );

      final tempoCorte = 130.0 + 90.0; // To + Tx no final
      final pontosOportunidade = OpportunityTime.calcularPontos(
        tempoCorteMin: tempoCorte,
        pontosAvanco: pontosAvanco,
      );

      // Todos os pontos devem ter To >= 0
      for (final p in pontosOportunidade) {
        expect(p.ehNegativo, isFalse, reason: 'To não pode ser negativo');
      }
      // Último ponto (final do sulco) deve ter To > 0
      expect(pontosOportunidade.last.tempoMin, greaterThan(0));
    });
  });

  group('ISSUE-016 — Caso milho §56: profundidade e largura pendentes', () {
    test('cálculo de sulco funciona sem largura/profundidade do sulco', () {
      // O cálculo de sulco não requer largura/profundidade do sulco
      // apenas espaçamento entre sulcos
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9, // espaçamento, não largura do sulco
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // O resultado deve ser válido mesmo sem largura/profundidade do sulco
      expect(resultado.eficiencia, greaterThan(0));
      expect(resultado.perfilLongitudinal, isNotEmpty);
    });
  });

  group('ISSUE-016 — Caso milho §56: isolamento de equações', () {
    test(
      'parâmetros de infiltração do caso milho não misturados com outros',
      () {
        // Ensaio §19: VI em mm/h com dados de entrada/saída
        final parametrosEnsaio19 = InfiltrationModel.ajustarCurva([
          const PontoInfiltracaoMedido(tempoMin: 2, volumeMm: 29.16),
          const PontoInfiltracaoMedido(tempoMin: 9, volumeMm: 18.00),
          const PontoInfiltracaoMedido(tempoMin: 19, volumeMm: 13.32),
          const PontoInfiltracaoMedido(tempoMin: 49, volumeMm: 10.44),
          const PontoInfiltracaoMedido(tempoMin: 79, volumeMm: 9.00),
          const PontoInfiltracaoMedido(tempoMin: 149, volumeMm: 7.92),
        ]);

        // Outro ensaio hipotético com parâmetros diferentes
        final parametrosOutro = InfiltrationModel.ajustarCurva([
          const PontoInfiltracaoMedido(tempoMin: 5, volumeMm: 40.0),
          const PontoInfiltracaoMedido(tempoMin: 15, volumeMm: 30.0),
          const PontoInfiltracaoMedido(tempoMin: 30, volumeMm: 22.0),
          const PontoInfiltracaoMedido(tempoMin: 60, volumeMm: 16.0),
        ]);

        // Os parâmetros devem ser diferentes (ensaios distintos)
        expect(parametrosEnsaio19.k, isNot(closeTo(parametrosOutro.k, 1.0)));
        expect(parametrosEnsaio19.n, isNot(closeTo(parametrosOutro.n, 0.01)));

        // Cada um deve ter sua própria unidade
        expect(parametrosEnsaio19.unidadeK, isNotEmpty);
        expect(parametrosOutro.unidadeK, isNotEmpty);
      },
    );
  });

  group('ISSUE-016 — Caso milho §56: desempenho', () {
    test('classificações de Ea, CUC, DU', () {
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      // Classificações devem ser válidas
      expect(
        resultado.classificacaoEa,
        anyOf(
          equals('Excelente'),
          equals('Bom'),
          equals('Regular'),
          equals('Ruim'),
        ),
      );
      expect(
        resultado.classificacaoCuc,
        anyOf(
          equals('Excelente'),
          equals('Bom'),
          equals('Regular'),
          equals('Ruim'),
        ),
      );
      expect(
        resultado.classificacaoDu,
        anyOf(
          equals('Excelente'),
          equals('Bom'),
          equals('Regular'),
          equals('Ruim'),
        ),
      );
    });

    test('perda por percolação e escoamento são não negativas', () {
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(resultado.perdaPercolacao, greaterThanOrEqualTo(0));
      expect(resultado.perdaEscoamento, greaterThanOrEqualTo(0));
    });

    test('resumo textual contém informações', () {
      final resultado = RunFurrowSimulation()(
        const IrrigationParameters(
          comprimento: 200,
          declividade: 0.005,
          larguraOuEspacamento: 0.9,
          k: 2.83,
          a: 0.554,
          vib: 0.0001,
          vazao: 1.5,
          tempoAplicacao: 130,
          laminaRequerida: 42,
          tempoAvancoMetadeMin: 35,
          tempoAvancoFinalMin: 90,
        ),
      );

      expect(resultado.resumoTextual, isNotEmpty);
    });
  });

  group('ISSUE-016 — Caso milho §56: limites e validações', () {
    test('ea mínima aceitável é 60%', () {
      final limites = const LimitesDesempenho();
      expect(limites.eaMinimaAceitavel, closeTo(60, 0.001));
    });

    test('ea ideal é 75%', () {
      final limites = const LimitesDesempenho();
      expect(limites.eaIdeal, closeTo(75, 0.001));
    });

    test('pp limite é 15%', () {
      final limites = const LimitesDesempenho();
      expect(limites.ppLimite, closeTo(15, 0.001));
    });

    test('pe limite é 10%', () {
      final limites = const LimitesDesempenho();
      expect(limites.peLimite, closeTo(10, 0.001));
    });
  });

  group('ISSUE-016 — Caso milho §56: diagnóstico automático', () {
    test('gera diagnóstico para desempenho insatisfatório', () {
      final desempenho = const DesempenhoResultado(
        eficienciaAplicacao: 50,
        eficienciaDistribuicao: 80,
        eficienciaConducao: 90,
        eficienciaAdequacao: 70,
        perdaPercolacao: 5,
        perdaEscoamento: 45,
        laminaMediaInfiltrada: 0.05,
        laminaAplicada: 0.073,
        laminaRequerida: 0.042,
        classificacaoEa: 'Regular',
        classificacaoCuc: 'Bom',
        classificacaoDu: 'Bom',
      );

      final diagnosticos = DepthPerformance.diagnosticar(
        desempenho: desempenho,
      );
      expect(diagnosticos, isNotEmpty);
    });
  });
}
