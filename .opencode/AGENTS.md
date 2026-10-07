# IrrigaSim

Flutter app for irrigation simulation.

**Stack:** Flutter + Dart + MVC + Riverpod + Feature-First

## Idioma

**Sempre responda em português brasileiro (pt-BR).** Todas as respostas, explicações, comentários no código, commits e documentação devem ser escritos em português.

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — run linter (uses flutter_lints)
- `flutter test` — run tests
- `flutter run` — start dev server

## Architecture

Feature-based MVC structure under `lib/`. The current code is organized by
layer, with feature folders inside each layer and shared irrigation adapters
at the layer root:

```
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── app.dart
│   ├── router/
│   └── theme/
├── core/
│   ├── navigation/
│   └── widgets/
├── models/
│   ├── cenarios/
│   ├── comum/          # caracterização e ensaios compartilhados
│   ├── faixas/
│   ├── inundacao/
│   ├── perfil/
│   ├── sulcos/
│   ├── user/
│   └── shared irrigation compatibility contracts at the root
├── services/
│   ├── auth/
│   ├── cenarios/
│   ├── perfil/
│   ├── persistence/
│   └── simulation/
│       ├── faixas/
│       ├── inundacao/
│       └── sulcos/
├── viewmodels/
│   ├── auth/
│   ├── cenarios/
│   ├── faixas/
│   ├── inundacao/
│   ├── perfil/
│   ├── sulcos/
│   └── shared irrigation dispatchers/providers at the root
└── views/
    ├── auth/
    ├── cenarios/
    ├── home/
    ├── perfil/
    ├── tutorial/
    └── irrigation/
        ├── sulcos/
        │   └── widgets/
        └── shared screens and widgets at the root
```

Use the smallest applicable MVC structure for each feature. Keep feature-specific
models, services, controllers/viewmodels, and views in their corresponding
feature folders. Irrigation is further divided by method (`sulcos/`, `faixas/`,
`inundacao/`). Keep shared contracts, adapters, providers, mathematical helpers,
and widgets at the layer root only when they are genuinely used across methods.

Base comum da irrigação:
- `models/comum/irrigacao_comum.dart` define método (forma de aplicação), sistema,
  posição, caracterização da área, estacas e observações de infiltração. A
  classificação segue `docs/Irrigacao_comum/Analise_base_comum.md`: sulcos,
  faixas e inundação são sistemas do método por superfície. Classificação
  didática e posição de aplicação são eixos distintos.
- `models/comum/adaptadores_superficie.dart` projeta `IrrigationProject`,
  `BorderProject` e cenários rápidos (`IrrigationParameters`) para `BaseIrrigacao`.
  Os modelos próprios continuam como fonte dos dados de simulação. Ao incluir
  um método, fornecer seu adaptador sem inventar valores para campos ausentes.
- `models/inundacao/basin_project.dart` reúne a base comum e os parâmetros dos
  regimes intermitente e permanente; seu coordenador aceita esse projeto ou o
  contrato rápido legado. O fluxo rápido também exporta `base_comum` no JSON.
- Unidades da base: distância/profundidade em m, declividade em %, tempo em min,
  lâmina em mm, vazão em L/s e clima em mm/dia. Converter explicitamente na
  borda: faixas guarda declive em m/m e raízes em cm.
- Ensaios, infiltração, solo, cultura e clima são conceitos compartilhados;
  calibração, parâmetros com unidades específicas e equações hidráulicas
  continuam nos serviços de cada sistema. A Aula 5 é conceitual: suas faixas
  de eficiência e vazão não são constantes de dimensionamento. Consultar
  `docs/Irrigacao_comum/dados_comuns.json` para páginas e escopo das referências.

Use the smallest applicable structure for each feature:
- `models/` - application data and immutable state objects
- `views/` - screens and feature-specific widgets
- `viewmodels/` - Riverpod state and UI workflow coordination
- `services/` - external integrations, persistence, and reusable domain calculations

Not every feature needs all four layers. Simple, view-only features such as
`home` and `tutorial` contain only `views/`. Shared irrigation compatibility
types such as `IrrigationParameters`, `SimulationResult`, `ParametersState`, and
`ParametersController` remain at their layer roots while method-specific
contracts and coordination are separated incrementally.

Dependency direction:

```text
Views -> Controllers -> Models/Services
```

Keep providers close to their feature in `providers.dart`. Do not add repository interfaces, use-case wrappers, or extra layers unless there is real policy, more than one implementation, or a testing requirement that needs the abstraction.

## Current State

- Navigation uses `go_router` with authenticated routes and a stateful bottom-navigation shell.
- Firebase Authentication is used on supported platforms; Linux authentication uses the Firebase REST API.
- Firestore stores authenticated users' scenarios on supported platforms.
- `SharedPreferences` stores theme and accessibility settings.
- Simulation tests live under `test/features/irrigation/`.

## Simulation Flow (Irrigation Feature)

```
Usuário
   │
   ▼
IrrigationScreen
   │
   ▼
ParametersScreen (quick flow) or method-specific project screen
   │
   ▼
ParametersController
   │
   ▼
Method coordinator in `viewmodels/<method>/`
   │
   ▼
Simulation service selected by irrigation method
   │
   ├── RunFurrowSimulation
   ├── RunBorderSimulation
   ├── RunBasinSimulation
   ├── RunPermanentBasinSimulation
   ├── SurfaceIrrigationMath
   └── PerformanceIndicators
   │
   ▼
SimulationResult
   │
   ▼
ResultsController
   │
   ▼
ResultsScreen
    │
    ├── AdvanceChart
    ├── InfiltrationChart
    └── WaterBalanceChart
```

`BaseIrrigacao` é uma projeção compartilhada de leitura, usada para
caracterização/exportação; as entradas hidráulicas continuam nos projetos
específicos. O coordenador de inundação aceita `BasinProject` (montado a partir
dos parâmetros do fluxo rápido) e escolhe entre os dois regimes.

Method-specific irrigation files live under matching `sulcos/`, `faixas/`, or
`inundacao/` folders. The current project workflow and terrain/profile widgets
under `views/irrigation/sulcos/` are specific to furrow irrigation. Quick-flow
screens and charts used by multiple methods remain shared under
`views/irrigation/`.

## Git Hooks

Setup after cloning:
```bash
./scripts/setup-hooks.sh
```

The `commit-msg` hook enforces **Conventional Commits**:
```
<type>(<scope>): <description>
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`

Examples:
- `feat(auth): adiciona login com Google`
- `fix: corrige crash na tela de irrigação`
- `docs: atualiza README`

Skip hook (not recommended): `git commit --no-verify -m "msg"`

## Conventions

- Dart SDK ^3.13.2
- Material Design with `uses-material-design: true`
- Use `flutter_lints` rules from `analysis_options.yaml`
- Use Portuguese names where the existing feature API is already in Portuguese; preserve established terminology
- Prefer package imports across features and relative imports within a feature
- Keep simulation algorithms separate because they contain substantial, independently testable domain logic
- Run `dart format` only on files changed by the task, then run `flutter analyze` and `flutter test`
- Se os pacotes de referência em `docs/` forem renomeados, atualizar os caminhos
  usados pelos testes de regressão sem alterar os valores esperados.
