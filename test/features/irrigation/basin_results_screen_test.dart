// Resultados de inundação (Fase 5 do plano): as seções Cultura e Clima
// auditam a origem de cada número com o vocabulário do plano de UI — "Não
// informado" para entrada ausente, "Não calculado" para derivado ausente e
// "Não aplicável" para o que não vale no regime (G4/G8); IRN informada e
// calculada coexistem sem sobrescrever (G14).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/services/cenarios/scenario_service.dart';
import 'package:irrigasim/services/persistence/local_scenario_store.dart';
import 'package:irrigasim/viewmodels/inundacao/basin_simulation_coordinator.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';
import 'package:irrigasim/views/irrigation/inundacao/basin_results_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpResultados(WidgetTester tester, BasinProject project) async {
    tester.view.physicalSize = const Size(1100, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = LocalScenarioStore();
    addTearDown(store.dispose);
    final result = const BasinSimulationCoordinator().executarProjeto(project);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resultsProvider.overrideWith(
            (ref) => ResultsController(ScenarioService(store)),
          ),
        ],
        child: MaterialApp(
          home: BasinResultsScreen(
            projectOverride: project,
            resultOverride: result,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('intermitente audita cultura, clima e a origem da IRN', (
    tester,
  ) async {
    await pumpResultados(tester, BasinProject.exemploAula8Intermitente());

    expect(find.text('Cultura e sistema radicular (p. 63)'), findsOneWidget);
    expect(find.text('Clima e demanda (p. 63)'), findsOneWidget);
    expect(find.text('ETc adotada (digitação)'), findsOneWidget);
    expect(find.text('Efetiva adotada'), findsOneWidget);
    expect(find.text('IRN efetiva (informada) (p. 63)'), findsOneWidget);
    expect(find.text('TR = IRN / (ETc − Pef) (p. 63)'), findsOneWidget);
    // IRN informada e calculada coincidem: o G14 só exibe as duas ao divergir.
    expect(find.text('IRN informada (prevalece, G14) (p. 63)'), findsNothing);
    expect(find.text('IRN calculada (auditoria, G14) (p. 63)'), findsNothing);
    expect(find.text('Não aplicável'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permanente marca IRN como não aplicável (G8) e traz o TR '
      'contínuo', (tester) async {
    await pumpResultados(tester, BasinProject.exemploAula8Permanente());

    expect(find.text('IRN'), findsOneWidget);
    expect(find.text('Não aplicável'), findsOneWidget);
    expect(
      find.textContaining(
        'O regime contínuo não usa a lâmina requerida intermitente (G8).',
      ),
      findsOneWidget,
    );
    expect(find.text('TR (turno de rega contínuo) (p. 67)'), findsOneWidget);
    expect(find.text('IRN efetiva (informada) (p. 63)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'entrada ausente vira "Não informado" e derivado "Não calculado"',
    (tester) async {
      // Carga de um mapa v1 sem agronomia nem ETc: nada disso vira zero (G4).
      final mapa = BasinProject.exemploAula8Permanente().toMap()
        ..remove('agronomia')
        ..remove('evapotranspiracao_mm_dia');
      await pumpResultados(tester, BasinProject.fromMap(mapa));

      expect(find.text('Não informado'), findsWidgets);
      expect(find.text('Não calculado'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
