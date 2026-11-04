import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('showIrrigationExportSheet mostra o CSV e copia ao confirmar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showIrrigationExportSheet(
                  context,
                  title: 'Prévia do CSV',
                  description: 'Confira o conteúdo antes de copiar.',
                  csv: 'grupo;indicador;valor;unidade\nresultado;Ea;82,4;%',
                ),
                child: const Text('Abrir exportação'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir exportação'));
    await tester.pumpAndSettle();

    expect(find.text('Prévia do CSV'), findsOneWidget);
    expect(find.text('Confira o conteúdo antes de copiar.'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('resultado;Ea;82,4'), findsOneWidget);

    await tester.tap(find.text('Copiar CSV'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsNothing);
    expect(find.textContaining('CSV copiado'), findsOneWidget);
  });
}
