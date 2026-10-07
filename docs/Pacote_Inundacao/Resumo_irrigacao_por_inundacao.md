# Irrigação por inundação — resumo e referência em Dart

Revisão 2: conferência visual das 84 páginas; omissões da primeira entrega recuperadas nas seções 8 e 9.

Fonte: Aula 8 — Irrigação por Inundação, Prof.ª Chaiane Guerra da Conceição, UNIPAMPA, 84 páginas. Os números de página abaixo correspondem à numeração do PDF.

## 1. Conceito e condições de uso (p. 2–8)

A água é conduzida pela superfície do solo por gravidade e retida em bacias ou tabuleiros delimitados por diques ou taipas. O sistema estabelece uma lâmina de água sobre o terreno.

Exige solos de textura média a fina, terreno com declividade uniforme inferior a 2% e culturas compatíveis com o manejo do excesso hídrico. O nivelamento é essencial para distribuir a água de forma uniforme.

**Vantagens:** economia de energia, aproveitamento da chuva, controle de plantas daninhas e da temperatura do solo, custos fixos e operacionais geralmente baixos.

**Limitações:** consumo elevado de água, restrições de terreno e cultura, custo de sistematização e perda de área útil com taipas e canais.

## 2. Modalidades (p. 9–12)

| Modalidade | Funcionamento | Aplicação destacada na aula |
|---|---|---|
| Intermitente | Aplica água até suprir o solo na zona radicular; a água infiltra ou é drenada. Nova irrigação quando a umidade chega ao limite inferior da cultura. | Também chamada de “dar banho”; a aula mostra frutíferas. |
| Contínua | Mantém lâmina durante parte do ciclo, desde alguns dias após a semeadura até antes da colheita. | Arroz, tolerante ao encharcamento. |
| Contínua com circulação | Entrada e saída permanentes de água. | Reposição e circulação entre quadros. |
| Contínua sem circulação | Entrada controlada, sem saída planejada do tabuleiro. | Retenção da água aplicada. |

## 3. Estrutura, geometria e implantação (p. 13–41)

Componentes: reservatório e motobomba, tabuleiros, taipas, canais de irrigação e drenagem, comportas ou sifões.

O tamanho dos tabuleiros depende do solo, topografia, vazão e prática local. A aula menciona desde 1 m² até mais de 5 ha. Subsolo menos permeável permite tabuleiros maiores.

Na inundação contínua, a diferença de elevação admissível é limitada a **2/3 da lâmina média**. No exemplo da p. 20, lâmina de 15 cm permite desnível de 10 cm. Dividindo esse desnível por 0,25% e 0,05%, obtêm-se limites de 40 m e 200 m, respectivamente, considerados separadamente em cada direção. Se os dois declives se acumularem entre cantos opostos, deve-se conferir o desnível total: adotar ambos os limites simultaneamente resultaria em 20 cm.

- **Retangulares:** diques retilíneos; normalmente exigem sistematização.
- **Em contorno:** diques acompanhando curvas de nível; tendem a demandar menor movimentação de terra. Podem ser paralelos ou seguir exatamente cada curva.
- **Alimentação individual:** entrada e drenagem próprias por tabuleiro.
- **Em sequência:** água passa de um tabuleiro a outro; a aula associa esse arranjo à inundação contínua.

A aula indica margem livre de 5–20 cm acima da água, base da taipa de 60–180 cm e altura de 60–80 cm. São valores citados no material, não uma dimensão calculada para os exemplos.

Preparo do solo: convencional, plantio direto e pré-germinado. No pré-germinado, a semeadura ocorre no lodo; a aula orienta drenagem após o preparo e posterior retomada da irrigação.

## 4. Inundação intermitente: cálculo (p. 42–63)

Consideram-se tabuleiros regulares, praticamente nivelados, avanço em uma direção e superfície da água horizontal após o corte. A depleção é relevante; a recessão é praticamente inexistente. O projeto procura garantir a irrigação real necessária (IRN) no final da área.

### Unidades e equações implementadas

Tempo `t` em minutos; distâncias e lâminas em metros; `Q0` em m³/(min·m), vazão por metro de largura; `VIB` em m/min; `Vmax` em m/min. `n` é o coeficiente de Manning.

```text
I(t) = k t^a + VIB t
Q0max = [Vmax^(13/3) n² L / 3600]^(3/7)
y0 = [Q0² n² L / 3600]^(3/13)
sigmaZ = [a + r(1-a) + 1] / [(1+a)(1+r)]
Q0 ta = 0,77 A0 L + sigmaZ k ta^a L + VIB ta L/(1+r)
r = ln(2) / ln(ta(L)/ta(L/2))
ti = max[ta, (IRN - 0,80 y0)L/Q0 + ta]
Ea = 100 IRN L/(Q0 ti)
```

Para o escoamento por unidade de largura, `A0` tem valor numérico igual à profundidade calculada na entrada. O slide 46 usa expoente arredondado 0,23; o código adota 3/13, apresentado no slide 58, de forma consistente.

A aula resolve o balanço por Newton-Raphson. A rotina principal usa **bisseção** na mesma equação e atualização iterativa de `r`, com limites de iteração e verificação de vazão insuficiente. Essa mudança numérica está documentada; a revisão também inclui `tempoNaDistanciaNewton` como alternativa, descrita na seção 8.

### Dados do exemplo (p. 63)

| Parâmetro | Primeira irrigação | Terceira irrigação |
|---|---:|---:|
| k | 0,0035 | 0,0034 |
| a | 0,47 | 0,45 |
| VIB (m/min) | 0,00011 | 0,00010 |

Área: 200 × 400 m = 8 ha; comprimento de avanço: 200 m; declividade zero; `n = 0,040`; IRN = 56 mm; ET = 8 mm/dia; Vmax = 8 m/min; vazão disponível = 400 L/s a cada sete dias. O slide também fornece rho1 = 1 e rho2 = 3,33, preservados no JSON, sem uso neste modelo de bacia por unidade de largura.

**Ajuste de unidade:** o slide rotula I como m³/min; nas equações de infiltração utilizadas, I precisa representar lâmina em metros. Essa interpretação dimensional é explicitada no código.

### Resultados de referência com Q0 = Q0max

| Resultado | Primeira | Terceira |
|---|---:|---:|
| Q0 (m³/min/m) | 0,872889 | 0,872889 |
| y0 (m) | 0,109111 | 0,109111 |
| Tempo de avanço (min) | 22,029325 | 21,795724 |
| Tempo de irrigação (min) | 22,029325 | 21,795724 |
| Eficiência de aplicação (%) | 58,244903 | 58,869158 |

Nesses casos o armazenamento superficial já excede a IRN ao término do avanço; aplica-se a regra `ti = ta`. **Não são resultados de vazão ótima.** A aula recomenda repetir a simulação variando a vazão para maximizar a eficiência, além de verificar a altura dos diques.

Para a operação em parcelas (p. 61–62), o material relaciona largura do tabuleiro, número de tabuleiros, área por parcela, jornada diária e tempo de mudança. A rotina `parcelas`, acrescentada na revisão, permite calcular esse planejamento quando forem fornecidos jornada diária, tempo de mudança e número de tabuleiros simultâneos. O exemplo original não fixa essas escolhas. Vazão por largura não deve ser confundida com os 400 L/s totais disponíveis.

Os CSVs representam **perfis simulados**, não medições extraídas do PDF. Usam `tx = ta (x/L)^(1/r)` e lâmina final `I(ta-tx) + 0,80 y0 + Q0(ti-ta)/L`. O perfil aproxima a lei de avanço e não integra exatamente os fatores empíricos do balanço.

## 5. Inundação contínua: cálculo (p. 64–73)

O enchimento deve saturar o solo, formar a lâmina superficial e compensar evapotranspiração e percolação. Depois, a manutenção repõe essas duas perdas.

```text
TR = DTA f Z / ETc
Qe = 0,116 [porosidade Z + Lm + (ETpc + K0)TR] A/TR
Qm = 0,116 (ETpc + K0) A
Ec = 100 Qm/Qd
Ea = 100 Les/Las
Las = 3600 Qm ti/A
```

**Atenção às unidades:** em TR, DTA é mm/cm e Z é cm. Em Qe, Z e Lm são mm; A é ha; TR é dias; ETpc e K0 são mm/dia; Qe e Qm saem em L/s. Em Las, Qm é L/s, ti é horas e A é m². O fator 0,116 é o arredondamento adotado na aula.

No exemplo da p. 73: área 20 ha; DTA 2 mm/cm; porosidade 0,50; Z 50 cm; K0 7 mm/dia; ET 7,2 mm/dia; Lm 150 mm; f 0,5. Resultados: **TR = 6,944444 dias; Qe = 166,576 L/s; Qm = 32,944 L/s**.

## 6. Arroz: volumes de água (p. 74–84)

```text
PT = 1 - Ds/Dp
Us = PT/Ds
V1 = (Us - Ua) PCI 10000 Ds         [saturação]
V2 = h1 10000                       [formação da lâmina]
V3 = h2 PI 10000                    [evaporação]
V4 = Ksat (h1 + PCI)/PCI PI 10000   [infiltração]
V5 = 0,4 MS_total                   [transpiração/formação de matéria seca]
VT = V1 + V2 + V3 + V4 + V5
Q1 = (V1 + V2) A/(Td 86400)
Q2 = (V3 + V4 + V5) A/(Tr 86400)
```

Volumes em m³/ha; alturas e PCI em m; h2 e Ksat em m/dia; PI, Td e Tr em dias; MS_total em kg/ha; área em ha. **Q1 e Q2 saem em m³/s**, e não L/s. Na fórmula de V1, Us e Ua são umidades gravimétricas, consistentes com o fator Ds. O coeficiente 0,4 é o valor fornecido pela aula.

O exercício da p. 84 informa Ds = 1,25 g/cm³; Dp = 2,65 g/cm³; PCI = 0,60 m; lâmina = 0,07 m; Ksat = 0,0006 m/dia; evaporação de tanque = 0,008 m/dia; período = 100 dias; produtividade = 435,6 sacos/ha, com 13% de umidade; índice de colheita = 40%.

Faltam **Ua, massa de cada saco, área e tempos de formação/manutenção** para obter uma solução única completa. A matéria seca dos grãos seria `435,6 × massa_saco × 0,87`; a matéria seca total seria esse resultado dividido por 0,40. Não se assume solo inicialmente seco nem massa do saco sem confirmação. A evaporação de tanque é preservada como dado informado; o material não fornece coeficiente de ajuste.

## 7. Conteúdo da pasta e execução

| Arquivo | Finalidade |
|---|---|
| Resumo_irrigacao_por_inundacao.md | Este resumo, equações e ressalvas de interpretação. |
| dados_extraidos.json | Dados dos exemplos, unidades e páginas de origem. |
| nucleo_referencia.dart | Funções de infiltração, avanço, irrigação contínua e volumes. |
| testar_referencia.dart | Testes com valores esperados e entradas inválidas. |
| resultados_referencia.json | Referências calculadas independentemente; não geradas por execução Dart. |
| perfil_primeira.csv / perfil_terceira.csv | Perfis simulados da lâmina infiltrada. |
| texto_extraido_por_pagina.txt | Extração textual por página; fórmulas em imagem podem estar ausentes. |
| evidencias/ | Imagens das principais equações consultadas. |
| validacao.txt | O que foi conferido e o que permanece sem execução. |

Com o Dart SDK instalado, entre na pasta extraída e execute:

```bash
dart run nucleo_referencia.dart
dart run testar_referencia.dart
```

O programa imprime os resultados em JSON. Não precisa de Flutter nem de pacotes externos. O SDK Dart não está disponível no ambiente de criação; os testes foram preparados, mas não executados em Dart. Os números foram verificados por cálculo independente, com conferência do resíduo do balanço volumétrico.

## 8. Complementos da revisão integral

### Guia de tamanho e relação de Henderson (p. 15–17)

Na inundação permanente, a área atendida por unidade de vazão pode ser maior do que na intermitente. A tabela da p. 16 foi omitida na primeira versão:

| Solo | Área sugerida para cada 10 L/s |
|---|---:|
| Arenoso | 0,01 ha |
| Franco-arenoso | 0,02 ha |
| Franco-argiloso | 0,03 ha |
| Argiloso | 0,04 ha |

A p. 17 fornece **A = 100 Q/VIB**, com A em m², Q em m³/h e VIB em mm/h. É uma relação empírica atribuída a Henderson (1965) no slide. O fator 100 foi preservado exatamente; não se deve substituí-lo automaticamente pelo fator de conversão volumétrica 1000. No Dart: `areaGuiaSolo` e `areaHenderson`.

### Detalhes conceituais e construtivos omitidos

- P. 5: inundar também permite conferir o nivelamento e orientar o acabamento do tabuleiro.
- P. 7: a aula inclui, entre as vantagens, maior eficiência dos herbicidas quando a água entra cedo na lavoura.
- P. 9: CC significa **capacidade de campo**; é a condição de umidade visada na zona radicular nesse manejo intermitente.
- P. 21: o arranjo com alimentação/drenagem individuais é associado a terreno plano ou pouco inclinado, em manejo contínuo ou intermitente; seus tabuleiros tendem a ser maiores que os do arranjo em sequência.
- P. 22–27: as setas mostram a diferença entre abastecer cada quadro separadamente e fazer a água passar de um quadro a outro. As áreas de 0,75/0,80 ha (p. 22) e 0,32 ha (p. 25) e cotas 100,60/100,90 (p. 27) pertencem às figuras ilustrativas, não aos exercícios posteriores.
- P. 28–32: diques em contorno são fechados por diques transversais retilíneos. Diques paralelos facilitam mecanização, mas exigem sistematização; diques que seguem exatamente o relevo têm espaçamento variável. Em áreas planas de arroz no Sul, o pranchão destorroador pode bastar para uniformizar a superfície, conforme a aula.
- P. 33: há uma variante com **transbordamento de canais em contorno**, que substituem os diques nesse arranjo.
- P. 34–35: nivelar por cortes/aterros ou pranchão com lâmina; a figura traz `Lm = (Li + Lf)/2` e `Z <= 2 Lm/3`. Esse Z é o desnível local da figura, e não a profundidade do solo usada na seção contínua.
- P. 36 e 74: o diagrama distingue entrada de irrigação, armazenamento na lâmina/solo, evapotranspiração e fluxos horizontal e vertical. A seta `Es` aparece saindo por cima da taipa; sua leitura como escoamento superficial é uma interpretação do desenho, pois a sigla não é definida no slide.
- P. 37: fotos ilustram implementos e máquinas de construção/acabamento de taipas e movimentação de terra.
- P. 39: convencional = aração → semeadura → aplicação de água.
- P. 40: direto = dessecação → semeadura → aplicação de água.
- P. 41: no pré-germinado, a aula indica drenagem preferencialmente **2–3 dias após o preparo do solo**; retoma-se a irrigação alguns dias depois.
- P. 66: levantamento do perfil do solo e determinação da condutividade hidráulica são indispensáveis ao dimensionamento apresentado.
- P. 71: eficiência de condução é especialmente relevante quando há bombeamento, escassez de água ou grande distância entre captação e lavoura.

### Tabela de vazão dos sifões/tubos — Booher (p. 38)

Vazões em **L/s**. Diâmetros e cargas hidráulicas em **cm**. A legenda do slide se refere a derivação de água em irrigação por faixa, embora a tabela esteja inserida nesta aula de inundação.

| Diâmetro | Carga 5 | 7,5 | 10 | 12,5 | 15 | 20 | 25 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 4,7 | 5,7 | 6,6 | 7,4 | 8,1 | 9,3 | 10,4 |
| 12,5 | 7,3 | 8,9 | 10,3 | 11,5 | 12,6 | 14,6 | 16,3 |
| 15 | 10,5 | 12,9 | 14,9 | 16,6 | 18,2 | 21 | 23,5 |
| 20 | 18,7 | 22,9 | 26,4 | 29,5 | 32,3 | 37,3 | 41,8 |
| 25 | 29,2 | 35,7 | 41,3 | 46,1 | 50,5 | 58,4 | 65,2 |
| 30 | 42 | **31,5*** | **39,4*** | 66,4 | 72,8 | 84,0 | 94,0 |
| 35 | 57,2 | 70 | 80,9 | 90,4 | 99,1 | 114,4 | 127,9 |

(*) **Valores literais do PDF, suspeitos.** Nessa linha, a vazão diminui quando a carga passa de 5 para 7,5 cm; os valores de 7,5 e 10 cm também ficam abaixo dos correspondentes ao diâmetro de 25 cm. A revisão não substitui esses números por estimativas. A tabela completa, com marcação dessas células, está no JSON e a imagem original em `evidencias/pagina_38.png`.

### Equações do intermitente que precisavam de explicação (p. 43–59)

A declividade do solo é praticamente nula, mas a **superfície da água** tem gradiente durante o avanço. A p. 45 escreve `S0 = Sf = y0/X`; nesse contexto a expressão é usada para a superfície líquida, sem mudar a hipótese de solo nivelado.

A infiltração final no início da bacia (p. 47–50) é:

```text
I0 = k ta^a + VIB ta + 0,80 y0 + Q0(ti-ta)/L
```

Os dois primeiros termos representam a infiltração durante o avanço; o terceiro, a lâmina superficial média; o último, a água aplicada depois do avanço. O slide 51 usa o ponto final, onde o tempo de oportunidade durante o avanço é zero, para calcular ti a partir da IRN. Sua frase “a equação 4 pode ser aplicada” é uma referência interna imprecisa, pois a equação 4 é a própria expressão que está sendo obtida.

O procedimento de Newton da p. 57, agora também disponível em `tempoNaDistanciaNewton`, é:

```text
t_inicial = 5 A0 L/Q0
F(t) = Q0 t - 0,77 A0 L - sigmaZ k t^a L - VIB t L/(1+r)
F'(t) = Q0 - sigmaZ a k L/t^(1-a) - VIB L/(1+r)
corr = F(t)/F'(t)
t_novo = t - corr
```

Começa-se com `r` entre 0,5 e 0,9, por exemplo 0,7. Calculam-se os tempos em L e L/2, recalculando A0 com X=L/2 em solo nivelado; atualiza-se r até estabilizar. Algumas referências aos números de equação na p. 58 estão deslocadas: a equação de A0 exibida ali é a **12**. A implementação principal mantém bisseção; a alternativa Newton retorna erro se sair do domínio ou não convergir.

`selecionarMelhorVazao` agora compara uma lista explícita de candidatos, verifica vazão não erosiva e altura do dique com margem. Ela retorna o melhor candidato viável da lista, **não uma garantia de ótimo global**. Não substitui a verificação posterior da vazão total disponível e da operação das parcelas.

### Parcelas e operação (p. 61–62)

Estas seis relações estavam apenas mencionadas na primeira versão:

```text
W0 = APP/(NTP L)        largura do tabuleiro
NTT = NTP NPD PI        número total de tabuleiros
Q = W0 NTP Q0          vazão total
TPP = ti + tm          tempo por parcela, incluindo mudança
NPD = TDF/TPP          parcelas por dia
APP = Atotal/(NPD PI)  área por parcela
```

APP e Atotal em m²; W0 e L em m; Q0 em m³/(min·m); Q em m³/min. Converter Q para L/s multiplicando por 1000/60. Usar a mesma unidade de tempo em ti, tm, TPP e TDF.

**Notação da fonte:** a p. 61 chama L de “largura”, mas o conjunto de equações e o exemplo anterior usam L como comprimento de avanço. No código, o argumento chama-se `comprimentoM`, preservando a identidade geométrica `APP = NTP × largura × comprimento`. A p. 62 usa PI e menciona período de um dia sem defini-lo suficientemente. Na rotina `parcelas`, PI é explicitamente fornecido como número de dias para atender a área; não se presume que sejam os 100 dias de cultivo do arroz.

A rotina retorna NPD teórico e adota a parte inteira inferior para o planejamento, de modo que parcelas completas caibam na jornada. Esse arredondamento é uma decisão de implementação, não uma regra escrita na fórmula do slide. Ainda é preciso conferir a vazão disponível e se a geometria calculada cabe na área.

### Umidades: diferença crucial na p. 76

O desenho apresenta **valores volumétricos ilustrativos**: saturação 0,50, capacidade de campo 0,35, umidade atual 0,25 e ponto de murcha permanente 0,15 cm³/cm³. Já `Us = PT/Ds` e a multiplicação por Ds na fórmula de V1 exigem usar Us e Ua como **umidades gravimétricas**.

Com densidade da água aproximada de 1 g/cm³:

```text
Ua_gravimétrica = umidade_volumétrica/Ds
V1 = (PT - umidade_volumétrica_inicial) PCI 10000
```

A segunda expressão é equivalente à fórmula gravimétrica do slide. **Não se deve inserir 0,25 volumétrico diretamente no parâmetro gravimétrico Ua.** Os valores da ilustração não são automaticamente dados do exercício da p. 84; inclusive a porosidade calculada com as densidades desse exercício é aproximadamente 0,5283, diferente dos 0,50 ilustrativos.

### Solução parcial que já é possível na p. 84

Sem inventar os dados ausentes, obtêm-se:

| Grandeza | Resultado |
|---|---:|
| Porosidade PT | 0,528301887 |
| Us gravimétrica | 0,422641509 |
| V1 | `3169,811321 − 7500 Ua` m³/ha, Ua gravimétrica |
| V2 | 700 m³/ha |
| V3 | 8000 m³/ha, usando os 8 mm/dia informados diretamente como h2 |
| V4 | 670 m³/ha |
| MS total | `947,43 × massa_saco_kg` kg/ha |
| V5 | `378,972 × massa_saco_kg` m³/ha |

V3 usa a evaporação de tanque diretamente como no modelo da aula; não foi aplicado um coeficiente de tanque ausente do enunciado. V1, V5, VT, Q1 e Q2 ainda dependem dos dados que faltam. `Tr` da p. 83 significa **tempo restante disponível**, enquanto `TR` da p. 67 significa **turno de rega**: não tratá-los como a mesma variável por causa da grafia parecida.

## 9. Como conferir esta revisão

- `Revisao_pagina_por_pagina.md`: registro individual das 84 páginas e ação tomada.
- `auditoria_por_pagina.json`: mesmo registro, texto extraído e caminho da imagem de cada página.
- `evidencias/pagina_01.png` até `pagina_84.png`: todas as páginas renderizadas, incluindo figuras e tabelas.
- `dados_extraidos.json`: exemplos, duas tabelas, relação de Henderson e avisos de unidade/notação.
- `nucleo_referencia.dart`: funções ampliadas para os conteúdos recuperados.
- `testar_referencia.dart`: testes ampliados; execução Dart ainda não realizada por ausência do SDK.

A revisão cobre as 84 páginas do PDF. Isso não equivale a afirmar que todo detalhe da fonte está correto ou que o código foi compilado: os pontos suspeitos, as interpretações e os limites de validação estão indicados.
