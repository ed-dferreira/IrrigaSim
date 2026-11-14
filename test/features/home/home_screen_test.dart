import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/theme/app_theme.dart';
import 'package:irrigasim/features/home/views/home_screen.dart';
import 'package:irrigasim/features/perfil/perfil.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  String? name,
  ThemeData? theme,
  Size size = const Size(1200, 800),
}) async {
  SharedPreferences.setMockInitialValues({'perfil_nome': ?name});
  await PreferenciasApp.init();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home exibe hero explicativo e remove o botão de tema', (
    tester,
  ) async {
    await _pumpHome(tester, name: 'Maria Silva');

    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(
      find.text(
        'Simule irrigação por superfície, compare o desempenho e planeje antes de ir a campo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Como escolher'), findsOneWidget);
    expect(find.text('Culturas em linha'), findsOneWidget);
    expect(find.text('Terreno inclinado'), findsOneWidget);
    expect(find.text('Talhões nivelados'), findsOneWidget);
    expect(find.byTooltip('Usar tema escuro'), findsNothing);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);
    expect(find.byIcon(Icons.light_mode_rounded), findsNothing);
  });

  testWidgets('cartões mostram a orientação ideal de cada método', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Ideal para culturas em linha'), findsOneWidget);
    expect(find.text('Ideal para terrenos inclinados'), findsOneWidget);
    expect(find.text('Ideal para áreas niveladas'), findsOneWidget);
  });

  testWidgets('home usa o nome genérico quando o perfil está em branco', (
    tester,
  ) async {
    await _pumpHome(tester, name: '   ');

    expect(find.text('Olá, Usuário'), findsOneWidget);
  });

  testWidgets('nome longo não estoura a home em tela estreita', (tester) async {
    await _pumpHome(tester, name: 'A' * 100, size: const Size(320, 640));

    expect(find.text('Olá, ${'A' * 100}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primeiro método aparece na primeira tela em 320x640', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(320, 640));

    final firstCard = find.widgetWithText(InkWell, 'Sulcos').first;
    expect(
      tester.getTopLeft(firstCard).dy,
      lessThan(640),
      reason: 'O hero não pode empurrar a ação principal para fora da tela.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fonte ampliada no tema escuro não estoura a home', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      theme: AppTheme.dark(fontScale: 1.3),
      size: const Size(320, 640),
    );

    expect(find.text('Como escolher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guia usa cores opacas nos temas de alto contraste', (
    tester,
  ) async {
    await _pumpHome(tester, theme: AppTheme.light(highContrast: true));

    final panel = tester.widget<Container>(
      find.byKey(const Key('home-choose-guide')),
    );
    final background = (panel.decoration! as BoxDecoration).color!;
    expect(background.a, 1.0);

    final hint = tester.widget<Text>(find.text('Culturas em linha'));
    expect(hint.style!.color!.a, 1.0);
    expect(tester.takeException(), isNull);

    await _pumpHome(tester, theme: AppTheme.dark(highContrast: true));

    final darkPanel = tester.widget<Container>(
      find.byKey(const Key('home-choose-guide')),
    );
    final darkBackground = (darkPanel.decoration! as BoxDecoration).color!;
    expect(darkBackground.a, 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero expõe cabeçalho e cartão expõe botão acionável', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpHome(tester, name: 'Maria Silva');

    final heading = tester.getSemantics(find.bySemanticsLabel('Olá, Maria'));
    expect(heading.getSemanticsData().flagsCollection.isHeader, isTrue);

    const cardLabel =
        'Sulcos. Água conduzida em canais entre as linhas de cultivo. '
        'Ideal para culturas em linha. Iniciar simulação.';
    final card = tester.getSemantics(find.bySemanticsLabel(cardLabel));
    final cardData = card.getSemanticsData();
    expect(cardData.flagsCollection.isButton, isTrue);
    expect(cardData.hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('grade de métodos usa 3 colunas em paisagem larga e 2 em média', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(1080, 700));

    final sulcos = find.widgetWithText(InkWell, 'Sulcos').first;
    final faixas = find.widgetWithText(InkWell, 'Faixas').first;
    final inundacao = find.widgetWithText(InkWell, 'Inundação').first;

    expect(tester.getTopLeft(sulcos).dy, tester.getTopLeft(faixas).dy);
    expect(tester.getTopLeft(sulcos).dy, tester.getTopLeft(inundacao).dy);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, size: const Size(600, 400));

    final sulcos600 = find.widgetWithText(InkWell, 'Sulcos').first;
    final faixas600 = find.widgetWithText(InkWell, 'Faixas').first;
    final inundacao600 = find.widgetWithText(InkWell, 'Inundação').first;

    expect(tester.getTopLeft(sulcos600).dy, tester.getTopLeft(faixas600).dy);
    expect(
      tester.getTopLeft(inundacao600).dy,
      greaterThan(tester.getTopLeft(sulcos600).dy),
    );
  });

  testWidgets('em retrato os três métodos ficam um abaixo do outro', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(600, 900));

    final sulcos = find.widgetWithText(InkWell, 'Sulcos').first;
    final faixas = find.widgetWithText(InkWell, 'Faixas').first;
    final inundacao = find.widgetWithText(InkWell, 'Inundação').first;

    expect(
      tester.getTopLeft(faixas).dy,
      greaterThan(tester.getTopLeft(sulcos).dy),
    );
    expect(
      tester.getTopLeft(inundacao).dy,
      greaterThan(tester.getTopLeft(faixas).dy),
    );
  });

  testWidgets('em retrato o hero e os cartões ficam compactos', (tester) async {
    await _pumpHome(tester, size: const Size(390, 844));

    final hero = find.byType(Card).first;
    expect(tester.getSize(hero).height, lessThan(240));

    final firstCard = find.widgetWithText(InkWell, 'Sulcos').first;
    expect(tester.getSize(firstCard).height, lessThan(180));
  });

  testWidgets('cartões têm a mesma altura em paisagem e desktop', (
    tester,
  ) async {
    for (final size in const [Size(1200, 800), Size(844, 390)]) {
      await _pumpHome(tester, size: size);

      final heights = <double>{
        for (final title in ['Sulcos', 'Faixas', 'Inundação'])
          tester.getSize(find.widgetWithText(InkWell, title).first).height,
      };
      expect(heights, hasLength(1), reason: 'tamanhos divergentes em $size');

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
