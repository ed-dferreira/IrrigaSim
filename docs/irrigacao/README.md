# Base técnica dos métodos de irrigação

Esta pasta concentra o conteúdo essencial dos materiais enviados para orientar a refatoração dos métodos de irrigação do IrrigaSim. A documentação separa conceitos agronômicos, equações, entradas, saídas e decisões de implementação.

## Escopo

O conjunto recebido cobre quatro métodos gerais de irrigação e detalha três sistemas por superfície usados pela aplicação:

- irrigação por sulcos;
- irrigação por faixas;
- irrigação por inundação intermitente;
- irrigação por inundação permanente ou contínua.

Aspersão, irrigação localizada e irrigação subsuperficial aparecem apenas como panorama geral. Não há material de dimensionamento suficiente para implementá-las nesta etapa.

## Como navegar

- [Fundamentos da irrigação por superfície](fundamentos-superficie.md): conceitos compartilhados, fases e modelo de infiltração.
- [Irrigação por sulcos](sulcos.md): condições de uso, entradas, cálculos e indicadores.
- [Irrigação por faixas](faixas.md): geometria, avanço, depleção, recessão e seleção de vazão.
- [Irrigação por inundação](inundacao.md): separação entre os modelos intermitente e permanente.
- [Modelo de domínio e plano de refatoração](modelo-de-dominio-e-refatoracao.md): tradução do conteúdo para entidades, serviços, validações e testes.
- [Fontes, duplicidades e ressalvas](fontes-e-ressalvas.md): rastreabilidade e problemas encontrados nos exemplos.

## Conclusões para o produto

1. O usuário deve escolher primeiro o método e, no caso de inundação, o regime intermitente ou permanente.
2. Cada fluxo deve solicitar apenas os dados usados por seu modelo. Um formulário único produz campos ambíguos e conversões frágeis.
3. As unidades devem ser explícitas na entrada, normalizadas antes do cálculo e apresentadas novamente na saída.
4. Os métodos iterativos precisam informar convergência, número de iterações e motivo de falha.
5. A escolha de vazão não deve retornar somente um cenário. O sistema deve comparar candidatos válidos e justificar o recomendado.
6. Resultados fisicamente impossíveis, como eficiência acima de 100% ou perda negativa, devem invalidar o cenário em vez de serem exibidos como normais.

## Vocabulário mínimo

| Símbolo | Significado | Unidade de referência |
| --- | --- | --- |
| `IRN` ou `LL` | irrigação real necessária ou lâmina líquida necessária | mm ou m, conforme o cálculo |
| `ta` | tempo de avanço | min |
| `to` | tempo de oportunidade de infiltração | min |
| `ti` | tempo de aplicação ou irrigação | min |
| `td` | instante final da depleção | min |
| `tr` | instante final da recessão | min |
| `Q0` | vazão de entrada por sulco ou por unidade de largura | L/s ou m³/min/m |
| `Qt` | vazão total do projeto | L/s |
| `Ea` | eficiência de aplicação | % |
| `Ed` | eficiência de distribuição | % |
| `Ec` | eficiência de condução | % |
| `GA` | grau de adequação | % |
| `Pp` | perda por percolação profunda | % |
| `Pe` | perda por escoamento superficial | % |

