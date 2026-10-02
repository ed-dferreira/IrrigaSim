import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';

void main() {
  const trial = BorderFieldTrial();
  const stakes = [
    BorderStake(0, 0, recessaoMin: 80),
    BorderStake(20, 10, recessaoMin: 85),
    BorderStake(40, 20, recessaoMin: 90),
    BorderStake(60, 30, recessaoMin: 95),
  ];
  test('ajuste de campo não extrapola e preserva pontos', () {
    final curve = trial.fit(stakes);
    expect(curve.r, closeTo(1, 1e-8));
    expect(curve.rmseMin, closeTo(0, 1e-8));
    expect(curve.arrival(40), closeTo(20, 1e-8));
    expect(() => curve.arrival(70), throwsFormatException);
    expect(curve.stakes.length, 4);
  });
  test('ensaio sem corte não anuncia Ea, mas fornece perfil medido', () {
    final project = BorderProject.ilustrativo.copyWith(comprimentoM: 60);
    final result = trial.evaluate(project, stakes);
    expect(result.ea, isNull);
    expect(result.profile.length, 401);
    final at15 = result.profile.firstWhere(
      (point) => (point.xM - 15).abs() < 1e-8,
    );
    expect(at15.recessaoMin, closeTo(83.75, 1e-8));
    expect(at15.avancoMin, closeTo(7.5, 1e-8));
    final withCut = trial.evaluate(project, stakes, cutoffMin: 30);
    expect(result.avisos.map((n) => n.status),
        contains(BorderStatus.avisoOrientativo));
    expect(withCut.entradaM3M, greaterThan(0));
    expect(withCut.deficitM3M, greaterThan(0));
    expect(
      withCut.utilM3M! + withCut.percoladoM3M! + withCut.escoadoM3M!,
      closeTo(withCut.entradaM3M!, 1e-8),
    );
  });

  test('avisos do ensaio carregam código canônico e página', () {
    final project = BorderProject.ilustrativo.copyWith(comprimentoM: 60);
    final semRecessao = trial.evaluate(
      project,
      const [
        BorderStake(0, 0),
        BorderStake(20, 10),
        BorderStake(40, 20),
        BorderStake(60, 30),
      ],
    );
    expect(semRecessao.status, BorderStatus.avisoOrientativo);
    final csv = borderTrialCsv(project, semRecessao);
    expect(csv, contains('status;aviso_orientativo;'));
    expect(csv, contains('[aviso_orientativo]'));
    expect(
      semRecessao.avisos.any(
        (n) => n.status == BorderStatus.avisoOrientativo && n.pagina != null,
      ),
      isTrue,
    );

    final completo = trial.evaluate(
      project,
      const [
        BorderStake(0, 0, recessaoMin: 80),
        BorderStake(20, 10, recessaoMin: 85),
        BorderStake(40, 20, recessaoMin: 90),
        BorderStake(60, 30, recessaoMin: 95),
      ],
      cutoffMin: 30,
    );
    expect(completo.avisos, isEmpty);
    expect(completo.status, BorderStatus.validoNoModelo);

    expect(
      () => trial.evaluate(
        project,
        const [
          BorderStake(0, 0, recessaoMin: 80),
          BorderStake(20, 10, recessaoMin: 85),
          BorderStake(40, 20, recessaoMin: 90),
        ],
      ),
      throwsA(
        isA<BorderModelException>().having(
          (e) => e.status,
          'status',
          BorderStatus.entradaInvalida,
        ),
      ),
    );
  });
}
