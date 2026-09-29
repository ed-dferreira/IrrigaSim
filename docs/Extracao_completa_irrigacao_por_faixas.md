# Irrigação por faixas: extração técnica e especificação para simulador

Fonte única: **Aula 7 - Irrigação por faixas.pdf**, 73 páginas, Universidade Federal do Pampa, Prof.ª Chaiane Guerra da Conceição. As páginas citadas são as páginas físicas do PDF e coincidem com a numeração dos slides. Extração realizada em 29/09/2026 com leitura do texto e inspeção visual das páginas, incluindo tabelas e equações inseridas como imagens.

## 1. Como usar este material

Este documento reúne conceitos, tipos, números, tabelas, fórmulas, procedimentos, o exemplo de projeto e requisitos aproveitáveis no aplicativo. Distingue três níveis:

- **PDF:** conteúdo efetivamente apresentado na aula.
- **Derivação:** conversão de unidade, rearranjo algébrico ou cálculo feito aqui a partir do PDF.
- **Proposta de implementação:** decisões necessárias para transformar o material em software; não são regras explicitamente fornecidas pela aula.

As correções propostas são identificadas. Nenhum número suspeito foi silenciosamente substituído. Não houve consulta a fontes externas: isto é uma extração e auditoria interna do documento, não uma confirmação bibliográfica das equações empíricas.

**Limite decisivo:** o PDF fornece uma metodologia de dimensionamento por balanço volumétrico e recessão aproximada. Não fornece um solucionador hidrodinâmico completo nem algoritmos suficientes para todos os tipos que menciona. O exemplo da p.73 contém somente entradas e a chamada “PLANILHA EXCEL!”. O PDF em si não traz a planilha nem um gabarito; há duas planilhas de faixas em `docs/materiais_origem/`, ainda não auditadas nesta extração. Não assumir que correspondem ao gabarito sem comparar origem, fórmulas e unidades.

## 2. Conceitos, tipos e componentes

### 2.1 Método e geometria [pp.2–11, 27, 49]

Aplicação de água ao solo em faixas delimitadas por diques paralelos. A declividade transversal é pequena ou nula; a longitudinal orienta o movimento. O escoamento é aproximado por canal de grande largura, com seção retangular e largura unitária nos cálculos.

A velocidade de avanço depende de largura, comprimento, vazão aplicada, declividade, resistência da cobertura vegetal e capacidade de infiltração do solo. A eficiência varia com a infiltração e o manejo. A infiltração durante a recessão deve ser considerada; as fases de depleção e recessão são relevantes, diferentemente da simplificação que às vezes se faz em sulcos.

| Classificação | Tipos presentes no PDF | Uso possível no aplicativo |
|---|---|---|
| Condição de jusante | Faixa aberta; faixa fechada com dique | Entrada categórica; habilitar apenas modelos compatíveis |
| Dimensionamento/manejo | Escoamento livre; redução de vazão; reuso do escoamento superficial | O algoritmo desenvolvido é o de escoamento livre |
| Diques/taipas | Temporários; permanentes | Cadastro construtivo e verificação da altura |
| Distribuição/controle | Comportas, tubos, sifões, válvulas; canais | Seleção do dispositivo; tabela de sifões/tubos |
| Estruturas destacadas | Comportas retangulares, sifões de grande diâmetro, tubos horizontais atravessando a parede do canal | Componentes de uma planta esquemática |
| Solo na tabela de Marr | Textura muito fina; fina; média | Recomendações tabuladas, não calibração de infiltração |
| Cobertura | Total; não total | Fator 2 na expressão de Hart apresentada |
| Condição de infiltração do exemplo | Primeira irrigação; terceira irrigação | Cenários distintos; não misturar coeficientes |
| Relevo no algoritmo | Em declive; em nível, apenas na fórmula especial de avanço | A recessão apresentada exige declive positivo |

O infográfico da p.10 lista cobertura total do solo, “pastagens, alfafa, fileiras”, projetos ≥4 ha, vazões grandes, sistematização/nivelamento e solos de textura média. A expressão “fileiras” é genérica e não demonstra cobertura total. O valor ≥4 ha é orientação do infográfico, não limitação matemática. A tabela da p.20 também inclui solos finos e muito finos; portanto, não se deve restringir o aplicativo a textura média.

As figuras mostram canal principal/secundário, derivação por sifões ou tomadas, diques, sentido de irrigação, saída de água, área radicular, frente de molhamento, percolação e escoamento. Na p.7 há a indicação ilustrativa de **faixas com 12 m de largura**. Fotografias não fornecem coeficientes numéricos adicionais confiáveis.

### 2.2 Diques [p.23]

| Ilustração | Tipo | Base ilustrada |
|---|---|---:|
| A | Temporário | 0,60 m |
| B | Permanente | 1,20 m |
| C | Permanente | 1,00 m |

O slide associa os permanentes a maior base/estabilidade e maior consumo de material/durabilidade. **As medidas são bases, não alturas.** Não há altura, talude, largura de crista, volume de terra ou borda livre especificados. Não usar essas bases para validar `y0 ≤ altura_dique`.

## 3. Critérios geométricos e manejo

| Critério extraído | Valor/condição | Página | Tratamento no aplicativo |
|---|---|---:|---|
| Declividade longitudinal | Em geral 0,2% a 6% | 12 | Aviso orientativo; não bloqueio absoluto |
| Perfil longitudinal | Uniforme ou decrescente no final | 12 | Entrada de perfil; modelo simples assume declive único |
| Trecho final plano | Últimos 30 a 50 m podem ser planos para acumular água e reduzir saída | 12 | Requer modelo por trechos; não simulado pelo declive único |
| Declividade transversal | Idealmente zero | 13 | Entrada com unidade explícita |
| Desnível transversal | Aproximadamente ≤2/5 da lâmina normal | 13 | Verificação geométrica |
| Sulcos transversais de distribuição | Dois, sem declividade, no início | 15, 26 | Recomendação construtiva |
| Declive longitudinal >3% | Aproximadamente três sulcos transversais adicionais, equidistantes | 15 | Aviso automático; 3% exatos não acionam “>3%” |
| Comprimento usual | 50–400 m | 18 | Aviso orientativo |
| Largura usual | 4–20 m | 19 | Aviso orientativo |
| Largura | Depende dos dois declives, vazão e máquinas colhedoras | 19 | Compatibilidade com maquinário |
| Comprimento | Depende de infiltração básica, vazão não erosiva, geometria da área e lâmina | 16–18 | Explorar alternativas de L e q |
| Corte da vazão | Frente em 2/3–3/4 de L, sob condição de tempo suficiente para a lâmina desejada | 21 | Regra de manejo condicionada, não corte automático universal |
| Estações de medição | Espaçadas de 10–30 m | 33–41 | Assistente de coleta de dados |

Faixas mais compridas tendem a reduzir a rede de distribuição e mão de obra, desde que irrigadas eficientemente. Menor infiltração permite maior comprimento. O PDF recomenda em geral fixar L e determinar a vazão que maximiza a eficiência.

### 3.1 Desnível e largura máxima [pp.13,19]

Notação normalizada: `D` = desnível transversal (m), `hn` = lâmina normal superficial (m), `St` = declividade transversal decimal, `W` = largura (m).

```text
Dmax = (2/5) hn = 0,4 hn
D = St W
Wmax = Dmax / |St|                 se St != 0
Wmax = 100 Dmax / |St_percentual|  se a entrada estiver em %
```

Na p.19 o PDF usa `L` para largura; no restante, `L` significa comprimento. No aplicativo, usar `W` evita a colisão. A p.13 apresenta hn=10 cm e D=4 cm=0,04 m. A p.19 mostra `0,04×100/St = 8 m`; isso implica **St=0,5%**, valor inferido do resultado, não escrito no denominador numérico.

Exemplo reconstruído: hn=0,10 m → Dmax=0,04 m; St=0,005 → Wmax=8 m. Aumentar a lâmina aumenta a tolerância ao desnível; aumentar o declive transversal reduz a largura. Para St=0, o critério não impõe largura máxima: não dividir por zero nem liberar largura infinita como recomendação. Permanecem vazão, máquinas, diques e orientações geométricas.

**4 cm é o resultado do exemplo, não um limite universal.** A lâmina normal de escoamento não é a IRN infiltrada. A p.14 explica que, para mesmo declive transversal, maior declive longitudinal reduz a lâmina normal e consequentemente a largura máxima.

## 4. Tabelas integralmente transcritas

### 4.1 Marr (1958): sugestões de dimensionamento [p.20]

| Textura | Declividade (%) | Vazão unitária (L/s/m) | Lâmina aplicada (mm) | Largura (m) | Comprimento (m) |
|---|---:|---:|---:|---:|---:|
| Muito fina | 0,15–0,6 | 3–4 | 100–150 | 5–18 | 150–300 |
| Muito fina | 0,6–1,5 | 2–3 | 100–150 | 5–6 | 150–400 |
| Muito fina | 1,5–4,0 | 1–2 | 100–150 | 5–6 | 200 |
| Fina | 0,15–0,6 | 6–8 | 50–100 | 5–18 | 90–180 |
| Fina | 0,6–1,5 | 4–6 | 50–100 | 5–6 | 100–200 |
| Fina | 1,5–4,0 | 2–4 | 50–100 | 5–6 | 100 |
| Média | 1,0–4,0 | 1–4 | 25–75 | 5–6 | 100–300 |

São sugestões, não coeficientes de Kostiakov–Lewis. A tabela não fornece `k`, `a`, `VIB` ou `n` por textura. Nos limites compartilhados, como 0,6%, retornar as duas linhas compatíveis ou declarar a convenção adotada; não escolher silenciosamente. Não extrapolar para outras texturas/declives. Os comprimentos 200 e 100 são valores únicos, não intervalos incompletos.

### 4.2 Booher: vazão em sifões ou tubos [p.26]

Vazões em **L/s**; diâmetro e carga hidráulica em **cm**. Transcrição literal:

| Diâmetro \ carga | 5 | 7,5 | 10 | 12,5 | 15 | 20 | 25 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 4,7 | 5,7 | 6,6 | 7,4 | 8,1 | 9,3 | 10,4 |
| 12,5 | 7,3 | 8,9 | **1,03** | 11,5 | 12,6 | 14,6 | 16,3 |
| 15 | 10,5 | 12,9 | 14,9 | 16,6 | 18,2 | 21,0 | 23,5 |
| 20 | 18,7 | 22,9 | 26,4 | 29,5 | 32,3 | 37,3 | 41,8 |
| 25 | 29,2 | 35,7 | 41,3 | 46,1 | **505,5** | 58,4 | 65,2 |
| 30 | 42,0 | 51,5 | 59,4 | 66,4 | 72,8 | 84,0 | 94,0 |
| 35 | 57,2 | 70,0 | 80,9 | 90,4 | **993,1** | 114,4 | 127,9 |

**Anomalias observadas na própria imagem:**

| Diâmetro/carga (cm) | Impresso (L/s) | Hipótese de correção (L/s) | Situação |
|---|---:|---:|---|
| 12,5 / 10 | 1,03 | 10,3 | Suspeita; não confirmada externamente |
| 25 / 15 | 505,5 | 50,5 | Suspeita; não confirmada externamente |
| 35 / 15 | 993,1 | 99,1 | Suspeita; não confirmada externamente |

As hipóteses seguem a progressão dos valores vizinhos. Isso não as transforma em dados validados. O aplicativo deve guardar `valor_impresso`, `valor_proposto`, `status` e `pagina`, deixando os três pontos indisponíveis para dimensionamento automático até revisão. Interpolação não é prescrita no PDF; se adicionada, identificá-la como aproximação e não interpolar através de células suspeitas. Sem extrapolação automática.

Derivação útil: para m dispositivos idênticos sob a mesma carga, `Qtotal=m Qdispositivo`. Número mínimo teórico `ceil(Qrequerida/Qdispositivo)` exige conferir carga real e divisão de água. O PDF não apresenta dimensionamento hidráulico de comportas, perdas em tubulações nem coeficientes de descarga.

## 5. Convenções e dicionário de unidades

Adotar internamente metros e minutos, seguindo as constantes 60 e 3600 do PDF. Converter somente nas fronteiras de entrada/saída.

| Símbolo normalizado | Significado | Unidade interna |
|---|---|---|
| L, X/x | Comprimento total da faixa, posição | m |
| Lt, Wt, W0 | Comprimento/largura da área, largura da faixa | m |
| S0, St, Sy | Declive longitudinal, transversal, razão yf/L | decimal |
| n | Rugosidade de Manning | s·m^(-1/3), convenção SI |
| q0 | Vazão por unidade de largura, chamada Q0 no PDF | m³/min/m = m²/min |
| Qfaixa, Qt | Vazão total por faixa, vazão do projeto | m³/min |
| y0, yf, hn | Profundidades superficiais | m |
| A0 | Área molhada para faixa de largura de referência 1 m | m² para essa faixa; A0/1 m=y0 |
| I ou z, IRN | Infiltração acumulada e lâmina requerida | m |
| a, r, σz | Expoentes e fator de forma | adimensionais |
| k | Coeficiente de infiltração | m/min^a |
| VIB | Velocidade de infiltração básica | m/min |
| VIM | Velocidade média de infiltração estimada | m/min |
| p | Coeficiente de avanço x=p t^r | m/min^r |
| t0 | Oportunidade necessária para infiltrar a IRN | min |
| ta(x), ta | Instante de chegada em x; chegada no final | min desde início |
| ti | Tempo de aplicação; instante de corte | min desde início |
| td | Instante de término da depleção | min desde início |
| tr(x), tr | Instante de recessão local; recessão no final | min desde início |
| τ(x) | Oportunidade local =tr(x)−ta(x) | min |
| Va, Vd, Vi | Volumes definidos abaixo | m³/m de largura, se q0 é unitária |
| Xa | Comprimento adequadamente irrigado | m |
| Ea, Er, Pp, Pe | Eficiências e perdas | % |
| TIP, tmu, TDF | Tempo por parcela, mudança, jornada diária | min, min, min/dia |
| NPD, NFP, NTF | Parcelas/dia; faixas/parcela; faixas totais | contagens/taxas |
| APP, PI | Área por parcela; período de irrigação | m²; dias |

Se trabalhar com a faixa de referência de 1 m, os números de `q0` e `Q0` coincidem, e os números de A0 e y0 também. Isso **não permite multiplicar novamente pela largura dentro do balanço unitário**. Calcular volumes totais por faixa multiplicando os volumes unitários por W0, uma única vez.

```text
S_decimal = S_percentual / 100
IRN_m = IRN_mm / 1000
q_m3_min_m = 0,06 q_L_s_m
Q_m3_min = 0,06 Q_L_s
Q_m3_s = Q_L_s / 1000
VIB_m_min = VIB_mm_h / 60000
T_min = 60 T_h
Area_ha = Area_m2 / 10000
Qfaixa = q0 W0
```

O PDF usa a letra `n` tanto para rugosidade como para número de segmentos na integração; usar `manning_n` e `n_segmentos`. Usa `ti` tanto para corte quanto, equivocadamente, na p.62; distinguir sempre. O termo “tempo de depleção” pode designar td no slide, mas a **duração da fase** é `td−ti`.

## 6. Catálogo completo de equações

### 6.1 Vazão e comprimento [pp.53–55]

**F01 — Hart et al. (1980), como impresso:**

```text
qmax = 0,01059 S0^(-0,75)
qmax_cobertura_total = 2 qmax
```

O slide identifica S0 como decimal. O título especifica vazão unitária, mas a legenda da fórmula diz somente m³/min. Preservar essa inconsistência. O coeficiente é empírico; não trocar % por decimal sem recalibração. Para S0=0,001, a leitura literal resulta em 1,883197895 m³/min/m, ou 31,38663159 L/s/m; esse resultado deve ser tratado como reprodução do slide, não limite erosivo confirmado. Não usar S0=0.

**F02 — Alternativa por velocidade máxima, transcrição da p.53:**

```text
qmax = [Vmax^ρ2 n² / (3600 S0 ρ1)]^[1/(ρ2−2)]
```

O exemplo fornece ρ1=1 e ρ2=3,33. O PDF não fornece Vmax nem explica sua unidade nesta expressão e não define completamente os parâmetros geométricos. Sob a forma escrita, o fator 3600 liga a convenção de tempo à de velocidade; não inserir Vmax em m/s por adivinhação. Guardar a fórmula como transcrita e bloquear seu uso automático enquanto as convenções não forem confirmadas. Exigir ρ2≠2 e base positiva.

**F03 — Walker e Skogerboe (1984), mínimo sugerido:**

```text
qmin = 0,000357 L S0^0,5 n^(-1)
```

É uma recomendação distinta da expressão anterior. Se os limites adotados forem incompatíveis, indicar inviabilidade sob esses critérios, sem forçar um resultado.

**F04 — Comprimento:**

```text
L ≤ qmax / VIB
```

Arredondar para submúltiplo do comprimento da área. Proposta operacional: para limite Llim>0, escolher `m=max(1,ceil(Lt/Llim))` e `L=Lt/m`, resultando no maior submúltiplo que não excede o limite. Na igualdade exata, essa convenção mantém o valor; o slide diz “imediatamente inferior” sem definir esse caso. VIB=0 retira esta restrição específica; não torna o comprimento livre de outras restrições.

**F05 — Profundidade na entrada:**

```text
y0 = [q0² n² / (3600 S0)]^0,3
```

Verificar `y0 ≤ altura_dique`. Borda livre não é fornecida. Exigir S0>0 para esta fórmula.

### 6.2 Infiltração e oportunidade [pp.47,56]

**F06 — Kostiakov–Lewis:**

```text
I(τ) = k τ^a + VIB τ
VI(τ) = k a τ^(a−1) + VIB  [derivada, útil ao cálculo]
```

`I` é infiltração acumulada; a derivada é velocidade. Para 0<a<1, I(0)=0, mas a derivada em zero é singular. Não avaliar τ^(a−1) em τ=0.

**F07 — Oportunidade alvo por Newton–Raphson:**

```text
f(t) = k t^a + VIB t − IRN
f'(t) = k a t^(a−1) + VIB
t_novo = t − f(t)/f'(t)
```

Inicialização da aula: `t=100 min`. Convergência da aula: diferença entre iterações menor que 0,1 min. Proposta: usar valor absoluto, limite de iterações e verificar também `|I(t)−IRN|`; salvaguarda por bisseção se Newton produzir tempo negativo ou derivada problemática. O intervalo 0<a<1 é uma escolha de domínio para o núcleo fornecido, não intervalo explicitamente fixado pelo slide.

### 6.3 Avanço medido ou simulado [pp.45,57–62]

**F08 — Lei ajustada a dados de campo:**

```text
x = p ta(x)^r
ta(x) = (x/p)^(1/r)
p = L / ta(L)^r  [derivação]
```

O PDF não fornece uma série numérica de medições nem coeficientes p e r de um ensaio. A figura da p.42 é ilustrativa; não foi convertida em um falso conjunto exato de dados. Medir avanço e recessão em estações espaçadas de 10–30 m. Se implementar ajuste logarítmico, usar apenas pares positivos, excluir (0,0) da transformação, informar erro de ajuste e conservar os dados brutos; isso é proposta de software.

**F09 — Balanço volumétrico para distância X:**

```text
q0 tx = 0,77 A0 X + σz k tx^a X + VIB tx X/(1+r)
```

Com largura de referência de 1 m, usar A0 numericamente igual a y0. O primeiro termo é armazenamento superficial aproximado, os demais representam infiltração. O fator 0,77 vem do PDF, sem calibração fornecida.

**F10 — Fator de forma:**

```text
σz = [a + r(1−a) + 1] / [(1+a)(1+r)]
```

**F11 — Newton para o avanço:**

```text
F(t) = q0 t − 0,77 A0 X − σz k t^a X − VIB t X/(1+r)
F'(t) = q0 − σz k a X t^(a−1) − VIB X/(1+r)
corr = F(t)/F'(t)
t_novo = t − corr
t_inicial = 5 A0 X/q0
```

O PDF escreve o termo da derivada também como `σz a k L/t^(1−a)`. Calcular em X=L e X=L/2, substituindo o comprimento em todos os termos dependentes de X.

**F12 — Iteração de r:**

```text
r_inicial = 0,7       [aula sugere iniciar entre 0,5 e 0,9]
r_novo = ln(2) / [ln(tx_L) − ln(tx_L/2)]
```

Forma geral da p.58: `(ln Lmax−ln Lmed)/(ln txmax−ln txmed)`. O intervalo inicial de r não é um limite obrigatório do resultado. Iterar σz, os dois tempos e r até convergir. Para os solos em declive, A0 permanece o da entrada, não é reduzida à metade.

O slide associa não convergência à vazão pequena para L. Software deve distinguir inviabilidade física de falha numérica. Para r fixo, k>0, 0<a<1, A0>0, a equação exige `q0 > VIB X/(1+r)` para possuir raiz positiva; isso é uma condição derivada da equação, não prova de validade do modelo inteiro. Newton pode falhar mesmo quando há raiz.

**F13 — Área molhada especial para solo em nível [p.61]:**

```text
A0(X) = [q0² n² X / 3600]^(3/13)
```

Recalcular A0 para cada X, inclusive L/2. O PDF só oferece essa adaptação ao avanço. Não usar S0=0 nas fórmulas de y0 e recessão que dividem por S0. Uma simulação completa em nível exige completar a metodologia.

### 6.4 Depleção e recessão [pp.43–45,62–66]

**F14 — Relação entre corte e término da depleção:**

```text
td = ti + y0 L/(2 q0)
ti = td − y0 L/(2 q0)
```

**F15 — Velocidade média estimada no instante td:**

```text
VIM = (a k/2) [td^(a−1) + (td−ta)^(a−1)] + VIB
```

Aqui ta é o avanço até o final, não o avanço local. A expressão usa as velocidades nos extremos; não é a integração espacial exata. Exige td>ta para 0<a<1.

**F16 — Vazão residual, profundidade final e Sy:**

```text
qf = q0 − VIM L
yf = [(qf n)/(60 sqrt(S0))]^0,6
Sy = yf/L
```

Equivalentemente, `Sy=[qf² n²/(3600 S0)]^(3/10)/L`, **desde que qf>0**. A forma com quadrado isoladamente esconderia um qf negativo. A segunda expressão da p.44 imprime multiplicação por L, em conflito com a primeira e com pp.63/65. A versão consistente adotada é divisão por L; isso é uma correção editorial identificada.

**F17 — Duração da recessão, Strelkoff (1977), como p.43:**

```text
Δtr = tr−td
Δtr = 0,095 n^0,47565 Sy^0,20725 L^0,6829 /
       [VIM^0,52435 S0^0,237825]
```

Páginas 63 e 66 usam expoentes arredondados: Sy^0,2072, VIM^0,5243 e S0^0,2378. O núcleo anexo usa a precisão da p.43 de forma consistente. Não misturar versões dentro de uma execução. Registrar a versão no resultado.

**F18 — Recessão alvo:**

```text
tr_alvo = t0 + ta(L)
```

Isso garante oportunidade t0 no final. A p.62 imprime `tr = ti = to + ta`; a igualdade `tr=ti` conflita com a p.43 e com o recálculo de ti na p.64. O núcleo usa apenas `tr=t0+ta`.

**F19 — Iteração de td:**

```text
td_inicial = tr_alvo
calcular VIM(td), qf(td), yf(td), Sy(td), Δtr(td)
td_novo = tr_alvo − Δtr(td)
repetir até convergir
```

O slide pede igualdade entre iterações; em ponto flutuante, usar tolerância e limite de iterações. Se td≤ta ou qf≤0, parar e marcar incompatibilidade do candidato com o modelo, sem potência complexa ou valor absoluto corretivo.

**F20 — Verificação e correção de oportunidade na entrada:**

```text
I0 = k td^a + VIB td
se I0 ≥ IRN: entrada atende
se I0 < IRN: redefinir td=t0
```

A aula usa > e <, deixando a igualdade sem descrição; tratá-la como atendimento dentro da tolerância. No ramo inadequado, recalcular VIM, Sy, duração e então `tr=td+Δtr(td)`, por rearranjo da p.66; recalcular `ti=td−y0L/(2q0)`.

**F21 — Infiltração final após ajuste:**

```text
If = k (tr−ta)^a + VIB (tr−ta)
```

Não basta supor que a faixa inteira atende porque os dois extremos atendem. Avaliar o perfil completo. O PDF oferece uma checagem simplificada da entrada, não uma prova geral para qualquer curva.

**F22 — Recessão linear e perfil:**

```text
tr(x) = td + (tr−td)x/L
τ(x) = tr(x) − ta(x)
I(x) = k τ(x)^a + VIB τ(x)
```

Recessão linear é hipótese expressa das pp.45/68. Curvas de avanço e recessão mais paralelas significam oportunidade mais uniforme, como explica a p.42. Não inserir `t0` alvo em todos os pontos: a oportunidade é local.

### 6.5 Integração, eficiência e perdas [pp.46–47,64,67–68]

**F23 — Regra dos trapézios:**

```text
Vi = L/(2N) [I0 + 2 I1 + 2 I2 + ... + 2 I(N−1) + IN]
```

A p.47 imprime a expressão abreviada `L/(2n)(Io+2I1+...In)`. A soma acima explicita os pesos internos. Para espaçamento variável: `Vi=Σ (xj+1−xj)(Ij+Ij+1)/2`. Com I em m, Vi é m³/m de largura; multiplicar por W0 para volume da faixa.

**F24 — Avaliação por regiões, como p.46:**

```text
Ea = 100 (IRN Xa + Vd)/(q0 ti)
Er = 100 (IRN Xa + Vd)/(IRN L)
Pp = 100 (Va − IRN Xa)/(q0 ti)
Pe = 100 − Ea − Pp
```

Xa é o comprimento que atende à IRN, Va o volume infiltrado nessa região, Vd o volume infiltrado na região deficitária. A legenda não define Xa explicitamente; a interpretação decorre das fórmulas. Guardar todos na mesma base de largura. Não presumir que a região adequada é sempre um único trecho inicial.

**F25 — Eficiência simplificada de dimensionamento:**

```text
Ea = 100 IRN L/(q0 ti)
```

Usada nas pp.64/67 e válida para benefício integral da IRN em toda a faixa. Se houver déficit local, usar F24 ou integração geral; caso contrário superestima a eficiência útil.

**Forma integral derivada, mais robusta para implementação:**

```text
Ventrada = q0 ti
Vinfiltrado = integral_0^L I(x) dx
Vutil = integral_0^L min(I(x), IRN) dx
Vpercolado = integral_0^L max(I(x)−IRN, 0) dx
Vdeficit = integral_0^L max(IRN−I(x), 0) dx
Vescoado = Ventrada − Vinfiltrado   [ao final, sem armazenamento superficial restante]
Ea = 100 Vutil/Ventrada
Er = 100 Vutil/(IRN L)
Pp = 100 Vpercolado/Ventrada
Pe = 100 Vescoado/Ventrada
```

Checar `Vinfiltrado=Vutil+Vpercolado`, `IRN L=Vutil+Vdeficit`, `Ventrada=Vutil+Vpercolado+Vescoado` e `Ea+Pp+Pe≈100%`. Valores negativos significativos ou >100% indicam inconsistência; não mascarar com clamp automático. A integração integral é equivalente à avaliação por regiões sob as mesmas hipóteses. Volume remanescente em superfície durante o evento deve entrar no balanço; não usar essa identidade final em qualquer instante.

### 6.6 Otimização e organização do projeto [pp.67,69–71]

**F26 — Busca em vazão:** decrementar a vazão inicial por Δq até maximizar Ea. O PDF exemplifica ΔQ=0,05 L/s; como trabalha por unidade de largura, o simulador deve explicitar se o passo é L/s/m. Nessa interpretação, 0,05 L/s/m = **0,003 m³/min/m**.

Ao mudar q0, recalcular y0, avanço completo e intermediário, r, oportunidade quando aplicável, recessão, corte e desempenho. A p.67 manda repetir d–l, mas repetir apenas literalmente esses itens reutilizaria grandezas dependentes de q0. O aplicativo deve refazer todas as dependências. Busca discreta dá o melhor ponto da grade viável, não garantia de ótimo contínuo/global. Registrar candidatos rejeitados e causas.

**F27 a F32 — Organização:**

```text
TIP = ti + tmu
NPD = TDF/TIP
APP = Wt Lt/(NPD PI)
W0 = APP/(NFP L)
NTF = NFP NPD PI
Qt = NFP W0 q0
```

W0 deve ser submúltiplo de Wt. NFP representa faixas irrigadas simultaneamente em uma parcela. PI é o período disponível para completar a irrigação; não confundir automaticamente com turno agronômico ou intervalo entre entregas de água.

Propostas para cronograma executável:

1. Usar `floor(TDF/TIP)` para parcelas completas/dia quando não há continuidade noturna; o quociente bruto pode ser fracionário e deve continuar disponível para consulta.
2. Escolher contagens inteiras de faixas/parcelas e recomputar a área realmente atendida.
3. Conferir `(Wt/W0)` e `(Lt/L)` inteiros dentro de tolerância.
4. Comparar `NTF_geometrico=(Wt/W0)(Lt/L)` com a capacidade do cronograma; diferença significa sobra ou cobertura incompleta.
5. Conferir `Qt_necessaria ≤ Qt_disponivel`, janela de fornecimento e jornada.
6. Se houver mudança ou lavagem adicional, modelar explicitamente o tempo; não ocultá-lo em ti.

## 7. Fases e visualização do evento

| Fase | Significado conforme figuras/texto | Representação no aplicativo |
|---|---|---|
| Avanço | Frente de água se desloca até L | x(t), mapa da faixa e ta(x) |
| Reposição | Prosseguimento da aplicação após o avanço, quando ocorre | Intervalo até corte ti |
| Depleção | Após o corte, a lâmina superficial diminui até início de exposição | Duração td−ti |
| Recessão | Superfície exposta progride, até recessão total | tr(x) e tr−td |

As pp.28–29 ilustram ordem T=0, Ta, Ti, Td, Tr. A recomendação operacional de corte em 2/3–3/4 de L pode produzir `ti<ta(L)`, situação que não segue essa sequência didática simples. O balanço de avanço com entrada constante até L **não simula automaticamente** o avanço restante após tal corte. O núcleo de referência rejeita essa situação; um motor mais completo precisa acompanhar a água armazenada após o corte.

Gráficos úteis: (1) avanço/recessão no mesmo eixo x–tempo, com τ como distância vertical; (2) I(x) com linha IRN e áreas de déficit/percolação; (3) Ea, Er, Pp e Pe por vazão; (4) volume útil/percolado/escoado; (5) infiltração acumulada e velocidade por cenário; (6) mapa de faixas e parcelas; (7) cronograma de operação; (8) convergência de t0, r e td. Animação interpolada das curvas é didática; não deve aparentar solução hidrodinâmica detalhada inexistente.

## 8. Exemplo da aula e validação numérica

### 8.1 Entradas efetivamente fornecidas [p.73]

| Dado | Primeira irrigação | Terceira irrigação |
|---|---:|---:|
| k | 0,0035 | 0,0034 |
| a | 0,47 | 0,45 |
| VIB | 0,00011 | 0,00010 |
| IRN | 56 mm | 56 mm |
| Área | 400×400 m | 400×400 m |
| Declividade em uma direção | 0,1% | 0,1% |
| Declividade na outra direção | 0,0% | 0,0% |
| n | 0,040 | 0,040 |
| ρ1; ρ2 | 1; 3,33 | 1; 3,33 |
| Evapotranspiração máxima | 8,0 mm/dia | 8,0 mm/dia |
| Vazão disponível | 400 L/s | 400 L/s |
| Disponibilidade | A cada sete dias | A cada sete dias |

A unidade impressa para I é **m³/min**, incompatível com infiltração acumulada. Para os cálculos reconstruídos, I e IRN são interpretadas em **m de lâmina**, k em m/min^a e VIB em m/min, coerentes com a metodologia unitária. Essa normalização precisa de confirmação com a planilha original para reproduzir o gabarito oficial.

### 8.2 Resultados diretamente derivados das entradas

```text
Área = 400×400 = 160.000 m² = 16 ha
S0 = 0,1/100 = 0,001
St = 0
IRN = 0,056 m
Qt = 400 L/s = 0,4 m³/s = 24 m³/min
VIB primeira = 6,6 mm/h
VIB terceira = 6,0 mm/h
Volume líquido por irrigação = 160.000×0,056 = 8.960 m³
Demanda líquida diária simplificada = 160.000×0,008 = 1.280 m³/dia
Turno simplificado = 56/8 = 7 dias
Tempo mínimo teórico a 100% de eficiência = 8.960/24
                                             = 373,333333 min = 6,222222 h
```

O turno 7 dias é derivação sem chuva, variação de ET ou outros termos de balanço. A frase “disponível a cada sete dias” não informa por quantas horas a água está disponível. Não equivale a sete dias de fornecimento contínuo. A jornada TDF, tmu, altura dos diques, largura das máquinas, Vmax, condição de cobertura e largura adotada não são fornecidas. Por isso não existe dimensionamento único fechado de W0, NFP e cronograma somente com os dados do PDF; as planilhas presentes no repositório precisam de auditoria separada.

### 8.3 Casos básicos para teste

| Caso | Resultado esperado | Origem |
|---|---:|---|
| hn=0,10 m → Dmax | 0,04 m | Exemplo p.13 |
| Dmax=0,04 m, St=0,5% → Wmax | 8 m | Reconstrução p.19 |
| 0,05 L/s/m em m³/min/m | 0,003 | Conversão do passo p.67 |
| I(100 min), primeira | 0,04148372565 m | Recalculado |
| I(100 min), terceira | 0,03700715998 m | Recalculado |
| t0 para 56 mm, primeira | 161,71965439 min | Raiz de Kostiakov–Lewis |
| t0 para 56 mm, terceira | 195,13612259 min | Raiz de Kostiakov–Lewis |
| qmin, L=400 m, S0=0,001, n=0,04 | 0,11289331247 m³/min/m | F03 |
| Mesmo qmin em L/s/m | 1,8815552078 | Conversão |
| Hart literal para S0=0,001, cobertura não total | 1,88319789523 m³/min/m | F01, unidade por confirmar |
| Hart literal, cobertura total | 3,76639579046 m³/min/m | Fator 2 do slide |

### 8.4 Cenário reconstruído para validar a cadeia de cálculo

**Escolhas adicionais explícitas:** faixa aberta em declive; L=400 m; q0=0,20 m³/min/m (=3,333333 L/s/m); n=0,04; S0=0,001; IRN=0,056 m; largura de referência 1 m; recessão linear; expoentes da p.43; correções editoriais descritas neste documento. A vazão de 0,20 é uma escolha de teste, não valor dado pela aula nem ótimo declarado.

| Saída | Primeira irrigação | Terceira irrigação |
|---|---:|---:|
| y0 (m) | 0,03758056 | 0,03758056 |
| t0 (min) | 161,71965 | 195,13612 |
| r | 0,73584982 | 0,76519686 |
| ta(L) (min) | 122,19072 | 112,15363 |
| td (min) | 214,70148 | 229,91529 |
| tr (min) | 283,91037 | 307,28975 |
| ti (min) | 177,12092 | 192,33473 |
| Ea (%) | 63,23364 | 58,23181 |
| Er (%) | 100,00000 | 100,00000 |
| Pp, aproximadamente (%) | 8,65193 | 4,67304 |
| Pe, aproximadamente (%) | 28,11443 | 37,09514 |
| Lâmina mínima (mm) | 56 | 56 |

Perdas vêm da integração do perfil; últimas casas dependem da discretização. O JSON inclui valores calculados com 2.000 segmentos. Os resultados são **referências internas reconstruídas**, não soluções publicadas pela professora. Verificação algébrica/numérica não comprova precisão hidráulica em campo.

Exemplo adicional de conversão de escala, com **W0=10 m escolhidos aqui**: Qfaixa=2 m³/min=33,333333 L/s; 12 faixas simultâneas consomem os 400 L/s disponíveis; a área total teria 40 faixas de 400×10 m. Precisaria de 4 grupos, sendo o último com 4 faixas, sob esse agrupamento. Isso não fecha o cronograma porque TDF/tmu/janela não foram dados e não avalia maquinário ou altura dos diques. O desnível transversal zero não limita essa largura pelo critério Dmax/St.

### 8.5 Testes artificiais de integração e erros

São casos de software construídos aqui, distintos do exemplo da aula:

- Perfil constante I=IRN=0,05 m, L=100 m, Ventrada=5 m³/m → Ea=Er=100%, Pp=Pe=0.
- Perfil constante I=0,06 m, IRN=0,05 m, L=100 m, Ventrada=8 m³/m → Vutil=5, Vpercolado=1, Vescoado=2; Ea=62,5%, Er=100%, Pp=12,5%, Pe=25%.
- Perfil constante I=0,03 m, IRN=0,05 m, L=100 m, Ventrada=5 m³/m → Ea=60%, Er=60%, Pp=0%, Pe=40%.
- Perfil linear [0,04;0,06;0,08] m em x=[0;50;100] m → Vi=6 m³/m.
- St=0 → não calcular divisão por zero; sem limite transversal específico.
- S0=0 → bloquear o ramo completo de declive; a fórmula especial de avanço não resolve a recessão.
- td≤ta com a<1 → rejeitar VIM indefinida.
- qf≤0 → rejeitar modelo de recessão; não elevar valor negativo a potência fracionária.
- ti≤0, IRN≤0, L≤0, q≤0, n≤0 → rejeitar execução.
- τ<0 → rejeitar perfil; nunca converter para módulo.
- VIB=0 → oportunidade ainda pode existir; não dividir por VIB no limite de comprimento.
- Dados não finitos, contagens fracionárias de faixas ou tempos com unidades inconsistentes → erro de entrada.
- Células 1,03;505,5;993,1 da tabela → dado sob revisão, não sugestão automática de equipamento.

## 9. Fluxo de implementação proposto

**Plano executável para o aplicativo:** [`plano-completo-irrigacao-por-faixas.md`](plano-completo-irrigacao-por-faixas.md). O roteiro abaixo descreve a sequência matemática; o plano vinculado começa com a organização de `models/`, `services/simulation/` e `viewmodels/` por método e prossegue com integração em etapas, arquivos reais, interface, persistência e critérios de aceite. O projeto de sulcos serve de referência visual, sem transpor suas equações.

1. Selecionar objetivo: avaliar ensaio medido, simular faixa ou dimensionar/otimizar projeto.
2. Escolher tipo de faixa e manejo. Declarar quais modelos estão implementados.
3. Ler e normalizar unidades, sem inferir unidade pela magnitude.
4. Validar solo, relevo, dimensões, vazão e dados operacionais.
5. Consultar recomendações geométricas e tabela de Marr; produzir avisos.
6. Calcular t0 de cada cenário de infiltração separadamente.
7. Definir L admissível e selecionar q candidatos; verificar oferta e critérios de vazão.
8. Calcular y0, checar diques e largura transversal.
9. Usar avanço medido ajustado ou resolver r/tempos pelo balanço.
10. Estimar recessão/depleção, aplicar ajuste da entrada e calcular ti.
11. Construir perfil τ/I; validar domínio e atendimento ao longo da faixa.
12. Integrar volumes; calcular Ea, Er, Pp e Pe; checar balanço.
13. Explorar candidatos de vazão/L e selecionar melhor candidato viável pelo objetivo declarado.
14. Dimensionar largura, contagens inteiras, parcelas e jornada; comparar demanda à disponibilidade.
15. Exportar entradas, hipóteses, referências de página, alertas, resultados e histórico de convergência.

O núcleo Python entregue implementa **um candidato** em declive, com vazão constante. Não implementa otimização automática, cronograma inteiro, ajuste estatístico de campo, faixas fechadas, redução de vazão, reuso ou trecho terminal plano. Essas funções estão especificadas, sem fingir que o documento as resolve integralmente.

## 10. Modelo de dados e telas

### 10.1 Entradas a armazenar

| Grupo | Campos |
|---|---|
| Proveniência | Documento, página, versão de fórmula, origem medida/assumida/derivada, data do ensaio |
| Área | Lt, Wt, perfil longitudinal, S0, St, área útil, orientação |
| Faixa | L, W0, condição jusante, dique temporário/permanente, altura real, bases e taludes se disponíveis |
| Solo | k, a, VIB, unidades, cenário primeira/terceira/outra irrigação, textura |
| Cultura | Cobertura total/parcial, IRN, ET, estágio/condição da cobertura, rugosidade medida ou estimada |
| Vazão | Qt disponível, q0, limites, passo, dispositivo, carga, diâmetro, status do dado tabulado |
| Campo | Estações x, ta, tr, referência de relógio, observações, p/r ajustados |
| Operação | TDF, tmu, PI, dias/horários reais de água disponível, NFP |
| Numérico | Método, tolerâncias, máximos de iterações, segmentos, versão dos expoentes de recessão |

### 10.2 Saídas

Dimensões candidatas; q por metro, Q por faixa e Qt; y0; t0; r/p/σz; ta(L/2)/ta(L); td/tr/ti; VIM/qf/Sy; perfil espacial; volumes unitários e totais; Ea/Er/Pp/Pe; déficit e área atendida; contagens operacionais; cronograma; motivos de rejeição; avisos de fonte; resíduos numéricos.

### 10.3 Telas sugeridas

- **Projeto:** geometria, declives, cultura, solo e unidades.
- **Ensaio de campo:** tabela de estações, avanço/recessão e ajuste.
- **Simulação:** cálculo por candidato, curvas e perfil.
- **Comparação:** primeira/terceira irrigação, diferentes q e L.
- **Equipamentos e manejo:** tabela com células sob revisão, diques, sulcos e corte.
- **Operação:** parcelas e disponibilidade de água.
- **Auditoria:** fórmula usada, página, unidades, hipótese/correção e status de cada validação.

Status recomendados: `valido_no_modelo`, `aviso_orientativo`, `entrada_invalida`, `fora_do_dominio`, `sem_convergencia`, `balanco_inconsistente`, `dado_fonte_suspeito`, `modelo_nao_implementado`. Ausência de erro numérico não deve ser rotulada como projeto validado em campo.

## 11. Inconsistências, omissões e decisões obrigatórias

| ID | Página | Problema | Tratamento documentado |
|---|---:|---|---|
| E01 | 19 | L representa largura, mas depois representa comprimento | Usar W para largura |
| E02 | 26 | Três células de vazão anômalas | Preservar bruto; correções apenas propostas |
| E03 | 40–41 | Rótulos Ta3/Ta4 aparecem na sequência de recessão | Registrar como prováveis Tr3/Tr4; não como novas medições |
| E04 | 44 | Sy=yf/L, mas outra linha multiplica por L | Usar divisão, concordante com pp.63/65 |
| E05 | 46 | Unidades e notação herdadas de sulcos | Normalizar todas à mesma largura de referência |
| E06 | 47 | Soma de trapézios abreviada | Explicitar peso 2 em todos os nós internos |
| E07 | 53–54 | Legendas m³/min, título m³/min/m | Tratar q como unitária; sinalizar inconsistência |
| E08 | 53 | Vmax/unidades e parâmetros da fórmula alternativa incompletos | Não executar sem dados/convenção confirmados |
| E09 | 62 | tr=ti=t0+ta contradiz depleção/corte | Usar tr=t0+ta; ti calculado separadamente |
| E10 | 63/66 | Expoentes arredondados em relação à p.43 | Versão única, registrada; aqui p.43 |
| E11 | 63 | Igualdade exata usada como parada | Tolerância + resíduo + teto de iterações |
| E12 | 64 | Igualdade I0=IRN omitida e teste só na entrada | Atendimento com tolerância; verificar perfil inteiro |
| E13 | 65–66 | Instrução manda substituir t0, mas fórmula mantém td iterativo | Fazer substituição explícita e rearranjar tr=td+Δtr |
| E14 | 67 | Repetição d–l não menciona todas as dependências de q | Recalcular cadeia inteira |
| E15 | 67 | Passo 0,05 L/s sem “por metro” | Solicitar/registrar base; aqui tratado por metro |
| E16 | 73 | I(m³/min) para infiltração acumulada | Interpretar como lâmina para cálculos; confirmar gabarito |
| E17 | 12/20/73 | Faixa geral 0,2–6%, tabela inicia em 0,15%, exemplo usa 0,1% | Recomendação, não bloqueio; mostrar fora da faixa usual |
| E18 | 21/28–29 | Corte antes de L pode preceder fim do avanço | Não aplicar sequência completa mecanicamente |
| E19 | 69–70 | Contagens podem sair fracionárias | Resolver discretização e revalidar cobertura |
| E20 | 73 | Exemplo remete a planilha não incluída no PDF; duas planilhas de faixas constam no repositório, sem auditoria nesta extração | Nenhum resultado reconstruído é gabarito oficial |

Não estão no documento: condições de calibração/validade das equações empíricas; erro estatístico dos coeficientes; tabela de rugosidade; velocidade máxima erosiva; chuva, demanda meteorológica completa e cálculo de IRN a partir de solo/raiz; qualidade de água; custos; bombeamento; dimensionamento de canais/comportas; armazenamento e bombeamento de reuso; hidrograma de redução de vazão; modelo completo em nível ou fechado; topografia 2D; solução de conservação de quantidade de movimento; janela diária de fornecimento. O simulador não deve inventar padrões para esses itens sem identificar que são hipóteses adicionais.

## 12. Cobertura das 73 páginas

| Páginas | Conteúdo extraído e destino |
|---|---|
| 1 | Título, instituição e autoria; identificação da fonte |
| 2 | Definição do método e direções de declividade; seção 2 |
| 3 | Esquema canal, tomadas, diques, faixas, sentido e saída; seção 2 |
| 4–6 | Fotografias de faixas/distribuição/cobertura; sem coeficientes adicionais |
| 7 | Esquema de canais e largura ilustrativa de 12 m; seção 2 |
| 8–9 | Fotografias de aplicação e culturas; apoio visual |
| 10 | Infográfico de compatibilidade, ≥4 ha, textura média e requisitos; seção 2 |
| 11 | Infiltração e fatores do avanço; seção 2 |
| 12 | Declividade longitudinal e trecho terminal plano; seção 3 |
| 13 | D≤2/5 hn e exemplo de 4 cm; seção 3 |
| 14 | Relação entre declive longitudinal, profundidade e largura; seção 3 |
| 15 | Sulcos transversais no início e para >3%; seção 3 |
| 16–18 | Critérios de comprimento, 50–400 m e otimização de vazão; seção 3 |
| 19 | Critérios de largura, 4–20 m e exemplo de 8 m; seção 3 |
| 20 | Sete linhas de Marr; seção 4 |
| 21 | Aplicação e critério condicionado de corte; seções 3 e 7 |
| 22 | Fotografias de derivação/controle; componentes |
| 23 | Diques e três bases ilustradas; seção 2 |
| 24–25 | Controle de vazão, tipos e fotografia; seção 2 |
| 26 | Matriz 7×7 de Booher e dois sulcos; seção 4 |
| 27 | Base unitária, depleção/recessão e infiltração; seções 2,5,7 |
| 28–29 | Sequência visual T=0, Ta, Ti, Td, Tr; seção 7 |
| 30 | Canal, sifão, diques, avanço, infiltração e zona radicular; seção 2 |
| 31 | Esquema “Rapid advance (T′/4)”, saída e boa distribuição | 
| 32 | Lâminas inicial/final, percolada e escoada; perfil e balanço |
| 33–37 | Medição progressiva de Ta1–Ta4, estações 10–30 m |
| 38–41 | Medição da recessão; rótulos inconsistentes em 40–41 |
| 42 | Curvas e paralelismo relacionado à uniformidade; seção 7 |
| 43–44 | Strelkoff, td, Δtr, Sy, yf, qf e VIM; seção 6 |
| 45 | Avanço potencial e recessão linear; seção 6 |
| 46 | Ea, Er, Pp, Pe e legenda; seção 6 |
| 47 | Infiltração e trapézios; seção 6 |
| 48 | Separador de dimensionamento, sem nova fórmula |
| 49 | Canal largo e importância de depleção/recessão; seção 2 |
| 50 | Tipos de faixa e três estratégias; seção 2 |
| 51 | Escopo: metodologia com escoamento livre |
| 52 | Lista de entradas; seções 5 e 10 |
| 53–55 | Limites de vazão, comprimento e y0; seção 6 |
| 56 | Kostiakov–Lewis e Newton de t0; seção 6 |
| 57 | Equação de avanço de campo; seção 6 |
| 58–59 | Balanço, σz e r; p.59 repete e destaca incógnitas |
| 60 | Iteração do avanço e correção Newton; seção 6 |
| 61 | Metade do comprimento e adaptação em nível; seção 6 |
| 62 | Atualização de r e recessão alvo; seção 6 |
| 63 | Iteração de td; seção 6 |
| 64 | I0, teste de adequação, ti e Ea; seção 6 |
| 65–66 | Ramo inadequado, recálculo e If; seção 6 |
| 67 | Ea e decremento/otimização de vazão; seção 6 |
| 68 | Perfil, percolação e escoamento; seção 6 |
| 69 | TIP, NPD, APP; seção 6 |
| 70 | W0, NFP e NTF; seção 6 |
| 71 | Vazão total necessária; seção 6 |
| 72 | Abertura do exemplo, sem valores |
| 73 | Entradas do único exemplo de projeto; seção 8 |

Na figura da p.31, a notação T′/4 aparece sem definição quantitativa suficiente para configurar um limite no software. Deve permanecer indicação qualitativa de avanço rápido, não ser transformada em uma regra numérica autônoma.

## 13. Conteúdo dos arquivos complementares

- `dados_extraidos.json`: as duas tabelas, anomalias preservadas, entradas do exemplo e metadados de unidades.
- `resultados_referencia.json`: saídas da cadeia calculada, hipóteses e tolerâncias sugeridas.
- `perfil_primeira.csv` e `perfil_terceira.csv`: perfis espaciais do cenário q0=0,20.
- `nucleo_referencia.py`: cálculo reprodutível de um candidato em declive, sem dependências externas.
- `testar_referencia.py`: testes numéricos, balanço, domínio e comparação Newton/bisseção.
- `validacao.txt`: resultado da execução dos testes.
- `texto_extraido_por_pagina.txt`: texto bruto extraível, explicitamente incompleto para fórmulas em imagem.
- `evidencias/`: imagens das páginas com tabelas, equações e exemplo para conferência da transcrição.

Executar localmente com Python 3: `python3 testar_referencia.py`. O comando `python3 nucleo_referencia.py` imprime os dois cenários. Não é necessário instalar pacotes.

Este conjunto permite iniciar um simulador rastreável e testar seu núcleo. Para reproduzir exatamente o exercício da professora e fechar o dimensionamento operacional, ainda são necessárias a conferência das planilhas de faixas disponíveis no repositório com a referência da p.73, a definição dos parâmetros faltantes e a resolução das inconsistências apontadas. A sequência de implementação no aplicativo está no plano vinculado na seção 9.
