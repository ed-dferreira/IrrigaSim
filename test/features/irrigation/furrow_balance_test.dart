import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result_model.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';
import 'package:irrigasim/services/simulation/surface_irrigation_math.dart';

void main() {
  test(
    'perfil não linear fecha as três identidades sem confundir Ea slide',
    () {
      final balance = SurfaceIrrigationMath.balance(
        profileM: [0.02, 0.05, 0.09],
        requiredDepthM: 0.04,
        appliedDepthM: 0.08,
      );
      expect(balance.meanInfiltratedDepthM, closeTo(0.0525, 1e-12));
      expect(balance.usefulDepthM, closeTo(0.035, 1e-12));
      expect(balance.percolatedDepthM, closeTo(0.0175, 1e-12));
      expect(balance.deficitDepthM, closeTo(0.005, 1e-12));
      expect(balance.runoffDepthM, closeTo(0.0275, 1e-12));
      expect(balance.applicationEfficiency, closeTo(43.75, 1e-10));
      expect(
        balance.usefulDepthM + balance.percolatedDepthM,
        closeTo(balance.meanInfiltratedDepthM, 1e-12),
      );
      expect(
        balance.usefulDepthM + balance.deficitDepthM,
        closeTo(0.04, 1e-12),
      );
      expect(
        balance.usefulDepthM + balance.percolatedDepthM + balance.runoffDepthM,
        closeTo(0.08, 1e-12),
      );
    },
  );

  test('perfil abaixo da IRN preserva déficit sem Pp integral', () {
    final balance = SurfaceIrrigationMath.balance(
      profileM: [0.01, 0.02, 0.03],
      requiredDepthM: 0.04,
      appliedDepthM: 0.05,
    );
    expect(balance.deepPercolationPercent, 0);
    expect(balance.deficitDepthM, closeTo(0.02, 1e-12));
    expect(
      balance.applicationEfficiency + balance.runoffPercent,
      closeTo(100, 1e-10),
    );
  });

  test('infiltração superior ao volume aplicado é balanço inconsistente', () {
    expect(
      () => SurfaceIrrigationMath.balance(
        profileM: [0.05001, 0.05001],
        requiredDepthM: 0.04,
        appliedDepthM: 0.05,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'motivo',
          contains('Balanço inconsistente'),
        ),
      ),
    );
  });

  test('sulco deficitário não publica Pp slide negativa como perda', () {
    final result = RunFurrowSimulation()(
      const IrrigationParameters(
        comprimento: 100,
        declividade: 0.002,
        larguraOuEspacamento: 0.8,
        k: 0.5,
        a: 0.5,
        vib: 0.0001,
        vazao: 1,
        tempoAplicacao: 120,
        laminaRequerida: 60,
      ),
    );
    expect(result.balancoSulco!.ppSlide, isNull);
    expect(result.balancoSulco!.deficitMm, greaterThan(0));
    expect(result.perdaPercolacao, 0);
    expect(result.metricas.containsKey('Pp slide (Lmi−IRN)/Lm'), isFalse);
  });

  test(
    'resultado separa slide e integral e conserva indicadores na restauração',
    () {
      final result = RunFurrowSimulation()(
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
      final b = result.balancoSulco!;
      expect(b.eaSlide, closeTo(result.eficiencia, 1e-10));
      expect(b.eaIntegral, isNot(closeTo(b.eaSlide, 0.01)));
      expect(b.ppSlide, isNotNull);
      expect(
        b.laminaInfiltradaMm,
        closeTo(b.laminaUtilMm + b.laminaPercoladaMm, 1e-8),
      );
      expect(
        b.laminaUtilMm + b.laminaPercoladaMm + b.laminaEscoadaMm,
        closeTo(result.laminaAplicadaMediaMm!, 1e-8),
      );
      expect(
        SimulationResultModel.fromMap(SimulationResultModel.toMap(result))
            .balancoSulco!
            .toMap(),
        b.toMap(),
      );
    },
  );
}
