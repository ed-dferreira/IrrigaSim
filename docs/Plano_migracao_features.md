# Plano de migração para arquitetura por features

> **Status:** proposta
> **Data:** 20/10/2026
> **Branch sugerida:** `refactor/features-isoladas`
> **Escopo:** reorganização estrutural do `lib/`, com isolamento progressivo das features e sem alterar as regras de cálculo.

> **Observação:** o bloco de ~43 linhas colado na conversa não chegou nesta sessão. Este plano foi derivado da leitura do código atual. Se o conteúdo for reenviado, os pontos de decisão da seção 11 podem ser ajustados.

---

## 1. Objetivo

Sair da organização atual — **camadas no topo e features dentro das camadas** (`models/faixas`, `views/irrigation/faixas`, etc.) — para uma organização **feature-first**, em que cada feature contém tudo o que é dela:

1. `irrigacao_sulcos`
2. `irrigacao_faixas`
3. `irrigacao_inundacao`
4. `cenarios`
5. `perfil`
6. `simulacao_guiada`

A simulação guiada deve ser uma feature **de entrada e encaminhamento**: ela apresenta o fluxo, coleta a escolha do método e navega para a feature correspondente. Ela não calcula, não salva cenário e não conhece os controllers das outras features.

O resultado esperado é:

- alterar uma feature sem precisar abrir as outras;
- remover imports cruzados entre métodos;
- deixar explícito o que é compartilhado (`shared/`) e o que é infraestrutura do app (`app/`, `core/`);
- permitir que `cenarios` e `perfil` evoluam de forma independente;
- manter o comportamento atual e os cenários já salvos funcionando.

### Resumo executivo

| Fase | Etapas | Entrega | Risco |
|------|--------|---------|-------|
| A — Preparação | 0–1 | Branch, baseline, `shared/` com contratos, cálculos e widgets | Médio |
| B — Features simples | 2–3 | `perfil` e `cenarios` isolados; abertura de cenário por `id` | Baixo/médio |
| C — Métodos | 4–6 | `faixas`, `inundacao` e `sulcos` isolados; controller central desmontado | Alto na etapa 6 |
| D — Entrada e rotas | 7–8 | `simulacao_guiada` só encaminha; rotas por feature | Médio |
| E — Fechamento | 9–10 | DTOs desacoplados, teste de fronteiras, docs e limpeza | Alto na etapa 9 |

As fases A–D já entregam a organização por features com comportamento preservado. A fase E é o que torna o isolamento **completo**, porque remove os DTOs que hoje conhecem todos os métodos.

**Trabalho paralelo:** as features podem ser construídas em branches separadas, mas a fundação (etapas 0–1) precisa estar pronta e congelada antes de abrir as branches paralelas. A estratégia completa está na seção 7.

---

## 2. O que já existe e ajuda

O projeto já tem uma boa base:

- Riverpod, `go_router` e `StatefulShellRoute` funcionando;
- features parcialmente separadas por método em `models/`, `services/`, `viewmodels/` e `views/`;
- testes de regressão numéricos e de tela em `test/features/irrigation/`;
- controllers próprios para faixas e inundação;
- um `AGENTS.md` que já declara a intenção de feature-first.

O que falta é **mover a fronteira**: hoje a divisão por camada vence a divisão por feature, e alguns arquivos compartilhados conhecem todos os métodos.

---

## 3. Diagnóstico do estado atual

### 3.1 Estrutura atual

```text
lib/
├── app/                  # app, router, tema
├── core/                 # navegação e widgets genéricos
├── models/
│   ├── cenarios/
│   ├── comum/
│   ├── faixas/
│   ├── inundacao/
│   ├── perfil/
│   ├── sulcos/
│   ├── irrigation_parameters.dart      # DTO "de todos"
│   ├── simulation_result.dart          # resultado "de todos"
│   └── simulation_result_model.dart    # serialização "de todos"
├── services/
│   ├── cenarios/
│   ├── perfil/
│   ├── persistence/
│   └── simulation/{faixas,inundacao,sulcos}
├── viewmodels/
│   ├── cenarios/
│   ├── faixas/
│   ├── inundacao/
│   ├── perfil/
│   ├── sulcos/
│   ├── parameters_controller.dart      # controller central (1.909 linhas)
│   └── results_controller.dart
└── views/
    ├── cenarios/
    ├── home/
    ├── perfil/
    ├── tutorial/
    └── irrigation/
        ├── faixas/
        ├── inundacao/
        ├── sulcos/
        └── widgets/                    # gráficos e componentes compartilhados
```

### 3.2 Acoplamentos que impedem o isolamento

| # | Sintoma | Onde está hoje | Por que atrapalha | Etapa que resolve |
|---|---------|----------------|-------------------|-------------------|
| 1 | `cenarios` importa controllers de faixas, inundação e o controller central | `views/cenarios/cenarios_screen.dart` | A tela de cenários conhece detalhes internos de três features e precisa mudar quando qualquer uma muda. | 3 |
| 2 | A tela genérica de resultados importa a tela de resultados de faixas | `views/irrigation/results_screen.dart` | O fluxo "rápido" virou um dispatcher que depende de outra feature. | 6 |
| 3 | Resultados de faixas importam widget de sulcos | `views/irrigation/faixas/border_results_screen.dart` | Um widget de terreno está no lugar errado; deveria ser compartilhado. | 4 |
| 4 | O modelo de inundação importa tipos de faixas | `models/inundacao/basin_project.dart` | `BorderStatus`/`BorderNotice` são conceitos de validação de superfície, não exclusivos de faixas. | 5 |
| 5 | `IrrigationParameters` importa projetos de sulcos, faixas e inundação | `models/irrigation_parameters.dart` | Um DTO compartilhado conhece todos os métodos. | 9 |
| 6 | `SimulationResult` e `SimulationResultModel` importam resultados e anexos de todos os métodos | `models/simulation_result.dart`, `models/simulation_result_model.dart` | O resultado compartilhado carrega campos específicos de cada método. | 9 |
| 7 | `CenarioSalvo` importa modelos dos três métodos | `models/cenarios/cenario_salvo.dart` | Salvar cenário depende de todos os métodos; qualquer mudança de método pode quebrar a persistência. | 9 |
| 7b | O adaptador da base comum importa projetos de faixas e sulcos | `models/comum/adaptadores_superficie.dart` | O "comum" depende de features, o que inverte a direção das dependências. | 9 |
| 8 | `ParametersController` concentra sulcos, faixas e inundação | `viewmodels/parameters_controller.dart` | É o maior bloqueio para isolar sulcos: a feature não consegue ser dona do próprio estado. | 6 |
| 9 | Home, tutorial e tela de irrigação repetem a mesma navegação por método | `views/home`, `views/tutorial`, `views/irrigation/irrigation_screen.dart` | Três cópias da mesma regra de encaminhamento. | 7 |
| 10 | O roteador conhece todas as telas e todos os caminhos | `app/router/app_router.dart` | Toda feature nova exige editar o arquivo central. | 8 |

### 3.3 O que é realmente compartilhado

| Grupo | Exemplos | Destino |
|-------|----------|---------|
| Contratos de irrigação | `MetodoIrrigacao`, `IrrigationParameters`, `SimulationResult`, `SimulationResultModel` | `shared/irrigacao/` (com dívida controlada até a etapa 9) |
| Base comum agronômica | `models/comum/*` | `shared/irrigacao/models/comum/` |
| Matemática comum | `kostiakov_lewis`, `blaney_criddle`, `lamina_requerida`, `performance_indicators`, `surface_irrigation_math`, `units_service` | `shared/irrigacao/services/` |
| Widgets/gráficos usados por mais de um método | `advance_chart`, `infiltration_chart`, `water_balance_chart`, `performance_bars_chart`, `scenario_comparison_chart`, `opportunity_time_chart`, `auditable_widgets`, `irrigation_project_components`, `terrain_view`/`terrain_painter` | `shared/irrigacao/widgets/` |
| Persistência de cenários | `CenarioSalvo`, `ScenarioService`, `LocalScenarioStore`, providers | `shared/cenarios/` |
| Salvar cenário a partir de resultados | `ResultsController` | `shared/cenarios/controllers/` |
| Tema, acessibilidade global, shell | `app/theme`, `core/navigation`, `core/widgets` | mantêm-se em `app/` e `core/` |

> **Decisão importante:** `CenarioSalvo`, `ScenarioService` e `LocalScenarioStore` ficam em `shared/cenarios/`, e não em `features/cenarios/`. O motivo é evitar dependência circular: as três features de método precisam **salvar** cenários, e a feature `cenarios` precisa **abrir** cenários das três. O contrato fica no compartilhado; a interação do usuário (histórico, busca, detalhes, exclusão) fica na feature.

---

## 4. Arquitetura alvo

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart          # composition root: junta as rotas das features
│   │   └── app_routes.dart          # caminhos e nomes canônicos
│   └── theme/
├── core/
│   ├── navigation/
│   ├── widgets/
│   └── accessibility/               # se necessário no futuro
├── shared/
│   ├── irrigacao/
│   │   ├── models/
│   │   │   ├── comum/
│   │   │   ├── irrigation_parameters.dart
│   │   │   ├── simulation_result.dart
│   │   │   ├── simulation_result_model.dart
│   │   │   └── validacao_superficie.dart   # BorderStatus, BorderNotice
│   │   ├── services/
│   │   │   ├── units_service.dart
│   │   │   ├── blaney_criddle.dart
│   │   │   ├── kostiakov_lewis.dart
│   │   │   ├── lamina_requerida.dart
│   │   │   ├── operational_planning.dart
│   │   │   ├── performance_indicators.dart
│   │   │   └── surface_irrigation_math.dart
│   │   └── widgets/
│   │       ├── charts/
│   │       ├── auditable_widgets.dart
│   │       ├── irrigation_project_components.dart
│   │       └── terrain/
│   └── cenarios/
│       ├── models/cenario_salvo.dart
│       ├── services/scenario_service.dart
│       ├── services/project_store.dart
│       ├── persistence/local_scenario_store.dart
│       ├── providers/scenario_providers.dart
│       └── controllers/salvar_cenario_controller.dart
└── features/
    ├── irrigacao_sulcos/
    │   ├── models/
    │   ├── services/
    │   ├── viewmodels/
    │   ├── views/
    │   │   └── widgets/
    │   ├── routes.dart
    │   └── irrigacao_sulcos.dart        # API pública da feature
    ├── irrigacao_faixas/
    │   ├── models/
    │   ├── services/
    │   ├── viewmodels/
    │   ├── views/
    │   ├── routes.dart
    │   └── irrigacao_faixas.dart
    ├── irrigacao_inundacao/
    │   ├── models/
    │   ├── services/
    │   ├── viewmodels/
    │   ├── views/
    │   ├── routes.dart
    │   └── irrigacao_inundacao.dart
    ├── cenarios/
    │   ├── views/
    │   │   ├── cenarios_screen.dart
    │   │   └── widgets/
    │   ├── routes.dart
    │   └── cenarios.dart                # API pública (se necessário)
    ├── perfil/
    │   ├── models/
    │   ├── services/
    │   ├── viewmodels/
    │   ├── views/
    │   ├── routes.dart
    │   └── perfil.dart
    └── simulacao_guiada/
        ├── views/
        │   ├── home_screen.dart
        │   ├── selecionar_metodo_screen.dart
        │   └── widgets/
        ├── navigation/guia_de_metodos.dart
        ├── routes.dart
        └── simulacao_guiada.dart
```

### 4.1 Regras de dependência

```text
app  ──────────────► features (rotas e telas)
app  ──────────────► shared
features ──────────► shared
features ──────────► core
feature A ──✖──────► feature B   (views/viewmodels)
simulacao_guiada ──► app_routes + API pública de perfil (somente leitura)
shared ──✖─────────► features
```

Regras práticas:

1. **Dentro da feature:** imports relativos.
2. **Fora da feature:** import de pacote (`package:irrigasim/...`).
3. **Uma feature não importa `views/` nem `viewmodels/` de outra.**
4. **Uma feature de método não importa outra feature de método.**
5. **`shared/` não importa `features/`.**
6. **`app/router/app_router.dart` é o único lugar que conhece todas as features.**
7. **`simulacao_guiada` só pode importar caminhos/rotas e, no máximo, a API pública de `perfil` para saudação.**
8. **`cenarios` abre cenários por `id` de rota**, não carregando controllers de outras features.

### 4.2 O que entra em cada camada da feature

| Pasta | Responsabilidade | Exemplo |
|-------|------------------|---------|
| `models/` | Estado e contratos imutáveis da feature | `BorderProject`, `BasinProject`, `IrrigationProject` |
| `services/` | Cálculo e integrações específicas do método | `run_border_simulation.dart` |
| `viewmodels/` | Riverpod, orquestração de tela e fluxo | `BorderProjectController` |
| `views/` | Telas e widgets exclusivos | `border_project_screen.dart` |
| `routes.dart` | Rotas da feature | `GoRoute(path: '/faixas/projeto', ...)` |
| `<feature>.dart` | Barrel com a API pública mínima | exporta provider e modelo necessários |

---

## 5. Mapa de rotas

### 5.1 Fase estrutural: manter os caminhos atuais

Para não quebrar deep links nem testes, a primeira migração **não muda os caminhos**:

| Tela | Caminho atual | Feature dona depois |
|------|---------------|---------------------|
| Home / simulação guiada | `/home` | `simulacao_guiada` |
| Escolha do método (tutorial) | `/home/tutorial` | `simulacao_guiada` |
| Sulcos — tipo | `/home/irrigation/tipo-sulco` | `irrigacao_sulcos` |
| Sulcos — projeto | `/home/irrigation/project` | `irrigacao_sulcos` |
| Sulcos — resultados | `/home/irrigation/project-results` | `irrigacao_sulcos` |
| Faixas — projeto | `/home/irrigation/border-project` | `irrigacao_faixas` |
| Faixas — resultados | `/home/irrigation/border-results` | `irrigacao_faixas` |
| Inundação — projeto | `/home/irrigation/basin-project` | `irrigacao_inundacao` |
| Inundação — resultados | `/home/irrigation/basin-results` | `irrigacao_inundacao` |
| Inundação — referência | `/home/irrigation/basin-reference` | `irrigacao_inundacao` |
| Cenários | `/cenarios` | `cenarios` |
| Perfil | `/perfil` | `perfil` |

### 5.2 Fase posterior: caminhos canônicos

Depois que a estrutura estiver estável, avaliar caminhos mais curtos, **com redirect dos antigos por pelo menos uma versão**:

```text
/sulcos/projeto
/sulcos/resultados
/faixas/projeto
/faixas/resultados
/inundacao/projeto
/inundacao/resultados
/inundacao/referencia
/simulacao-guiada
```

Não fazer essa renomeação junto com a movimentação de arquivos. São duas mudanças independentes.

### 5.3 Abertura de cenário por id

Novo contrato de navegação:

```text
/home/irrigation/project?cenarioId=<uuid>
/home/irrigation/border-project?cenarioId=<uuid>
/home/irrigation/basin-project?cenarioId=<uuid>
```

Cada tela de projeto:

1. lê `cenarioId` da rota;
2. busca o cenário em `scenarioServiceProvider`;
3. entrega os dados ao **próprio** controller;
4. remove o `cenarioId` da URL ou segue o fluxo normal.

Assim, `cenarios` não importa `BorderProjectController`, `BasinProjectController` nem `ParametersController`.

---

## 6. Plano por etapas

Cada etapa deve terminar com `flutter analyze` e `flutter test` verdes e um commit próprio. As etapas 1–8 são estruturais; a 9 é a que remove a dívida dos DTOs; a 10 cria a proteção para o futuro.

### Etapa 0 — Baseline e rede de segurança

**Objetivo:** saber exatamente o que não pode quebrar.

**Ações:**

- [ ] Criar a branch `refactor/features-isoladas`.
- [ ] Rodar e registrar:
  ```bash
  flutter pub get
  flutter analyze
  flutter test
  ```
- [ ] Salvar a lista de arquivos e o grafo de imports atual:
  ```bash
  find lib -type f -name '*.dart' | sort > /tmp/irrigasim-antes.txt
  grep -rhoP "package:irrigasim/\\K[^']+" lib | sort -u > /tmp/irrigasim-imports-antes.txt
  ```
- [ ] Fazer um commit vazio de marcação (`chore: inicia refatoração por features`) ou anotar o hash base.
- [ ] Testar manualmente o fluxo completo: home → cada método → resultados → salvar → cenários → reabrir → perfil.

**Validação:** todos os testes passam antes de qualquer mudança.

**Risco:** baixo.

---

### Etapa 1 — Criar o esqueleto e mover o que é realmente compartilhado

**Objetivo:** tirar do caminho os contratos, cálculos e widgets usados por mais de um método. Ainda não há feature nova; só o `shared/` nasce.

> Na estratégia de branches paralelas (seção 7), esta etapa é a **branch-base** e inclui também `app_routes.dart`, os barris públicos e os `routes.dart` de cada feature. Ela precisa ser mergeada antes de abrir as branches paralelas.

**Ações:**

1. Criar:
   ```text
   lib/shared/irrigacao/{models,services,widgets}
   lib/shared/cenarios/{models,services,persistence,providers,controllers}
   lib/features/
   ```
2. Mover com `git mv` (preserva histórico):
   - `models/comum/*` → `shared/irrigacao/models/comum/`
   - `models/irrigation_parameters.dart` → `shared/irrigacao/models/`
   - `models/simulation_result.dart` → `shared/irrigacao/models/`
   - `models/simulation_result_model.dart` → `shared/irrigacao/models/`
   - `services/units_service.dart` → `shared/irrigacao/services/`
   - `services/simulation/{blaney_criddle,kostiakov_lewis,lamina_requerida,operational_planning,performance_indicators,surface_irrigation_math}.dart` → `shared/irrigacao/services/`
   - `views/irrigation/widgets/{advance_chart,infiltration_chart,water_balance_chart,performance_bars_chart,scenario_comparison_chart,opportunity_time_chart,auditable_widgets,irrigation_project_components}.dart` → `shared/irrigacao/widgets/`
   - `views/irrigation/sulcos/widgets/{terrain_view,terrain_painter}.dart` → `shared/irrigacao/widgets/terrain/`
   - `models/cenarios/cenario_salvo.dart` → `shared/cenarios/models/`
   - `services/cenarios/scenario_service.dart` → `shared/cenarios/services/`
   - `services/persistence/local_scenario_store.dart` → `shared/cenarios/persistence/`
   - `services/persistence/project_store.dart` → `shared/cenarios/services/`
   - `viewmodels/cenarios/scenario_providers.dart` → `shared/cenarios/providers/`
   - `viewmodels/results_controller.dart` → `shared/cenarios/controllers/salvar_cenario_controller.dart` (renomear classe/provedor junto ou em etapa separada)
3. Atualizar todos os imports. Fazer de forma mecânica e conferir com:
   ```bash
   grep -rn "models/irrigation_parameters.dart\|models/simulation_result.dart\|views/irrigation/widgets" lib test
   ```
4. Atualizar os imports dos testes.
5. Rodar `dart format` nos arquivos alterados, `flutter analyze` e `flutter test`.

**Validação:**

- `flutter analyze` sem erros;
- `flutter test` verde;
- nenhum arquivo referenciando os caminhos antigos.

**Risco:** médio — é muita movimentação mecânica. Mitigação: um commit só para contratos e outro só para widgets.

**Dívida assumida:** `shared/irrigacao/models/irrigation_parameters.dart` ainda importa modelos de métodos. Isso será resolvido na etapa 9. Até lá, `shared → features` é uma exceção documentada.

---

### Etapa 2 — Extrair `perfil`

**Objetivo:** primeira feature isolada e de baixo risco.

**Mover:**

```text
models/perfil/tamanho_fonte.dart              → features/perfil/models/
services/perfil/preferencias_app.dart         → features/perfil/services/
viewmodels/perfil/perfil_controller.dart      → features/perfil/viewmodels/
views/perfil/perfil_screen.dart               → features/perfil/views/
```

**Criar:**

- `features/perfil/perfil.dart` exportando `perfilProvider`, `PerfilState`, `PerfilScreen`;
- `features/perfil/routes.dart` com a rota `/perfil`.

**Atualizar:**

- `app/app.dart` (tema/acessibilidade);
- `features/simulacao_guiada/views/home_screen.dart` (saudação e botão de tema);
- `app/router/app_router.dart` (usar a rota da feature).

**Validação:**

- tema claro/escuro, tamanho de fonte, alto contraste, negrito, leitor de tela e animações reduzidas continuam funcionando;
- `perfilProvider` continua sendo observado no `MaterialApp`;
- testes existentes verdes.

**Risco:** baixo.

---

### Etapa 3 — Extrair `cenarios`

**Objetivo:** transformar a tela de histórico em uma feature que **interage** com cenários, sem conhecer os controllers dos métodos.

**Mover:**

```text
views/cenarios/cenarios_screen.dart → features/cenarios/views/cenarios_screen.dart
```

**Dividir a tela (recomendado):**

- `cenarios_screen.dart` — lista, busca, empty state;
- `widgets/cenario_card.dart` — card e KPIs;
- `widgets/cenario_details_sheet.dart` — bottom sheet de detalhes;
- `widgets/cenario_empty_state.dart` — estado vazio.

**Trocar a abertura direta por rota + id:**

Hoje a tela faz:

```dart
ref.read(borderProjectProvider.notifier).carregar(projeto);
context.go('/home/irrigation/border-project');
```

Depois:

```dart
context.go('/home/irrigation/border-project?cenarioId=${cenario.id}');
```

E cada tela de projeto hidrata o próprio controller.

**Remover da feature `cenarios`:**

- imports de `viewmodels/faixas/border_project_controller.dart`;
- imports de `viewmodels/inundacao/basin_project_controller.dart`;
- imports de `viewmodels/parameters_controller.dart`;
- conhecimento de `projetoFaixa`/`projetoInundacao`/`entradasProjetoSulco`.

**Adicionar suporte a `cenarioId` nas três telas de projeto** (pode ser feito nesta etapa ou na etapa de cada feature):

- `/home/irrigation/project`
- `/home/irrigation/border-project`
- `/home/irrigation/basin-project`

**Validação:**

- salvar um cenário de cada método;
- listar, buscar por nome e por método;
- abrir detalhes e reabrir nas entradas;
- excluir;
- cenário antigo (legado) continua abrindo;
- `flutter test test/features/irrigation/border_results_screen_test.dart` e equivalentes.

**Risco:** médio — a persistência é o contrato mais sensível. Não alterar `toMap`/`fromMap` nesta etapa; só mover e mudar a navegação.

---

### Etapa 4 — Extrair `irrigacao_faixas`

**Objetivo:** primeira feature de método completa.

**Mover:**

```text
models/faixas/*                          → features/irrigacao_faixas/models/
services/simulation/faixas/*             → features/irrigacao_faixas/services/
viewmodels/faixas/*                      → features/irrigacao_faixas/viewmodels/
views/irrigation/faixas/*                → features/irrigacao_faixas/views/
```

**Corrigir dependências:**

- `border_results_screen.dart` importa `views/irrigation/sulcos/widgets/terrain_view.dart` → usar `shared/irrigacao/widgets/terrain/`;
- confirmar que `border_project_screen.dart` usa apenas `shared/` para `IrrigationParameters` e componentes;
- mover `BorderStatus`/`BorderNotice` para `shared/irrigacao/models/validacao_superficie.dart` (se ainda não foi feito; ver etapa 5).

**Criar:**

- `features/irrigacao_faixas/irrigacao_faixas.dart` com a API pública (providers e modelos que outras features realmente precisam);
- `features/irrigacao_faixas/routes.dart`.

**Atualizar:**

- `app/router/app_router.dart`;
- `shared/cenarios` (apenas se o codec ainda estiver acoplado);
- testes que importam `package:irrigasim/models/faixas/...`, `viewmodels/faixas/...` e `views/irrigation/faixas/...`.

**Validação:**

- `border_reference_golden_test`, `border_hydraulics_test`, `border_planning_test`, `border_project_controller_test`, `border_project_screen_test`, `border_results_screen_test`;
- fluxo manual de faixas: projeto → resultados → salvar → reabrir.

**Risco:** médio.

---

### Etapa 5 — Extrair `irrigacao_inundacao`

**Objetivo:** isolar inundação e eliminar o empréstimo de tipos de faixas.

**Mover:**

```text
models/inundacao/*                       → features/irrigacao_inundacao/models/
services/simulation/inundacao/*          → features/irrigacao_inundacao/services/
viewmodels/inundacao/*                   → features/irrigacao_inundacao/viewmodels/
views/irrigation/inundacao/*             → features/irrigacao_inundacao/views/
```

**Extrair tipos compartilhados de validação:**

`BorderStatus`, `BorderNotice` e tipos correlatos usados por faixas e inundação devem ir para:

```text
shared/irrigacao/models/validacao_superficie.dart
```

Depois:

- `shared/irrigacao/models/validacao_superficie.dart` não importa nenhuma feature;
- `features/irrigacao_faixas/models/border_result.dart` importa o compartilhado;
- `features/irrigacao_inundacao/models/basin_project.dart` importa o compartilhado;
- `basin_results_screen.dart` deixa de importar `models/faixas/border_result.dart`.

**Criar:**

- `features/irrigacao_inundacao/irrigacao_inundacao.dart`;
- `features/irrigacao_inundacao/routes.dart`.

**Atualizar:**

- `app/router/app_router.dart`;
- testes `basin_*` e `inundacao_*`.

**Validação:**

- golden tests de inundação;
- os dois regimes (intermitente e permanente);
- fluxo manual: projeto → resultados → salvar → reabrir;
- tela de referência.

**Risco:** médio — os tipos de validação são usados em serialização e testes.

---

### Etapa 6 — Extrair `irrigacao_sulcos` e desmontar o controller central

**Objetivo:** a etapa mais delicada. Sulcos é a feature mais entrelaçada com o fluxo genérico.

**6a. Mover os arquivos específicos de sulcos:**

```text
models/sulcos/*                          → features/irrigacao_sulcos/models/
services/simulation/sulcos/*             → features/irrigacao_sulcos/services/
viewmodels/sulcos/*                      → features/irrigacao_sulcos/viewmodels/
views/irrigation/sulcos/*                → features/irrigacao_sulcos/views/
```

**6b. Renomear o controller central sem mudar lógica:**

```text
viewmodels/parameters_controller.dart
  → features/irrigacao_sulcos/viewmodels/furrow_project_controller.dart
```

Renomear:

- `ParametersController` → `FurrowProjectController`;
- `ParametersState` → `FurrowProjectState`;
- `parametersProvider` → `furrowProjectProvider`.

Nesta subetapa, **não** remover campos nem branches. Apenas mover e renomear, atualizando:

- `tipo_sulco_screen.dart`;
- `project_screen.dart`;
- `project_results_screen.dart`;
- `results_screen.dart` (enquanto existir);
- `cenarios_screen.dart` (se ainda usar);
- testes.

**6c. Remover dos sulcos o que é de faixas/inundação:**

- remover `setMetodo`, `setTipoInundacao` e campos de inundação do controller de sulcos;
- `executarSimulacao` passa a chamar somente `FurrowSimulationCoordinator`;
- remover branches `MetodoIrrigacao.faixa` e `MetodoIrrigacao.inundacao`;
- manter `toIrrigationParameters()` apenas como adaptador de persistência/exportação até a etapa 9.

**6d. Aposentar o fluxo rápido genérico:**

Arquivos:

```text
views/irrigation/parameters_screen.dart
views/irrigation/results_screen.dart
```

Eles só são alcançados hoje por:

- fallback inalcançável em `home_screen.dart`, `tutorial_screen.dart` e `irrigation_screen.dart` (o enum só tem três valores);
- cenário legado de faixa em `cenarios_screen.dart`.

Antes de removê-los:

1. fazer o cenário legado de faixa abrir `/home/irrigation/border-project?cenarioId=...`;
2. garantir que `BorderProject.fromLegacy` cobre os dados antigos;
3. remover as rotas `/home/irrigation/parameters` e `/home/irrigation/results`;
4. remover os arquivos e seus testes/imports.

**Criar:**

- `features/irrigacao_sulcos/irrigacao_sulcos.dart`;
- `features/irrigacao_sulcos/routes.dart`.

**Validação:**

- `furrow_domain_test`, `furrow_balance_test`, `furrow_erosion_reduction_test`, `furrow_project_contract_test`, `project_step_navigation_test`, `project_results_screen_test`, `integration_corn_project_test`, `length_and_advance_planning_test`, `domain_calculation_regressions_test`;
- fluxo manual completo de sulcos, incluindo ensaios, Criddle, manejo reduzido e salvamento.

**Risco:** alto. Mitigação: dividir em 6a, 6b, 6c e 6d, cada uma com commit e testes próprios. Não reescrever fórmulas; apenas mover e remover branches.

---

### Etapa 7 — Extrair `simulacao_guiada`

**Objetivo:** uma feature de entrada que só encaminha.

**Mover:**

```text
views/home/home_screen.dart              → features/simulacao_guiada/views/home_screen.dart
views/tutorial/tutorial_screen.dart      → features/simulacao_guiada/views/selecionar_metodo_screen.dart
views/irrigation/irrigation_screen.dart  → remover (duplicata do seletor)
views/irrigation/widgets/irrigation_method_card.dart
                                         → features/simulacao_guiada/views/widgets/
```

**Criar:**

```dart
// features/simulacao_guiada/navigation/guia_de_metodos.dart
enum MetodoGuiado { sulcos, faixas, inundacao }

extension MetodoGuiadoDestino on MetodoGuiado {
  String get rota => switch (this) {
    MetodoGuiado.sulcos => AppRoutes.sulcosTipo,
    MetodoGuiado.faixas => AppRoutes.faixasProjeto,
    MetodoGuiado.inundacao => AppRoutes.inundacaoProjeto,
  };
}
```

**Remover da feature guiada:**

- `ref.read(parametersProvider.notifier).setMetodo(...)`;
- qualquer import de controller de método;
- qualquer cálculo, salvamento ou conhecimento de projeto.

O único estado que ela pode ler é o nome do usuário, via API pública de `perfil`, para a saudação da home.

**Consolidar:**

- a home e o tutorial passam a usar o mesmo `SelecionarMetodoScreen`/widget de cards;
- a regra "método → rota" existe em um único lugar;
- `home_method_navigation_test` é atualizado para verificar as três rotas.

**Validação:**

- home → "Começar com ajuda" → escolher método → tela de projeto correta;
- home → card de método → tela de projeto correta;
- botão voltar do sistema funciona;
- nenhum import de `features/irrigacao_*` na feature guiada.

**Risco:** baixo/médio.

---

### Etapa 8 — Rotas por feature e composition root

**Objetivo:** parar de editar um roteador monolítico a cada feature nova.

**Ações:**

1. Criar `app/router/app_routes.dart` com constantes:
   ```dart
   abstract final class AppRoutes {
     static const home = '/home';
     static const guiada = '/home/tutorial';
     static const sulcosProjeto = '/home/irrigation/project';
     static const sulcosResultados = '/home/irrigation/project-results';
     static const sulcosTipo = '/home/irrigation/tipo-sulco';
     static const faixasProjeto = '/home/irrigation/border-project';
     static const faixasResultados = '/home/irrigation/border-results';
     static const inundacaoProjeto = '/home/irrigation/basin-project';
     static const inundacaoResultados = '/home/irrigation/basin-results';
     static const inundacaoReferencia = '/home/irrigation/basin-reference';
     static const cenarios = '/cenarios';
     static const perfil = '/perfil';
   }
   ```
2. Cada feature expõe `routes.dart` com suas `GoRoute`s.
3. `app_router.dart` passa a apenas compor:
   ```dart
   StatefulShellRoute.indexedStack(
     builder: ...,
     branches: [
       StatefulShellBranch(routes: simulacaoGuiadaRoutes),
       StatefulShellBranch(routes: cenariosRoutes),
       StatefulShellBranch(routes: perfilRoutes),
     ],
   )
   ```
4. As subrotas de método ficam aninhadas sob a rota da simulação guiada, mas definidas nos `routes.dart` de cada método.
5. **Não renomear caminhos nesta etapa.** Renomeações futuras usam `redirect`.

**Validação:**

- todos os caminhos atuais continuam respondendo;
- deep links existentes continuam funcionando;
- `flutter test test/features/irrigation/home_method_navigation_test.dart`;
- teste manual de navegação e botão voltar.

**Risco:** médio — `go_router` com `StatefulShellRoute` exige atenção à hierarquia.

---

### Etapa 9 — Desacoplar os DTOs compartilhados (dívida dos métodos)

**Objetivo:** remover a última e mais profunda dependência: os contratos "de todos".

Hoje:

- `IrrigationParameters` tem campos de sulcos, `projetoFaixa` e `projetoInundacao`;
- `SimulationResult` tem `borderResult`, `balancoSulco`, anexos de inundação;
- `SimulationResultModel` serializa todos;
- `CenarioSalvo` serializa todos.

**Estratégia recomendada (strangler):**

1. **Envelope de cenário:**
   ```dart
   class CenarioSalvo {
     final String id;
     final String nome;
     final MetodoIrrigacao metodo;
     final Map<String, dynamic> parametros; // payload do método
     final Map<String, dynamic> resultado;  // payload do método
     final CenarioResumo resumo;            // KPIs para a lista
     final DateTime dataCriacao;
     final DateTime dataModificacao;
   }
   ```
   `CenarioResumo` guarda apenas o que a tela de cenários mostra (eficiência, CUC, lâmina média, método, nome, datas). Assim, `cenarios` não precisa decodificar projeto/resultado para listar.

2. **Codec por feature:**
   ```dart
   abstract interface class CenarioCodec {
     MetodoIrrigacao get metodo;
     Map<String, dynamic> encodeParametros(...);
     Map<String, dynamic> encodeResultado(...);
     ...
   }
   ```
   Cada feature implementa o seu e registra em um `CenarioCodecRegistry` no `app/` (composition root) ou em `shared/cenarios/`.

3. **Compatibilidade:**
   - manter leitura dos JSONs antigos;
   - adicionar testes com fixtures reais de cenários salvos antes da refatoração;
   - nunca alterar os valores esperados dos testes de regressão.

4. **`IrrigationParameters` e `SimulationResult`:**
   - aposentar como DTO principal;
   - manter adaptadores temporários apenas para exportação/legado;
   - mover o que for realmente comum para `shared/irrigacao/models/` sem importar features.

5. **`ProjectStore`:**
   - vira `shared/cenarios/services/project_store.dart` usando os codecs, ou
   - vira um exportador em `app/` que conhece o registry.

**Validação:**

- abrir um cenário salvo antes da refatoração e outro depois;
- comparar JSON exportado antes/depois;
- todos os testes de persistência e golden;
- `shared/` sem imports de `features/`.

**Risco:** alto. Esta etapa pode ser um projeto separado. As etapas 1–8 entregam a organização por features com uma dívida explicitamente documentada; a 9 fecha o isolamento de domínio.

---

### Etapa 10 — Guardrails, documentação e limpeza

**Objetivo:** impedir regressão arquitetural.

**Ações:**

1. Criar `test/architecture/feature_boundaries_test.dart` (ou `tool/check_feature_boundaries.dart`) que:
   - percorre `lib/features/*`;
   - lê os imports;
   - falha se uma feature importar `views/` ou `viewmodels/` de outra;
   - falha se uma feature de método importar outra feature de método;
   - falha se `shared/` importar `features/`;
   - permite exceções explícitas e documentadas.
2. Rodar esse teste no CI (`.github/workflows`).
3. Atualizar `AGENTS.md`:
   - nova árvore;
   - regras de dependência;
   - o que é `shared/`;
   - onde ficam as rotas.
4. Atualizar o `README.md` (a seção de arquitetura ainda descreve Kotlin Multiplatform, o que não corresponde ao código atual).
5. Remover pastas vazias:
   ```bash
   find lib -type d -empty -delete
   ```
6. Rodar a validação final:
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   ```

**Critérios de aceite:**

- [ ] `lib/features/<feature>` contém tudo o que é da feature.
- [ ] Nenhuma feature importa `views/` ou `viewmodels/` de outra.
- [ ] `simulacao_guiada` só encaminha.
- [ ] `cenarios` abre cenários por `id`, sem carregar controllers de métodos.
- [ ] `shared/` não importa `features/` (após a etapa 9).
- [ ] `app_router.dart` só compõe rotas.
- [ ] Um cenário de cada método salva, lista e reabre.
- [ ] `flutter analyze` e `flutter test` verdes.
- [ ] Pastas antigas (`models/`, `services/`, `viewmodels/`, `views/`) removidas.

---

## 7. Estratégia de branches e trabalho paralelo

### 7.1 Premissa

É possível construir as seis features em paralelo, mas **não é possível paralelizar a fundação**. Se cada branch mover os mesmos arquivos compartilhados e editar o mesmo `app_router.dart`, o custo de merge será maior que o ganho.

A regra é:

> **Primeiro congela-se a fundação. Depois as features evoluem em paralelo.**

A fundação é composta por:

- criação de `lib/features/` e `lib/shared/`;
- movimentação dos contratos, cálculos e widgets compartilhados (etapa 1);
- `app/router/app_routes.dart` com todos os caminhos;
- `routes.dart` e barrel público de cada feature (mesmo que inicialmente apontem para as telas antigas);
- `app_router.dart` compondo as rotas por feature;
- extração de `BorderStatus`/`BorderNotice` para `shared/`;
- contrato de abertura de cenário por `id`;
- `AGENTS.md` com as regras de dependência.

Depois disso, cada feature mexe apenas na própria pasta.

### 7.2 Modelo de branches

```text
main
└── refactor/features-isoladas          # tronco da refatoração (fundação)
    ├── refactor/perfil
    ├── refactor/faixas
    ├── refactor/inundacao
    ├── refactor/sulcos
    ├── refactor/cenarios
    ├── refactor/guiada
    └── refactor/divida-dtos            # etapa 9, depois das estruturais
```

Fluxo:

1. `refactor/features-isoladas` nasce de `main`.
2. Recebe as etapas 0 e 1 + os contratos congelados.
3. As branches de feature nascem dela.
4. Cada branch abre PR de volta para `refactor/features-isoladas`.
5. Quando todas estiverem integradas e verdes, `refactor/features-isoladas` abre PR para `main`.

Não criar uma branch de feature a partir de `main` enquanto a fundação não estiver no tronco.

### 7.3 O que a branch-base precisa entregar

Antes de abrir as branches paralelas, a base deve ter:

- [ ] `lib/shared/irrigacao/` com contratos, serviços e widgets da etapa 1.
- [ ] `lib/shared/cenarios/` com modelo, serviço, store, providers e controller de salvamento.
- [ ] `lib/shared/irrigacao/models/validacao_superficie.dart` com `BorderStatus`/`BorderNotice`.
- [ ] `lib/app/router/app_routes.dart` com todos os caminhos atuais.
- [ ] `lib/features/<feature>/routes.dart` para as seis features, apontando para as telas existentes.
- [ ] `lib/features/<feature>/<feature>.dart` com a API pública mínima (barrel), usando **re-export temporário** dos caminhos antigos.
- [ ] `app_router.dart` compondo as rotas a partir dos `routes.dart`.
- [ ] Estratégia de compatibilidade para os DTOs que ainda importam modelos de método (ver 7.12).
- [ ] Contrato `cenarioId` documentado e constante de query param definida.
- [ ] `AGENTS.md` atualizado com as regras de dependência.
- [ ] `flutter analyze` e `flutter test` verdes.

> **Por que os barrels entram na base?** Porque eles são o contrato entre as features. Se cada branch criar o seu, a branch de `cenarios` e a de `sulcos` podem divergir no nome do provider ou do modelo. Com o barrel congelado, cada branch sabe exatamente o que pode importar.

### 7.4 Matriz de propriedade

| Área | Dono | Outras branches podem editar? |
|------|------|-------------------------------|
| `lib/shared/**` | branch-base | Não. Mudanças via PR pequeno para a base. |
| `lib/core/**` | branch-base | Não. |
| `lib/app/router/app_routes.dart` | branch-base | Não. |
| `lib/app/router/app_router.dart` | branch-base/integração | Não. |
| `lib/features/perfil/**` | `refactor/perfil` | Não. |
| `lib/features/cenarios/**` | `refactor/cenarios` | Não. |
| `lib/features/irrigacao_faixas/**` | `refactor/faixas` | Não. |
| `lib/features/irrigacao_inundacao/**` | `refactor/inundacao` | Não. |
| `lib/features/irrigacao_sulcos/**` | `refactor/sulcos` | Não. |
| `lib/features/simulacao_guiada/**` | `refactor/guiada` | Não. |
| `test/features/<feature>/**` | branch da feature | Não. |
| `pubspec.yaml` | branch-base | Não. |
| `AGENTS.md`, `README.md` | branch de docs/integração | Não durante as features. |

Se uma feature precisar mudar algo compartilhado:

1. abre um PR pequeno e isolado para `refactor/features-isoladas`;
2. a base é mergeada;
3. todas as branches fazem `git rebase refactor/features-isoladas`;
4. a feature continua.

Isso evita que uma branch de feature altere o contrato das outras.

### 7.5 Contratos que precisam estar congelados

| Contrato | Onde fica | Quem usa |
|----------|-----------|----------|
| `MetodoIrrigacao` e enums comuns | `shared/irrigacao/models/` | Todas |
| `IrrigationParameters`, `SimulationResult` | `shared/irrigacao/models/` | Todas (até a etapa 9) |
| `CenarioSalvo`, `ScenarioService` | `shared/cenarios/` | Todas |
| `scenarioServiceProvider` | `shared/cenarios/providers/` | Todas |
| `salvarCenarioProvider` | `shared/cenarios/controllers/` | Resultados de todos os métodos |
| `AppRoutes.*` | `app/router/app_routes.dart` | Todas |
| `cenarioId` (query param) | `AppRoutes` ou constante compartilhada | `cenarios` e métodos |
| `perfilProvider` | `features/perfil/perfil.dart` | `simulacao_guiada` (somente leitura) |
| `routes.dart` de cada feature | própria feature | `app_router.dart` |

### 7.6 Dependências entre as branches

| Branch | Depende de | Pode começar em paralelo? | Observação |
|--------|------------|----------------------------|------------|
| `refactor/perfil` | base | Sim | Baixo risco, 4 arquivos. |
| `refactor/faixas` | base (`shared` + `terrain` + validação) | Sim | Não toca em outras features. |
| `refactor/inundacao` | base (`validacao_superficie`) | Sim | Depende da extração de `BorderStatus` feita na base. |
| `refactor/sulcos` | base (`shared` + barris) | Sim, mas é a mais longa | Dividir em subcommits: mover, renomear controller, remover branches, aposentar fluxo rápido. |
| `refactor/cenarios` | base (`shared/cenarios` + contrato `cenarioId`) | Sim | A abertura por `id` só funciona de ponta a ponta quando as branches de método estiverem integradas. Testar a navegação com mock/rota. |
| `refactor/guiada` | base (`AppRoutes` + `routes.dart`) | Sim | As rotas de método já existem na base apontando para as telas antigas. |
| `refactor/divida-dtos` | todas as estruturais | Não | Alto conflito com `shared/` e com os três métodos. Fazer depois da integração das features. |

### 7.7 Conflitos previsíveis e como evitar

| Arquivo/área | Risco de conflito | Estratégia |
|--------------|-------------------|------------|
| `app_router.dart` | Alto se cada branch editar | Base compõe; feature só edita seu `routes.dart`. |
| `app_routes.dart` | Alto se cada branch adicionar caminho | Base define todos os caminhos antes. |
| `shared/**` | Alto | Congelado na base; mudanças via PR pequeno. |
| Imports de arquivos antigos | Médio | Base move o compartilhado; feature move só o seu. |
| `shared` quebrar quando um modelo de método se move | Alto | Shims de export no caminho antigo; integração atualiza `shared/` e remove os shims (ver 7.12). |
| `shared/cenarios/cenario_salvo.dart` | Alto na etapa 9 | Branch separada e sequencial. |
| `AGENTS.md`/`README.md` | Baixo | Só na branch de docs/integração. |
| `pubspec.yaml` | Baixo | Só na base, salvo nova dependência. |

### 7.8 Fluxo com worktrees

O repositório já é um projeto Flutter comum; worktrees permitem abrir cada branch em uma pasta separada, sem trocar de branch no mesmo diretório.

```bash
# 1. Criar o tronco da refatoração
git switch main
git pull
git switch -c refactor/features-isoladas

# 2. Fazer as etapas 0 e 1 + contratos congelados
# ... commits ...
git push -u origin refactor/features-isoladas

# 3. Criar as branches de feature a partir do tronco
git worktree add ../irrigasim-perfil     -b refactor/perfil     refactor/features-isoladas
git worktree add ../irrigasim-faixas     -b refactor/faixas     refactor/features-isoladas
git worktree add ../irrigasim-inundacao  -b refactor/inundacao  refactor/features-isoladas
git worktree add ../irrigasim-sulcos     -b refactor/sulcos     refactor/features-isoladas
git worktree add ../irrigasim-cenarios   -b refactor/cenarios   refactor/features-isoladas
git worktree add ../irrigasim-guiada     -b refactor/guiada     refactor/features-isoladas

# 4. Em cada worktree
cd ../irrigasim-perfil
flutter pub get
# ... desenvolver ...
dart format lib test
flutter analyze
flutter test
git rebase refactor/features-isoladas
git push -u origin refactor/perfil
```

Para listar/remover worktrees:

```bash
git worktree list
git worktree remove ../irrigasim-perfil
```

### 7.9 Ordem de merge recomendada

Independentemente da ordem de desenvolvimento, a integração fica mais simples assim:

1. `refactor/features-isoladas` (fundação) — obrigatório antes de tudo.
2. `refactor/perfil` — baixo risco, valida o fluxo de PR.
3. `refactor/faixas` — valida o uso do `shared` por uma feature de método.
4. `refactor/inundacao` — valida os tipos compartilhados de validação.
5. `refactor/sulcos` — maior risco; entra com a suíte de regressão.
6. `refactor/cenarios` — fecha a abertura por `id`.
7. `refactor/guiada` — consolida a entrada e remove a navegação duplicada.
8. `refactor/divida-dtos` — etapa 9, depois de tudo estável.
9. `test/guardrails` + docs — por último.

Se uma branch atrasar, as outras não precisam esperar: elas nascem da base e só dependem dela. A exceção é `cenarios`, que só fecha o fluxo completo quando os métodos aceitarem `cenarioId`.

### 7.10 Rotina de sincronização e Definition of Done

**Sincronização:**

- Rebasear a branch em `refactor/features-isoladas` pelo menos uma vez por dia.
- Se a base mudar um contrato congelado, avisar as branches e rebasear todas.
- Evitar branches com mais de 3 dias sem integração. Se a feature for grande (sulcos), dividir em subbranches ou subcommits.

**Definition of Done de cada branch:**

- [ ] A feature só importa `shared/`, `core/`, sua própria pasta e os barris públicos permitidos.
- [ ] Nenhum import de outra feature de método.
- [ ] `flutter analyze` sem erros.
- [ ] `flutter test` verde.
- [ ] Teste manual do fluxo da feature.
- [ ] Nenhum arquivo compartilhado alterado sem PR para a base.
- [ ] `routes.dart` da feature atualizado.
- [ ] PR descrevendo o que foi movido, o que foi alterado e o que ficou como dívida.

### 7.11 Se quiser paralelizar sem branch-base

Não é a recomendação, mas é possível com disciplina:

- cada branch move apenas a própria pasta e não toca em `shared/`, `app_router.dart` nem `app_routes.dart`;
- o `app_router.dart` é atualizado uma única vez, na branch de integração;
- os imports compartilhados são resolvidos com um "commit de compatibilidade" central;
- a integração é feita diariamente, não no fim.

O custo esperado é 3–5 vezes mais conflitos, principalmente em imports e no roteador. Para este projeto, a branch-base é mais barata.

### 7.12 Compatibilidade temporária: shims e barrels

Existe uma dívida que atravessa o paralelismo: `IrrigationParameters`, `SimulationResult`, `CenarioSalvo` e `SimulationResultModel` ainda importam modelos que vão morar dentro das features. Se a branch de faixas mover `BorderProject` e a de inundação mover `BasinProject` ao mesmo tempo, o `shared/` quebra nas duas.

Solução: **shims de compatibilidade + barrels temporários**.

**Na branch-base**, cada barrel reexporta o caminho antigo:

```dart
// features/perfil/perfil.dart (temporário, na base)
export 'package:irrigasim/viewmodels/perfil/perfil_controller.dart';
export 'package:irrigasim/views/perfil/perfil_screen.dart';
```

Assim, `app/app.dart` e outras telas passam a importar o barrel e não precisam mudar quando a feature mover os arquivos.

**Na branch da feature**, ao mover `models/faixas/border_project.dart`:

1. mover o arquivo para `features/irrigacao_faixas/models/border_project.dart`;
2. atualizar o barrel `features/irrigacao_faixas/irrigacao_faixas.dart` para o novo caminho;
3. deixar um shim no caminho antigo:
   ```dart
   // lib/models/faixas/border_project.dart (shim temporário)
   export 'package:irrigasim/features/irrigacao_faixas/models/border_project.dart';
   ```
4. não editar `shared/` nesta branch.

**Na branch de integração**, depois que todas as features estiverem mergeadas:

1. atualizar `shared/irrigation_parameters.dart`, `shared/simulation_result.dart` e `shared/cenarios/cenario_salvo.dart` para os caminhos novos;
2. remover todos os shims;
3. remover os barrels temporários que só reexportavam caminhos antigos;
4. rodar a suíte completa.

Esse padrão permite que cada branch mova a própria pasta sem tocar no compartilhado. O preço é uma etapa curta de limpeza no fim, que é muito mais barata do que resolver conflitos em `shared/` em todas as branches.

> **Alternativa:** fazer a etapa 9 (desacoplamento dos DTOs) antes do paralelismo. É a solução definitiva, mas aumenta o escopo da fundação e atrasa o início das features. Para este projeto, a recomendação é começar com shims e fechar a dívida na etapa 9.

---

## 8. Mapa de arquivos (de → para)

### 8.1 Compartilhado

| De | Para |
|----|------|
| `models/comum/adaptadores_superficie.dart` | `shared/irrigacao/models/comum/adaptadores_superficie.dart` |
| `models/comum/clima_demanda.dart` | `shared/irrigacao/models/comum/clima_demanda.dart` |
| `models/comum/crop_presets.dart` | `shared/irrigacao/models/comum/crop_presets.dart` |
| `models/comum/irrigacao_comum.dart` | `shared/irrigacao/models/comum/irrigacao_comum.dart` |
| `models/irrigation_parameters.dart` | `shared/irrigacao/models/irrigation_parameters.dart` |
| `models/simulation_result.dart` | `shared/irrigacao/models/simulation_result.dart` |
| `models/simulation_result_model.dart` | `shared/irrigacao/models/simulation_result_model.dart` |
| `services/units_service.dart` | `shared/irrigacao/services/units_service.dart` |
| `services/simulation/blaney_criddle.dart` | `shared/irrigacao/services/blaney_criddle.dart` |
| `services/simulation/kostiakov_lewis.dart` | `shared/irrigacao/services/kostiakov_lewis.dart` |
| `services/simulation/lamina_requerida.dart` | `shared/irrigacao/services/lamina_requerida.dart` |
| `services/simulation/operational_planning.dart` | `shared/irrigacao/services/operational_planning.dart` |
| `services/simulation/performance_indicators.dart` | `shared/irrigacao/services/performance_indicators.dart` |
| `services/simulation/surface_irrigation_math.dart` | `shared/irrigacao/services/surface_irrigation_math.dart` |
| `views/irrigation/widgets/advance_chart.dart` | `shared/irrigacao/widgets/charts/advance_chart.dart` |
| `views/irrigation/widgets/infiltration_chart.dart` | `shared/irrigacao/widgets/charts/infiltration_chart.dart` |
| `views/irrigation/widgets/water_balance_chart.dart` | `shared/irrigacao/widgets/charts/water_balance_chart.dart` |
| `views/irrigation/widgets/performance_bars_chart.dart` | `shared/irrigacao/widgets/charts/performance_bars_chart.dart` |
| `views/irrigation/widgets/scenario_comparison_chart.dart` | `shared/irrigacao/widgets/charts/scenario_comparison_chart.dart` |
| `views/irrigation/widgets/opportunity_time_chart.dart` | `shared/irrigacao/widgets/charts/opportunity_time_chart.dart` |
| `views/irrigation/widgets/auditable_widgets.dart` | `shared/irrigacao/widgets/auditable_widgets.dart` |
| `views/irrigation/widgets/irrigation_project_components.dart` | `shared/irrigacao/widgets/irrigation_project_components.dart` |
| `views/irrigation/sulcos/widgets/terrain_view.dart` | `shared/irrigacao/widgets/terrain/terrain_view.dart` |
| `views/irrigation/sulcos/widgets/terrain_painter.dart` | `shared/irrigacao/widgets/terrain/terrain_painter.dart` |

### 8.2 Cenários

| De | Para |
|----|------|
| `models/cenarios/cenario_salvo.dart` | `shared/cenarios/models/cenario_salvo.dart` |
| `services/cenarios/scenario_service.dart` | `shared/cenarios/services/scenario_service.dart` |
| `services/persistence/local_scenario_store.dart` | `shared/cenarios/persistence/local_scenario_store.dart` |
| `services/persistence/project_store.dart` | `shared/cenarios/services/project_store.dart` |
| `viewmodels/cenarios/scenario_providers.dart` | `shared/cenarios/providers/scenario_providers.dart` |
| `viewmodels/results_controller.dart` | `shared/cenarios/controllers/salvar_cenario_controller.dart` |
| `views/cenarios/cenarios_screen.dart` | `features/cenarios/views/cenarios_screen.dart` |

### 8.3 Perfil

| De | Para |
|----|------|
| `models/perfil/tamanho_fonte.dart` | `features/perfil/models/tamanho_fonte.dart` |
| `services/perfil/preferencias_app.dart` | `features/perfil/services/preferencias_app.dart` |
| `viewmodels/perfil/perfil_controller.dart` | `features/perfil/viewmodels/perfil_controller.dart` |
| `views/perfil/perfil_screen.dart` | `features/perfil/views/perfil_screen.dart` |

### 8.4 Sulcos

| De | Para |
|----|------|
| `models/sulcos/*` | `features/irrigacao_sulcos/models/*` |
| `services/simulation/sulcos/*` | `features/irrigacao_sulcos/services/*` |
| `viewmodels/sulcos/*` | `features/irrigacao_sulcos/viewmodels/*` |
| `viewmodels/parameters_controller.dart` | `features/irrigacao_sulcos/viewmodels/furrow_project_controller.dart` |
| `views/irrigation/sulcos/*` | `features/irrigacao_sulcos/views/*` |

### 8.5 Faixas

| De | Para |
|----|------|
| `models/faixas/*` | `features/irrigacao_faixas/models/*` |
| `services/simulation/faixas/*` | `features/irrigacao_faixas/services/*` |
| `viewmodels/faixas/*` | `features/irrigacao_faixas/viewmodels/*` |
| `views/irrigation/faixas/*` | `features/irrigacao_faixas/views/*` |

### 8.6 Inundação

| De | Para |
|----|------|
| `models/inundacao/*` | `features/irrigacao_inundacao/models/*` |
| `services/simulation/inundacao/*` | `features/irrigacao_inundacao/services/*` |
| `viewmodels/inundacao/*` | `features/irrigacao_inundacao/viewmodels/*` |
| `views/irrigation/inundacao/*` | `features/irrigacao_inundacao/views/*` |

### 8.7 Simulação guiada

| De | Para |
|----|------|
| `views/home/home_screen.dart` | `features/simulacao_guiada/views/home_screen.dart` |
| `views/tutorial/tutorial_screen.dart` | `features/simulacao_guiada/views/selecionar_metodo_screen.dart` |
| `views/irrigation/irrigation_screen.dart` | remover (consolidar no seletor) |
| `views/irrigation/widgets/irrigation_method_card.dart` | `features/simulacao_guiada/views/widgets/irrigation_method_card.dart` |

### 8.8 Removidos após a etapa 6

| Arquivo | Motivo |
|---------|--------|
| `views/irrigation/parameters_screen.dart` | fluxo rápido genérico legado |
| `views/irrigation/results_screen.dart` | fluxo rápido genérico legado |
| rotas `/home/irrigation/parameters` e `/home/irrigation/results` | não têm mais entrada válida |

---

## 9. Ordem de commits sugerida

### 9.1 Branch-base `refactor/features-isoladas`

```text
docs: adiciona plano de migração para arquitetura por features
refactor(shared): move contratos, cálculos e widgets compartilhados
refactor(shared): extrai tipos de validação de superfície
refactor(router): cria AppRoutes e compõe rotas por feature
refactor(features): cria barris e routes.dart com a API congelada
docs: registra regras de dependência no AGENTS
```

### 9.2 Branches paralelas

```text
# refactor/perfil
refactor(perfil): isola feature de perfil

# refactor/faixas
refactor(faixas): move modelos, serviços, controllers e telas
refactor(faixas): usa widgets compartilhados de terreno

# refactor/inundacao
refactor(inundacao): isola feature de irrigação por inundação
refactor(inundacao): usa tipos compartilhados de validação

# refactor/sulcos
refactor(sulcos): move modelos, serviços, controllers e telas
refactor(sulcos): renomeia controller central para FurrowProjectController
refactor(sulcos): remove branches de faixas e inundação
refactor(sulcos): aposenta fluxo rápido genérico

# refactor/cenarios
refactor(cenarios): divide tela de histórico em widgets
refactor(cenarios): abre cenários por id de rota
refactor(cenarios): remove imports de controllers de métodos

# refactor/guiada
refactor(guiada): unifica home, tutorial e seleção de método
refactor(guiada): encaminha sem alterar estado de outras features
```

### 9.3 Fechamento

```text
# refactor/divida-dtos
refactor(shared): desacopla DTOs e codecs de cenário

# test/guardrails + docs
test(arch): adiciona teste de fronteiras entre features
docs: atualiza arquitetura no AGENTS e README
```

Cada commit deve passar em `flutter analyze` e `flutter test`.

---

## 10. Riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Muitos imports quebrados na movimentação | Alta | Baixo | `git mv` + atualização mecânica + `flutter analyze` após cada grupo |
| `ParametersController` (1.909 linhas) esconder dependências | Alta | Alto | Não reescrever lógica; renomear/mover primeiro, remover branches depois, com testes de caracterização |
| Persistência de cenários quebrar | Média | Alto | Não alterar `toMap`/`fromMap` na fase estrutural; fixtures reais antes da etapa 9 |
| `IrrigationParameters`/`SimulationResult` continuarem como DTOs "de todos" | Alta | Médio | Tratar como dívida explícita; etapa 9 separada e obrigatória para o isolamento completo |
| `go_router` com `StatefulShellRoute` quebrar o botão voltar | Média | Médio | Manter caminhos e hierarquia; testar manualmente e com `home_method_navigation_test` |
| Deep links quebrarem | Baixa | Médio | Não renomear caminhos na fase estrutural; redirects em fase posterior |
| Testes de golden mudarem por causa de imports | Baixa | Baixo | Apenas mover; não alterar widgets/valores |
| Duas fontes de verdade durante a transição | Média | Médio | Commits pequenos; não manter cópias antigas e novas por muito tempo |
| Conflitos entre branches paralelas | Alta se a base não existir | Alto | Congelar a fundação antes de abrir as branches; matriz de propriedade; rebase diário |
| Branch de feature alterar contrato compartilhado | Média | Alto | Mudanças em `shared/` só via PR pequeno para a branch-base; rebase de todas depois |

---

## 11. Decisões pendentes

1. **O bloco de ~43 linhas colado na conversa não chegou.** Se ele contiver uma árvore ou nomes de pastas diferentes, este plano deve ser alinhado.
2. **`cenarios` dono da persistência ou `shared/cenarios`?** A recomendação é contrato em `shared/cenarios` e interação em `features/cenarios`, para evitar ciclo. Confirmar se essa separação faz sentido para o projeto.
3. **Aposentar o fluxo rápido genérico?** A recomendação é sim, após a etapa 6. Ele está inalcançável para métodos novos e só atende cenários legados.
4. **Home dentro de `simulacao_guiada`?** A recomendação é sim, porque a home é a porta de entrada do fluxo guiado.
5. **Renomear caminhos de rota?** A recomendação é não nesta refatoração; fazer depois com redirect.
6. **`ProjectStore`:** hoje só é usado por testes, mas conhece todos os métodos. Mantê-lo em `shared/cenarios` ou transformá-lo em exportador no `app/`?
7. **Codecs de cenário:** implementar já na etapa 3 ou deixar para a etapa 9? A recomendação é deixar para a 9, para não misturar movimentação com mudança de contrato.
8. **Estratégia de branches:** confirmar se o modelo `main → refactor/features-isoladas → branches de feature` atende. A recomendação é sim; a alternativa (features direto de `main`) aumenta muito os conflitos.

---

## 12. Checklist final de validação manual

- [ ] Abrir o app e ver a home com o nome do perfil.
- [ ] Alternar tema claro/escuro e conferir persistência.
- [ ] Abrir "Nova simulação guiada", escolher Sulcos e concluir um projeto.
- [ ] Salvar o cenário de sulcos e reabri-lo em Cenários.
- [ ] Repetir para Faixas.
- [ ] Repetir para Inundação (intermitente e permanente).
- [ ] Buscar cenário por nome e por método.
- [ ] Excluir um cenário.
- [ ] Abrir um cenário legado (se houver fixture) e conferir os valores.
- [ ] Conferir botão voltar do sistema em todas as telas.
- [ ] Conferir que a simulação guiada não tem cálculo nem persistência.
- [ ] Rodar `flutter analyze` e `flutter test` uma última vez.
