# IrrigaSim

Flutter app for irrigation simulation.

**Stack:** Flutter + Dart + MVVM + Clean Architecture + Riverpod + Feature-First

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — run linter (uses flutter_lints)
- `flutter test` — run tests
- `flutter run` — start dev server

## Architecture

Feature-based structure under `lib/`:

```
lib/
├── main.dart
├── router/
├── theme/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
└── features/
    ├── authentication/
    ├── home/
    └── irrigation/
```

Each feature follows MVVM pattern (see `docs/Como funciona o mvvm.md`):
- `data/` — datasources, models, repositories
- `domain/` — entities, repositories, services
- `presentation/` — screens, viewmodels, widgets

## Current State

- Theme files (`lib/theme/`) are empty — implement before adding UI
- Router (`lib/router/app_router.dart`) is empty — set up navigation
- `main.dart` still has default demo code — needs cleanup
- No tests exist yet

## Simulation Flow (Irrigation Feature)

```
Usuário
   │
   ▼
IrrigationMethodScreen
   │
   ▼
ParametersScreen
   │
   ▼
ParametersViewModel
   │
   ▼
RunFurrowSimulation
   │
   ├── KostiakovLewis
   ├── FurrowSimulation
   ├── WaterBalance
   └── PerformanceIndicators
   │
   ▼
SimulationResult
   │
   ▼
ResultsViewModel
   │
   ▼
ResultsScreen
   │
   ├── AdvanceChart
   ├── InfiltrationChart
   └── WaterBalanceChart
```

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
