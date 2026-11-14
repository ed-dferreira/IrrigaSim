# Tutorial de operação do IrrigaSIM — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar uma área consultável de tutorial dentro do Perfil, com índice por assunto, artigos de operação e atalhos para as telas reais do app.

**Architecture:** Nova feature `lib/features/tutorial/` com modelos e conteúdo em Dart, telas de índice e artigo, e rotas filhas de `/perfil`. O composition root monta `perfilRoute(children: tutorialRoutes)`, mantendo o Perfil sem importar a feature de tutorial.

**Tech Stack:** Flutter, Dart, go_router, Riverpod, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-12-tutorial-operacao-design.md`

## Global Constraints

- Textos de UI em pt-BR.
- Não adicionar dependências novas.
- Não alterar cálculos, persistência, rotas existentes ou telas de projeto.
- Não criar onboarding automático, busca, screenshots ou controle de leitura.
- O tutorial não importa `views/`, `viewmodels/` ou controllers das features de método.
- Nenhuma feature importa `tutorial`, exceto a composição em `lib/app/router/app_router.dart`.
- Não commitar: o usuário não pediu commit.
- `flutter analyze` e toda a suíte `flutter test` devem passar ao final.

## Review Focus

- Atalho deve trocar de branch com `context.go`, não empilhar uma rota de outra aba com `push`. Teste na Task 3.
- Artigo inexistente não pode quebrar o app nem deixar a tela vazia. Teste de fallback na Task 3.
- IDs duplicados ou atalhos para rotas inexistentes precisam falhar em teste de conteúdo. Teste na Task 1.
- O card do Perfil precisa abrir `/perfil/tutorial` e manter a aba Perfil. Teste na Task 4.
- Conteúdo longo e fonte ampliada não podem estourar em 320 px. Teste na Task 5.

---

## File Structure

```text
lib/features/tutorial/
  tutorial.dart
  routes.dart
  models/artigo_tutorial.dart
  content/manual_operacao.dart
  views/tutorial_screen.dart
  views/artigo_tutorial_screen.dart

test/features/tutorial/
  conteudo_tutorial_test.dart
  tutorial_screen_test.dart
  artigo_tutorial_screen_test.dart
  tutorial_acessibilidade_test.dart

test/features/perfil/
  tutorial_entry_test.dart
```

Arquivos existentes modificados:

- `lib/app/router/app_routes.dart` — constante `tutorial`.
- `lib/app/router/app_router.dart` — composição de `perfilRoute`.
- `lib/features/perfil/routes.dart` — `perfilRoute({children})`.
- `lib/features/perfil/views/perfil_screen.dart` — card de entrada.

---

### Task 1: Modelos e catálogo de conteúdo

**Files:**
- Create: `lib/features/tutorial/models/artigo_tutorial.dart`
- Create: `lib/features/tutorial/content/manual_operacao.dart`
- Test: `test/features/tutorial/conteudo_tutorial_test.dart`

**Interfaces:**
- Consumes: `AppRoutes` (rotas existentes).
- Produces:
  - `enum CategoriaTutorial { primeirosPassos, metodos, resultados, cenarios, perfil }` com campo `String titulo`.
  - `class ArtigoTutorial` com `String id`, `String titulo`, `String resumo`, `CategoriaTutorial categoria`, `IconData icone`, `List<SecaoTutorial> secoes`, `List<AtalhoTutorial> atalhos`.
  - `class SecaoTutorial` com `String titulo`, `List<String> paragrafos`, `List<String> passos`.
  - `class AtalhoTutorial` com `String rotulo`, `String descricao`, `String rota`, `IconData icone`.
  - `const List<ArtigoTutorial> manualOperacao`.
  - `ArtigoTutorial? buscarArtigoTutorial(String id)`.
  - `List<ArtigoTutorial> artigosDaCategoria(CategoriaTutorial categoria)`.

- [ ] **Step 1: Write the failing content test**

Create `test/features/tutorial/conteudo_tutorial_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/features/tutorial/content/manual_operacao.dart';
import 'package:irrigasim/features/tutorial/models/artigo_tutorial.dart';

void main() {
  test('IDs são únicos e todo artigo tem conteúdo', () {
    final ids = manualOperacao.map((artigo) => artigo.id).toList();
    expect(ids.toSet().length, ids.length);

    for (final artigo in manualOperacao) {
      expect(artigo.id.trim(), isNotEmpty);
      expect(artigo.titulo.trim(), isNotEmpty, reason: artigo.id);
      expect(artigo.resumo.trim(), isNotEmpty, reason: artigo.id);
      expect(artigo.secoes, isNotEmpty, reason: artigo.id);
      for (final secao in artigo.secoes) {
        expect(secao.titulo.trim(), isNotEmpty, reason: artigo.id);
        expect(
          secao.paragrafos.isNotEmpty || secao.passos.isNotEmpty,
          isTrue,
          reason: '${artigo.id}/${secao.titulo}',
        );
      }
    }
  });

  test('todas as categorias têm pelo menos um artigo', () {
    for (final categoria in CategoriaTutorial.values) {
      expect(
        artigosDaCategoria(categoria),
        isNotEmpty,
        reason: categoria.name,
      );
    }
  });

  test('atalhos apontam para rotas conhecidas', () {
    const rotasConhecidas = {
      AppRoutes.home,
      AppRoutes.sulcosTipo,
      AppRoutes.sulcosProjeto,
      AppRoutes.sulcosResultados,
      AppRoutes.faixasProjeto,
      AppRoutes.faixasResultados,
      AppRoutes.inundacaoProjeto,
      AppRoutes.inundacaoResultados,
      AppRoutes.inundacaoReferencia,
      AppRoutes.cenarios,
      AppRoutes.perfil,
    };

    for (final artigo in manualOperacao) {
      for (final atalho in artigo.atalhos) {
        expect(atalho.rotulo.trim(), isNotEmpty, reason: artigo.id);
        expect(atalho.descricao.trim(), isNotEmpty, reason: artigo.id);
        expect(
          rotasConhecidas,
          contains(atalho.rota),
          reason: '${artigo.id}/${atalho.rotulo}',
        );
      }
    }
  });

  test('busca artigo por ID e devolve null para desconhecido', () {
    expect(buscarArtigoTutorial('sulcos')?.titulo, 'Sulcos');
    expect(buscarArtigoTutorial('inexistente'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tutorial/conteudo_tutorial_test.dart`
Expected: FAIL because `manual_operacao.dart` and `artigo_tutorial.dart` do not exist.

- [ ] **Step 3: Implement models and content**

Create the models exactly as described in Interfaces, using `const` constructors and `final` fields.

Create `manualOperacao` with these stable IDs, categories and shortcuts:

| ID | Categoria | Título | Atalhos |
|---|---|---|---|
| `visao-geral` | `primeirosPassos` | Visão geral do app | `AppRoutes.home` |
| `preencher-projeto` | `primeirosPassos` | Como preencher um projeto | `AppRoutes.sulcosTipo`, `AppRoutes.sulcosProjeto` |
| `sulcos` | `metodos` | Sulcos | `AppRoutes.sulcosTipo`, `AppRoutes.sulcosProjeto` |
| `faixas` | `metodos` | Faixas | `AppRoutes.faixasProjeto` |
| `inundacao` | `metodos` | Inundação | `AppRoutes.inundacaoProjeto`, `AppRoutes.inundacaoReferencia` |
| `resultados` | `resultados` | Como ler e salvar resultados | `AppRoutes.cenarios` |
| `cenarios` | `cenarios` | Salvar, reabrir, comparar e exportar | `AppRoutes.cenarios` |
| `perfil` | `perfil` | Perfil e acessibilidade | `AppRoutes.perfil` |

Cada artigo deve ter pelo menos duas seções. O conteúdo descreve apenas operação: abas, etapas, botões Confirmar/Próximo, revisão, cálculo, resultados e salvamento. Não explicar fórmulas nem agronomia.

Use ícones existentes em `AppIcons` (`guiaDidatico`, `home`, `sulco`, `faixa`, `inundacao`, `relatorio`, `salvarCenario`, `navPerfil`).

Implemente os helpers percorrendo a lista com `for`, sem adicionar dependências.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/tutorial/conteudo_tutorial_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer on new files**

Run: `flutter analyze lib/features/tutorial`
Expected: No issues found.

---

### Task 2: Tela de índice e rota de listagem

**Files:**
- Create: `lib/features/tutorial/views/tutorial_screen.dart`
- Create: `lib/features/tutorial/routes.dart`
- Create: `lib/features/tutorial/tutorial.dart`
- Test: `test/features/tutorial/tutorial_screen_test.dart`

**Interfaces:**
- Consumes: `manualOperacao`, `artigosDaCategoria`, `CategoriaTutorial`, `ArtigoTutorial`.
- Produces:
  - `class TutorialScreen extends StatelessWidget` com construtor `const TutorialScreen({super.key})`.
  - `final List<RouteBase> tutorialRoutes` contendo a rota relativa `tutorial` para `TutorialScreen`.
  - `String localizacaoArtigoTutorial(String id)` retornando `'${AppRoutes.tutorial}/$id'`.
  - Barrel `tutorial.dart` exportando `routes.dart`, `views/tutorial_screen.dart` e `views/artigo_tutorial_screen.dart` (este último será criado na Task 3).

- [ ] **Step 1: Write the failing index test**

Create `test/features/tutorial/tutorial_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/tutorial/content/manual_operacao.dart';
import 'package:irrigasim/features/tutorial/models/artigo_tutorial.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

void main() {
  testWidgets('índice lista categorias e artigos', (tester) async {
    final router = GoRouter(
      initialLocation: '/perfil/tutorial',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const Scaffold(),
          routes: tutorialRoutes,
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    for (final categoria in CategoriaTutorial.values) {
      expect(
        find.text(categoria.titulo),
        findsOneWidget,
        reason: categoria.name,
      );
    }
    for (final artigo in manualOperacao) {
      expect(find.text(artigo.titulo), findsWidgets, reason: artigo.id);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tutorial/tutorial_screen_test.dart`
Expected: FAIL because `tutorialRoutes` does not exist.

- [ ] **Step 3: Implement `TutorialScreen` and `tutorialRoutes`**

`TutorialScreen` deve ter `Scaffold` com `AppBar(title: Text('Tutorial e ajuda'))`, corpo rolável, cabeçalho com subtítulo, e um bloco por categoria na ordem de `CategoriaTutorial.values`.

Cada artigo é um `Card` com `InkWell`/`ListTile`, ícone, título, resumo e seta. Ao tocar, use `context.push(localizacaoArtigoTutorial(artigo.id))`.

`routes.dart` deve declarar:

```dart
final tutorialRoutes = <RouteBase>[
  GoRoute(
    path: 'tutorial',
    builder: (context, state) => const TutorialScreen(),
  ),
];
```

`localizacaoArtigoTutorial` fica em `routes.dart` e ainda não é usada por nenhuma rota filha nesta task.

Crie o barrel `tutorial.dart` exportando `routes.dart` e `views/tutorial_screen.dart`; adicione o export de `views/artigo_tutorial_screen.dart` na Task 3.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/tutorial/tutorial_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze lib/features/tutorial test/features/tutorial`
Expected: No issues found.

---

### Task 3: Tela de artigo, atalhos e fallback

**Files:**
- Create: `lib/features/tutorial/views/artigo_tutorial_screen.dart`
- Modify: `lib/features/tutorial/routes.dart`
- Modify: `lib/features/tutorial/tutorial.dart`
- Test: `test/features/tutorial/artigo_tutorial_screen_test.dart`

**Interfaces:**
- Consumes: `buscarArtigoTutorial`, `ArtigoTutorial`, `SecaoTutorial`, `AtalhoTutorial`, `AppRoutes`, `localizacaoArtigoTutorial`.
- Produces:
  - `class ArtigoTutorialScreen extends StatelessWidget` com `const ArtigoTutorialScreen({super.key, required ArtigoTutorial? artigo})`.
  - Rota filha `':artigoId'` dentro de `tutorialRoutes`, usando `buscarArtigoTutorial(state.pathParameters['artigoId'] ?? '')`.

- [ ] **Step 1: Write the failing article tests**

Create `test/features/tutorial/artigo_tutorial_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

GoRouter routerPara(String localizacao) {
  return GoRouter(
    initialLocation: localizacao,
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (_, _) => const Scaffold(),
        routes: tutorialRoutes,
      ),
      GoRoute(
        path: '/home/irrigation/tipo-sulco',
        builder: (_, _) =>
            const Scaffold(body: Text('Tela de tipo de sulco')),
      ),
    ],
  );
}

void main() {
  testWidgets('artigo de sulcos mostra seções e abre atalho', (tester) async {
    final router = routerPara('/perfil/tutorial/sulcos');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Sulcos'), findsOneWidget);
    expect(find.textContaining('tipo de sulco'), findsWidgets);

    final atalho = find.text('Abrir tipo de sulco');
    await tester.ensureVisible(atalho);
    await tester.tap(atalho);
    await tester.pumpAndSettle();

    expect(find.text('Tela de tipo de sulco'), findsOneWidget);
  });

  testWidgets('artigo inexistente mostra fallback e volta ao índice', (
    tester,
  ) async {
    final router = routerPara('/perfil/tutorial/inexistente');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Artigo não encontrado'), findsOneWidget);

    await tester.tap(find.text('Voltar ao tutorial'));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    expect(find.text('Visão geral do app'), findsOneWidget);
  });
}
```

O conteúdo do artigo `sulcos` deve conter um passo ou parágrafo com a expressão “tipo de sulco” e um atalho com rótulo `Abrir tipo de sulco`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tutorial/artigo_tutorial_screen_test.dart`
Expected: FAIL because the article route and screen do not exist.

- [ ] **Step 3: Implement the article screen and child route**

`ArtigoTutorialScreen` deve:

- Se `artigo == null`, renderizar `Scaffold` com `AppBar(title: Text('Artigo não encontrado'))`, texto explicativo e `FilledButton` “Voltar ao tutorial” que executa `context.go(AppRoutes.tutorial)`.
- Caso contrário, renderizar `AppBar(title: Text(artigo!.titulo))`, corpo rolável com chip da categoria, resumo, seções e passos numerados.
- Para cada seção: cabeçalho `Semantics(header: true)`, parágrafos e passos em `Text` com numeração.
- Se houver atalhos, exibir cabeçalho “Ir para” e um botão por atalho com ícone, rótulo e descrição. O `onPressed` deve executar `context.go(atalho.rota)`.
- Não usar `push` nos atalhos.

Adicione a rota filha em `tutorialRoutes`:

```dart
GoRoute(
  path: ':artigoId',
  builder: (context, state) => ArtigoTutorialScreen(
    artigo: buscarArtigoTutorial(state.pathParameters['artigoId'] ?? ''),
  ),
),
```

Adicione o export de `views/artigo_tutorial_screen.dart` ao barrel.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/tutorial/tutorial_screen_test.dart test/features/tutorial/artigo_tutorial_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze lib/features/tutorial test/features/tutorial`
Expected: No issues found.

---

### Task 4: Entrada no Perfil e composição do roteador

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/perfil/routes.dart`
- Modify: `lib/features/perfil/views/perfil_screen.dart`
- Test: `test/features/perfil/tutorial_entry_test.dart`

**Interfaces:**
- Consumes: `tutorialRoutes`, `AppRoutes.perfil`.
- Produces:
  - `AppRoutes.tutorial` igual a `'/perfil/tutorial'`.
  - `GoRoute perfilRoute({List<RouteBase> children = const []})` substituindo a lista `perfilRoutes`.
  - Card “Tutorial e ajuda” no Perfil que executa `context.push(AppRoutes.tutorial)`.

- [ ] **Step 1: Write the failing entry test**

Create `test/features/perfil/tutorial_entry_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/features/perfil/routes.dart';
import 'package:irrigasim/features/perfil/services/preferencias_app.dart';
import 'package:irrigasim/features/tutorial/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('card do Perfil abre o tutorial', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PreferenciasApp.init();

    final router = GoRouter(
      initialLocation: AppRoutes.perfil,
      routes: [perfilRoute(children: tutorialRoutes)],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final abrir = find.text('Abrir tutorial');
    await tester.ensureVisible(abrir);
    await tester.tap(abrir);
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    expect(find.text('Visão geral do app'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/perfil/tutorial_entry_test.dart`
Expected: FAIL because `AppRoutes.tutorial`, `perfilRoute` and the card do not exist.

- [ ] **Step 3: Implement routes, composition and card**

Em `app_routes.dart`, adicionar:

```dart
static const tutorial = '/perfil/tutorial';
```

Em `perfil/routes.dart`, substituir `final perfilRoutes = <RouteBase>[...]` por:

```dart
GoRoute perfilRoute({List<RouteBase> children = const []}) {
  return GoRoute(
    path: AppRoutes.perfil,
    builder: (context, state) => const PerfilScreen(),
    routes: children,
  );
}
```

Em `app_router.dart`, importar `tutorial/routes.dart` e montar:

```dart
StatefulShellBranch(routes: [perfilRoute(children: tutorialRoutes)]),
```

Em `perfil_screen.dart`, adicionar `import 'package:go_router/go_router.dart';` e um widget `_TutorialCard` posicionado após `_StatisticsGrid` e antes do cabeçalho “Preferências”. O card deve ter ícone `AppIcons.guiaDidatico`, título “Tutorial e ajuda”, descrição curta e botão “Abrir tutorial” com `onPressed: () => context.push(AppRoutes.tutorial)`.

O Perfil não deve importar `features/tutorial/`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/perfil/tutorial_entry_test.dart test/features/tutorial/`
Expected: PASS.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: No issues found.

---

### Task 5: Acessibilidade, layout estreito e verificação final

**Files:**
- Test: `test/features/tutorial/tutorial_acessibilidade_test.dart`
- Modify if needed: `lib/features/tutorial/views/*.dart`

**Interfaces:**
- Consumes: `tutorialRoutes`, `TutorialScreen`, `ArtigoTutorialScreen`.
- Produces: cobertura de layout estreito e fonte ampliada; nenhuma API nova.

- [ ] **Step 1: Write the failing accessibility test**

Create `test/features/tutorial/tutorial_acessibilidade_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

Widget appComEscala(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(2)),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

GoRouter routerPara(String localizacao) {
  return GoRouter(
    initialLocation: localizacao,
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (_, _) => const Scaffold(),
        routes: tutorialRoutes,
      ),
    ],
  );
}

void main() {
  testWidgets('índice não estoura em 320 px com fonte 2x', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = routerPara('/perfil/tutorial');
    addTearDown(router.dispose);

    await tester.pumpWidget(appComEscala(router));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('artigo não estoura em 320 px com fonte 2x', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = routerPara('/perfil/tutorial/sulcos');
    addTearDown(router.dispose);

    await tester.pumpWidget(appComEscala(router));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sulcos'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails or exposes overflow**

Run: `flutter test test/features/tutorial/tutorial_acessibilidade_test.dart`
Expected: FAIL se houver overflow/erro de layout; caso contrário, o teste já deve passar após ajustar o setup.

- [ ] **Step 3: Fix layout issues**

Ajuste padding, `Wrap`, `Flexible`/`Expanded` e tamanhos mínimos de toque apenas onde o teste apontar. Não reduza a fonte nem ignore o `MediaQuery`.

- [ ] **Step 4: Run the full tutorial and perfil tests**

Run: `flutter test test/features/tutorial/ test/features/perfil/`
Expected: PASS.

- [ ] **Step 5: Run analyzer and full suite**

Run: `flutter analyze`
Expected: No issues found.

Run: `flutter test`
Expected: All tests passed.
