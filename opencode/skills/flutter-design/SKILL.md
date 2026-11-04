---
name: flutter-design
description: >-
  Boas práticas de design de UI para apps Flutter — criação e revisão de
  telas, temas (ThemeData/ColorScheme), tipografia, ícones e componentes,
  com acessibilidade (escala de fonte, alto contraste, negrito, leitor de
  tela, animações reduzidas) embutida desde o início. Use esta skill sempre
  que o usuário pedir para criar, desenhar, montar ou revisar qualquer parte
  da interface de um app Flutter — telas, widgets, tema, cores, tipografia,
  componentes, navegação — mesmo que ele não use a palavra design
  explicitamente, por exemplo faz uma tela de login, muda a cor do botão,
  cria um card de resultado, revisa esse widget. Também use quando o
  usuário mencionar Material 3, ColorScheme, ThemeData, acessibilidade em
  Flutter, ou pedir para criar ou editar arquivos de tokens de design como
  AppColors, AppTextStyles, AppIcons ou AppTheme.
---

# Design de UI para Flutter

Skill geral para trabalho de design em apps Flutter: cria UI nova e revisa UI
existente, sempre em cima de um design system próprio baseado em tokens
(cores, tipografia, ícones, raio de borda) em vez de valores soltos, com
acessibilidade como requisito de primeira classe, não um extra.

Esta skill assume Material 3 com uma estética "flat" (elevação baixa/zero,
separação por borda) como ponto de partida, mas **sempre prioriza os
padrões que já existem no projeto do usuário** sobre os defaults descritos
aqui — ver Passo 1.

## Quando usar cada arquivo

- **Este arquivo (SKILL.md)**: fluxo de trabalho — o que fazer, em que ordem.
- **`references/design_principles.md`**: o "porquê" de cada regra (raio de
  borda, elevação, acessibilidade, alvo de toque, etc.) e o checklist de
  revisão. Leia antes de revisar uma tela, ou quando precisar justificar uma
  escolha de design.
- **`references/app_theme_template.dart`**: padrão de `ThemeData` completo
  (cores, botões, inputs, nav bar, snackbar...) parametrizado por
  `fontScale`/`highContrast`/`boldText`.
- **`references/app_text_styles_template.dart`**: padrão de `TextTheme` +
  variantes escaladas para acessibilidade.
- **`references/app_icons_template.dart`**: padrão de registro central de
  ícones, agrupado por feature.

Não é necessário ler os quatro de uma vez. Leia o que for relevante para a
tarefa (ex.: só `app_theme_template.dart` se a tarefa é sobre cores/tema).

## Passo 1 — Detectar as convenções do projeto (sempre, antes de gerar código)

Nunca assuma arquitetura ou tokens de design de cabeça. Antes de escrever
qualquer widget ou alterar o tema:

1. Rode/veja `pubspec.yaml` para identificar o gerenciamento de estado do
   projeto (`flutter_riverpod`, `flutter_bloc`, `provider`, ou nenhum →
   `StatefulWidget` puro). **Gere o código novo seguindo o que o projeto já
   usa**, não um padrão fixo desta skill.
2. Procure por arquivos de tokens já existentes (tipicamente
   `lib/app/theme/` ou `lib/core/theme/`: `app_colors.dart`,
   `app_text_styles.dart`, `app_theme.dart`, `app_icons.dart` ou nomes
   equivalentes). Se existirem, **use-os** — não crie tokens paralelos.
3. Se não existirem tokens ainda e a tarefa exigir criá-los, use os arquivos
   em `references/` como ponto de partida, adaptando cores/raios ao
   branding informado pelo usuário.
4. Se perceber, ao longo do trabalho, um padrão do projeto que vale a pena
   virar regra geral desta skill (uma convenção de nomeação, uma decisão de
   arquitetura consistente), avise o usuário e pergunte se quer que a skill
   seja atualizada com isso — não decida sozinho.

## Passo 2 — Criar UI nova

1. Complete o Passo 1.
2. Estruture qualquer widget de tela em cima de tokens:
   `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`,
   `AppIcons.*` — nunca `Color(0xFF...)`, `TextStyle(fontSize: N)` ou
   `Icons.*` soltos no meio do widget (exceção: os próprios arquivos de
   token).
3. Aplique a escala de raio do projeto (tipicamente 2 valores: um para
   containers grandes, outro para controles — ver
   `references/design_principles.md` §3).
4. Garanta alvo de toque mínimo 48x48 em qualquer elemento tocável.
5. Se o texto carrega informação importante (valor de resultado, alerta),
   confirme que reage a `fontScale`/`boldText` do tema — nunca hardcode
   `fontSize`.
6. Nunca comunique estado (erro, sucesso, alerta) só por cor — combine com
   ícone e/ou texto, para não quebrar com `highContrast` ou daltonismo.
7. Trate os três estados básicos de qualquer tela com dados: carregando,
   vazio, erro — usando os mesmos tokens de tema, não texto improvisado.

## Passo 3 — Criar ou estender o design system (tema, cores, tipografia, ícones)

1. Complete o Passo 1.
2. Leia o template relevante em `references/` inteiro antes de editar —
   eles têm comentários explicando cada decisão.
3. Ao adicionar uma cor nova: dê um papel semântico a ela dentro do
   `ColorScheme` (ex. `tertiaryContainer` para um novo tipo de destaque) em
   vez de criar uma constante solta `Color(0xFF...)` fora do ColorScheme.
4. Ao adicionar um ícone novo: coloque no grupo de feature correto (ou crie
   um novo grupo com comentário de seção) em `app_icons.dart`, nomeado pela
   intenção ("confirmarPagamento"), não pelo ícone ("checkIcon").
5. Ao adicionar um estilo de texto novo: se é um caso comum, adicione ao
   `TextTheme` via `buildTextTheme`; se é um caso especial (ex. um número
   gigante de destaque), crie uma variante `nomeScaled(fontScale, {bold})`
   seguindo o padrão das existentes — nunca um `TextStyle` fixo.

## Passo 4 — Revisar UI existente

1. Leia `references/design_principles.md` §8 (checklist).
2. Percorra o(s) arquivo(s) fornecido(s) item a item do checklist.
3. Reporte achados agrupados por severidade:
   - **Quebra acessibilidade** (fontSize fixo, alvo de toque pequeno, cor
     como único sinal de estado) — prioridade alta.
   - **Inconsistência de design system** (cor/raio/ícone fora do padrão do
     projeto) — prioridade média.
   - **Sugestão de polimento** (espaçamento, hierarquia visual) — opcional.
4. Para cada achado, mostre o trecho problemático e a correção sugerida
   usando os tokens corretos do projeto (não os do template, se o projeto
   já tiver os seus próprios).

## Lembretes finais

- Português nos nomes de widgets/campos é aceitável e comum nesse tipo de
  projeto (ex. `perfilState`, `temaEscuro`) — siga o idioma que o projeto já
  usa, não force inglês nem português.
- Esta skill descreve uma estética específica (Material 3 flat, cantos
  arredondados generosos, tokens semânticos). Se o usuário pedir
  explicitamente outra estética (Cupertino puro, Material 2, design mais
  "denso"/corporativo), siga o pedido dele — os defaults aqui são um ponto
  de partida, não uma regra rígida.
