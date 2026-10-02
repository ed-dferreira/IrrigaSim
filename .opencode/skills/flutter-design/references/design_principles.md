# Princípios de design Flutter

Guia de referência por trás dos templates em `app_theme_template.dart`,
`app_text_styles_template.dart` e `app_icons_template.dart`. Consulte a
seção relevante quando for criar ou revisar UI.

## 1. Tokens antes de valores soltos

Nunca escreva `Color(0xFF...)`, `fontSize: 16`, ou `Icons.save` direto num
widget de tela. Tudo passa por três arquivos centrais:

- `app_colors.dart` — `ColorScheme` completo (light + dark + variante
  highContrast), nunca cores isoladas sem papel semântico.
- `app_text_styles.dart` — `TextTheme` construído via `buildTextTheme()`.
- `app_icons.dart` — todo ícone do app, agrupado por feature.

Ao revisar código, qualquer `Color(0xFF...)`, `TextStyle(fontSize: ...)` ou
`Icons.` direto dentro de um widget de tela é um cheiro de código a apontar
(exceção: os próprios arquivos de token).

## 2. Material 3, mas "flat"

- `useMaterial3: true` sempre.
- `elevation: 0` na maioria dos componentes (AppBar, Card, NavigationBar,
  botões). Separação visual vem de `outline`/`outlineVariant` (bordas
  finas), não de sombra.
- Fundos usam a escala `surfaceContainerLow/…/Highest` do ColorScheme para
  criar hierarquia sem elevação.

Isso é uma escolha estética válida, mas é uma escolha — se o projeto do
usuário já usa elevação/sombra de propósito, siga o padrão existente em vez
de "corrigir" para flat.

## 3. Escala de raio de borda (duas categorias, não uma por widget)

- `cardRadius` (ex. 24): containers grandes — cards, sheets, diálogos.
- `controlRadius` (ex. 16): botões, inputs, chips.
- Controles pequenos (ícone isolado, indicador de nav) podem usar um raio
  menor (ex. 14), mas mantenha só 2–3 valores no total. Se uma tela nova
  introduz um quarto valor de raio, isso é inconsistência — alinhe a um dos
  existentes em vez de inventar um novo.

## 4. Acessibilidade é parâmetro do tema, não um "modo extra"

O tema é construído como função de:

- `fontScale` (double, multiplicador aplicado a todo `fontSize`)
- `highContrast` (bool, troca a `ColorScheme` inteira, não só ajusta opacidade)
- `boldText` (bool, aumenta o peso da fonte no `TextTheme` inteiro)

Ao adicionar qualquer novo `TextStyle`, ele **precisa** aceitar esses
parâmetros (ou vir do `TextTheme` já escalado) — um `TextStyle` com
`fontSize` fixo quebra a acessibilidade do app inteiro.

Combine também com os sinais do próprio sistema operacional
(`MediaQuery.boldTextOf`, `MediaQuery.textScalerOf`) em vez de só expor as
prefs do app — o efetivo deve ser a composição dos dois (ver padrão de
`App` que combina `perfilState` com `MediaQuery` antes de repassar ao tema).

Outros sinais de acessibilidade a preservar como estado de app (não só de
tema): animações reduzidas (`reducedAnimations`) e modo leitor de tela
(`modoLeitorTela`/semelhante), expostos via um escopo
(`InheritedWidget`/provider) que qualquer widget pode consultar para decidir
se anima ou anuncia algo extra via `Semantics`.

## 5. Alvo de toque mínimo

Todo elemento tocável (botão, ícone de ação, item de lista clicável) tem
`minimumSize` de pelo menos 48x48 (WCAG / Material). Isso vale mesmo para
ícones "decorativos" que viram clicáveis.

## 6. Ícones: nomeados por intenção, agrupados por feature

Ver `app_icons_template.dart`. Nunca `Icons.x` cru em uma tela; sempre
`AppIcons.nomeDaIntencao`. O arquivo de ícones deve, ao ser lido de cima a
baixo, funcionar como um mapa das telas/fluxos do produto.

## 7. Detectar a arquitetura do projeto antes de gerar código

Este é um ponto que **muda por projeto** e não deve ser assumido:

1. Olhe `pubspec.yaml` para identificar o gerenciamento de estado
   (`flutter_riverpod`, `flutter_bloc`, `provider`, nenhum ⇒ `StatefulWidget`
   puro).
2. Olhe um arquivo de feature já existente (`lib/features/**`) para copiar o
   padrão real usado (nome de camadas — `presentation`, `view_model`,
   `provider` — convenções de nomeação em português ou inglês, etc.).
3. Gere código novo seguindo o que já existe no projeto, não um padrão fixo
   desta skill. Se o projeto não tiver nada ainda, prefira Riverpod
   (`ConsumerWidget`/`ConsumerStatefulWidget` + `Provider`/`NotifierProvider`)
   como default razoável, mas pergunte se o usuário quer outra coisa antes de
   assumir para um projeto novo.
4. Se perceber um padrão novo e consistente que vale a pena guardar (ex.: o
   projeto sempre usa um nome de camada específico, ou uma convenção de
   nomeação particular), sugira atualizar esta skill (arquivo
   `references/design_principles.md` ou os templates) para refletir isso —
   não decida sozinho, confirme com o usuário primeiro.

## 8. Revisão de UI — checklist rápido

Ao revisar uma tela ou componente existente, verificar:

- [ ] Cores vêm de `Theme.of(context).colorScheme`, não hardcoded.
- [ ] Texto vem de `Theme.of(context).textTheme` ou de um `*Scaled(...)`,
      não de `TextStyle(fontSize: N)` fixo.
- [ ] Ícones vêm de `AppIcons.*`, não de `Icons.*` direto.
- [ ] Raio de borda é um dos valores padrão do tema (não um número novo).
- [ ] Elementos tocáveis têm no mínimo 48x48.
- [ ] Se a tela tem texto/valor importante, ele reage a `fontScale` e
      `boldText`.
- [ ] Nenhuma informação é passada só por cor (ex.: erro só em vermelho sem
      ícone/texto) — importante para daltonismo e para `highContrast`.
- [ ] Estado de loading/erro/vazio existe e usa os mesmos tokens (não é um
      texto solto improvisado).
