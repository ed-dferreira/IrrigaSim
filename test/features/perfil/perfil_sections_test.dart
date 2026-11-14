import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/features/perfil/perfil.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPerfil(
  WidgetTester tester, {
  List<CenarioSalvo> cenarios = const [],
  Size size = const Size(800, 900),
}) async {
  SharedPreferences.setMockInitialValues({});
  await PreferenciasApp.init();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cenariosProvider.overrideWith((ref) => Stream.value(cenarios)),
      ],
      child: const MaterialApp(home: PerfilScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('perfil organiza configurações, cálculos e sobre em seções', (
    tester,
  ) async {
    await _pumpPerfil(tester);

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Cálculos'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Sobre o IrrigaSim'), findsOneWidget);
  });

  testWidgets('cálculos fica abaixo do sobre e abre em um único card', (
    tester,
  ) async {
    await _pumpPerfil(tester);

    final sobre = tester.getTopLeft(find.text('Sobre')).dy;
    final calculos = tester.getTopLeft(find.text('Cálculos')).dy;
    expect(calculos, greaterThan(sobre));

    expect(find.text('IRN calculada'), findsNothing);
    await tester.ensureVisible(find.text('Cálculos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cálculos'));
    await tester.pumpAndSettle();

    expect(find.text('IRN calculada'), findsOneWidget);
    expect(find.text('Sulcos'), findsWidgets);
  });

  testWidgets('perfil mostra o total e o método favorito dos cenários', (
    tester,
  ) async {
    await _pumpPerfil(
      tester,
      cenarios: [
        _cenario(MetodoIrrigacao.faixa, DateTime(2026, 1, 1)),
        _cenario(MetodoIrrigacao.faixa, DateTime(2026, 1, 2)),
        _cenario(MetodoIrrigacao.sulco, DateTime(2026, 1, 3)),
      ],
    );

    final totalCard = find.ancestor(
      of: find.text('Simulações salvas'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: totalCard, matching: find.text('3')),
      findsOneWidget,
    );

    final favoriteCard = find.ancestor(
      of: find.text('Método favorito'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: favoriteCard, matching: find.text('Faixas')),
      findsOneWidget,
    );
  });

  testWidgets('sobre usa duas colunas no desktop e uma no celular', (
    tester,
  ) async {
    await _pumpPerfil(tester, size: const Size(1200, 900));

    final desktopDev = tester.getTopLeft(find.text('Desenvolvido por')).dy;
    final desktopInstituicao = tester.getTopLeft(find.text('Instituição')).dy;
    expect(desktopDev, lessThan(desktopInstituicao));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpPerfil(tester, size: const Size(360, 800));

    final mobileDev = tester.getTopLeft(find.text('Desenvolvido por')).dy;
    final mobileInstituicao = tester.getTopLeft(find.text('Instituição')).dy;
    expect(mobileDev, greaterThan(mobileInstituicao));
    expect(tester.takeException(), isNull);
  });
}

CenarioSalvo _cenario(MetodoIrrigacao metodo, DateTime modificado) {
  return CenarioSalvo(
    id: '${metodo.name}-${modificado.microsecondsSinceEpoch}',
    nome: 'Cenário ${metodo.name}',
    metodo: metodo,
    parametros: const IrrigationParameters(
      comprimento: 100,
      declividade: 0.01,
      larguraOuEspacamento: 1,
      k: 1,
      a: 1,
      vib: 1,
      vazao: 1,
      tempoAplicacao: 60,
      laminaRequerida: 50,
    ),
    resultado: const SimulationResult(
      eficiencia: .8,
      eficienciaRequerimento: .8,
      cuc: .8,
      du: .8,
      laminaMedia: 50,
      laminaRequerida: 50,
      tempoAvanco: 60,
      perdaPercolacao: 0,
      perdaEscoamento: 0,
      curvaAvanco: [],
      perfilLongitudinal: [],
      resumoTextual: '',
    ),
    dataCriacao: modificado,
    dataModificacao: modificado,
  );
}
