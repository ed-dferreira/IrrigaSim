# Aula 5 — Métodos de irrigação: análise da base comum

Fonte: Aula 5 — Métodos de irrigação(1).pdf, Prof.ª Chaiane Guerra da Conceição, UNIPAMPA. Conferência visual e textual de todas as 31 páginas, incluindo os quadros que não aparecem na extração de texto. A análise abaixo interpreta o material fornecido; não verifica externamente suas faixas de desempenho.

## 1. O papel desta aula no conjunto

Esta é a **base conceitual e de classificação** do conteúdo de irrigação. Ela explica o que distingue os métodos, quais sistemas pertencem a cada grupo, como são operados e quais fatores influenciam a escolha. A Aula 8 aprofunda um dos sistemas apresentados aqui: a inundação, dentro do método por superfície.

A distribuição do conteúdo não é uniforme: as páginas 6–20 detalham aspersão; 21–27 tratam de localizada; 28–29 de subsuperfície; 30 introduz superfície e 31 é apenas uma divisória. Portanto, esta aula é comum como introdução, mas não contém todo o conhecimento comum de cálculo necessário aos módulos específicos.

Não há exercício numérico resolvido, equações de perda de carga, cálculo de demanda hídrica ou algoritmo completo de dimensionamento. Há faixas e percentuais didáticos importantes, que precisam conservar seu contexto.

## 2. Método, sistema e operação

Nas páginas 2 e 5, **método** representa a forma de aplicação da água; **sistema** reúne equipamentos, acessórios, operação e manejo que realizam essa aplicação.

| Nível | Pergunta que responde | Exemplos |
|---|---|---|
| Método | Como a água chega à área/solo? | Superfície, aspersão, localizada, subsuperfície |
| Sistema | Que conjunto e arranjo executam isso? | Inundação, pivô central, convencional portátil, gotejamento |
| Configuração | Como o sistema está instalado? | Tubulações fixas/móveis; gotejamento superficial/enterrado |
| Manejo | Como ele é operado? | Frequência, duração e reposição de água |

Os dois primeiros níveis são explícitos na aula; separar configuração e manejo é uma proposta de organização para o projeto em Dart. Evita colocar, por exemplo, “pivô”, “aspersão” e “alta frequência” como opções equivalentes de uma mesma lista.

## 3. Os quatro métodos

| Método | Princípio apresentado | Sistemas/exemplos | Questões destacadas no material |
|---|---|---|---|
| Superfície | A água se distribui por gravidade e usa o solo como meio de transporte. | Sulcos, faixas, inundação. | Topografia, comportamento da infiltração, sistematização e perdas. |
| Aspersão | Aplicação semelhante à chuva por emissores. | Convencional, pivô, linear, lateral rolante, carretel, montagem direta. | Pressão/energia, vento, intensidade de aplicação e mobilidade. |
| Localizada | Água aplicada em parte da área, perto da zona radicular. | Gotejamento, microaspersão, geotêxteis e exsudantes. | Frequência, área molhada, vazão dos emissores, filtragem e manutenção. |
| Subsuperfície | Aplicação abaixo da superfície e redistribuição no solo. | Gotejo enterrado, elevação do lençol, subirrigação protegida/mesas de capilaridade. | Posição de aplicação e mecanismo de fornecimento de água. |

**Ponto de modelagem:** gotejamento enterrado tem aplicação localizada e posição subsuperficial. Preservar os quatro grupos da aula não exige tratar essas características como mutuamente exclusivas. No Dart, `metodoNaAula`, `posicao` e `aplicacaoLocalizada` estão separados.

A definição estreita da p. 4, centrada em tubos enterrados, não esgota subsuperfície: as páginas 28–29 também incluem controle do lençol e mesas de capilaridade.

## 4. Taxonomia que poderia passar despercebida

A árvore da p. 5 é uma imagem e contém mais sistemas do que o texto extraído revela:

- **Superfície:** sulcos, inundação e faixas.
- **Aspersão convencional:** fixos permanentes, fixos temporários, semifixos e portáteis. Na p. 8, “semi-portátil” descreve principal fixa e laterais móveis.
- **Aspersão mecanizada:** laterais autopropelidas (linear, lateral rolante e pivô), aspersores autopropelidos e montagem direta.
- **Localizada:** microaspersores rotativos, estacionários e artesanais; gotejadores internos, integrados, externos e artesanais; mantas/tapetes capilares, fitas capilares e tubos/mangueiras exsudantes.
- **Subterrânea/subsuperfície:** gotejamento com tubulação, geotêxteis/exsudantes, sistemas artesanais e sistemas mistos de gotejamento/exsudação. KISSS e ECO-MAT aparecem como exemplos na figura, não como recomendação de produtos.

A taxonomia completa está no JSON e no catálogo Dart, com os exemplos adicionais das páginas 15, 28 e 29.

## 5. O que cada bloco acrescenta

### Aspersão (p. 6–20)

A mobilidade define os convencionais: no portátil, todo o conjunto é móvel, inclusive motobomba; no semi-portátil, a principal é fixa; no fixo permanente, a tubulação é fixa; no temporário, permanece fixa durante o ciclo. O esquema da p. 10 distingue linha principal, laterais, aspersores e área irrigada.

Nos mecanizados, o pivô tem deslocamento radial e o linear tem deslocamento linear. A lateral rolante se desloca de forma intermitente. A p. 14 mostra placa estriada fixa, placa estriada tripla oscilante e LEPA sobre a copa ou sobre o solo. A p. 15 mostra tanto canhão quanto barra irrigadora tracionados por carretel. A montagem direta reúne bombeamento móvel e canhão na unidade ou na extremidade de tubulação/mangueira.

O material associa adaptação, automação e flexibilidade à aspersão, mas também relaciona pressão ao gasto energético, intensidade de aplicação ao risco de escoamento e vento/umidade à qualidade da aplicação. Cita efeitos sobre pulverizações, doenças e danos decorrentes de água salina/sedimentos. A altura e o tipo de aspersor precisam ser compatíveis com a cultura.

Os usos adicionais citados são controle de microclima, proteção contra geada, resfriamento evaporativo e aplicação de produtos/fertilizantes via água. A aula apresenta esses usos; não fornece procedimentos operacionais ou doses.

### Localizada (p. 21–27)

O princípio de manejo é **alta frequência e baixo volume**, buscando manter a umidade próxima da capacidade de campo (CC). Isso não define sozinho o tempo de irrigação: ainda faltam demanda, área atendida e vazão efetiva do sistema.

A figura da p. 24 identifica bombeamento, tubulação de recalque, cabeçal de controle, linha principal, derivação, válvulas reguladoras e gotejadores. O cabeçal filtra, regula, mede e protege o sistema; as linhas levam água até os emissores.

Gotejamento: economia potencial de água/energia, aproveitamento de fertilizantes e uniformidade; contrapontos de entupimento, filtragem, qualidade da água, implantação e manutenção. A aula menciona limitação do sistema radicular; isso deve ser registrado como observação qualitativa do manejo e do volume molhado, não como coeficiente fixo de redução das raízes.

Microaspersão: adaptação a declives e formatos, uniformidade e fertirrigação. O material destaca potencial em condições de água cara/escassa, terreno irregular, solo arenoso/pedregoso e culturas de alto valor sensíveis à umidade. Não fornece um ranking quantitativo para decidir entre métodos.

### Subsuperfície e superfície (p. 28–31)

A subsuperfície é ligada à aplicação abaixo do solo, ascensão capilar e diferença de potencial. Exemplos: elevação do lençol em batata, gotejo enterrado em café e mesas de capilaridade em ornamentais.

Na superfície, a variabilidade temporal do solo afeta a lâmina infiltrada. A afirmação da p. 30 sobre dificuldade de previsão precisa deve ser entendida como uma limitação do modelo e da medição. Ela não invalida a estimativa por ensaios e equações apresentada depois na Aula 8.

## 6. Números: guardar referência, página e escopo

| Informação | Valor na aula | Página | Tratamento na base comum |
|---|---|---:|---|
| Eficiência da aspersão no quadro geral | 70–85% | 4 | Tipo de eficiência não especificado. |
| Eficiência de irrigação da aspersão | 80–90% | 19 | Definida como água usada pela cultura / água captada. |
| Eficiência da localizada | 85–95% | 4 | Referência didática, sem garantia para qualquer instalação. |
| Eficiência da subsuperfície | Acima de 90% | 4 | Não estender automaticamente a todo sistema da categoria. |
| Intensidade mínima citada para estacionários | 3 mm/h | 17 | Não tratar como limite universal de equipamentos. |
| Economia possível frente à superfície | 50% | 18 | Economia comparativa, não eficiência de aplicação. |
| Vazão de gotejadores | 2–20 L/h | 23 | Por emissor, não vazão total do projeto. |
| Vazão de microaspersores | 20–150 L/h | 23 | Por emissor; faixa didática. |
| Área molhada em perenes | Máxima 60%; mínimas aproximadas 20% em clima úmido e 30% em árido/semiárido | 23 | Percentual de área; não eficiência e não regra geral para toda cultura. |

As duas faixas de aspersão não devem ser fundidas em uma média. A aula não demonstra que usam o mesmo denominador, condições ou componentes de perda. Na Aula 8 há distinção entre eficiência de condução e aplicação; portanto, “eficiência” sem definição não pode virar uma constante global compartilhada.

## 7. Ambiguidades que não devem virar regras automáticas

| Página | Expressão/questão | Interpretação para o projeto |
|---:|---|---|
| 4 | “Gotejo subterrâneo (superficial)” | Contradição de redação. Preservar nota da fonte e separar posição de aplicação. |
| 11 e 13 | Mecanizados se movimentam enquanto aplicam; lateral rolante é intermitente. | Mobilidade não significa necessariamente deslocamento contínuo. |
| 17 | Laterais móveis associadas à alta frequência. | Adequação também depende de reposicionamento, mão de obra e operação; não tornar uma garantia. |
| 18 | Tubulações podem ser removidas/transportadas. | Característica de alguns arranjos, não de toda instalação fixa. |
| 27 | “Não apresenta escoamento superficial”. | Não usar para dispensar avaliação de intensidade, infiltração e operação. |
| 27 | Fertirrigação em “qualquer dose”. | O slide não fornece limites agronômicos/hidráulicos para justificar uma regra sem restrições. |
| 30 | “Impossível prever, com precisão”. | Registrar incerteza/variabilidade; não impedir cálculos de estimativa. |

Essas são ressalvas de leitura e implementação. Não foi realizada validação agronômica externa para substituir o conteúdo dos slides por recomendações novas.

## 8. Como aproveitar a parte comum no Dart

A separação sugerida é:

| Camada | Conteúdo comum | O que permanece específico |
|---|---|---|
| Catálogo | Métodos, sistemas, descrições e páginas de origem. | Subtipos e componentes de cada sistema. |
| Caracterização da área | Solo, cultura, clima, topografia, água, energia, custos e operação. | Parâmetros adicionais exigidos pelo cálculo escolhido. |
| Referências didáticas | Faixas, unidades, contexto e ambiguidades. | Valores de projeto medidos ou escolhidos com justificativa. |
| Dimensionamento | Convenções de unidades e identificação da origem dos dados. | Equações de inundação, aspersão, localizada etc. |

A lista de caracterização é uma **síntese desta análise**; a Aula 5 não apresenta um formulário obrigatório nem uma função matemática de seleção.

O arquivo `base_comum.dart` é um catálogo importável em Dart/Flutter, com enums de classificação, identificação de um exemplo de sistema e os dados didáticos completos. Não implementa dimensionamento nem escolhe automaticamente o método “melhor”. Para lê-lo isoladamente, com SDK Dart instalado:

```bash
dart run base_comum.dart
```

Ele imprime o catálogo em JSON. Não precisa de Flutter nem pacotes externos. O arquivo não foi compilado/executado neste ambiente por ausência do SDK.

A integração com a Aula 8 deve apontar **superfície → inundação** para as funções já produzidas. Coeficientes de infiltração, bisseção/Newton, tempos de avanço, taipas e volumes V1–V5 ficam no módulo específico. O catálogo comum não deve receber esses parâmetros como se fossem universais.

## 9. Conteúdo entregue

- `Analise_base_comum.md`: análise conceitual, numérica e de integração.
- `Revisao_pagina_por_pagina.md`: conferência individual de 31 páginas.
- `dados_comuns.json`: taxonomia, referências e ambiguidades.
- `base_comum.dart`: representação reutilizável do catálogo.
- `auditoria_por_pagina.json` e `texto_extraido_por_pagina.txt`: rastreabilidade textual.
- `evidencias/`: imagens das 31 páginas.
- `validacao.txt`: verificações realizadas e limites.

Não foram criados perfis de infiltração nem resultados de dimensionamento: esta aula não fornece os dados necessários para esses produtos.
