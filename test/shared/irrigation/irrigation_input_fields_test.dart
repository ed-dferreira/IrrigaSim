import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';

Widget _envoltorio(Widget child) => MaterialApp(
  home: Scaffold(body: Form(child: ListView(children: [child]))),
);

enum TipoRega { continuo, intermitente, esporadico }

void main() {
  testWidgets('IrrigationNumberField aceita vírgula, ponto e vazio opcional', (
    tester,
  ) async {
    final valores = <String>[];
    String? validador(String? texto) =>
        double.tryParse(texto!.replaceAll(',', '.')) == null
        ? 'Informe um número válido'
        : null;

    await tester.pumpWidget(
      _envoltorio(
        IrrigationNumberField(
          label: 'Comprimento',
          value: 12.5,
          unit: 'm',
          optional: true,
          helper: 'Opcional; vazio = não informado',
          fieldKey: const ValueKey('comprimento'),
          onChanged: valores.add,
          validator: validador,
        ),
      ),
    );

    // Valor inicial formatado sem zeros finais e com o sufixo da unidade.
    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '3,75');
    expect(valores.single, '3,75');
  });

  testWidgets('IrrigationNumberField reflete rebuild com key nova', (
    tester,
  ) async {
    final valores = <String>[];
    await tester.pumpWidget(
      _envoltorio(
        IrrigationNumberField(
          label: 'Comprimento',
          value: 12.5,
          fieldKey: const ValueKey('comprimento'),
          onChanged: valores.add,
        ),
      ),
    );
    expect(find.text('12.5'), findsOneWidget);

    await tester.pumpWidget(
      _envoltorio(
        IrrigationNumberField(
          label: 'Comprimento',
          value: 2,
          fieldKey: const ValueKey('comprimento-2'),
          onChanged: valores.add,
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('IrrigationNumberField usa o validador customizado', (
    tester,
  ) async {
    String? validador(String? texto) =>
        texto == null || texto.trim().isEmpty ? 'Obrigatório' : null;
    await tester.pumpWidget(
      _envoltorio(
        IrrigationNumberField(
          label: 'Vazão',
          value: 1,
          onChanged: (v) {},
          validator: validador,
        ),
      ),
    );
    final form = tester.state<FormState>(find.byType(Form).first);
    await tester.enterText(find.byType(TextFormField), '');
    expect(form.validate(), isFalse);
  });

  testWidgets('IrrigationSelectField mostra três opções e troca o valor', (
    tester,
  ) async {
    var selecionado = TipoRega.continuo;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ListView(
              children: [
                IrrigationSelectField<TipoRega>(
                  label: 'Regime',
                  value: selecionado,
                  options: TipoRega.values,
                  labelFor: (opcao) => switch (opcao) {
                    TipoRega.continuo => 'Contínuo',
                    TipoRega.intermitente => 'Intermitente',
                    TipoRega.esporadico => 'Esporádico',
                  },
                  onChanged: (opcao) => setState(() => selecionado = opcao),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Regime'), findsOneWidget);
    await tester.tap(find.text('Contínuo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esporádico').last);
    await tester.pumpAndSettle();
    expect(selecionado, TipoRega.esporadico);
  });
}
