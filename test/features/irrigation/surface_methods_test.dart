import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/inundacao/run_basin_simulation.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';
import 'package:irrigasim/services/simulation/inundacao/run_permanent_basin_simulation.dart';
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

  test('inundação intermitente reproduz o cenário de 5 L/s da planilha', () {
    final result = RunBasinSimulation()(
      IrrigationParameters(
        comprimento: 200,
        declividade: 0,
        larguraOuEspacamento: 400,
        k: 0.0034,
        a: 0.45,
        vib: 0.0001,
        vazao: 5,
        tempoAplicacao: 0,
        laminaRequerida: 56,
        manningN: 0.04,
        sigmaZ: 0.65,
      ),
    );

    expect(result.metricas['Tempo de avanço'], closeTo(45.61, 0.1));
    expect(result.metricas['Tempo de oportunidade'], closeTo(47.07, 0.1));
    expect(result.eficiencia, closeTo(79.31, 0.5));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('inundação permanente separa enchimento e manutenção', () {
    final result = RunPermanentBasinSimulation()(
      base().copyWith(tipoInundacao: TipoInundacao.permanente),
    );

    expect(result.metricas['Vazão de enchimento'], isPositive);
    expect(result.metricas['Vazão de manutenção'], isPositive);
    expect(result.metricas['Volume de enchimento'], isPositive);
  });
}
