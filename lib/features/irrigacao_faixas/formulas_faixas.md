# Fórmulas – Irrigação por Faixas (UNIPAMPA)

> Transcritas dos slides enviados. Onde o slide não define um símbolo, ele aparece como "não definido no slide".

---

## 1. Faixas – Declividade

Diferença de nível transversal máxima permitida (aproximadamente 2/5 da lâmina normal que se movimentará sobre a faixa):

$$
D \leq \frac{2}{5} \cdot h_m \leq \frac{2}{5} \cdot 10 \leq 4\ \text{cm} \leq 0{,}04\ \text{m}
$$

---

## 2. Faixas – Largura

Relação entre a diferença de nível transversal e a declividade transversal:

$$
D = S_t \cdot L
$$

Largura máxima (em geral a largura varia entre 4 e 20 m):

$$
L = \frac{D}{S_t} = \frac{0{,}04 \cdot 100}{S_t} = 8\ \text{m}
$$

**Largura depende de:** declividade transversal, declividade longitudinal, vazão disponível e largura das máquinas colhedoras.

---

## 3. Obtenção da fase de avanço e recessão

### 3.1 Tempo de depleção e duração da fase de recessão (Strelkoff, 1977)

Tempo de depleção:

$$
t_d = t_i + \frac{y_0 \cdot L}{2\, Q_0}
$$

Duração da fase de recessão:

$$
t_r - t_d = \frac{0{,}095 \cdot n^{0{,}47565} \cdot S_y^{0{,}20725} \cdot L^{0{,}6829}}{VIM^{0{,}52435} \cdot S_0^{0{,}237825}}
$$

### 3.2 Lâmina e volume de escoamento

Relação de volume de escoamento:

$$
S_y = \frac{y_f}{L}
$$

Lâmina de escoamento no final da faixa:

$$
y_f = \left( \frac{(Q_0 - VIM \cdot L) \cdot n}{60 \cdot S_0^{0{,}5}} \right)^{0{,}6}
$$

Forma alternativa do volume de escoamento:

$$
S_y = \left[ \frac{Q_f^2 \cdot n^2}{3600 \cdot S_0} \right]^{3/10} \cdot L
$$

Vazão final:

$$
Q_f = Q_0 - VIM \cdot L
$$

### 3.3 Velocidade de infiltração média

$$
VIM = \frac{a \cdot k}{2} \left[ t_d^{\,a-1} + (t_d - t_a)^{a-1} \right] + VIB
$$

- **VIM:** velocidade de infiltração média ao longo da faixa no instante $t_d$, ou seja, no final da fase de depleção.

---

## 4. Tabelas de referência

### Tabela 1 – Sugestões para dimensionamento de faixas (Marr, 1958)

| Tipo de solo | Declividade (%) | Vazão unitária (L s⁻¹/m) | Lâmina aplicada (mm) | Largura (m) | Comprimento (m) |
|---|---|---|---|---|---|
| Textura muito fina | 0,15 a 0,6 | 3 a 4 | 100 a 150 | 5 a 18 | 150 a 300 |
| Textura muito fina | 0,6 a 1,5 | 2 a 3 | 100 a 150 | 5 a 6 | 150 a 400 |
| Textura muito fina | 1,5 a 4,0 | 1 a 2 | 100 a 150 | 5 a 6 | 200 |
| Textura fina | 0,15 a 0,6 | 6 a 8 | 50 a 100 | 5 a 18 | 90 a 180 |
| Textura fina | 0,6 a 1,5 | 4 a 6 | 50 a 100 | 5 a 6 | 100 a 200 |
| Textura fina | 1,5 a 4,0 | 2 a 4 | 50 a 100 | 5 a 6 | 100 |
| Textura média | 1,0 a 4,0 | 1 a 4 | 25 a 75 | 5 a 6 | 100 a 300 |

### Tabela 2 – Vazão (L/s) em sifões ou tubos, segundo Booher

| Diâmetro (cm) | 5 cm | 7,5 cm | 10 cm | 12,5 cm | 15 cm | 20 cm | 25 cm |
|---|---|---|---|---|---|---|---|
| 10 | 4,7 | 5,7 | 6,6 | 7,4 | 8,1 | 9,3 | 10,4 |
| 12,5 | 7,3 | 8,9 | 1,03 ⚠️ | 11,5 | 12,6 | 14,6 | 16,3 |
| 15 | 10,5 | 12,9 | 14,9 | 16,6 | 18,2 | 21,0 | 23,5 |
| 20 | 18,7 | 22,9 | 26,4 | 29,5 | 32,3 | 37,3 | 41,8 |
| 25 | 29,2 | 35,7 | 41,3 | 46,1 | 505,5 ⚠️ | 58,4 | 65,2 |
| 30 | 42,0 | 51,5 | 59,4 | 66,4 | 72,8 | 84,0 | 94,0 |
| 35 | 57,2 | 70,0 | 80,9 | 90,4 | 993,1 ⚠️ | 114,4 | 127,9 |

⚠️ *Valores provavelmente com erro de digitação no slide original (ex.: 1,03 e 505,5 fora da progressão da tabela). Conferir na fonte antes de usar.*

**Observação do slide:** é necessário construir dois sulcos transversais sem declividade para espalhar a água, após a derivação, em toda a largura da faixa.

---

## 5. Diques (taipas)

| Tipo | Base | Uso |
|---|---|---|
| Dique A – Temporário | 0,6 m | Controle de água temporário |
| Dique B – Permanente | 1,20 m | Maior base e estabilidade, uso permanente |
| Dique C – Permanente | 1,00 m | Maior base e estabilidade, uso permanente |

---

# Parte 2 – Avanço, balanço, infiltração e dimensionamento

## 6. Obtenção da fase de avanço e recessão (continuação)

### 6.1 Curvas de avanço e recessão

Conhecendo as curvas de avanço e de recessão (medidas no campo ou simuladas) e a equação de infiltração, pode-se determinar o perfil de infiltração e, consequentemente, os parâmetros de desempenho.

Curva de avanço:

$$
x = p \cdot t_a^{\,r}
$$

Curva de recessão:

$$
t_r = t_d + \frac{(t_r - t_d)}{L} \cdot x
$$

- **L:** comprimento total da faixa;
- **x:** comprimento parcial.

### 6.2 Parâmetros de desempenho

Eficiência de aplicação:

$$
E_a = \frac{(IRN \cdot X_a + Vd)}{Q_0 \cdot t_i} \cdot 100
$$

Perdas por percolação:

$$
P_p = \frac{(V_a - IRN \cdot X_a)}{Q_0 \cdot t_i} \cdot 100
$$

Perdas por escoamento:

$$
P_e = 100 - E_a - P_p
$$

Eficiência de armazenamento:

$$
E_r = \frac{(IRN \cdot X_a + Vd)}{IRN \cdot L} \cdot 100
$$

**Onde:**

- $E_a$ = eficiência de aplicação (%);
- $E_r$ = eficiência de armazenamento (%);
- $P_p$ = perdas por percolação (%);
- $P_e$ = perdas por escoamento (%);
- $IRN$ = irrigação real necessária (m³/m);
- $Q_0$ = vazão no início do sulco/faixa (m³/min);
- $t_i$ = tempo de aplicação de água no início do sulco/faixa (min);
- $V_a$ = volume de água infiltrada na região adequadamente irrigada (m³);
- $V_d$ = volume de água infiltrada na região deficientemente irrigada (m³).

### 6.3 Infiltração

Lâmina infiltrada acumulada (equação de Kostiakov-Lewis):

$$
I = k \cdot t_o^{\,a} + VIB \cdot t_o
$$

Volume infiltrado (regra dos trapézios, com $n$ intervalos):

$$
Vi = \frac{L}{2n}\left(I_0 + 2I_1 + \dots + I_n\right)
$$

---

## 7. Dimensionamento da irrigação por faixa

### Passo 2 – Vazão por unidade de largura no início da faixa, $Q_0$ (m³/min/m)

A vazão deve estar próxima da vazão máxima não erosiva. Hart et al. (1980) sugeriram:

$$
Q_{máx} = 0{,}01059 \cdot S_0^{-0{,}75}
$$

- Usar esse valor para solos com culturas que **não cobrem** toda a superfície;
- Usar **o dobro** desse valor para solos com culturas que **cobrem** toda a superfície.

Ou, de forma alternativa:

$$
Q_{máx} = \left( \frac{V_{máx}^{\,\rho_2} \cdot n^2}{3600 \cdot S_0 \cdot \rho_1} \right)^{1/(\rho_2 - 2)}
$$

Walker e Skogerboe (1984) consideram a equação anterior conservadora e sugerem que a **vazão de entrada deve ter um valor mínimo** estimado por:

$$
Q_{min} = 0{,}000357 \cdot L \cdot S_0^{\,0{,}5} \cdot n^{-1}
$$

- $Q_{min}$ em m³/min; $L$ em m; $S_0$ = declividade.

### Passo 3 – Comprimento da faixa

Arredondar o valor para o submúltiplo do comprimento da área imediatamente inferior:

$$
L \leq \frac{Q_{máx}}{VIB}
$$

### Passo 4 – Profundidade na entrada da faixa

$$
y_0 = \left( \frac{Q_0^2 \cdot n^2}{3600 \cdot S_0} \right)^{0{,}3}
$$

> ⚠️ Verificar se esse valor não excede a altura dos diques.

### Passo 5 – Tempo de oportunidade (Newton-Raphson, equação de Kostiakov-Lewis)

Equação a resolver: $I = k \cdot t_0^{\,a} + VIB \cdot t_0$

Procedimento:

1. Assumir um valor inicial: $t_{0(i)} = 100$ min.
2. Calcular o tempo de oportunidade corrigido:

$$
t_{0(i+1)} = t_{0(i)} - \frac{k \cdot t_{0(i)}^{\,a} + VIB \cdot t_{0(i)} - IRN}{k \cdot a \cdot t_{0(i)}^{\,a-1} + VIB}
$$

3. Se $|t_{0(i+1)} - t_{0(i)}| < 0{,}1$ min, o problema está resolvido ($t_0 = t_{0(i+1)}$). Caso contrário, faça $t_{0(i)} = t_{0(i+1)}$ e repita os passos 2 e 3.

### Passo 6 – Tempo de avanço

Usar a equação de avanço ajustada aos dados do teste de avanço feito diretamente no campo:

$$
x = p \cdot T_x^{\,r}
$$

Alternativamente, simulação pelo método do balanço volumétrico (abaixo).

---

## 8. Simulação do tempo de avanço (balanço volumétrico)

Reescrevendo a equação do balanço volumétrico para $X = L$ e $Q_0$ igual à vazão máxima não erosiva:

$$
Q_0 \, t_x = 0{,}77 \cdot A_0 \cdot L + \sigma_z \cdot k \cdot t_x^{\,a} \cdot L + \frac{VIB \cdot t_x \cdot L}{1 + r}
$$

Onde:

$$
\sigma_z = \frac{a + r(1 - a) + 1}{(1 + a)(1 + r)}
$$

$$
r = \frac{\ln(L_{máx}) - \ln(L_{méd})}{\ln(t_{x\,máx}) - \ln(t_{x\,méd})}
$$

> **Variáveis desconhecidas:** $t_x$ e $r$. Devem ser resolvidas numericamente pelo método de Newton, conforme o procedimento abaixo.

### Procedimento numérico

a) Assumir um valor inicial de $r$ entre 0,5 e 0,9, por exemplo $r_{(i)} = 0{,}7$.

b) Calcular $\sigma_z$ com a fórmula acima.

c) Calcular o tempo de avanço $t_x$ pelo método de Newton-Raphson:

i. Valor inicial:

$$
t_{x(i)} = 5{,}0 \cdot \frac{A_0 \cdot L}{Q_0}
$$

ii. Atualização:

$$
t_{x(i+1)} = T_{x(i)} - corr
$$

com

$$
corr = \frac{Q_0 t_{x(i)} - 0{,}77 A_0 L - \sigma_z k t_{x(i)}^{\,a} L - \dfrac{VIB \, t_{x(i)} L}{1 + r}}{Q_0 - \dfrac{\sigma_z \, a \, k \, L}{t_{x(i)}^{\,1-a}} - \dfrac{VIB \, L}{1 + r}}
$$

iii. Se o valor absoluto de $corr$ for desprezível, assumir $t_x = t_{x(i+1)}$ e prosseguir no item d. Caso contrário, definir $t_{x(i)} = t_{x(i+1)}$ e repetir os passos ii e iii.

> ⚠️ Se $Q_0$ for muito pequeno para o comprimento $L$, o procedimento não converge. Nesse caso, a vazão deve ser aumentada ou o comprimento reduzido.

> ℹ️ O slide cortou o item d do procedimento (o passo seguinte ao cálculo de $t_x$). Conferir a fonte para completar.

---

# Parte 3 – Conclusão da simulação do tempo de avanço e verificação da irrigação

## 9. Simulação do tempo de avanço (continuação do procedimento numérico)

### Item d – Tempo de avanço para a metade do comprimento ($t_{xméd}$)

Calcular $t_{xméd}$ para a distância $X = L/2$, usando o mesmo procedimento do passo c.

- **Solos em declive:** na equação de $corr$, substituir $L$ por $0{,}5\,L$ para o cálculo de $t_{xméd}$.
- **Solos em nível, irrigação por faixa ou inundação:** substituir também $A_0$ nas equações de $corr$ e de $Q_0 t_x$ pela equação da área molhada:

$$
A_0 = \left( \frac{Q_0^{\,2} \cdot n^2 \cdot X}{3600} \right)^{3/13}
$$

### Item e – Valor revisado de $r$

$$
r_{(i+1)} = \frac{\ln(2)}{\ln(t_x) - \ln(t_{xméd})}
$$

### Item f – Comparação de $r$

- **Se a diferença entre $r_{(i)}$ e $r_{(i+1)}$ for desprezível:** $t_x = t_{x(i+1)}$.
- **Caso contrário:** fazer $r_{(i)} = r_{(i+1)}$ e repetir os passos b a f.

### Item g – Tempo de recessão para aplicar a IRN no final da faixa

$$
t_r = t_i = t_o + t_a
$$

---

## 10. Item h – Tempo de depleção ($t_d$)

Procedimento iterativo:

i. Fazer $t_{d(i)} = t_r$.

ii. Calcular a velocidade de infiltração média:

$$
VIM = 0{,}5 \cdot a \cdot k \left[ t_{d(i)}^{\,a-1} + (t_{d(i)} - t_a)^{a-1} \right] + VIB
$$

iii. Calcular a vazão de saída, $S_y$:

$$
S_y = \left[ \frac{(Q_0 - VIM \cdot L)\, n}{60 \cdot S_0^{0{,}5}} \right]^{0{,}6} L^{-1} = y_f \cdot L^{-1}
$$

iv. Calcular o novo tempo de depleção:

$$
t_{d(i+1)} = t_r - \frac{0{,}095 \cdot n^{0{,}47565} \cdot S_y^{0{,}2072} \cdot L^{0{,}6829}}{VIM^{0{,}5243} \cdot S_0^{0{,}2378}}
$$

**Critério de parada:**

- Se $t_{d(i)} \neq t_{d(i+1)}$: fazer $t_{d(i)} = t_{d(i+1)}$ e repetir os passos ii a iv.
- Se $t_{d(i)} = t_{d(i+1)}$: $t_d = t_{d(i+1)}$.

---

## 11. Item i – Verificação da adequação da irrigação

Infiltração acumulada na entrada da faixa:

$$
I_o = k \cdot t_d^{\,a} + VIB \cdot t_d
$$

- Se $I_o > IRN$: a irrigação é **adequada** → $t_d > t_o$.
- Se $I_o < IRN$: a irrigação é **inadequada** → $t_d < t_o$.

---

## 12. Item j – Irrigação adequada: tempo de irrigação e eficiência de aplicação

Quando a irrigação é adequada:

$$
t_i = t_d - \frac{y_0 \cdot L}{2 \cdot Q_0}
$$

$$
E_a = \frac{IRN \cdot L}{Q_0 \cdot t_i} \cdot 100
$$

---

## 13. Item k – Irrigação inadequada

Quando $t_d < t_o$ (tempo de depleção menor que o tempo de oportunidade), proceder:

i. Fazer $t_d = t_0$ e recalcular o tempo de irrigação:

$$
t_i = t_d - \frac{y_0 \cdot L}{2 \cdot Q_0}
$$

ii. Calcular VIM, usando $t_0$ no lugar de $t_{d(i)}$:

$$
VIM = 0{,}5 \cdot a \cdot k \left[ t_{d(i)}^{\,a-1} + (t_{d(i)} - t_a)^{a-1} \right] + VIB
$$

iii. Calcular $S_y$:

$$
S_y = \left[ \frac{(Q_0 - VIM \cdot L)\, n}{60 \cdot S_0^{0{,}5}} \right]^{0{,}6} L^{-1} = y_f \cdot L^{-1}
$$

> ℹ️ O slide cortou após o item iii do item k. Conferir na fonte se há passos adicionais.

---

# Parte 4 – Fechamento da irrigação inadequada, eficiência, parcelas e dimensionamento final

## 14. Item k (continuação) – Irrigação inadequada

Após calcular $VIM$ e $S_y$ com $t_0$ (itens i a iii da seção 13):

iv. Determinar o tempo de recessão, utilizando $t_0$ no lugar de $t_{d(i+1)}$:

$$
t_{d(i+1)} = t_r - \frac{0{,}095 \cdot n^{0{,}47565} \cdot S_y^{0{,}2072} \cdot L^{0{,}6829}}{VIM^{0{,}5243} \cdot S_0^{0{,}2378}}
$$

v. Calcular a infiltração acumulada no final da faixa:

$$
I_f = K \,(t_r - t_a)^{a} + VIB\,(t_r - t_a)
$$

---

## 15. Item l – Eficiência de aplicação

$$
E_a = \frac{IRN \cdot L}{Q_0 \cdot t_i} \cdot 100
$$

### Item m – Otimização da vazão inicial

- A vazão inicial $Q_0$ deve ser decrescida de um $\Delta Q$ (por exemplo, 0,05 L/s), e o procedimento dos itens d) a l) deve ser repetido até que a **eficiência de aplicação seja maximizada**.
- Quando isso acontecer, têm-se os valores de:
  - vazão a ser aplicada no início da faixa, $Q_0$;
  - tempo de irrigação, $t_i$;
  - eficiência de aplicação, $E_a$.

---

## 16. Item n – Perdas e volume total infiltrado

Conhecendo as equações de avanço e de infiltração, e assumindo que o tempo de recessão varia linearmente de $t_d$ a $t_r$, pode-se obter o perfil de infiltração ao longo da faixa e, consequentemente, o volume total infiltrado.

Perdas por percolação:

$$
P_p = \frac{(V_a - IRN \cdot X_a)}{Q_0 \cdot t_i} \cdot 100
$$

Perdas por escoamento:

$$
P_e = 100 - E_a - P_p
$$

---

## 17. Dimensionamento da área e do conjunto de parcelas

### Tempo de irrigação por parcela (TIP)

Considera o tempo necessário para mudar o sistema de distribuição de água para outra parcela ($t_{mu}$):

$$
TIP = t_i + t_{mu}
$$

### Número de parcelas irrigadas por dia (NPD)

Calculado para uma jornada de trabalho diária (TDF):

$$
NPD = \frac{TDF}{TIP}
$$

### Área irrigada por parcela (APP)

Depende da largura ($W_t$) e do comprimento ($L_t$) da área total irrigada e do período de irrigação (PI):

$$
APP = \frac{W_t \cdot L_t}{NPD \cdot PI}
$$

### Largura da faixa ($W_0$) e número de faixas por parcela (NFP)

$$
W_0 = \frac{APP}{NFP \cdot L}
$$

> A largura da faixa deve ser um submúltiplo da largura da área, para que todas as faixas tenham a mesma largura. Além disso, a largura da faixa depende da declividade transversal, como abordado anteriormente.

### Número total de faixas (NTF)

$$
NTF = NFP \cdot NPD \cdot PI
$$

---

## 18. Vazão total do projeto

$$
Q_t = NFP \cdot W_0 \cdot Q_0
$$

---

## Resumo das variáveis novas desta parte

| Símbolo | Significado |
|---|---|
| $TIP$ | Tempo de irrigação por parcela (min) |
| $t_{mu}$ | Tempo para mudar o sistema de distribuição para outra parcela |
| $TDF$ | Jornada de trabalho diária |
| $NPD$ | Número de parcelas irrigadas por dia |
| $APP$ | Área irrigada por parcela |
| $W_t$, $L_t$ | Largura e comprimento da área total irrigada |
| $PI$ | Período de irrigação |
| $NFP$ | Número de faixas por parcela |
| $W_0$ | Largura da faixa |
| $NTF$ | Número total de faixas |
| $Q_t$ | Vazão total necessária no projeto |

> ℹ️ Os slides não definem explicitamente $K$ no item v do item k (aparece como $K$ maiúsculo, enquanto nas demais fórmulas aparece $k$ minúsculo). Pode ser apenas notação; conferir na fonte.
> ℹ️ No item o, o slide não detalha o significado de $L$ na fórmula de $W_0$ (presumivelmente o comprimento da faixa). Conferir na fonte.
