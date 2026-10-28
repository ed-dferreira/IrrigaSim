# Nomenclatura pt-BR dos viewmodels de sulcos

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portuguesizar nomes públicos e internos de `lib/features/irrigacao_sulcos/viewmodels` e extrair helpers/constantes, sem alterar fórmulas, chaves string das telas nem tipos de `shared/`.

**Architecture:** Rename em cascata (arquivos → tipos → métodos → call sites). Clean code limitado a constantes de campo e extração de privados nos três métodos grandes. `StateNotifier` e os três arquivos da pasta permanecem; entra um quarto arquivo só de constantes.

**Tech Stack:** Flutter, Dart, Riverpod `StateNotifierProvider`.

**Spec:** Desenho aprovado na conversa de 2026-10-28: opção 2 + clean code no recorte da pasta; chaves `'vazao'`/`'k'` e `IrrigationParameters`/`SimulationResult` intactos.

## Global Constraints

- Não alterar fórmulas, defaults numéricos nem mensagens ao usuário.
- Valores das chaves de `atualizarCampo` permanecem iguais (`'vazao'`, `'k'`, …).
- Não renomear tipos em `shared/` (`IrrigationParameters`, `SimulationResult`, `OperationalPlanning`).
- Não fatiar o wizard nem trocar `StateNotifier`.
- Não commitar a menos que o usuário peça.

## Review Focus

- Call site de tear-off (`setFator11Vib`, `setCondicoesEnsaioAvanco`, `setPontosEnsaioAvanco`, `setMedicoesRecessao`, `setMedicoesEntradaSaida`) deve continuar compatível após `definir…`.
- `copyWith(limpar…)` deve anular o campo quando a flag é true, como `clear…` hoje.
- `provedorParametrosSulco.overrideWith` nos testes de widget deve continuar injetando o controlador.
- `paraParametrosIrrigacao()` deve produzir o mesmo `IrrigationParameters` que `toIrrigationParameters()` hoje.
- Análise (`flutter analyze`) sem referências órfãs a `ParametersState` / `parametersProvider` / `FurrowSimulationCoordinator` no código Dart.

---

### Task 1: Coordenador de simulação

**Files:**
- Create: `lib/features/irrigacao_sulcos/viewmodels/coordenador_simulacao_sulcos.dart`
- Delete: `lib/features/irrigacao_sulcos/viewmodels/furrow_simulation_coordinator.dart`
- Modify: `lib/features/irrigacao_sulcos/viewmodels/parameters_controller.dart` (import e `const FurrowSimulationCoordinator()`)

**Interfaces:**
- Consumes: `IrrigationParameters`, `SimulationResult`, `ResultadoCurvaAvanco`, `SimuladorSulcos`, `OperationalPlanning.calcular`
- Produces:

```dart
class CoordenadorSimulacaoSulcos {
  const CoordenadorSimulacaoSulcos();
  SimulationResult simular(IrrigationParameters parametros, {ResultadoCurvaAvanco? curvaAvanco});
  SimulationResult executar(IrrigationParameters parametros, {ResultadoCurvaAvanco? curvaAvanco});
}
```

- [ ] **Step 1: Criar `CoordenadorSimulacaoSulcos`**

Copiar o corpo atual de `FurrowSimulationCoordinator` com o nome novo. Manter a chamada `SimuladorSulcos()(parametros, advanceCurve: curvaAvanco)` — `advanceCurve` é da API de `shared`/serviço, fora do recorte.

- [ ] **Step 2: Trocar usos no controlador e apagar o arquivo antigo**

`const CoordenadorSimulacaoSulcos().simular` / `.executar`.

- [ ] **Step 3: Verificar**

Run: `dart analyze lib/features/irrigacao_sulcos/viewmodels`
Expected: sem erro de símbolo `FurrowSimulationCoordinator`.

---

### Task 2: Estado e constantes de campo

**Files:**
- Create: `lib/features/irrigacao_sulcos/viewmodels/estado_parametros_sulco.dart`
- Create: `lib/features/irrigacao_sulcos/viewmodels/campos_parametros_sulco.dart`
- Delete: `lib/features/irrigacao_sulcos/viewmodels/parameters_state.dart`
- Modify: `lib/features/irrigacao_sulcos/viewmodels/parameters_controller.dart` (tipo, `copyWith`, export)
- Modify: `lib/features/irrigacao_sulcos/irrigacao_sulcos.dart` (export do estado)

**Interfaces:**
- Consumes: mesmos campos e getters atuais de `ParametersState`
- Produces: `class EstadoParametrosSulco` com a mesma API de campos; `IrrigationParameters paraParametrosIrrigacao()`; flags `limpar*` no `copyWith`; `abstract final class CamposParametrosSulco` com `static const` cujo **valor** é a string atual.

Flags `copyWith`:

| Hoje | Depois |
|---|---|
| `clearLaminaRequeridaResultado` | `limparLaminaRequeridaResultado` |
| `clearCurvaInfiltracaoSulco` | `limparCurvaInfiltracaoSulco` |
| `clearEtoMmDia` | `limparEtoMmDia` |
| `clearTemperaturaMediaC` | `limparTemperaturaMediaC` |
| `clearLatitudeGraus` | `limparLatitudeGraus` |
| `clearDecliveEncostaPercent` | `limparDecliveEncostaPercent` |
| `clearEnsaioErosao` | `limparEnsaioErosao` |
| `clearLarguraSulcoM` | `limparLarguraSulcoM` |
| `clearProfundidadeSulcoM` | `limparProfundidadeSulcoM` |

Constantes: uma por chave usada em `updateField` / origens (`comprimento`, `k`, `a`, `vazao`, `etoMmDia`, `curvaCoeficiente`, …). Não inventar chaves novas.

- [ ] **Step 1: Escrever `CamposParametrosSulco` e `EstadoParametrosSulco`**

Mover o conteúdo de `parameters_state.dart`. Renomear classe, `paraParametrosIrrigacao`, flags `limpar*`. Locais `point` → `ponto`.

- [ ] **Step 2: Atualizar controlador e barrel; apagar `parameters_state.dart`**

`export 'estado_parametros_sulco.dart';` no controlador e no barrel. Trocar todo `ParametersState` / `toIrrigationParameters` / `clear*` internos do controlador (ainda com os nomes de método `set*` nesta task, se a Task 3 não tiver rodado).

- [ ] **Step 3: Verificar**

Run: `rg -n "ParametersState|toIrrigationParameters|parameters_state" lib test --glob '*.dart'`
Expected: zero ocorrências (exceto comentário em `basin_project.dart`, atualizado nesta task para o caminho novo).

---

### Task 3: Controlador, provider e extração

**Files:**
- Create: `lib/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart`
- Delete: `lib/features/irrigacao_sulcos/viewmodels/parameters_controller.dart`
- Modify: barrel `lib/features/irrigacao_sulcos/irrigacao_sulcos.dart`

**Interfaces:**
- Consumes: `EstadoParametrosSulco`, `CamposParametrosSulco`, `CoordenadorSimulacaoSulcos`
- Produces:

```dart
class ControladorParametrosSulco extends StateNotifier<EstadoParametrosSulco> {
  ControladorParametrosSulco();
  void resetar();
  void definirTipoSulco(TipoSulco tipo);
  void carregarDeParametros(IrrigationParameters params);
  void atualizarCampo({String? campo, String? valor});
  void definirTexturaSolo(TexturaSolo textura);
  void definirNomeCultura(String nome);
  void definirManejoSulco(ManejoSulco manejo);
  void definirOrigemVazaoReduzida(OrigemVazaoReduzida origem);
  void definirFator11Vib(bool valor);
  void definirCondicoesEnsaioAvanco(String valor);
  void definirEnsaioErosao(EnsaioErosao? valor);
  void definirOrigemAvanco(OrigemAvanco origem);
  void definirPontosEnsaioAvanco(List<PontoEnsaioAvanco> pontos);
  void definirMetodoCurvaAvanco(MetodoAjusteAvanco metodo);
  void definirOrigemCurvaInfiltracao(OrigemCurvaInfiltracao origem);
  void definirMetodoEtc(MetodoEtc metodo);
  void definirMesReferencia(int mes);
  void definirOrigemChuva(OrigemChuva origem);
  void definirOrientacaoSulco(String valor);
  void definirOrigemGeometria(ProvenienciaDado origem);
  void definirDimensionarComprimentoCriddle(bool ativo);
  void configurarCurvaInfiltracao({TipoCurvaInfiltracao? tipo, BaseInfiltracao? base});
  void definirDataCurvaInfiltracao(DateTime? data);
  void definirMedicoesEntradaSaida(List<MedicaoEntradaSaida> medicoes);
  void definirHipoteseRecessao(HipoteseRecessao hipotese);
  void definirMedicoesRecessao(List<MedicaoRecessao> medicoes);
  String? validarEnsaio();
  void dimensionarComprimentoCriddle();
  void recomendarMaiorComprimento();
  double calcularDeclividade();
  Future<void> executarSimulacao();
}

final provedorParametrosSulco =
    StateNotifierProvider<ControladorParametrosSulco, EstadoParametrosSulco>(...);
```

Privados a renomear no mesmo arquivo: `_getDefaultsForTipoSulco` → `_padroesParaTipoSulco`; `_stateComAvancoDaOrigem` → `_estadoComAvancoDaOrigem`; parâmetros `current`/`source` → `atual`/`origem`.

Clean code (mesmo arquivo, comportamento idêntico):

- `atualizarCampo` despacha para `_atualizarCamposCurvaInfiltracao`, `_atualizarCamposOpcionaisClima`, `_atualizarDimensoesSulco`, `_atualizarCampoNumerico`. Comparar `campo` com `CamposParametrosSulco.*`, não com literais soltos.
- De `dimensionarComprimentoCriddle`, extrair cálculo de `to`/`taAlvo` e o comprimento via curva (ensaio vs estimativa) para privados com nomes em português.
- De `recomendarMaiorComprimento`, extrair a avaliação de um comprimento candidato para um privado que devolve texto de avaliação + `EstadoParametrosSulco?`.

- [ ] **Step 1: Criar o arquivo novo com os nomes e extrações acima; exportar o estado; apagar o antigo**

- [ ] **Step 2: Atualizar o barrel**

```dart
export 'viewmodels/controlador_parametros_sulco.dart';
export 'viewmodels/estado_parametros_sulco.dart';
```

- [ ] **Step 3: Verificar analyze do viewmodel**

Run: `dart analyze lib/features/irrigacao_sulcos/viewmodels`
Expected: clean no recorte; views ainda quebram até a Task 4 — isso é esperado se rodar analyze na feature inteira.

---

### Task 4: Views e testes

**Files:**
- Modify views: `project_screen.dart`, `tipo_sulco_screen.dart`, `project_results_screen.dart`, `project_results/project_results_widgets.dart`, `project_results/project_results_sections.dart`, `project_steps/{area,avanco,clima,cultura,operacao,revisao,solo,sulco}_step.dart`, `project_steps/project_step_widgets.dart`
- Modify tests: `test/features/irrigation/{project_results_screen_test,domain_calculation_regressions_test,furrow_erosion_reduction_test,length_and_advance_planning_test}.dart`, `test/services/simulation/blaney_criddle_test.dart`
- Modify comment: `lib/features/irrigacao_inundacao/models/basin_project.dart` (caminho do getter, se ainda não foi na Task 2)

**Interfaces:**
- Consumes: API pública da Task 3
- Produces: app e testes compilando com os nomes novos

Substituições mecânicas:

- import `parameters_controller.dart` → `controlador_parametros_sulco.dart`
- `ParametersState` → `EstadoParametrosSulco`
- `ParametersController` → `ControladorParametrosSulco`
- `parametersProvider` → `provedorParametrosSulco`
- `loadFromParams` → `carregarDeParametros`
- `updateField` → `atualizarCampo`
- `toIrrigationParameters` → `paraParametrosIrrigacao`
- cada `setX` → `definirX` da tabela da Task 3
- tear-offs (` .setFator11Vib`) → ` .definirFator11Vib`

Não alterar os mapas/strings `'kc'`, `'vazao'`, `name:` dos `StepField`.

- [ ] **Step 1: Atualizar views e testes**

- [ ] **Step 2: Conferir resíduos**

Run: `rg -n "Parameters(State|Controller)|parametersProvider|FurrowSimulationCoordinator|loadFromParams|toIrrigationParameters|parameters_controller|parameters_state|furrow_simulation" lib test --glob '*.dart'`
Expected: zero no Dart (docs históricos como `docs/Plano_migracao_features.md` ficam).

- [ ] **Step 3: Analyze + testes de regressão**

Run:

```
dart analyze lib/features/irrigacao_sulcos lib/features/irrigacao_inundacao/models/basin_project.dart
flutter test test/features/irrigation/domain_calculation_regressions_test.dart test/features/irrigation/length_and_advance_planning_test.dart test/features/irrigation/furrow_erosion_reduction_test.dart test/features/irrigation/project_results_screen_test.dart test/services/simulation/blaney_criddle_test.dart
```

Expected: analyze sem erros; todos os testes PASS. Números de eficiência, IRN, comprimentos Criddle e q reduzida iguais aos de hoje.
