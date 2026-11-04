# Equações de Avanço e Infiltração (Irrigação por Sulcos)

Extraído das prints do PDF. Valores e fórmulas mantidos como no original, com notas onde houve divergência.

---

## 1. Função de avanço

### 1.1 Equação potencial

$$
T_x = k \cdot x^{b}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `x` | Distância atingida pela frente de avanço | m |
| `T_x` | Tempo de avanço até o ponto x | min |
| `k`, `b` | Parâmetros de ajuste | - |

### 1.2 Linearização (coordenadas logarítmicas)

$$
\log T_x = \log k + b \cdot \log x
$$

Se `T_x` versus `x` em escala log-log resultar em uma reta, a equação tem forma potencial.

---

## 2. Estimativa dos parâmetros

### 2.1 Método dos dois pontos

Usa o tempo para metade do comprimento da parcela (`T_0,5x`) e o tempo para o comprimento total (`T_x`).

$$
b = \frac{\ln(T_{0,5x}) - \ln(T_x)}{\ln(0,5)}
$$

$$
k = \frac{T_x}{x^{b}}
$$

**Observação do PDF:** se não houver valor médio tabelado, fazer interpolação.

**Exemplo do PDF (dados da tabela de avanço):**

| Dado | Valor |
|---|---|
| `x` (comprimento total) | 200 m |
| `T_x` (tempo total) | 93,5 min |
| `T_0,5x` (tempo para 100 m) | 37,9 min |

- `b = (ln(37,9) − ln(93,5)) / ln(0,5) = 1,30`
- `k = 93,5 / 200^1,30 = 0,095`
- **Resultado:** `T_x = 0,095 · x^1,30`

### 2.2 Método dos mínimos quadrados

Modelo linearizado:

$$
Y_i = A + b \cdot X_i
$$

com `X_i = log x_i`, `Y_i = log T_xi` e `A = log k`.

Para minimizar a soma dos quadrados dos desvios, igualam-se a zero as derivadas parciais ∂SQD/∂A e ∂SQD/∂b. No slide, a fórmula do intercepto aparece como `a = ȳ − n · x̄`, em que `n` é o coeficiente angular (equivalente a `b` aqui).

Fórmulas (N = número de pares válidos):

$$
b = \frac{\sum(xy) - \dfrac{\sum x \sum y}{N}}{\sum x^2 - \dfrac{(\sum x)^2}{N}}
$$

$$
a = \bar{y} - b \cdot \bar{x}
$$

$$
k = 10^{A}
$$

**Atenção para código:** `log(0)` é indefinido. O ponto de distância 0 / tempo 0 da tabela de avanço deve ser descartado antes do ajuste.

**Exemplo do PDF (tabela de avanço, estacas 0 a 10):**

| Estaca | Distância x (m) | Tempo de avanço T_x (min) |
|---|---|---|
| 0 | 0 | 0 (excluída do ajuste) |
| 1 | 20 | 5 |
| 2 | 40 | 10,5 |
| 3 | 60 | 19,2 |
| 4 | 80 | 30 |
| 5 | 100 | 37,9 |
| 6 | 120 | 48 |
| 7 | 140 | 60,5 |
| 8 | 160 | 68 |
| 9 | 180 | 81,3 |
| 10 | 200 | 93,5 |

Resultados do PDF:

- Dois pontos (x = 200 m, T_x = 93,5 min, T_0,5x = 37,9 min): `T_x = 0,095 · x^1,30`
- Regressão (gráfico, mínimos quadrados em log-log): `T_x = 0,0978 · x^1,2944`

Não há soma detalhada no PDF para a regressão.

---

## 3. Equação de infiltração: método da entrada e saída

### 3.1 Dados tabelados

Colunas: tempo `T` (min), vazão na estaca 0 e na estaca 5 (L/s, 100 m), infiltração (L/s·100m e mm/h).

| Tempo (min) | Estaca 0 (L/s) | Estaca 5 (L/s) | Infiltração (L/s·100m) | Infiltração (mm/h) |
|---|---|---|---|---|
| 0 | 1 | 0 | - | - |
| 2 | 1 | 0,19 | 0,81 | 29,2 |
| 9 | 1 | 0,50 | 0,50 | 18,0 |
| 19 | 1 | 0,63 | 0,37 | 13,3 |
| 29 | 1 | 0,66 | 0,34 | 12,2 |
| 49 | 1 | 0,71 | 0,29 | 10,4 |
| 64 | 1 | 0,73 | 0,27 | 9,7 |
| 79 | 1 | 0,75 | 0,25 | 9,0 |
| 89 | 1 | 0,76 | 0,24 | 8,6 |
| 101 | 1 | 0,77 | 0,23 | 8,3 |
| 119 | 1 | 0,78 | 0,22 | 7,9 |
| 149 | 1 | 0,78 | 0,22 | 7,9 |

Cálculos linha a linha (`x = log T`, `y = log VI` usando a coluna L/s·100m, conforme a tabela do PDF):

| Tempo T (min) | x = log T | y = log VI | x·y | x² |
|---|---|---|---|---|
| 2 | 0,30 | −0,09 | −0,03 | 0,09 |
| 9 | 0,95 | −0,30 | −0,29 | 0,91 |
| 19 | 1,28 | −0,43 | −0,55 | 1,64 |
| 29 | 1,46 | −0,47 | −0,69 | 2,14 |
| 49 | 1,69 | −0,54 | −0,91 | 2,86 |
| 64 | 1,81 | −0,57 | −1,03 | 3,26 |
| 79 | 1,90 | −0,60 | −1,14 | 3,60 |
| 89 | 1,95 | −0,62 | −1,21 | 3,80 |
| 101 | 2,00 | −0,64 | −1,28 | 4,02 |
| 119 | 2,08 | −0,66 | −1,36 | 4,31 |
| 149 | 2,17 | −0,66 | −1,43 | 4,72 |
| **Soma** | 17,59 | −5,57 | −9,91 | 31,34 |
| **Média** | 1,60 | −0,51 | −0,90 | 2,85 |

### 3.2 Somatórios do PDF

| Grandeza | Valor |
|---|---|
| Σx | 17,59 |
| Σy | −5,57 |
| Σxy | −9,91 |
| Σx² | 31,34 |
| N (linhas com dados) | 11 |
| x̄ (média) | 1,60 |
| ȳ (média) | −0,51 |

### 3.3 Coeficiente angular (`n` ou `b`)

Fórmula de mínimos quadrados aplicada com os somatórios acima:

$$
n = \frac{\sum(xy) - \dfrac{\sum x \sum y}{N}}{\sum x^2 - \dfrac{(\sum x)^2}{N}}
$$

**Resultado do PDF:** `n = −0,32`

**Resultado recalculado com N = 11 (ver seção 5):** `n ≈ −0,312`

### 3.4 Intercepto (`a`)

$$
a = \bar{y} - n \cdot \bar{x}
$$

**Resultado do PDF:** `a = 1,546` (ver seção 5, o cálculo mostrado não reproduz esse valor)

**Recalculado com os valores de média e N = 11:** `a ≈ −0,007`

### 3.5 Constante `k`

$$
k = 10^{a}
$$

- **PDF:** `K = 10^1,546 = 35,23`

### 3.6 Equação final

$$
VI = 35{,}23 \cdot T^{-0{,}32}
$$

**Regressão (gráfico do PDF):** `I = 35,203 · x^−0,311`

---

## 4. Implementação de referência (Python)

```python
import math


def ajuste_dois_pontos(t_meio: float, t_total: float, x_total: float) -> tuple[float, float]:
    """
    Método dos dois pontos para T_x = k * x^b.

    t_meio:  T_0,5x, tempo de avanço para metade do comprimento
    t_total: T_x, tempo de avanço para o comprimento total
    x_total: comprimento total x (m)

    Retorna (k, b).
    """
    b = (math.log(t_meio) - math.log(t_total)) / math.log(0.5)
    k = t_total / (x_total ** b)
    return k, b


def ajuste_minimos_quadrados(x: list[float], t: list[float]) -> tuple[float, float]:
    """
    Mínimos quadrados em escala log10 para T = k * x^b.
    Pontos com x <= 0 ou t <= 0 devem ser removidos antes.

    Retorna (k, b).
    """
    pares = [(xi, ti) for xi, ti in zip(x, t) if xi > 0 and ti > 0]
    X = [math.log10(xi) for xi, _ in pares]
    Y = [math.log10(ti) for _, ti in pares]
    N = len(X)

    sx = sum(X)
    sy = sum(Y)
    sxy = sum(xi * yi for xi, yi in zip(X, Y))
    sxx = sum(xi * xi for xi in X)

    b = (sxy - sx * sy / N) / (sxx - sx ** 2 / N)
    A = (sy - b * sx) / N  # equivalente a ybar - b * xbar
    k = 10 ** A
    return k, b


def ajuste_infiltracao_entrada_saida(tempos: list[float], infiltracao: list[float]) -> tuple[float, float]:
    """
    Ajuste VI = k * T^n (método entrada e saída).
    Usa log10 de T e log10 de VI. Remove T = 0.

    Retorna (k, n).
    """
    pares = [(t, v) for t, v in zip(tempos, infiltracao) if t > 0 and v > 0]
    X = [math.log10(t) for t, _ in pares]
    Y = [math.log10(v) for _, v in pares]
    N = len(X)

    sx = sum(X)
    sy = sum(Y)
    sxy = sum(xi * yi for xi, yi in zip(X, Y))
    sxx = sum(xi * xi for xi in X)

    n = (sxy - sx * sy / N) / (sxx - sx ** 2 / N)
    a = (sy - n * sx) / N
    k = 10 ** a
    return k, n
```

---

## 5. Divergências encontradas no PDF

Essas inconsistências afetam o resultado final da infiltração. Verifique antes de usar os números em produção.

1. **Número de pontos (N):** a tabela tem 11 linhas com dados (tempos 2 a 149), mas o slide informa N = 10. As médias (x̄ = 1,60 e ȳ = −0,51) só batem com N = 11 (17,59/11 e −5,57/11). Com N = 11, o coeficiente angular fica `n ≈ −0,312`, em vez de −0,32. Esse valor bate com o gráfico de regressão (−0,311).

2. **Cálculo do intercepto:** a conta mostrada no slide é `−0,51 − (−0,32) · 1,60`, que dá `≈ 0,002`, e não `1,546`. O valor 1,546 corresponde ao log de 35,2, que vem do gráfico de regressão, não do cálculo mostrado.

3. **Unidade da variável y:** a coluna `y = log VI` usa a infiltração em L/s·100m, não em mm/h. Por isso o intercepto calculado é próximo de zero (≈ −0,007, ou seja, k ≈ 0,98 em L/s·100m). Para obter a equação em mm/h, multiplique por 36 (conversão 1 L/s·100m = 36 mm/h, válida pela razão entre as colunas do PDF). Isso resulta em `VI ≈ 35,3 · T^−0,31`, consistente com o gráfico (`35,203 · x^−0,311`).

4. **Equação final:** o PDF usa expoente −0,32 e coeficiente 35,23. O gráfico usa −0,311 e 35,203. Os valores são muito próximos, mas não são idênticos, e a diferença vem dos itens 1 e 2.

5. **Método dos dois pontos (exemplo):** conferido e consistente. `b = 1,30`, `k = 0,095`.

---

## 6. Resumo rápido de variáveis

| Variável | Descrição | Unidade |
|---|---|---|
| `x` | Distância da frente de avanço | m |
| `T_x` | Tempo de avanço até x | min |
| `T_0,5x` | Tempo de avanço até metade do comprimento | min |
| `k`, `b` | Parâmetros da função de avanço | - |
| `T` | Tempo de infiltração (entrada e saída) | min |
| `VI` | Velocidade/taxa de infiltração | mm/h |
| `n` ou `b` | Expoente da equação de infiltração | - |
| `a` ou `A` | Intercepto em log10 | - |
| `N` | Número de pontos válidos | - |

---

## 7. Infiltração acumulada

### 7.1 Conversão de infiltração instantânea para acumulada

Com `VI = K · T^n` (VI em mm/h, T em min):

$$
I = \frac{K}{n + 1} \cdot T^{n+1}
$$

Como VI está em mm/h e T em min, a conversão para mm exige dividir por 60:

$$
I = \frac{K}{60\,(n+1)} \cdot T^{n+1}
$$

**Resultados do PDF:**

- Com `K = 35,23` e `n = −0,32`: `I = 35,23 / ((−0,32 + 1) · 60) · T^0,68`, que o slide apresenta como `I = 0,85 · T^0,68`.
- Resultado final apresentado: `I = 0,85 · T^0,68`.

**Observação:** com os valores do slide (K = 35,23, n = −0,32), a conta dá `35,23 / 40,8 ≈ 0,86`, não 0,85. O valor 0,85 bate com os parâmetros da regressão do gráfico (K = 35,203, n = −0,311), onde `35,203 / (0,689 · 60) ≈ 0,851`.

### 7.2 Resultado final (PDF)

| Tipo | Equação |
|---|---|
| Infiltração instantânea | `VI = 35,23 · T^−0,32` |
| Infiltração acumulada | `I = 0,85 · T^0,68` |

---

## 8. Processo de reposição

### 8.1 Tempo de oportunidade de infiltração no ponto i

$$
T_{o(i)} = T_c - T_{x(i)} + T_d + T_{rec(i)}
$$

Tempo de reposição (com `T_x` = tempo de avanço até o comprimento total da parcela):

$$
T_r = T_c - T_x
$$

| Símbolo | Significado |
|---|---|
| `T_o(i)` | Tempo de oportunidade no ponto i |
| `T_c` | Tempo de corte (ou de irrigação) |
| `T_x(i)` | Tempo de avanço até o ponto i |
| `T_d` | Tempo de drenagem |
| `T_rec(i)` | Tempo de recessão no ponto i |
| `T_r` | Tempo de reposição |

Nota: o PDF não define `T_c`, `T_d` e `T_rec(i)`. As descrições acima são inferidas do contexto e devem ser confirmadas.

---

## 9. Dimensionamento do sulco

### 9.1 Tempo de avanço máximo (Criddle, regra prática)

$$
T_a = \frac{1}{4} T_o
$$

Usada para definir o comprimento máximo `L` do sulco.

### 9.2 Vazão máxima não erosiva

Forma geral (Criddle, 1956):

$$
q_{max} = \frac{c}{S_0^{\,a}}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `q_max` | Vazão máxima não erosiva | L/s |
| `S_0` | Declividade do sulco | % |
| `c`, `a` | Parâmetros do tipo de solo | - |

Parâmetros por textura (Hamad e Stringham, 1978):

| Textura | c | a |
|---|---|---|
| Muito fina | 0,892 | 0,937 |
| Fina | 0,988 | 0,550 |
| Média | 0,613 | 0,733 |
| Grossa | 0,644 | 0,704 |
| Muito grossa | 0,665 | 0,548 |

Forma prática e simplificada:

$$
q_{max} = \frac{0{,}631}{S}
$$

onde `S` é a declividade do sulco (%) e `q_max` em L/s.

**Faixa usual de vazão colocada no sulco:** 0,5 a 2 L/s, com valor comum de 1,0 L/s. A vazão adotada não deve ultrapassar `q_max`.

### 9.3 Geometria típica do sulco (em V)

| Parâmetro | Valor típico |
|---|---|
| Largura (topo) | 20 a 30 cm (média) |
| Profundidade | 15 a 25 cm (média) |

### 9.4 Fatores a considerar e geometria

Fatores a considerar no dimensionamento:

- Tamanho e forma da área
- Tipo de solo
- Vazão
- Declividade do solo
- Mão de obra
- Perda de área de cultivo
- Dificuldades de mecanização
- Perdas por percolação e escoamento

A geometria do sulco depende da cultura a ser irrigada (mais comum em V).

---

## 10. Lâmina de irrigação

### 10.1 Lâmina média aplicada (vazão constante)

$$
L_m = \frac{T_t \cdot q_c}{C \cdot L} \cdot 3600
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `L_m` | Lâmina média aplicada por sulco | mm |
| `T_t` | Tempo total de aplicação de água por sulco | h |
| `q_c` | Vazão constante aplicada por sulco | L/s |
| `C` | Comprimento do sulco | m |
| `L` | Largura da faixa umedecida por sulco (para sulcos próximos, é o espaçamento entre sulcos) | m |

**Exemplo do PDF:** `Lm = (3,33 · 1) / (200 · 1) · 3600 = 60 mm`

Premissas do PDF para vazão constante: a lâmina infiltrada no final do sulco (`L_f`) deve ser igual à lâmina real de irrigação a ser aplicada. A lâmina infiltrada no início (`L_i`) é obtida pela curva ou equação de infiltração acumulada (seção 7).

### 10.2 Lâmina média aplicada (com redução de vazão)

$$
L_m = \frac{(T_t - T_r) \cdot q_i + T_r \cdot q_r}{C \cdot L} \cdot 3600
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `T_t` | Tempo total de aplicação | h |
| `T_r` | Tempo de aplicação da vazão reduzida | h |
| `q_i` | Vazão inicial | L/s |
| `q_r` | Vazão reduzida | L/s |

**Nota do PDF:** para facilitar o manejo no campo, `T_r` deve ser múltiplo de `T_t`.

### 10.3 Lâmina média infiltrada

$$
L_{mi} = \frac{\sum_{i=1}^{n} y_i}{n} = \frac{L_i + L_f}{2}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `L_mi` | Lâmina média infiltrada no sulco | mm |
| `y_i` | Lâmina infiltrada na estaca i | mm |
| `n` | Total de estacas (de 10 em 10 m) | - |
| `L_i` | Lâmina aplicada no início do sulco | mm |
| `L_f` | Lâmina aplicada no final do sulco | mm |

---

## 11. Eficiências e indicadores

### 11.1 Eficiência de condução (Ec)

$$
E_c = \frac{V_a}{V_d} \cdot 100
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `E_c` | Eficiência de condução | % |
| `V_a` | Volume de água aplicado na área | m³ |
| `V_d` | Volume de água derivado do reservatório para irrigação | m³ |

Importante em projetos com bombeamento na fonte de derivação, regiões onde a água é fator limitante e projetos com grande distância entre fonte e área irrigada.

### 11.2 Eficiência de distribuição (Ed)

$$
E_d = \frac{L_f}{\left(\dfrac{L_i + L_f}{2}\right)} \cdot 100
$$

- Em condições corretas, `E_d > 70%`, exceto em solos muito permeáveis.
- Em irrigação por sulcos, Ed é menos importante que Ea.

### 11.3 Eficiência de aplicação (Ea)

$$
E_a = \frac{L_f}{L_m} \cdot 100
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `E_a` | Eficiência de aplicação | % |
| `L_f` | Lâmina infiltrada no final do sulco | mm |
| `L_m` | Lâmina média aplicada por sulco | mm |

- Valor mínimo aceitável: **60%**
- Considerado ideal: **acima de 70%**

### 11.4 Grau de adequação (GA)

$$
GA = \frac{\text{lâmina infiltrada útil}}{\text{lâmina requerida}} \cdot 100
$$

Interpretação:

- `GA = 100%`: irrigação perfeita (ideal, mas raro)
- `GA < 100%`: déficit de água (parte da área recebeu menos do que precisava)
- `GA > 100%`: excesso de água (perdas por percolação profunda)

### 11.5 Perdas

Perdas por percolação profunda:

$$
P_p = \frac{L_{mi} - LL}{L_m} \cdot 100
$$

Perdas por escoamento superficial:

$$
P_e = \frac{L_m - L_{mi}}{L_m} \cdot 100
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `LL` | Lâmina líquida necessária | mm |
| `L_mi` | Lâmina média infiltrada no sulco | mm |
| `L_m` | Lâmina média aplicada em cada sulco | mm |

Limites do PDF: `Pp` até 15% (aceitável); `Pe` até 10%.

---

## 12. Implementação de referência (complemento em Python)

```python
import math


def infiltracao_acumulada(K: float, n: float, T_min: float) -> float:
    """
    I (mm) = K / (60 * (n + 1)) * T^(n+1), com VI em mm/h e T em min.
    """
    return K / (60 * (n + 1)) * T_min ** (n + 1)


def qmax_nao_erosiva(S_percent: float, c: float | None = None, a: float | None = None) -> float:
    """
    Vazão máxima não erosiva (L/s).
    Sem c e a: forma simplificada 0,631 / S.
    Com c e a: forma geral c / S^a (Criddle, 1956).
    """
    if c is None or a is None:
        return 0.631 / S_percent
    return c / S_percent ** a


def lamina_media_vazao_constante(Tt_h: float, qc: float, C: float, L: float) -> float:
    """Lm (mm) com vazão constante."""
    return Tt_h * qc / (C * L) * 3600


def lamina_media_com_reducao(Tt_h: float, Tr_h: float, qi: float, qr: float, C: float, L: float) -> float:
    """Lm (mm) com redução de vazão."""
    return ((Tt_h - Tr_h) * qi + Tr_h * qr) / (C * L) * 3600


def lamina_media_infiltrada(lamina_estacas: list[float] | None = None, Li: float | None = None, Lf: float | None = None) -> float:
    """Lmi (mm): média das estacas, ou (Li + Lf) / 2 se só os extremos forem conhecidos."""
    if lamina_estacas:
        return sum(lamina_estacas) / len(lamina_estacas)
    return (Li + Lf) / 2


def eficiencia_conducao(Va: float, Vd: float) -> float:
    return Va / Vd * 100


def eficiencia_distribuicao(Li: float, Lf: float) -> float:
    return Lf / ((Li + Lf) / 2) * 100


def eficiencia_aplicacao(Lf: float, Lm: float) -> float:
    return Lf / Lm * 100


def grau_adequacao(lamina_util: float, lamina_requerida: float) -> float:
    return lamina_util / lamina_requerida * 100


def perda_percolacao(Lmi: float, LL: float, Lm: float) -> float:
    return (Lmi - LL) / Lm * 100


def perda_escoamento(Lm: float, Lmi: float) -> float:
    return (Lm - Lmi) / Lm * 100
```

---

## 13. Divergências adicionais

1. **Infiltração acumulada:** o slide apresenta `I = 0,85 · T^0,68`, mas com K = 35,23 e n = −0,32 a conta dá 0,86. O 0,85 é consistente com a regressão (K = 35,203, n = −0,311).
2. **Lâmina média aplicada (exemplo):** o resultado de 60 mm está correto (`3,33 / 200 · 3600 ≈ 59,9`, arredondado para 60).
3. **Eficiências:** as fórmulas de Ea e Ed usam `L_f` e `L_i`. Ao calcular, não esqueça de converter para a mesma unidade (mm) usada na lâmina média.

---

## 14. Exemplo resolvido: lâminas, eficiências e perdas

Dados do exemplo (sulco de C = 200 m, L = 1 m, Tt = 3,33 h, qc = 1 L/s):

| Grandeza | Valor | Origem |
|---|---|---|
| Lâmina média aplicada `Lm` | 60 mm | Seção 10.1 |
| Lâmina infiltrada no final `Lf` | 30,0 mm | Dado do exemplo |
| Lâmina infiltrada no início `Li` | 31,2 mm | `I = 0,85 · 200^0,68` |

### 14.1 Lâminas

Lâmina no início do sulco, usando a equação acumulada (seção 7):

$$
L_i = 0{,}85 \cdot 200^{0{,}68} \approx 31{,}2 \text{ mm}
$$

Lâmina média infiltrada (seção 10.3):

$$
L_{mi} = \frac{L_i + L_f}{2} = \frac{31{,}2 + 30{,}0}{2} = 30{,}6 \text{ mm}
$$

### 14.2 Eficiências

Distribuição (seção 11.2):

$$
E_d = \frac{30{,}0}{\dfrac{31{,}2 + 30{,}0}{2}} \cdot 100 \approx 98\%
$$

Aplicação (seção 11.3):

$$
E_a = \frac{30{,}0}{60{,}0} \cdot 100 = 50\% \quad \text{(inaceitável)}
$$

### 14.3 Perdas

Percolação profunda (seção 11.5), considerando `LL = 30 mm`:

$$
P_p = \frac{30{,}6 - 30}{60} \cdot 100 \approx 1\%
$$

Escoamento superficial:

$$
P_e = \frac{60 - 30{,}6}{60} \cdot 100 \approx 49\%
$$

Conferência: `Pp + Pe ≈ 50%`, que é igual a `100% − Ea`.

### 14.4 Redução de vazão

Vazão reduzida sugerida pelo PDF, com `fo = 7,9 mm/h`:

$$
Q_r = 1{,}1 \cdot \frac{f_o \cdot L \cdot E}{3600} = \frac{7{,}9 \cdot 200 \cdot 1}{3600} \approx 0{,}44 \text{ L/s}
$$

Lâmina média com redução, considerando `Tr = 140 min ≈ 2,33 h`:

$$
L_m = \frac{(3{,}33 - 2{,}33) \cdot 1{,}0 + 2{,}33 \cdot 0{,}44}{200 \cdot 1} \cdot 3600 \approx 36{,}45 \text{ mm}
$$

---

## 15. Divergências e pontos de atenção (exemplo resolvido)

1. **Limites de eficiência inconsistentes entre slides:**
   - Ed: o slide anterior diz `Ed > 70%`, e este diz `> 80%`.
   - Ea: o slide anterior diz `ideal acima de 70%`, e este diz `ideal acima de 75%`. O mínimo aceitável (60%) é o mesmo nos dois.
   Confirme qual critério vale antes de usar nos códigos. Em `E_d` e `E_a`, deixe os limites como parâmetros.

2. **Fator 1,1 na vazão reduzida:** a fórmula `Qr = 1,1 · fo · L · E / 3600` tem um fator 1,1 que o slide não explica. Também não está claro o que é `E` (provavelmente o espaçamento entre sulcos). Vale confirmar a origem desse fator.

3. **Tr não é múltiplo de Tt:** a nota do PDF diz que `Tr` deve ser múltiplo de `Tt`. Mas `Tt = 3,33 h (≈ 200 min)` e `Tr = 140 min`, e 140 não é múltiplo de 200. O cálculo do slide não respeita essa recomendação.

4. **Tempo Tr em horas:** o slide usa `Tr = 2,33 h`, que corresponde a 140 min. A conversão está correta, mas vale deixar a unidade explícita no código.

5. **Eficiência de aplicação após redução de vazão (cálculo derivado, não está no slide):** se `Lm` cair para 36,45 mm e `Lf` continuar 30 mm, então `Ea ≈ 82%` e `Pe ≈ 16%`. Esses números não aparecem no PDF. Confirme se `Lf` também muda com a redução de vazão antes de usar esse resultado.

6. **Unidades de `Lm` e `Tt`:** a fórmula com fator 3600 só fica correta se `Tt` estiver em horas, `q` em L/s, `C` e `L` em metros, e o resultado em mm. Ao codificar, aplique a conversão de forma explícita.

### 15.1 Complemento em Python

```python
def vazao_reduzida(fo_mm_h: float, L: float, E: float, fator: float = 1.1) -> float:
    """Qr (L/s) = fator * fo * L * E / 3600. O fator 1,1 vem do slide e precisa ser confirmado."""
    return fator * fo_mm_h * L * E / 3600


def lamina_media_com_reducao_tr_multiplo(Tt_h: float, Tr_h: float, qi: float, qr: float, C: float, L: float) -> float:
    """
    Mesma fórmula da seção 10.2, mas avisa se Tr não for múltiplo de Tt
    (recomendação do PDF para facilitar o manejo no campo).
    """
    ratio = Tr_h / Tt_h
    if abs(ratio - round(ratio)) > 1e-6:
        print(f"Aviso: Tr ({Tr_h:.2f} h) não é múltiplo de Tt ({Tt_h:.2f} h).")
    return ((Tt_h - Tr_h) * qi + Tr_h * qr) / (C * L) * 3600


def checar_eficiencias(Ea: float, Ed: float, ideal_ea: float = 70.0, ideal_ed: float = 70.0) -> dict:
    """
    Limites variam entre slides (Ea ideal: 70% ou 75%; Ed: 70% ou 80%).
    Os valores padrão seguem o slide de eficiências; ajuste conforme o critério adotado.
    """
    return {
        "Ea_minimo_ok": Ea > 60.0,
        "Ea_ideal": Ea > ideal_ea,
        "Ed_ok": Ed > ideal_ed,
    }
```

---

## 16. Verificação das eficiências com a nova lâmina média (36,45 mm)

Com `Lf = 30,0 mm`, `Lmi = 30,6 mm`, `LL = 30 mm` e `Lm = 36,45 mm`:

$$
E_a = \frac{30{,}0}{36{,}45} \cdot 100 \approx 82{,}3\%
$$

$$
P_p = \frac{30{,}6 - 30}{36{,}45} \cdot 100 \approx 1{,}64\%
$$

$$
P_e = \frac{36{,}45 - 30{,}6}{36{,}45} \cdot 100 \approx 16{,}04\%
$$

Conferência: `Pp + Pe ≈ 17,7%`, que é igual a `100% − Ea`. Os valores batem com o slide, que confirma o cálculo derivado da seção 15 (item 5).

---

## 17. Tempo de irrigação e turno de rega

### 17.1 Tempo de irrigação por sulco

Considerando que as fases de depleção e recessão são desprezíveis, o tempo de recessão é igual ao tempo de irrigação:

$$
T_i = t_0 + t_a
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `T_i` | Tempo de irrigação | h |
| `t_0` | Tempo de oportunidade | h |
| `t_a` | Tempo de avanço | h |

### 17.2 Turno de rega

$$
TR = \frac{CRA}{Etc - Pe}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `TR` | Turno de rega | dias |
| `CRA` | Capacidade real de água no solo | mm |
| `Etc` | Evapotranspiração da cultura | mm/dia |
| `Pe` | Precipitação efetiva (usar quando irrigação suplementar) | mm/dia |

**Atenção:** `Etc − Pe` precisa ser maior que zero. Se não for, o turno não é definido.

---

## 18. Dimensionamento da área e do sistema

### 18.1 Número total de sulcos (NTS)

$$
NTS = \frac{L_t \cdot W_t}{L \cdot E}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `L_t` | Comprimento total da área | m |
| `W_t` | Largura total da área | m |
| `L` | Comprimento do sulco | m |
| `E` | Espaçamento entre sulcos | m |

### 18.2 Número de sulcos por dia (NSD)

$$
NSD = \frac{NTS}{PI}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `NSD` | Número de sulcos por dia | - |
| `NTS` | Número total de sulcos | - |
| `PI` | Período de irrigação | dias |

### 18.3 Tempo de irrigação por parcela (TIP)

$$
TIP = t_i + t_{mud}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `TIP` | Tempo de irrigação por parcela | h |
| `t_i` | Tempo de irrigação por sulco | h |
| `t_mud` | Tempo para mudar o sistema de distribuição de água para outra parcela | h |

### 18.4 Número de parcelas possíveis por dia (NPD)

$$
NPD = \frac{TDF}{TIP}
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `NPD` | Número de parcelas possíveis de irrigar por dia | - |
| `TDF` | Tempo de funcionamento por dia (jornada) | h |
| `TIP` | Tempo de irrigação por parcela | h |

### 18.5 Número de sulcos por parcela (NSP)

$$
NSP = \frac{NSD}{NPD}
$$

### 18.6 Vazão necessária (Q)

$$
Q = NSP \cdot Q_0 + PC
$$

| Símbolo | Significado | Unidade |
|---|---|---|
| `Q` | Vazão necessária | L/s |
| `NSP` | Número de sulcos por parcela | - |
| `Q_0` | Vazão de entrada por sulco | L/s |
| `PC` | Perdas (infiltração nos canais ou vazamento nas tubulações) | L/s |

---

## 19. Notas para implementação e divergências

1. **Arredondamento de contagens:** `NTS`, `NSD`, `NPD` e `NSP` representam quantidades inteiras. O PDF não diz se devem ser arredondadas para cima. Na prática, arredondar `NTS` e `NSP` para cima (ceil) é o mais seguro. Deixei isso como opção no código.
2. **Unidades de tempo:** `T_i`, `t_0`, `t_a`, `TIP` e `TDF` estão em horas, mas `T_x` e `T` (na infiltração) estão em minutos. Converta explicitamente antes de combinar esses valores.
3. **Vazão necessária:** a fórmula `Q = NSP · Q0 + PC` assume que `Q0` é a vazão por sulco e que `PC` já está em L/s. O PDF não detalha isso.
4. **Turno de rega:** a fórmula não contempla o caso `Etc ≤ Pe`. O código deve tratar essa condição.

### 19.1 Complemento em Python

```python
import math


def tempo_irrigacao(t0_h: float, ta_h: float) -> float:
    """Ti (h) = t0 + ta. Considera recessão igual ao tempo de irrigação."""
    return t0_h + ta_h


def turno_rega(CRA_mm: float, Etc_mm_dia: float, Pe_mm_dia: float = 0.0) -> float:
    """TR (dias) = CRA / (Etc - Pe). Pe = 0 quando não há irrigação suplementar."""
    diferenca = Etc_mm_dia - Pe_mm_dia
    if diferenca <= 0:
        raise ValueError("Etc - Pe deve ser maior que zero para definir o turno de rega.")
    return CRA_mm / diferenca


def numero_total_sulcos(Lt: float, Wt: float, L: float, E: float, arredondar_cima: bool = True) -> float:
    """NTS = (Lt * Wt) / (L * E)."""
    nts = Lt * Wt / (L * E)
    return math.ceil(nts) if arredondar_cima else nts


def sulcos_por_dia(NTS: float, PI_dias: float) -> float:
    """NSD = NTS / PI."""
    return NTS / PI_dias


def tempo_irrigacao_parcela(ti_h: float, tmud_h: float) -> float:
    """TIP (h) = ti + tmud."""
    return ti_h + tmud_h


def parcelas_por_dia(TDF_h: float, TIP_h: float) -> float:
    """NPD = TDF / TIP."""
    return TDF_h / TIP_h


def sulcos_por_parcela(NSD: float, NPD: float, arredondar_cima: bool = True) -> float:
    """NSP = NSD / NPD."""
    nsp = NSD / NPD
    return math.ceil(nsp) if arredondar_cima else nsp


def vazao_necessaria(NSP: float, Q0_Ls: float, PC_Ls: float) -> float:
    """Q (L/s) = NSP * Q0 + PC."""
    return NSP * Q0_Ls + PC_Ls
```
