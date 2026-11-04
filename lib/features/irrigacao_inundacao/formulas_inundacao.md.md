# Fórmulas extraídas das imagens

## Tamanho do tabuleiro (slide 17)

Relação de Henderson (1965) entre vazão disponível, área dos tabuleiros e velocidade de infiltração básica do solo:

$$A = 100 \frac{Q}{VIB}$$

Onde:
- $A$ = área dos tabuleiros, em m²
- $Q$ = vazão disponível, em m³/h
- $VIB$ = velocidade de infiltração básica do solo, em mm/h

## Construção dos tabuleiros (slide 34)

Condição de altura da água no tabuleiro:

$$Z < \frac{2}{3} L_m$$

Largura média do canal:

$$L_m = \frac{L_i + L_f}{2}$$

Onde:
- $Z$ = desnível considerado
- $L_i$ = largura inicial
- $L_f$ = largura final
- $L_m$ = largura média

## Dimensionamento de bacias de irrigação por superfície (slides 44 a 48)

Considera apenas bacias ou tabuleiros de forma geométrica regular, com escoamento em uma única direção. São feitas três suposições.

### Declividade da superfície líquida (1ª suposição)

$$S_0 = S_f = \frac{y_0}{X} \qquad (1)$$

Onde:
- $S_0$ = declividade da superfície líquida, em m/m
- $S_f$ = declividade da superfície líquida, em m/m
- $y_0$ = profundidade no início da bacia, em m
- $X$ = distância do início da bacia até a frente de avanço, em m

### Profundidade no início da bacia (substituindo (1) na equação de Manning)

$$y_0 = \left\{ \frac{Q_0^2 \, n^2 \, X}{3600} \right\}^{0,23} \qquad (2)$$

Onde:
- $Q_0$ = vazão na entrada da área, em m³/min/m
- $n$ = coeficiente de Manning (não definido nas imagens)
- $X$ = distância do início da bacia até a frente de avanço, em m

### Infiltração acumulada no início da área (2ª suposição)

Quando a vazão na entrada é cortada, a superfície líquida fica horizontal e a lâmina infiltra verticalmente. Assim, a lâmina infiltrada ao longo da bacia é igual à infiltrada durante a fase de avanço mais a lâmina aplicada após a fase de avanço.

$$I_0 = k \, t_a^{a} + VIB \, t_a + 0{,}80 \, y_0 + Q_0 (t_i - t_a) \, L^{-1} \qquad (3)$$

Onde:
- $I_0$ = infiltração acumulada no início da área
- $k$ e $a$ = parâmetros da equação de infiltração (não definidos nas imagens)
- $t_a$ = tempo de avanço (não definido nas imagens)
- $VIB$ = velocidade de infiltração básica, em mm/h
- $y_0$ = profundidade média da água durante o tempo de avanço (terceiro termo)
- $Q_0$ = vazão na entrada da área
- $t_i$ = tempo de irrigação (não definido nas imagens)
- $L$ = comprimento da bacia (não definido nas imagens)

Interpretação dos termos, segundo os slides:
- Os dois primeiros termos correspondem à infiltração ocorrida durante a fase de avanço.
- O terceiro termo é a profundidade média da água durante o tempo de avanço.

### Tempo de irrigação (3ª suposição)

A dimensão é feita para aplicar a irrigação real necessária (IRN) no final da bacia, onde se tem a menor lâmina aplicada. Na equação (3), faz-se $I_0 = IRN$ e resolve-se para $t_i$:

$$t_i = \frac{IRN \cdot L - 0{,}8 \cdot y_0 \cdot L}{Q_0} + t_a \qquad (4)$$

Onde:
- $t_i$ = tempo de irrigação
- $IRN$ = irrigação real necessária
- $L$ = comprimento da bacia
- $y_0$ = profundidade no início da bacia
- $Q_0$ = vazão na entrada da área
- $t_a$ = tempo de avanço

## Procedimento para o dimensionamento da irrigação por inundação intermitente (slides 52 a 62)

### Vazão máxima não erosiva (passo b)

$$Q_{0max} = \left( \frac{V_{max}^{13/3} \, n^2 \, L}{3600} \right)^{3/7} \qquad (5)$$

Onde:
- $Q_{0max}$ = vazão máxima não erosiva, em m³/m/min
- $V_{max}$ = velocidade máxima não erosiva (não definida nas imagens)
- $n$ = coeficiente de rugosidade de Manning
- $L$ = comprimento da bacia

### Balanço volumétrico para simulação do tempo de avanço (passo c)

$$Q_0 t_x = 0{,}77 \, A_0 \, L + \sigma_z \, k \, t_x^{a} \, L + \frac{VIB \, t_x \, L}{1 + r} \qquad (6)$$

Onde $\sigma_z$ é dado pela equação (7) e $r$ pela equação (8).

$$\sigma_z = \frac{a + r(1 - a) + 1}{(1 + a)(1 + r)} \qquad (7)$$

$$r = \frac{\ln(L_{máx}) - \ln(L_{méd})}{\ln(t_{xmáx}) - \ln(t_{xméd})} \qquad (8)$$

Onde:
- $t_x$ = tempo de avanço
- $A_0$ = área da seção transversal do escoamento no início (ver equação 12)
- $a$ e $k$ = parâmetros da equação de infiltração (não definidos nas imagens)
- $L_{máx}$, $L_{méd}$, $t_{xmáx}$ e $t_{xméd}$ = valores máximos e médios de comprimento e tempo de avanço (não definidos nas imagens)

### Solução numérica pelo método de Newton-Raphson (passo c)

Chute inicial:

$$t_{x(i)} = 5{,}0 \, \frac{A_0 \, L}{Q_0} \qquad (9)$$

Atualização:

$$t_{x(i+1)} = t_{x(i)} - corr \qquad (10)$$

Correção:

$$corr = \frac{Q_0 t_x - 0{,}77 A_0 L - \sigma_z k \, t_{x(i)}^{a} \, L - \dfrac{VIB \, t_{x(i)} \, L}{1 + r}}{Q_0 - \dfrac{\sigma_z \, a \, k \, L}{t_{x(i)}^{1-a}} - \dfrac{VIB \, L}{1 + r}} \qquad (11)$$

Critério: se o valor absoluto de $corr$ for desprezível, adota-se $t_x = t_{x(i+1)}$. Caso contrário, faz-se $t_{x(i)} = t_{x(i+1)}$ e repetem-se os passos ii e iii. Se $Q_0$ for muito pequeno para o comprimento $L$, o procedimento não converge, indicando que a vazão deve ser aumentada ou o comprimento reduzido.

### Área molhada (solos em nível, passo 4)

$$A_0 = \left( \frac{Q_0^2 \, n^2 \, X}{3600} \right)^{3/13} \qquad (12)$$

### Revisão de r (passo 5)

$$r_{(i+1)} = \frac{\ln(2)}{\ln(t_x) - \ln(t_{xméd})} \qquad (13)$$

Para o cálculo de $t_{xméd}$ (passo 4), em solos em declive substitui-se $L$ por $0{,}5\,L$ na equação (10). Em solos em nível, em irrigação por faixa ou inundação, substitui-se também $A_0$ pela equação (12).

### Eficiência de aplicação (passo e)

$$E_a = \frac{IRN \cdot L}{Q_0 \, t_i} \cdot 100 \qquad (14)$$

Onde $E_a$ é a eficiência de aplicação, em %.

### Largura do tabuleiro (passo g)

$$W_0 = \frac{APP}{NTP \cdot L} \qquad (15)$$

Onde:
- $W_0$ = largura do tabuleiro
- $APP$ = área mínima por parcela (equação 20)
- $NTP$ = número de tabuleiros por parcela
- $L$ = largura

### Número total de tabuleiros

$$NTT = NTP \cdot NPD \cdot PI \qquad (16)$$

### Vazão total necessária

$$Q = W_0 \cdot NTP \cdot Q_0 \qquad (17)$$

### Tempo de irrigação por parcela

$$TPP = t_i + t_m \qquad (18)$$

Onde $t_m$ é o tempo de manejo (não definido nas imagens).

### Número de parcelas irrigadas por dia

$$NPD = \frac{TDF}{TPP} \qquad (19)$$

Onde $TDF$ é o tempo de funcionamento por dia.

### Área por parcela

Como o período de irrigação é de um dia, a área mínima por parcela é:

$$APP = \frac{\text{área total}}{NPD \cdot PI} \qquad (20)$$

Onde $PI$ é um parâmetro do projeto (não definido nas imagens).

## Dimensionamento de irrigação por inundação contínua (slides 64 a 69)

### Vazão necessária para o enchimento dos tabuleiros (1)

$$Q_e = 0{,}116 \left( \phi Z + L_m + ET_{pc} \, TR + K_0 \, TR \right) \frac{A}{TR} \qquad (1)$$

Com o turno de rega dado por:

$$TR = \frac{DTA \cdot f \cdot Z}{ETc}$$

Onde:
- $Q_e$ = vazão necessária para o enchimento dos tabuleiros, em L/s
- $\phi$ = porosidade do solo, decimal
- $Z$ = profundidade do solo, em mm
- $L_m$ = lâmina média na superfície do solo, em mm
- $ET_{pc}$ = evapotranspiração potencial da cultura, em mm/dia
- $TR$ = turno de rega, em dias
- $K_0$ = condutividade hidráulica do solo saturado, em mm/dia
- $A$ = área irrigada, em ha
- $DTA$, $f$ e $ETc$ = termos do cálculo do turno de rega (não definidos nas imagens)

### Vazão de manutenção (2)

Após o enchimento do tabuleiro, a vazão necessária, chamada vazão de manutenção ($Q_m$), corresponde às perdas por percolação mais a evapotranspiração:

$$Q_m = 0{,}116 \left( ET_{pc} + K_0 \right) A \qquad (2)$$

### Eficiência de condução (3)

Reflete a perda de água entre a captação e a parcela de irrigação:

$$E_c = \frac{Q_m}{Q_d} \cdot 100 \qquad (3)$$

Onde:
- $E_c$ = eficiência de condução, em %
- $Q_m$ = vazão de manutenção, em L/s
- $Q_d$ = vazão derivada da fonte de água, em L/s

### Eficiência de aplicação (4)

$$E_a = \frac{L_{es}}{L_{as}} \cdot 100 \qquad (4)$$

Onde:
- $E_a$ = eficiência de aplicação, em %
- $L_{es}$ = lâmina evapotranspirada por semana, em mm (estimada com tanque Classe A instalado ao lado do tabuleiro)
- $L_{as}$ = lâmina aplicada por semana, em mm

### Lâmina aplicada por semana (5)

$$L_{as} = \frac{Q_m \cdot t_i}{A} \cdot 3600 \qquad (5)$$

Onde:
- $Q_m$ = vazão de manutenção, em L/s
- $A$ = área do projeto, em m²
- $t_i$ = tempo de irrigação, em h
