import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

void main() {
  Widget field(String label) => IrrigationLabeledField(
    label: label,
    child: Text('campo $label'),
  );

  Future<void> pumpGrid(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IrrigationFieldGrid(
              fields: [
                field('A'),
                field('B'),
                field('C'),
                field('D'),
                const Text('Conteúdo de largura total'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('IrrigationFieldGrid fica em uma coluna em 390 px', (
    tester,
  ) async {
    await pumpGrid(tester, 390);

    final primeiro = tester.getTopLeft(find.byType(IrrigationLabeledField).at(0));
    final segundo = tester.getTopLeft(find.byType(IrrigationLabeledField).at(1));
    expect(segundo.dx, primeiro.dx);
    expect(segundo.dy, greaterThan(primeiro.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('IrrigationFieldGrid usa até três colunas em 1100 px', (
    tester,
  ) async {
    await pumpGrid(tester, 1100);

    final a = tester.getTopLeft(find.byType(IrrigationLabeledField).at(0));
    final b = tester.getTopLeft(find.byType(IrrigationLabeledField).at(1));
    final c = tester.getTopLeft(find.byType(IrrigationLabeledField).at(2));
    final d = tester.getTopLeft(find.byType(IrrigationLabeledField).at(3));
    expect(b.dy, a.dy);
    expect(c.dy, a.dy);
    expect(d.dy, greaterThan(a.dy));
    final larguraTexto = tester.getSize(find.text('Conteúdo de largura total'));
    expect(larguraTexto.width, greaterThan(1000));
    expect(tester.takeException(), isNull);
  });

  testWidgets('IrrigationStepNavigation preserva rótulos e estados', (
    tester,
  ) async {
    var anterior = 0;
    var proximo = 0;
    var confirmar = 0;
    var calcular = 0;

    Widget navigation({
      required bool isFirst,
      required bool isLast,
      required bool isConfirmed,
      required bool canCalculate,
    }) => MaterialApp(
      home: Scaffold(
        body: IrrigationStepNavigation(
          isFirst: isFirst,
          isLast: isLast,
          isConfirmed: isConfirmed,
          isBusy: false,
          canCalculate: canCalculate,
          onPrevious: () => anterior++,
          onConfirm: () => confirmar++,
          onNext: () => proximo++,
          onCalculate: () => calcular++,
        ),
      ),
    );

    await tester.pumpWidget(
      navigation(
        isFirst: true,
        isLast: false,
        isConfirmed: false,
        canCalculate: false,
      ),
    );
    expect(find.text('Voltar'), findsNothing);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Próximo'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.tap(find.text('Próximo'));
    expect(confirmar, 1);
    expect(proximo, 1);

    await tester.pumpWidget(
      navigation(
        isFirst: false,
        isLast: false,
        isConfirmed: true,
        canCalculate: true,
      ),
    );
    expect(find.text('Voltar'), findsOneWidget);
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);
    await tester.tap(find.text('Voltar'));
    expect(anterior, 1);

    await tester.pumpWidget(
      navigation(
        isFirst: false,
        isLast: true,
        isConfirmed: false,
        canCalculate: false,
      ),
    );
    expect(find.text('Confirmar'), findsNothing);
    final botao = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Calcular projeto'),
    );
    expect(botao.onPressed, isNull);
    await tester.pumpWidget(
      navigation(
        isFirst: false,
        isLast: true,
        isConfirmed: false,
        canCalculate: true,
      ),
    );
    await tester.tap(find.text('Calcular projeto'));
    expect(calcular, 1);
  });
}
