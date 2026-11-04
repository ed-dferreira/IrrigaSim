# AGENTS.md — IrrigaSim

## Arquitetura

O app Flutter do IrrigaSim é organizado **feature-first**. Cada feature contém
tudo que é dela (`models/`, `services/`, `viewmodels/`, `views/`, `routes.dart`
e um barrel público `<feature>.dart`).

```text
lib/
├── main.dart
├── app/                            # composition root: app, rotas canônicas, tema
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart         # único lugar que conhece todas as features
│   │   └── app_routes.dart         # caminhos canônicos + query params
│   └── theme/
├── core/                           # infraestrutura genérica (shell, widgets base)
│   ├── navigation/
│   └── widgets/
├── shared/                         # contratos e código genuinamente compartilhado
│   ├── irrigacao/
│   │   ├── models/                 # IrrigationParameters, SimulationResult, comum/
│   │   ├── services/               # Kostiakov-Lewis, Blaney-Criddle, indicadores…
│   │   └── widgets/                # charts/, terrain/, componentes reutilizados
│   └── cenarios/                   # CenarioSalvo, ScenarioService, stores, providers
└── features/
    ├── irrigacao_sulcos/
    ├── irrigacao_faixas/
    ├── irrigacao_inundacao/
    ├── cenarios/
    ├── perfil/
    └── simulacao_guiada/           # só encaminha: home → escolha do método → rota
```

## Regras de dependência

1. `app/router/app_router.dart` é o **único** arquivo que conhece todas as
   features; cada feature expõe suas rotas em `routes.dart`.
2. Uma feature **não** importa `views/` nem `viewmodels/` de outra feature.
3. Uma feature de método (sulcos/faixas/inundacao) **não** importa outra
   feature de método.
4. `shared/` **não** importa `features/` (ver dívida conhecida abaixo).
5. `simulacao_guiada` só encaminha: não calcula, não salva cenário e lê apenas
   o nome do usuário via API pública de `perfil`.
6. Cenários são abertos por `cenarioId` (query param em `AppRoutes.cenarioId`);
   a feature de destino hidrata o próprio controller.
7. Dentro da feature use imports relativos; fora dela use
   `package:irrigasim/...`.

## Dívidas conhecidas (migração)

- `shared/irrigacao/models/*` (`irrigation_parameters`, `simulation_result`,
  `simulation_result_model`) e `shared/cenarios/*` ainda importam modelos das
  features de método. É a dívida dos DTOs "de todos" — plano de migração
  `docs/Plano_migracao_features.md`, etapa 9 (codecs de cenário por feature).
- `features/irrigacao_sulcos/viewmodels/parameters_controller.dart` ainda
  importa faixas/inundação (`setMetodo`, coordenação de faixa/bacia). Será
  removido na etapa 6c do plano; não reescrever fórmulas ao fazer.
- O `README.md` ainda descreve a versão Kotlin Multiplatform antiga.

## Validação obrigatória

Antes de cada commit:

```bash
dart format lib test
flutter analyze   # sem erros
flutter test      # verde
```

Testes de regressão numérica e de tela ficam em `test/`; nunca alterar os
valores esperados dos testes de regressão sem justificativa.
