# AGENTS.md — IrrigaSim

## Arquitetura

O app Flutter do IrrigaSim é organizado **feature-first**. Cada feature contém
tudo que é dela (`models/`, `services/`, `viewmodels/`, `views/`, `routes.dart`
e um barrel público `<feature>.dart`).

```text
lib/
├── main.dart                       # registrarCodecs() + PreferenciasApp.init()
├── app/                            # composition root
│   ├── app.dart                    # MaterialApp.router + tema/densidade via perfil
│   ├── codecs.dart                 # registra os codecs dos 3 métodos (ordem fixa)
│   ├── router/
│   │   ├── app_router.dart         # único lugar que conhece todas as features
│   │   └── app_routes.dart         # caminhos canônicos + query params
│   └── theme/                      # AppTheme, AppTextStyles, AppAnimations
├── core/                           # infraestrutura genérica
│   ├── navigation/main_shell.dart  # shell com abas (StatefulShellRoute)
│   ├── theme/                      # AppColors, AppIcons (tokens compartilhados)
│   └── widgets/                    # botão, campo, KPI, estados de loading/erro…
├── shared/                         # conceitos agronômicos e código compartilhado
│   ├── clima/                      # demanda climática, Blaney-Criddle
│   ├── comum/                      # UnitsService (conversões centralizadas)
│   ├── cultura/                    # CropPreset (predefinições de cultura)
│   └── irrigacao/
│       ├── models/                 # IrrigationParameters, SimulationResult e
│       │                           # comum/: contratos dos métodos
│       │                           # (ProjetoMetodo, AnexoSimulacao, CodecMetodo),
│       │                           # adaptadores e identificação de irrigação
│       ├── services/               # Kostiakov-Lewis, lâmina requerida,
│       │                           # indicadores de performance, planejamento
│       │                           # operacional, registro_codecs (registry)
│       └── widgets/                # charts/, terrain/, formulários, KPIs
└── features/
    ├── irrigacao_sulcos/           # tipo de sulco, projeto, ensaios, resultados
    ├── irrigacao_faixas/
    ├── irrigacao_inundacao/
    ├── cenarios/                   # salva/carrega/exporta/importa/compara;
    │                               # CenarioSalvo, SimulationResultModel,
    │                               # project_store, providers, CSVs por método
    ├── perfil/                     # preferências (tema, fonte, alto contraste)
    └── simulacao_guiada/           # só encaminha: home → escolha do método → rota
```

## Regras de dependência

1. `app/router/app_router.dart` é o **único** arquivo que conhece todas as
   features; cada feature expõe suas rotas em `routes.dart`. As rotas de método
   são **subrotas do fluxo guiado** (`children` da rota `/home`) para preservar
   deep links — os caminhos em `routes.dart` são relativos, os absolutos ficam
   em `AppRoutes`. Navegue sempre via `AppRoutes`, nunca com strings soltas.
2. Fora da própria feature, importe apenas o barrel `<feature>.dart` (API
   pública). Exceção única: `features/cenarios` é a feature de integração —
   ela compõe as telas de resultados dos métodos e pode importar
   models/views/viewmodels de sulcos, faixas e inundação. Nenhuma outra
   feature tem esse privilégio.
3. Uma feature de método (sulcos/faixas/inundação) **não** importa outra
   feature de método.
4. `shared/` **não** importa `features/`. O compartilhado (de)codifica os
   projetos sem conhecê-los: cada feature registra um `CodecMetodo`
   (`codec_faixa.dart`, `codec_sulco.dart`, `codec_inundacao.dart`) no
   registry `registro_codecs.dart`, uma única vez em `app/codecs.dart` a
   partir de `main.dart`. A ordem de registro define a ordem das chaves de
   anexo no JSON persistido — não alterá-la sem atualizar também
   `test/architecture/ordem_chaves_persistencia_test.dart`.
5. `simulacao_guiada` só encaminha (`navigation/guia_de_metodos.dart`): não
   calcula, não salva cenário e importa apenas o barrel `perfil.dart`.
6. Cenários são abertos por `cenarioId` (query param `AppRoutes.cenarioId`);
   a tela de projeto da feature de destino lê o query param e hidrata o
   próprio controller (ex.: `project_screen.dart` de sulcos).
7. Use sempre imports `package:irrigasim/...`, inclusive dentro da própria
   feature (o codebase não usa imports relativos).

## Testes de arquitetura

`test/architecture/` contém guardrails (`shared_sem_features_test.dart`,
`ordem_chaves_persistencia_test.dart`). Nunca enfraqueça esses testes para
fazer uma mudança compilar; se a regra precisar mudar, discuta antes.

## Dívidas conhecidas

- O `README.md` ainda descreve a versão Kotlin Multiplatform antiga (agora é
  um app Flutter único).
- `shared/irrigacao/models/irrigation_parameters.dart` e
  `simulation_result.dart` são os DTOs legados "de todos os métodos"; o modelo
  canônico de resultado persistido é
  `features/cenarios/models/simulation_result_model.dart`.

## Validação obrigatória

Antes de cada commit:

```bash
dart format lib test
flutter analyze   # sem erros
flutter test      # verde
```

Testes de regressão numérica e de tela ficam em `test/`; nunca alterar os
valores esperados dos testes de regressão sem justificativa.
