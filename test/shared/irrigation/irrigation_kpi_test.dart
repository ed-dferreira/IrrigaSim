import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/core/widgets/kpi_card.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_kpi.dart';

void main() {
  const items = [
    IrrigationKpiItem(
      titulo: 'Eficiência Ea',
      valor: '82,4',
      unidade: '%',
      subtitulo: 'Água aproveitada',
      icon: Icons.water_drop_outlined,
    ),
    IrrigationKpiItem(
      titulo: 'Uniformidade CUC',
      valor: '91,2',
      unidade: '%',
      subtitulo: 'Christiansen',
    ),
    IrrigationKpiItem(
      titulo: 'Tempo de avanço',
      valor: '36',
      unidade: 'min',
      subtitulo: 'Até o final',
    ),
    IrrigationKpiItem(
      titulo: 'Lâmina média',
      valor: '48,7',
      unidade: 'mm',
      subtitulo: 'Infiltrada',
    ),
  ];

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IrrigationKpiGrid(items: items),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('IrrigationKpiGrid mantém 4 KPIs sem overflow em 360 px', (
    tester,
  ) async {
    await pumpAt(tester, 360);

    expect(find.byType(KpiCard), findsNWidgets(4));
    expect(find.text('Eficiência Ea'), findsOneWidget);
    expect(find.text('82,4'), findsOneWidget);
    expect(find.text('%'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('IrrigationKpiGrid usa até duas colunas em 700 px', (
    tester,
  ) async {
    await pumpAt(tester, 700);

    expect(find.byType(KpiCard), findsNWidgets(4));
    final primeiro = tester.getTopLeft(find.byType(KpiCard).at(0));
    final segundo = tester.getTopLeft(find.byType(KpiCard).at(1));
    final terceiro = tester.getTopLeft(find.byType(KpiCard).at(2));
    expect(segundo.dy, primeiro.dy);
    expect(segundo.dx, greaterThan(primeiro.dx));
    expect(terceiro.dy, greaterThan(primeiro.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('IrrigationKpiGrid usa três colunas em 1100 px', (
    tester,
  ) async {
    await pumpAt(tester, 1100);

    expect(find.byType(KpiCard), findsNWidgets(4));
    final primeiro = tester.getTopLeft(find.byType(KpiCard).at(0));
    final segundo = tester.getTopLeft(find.byType(KpiCard).at(1));
    final terceiro = tester.getTopLeft(find.byType(KpiCard).at(2));
    final quarto = tester.getTopLeft(find.byType(KpiCard).at(3));
    expect(segundo.dy, primeiro.dy);
    expect(terceiro.dy, primeiro.dy);
    expect(quarto.dy, greaterThan(primeiro.dy));
    expect(tester.takeException(), isNull);
  });
}
