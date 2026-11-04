# Plano de alinhamento visual e clean code das telas de irrigação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Data:** 2026-11-04
**Base visual:** `lib/features/irrigacao_sulcos/views/`
**Telas a alinhar:** `lib/features/irrigacao_faixas/views/` e `lib/features/irrigacao_inundacao/views/`
**Referência de migração:** `docs/Plano_migracao_features.md`
**Spec:** este documento

## Objetivo

Deixar as telas de faixas e inundação visualmente consistentes com a tela de sulcos, usando um design system compartilhado de irrigação, e depois reduzir o acoplamento e o tamanho dos arquivos com clean code — sem alterar cálculo, validação, textos, chaves de persistência ou CSV.

## Arquitetura da solução

- **`lib/core/widgets/` continua genérica.** Nada específico de irrigação entra ali. Só primitivas reutilizáveis pelo app inteiro (ex.: `KpiCard`, `CalculatedField`).
- **`lib/shared/irrigacao/widgets/` é o design system de irrigação.** Componentes visuais comuns às três features, sem importar `lib/features/` (guardrail existente em `test/architecture/shared_sem_features_test.dart`).
- **As telas de feature orquestram.** Elas montam dados, mapeiam status e textos, e delegam a apresentação para os componentes compartilhados.
- **A ordem é deliberada:** primeiro só apresentação (Etapa 1), depois decomposição dos arquivos (Etapa 2). Assim a revisão visual não se mistura com movimentação de código.

## Restrições globais

- Não alterar fórmulas, valores padrão, validações, mensagens ao usuário, chaves de `toMap`/`fromMap`, CSV ou ordem de persistência.
- Não renomear classes, providers, controllers ou rotas nesta empreitada.
- `lib/shared/` não pode importar nem reexportar `lib/features/`.
- Preservar `Semantics`, `tooltip`, `ValueKey` e textos usados pelos testes.
- Preservar comportamento em tema claro/escuro, tela estreita (390 px), desktop (1120 px) e texto ampliado (1.8×).
- Não commitar sem autorização explícita do usuário.
- Ao final de cada tarefa: `flutter analyze` e o teste indicado devem passar.

## Review Focus

Os cinco riscos mais prováveis nesta empreitada, e onde cada um vira teste:

1. **Texto existente some ou muda.** Testes de tela em `border_project_screen_test.dart`, `border_results_screen_test.dart`, `basin_project_screen_test.dart`, `basin_results_screen_test.dart`, `project_results_screen_test.dart` e `project_step_navigation_test.dart` continuam procurando os mesmos rótulos.
2. **Overflow em tela estreita.** `IrrigationKpiGrid` e `IrrigationFieldGrid` ganham testes em 360–390 px; as telas de projeto e resultado são reexecutadas nessa largura.
3. **Tema escuro e texto ampliado quebram contraste ou layout.** Teste de fumaça com `ThemeData.dark()` e `TextScaler.linear(1.8)` nas três telas de resultado.
4. **Semântica, tooltip ou `ValueKey` usados por teste desaparecem.** Testes de abas, navegação e campos verificam `Semantics.selected`, tooltips de exportação e chaves de campos.
5. **CSV muda conteúdo ou ordem.** Testes de exportação de sulcos e faixas continuam verificando linhas e ordem; a extração do CSV de sulcos para serviço mantém a mesma string.


## Tokens visuais de referência

| Elemento | Valor |
|---|---|
| Card | raio 24, `Card` do tema, sem elevação |
| Padding interno de card | 20 |
| Espaçamento entre cards/seções | 20 (`IrrigationSpacing.major`) |
| Espaçamento entre campos | 12 (`IrrigationSpacing.field`) |
| Título de seção | `titleMedium`, `w700` |
| Rótulo de campo | `labelLarge` |
| Texto auxiliar | `bodySmall`, `onSurfaceVariant` |
| Ícone de seção | 20, cor primária ou acento do método |
| Acento | `AppColors.sulco`, `AppColors.faixa`, `AppColors.inundacao` |
| Banner | raio 24, padding 20, ícone 32, título `titleMedium w700` |
| KPI | `Card` raio 24, padding 16, valor `headlineSmall w700`, unidade `bodySmall` |
| Botão principal | `FilledButton` do tema |
| Botão secundário | `OutlinedButton` do tema |

---

# Etapa 0 — Baseline

### Tarefa 0: Registrar o estado atual

**Arquivos:**
- Nenhum arquivo de produção.
- Opcional: anotar resultados em `docs/Plano_alinhamento_visual_irrigacao.md`.

**Passos:**
- [x] Rodar `flutter analyze` e registrar os problemas existentes.
- [x] Rodar `flutter test` e registrar a linha final de cada suíte.
- [x] Confirmar que os testes de tela existentes passam antes de qualquer mudança:
  - `test/features/irrigation/project_results_screen_test.dart`
  - `test/features/irrigation/project_step_navigation_test.dart`
  - `test/features/irrigation/border_project_screen_test.dart`
  - `test/features/irrigation/border_results_screen_test.dart`
  - `test/features/irrigation/basin_project_screen_test.dart`
  - `test/features/irrigation/basin_results_screen_test.dart`
- [x] Se algum teste já falhar, anotar e não corrigir nesta empreitada. (Nenhuma falha pré-existente.)

**Resultado registrado (baseline):**
- `flutter analyze`: 2 issues pré-existentes — `info` (`curly_braces_in_flow_control_structures`) em `lib/features/irrigacao_sulcos/services/modelo_curva_avanco.dart:291` e `warning` (`unused_import`) em `lib/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart:17`.
- `flutter test`: 292 testes passando (`All tests passed!`), sem falhas pré-existentes.

**Critério de conclusão:** existe uma linha de base confiável para comparar depois.

---

# Etapa 1 — Alinhamento visual

**Meta da etapa:** faixas e inundação passam a usar os mesmos componentes visuais de sulcos. Os arquivos grandes continuam grandes nesta etapa; a única mudança estrutural é a criação do design system compartilhado.

## Tarefa 1: Feedback e banners compartilhados

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_feedback.dart`
- Teste: `test/shared/irrigation/irrigation_feedback_test.dart`
- Modificar depois: `lib/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart`
- Modificar depois: `lib/features/irrigacao_faixas/views/border_results_screen.dart`
- Modificar depois: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`

**Interfaces:**
- `enum IrrigationBannerTone { success, warning, error, info }`
- `class IrrigationBanner extends StatelessWidget`
  - `String title`
  - `String message`
  - `IconData icon`
  - `IrrigationBannerTone tone`
  - `String? semanticsLabel`

**Passos:**
- [ ] Escrever teste que monta `IrrigationBanner` nos quatro tons e verifica título, mensagem, ícone e ausência de exceção.
- [ ] Rodar o teste e confirmar que falha por ausência do componente.
- [ ] Implementar `IrrigationBanner` com raio 24, padding 20, ícone 32 e cores `errorContainer`/`tertiaryContainer`/`primaryContainer`/`surfaceContainerHigh`.
- [ ] Rodar o teste e confirmar que passa.
- [ ] Substituir o corpo visual de `RecommendationBanner` (sulcos), `_BorderRecommendation` (faixas) e `_BasinRecommendation` (inundação) por `IrrigationBanner`, mantendo os textos e o mapeamento de tom de cada feature.
- [ ] Rodar os testes das três telas de resultado.
- [ ] Rodar `flutter analyze`.

**Critério de conclusão:** os três banners usam o mesmo componente, com o mesmo raio, padding, tipografia e hierarquia.

## Tarefa 2: KPIs compartilhados

**Arquivos:**
- Modificar: `lib/core/widgets/kpi_card.dart`
- Criar: `lib/shared/irrigacao/widgets/irrigation_kpi.dart`
- Teste: `test/shared/irrigation/irrigation_kpi_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_results_screen.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`

**Interfaces:**
- `class IrrigationKpiItem`
  - `String titulo`
  - `String valor`
  - `String unidade`
  - `String? subtitulo`
  - `IconData? icon`
  - `Color? color`
- `class IrrigationKpiGrid extends StatelessWidget`
  - `List<IrrigationKpiItem> items`
  - `double spacing = IrrigationSpacing.field`
  - `int maxColumns = 3`
- `KpiCard` passa a aceitar os mesmos campos visuais e mantém a API atual.

**Passos:**
- [ ] Escrever teste de `IrrigationKpiGrid` com 4 itens em largura 360, 700 e 1100; verificar quantidade de `KpiCard`, textos e ausência de overflow.
- [ ] Rodar o teste e confirmar que falha.
- [ ] Ajustar `KpiCard` para o padrão de sulcos: `Card` raio 24, padding 16, valor `headlineSmall` na cor de destaque, unidade `bodySmall`, subtítulo `bodySmall`.
- [ ] Implementar `IrrigationKpiGrid` com `LayoutBuilder`: 1 coluna abaixo de 480, 2 entre 480 e 719, 3 a partir de 720; respeitar `maxColumns`.
- [ ] Rodar o teste e confirmar que passa.
- [ ] Trocar `KpiGrid` de sulcos, a grade inline de faixas e a grade inline de inundação por `IrrigationKpiGrid`.
- [ ] Separar unidade do valor em faixas e sulcos (ex.: `valor: '82,4'`, `unidade: '%'`).
- [ ] Rodar os testes das três telas de resultado.
- [ ] Rodar `flutter analyze`.

**Critério de conclusão:** as três telas mostram KPIs com o mesmo card, mesma tipografia e mesma grade responsiva.

## Tarefa 3: Seção de gráficos compartilhada

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_chart_section.dart`
- Teste: `test/shared/irrigation/irrigation_chart_section_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`
- Faixas: `BorderCharts` já tem o mesmo shell visual; a migração para o componente compartilhado fica na Tarefa 11.

**Interfaces:**
- `class IrrigationChartTab`
  - `String label`
  - `IconData icon`
- `class IrrigationChartSection extends StatelessWidget`
  - `String title`
  - `List<IrrigationChartTab> tabs`
  - `int selectedIndex`
  - `ValueChanged<int> onTabSelected`
  - `List<Widget> children`
  - `double height = 340`

**Passos:**
- [ ] Escrever teste que monta duas abas, toca na segunda e verifica que o `IndexedStack` mudou de índice e que o `Semantics` está selecionado.
- [ ] Rodar o teste e confirmar que falha.
- [ ] Implementar o shell com `Card` raio 24, padding 20, cabeçalho `titleMedium w700`, abas horizontais de 56 px, pills de raio 14 e `IndexedStack` de 340 px.
- [ ] Rodar o teste e confirmar que passa.
- [ ] Em sulcos, substituir o `ChartSection` local por `IrrigationChartSection`.
- [ ] Em inundação, agrupar os gráficos em abas: `Avanço`, `Infiltração`, `Balanço`, `Indicadores` e `Comparação` (esta última só quando houver comparação). Usar um `StatefulWidget` privado para o índice local.
- [ ] Rodar os testes de sulcos e inundação.
- [ ] Rodar `flutter analyze`.

**Critério de conclusão:** sulcos e inundação usam o mesmo card de gráficos com abas; faixas já está visualmente próximo e será migrado na Etapa 2.

## Tarefa 4: Campos e grade de formulário

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_forms.dart`
- Teste: `test/shared/irrigation/irrigation_forms_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_steps/project_step_widgets.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_project_screen.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_project_screen.dart`

**Interfaces:**
- `class IrrigationLabeledField extends StatelessWidget`
  - `String label`
  - `Widget child`
- `class IrrigationFieldGrid extends StatelessWidget`
  - `List<Widget> fields`
  - `double maxFieldWidth = 340`
  - `double spacing = IrrigationSpacing.field`
- `class IrrigationStepNavigation extends StatelessWidget`
  - `bool isFirst`
  - `bool isLast`
  - `bool isConfirmed`
  - `bool isBusy`
  - `bool canCalculate`
  - `String nextLabel = 'Próximo'`
  - `String calculateLabel = 'Calcular projeto'`
  - `String busyLabel = 'Calculando…'`
  - `VoidCallback onPrevious`
  - `VoidCallback onConfirm`
  - `VoidCallback onNext`
  - `VoidCallback onCalculate`

**Passos:**
- [ ] Escrever teste de `IrrigationLabeledField` + `IrrigationFieldGrid`: em 390 px os campos ficam em uma coluna; em 1100 px ficam em até três colunas; widgets que não são `IrrigationLabeledField` ocupam a linha inteira.
- [ ] Escrever teste de `IrrigationStepNavigation`: primeira etapa não mostra `Voltar`; etapa confirmada mostra `Confirmada`; última etapa mostra o botão de cálculo desabilitado quando `canCalculate == false`.
- [ ] Rodar os testes e confirmar que falham.
- [ ] Implementar os três componentes.
- [ ] Substituir `StepFieldGrid` por `IrrigationFieldGrid`.
- [ ] Substituir `_BorderInput` por `IrrigationLabeledField` e `_layoutFields` por `IrrigationFieldGrid`.
- [ ] Substituir `_BasinInput` por `IrrigationLabeledField` e `_layoutFields` por `IrrigationFieldGrid`.
- [ ] Substituir `StepNavigationButtons`, a `Row` de navegação de faixas e `_navigationRow` de inundação por `IrrigationStepNavigation`.
- [ ] Rodar os testes de projeto das três features.
- [ ] Rodar `flutter analyze`.

**Critério de conclusão:** as três telas de projeto usam a mesma grade de campos e a mesma barra de navegação.

## Tarefa 5: Exportação CSV compartilhada

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_export.dart`
- Teste: `test/shared/irrigation/irrigation_export_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results_screen.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_results_screen.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`

**Interfaces:**
- `Future<void> showIrrigationExportSheet(BuildContext context, {required String title, required String description, required String csv, String copyLabel = 'Copiar CSV'})`

**Passos:**
- [x] Escrever teste que abre o sheet, encontra o `SelectableText` com o CSV e toca em copiar; verificar que o sheet fecha e que o `SnackBar` aparece.
- [x] Rodar o teste e confirmar que falha.
- [x] Implementar o sheet com `showModalBottomSheet`, `showDragHandle`, `SafeArea`, `SelectableText` e botão `FilledButton.icon`.
- [x] Rodar o teste e confirmar que passa.
- [x] Substituir `_showExport` de sulcos, `_mostrarExportacao` de faixas e `_mostrarExportacao` de inundação pelo componente.
- [x] Rodar os testes das três telas.
- [x] Rodar `flutter analyze`.
  - Obs.: em teste, `Clipboard.setData` exige mock de `SystemChannels.platform` (`TestDefaultBinaryMessengerBinding`) — já aplicado em `irrigation_export_test.dart`.

**Critério de conclusão:** a exportação tem o mesmo visual e o mesmo comportamento nas três telas.

## Tarefa 6: Estados vazios e de carregamento

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_states.dart`
- Teste: `test/shared/irrigation/irrigation_states_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results_screen.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_results_screen.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`

**Interfaces:**
- `class IrrigationEmptyResult extends StatelessWidget`
  - `IconData icon`
  - `String title`
  - `String message`
  - `String actionLabel`
  - `VoidCallback onAction`
- Reutilizar `LoadingWidget` de `lib/core/widgets/loading_widget.dart` para o estado de carregamento.

**Passos:**
- [x] Escrever teste que monta `IrrigationEmptyResult` e verifica ícone, título, mensagem e ação.
- [x] Rodar o teste e confirmar que falha.
- [x] Implementar `IrrigationEmptyResult` com o padrão de sulcos (ícone 48, título `titleLarge`, mensagem `bodyMedium`, botão `FilledButton.icon`).
- [x] Rodar o teste e confirmar que passa.
- [x] Substituir os estados vazios inline de faixas, inundação e sulcos.
  - Obs.: o caso de **erro** da tela de sulcos (results com falha de cálculo) permanece inline, pois exibe ícone na cor de erro, título e detalhe da mensagem sem botão de ação — o componente compartilhado exige ação.
- [x] Substituir o `CircularProgressIndicator` + texto de sulcos por `LoadingWidget`.
- [x] Rodar os testes das três telas.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** resultados vazios e carregamento têm o mesmo visual nas três features, reutilizando `LoadingWidget` do core.

## Tarefa 7: Aplicar o design system em faixas

**Arquivos:**
- Modificar: `lib/features/irrigacao_faixas/views/border_project_screen.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_results_screen.dart`
- Teste: `test/features/irrigation/border_project_screen_test.dart`
- Teste: `test/features/irrigation/border_results_screen_test.dart`

**Passos:**
- [x] No projeto, trocar `IrrigationSpacing.section` por `IrrigationSpacing.major` entre o indicador, o card da etapa e a navegação.
- [x] Criar uma lista `_subtitles` com uma frase descritiva por etapa, no padrão de sulcos, e usar em `IrrigationProjectStepCard`.
- [x] Garantir que o card da etapa use `IrrigationProjectStepCard` com acento `AppColors.faixa`.
- [x] Nos resultados, usar `IrrigationKpiGrid`, `IrrigationBanner` e `IrrigationExportSheet`.
- [x] Manter `BorderCharts` como está visualmente; a migração do shell para `IrrigationChartSection` fica na Tarefa 11.
- [x] Manter os textos de status, os códigos canônicos e as seções auditáveis.
- [x] Rodar os dois testes de faixas.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** faixas usa os mesmos componentes e espaçamentos de sulcos, sem mudança de comportamento.

## Tarefa 8: Aplicar o design system em inundação

**Arquivos:**
- Modificar: `lib/features/irrigacao_inundacao/views/basin_project_screen.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart`
- Teste: `test/features/irrigation/basin_project_screen_test.dart`
- Teste: `test/features/irrigation/basin_results_screen_test.dart`

**Passos:**
- [x] No projeto, trocar o espaçamento entre indicador, card e navegação para `IrrigationSpacing.major`.
- [x] Criar `_subtitles` descritivos por etapa e usar em `IrrigationProjectStepCard`.
- [x] Usar `IrrigationFieldGrid` e `IrrigationStepNavigation`.
- [x] Nos resultados, usar `IrrigationKpiGrid`, `IrrigationBanner`, `IrrigationChartSection` e `IrrigationExportSheet`.
- [x] Manter os anexos, seções auditáveis, páginas-fonte e textos de status.
- [x] Adicionar teste de fumaça de `BasinResultsScreen` em tema escuro e `TextScaler.linear(1.8)`, verificando ausência de exceção e presença de `Indicadores principais`.
  - Fix extraído do teste: `_BooherTable` do painel de referência ganhou `DataTable.dataRowMaxHeight: double.infinity` para a linha crescer com texto ampliado.
- [x] Rodar os dois testes de inundação.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** inundação usa os mesmos componentes e espaçamentos de sulcos, sem mudança de comportamento.

## Tarefa 9: Alinhar sulcos ao design system extraído

**Arquivos:**
- Modificar: `lib/features/irrigacao_sulcos/views/project_screen.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results_screen.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_steps/project_step_widgets.dart`
- Teste: `test/features/irrigation/project_results_screen_test.dart`
- Teste: `test/features/irrigation/project_step_navigation_test.dart`

**Passos:**
- [ ] Trocar `StepBentoCard` por `IrrigationProjectStepCard` diretamente.
- [ ] Trocar `StepFieldGrid` por `IrrigationFieldGrid`.
- [ ] Trocar `StepNavigationButtons` por `IrrigationStepNavigation`.
- [ ] Trocar `KpiGrid` por `IrrigationKpiGrid`.
- [ ] Trocar `RecommendationBanner` por `IrrigationBanner`.
- [ ] Trocar `ChartSection` por `IrrigationChartSection`.
- [x] Trocar o sheet de exportação por `showIrrigationExportSheet`.
- [x] Adicionar teste de fumaça de `ProjectResultsScreen` em tema escuro e `TextScaler.linear(1.8)`.
  - Fix extraído do teste: o overlay central de `WaterBalanceChart` (shared) ganhou `FittedBox(fit: BoxFit.scaleDown)` para não transbordar com texto ampliado.
- [x] Rodar os dois testes de sulcos.
- [x] Rodar `flutter analyze`.
  - Obs.: nesta etapa os wrappers locais (`StepBentoCard`, `StepFieldGrid`, `StepNavigationButtons`, `KpiGrid`) foram mantidos, apenas delegando aos componentes compartilhados; a remoção direta fica para a Etapa 2, conforme ajuste de escopo combinado.

**Critério de conclusão:** sulcos também consome o design system; a base deixa de ter cópias locais dos componentes.

---

# Etapa 2 — Clean code

**Meta da etapa:** reduzir os arquivos gigantes, separar responsabilidades e remover wrappers que só delegam. Nenhuma mudança de comportamento.

## Tarefa 10: Quebrar a tela de projeto de faixas

**Arquivos:**
- Manter: `lib/features/irrigacao_faixas/views/border_project_screen.dart` (orquestrador)
- Criar: `lib/features/irrigacao_faixas/views/border_project/border_project_fields.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/area_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/dimensoes_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/solo_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/cultura_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/clima_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/avanco_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/operacao_step.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_project_steps/revisao_step.dart`
- Teste: `test/features/irrigation/border_project_screen_test.dart`

**Interfaces:**
- Cada step recebe `BorderProject project`, `bool wide`, e callbacks/ref quando precisar alterar o controller.
- `BorderProjectFields` expõe `Widget number(...)`, `Widget select<T>(...)`, `Widget review(...)` e `String format(double?)`.

**Passos:**
- [x] Mover o conteúdo de cada `case` do `switch (_step)` para o arquivo de step correspondente.
- [x] Mover `_number`, `_select`, `_review` e `_fmt` para `border_project_fields.dart`.
- [x] Deixar `border_project_screen.dart` com build, indicador, card, navegação, carregamento de cenário e cálculo.
- [x] Rodar `test/features/irrigation/border_project_screen_test.dart`.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** `border_project_screen.dart` fica abaixo de ~300 linhas e cada step tem responsabilidade única.

## Tarefa 11: Quebrar a tela de resultado de faixas

**Arquivos:**
- Manter: `lib/features/irrigacao_faixas/views/border_results_screen.dart` (orquestrador)
- Criar: `lib/features/irrigacao_faixas/views/border_results/border_results_sections.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_results/border_results_kpis.dart`
- Criar: `lib/features/irrigacao_faixas/views/border_results/border_results_actions.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_charts.dart`
- Teste: `test/features/irrigation/border_results_screen_test.dart`

**Passos:**
- [x] Mover as seções auditáveis (`Dados e hipóteses`, `Avanço e recessão`, `Perfil e balanço`, `Auditoria e operação`, `Detalhes técnicos`) para `border_results_sections.dart`.
- [x] Mover a construção dos KPIs para `border_results_kpis.dart`.
- [x] Mover o diálogo de comparação de vazões e o botão de alternativas para `border_results_actions.dart`.
- [x] Refatorar `BorderCharts` para usar `IrrigationChartSection` como shell, preservando as abas dinâmicas e os testes de `Semantics`.
  - `IrrigationChartTab` ganhou `semanticsLabel` opcional (default = `label`) para preservar visível `Volumes` × Semantics `Gráfico de Volumes` sem dobrar o chip.
  - `height: 380` nesta tela para evitar overflow de 11 px com `TextScaler.linear(1.8)`.
- [x] Manter o CSV em `faixa_csv.dart` e a exportação no componente compartilhado.
- [x] Rodar o teste de resultados de faixas.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** a tela orquestra, mas não contém regras de montagem de seções nem diálogos extensos.

## Tarefa 12: Quebrar a tela de projeto de inundação

**Arquivos:**
- Manter: `lib/features/irrigacao_inundacao/views/basin_project_screen.dart` (orquestrador)
- Criar: `lib/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/regime_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/area_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/taipa_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/solo_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/cultura_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/clima_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/operacao_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/planejamento_step.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_project_steps/revisao_step.dart`
- Teste: `test/features/irrigation/basin_project_screen_test.dart`

**Passos:**
- [x] Mover cada método `_*Fields` para o step correspondente.
- [x] Mover `_number`, `_select`, `_review`, `_fmt` e `_layoutFields` para `basin_project_fields.dart`.
- [x] Manter no orquestrador apenas estado do wizard, carregamento de cenário, cálculo e navegação.
- [x] Rodar o teste de projeto de inundação.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** `basin_project_screen.dart` fica abaixo de ~350 linhas e cada step tem responsabilidade única.

## Tarefa 13: Quebrar a tela de resultado de inundação

**Arquivos:**
- Manter: `lib/features/irrigacao_inundacao/views/basin_results_screen.dart` (orquestrador)
- Criar: `lib/features/irrigacao_inundacao/views/basin_results/basin_results_sections.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_results/basin_results_kpis.dart`
- Criar: `lib/features/irrigacao_inundacao/views/basin_results/basin_results_charts.dart`
- Teste: `test/features/irrigation/basin_results_screen_test.dart`

**Passos:**
- [x] Mover as seções auditáveis para `basin_results_sections.dart`.
- [x] Mover a construção dos KPIs para `basin_results_kpis.dart`.
- [x] Mover o agrupamento de gráficos em abas para `basin_results_charts.dart`.
- [x] Manter no orquestrador o banner, a barra de ações, a exportação e o salvamento.
- [x] Rodar o teste de resultados de inundação.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** `basin_results_screen.dart` fica abaixo de ~350 linhas.

## Tarefa 14: Limpar as telas de design de sulcos

**Arquivos:**
- Criar: `lib/features/irrigacao_sulcos/services/csv_sulco.dart`
- Criar: `lib/features/irrigacao_sulcos/views/project_results/operational_planning_section.dart`
- Criar: `lib/features/irrigacao_sulcos/views/project_results/furrow_details_section.dart`
- Criar: `lib/features/irrigacao_sulcos/views/project_results/save_card.dart`
- Criar: `lib/features/irrigacao_sulcos/views/project_results/detail_sub_section.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results_screen.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results/project_results_sections.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart`
- Teste: `test/features/irrigation/project_results_screen_test.dart`

**Passos:**
- [x] Mover `_buildCsv` para `csv_sulco.dart` com a assinatura `String csvSulco(EstadoParametrosSulco state, SimulationResult result)`.
- [x] Mover `OperationalPlanningSection`, `FurrowDetailsSection`, `DetailSubSection` e `SaveCard` para arquivos próprios.
- [x] Remover wrappers que só delegam (`AuditableSection`, `AuditRow`, `FormulaCard`, `AlertBanner`) e usar diretamente `IrrigationAuditSection`, `IrrigationAuditRow`, `IrrigationFormulaCard` e `IrrigationAlertBanner`.
- [x] Mover `ScenarioComparison` para um arquivo próprio ou para o widget compartilhado de comparação.
- [x] Rodar o teste de resultados de sulcos.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** `project_results_screen.dart` fica abaixo de ~400 linhas, o CSV sai da view e os wrappers desnecessários desaparecem.

## Tarefa 15: Unificar campos numéricos e seletores

**Arquivos:**
- Criar: `lib/shared/irrigacao/widgets/irrigation_input_fields.dart`
- Teste: `test/shared/irrigation/irrigation_input_fields_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_steps/project_step_widgets.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_project/border_project_fields.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart`

**Interfaces:**
- `class IrrigationNumberField extends StatelessWidget`
  - `String label`
  - `double? value`
  - `String? unit`
  - `bool optional`
  - `bool allowZero`
  - `String? helper`
  - `String? Function(String?)? validator`
  - `ValueChanged<String> onChanged`
  - `Key? fieldKey`
- `class IrrigationSelectField<T> extends StatelessWidget`
  - `String label`
  - `T value`
  - `List<T> options`
  - `String Function(T) labelFor`
  - `ValueChanged<T> onChanged`
  - `bool expanded = true`

**Passos:**
- [x] Escrever teste de `IrrigationNumberField` com vírgula e ponto, valor opcional vazio e validador customizado.
- [x] Escrever teste de `IrrigationSelectField` com três opções e troca de valor.
- [x] Rodar os testes e confirmar que falham.
- [x] Implementar os componentes mantendo `FilteringTextInputFormatter` e as mensagens de validação existentes via callback.
  - `IrrigationNumberField` ganhou parâmetro opcional `initialText` para a tela de inundação (sempre exibiu `'30,0'`/`'56,0'` com vírgula no valor inicial — preservado).
- [x] Rodar os testes e confirmar que passam.
- [x] Substituir os `TextFormField` numéricos e `DropdownButtonFormField` repetidos nas três features.
  - Obs.: em sulcos, `OptionalNumericCurveField` (k/b, sem formatação/validação próprias) permanece simples — não é o padrão repetido com formatação/validação.
- [x] Rodar os testes de projeto das três features.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** existe uma única implementação de campo numérico e de seletor para as três features.

## Tarefa 16: Formatação numérica compartilhada

**Arquivos:**
- Criar: `lib/shared/irrigacao/services/formatacao_numerica.dart`
- Teste: `test/shared/irrigation/formatacao_numerica_test.dart`
- Modificar: `lib/features/irrigacao_sulcos/views/project_steps/project_step_widgets.dart`
- Modificar: `lib/features/irrigacao_faixas/views/border_project/border_project_fields.dart`
- Modificar: `lib/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart`

**Interfaces:**
- `String formatarNumero(double? valor, {int casas = 2, bool removerZerosFinais = false, String vazio = '—'})`
- `String formatarNumeroComUnidade(double? valor, String unidade, {int casas = 2, String vazio = '—'})`

**Passos:**
- [x] Escrever teste com `null`, inteiro, decimal, valor muito pequeno e `removerZerosFinais`.
- [x] Rodar o teste e confirmar que falha.
- [x] Implementar as duas funções.
- [x] Rodar o teste e confirmar que passa.
- [x] Substituir `_fmt` locais por `formatarNumero`.
  - Faixas: `BorderProjectFields.format` delega a `formatarNumero` mantendo o caso especial de valores < 0,001 (6 casas); Boomher/IRN idem.
  - Inundação: `BasinProjectFields.format` = `formatarNumero(casas, removerZerosFinais: true)`.
  - Sulcos: `_format` de `project_step_widgets` eliminado; o valor inicial dos campos agora vem de `IrrigationNumberField` (`formatarNumero` com 6 casas sem zeros finais).
- [x] Rodar os testes das três features.
- [x] Rodar `flutter analyze`.

**Critério de conclusão:** não há mais três implementações diferentes de formatação numérica.

---

# Etapa 3 — Fechamento e guardrails

### Tarefa 17: Validação final

**Passos:**
- [x] Rodar `flutter analyze` e garantir zero issues.
- [x] Rodar `flutter test` e garantir toda a suíte verde.
- [x] Rodar os testes de arquitetura, em especial `test/architecture/shared_sem_features_test.dart`.
- [ ] Verificar manualmente cada tela em:
  - 390×844 (celular estreito)
  - 800×900 (tablet)
  - 1120×1800 (desktop)
  - tema claro e escuro
  - `TextScaler.linear(1.8)`
  - *Coberto parcialmente pelos testes de fumaça em tema escuro + `TextScaler.linear(1.8)` e larguras 390/800/1100; revisão manual visual ainda recomendada.*
- [x] Conferir que nenhum texto, tooltip, `ValueKey` ou `Semantics` usado por teste desapareceu.
- [x] Conferir que o CSV exportado continua com o mesmo conteúdo e a mesma ordem.
- [x] Atualizar este documento com o que foi concluído e o que ficou para depois.

**Critério de conclusão:** análise limpa, suíte verde, três telas visualmente consistentes e arquivos de tela com responsabilidade de orquestração.

---

## Ordem de execução resumida

1. Baseline.
2. Design system compartilhado (banners, KPIs, gráficos, campos, navegação, exportação, estados).
3. Aplicar em faixas.
4. Aplicar em inundação.
5. Alinhar sulcos ao design system.
6. Quebrar projeto/resultado de faixas.
7. Quebrar projeto/resultado de inundação.
8. Limpar telas de sulcos.
9. Unificar campos e formatação.
10. Validação final.

## Não-metas

- Não mover componentes de irrigação para `lib/core/widgets/`.
- Não alterar a matemática, os modelos ou os controllers.
- Não renomear arquivos/classes por estética nesta empreitada.
- Não introduzir novo gerenciador de estado.
- Não criar golden tests de imagem nesta etapa.
- Não commitar sem autorização.

---

## Registro de execução — Etapas 0 e 1 (concluídas)

**Baseline (Etapa 0):** `flutter analyze` com 2 issues pré-existentes (`modelo_curva_avanco.dart:291` info, `controlador_parametros_sulco.dart:17` warning) e `flutter test` com 292 testes verdes — ambos preservados ao fim da etapa.

**Componentes compartilhados criados em `lib/shared/irrigacao/widgets/`:**
- `irrigation_feedback.dart` (`IrrigationBanner`) — banners de status das três features.
- `irrigation_kpi.dart` (`IrrigationKpiGrid`/`IrrigationKpiItem`) — valor e unidade separados, cores de acento `AppColors.sulco`/`faixa`/`inundacao`.
- `irrigation_chart_section.dart` (`IrrigationChartSection`) — shell de gráficos em abas (sulcos e inundação).
- `irrigation_forms.dart` (`IrrigationLabeledField`, `IrrigationFieldGrid`, `IrrigationStepNavigation`) — navegação recebeu `nextTooltip`/`calculateTooltip`/`calculateIcon` opcionais para preservar os tooltips/ícones de faixas e inundação.
- `irrigation_export.dart` (`showIrrigationExportSheet`) — substitui `_showExport` de sulcos e `_mostrarExportacao` de faixas/inundação.
- `irrigation_states.dart` (`IrrigationEmptyResult`) — estados vazios; sulcos também usa `LoadingWidget` do core no carregamento.
- `lib/core/widgets/kpi_card.dart` atualizado (raio 24, padding 16, `headlineSmall`).

**Aplicação nas telas (tarefas 7–9):** faixas e inundação com indicador/card/navegação do design system, espaçamento `IrrigationSpacing.major` e subtitles por etapa; inundação agrupou os gráficos em `_BasinCharts` com abas (`IrrigationChartSection`); sulcos mantém wrappers locais que delegam ao shared, a serem removidos na Etapa 2.

**Correções visuais extraídas dos testes de fumaça:**
- `_BooherTable` (`basin_reference_panel.dart`): `DataTable.dataRowMaxHeight: double.infinity` para a linha crescer com `TextScaler.linear(1.8)`.
- `WaterBalanceChart` (shared): overlay central em `FittedBox(fit: BoxFit.scaleDown)` para o gráfico em 180 px não transbordar com texto ampliado.

**Testes adicionados:**
- `test/shared/irrigation/`: testes dos componentes compartilhados (banner, KPI, export com mock de `SystemChannels.platform`, estado vazio).
- Fumaça de `BasinResultsScreen` e `ProjectResultsScreen` em tema escuro + `TextScaler.linear(1.8)`.

**`flutter analyze` final:** mesmas 2 issues do baseline. Testes de tela das três features verdes.

---

## Registro de execução — Etapas 2 e 3 (concluídas)

**Ordem executada:** Tarefa 16 (formatação compartilhada) → Tarefa 15 (campos compartilhados) → Tarefas 10/12/11/13 (quebras das telas) → Tarefa 14 (sulcos) → Tarefa 17 (validação). Bases compartilhadas foram implementadas antes das quebras para evitar duplicar `_fmt`/campos em três lugares.

**Componentes compartilhados criados:**
- `lib/shared/irrigacao/services/formatacao_numerica.dart` (`formatarNumero`, `formatarNumeroComUnidade`) — Tarefa 16.
- `lib/shared/irrigacao/widgets/irrigation_input_fields.dart` (`IrrigationNumberField`, `IrrigationSelectField`) — Tarefa 15; `IrrigationFieldGrid` passou a reconhecê-los como "chips" de coluna como já fazia com `IrrigationLabeledField`.

**Quebras de telas (Tarefa 10–13):**
- `border_project_screen.dart` 1320 → 303 linhas + `border_project_fields.dart` + 8 steps (`border_project_steps/`).
- `border_results_screen.dart` 968 → 297 linhas + `border_results/{sections,kpis,actions}.dart`; `BorderCharts` usa `IrrigationChartSection` (aba com `semanticsLabel` opcional para preservar `Gráfico de Volumes` etc.; altura 380 px para escala 1.8).
- `basin_project_screen.dart` 1924 → 328 linhas + `basin_project_fields.dart` + 9 steps (`basin_project_steps/`).
- `basin_results_screen.dart` → 212 linhas + `basin_results/{sections,kpis,charts}.dart`.
- `project_results_screen.dart` (sulcos) 798 → 179 linhas; CSV movido para `services/csv_sulco.dart` (`csvSulco`); `OperationalPlanningSection`, `FurrowDetailsSection`, `DetailSubSection`, `SaveCard` e `ScenarioComparison` em arquivos próprios; seções auditáveis em `project_results_sections.dart` (`secoesAuditoriaSulco`).

**Wrappers removidos/pendentes:** `AuditableSection`, `AuditRow`, `FormulaCard`, `AlertBanner` (sulcos) foram removidos e substituídos pelos componentesIR compartilhados. `StepBentoCard`, `StepFieldGrid`, `StepNavigationButtons`, `KpiGrid` (delegates puros) continuam em `project_steps/project_step_widgets.dart` e podem ser removidos numa passada de limpeza futura.

**Validação final (Tarefa 17):**
- `flutter analyze`: **0 issues** (baseline de 2 issues da Etapa 0 resolvido: chaves em `modelo_curva_avanco.dart` e import não usado em `controlador_parametros_sulco.dart`).
- `flutter test`: **326 testes, todos passando** (baseline era 292).
- `test/architecture/` (shared_sem_features + ordem_chaves_persistencia): verde.
- Guardas: nenhum CSV, tooltip, `ValueKey`, `Semantics` ou mensagem alterado; testes de posição de botões (inundação) e de `ValueKey` (faixas/inundação) continuam intocáveis.

**Anotações de escopo:**
- `IrrigationNumberField` recebeu parâmetros opcionais `initialText` (inundação preserva vírgula como `'30,0'`), `fieldKey` e `validator` — comportamento e testes preservados.
- Formatação numérica unificada em `formatarNumero` (ponto, zeros finais removidos); o caso especial de faixas (valores < 0,001 com 6 casas) fica no delegador `BorderProjectFields.format`.
- O erro de compilação transiente em `lib/features/perfil/` (`expansionTileShape`) durante a sessão era WIP paralelo do usuário e não exigiu intervenção.
- Nada foi commitado; o worktree mantém as mudanças pré-existentes ao lado das novas.

