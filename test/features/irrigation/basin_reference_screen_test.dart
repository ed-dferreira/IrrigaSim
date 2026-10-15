import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/views/irrigation/inundacao/basin_reference_screen.dart';
import 'package:markdown/markdown.dart' show ExtensionSet;

const assetEsperado = 'docs/Pacote_Inundacao/Resumo_irrigacao_por_inundacao.md';

void main() {
  test('pubspec.yaml declara o resumo da Aula 8 como asset (Fase 7)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(
        r'assets:\s*\n\s+- docs/Pacote_Inundacao/Resumo_irrigacao_por_inundacao\.md',
      ).hasMatch(pubspec),
      isTrue,
      reason:
          'o resumo precisa estar em flutter.assets para a tela de '
          'referência carregá-lo',
    );
    expect(File(assetEsperado).existsSync(), isTrue);
  });

  testWidgets('tela de referência renderiza o resumo da Aula 8', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BasinReferenceScreen()));
    expect(find.text('Carregando resumo da Aula 8…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Referência — Aula 8'), findsOneWidget);

    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.data, contains('Irrigação por inundação — resumo'));
    expect(markdown.data, contains('Aula 8 — Irrigação por Inundação'));
    expect(markdown.data, contains('2/3 da lâmina média'));
    expect(
      markdown.extensionSet,
      ExtensionSet.gitHubFlavored,
      reason: 'tabelas da aula precisam ser renderizadas',
    );
    expect(find.byType(SelectableText), findsWidgets);
  });
}
