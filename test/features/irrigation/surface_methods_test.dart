import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/inundacao/run_basin_simulation.dart';
import 'package:irrigasim/services/simulation/inundacao/basin_reference_math.dart';
import 'package:irrigasim/services/simulation/inundacao/basin_planning.dart';
import 'package:irrigasim/services/simulation/inundacao/rice_volumes_service.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';
import 'package:irrigasim/services/simulation/inundacao/run_permanent_basin_simulation.dart';
import 'package:irrigasim/viewmodels/inundacao/basin_simulation_coordinator.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

void main() {
  IrrigationParameters base() => const IrrigationParameters(
    comprimento: 100,
    declividade: 0.002,
    larguraOuEspacamento: 0.8,
    k: 0.005,
    a: 0.5,
    vib: 0.0001,
    vazao: 1,
    tempoAplicacao: 120,
    laminaRequerida: 60,
  );

  void expectPhysicalBalance(
    double efficiency,
    double percolation,
    double runoff,
  ) {
    expect(efficiency, inInclusiveRange(0, 100));
    expect(percolation, inInclusiveRange(0, 100));
    expect(runoff, inInclusiveRange(0, 100));
    expect(efficiency + percolation + runoff, closeTo(100, 0.01));
  }

  test('a seleção do método não volta automaticamente para sulco', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(parametersProvider.notifier)
        .setMetodo(MetodoIrrigacao.faixa);

    expect(container.read(parametersProvider).metodo, MetodoIrrigacao.faixa);
  });

  test('sulco calcula limite não erosivo e fecha o balanço', () {
    final result = RunFurrowSimulation()(base());

    expect(result.metricas['Vazão máxima não erosiva'], isPositive);
    expect(result.metricas['Tempo de aplicação calculado'], greaterThan(60));
    expectPhysicalBalance(
      result.balancoSulco!.eaIntegral,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('sulco reproduz as fórmulas da planilha de referência', () {
    final result = RunFurrowSimulation()(
      base().copyWith(
        comprimento: 200,
        declividade: 0.005,
        larguraOuEspacamento: 0.9,
        k: 2.83,
        a: 0.554,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      ),
    );

    expect(result.metricas['Vazão máxima não erosiva'], closeTo(1.02, 0.01));
    expect(result.metricas['Tempo de aplicação calculado'], 220);
    expect(result.metricas['Lâmina aplicada'], closeTo(73.3333, 0.001));
    expect(result.eficiencia, closeTo(57.2281, 0.001));
    expect(
      result.metricas['Eficiência de distribuição'],
      closeTo(85.5295, 0.001),
    );
    expect(result.perfilLongitudinal.first * 1000, closeTo(56.1680, 0.001));
    expect(result.perfilLongitudinal.last * 1000, closeTo(41.9673, 0.001));
  });

  test('faixa usa avanço e recessão para formar o perfil', () {
    final result = RunBorderSimulation()(
      base().copyWith(
        comprimento: 400,
        declividade: 0.001,
        larguraOuEspacamento: 50,
        k: 0.0034,
        a: 0.45,
        vib: 0.0001,
        vazao: 1.8,
        laminaRequerida: 56,
        manningN: 0.04,
        sigmaZ: 0.66,
      ),
    );

    expect(
      result.perfilLongitudinal.first,
      greaterThan(result.perfilLongitudinal.last),
    );
    expect(result.metricas['Vazão total da faixa'], closeTo(90, 0.001));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test(
    'faixa calcula cenário com resíduos e balanço integral, sem F02 presumida',
    () {
      final result = RunBorderSimulation()(
        base().copyWith(
          comprimento: 400,
          declividade: 0.001,
          larguraOuEspacamento: 50,
          k: 0.0034,
          a: 0.45,
          vib: 0.0001,
          vazao: 1.8,
          laminaRequerida: 56,
          manningN: 0.04,
          sigmaZ: 0.66,
        ),
      );

      expect(result.metricas.containsKey('Vazão unitária máxima'), isFalse);
      expect(
        result.metricas['Tempo de oportunidade'],
        closeTo(195.13612, 0.001),
      );
      expect(result.borderResult!.residualAvancoM3M, lessThan(0.00001));
      expect(
        result.borderResult!.tiMin,
        greaterThanOrEqualTo(result.tempoAvanco),
      );
      expectPhysicalBalance(
        result.eficiencia,
        result.perdaPercolacao,
        result.perdaEscoamento,
      );
    },
  );

  test('inundação intermitente reproduz o cenário da Aula 8 (Q0 = Q0max)', () {
    // Hidráulica por unidade de largura: a vazão total é distribuída pela
    // largura do tabuleiro (400 m) e reproduz Q0max da referência.
    final q0Max = vazaoMaxima(8, 0.04, 200);
    final result = RunBasinSimulation()(
      IrrigationParameters(
        comprimento: 200,
        declividade: 0,
        larguraOuEspacamento: 400,
        k: 0.0035,
        a: 0.47,
        vib: 0.00011,
        vazao: q0Max * 400 * 1000 / 60,
        tempoAplicacao: 0,
        laminaRequerida: 56,
        manningN: 0.04,
      ),
    );

    expect(result.metricas['Vazão unitária Q0'], closeTo(q0Max, 1e-12));
    expect(result.metricas['Tempo de avanço'], closeTo(22.029325408, 1e-5));
    expect(
      result.metricas['Tempo de oportunidade'],
      closeTo(22.029325408, 1e-5),
    );
    expect(result.eficiencia, closeTo(58.244903448, 1e-5));
    expect(result.metricas['Resíduo do balanço'], lessThan(1e-7));
    expect(result.metricas['Expoente do avanço'], closeTo(0.782063632, 1e-6));
    expect(result.perfilLongitudinal, hasLength(41));
    expect(result.alertaVazaoExcedida, isNull);
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('inundação intermitente reproduz a 3ª irrigação da Aula 8', () {
    // Solo da terceira irrigação: k=0,0034, a=0,45, VIB=0,0001 (mesmo Q0max).
    final q0Max = vazaoMaxima(8, 0.04, 200);
    final result = RunBasinSimulation()(
      IrrigationParameters(
        comprimento: 200,
        declividade: 0,
        larguraOuEspacamento: 400,
        k: 0.0034,
        a: 0.45,
        vib: 0.00010,
        vazao: q0Max * 400 * 1000 / 60,
        tempoAplicacao: 0,
        laminaRequerida: 56,
        manningN: 0.04,
      ),
    );

    expect(result.metricas['Vazão unitária Q0'], closeTo(q0Max, 1e-12));
    expect(result.metricas['Tempo de avanço'], closeTo(21.795724240, 1e-5));
    expect(
      result.metricas['Tempo de oportunidade'],
      closeTo(21.795724240, 1e-5),
    );
    expect(result.eficiencia, closeTo(58.869157882, 1e-5));
    expect(result.metricas['Expoente do avanço'], closeTo(0.785833943, 1e-6));
    expect(result.metricas['Resíduo do balanço'], lessThan(1e-7));
    expect(result.perfilLongitudinal, hasLength(41));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('inundação alerta a vazão total acima de Q0max × largura', () {
    final q0Max = vazaoMaxima(8, 0.04, 200);
    final result = RunBasinSimulation()(
      IrrigationParameters(
        comprimento: 200,
        declividade: 0,
        larguraOuEspacamento: 400,
        k: 0.0035,
        a: 0.47,
        vib: 0.00011,
        vazao: (q0Max + 0.05) * 400 * 1000 / 60,
        tempoAplicacao: 0,
        laminaRequerida: 56,
        manningN: 0.04,
      ),
    );

    expect(result.alertaVazaoExcedida, isNotNull);
    expect(result.tempoAvanco, greaterThan(0));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('inundação rejeita vazão insuficiente com FormatException', () {
    expect(
      () => RunBasinSimulation()(
        IrrigationParameters(
          comprimento: 200,
          declividade: 0,
          larguraOuEspacamento: 400,
          k: 0.0035,
          a: 0.47,
          vib: 0.00011,
          vazao: 0.5,
          tempoAplicacao: 0,
          laminaRequerida: 56,
          manningN: 0.04,
        ),
      ),
      throwsFormatException,
    );
  });

  test('inundação permanente separa enchimento e manutenção', () {
    final result = RunPermanentBasinSimulation()(
      base().copyWith(tipoInundacao: TipoInundacao.permanente),
    );

    expect(result.metricas['Vazão de enchimento'], isPositive);
    expect(result.metricas['Vazão de manutenção'], isPositive);
    expect(result.metricas['Volume de enchimento'], isPositive);
    // Las/Ea semanais (p. 72) e Ec = 100 Qm/Qd.
    final qm = result.metricas['Vazão de manutenção']!;
    final qd = result.metricas['Vazão disponível']!;
    final las = result.metricas['Lâmina aplicada por semana Las']!;
    final les = result.metricas['Lâmina evapotranspirada por semana Les']!;
    final ea = result.metricas['Eficiência de aplicação Ea']!;
    expect(
      result.metricas['Eficiência de condução'],
      closeTo(100 * qm / qd, 1e-9),
    );
    expect(las, greaterThan(les));
    expect(ea, closeTo(100 * les / las, 1e-9));
    expect(ea, inInclusiveRange(0, 100));
    expect(result.metricas['Checagem operacional - vazão'], 1.0);
    expect(result.metricas['Checagem operacional - geometria'], 1.0);
    expect(result.alertaVazaoExcedida, isNull);
  });

  test('inundação permanente valida declividade < 2% (G9)', () {
    expect(
      () => RunPermanentBasinSimulation()(
        base().copyWith(
          tipoInundacao: TipoInundacao.permanente,
          declividade: 0.03,
        ),
      ),
      throwsFormatException,
    );
  });

  test('inundação permanente alerta geometria acima da área (G3)', () {
    final result = RunPermanentBasinSimulation()(
      base().copyWith(
        tipoInundacao: TipoInundacao.permanente,
        comprimento: 400,
        larguraOuEspacamento: 400,
        areaHectares: 2,
      ),
    );

    expect(result.metricas['Checagem operacional - geometria'], 0.0);
    expect(result.alertaVazaoExcedida, contains('excede a área'));
  });

  test('volumes do arroz preservam lacunas da p. 84 e completam com dados', () {
    const service = RiceVolumesService();
    final parcial = service.solucaoPagina84();
    expect(parcial.pt, closeTo(0.528301887, 1e-9));
    expect(parcial.us, closeTo(0.422641509, 1e-9));
    expect(parcial.v2M3Ha, closeTo(700, 1e-9));
    expect(parcial.v3M3Ha, closeTo(8000, 1e-9));
    expect(parcial.v4M3Ha, closeTo(670, 1e-9));
    expect(parcial.v1M3Ha, isNull);
    expect(parcial.v5M3Ha, isNull);
    expect(parcial.vtM3Ha, isNull);
    expect(parcial.q1M3S, isNull);
    expect(parcial.q2M3S, isNull);
    expect(parcial.dadosAusentes, isNotEmpty);

    final completo = service.solucaoPagina84(
      uaGravimetrica: 0.1,
      massaSacoKg: 60,
      areaHa: 10,
      tdDias: 5,
      trDias: 95,
    );
    // V1 = 3169,811321 − 7500·Ua; MS = 947,43·massa; V5 = 378,972·massa.
    expect(completo.v1M3Ha, closeTo(3169.8113207547167 - 7500 * 0.1, 1e-6));
    expect(completo.materiaSecaTotalKgHa, closeTo(947.43 * 60, 1e-6));
    expect(completo.v5M3Ha, closeTo(378.972 * 60, 1e-6));
    expect(
      completo.vtM3Ha,
      closeTo(completo.v1M3Ha! + 700 + 8000 + 670 + completo.v5M3Ha!, 1e-6),
    );
    // Q1/Q2 em m³/s pela fórmula da aula.
    expect(
      completo.q1M3S,
      closeTo((completo.v1M3Ha! + 700) * 10 / (5 * 86400), 1e-12),
    );
    expect(
      completo.q2M3S,
      closeTo((8000 + 670 + completo.v5M3Ha!) * 10 / (95 * 86400), 1e-12),
    );
    expect(completo.dadosAusentes, isEmpty);
    // Conversão volumétrica → gravimétrica (p. 76).
    expect(
      RiceVolumesService.umidadeGravimetrica(0.25, 1.25),
      closeTo(0.2, 1e-12),
    );
    // Forma volumétrica equivalente de V1: (PT − u)·PCI·10000.
    expect(
      RiceVolumesService.v1PorUmidadeVolumetrica(
        pt: 0.5283018867924528,
        umidadeVolumetricaInicial: 0.25,
        pciM: 0.60,
      ),
      closeTo(3169.8113207547167 - 7500 * 0.2, 1e-6),
    );
  });

  test(
    'planejamento em parcelas reproduz o caso operacional de referência',
    () {
      const planning = BasinPlanning();
      final op = planning.planejarParcelas(
        areaTotalM2: 80000,
        comprimentoM: 200,
        tabuleirosPorParcela: 2,
        q0M3MinM: 0.5,
        tiMin: 30,
        jornadaDiariaH: 8,
        tempoMudancaParcelaMin: 10,
        periodoIrrigacaoDias: 1,
      );

      expect(op.npdInteiro, 12);
      expect(op.ntt, 24);
      expect(op.qTotalLS, closeTo(277.77777777777777, 1e-9));
      expect(op.tppMin, 40);
      expect(op.appM2, closeTo(80000 / 12, 1e-9));
      expect(op.larguraTabuleiroM, closeTo((80000 / 12) / (2 * 200), 1e-9));
      expect(
        () => planning.planejarParcelas(
          areaTotalM2: 100,
          comprimentoM: 10,
          tabuleirosPorParcela: 1,
          q0M3MinM: 0.1,
          tiMin: 60,
          jornadaDiariaH: 0.5,
          tempoMudancaParcelaMin: 0,
          periodoIrrigacaoDias: 1,
        ),
        throwsFormatException,
      );
    },
  );

  test('checagem operacional G3 compara vazão e geometria', () {
    const planning = BasinPlanning();
    final ok = planning.checarOperacao(
      vazaoPlanejadaLs: 30,
      vazaoDisponivelLs: 36,
      areaTabuleiroM2: 80000,
      areaDeclaradaM2: 80000,
    );
    expect(ok.viavel, isTrue);
    expect(ok.motivo, isNull);

    final semVazao = planning.checarOperacao(
      vazaoPlanejadaLs: 40,
      vazaoDisponivelLs: 36,
      areaTabuleiroM2: 80000,
      areaDeclaradaM2: 80000,
    );
    expect(semVazao.atendeVazao, isFalse);
    expect(semVazao.viavel, isFalse);
    expect(semVazao.motivo, contains('vazão'));

    final semArea = planning.checarOperacao(
      vazaoPlanejadaLs: 30,
      vazaoDisponivelLs: 36,
      areaTabuleiroM2: 90000,
      areaDeclaradaM2: 80000,
    );
    expect(semArea.geometriaCabeNaArea, isFalse);
    expect(semArea.motivo, contains('área'));
  });

  test('intermitente preenche a checagem operacional G3 na coordenação', () {
    final result = const BasinSimulationCoordinator().executarProjeto(
      BasinProject.exemploAula8Intermitente(),
    );

    expect(result.checagemOperacional, isNotNull);
    expect(result.checagemOperacional!.viavel, isTrue);
    expect(result.metricas['Checagem operacional - vazão'], 1.0);
    expect(result.metricas['Checagem operacional - geometria'], 1.0);
    expect(result.alertaVazaoExcedida, isNull);
  });

  test('intermitente com vazão acima da disponível sinaliza G3', () {
    final result = const BasinSimulationCoordinator().executarProjeto(
      BasinProject.exemploAula8Intermitente().copyWith(vazaoTotalLs: 900),
    );

    expect(result.checagemOperacional, isNotNull);
    expect(result.checagemOperacional!.atendeVazao, isFalse);
    expect(result.checagemOperacional!.viavel, isFalse);
    expect(result.metricas['Checagem operacional - vazão'], 0.0);
    expect(result.alertaVazaoExcedida, contains('vazão'));
  });

  test('dimensionamento aceita r inicial alternativo e valida o domínio', () {
    final solo = Infiltracao(0.0035, 0.47, 0.00011);
    final padrao = dimensionar(
      solo,
      l: 200,
      n: 0.04,
      irn: 0.056,
      vazao: 0.8728887470978953,
    );
    final partida = dimensionar(
      solo,
      l: 200,
      n: 0.04,
      irn: 0.056,
      vazao: 0.8728887470978953,
      rInicial: 0.3,
    );

    expect(partida.r, closeTo(padrao.r, 1e-6));
    expect(() => dimensionar(solo, rInicial: 0), throwsArgumentError);
  });
}
