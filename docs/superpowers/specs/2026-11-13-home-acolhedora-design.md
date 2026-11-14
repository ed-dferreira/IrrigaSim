# Home acolhedora — desenho

Data: 2026-11-13

## 1. Intenção

Deixar a tela inicial mais agradável e autoexplicativa, mantendo os três
métodos (Sulcos, Faixas e Inundação) como ação principal. A home deve dizer,
em linguagem simples, o que o IrrigaSim faz e como escolher entre os métodos.
O botão de tema sai da home, pois a preferência já existe em Perfil.

## 2. Objetivos

- Cabeçalho (hero) com gradiente suave da paleta, saudação e explicação do app.
- Faixa "Como escolher" com um critério curto para cada método.
- Cartões refinados, com uma frase "Ideal para..." e hierarquia visual clara.
- Layout responsivo (1, 2 ou 3 colunas), acessível e sem dependências novas.
- Manter a navegação e as rotas atuais intactas.

## 3. Não objetivos

- Não adicionar cenários recentes, estatísticas, tutorial ou novos atalhos.
- Não alterar cálculos, persistência, tema, rotas ou telas de projeto.
- Não criar imagens ou ilustrações externas.
- Não redesenhar outras telas além da remoção do botão de tema da home.

## 4. Anti-objetivos

- Home sobrecarregada no celular; o hero precisa ser compacto.
- Texto explicativo longo ou didático demais.
- Contraste ruim nos temas claro e escuro.

## 5. Abordagens consideradas

1. **Hero + cartões refinados (escolhida)** — mais acolhedor e responde às duas
   dúvidas (o que é o app e como escolher); custa alguma altura no celular.
2. **Bloco "Como escolher" compacto** — mais econômico em espaço, porém com
   menos impacto visual.
3. **Explicação diluída nos cartões** — mínimo e limpo, mas a explicação geral
   fica pouco visível.

A opção 1 foi escolhida por combinar identidade visual com orientação prática.

## 6. Desenho

### Estrutura

- `Scaffold` + `SafeArea` + rolagem, com largura máxima de 1080 e padding
  horizontal de 16 (celular) ou 28 (telas largas), como hoje.

### Hero

- `Card` com gradiente de `primaryContainer` para `secondaryContainer`,
  cantos de 24 e padding interno de 24–28 (14 em retrato).
- Ícone de gota em um tile `primary`/`onPrimary` (decorativo).
- Saudação "Olá, {primeiro nome}" em `headlineSmall` com peso 700.
- Explicação: "Simule irrigação por superfície, compare o desempenho e planeje
  antes de ir a campo." Em retrato, usa a versão curta "Simule irrigação por
  superfície e planeje antes de ir a campo."
- Painel "Como escolher":
  - Sulcos — culturas em linha;
  - Faixas — terreno inclinado;
  - Inundação — talhões nivelados.
  - Em paisagem, o guia fica dentro do hero (coluna lateral em telas largas,
    abaixo do texto em telas médias).
  - Em retrato, o hero mostra apenas saudação e explicação; o guia desce para
    logo acima dos cartões, em uma linha compacta por método.
  - Cada item tem ícone do método, título curto e critério em texto secundário.

### Métodos

- Título "Escolha o método" e subtítulo "Acesse diretamente a configuração do
  seu projeto."
- Três cartões com os tons atuais (`primaryContainer`, `secondaryContainer`,
  `tertiaryContainer`), ícone, título, descrição curta e uma linha
  "Ideal para..." em destaque suave.
- A seta no topo direito e o `InkWell` continuam indicando que o cartão é
  clicável; as rotas permanecem as mesmas.
- Em paisagem: grade com 3 colunas a partir de 840 px, 2 a partir de 520 px e
  1 abaixo disso. Os três cartões compartilham a mesma altura, com a etiqueta
  "Ideal para..." alinhada na base.
- Em retrato: sempre 1 coluna, com o cartão em layout horizontal compacto
  (ícone à esquerda; título, descrição e "Ideal para..." à direita).

### Tema

- Remover o `IconButton` de tema e o `watch` de `temaEscuro` da home.
- Nenhuma tela nova é necessária: o switch "Tema escuro" já está em
  Perfil → Preferências.

### Textos dos cartões

- Sulcos — "Água conduzida em canais entre as linhas de cultivo."
  Ideal para culturas em linha.
- Faixas — "Lâmina contínua aplicada em faixas do terreno."
  Ideal para terrenos inclinados.
- Inundação — "Alagamento controlado em talhões nivelados."
  Ideal para áreas niveladas.

### Acessibilidade

- Saudação com `Semantics(header: true)`.
- Ícones decorativos excluídos da árvore semântica.
- Manter o rótulo atual dos cartões ("{título}. {descrição}. Iniciar simulação.")
  e adicionar o critério "Ideal para" ao rótulo.

## 7. Critérios de aceite

- A home exibe o hero com explicação do app e a faixa "Como escolher".
- Os três cartões continuam abrindo as rotas atuais.
- O botão de tema não aparece mais na home; o tema continua alterável em Perfil.
- Layout sem overflow em 360 px, 600 px e 1080 px.
- `flutter analyze` e `flutter test` passam.

## 8. Verificação

- Estender o teste de widget da home para conferir a explicação, o critério de
  cada método e a ausência do botão de tema.
- Rodar o teste existente de navegação por Faixas.
