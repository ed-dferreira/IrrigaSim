import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_basin_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_border_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_furrow_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_permanent_basin_simulation.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';

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

  test('sulco calcula limite por textura e fecha o balanço', () {
    final result = RunFurrowSimulation()(base());

    expect(result.metricas['Vazão máxima não erosiva'], isPositive);
    expect(result.metricas['Tempo de aplicação calculado'], greaterThan(60));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('faixa usa avanço e recessão para formar o perfil', () {
    final result = RunBorderSimulation()(
      base().copyWith(
        comprimento: 200,
        declividade: 0.005,
        larguraOuEspacamento: 8,
        vazao: 1.8,
        tempoAplicacao: 142,
        tempoAvancoMetadeMin: 30,
        tempoAvancoFinalMin: 90,
        instanteRecessaoInicioMin: 160,
        instanteRecessaoFinalMin: 210,
      ),
    );

    expect(
      result.perfilLongitudinal.first,
      greaterThan(result.perfilLongitudinal.last),
    );
    expect(result.metricas['Vazão total da faixa'], closeTo(14.4, 0.001));
    expectPhysicalBalance(
      result.eficiencia,
      result.perdaPercolacao,
      result.perdaEscoamento,
    );
  });

  test('inundação intermitente calcula aplicação sem rugosidade', () {
    final result = RunBasinSimulation()(
      base().copyWith(
        comprimento: 100,
        declividade: 0.0005,
        larguraOuEspacamento: 20,
        vazao: 100,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 45,
      ),
    );

    expect(result.metricas['Fim da depleção'], greaterThan(45));
    expect(result.metricas['Volume aplicado'], isPositive);
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
