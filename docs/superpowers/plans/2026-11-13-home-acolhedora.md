# Home acolhedora — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar a home mais acolhedora com um hero explicativo, um guia "Como escolher" e cartões refinados, mantendo os três métodos e removendo o botão de tema.

**Architecture:** Toda a mudança visual fica em `lib/features/home/views/home_screen.dart`, com widgets privados (`_HomeHero`, `_ChooseGuide`, `_GuideItem`, `_MethodCard`). Os textos e o comportamento responsivo vêm do desenho aprovado. Nenhuma dependência, rota ou provider novo.

**Tech Stack:** Flutter + Material 3 + flutter_riverpod; testes com flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-13-home-acolhedora-design.md`

## Global Constraints

- Não adicionar dependências ao `pubspec.yaml`.
- Manter as rotas `AppRoutes.sulcosTipo`, `AppRoutes.faixasProjeto` e `AppRoutes.inundacaoProjeto`.
- Manter a navegação por `context.push` e a largura máxima de 1080.
- Copiar os textos exatamente como no desenho.
- Não alterar outras telas; o switch de tema já existe em Perfil.
- Usar apenas cores do `ColorScheme` para funcionar nos temas claro e escuro.

## Review Focus

- Nome do usuário vazio ou só com espaços → hero deve mostrar "Olá, Usuário".
- Nome muito longo → deve quebrar linha sem overflow no hero.
- Fonte ampliada pelo Perfil → hero, guia e cartões não podem estourar.
- Tela estreita (320–360 px) → guia empilha e cartões ficam em 1 coluna.
- Tema escuro → gradiente, textos e etiquetas "Ideal para" continuam legíveis.

---

### Task 1: Hero explicativo e remoção do botão de tema

**Files:**
- Modify: `lib/features/home/views/home_screen.dart`
- Test: `test/features/home/home_screen_test.dart` (criar)

**Interfaces:**
- Consumes: `perfilProvider.select((state) => state.nome)`.
- Produces: `_HomeHero({required String firstName})` e `_ChooseGuide()`, usados pela `HomeScreen`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
testWidgets('home exibe hero explicativo e remove o botão de tema', (
  tester,
) async {
  SharedPreferences.setMockInitialValues({'perfil_nome': 'Maria Silva'});
  await PreferenciasApp.init();

  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: HomeScreen())),
  );
  await tester.pumpAndSettle();

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
```

- [ ] **Step 2: Rodar o teste e confirmar a falha**

Run: `flutter test test/features/home/home_screen_test.dart`
Expected: FAIL — textos do hero ainda não existem.

- [ ] **Step 3: Implementar o hero**

Em `home_screen.dart`:

- Remover o `ref.watch(perfilProvider.select((state) => state.temaEscuro))` e o `Tooltip`/`IconButton` de tema.
- Manter só o watch do nome e o cálculo de `firstName`.
- Substituir o bloco de saudação por `_HomeHero(firstName: firstName)`.
- Criar `_HomeHero` como `Card` com `Ink` de gradiente `LinearGradient` de
  `colors.primaryContainer` para `colors.secondaryContainer`,
  `borderRadius` 24 e padding 24 (16 px de padding interno em telas estreitas).
- Layout interno: `LayoutBuilder`; a partir de 760 px, `Row` com texto à
  esquerda e guia à direita (largura 360); abaixo disso, `Column`.
- Texto: tile decorativo com `AppIcons.logoApp` em `colors.primary` /
  `colors.onPrimary`; `Text('Olá, $firstName')` em `headlineSmall` peso 700 e
  cor `colors.onPrimaryContainer`; explicação em `bodyLarge` com
  `colors.onPrimaryContainer.withValues(alpha: .85)`.
- Criar `_ChooseGuide`: painel `colors.surfaceContainerLowest.withValues(alpha: .55)`,
  borda arredondada 20, padding 16, título "Como escolher" em `titleSmall`
  peso 700 e três `_GuideItem`.
- `_GuideItem` recebe `icon`, `title`, `hint` e `accent` (primary, secondary,
  tertiary), com ícone em círculo `accent`/`onAccent` e textos em
  `onPrimaryContainer`; itens separados por 12 px.

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/home/home_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/views/home_screen.dart test/features/home/home_screen_test.dart docs/superpowers/specs/2026-11-13-home-acolhedora-design.md docs/superpowers/plans/2026-11-13-home-acolhedora.md
git commit -m "feat: hero explicativo na tela inicial"
```

---

### Task 2: Cartões com "Ideal para" e verificação responsiva

**Files:**
- Modify: `lib/features/home/views/home_screen.dart`
- Modify: `test/features/home/home_screen_test.dart`
- Test: `test/features/irrigation/home_method_navigation_test.dart` (existente, não alterar)

**Interfaces:**
- Consumes: `_HomeHero` da Task 1; `_MethodCard` atual.
- Produces: `_MethodCard` com o parâmetro `ideal` (`String`).

- [ ] **Step 1: Escrever o teste que falha**

Adicionar em `home_screen_test.dart`:

```dart
testWidgets('cartões mostram ideal e não estouram em tela estreita', (
  tester,
) async {
  SharedPreferences.setMockInitialValues({});
  await PreferenciasApp.init();
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: HomeScreen())),
  );
  await tester.pumpAndSettle();

  expect(find.text('Ideal para culturas em linha'), findsOneWidget);
  expect(find.text('Ideal para terrenos inclinados'), findsOneWidget);
  expect(find.text('Ideal para áreas niveladas'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Rodar o teste e confirmar a falha**

Run: `flutter test test/features/home/home_screen_test.dart`
Expected: FAIL — as frases "Ideal para..." ainda não existem.

- [ ] **Step 3: Refinar os cartões**

Em `_MethodCard`:

- Adicionar `required this.ideal` e passar:
  - Sulcos: `'Ideal para culturas em linha'`
  - Faixas: `'Ideal para terrenos inclinados'`
  - Inundação: `'Ideal para áreas niveladas'`
- Ajustar as descrições para:
  - `'Água conduzida em canais entre as linhas de cultivo.'`
  - `'Lâmina contínua aplicada em faixas do terreno.'`
  - `'Alagamento controlado em talhões nivelados.'`
- Depois da descrição, inserir uma etiqueta com `Icons.lightbulb_outline_rounded`
  (16 px) e o texto `ideal`, em `foreground` com peso 600, fundo
  `foreground.withValues(alpha: .08)`, borda 10 e padding
  `EdgeInsets.symmetric(horizontal: 10, vertical: 7)`.
- Incluir o `ideal` no `Semantics.label` do cartão.
- Manter `_MethodsGrid` com 3/2/1 colunas e os mesmos `gap`, rotas e tons.

- [ ] **Step 4: Rodar os testes**

Run: `flutter test test/features/home/home_screen_test.dart test/features/irrigation/home_method_navigation_test.dart`
Expected: PASS nos dois arquivos.

- [ ] **Step 5: Verificar análise e formatação**

Run: `dart format lib/features/home/views/home_screen.dart test/features/home/home_screen_test.dart`
Run: `flutter analyze`
Expected: sem erros novos.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/views/home_screen.dart test/features/home/home_screen_test.dart
git commit -m "feat: cartões com orientação de uso na tela inicial"
```
