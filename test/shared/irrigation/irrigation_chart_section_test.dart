import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_chart_section.dart';

void main() {
  testWidgets('IrrigationChartSection troca de aba e marca Semantics', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => IrrigationChartSection(
              title: 'Gráficos',
              tabs: const [
                IrrigationChartTab(
                  label: 'Avanço',
                  icon: Icons.timeline_rounded,
                ),
                IrrigationChartTab(
                  label: 'Infiltração',
                  icon: Icons.water_drop_outlined,
                ),
              ],
              selectedIndex: selected,
              onTabSelected: (index) => setState(() => selected = index),
              children: const [Text('Conteúdo A'), Text('Conteúdo B')],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gráficos'), findsOneWidget);
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      0,
    );

    await tester.tap(find.text('Infiltração'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      1,
    );
    final segundaAba = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Infiltração',
    );
    expect(
      tester.widget<Semantics>(segundaAba).properties.selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
