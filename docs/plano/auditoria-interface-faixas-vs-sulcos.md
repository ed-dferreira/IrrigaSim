# Auditoria de interface — faixas vs. sulcos

Data: 2026-09-30 · Escopo: paridade visual/estrutural entre o fluxo de **faixas**
(`border_project_screen.dart`, `border_results_screen.dart`, `border_charts.dart`) e o fluxo de
**sulcos** (`project_screen.dart`, `project_results_screen.dart`), que é a referência.

Arquivos de referência:

- `lib/views/irrigation/sulcos/project_screen.dart` (2553 linhas)
- `lib/views/irrigation/sulcos/project_results_screen.dart` (1687 linhas)
- `lib/views/irrigation/faixas/border_project_screen.dart` (717 linhas)
- `lib/views/irrigation/faixas/border_results_screen.dart` (425 linhas)
- `lib/views/irrigation/faixas/border_charts.dart` (134 linhas)

---

## 1. Tela de projeto (formulário)

| Aspecto | Sulcos (referência) | Faixas (atual) |
|---|---|---|
| Progresso de etapas | `_StepIndicator` custom: chips animados (radius 14), estado "Etapa atual/Preenchida" via `Semantics(button/selected)`, tooltip, chevrons `etapasAnteriores/Seguintes`, check de concluída, accent por método — `project_screen.dart:187-403` | `ChoiceChip` puro do Material, sem a11y de etapa, sem setas, sem estado de concluída — `border_project_screen.dart:65-81` |
| Confirmação de etapa | "Confirmar" → Chip "Confirmada"; cálculo exige todas confirmadas (`_allStepsConfirmed`, `project_screen.dart:76`) | **Inexistente** — pula etapas livremente sem validar |
| Card da etapa | `_BentoCard`: ícone+accent, título w700, subtítulo `onSurfaceVariant` — `project_screen.dart:481-518` | `Card` sem título visual, sem ícone, sem subtítulo — `border_project_screen.dart:83-98` |
| Navegação | `_NavigationButtons`: "Voltar" (`arrow_back`), "Confirmar" (`check_circle`), "Próximo" (`arrow_forward`), final com spinner + `AppIcons.executarSimulacao` — `project_screen.dart:404-477` | "Anterior" com **ícone errado** (`projetoRevisao` = fact_check) em `border_project_screen.dart:136`, "Calcular faixa" sem ícone/spinner — `border_project_screen.dart:139-175` |
| Campos | `_Field`: label acima (`labelLarge`), `inputFormatters` `[0-9,.-]`, 2 colunas no desktop (`_FieldGrid` width 300) — `project_screen.dart:534-651` | `labelText` dentro do campo, sem filtro de entrada, coluna única, `suffixText` — `border_project_screen.dart:637-676` |
| Erros de validação | Mensagem pelo `validator` no próprio campo | Erro de estacas em `Text` vermelho solto — `border_project_screen.dart:452-457` |
| Revisão | `_RevisaoStep`: hero com gradiente accent, Cards por seção com ícone, rows label 160px/valor — `project_screen.dart:1938-2048` | `Text('$label: $value')` corrido, sem seções/ícones/colunas — `border_project_screen.dart:595-634` |
| Accent do método | `_methodColor` → `AppColors.faixa` — `project_screen.dart:2549-2553` | **Não usa** accent nenhum |
| Conteúdo técnico | Fórmulas/`CalculatedField` | `Text` solto: S0/St (`border_project_screen.dart:225-227`), tabelas Marr/Booher em `ExpansionTile` de texto puro (`:311-322`), ensaio medido em `Text` (`:485-495`) |

## 2. Tela de resultados

| Aspecto | Sulcos (referência) | Faixas (atual) |
|---|---|---|
| Estado vazio/erro | Ícone 48 + título + detalhe + recuperação — `project_results_screen.dart:37-75` | `Text('Nenhum cálculo…')` nu — `border_results_screen.dart:34-39` |
| Exportar | AppBar action → bottom sheet com pré-visualização `SelectableText` + copiar — `project_results_screen.dart:104-186` | Só botão "Copiar CSV" no fim da página — `border_results_screen.dart:394-416` |
| KPIs | `_KpiGrid` responsivo (Ea/CUC/DU/lâmina/avanço/Er) com classificação — `project_results_screen.dart:757-843` | **Inexistente** — Ea/Er/Pp/Pe/ta/tr em linhas de texto — `border_results_screen.dart:132-141` |
| Seções | `_AuditableSection` (ícone accent + título w700) — `project_results_screen.dart:846-877` | `section()` local com `titleLarge` sem ícone — `border_results_screen.dart:50-62` |
| Linhas de auditoria | `_AuditRow` responsivo (<520 empilha), valor w600, `detail`, `isWarning` em `error` — `project_results_screen.dart:881-955` | `row()` `'$label: $value'` sem formatação — `border_results_screen.dart:46-49` |
| Avisos/erros | `_AlertBanner` (`errorContainer`) — `project_results_screen.dart:997-1028` | Avisos em `Row` com ícone `onSurfaceVariant` (sem cor de erro) — `border_results_screen.dart:198-211` |
| Fórmulas | `_FormulaCard` (fórmula + descrição) — `project_results_screen.dart:958+` | Fórmulas F07/F09/F19/Hart/F04 em linhas densas com `toStringAsExponential` — `border_results_screen.dart:180-196` |
| Terreno | `TerrainView` — `project_results_screen.dart:250` | **Inexistente** |
| Recomendação | `_RecommendationBanner` — `project_results_screen.dart:685` | Botão "Comparar vazões" solto — `border_results_screen.dart:281-331` |
| Perfil amostrado | — | 10+ linhas de `row()` — `border_results_screen.dart:145-153` (sem expansão/tabela) |
| Salvar cenário | Validação de nome + snackbar — `project_results_screen.dart:90-102` | Validação apenas por `onPressed` — `border_results_screen.dart:365-393` |

## 3. Gráficos (`border_charts.dart`)

- OK: `Semantics` descritivo (`:65-67`, `:99-101`) e respeito a `disableAnimations` (`:87`, `:120`).
- Falta: envolver em `_ChartSection` (título, card, eixo/legenda estilizada como sulcos);
  legenda de cores — "Avanço · Recessão" e "Infiltração · IRN" só como texto abaixo do gráfico (`:94-97`, `:127-130`).

## 4. Achados corrigíveis imediatamente

1. Ícone do botão "Anterior" é `AppIcons.projetoRevisao` (fact_check) — `border_project_screen.dart:136`.
2. Sem estado "Calculando…" no botão final (cálculo síncrono; spinner ainda dá feedback).
3. Sem `Semantics`/tooltip nos chips e botões das faixas (sulcos tem em todos).
4. `BorderStatus` exibido como texto simples em vez de banner tipado (sulcos usa `_AlertBanner`) — `border_results_screen.dart:87-93`.
5. Altura fixa `SizedBox(height: 64)` nos chips (`border_project_screen.dart:65`) — teste de textScale 2 já existe e passa, mas paridade pede a abordagem do `_StepIndicator`.

## 5. Plano de adequação (3 fases)

### F1 — Compartilhar componentes
Extrair de `project_screen.dart` para `lib/views/irrigation/widgets/`:
- `_StepIndicator`, `_BentoCard`, `_NavigationButtons`, `_Field`/`_StringField`/`_FieldGrid`, hero de revisão;
- de `project_results_screen.dart`: `_AuditableSection`/`_AuditRow`, `_KpiGrid`, `_AlertBanner`, `_FormulaCard`, `_ChartSection`.

Sulcos passa a importar os mesmos widgets → paridade garantida e mantida.

### F2 — Reformular `border_project_screen.dart`
- Etapas com confirmação (chips com estado concluído + Semantics), accent `AppColors.faixa`;
- ícones corrigidos (`arrow_back`/`arrow_forward`/`executarSimulacao`), spinner no cálculo;
- campos com label acima + `inputFormatters` + `_FieldGrid` 2 colunas no desktop;
- erro de estacas dentro do campo; revisão em seções com ícone; Booher/Marr em cards estilizados.

### F3 — Reformular `border_results_screen.dart` + `border_charts.dart`
- Estado vazio/erro com ícone + CTA; export via bottom sheet (AppBar action);
- KPI grid (ta, tr, Ea, Er, Pp, Pe, lâmina); `TerrainView`;
- `_AlertBanner` para `BorderStatus` e avisos do modelo; `_FormulaCard` para F04/F07/F19/Hart;
- `_ChartSection` com legenda de cores; perfil amostrado em expansão/tabela.

### Verificação
- `flutter analyze` limpo;
- ajustar `test/features/irrigation/border_project_screen_test.dart` e
  `border_results_screen_test.dart` (asserts em 'Próxima etapa', 'Tabela Booher',
  'Dados e hipóteses' podem mudar de posição/nome);
- revisar com a skill `flutter-design` (a11y, escala de fonte, contraste).

### Fora de escopo (esta auditoria)
- L1–L10 do `plano-completo-irrigacao-por-faixas.md` (golden tests, contrato numérico,
  status tipados, Xa/Va/Vd/F21, busca F04, F31/W0, ensaio de campo, comparação/gráficos,
  dique/dispositivo, links/docs) — ver Etapas 7–11 daquele plano.
