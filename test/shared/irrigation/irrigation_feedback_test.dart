import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_feedback.dart';

void main() {
  testWidgets('IrrigationBanner apresenta os quatro tons sem exceção', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final tone in IrrigationBannerTone.values)
                  IrrigationBanner(
                    title: 'Título ${tone.name}',
                    message: 'Mensagem ${tone.name}',
                    icon: Icons.info_outline,
                    tone: tone,
                    semanticsLabel: 'Banner ${tone.name}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final tone in IrrigationBannerTone.values) {
      expect(find.text('Título ${tone.name}'), findsOneWidget);
      expect(find.text('Mensagem ${tone.name}'), findsOneWidget);
    }
    expect(find.byIcon(Icons.info_outline), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
