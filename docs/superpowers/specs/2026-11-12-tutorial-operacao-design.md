# Tutorial de operação do IrrigaSIM — desenho

Data: 2026-11-12

## 1. Intenção

Criar uma área consultável de tutorial dentro do Perfil para ensinar a **operar o IrrigaSIM**: onde ficam as telas, o que cada etapa pede, como revisar, calcular, ler resultados e salvar cenários. O foco é operação do aplicativo, não conceitos agronômicos ou fórmulas.

O acesso é opcional e permanente. Não há onboarding automático, popup de primeiro acesso nem destaque sobre as telas reais.

## 2. Objetivos

- Servir como manual de operação consultável a qualquer momento.
- Organizar o conteúdo por assunto e permitir abrir um artigo específico.
- Oferecer atalhos para a tela real correspondente ao final de cada artigo.
- Manter o tutorial independente das features de simulação.
- Funcionar offline, com o mesmo tema, acessibilidade e navegação do restante do app.

## 3. Não objetivos

- Não ensinar fórmulas, cálculos ou fundamentos de irrigação.
- Não criar um segundo assistente de simulação.
- Não alterar cálculos, persistência, rotas existentes ou telas de projeto.
- Não controlar leitura, progresso ou “tutorial concluído”.
- Não ter busca, CMS, backend ou conteúdo remoto nesta primeira versão.
- Não usar screenshots ou imagens que envelheçam junto com a interface.

## 4. Abordagem escolhida

Conteúdo tipado em Dart, com índice e artigos.

Foram consideradas duas alternativas:

- **Markdown em assets + `flutter_markdown`**: facilita edição textual, mas adiciona dependência, exige sintaxe própria para atalhos e deixa o conteúdo menos testável estruturalmente.
- **Página única com todas as seções**: mais simples, porém ruim para consulta, sem link direto para um assunto e sem atalhos por artigo.

O conteúdo tipado foi escolhido por ser offline, testável, sem dependência nova, integrado ao tema e capaz de usar rotas tipadas nos atalhos.

## 5. Arquitetura

Nova feature:

```text
lib/features/tutorial/
  tutorial.dart
  routes.dart
  models/
    artigo_tutorial.dart
  content/
    manual_operacao.dart
  views/
    tutorial_screen.dart
    artigo_tutorial_screen.dart
```

Fronteiras:

- `tutorial` não importa `views/`, `viewmodels/` ou controllers das features de método.
- `tutorial` pode importar `AppRoutes`, tema/ícones e widgets neutros.
- Nenhuma feature importa `tutorial`, exceto a composição no `app_router`.
- O Perfil conhece apenas a constante de rota, sem importar a feature de tutorial.

## 6. Modelos

```dart
enum CategoriaTutorial { primeirosPassos, metodos, resultados, cenarios, perfil }

final class ArtigoTutorial {
  final String id;
  final String titulo;
  final String resumo;
  final CategoriaTutorial categoria;
  final IconData icone;
  final List<SecaoTutorial> secoes;
  final List<AtalhoTutorial> atalhos;
}

final class SecaoTutorial {
  final String titulo;
  final List<String> paragrafos;
  final List<String> passos;
}

final class AtalhoTutorial {
  final String rotulo;
  final String descricao;
  final String rota;
  final IconData icone;
}
```

Os IDs dos artigos são estáveis e usados na URL.

## 7. Conteúdo inicial

Pelo menos estes artigos, em pt-BR:

| Categoria | Artigo | Atalhos |
|---|---|---|
| Primeiros passos | Visão geral do app | Home |
| Primeiros passos | Como preencher um projeto | Sulcos |
| Métodos | Sulcos | Tipo de sulco, projeto |
| Métodos | Faixas | Projeto de faixas |
| Métodos | Inundação | Projeto, referência |
| Resultados | Como ler e salvar resultados | Cenários |
| Cenários | Salvar, reabrir, comparar e exportar | Cenários |
| Perfil | Perfil e acessibilidade | Perfil |

O conteúdo descreve a operação real da interface: abas, etapas, botões Confirmar/Próximo, revisão, cálculo, resultados e salvamento.

## 8. Rotas

- `/perfil/tutorial` — índice.
- `/perfil/tutorial/:artigoId` — leitura do artigo.

As rotas são filhas de `/perfil`, dentro do mesmo branch do `StatefulShellRoute`, para manter a barra inferior e a aba Perfil selecionada.

`AppRoutes` ganha:

```dart
static const tutorial = '/perfil/tutorial';
```

`perfil/routes.dart` passa a expor `perfilRoute({children})`, espelhando `homeRoute`, para que o composition root monte:

```dart
StatefulShellBranch(routes: [perfilRoute(children: tutorialRoutes)])
```

Assim o Perfil não importa a feature de tutorial.

Artigo inexistente exibe uma tela amigável de “Artigo não encontrado” com ação para voltar ao índice.

## 9. Entrada no Perfil

Um card “Tutorial e ajuda” é adicionado após os cards de estatísticas, antes da seção “Preferências”. Ele tem ícone, título, descrição curta e ação “Abrir tutorial”, que faz `context.push(AppRoutes.tutorial)`.

## 10. Interface

### Índice

- Cabeçalho “Tutorial e ajuda” e subtítulo.
- Artigos agrupados por categoria.
- Cada artigo mostra ícone, título, resumo e seta.
- Sem busca na primeira versão.

### Artigo

- AppBar com voltar e título do artigo.
- Chip da categoria, resumo e seções com parágrafos e passos numerados.
- Bloco final “Ir para” com botões de atalho.
- Os atalhos usam `context.go(rota)` para trocar de branch corretamente e manter a barra inferior.

## 11. Acessibilidade

- Cabeçalhos com `Semantics(header: true)`.
- Cards e atalhos com rótulos e alvos de toque de pelo menos 48 px.
- Layout em uma coluna em telas estreitas (320/390 px).
- Cores, tipografia e escala vindas do tema e das preferências do Perfil.
- Sem animações próprias que ignorem `AppAccessibility.reducedAnimations`.

## 12. Testes

- Conteúdo: IDs únicos, categorias preenchidas, artigos com título/resumo/seções e atalhos com rotas válidas.
- Índice: renderiza categorias/artigos e abre o artigo ao tocar.
- Artigo: renderiza seções, passos e atalhos; atalho navega para a rota esperada.
- Artigo inexistente: mostra o estado de fallback.
- Perfil: o card “Tutorial e ajuda” abre `/perfil/tutorial`.
- Layout estreito e escala de texto ampliada.
- `flutter analyze` e toda a suíte `flutter test` passam.

## 13. Critérios de aceite

- O usuário encontra “Tutorial e ajuda” no Perfil e abre o índice.
- Consegue abrir qualquer artigo, ler o conteúdo e voltar.
- Os atalhos levam à tela real correta, mantendo a barra inferior.
- O tutorial funciona sem internet e sem alterar cálculos ou cenários.
- A feature não cria dependência das telas ou viewmodels das features de método.
