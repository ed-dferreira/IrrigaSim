# Fases da irrigação por sulcos e cálculo do avanço

## Objetivo

Este documento estrutura as fases hidráulicas da irrigação por sulcos e os cálculos necessários para estimar a curva de avanço da água. Ele deve servir como referência para implementação, armazenamento e validação dos cálculos na aplicação.

> Os cálculos devem ser armazenados com precisão suficiente para permitir auditoria e reprodução dos resultados. O arredondamento deve acontecer apenas na apresentação.

## 1. Fases da irrigação por sulcos

### 1.1 Fase de avanço (`ta`)

Começa com a entrada de água no início do sulco e termina quando a frente de avanço da água alcança o final do sulco.

- Também chamada de **tempo de avanço**;
- Depende da vazão aplicada, do comprimento do sulco, da declividade, do solo e da geometria do sulco;
- O tempo de avanço deve ser controlado para evitar perdas excessivas por percolação no início da área.

### 1.2 Fase de reposição ou infiltração (`ti`)

Começa quando o espelho d'água está totalmente formado, no final do avanço, e termina quando a aplicação de água é interrompida.

No contexto do sulco, a duração da aplicação após a chegada da água é:

```text
ti - ta
```

Essa fase corresponde ao período em que a água repõe a umidade do solo por infiltração.

### 1.3 Fase de depleção (`td`)

Começa com a interrupção da entrada de água no início da área e termina quando ocorre a exposição de qualquer ponto da superfície do solo ao longo da área.

- Normalmente tem duração muito pequena em sulcos;
- Pode ser desprezada em modelos simplificados;
- Deve ser mantida como campo de entrada quando a aplicação precisar de maior precisão.

### 1.4 Fase de recesso (`tr`)

Começa após a fase de depleção e termina quando não há mais água sobre a superfície do solo ao longo de toda a área.

- Normalmente tem duração muito pequena em sulcos;
- Pode ser desprezada em modelos simplificados;
- É importante em modelos que calculam o tempo de oportunidade ponto a ponto.

## 2. Tempo de oportunidade

O tempo de oportunidade (`top`) é o período em que um ponto específico permanece em contato com a água e ocorre infiltração.

Para um ponto qualquer do sulco:

```text
top(x) = tr(x) - ta(x)
```

Onde:

- `ta(x)`: instante em que a frente de avanço chega ao ponto `x`;
- `tr(x)`: instante em que a água deixa o ponto `x`;
- `top(x)`: tempo de oportunidade de infiltração naquele ponto.

No diagrama, a diferença vertical entre a curva de avanço e a curva de recesso representa o tempo de oportunidade em cada posição.

> Atenção: os símbolos podem variar entre autores. Nesta aplicação, recomenda-se usar nomes completos no código (`tempo_avanco`, `tempo_recesso`, `tempo_oportunidade`) e manter as siglas apenas como abreviações de exibição.

## 3. Comprimento do sulco e critério de avanço

Criddle (1956) recomendou determinar o comprimento do sulco analisando, para diferentes vazões:

- perda por percolação;
- escoamento no final do sulco;
- lâmina infiltrada ao longo do sulco.

Como regra prática, o comprimento do sulco deveria ser escolhido de modo que o tempo de avanço fosse aproximadamente um quarto do tempo de oportunidade:

```text
ta ≈ top / 4
```

ou, de forma equivalente:

```text
top ≈ 4 * ta
```

Esse critério é uma regra prática histórica. Modelos atuais podem dimensionar o sistema maximizando a eficiência de aplicação, sem depender exclusivamente dessa proporção.

## 4. Equação potencial de avanço

A equação potencial é uma das formas mais comuns de representar o avanço da água:

```text
Tx = k * x^b
```

### Variáveis

| Símbolo | Nome | Unidade | Descrição |
|---|---|---|---|
| `x` | distância | m | Distância alcançada pela frente de avanço da água |
| `Tx` | tempo de avanço | min | Tempo necessário para a água alcançar a posição `x` |
| `k` | parâmetro de ajuste | depende das unidades | Coeficiente da equação |
| `b` | expoente de ajuste | adimensional | Expoente da curva de avanço |

Os valores de `k` e `b` dependem das unidades utilizadas. Se a distância ou o tempo forem convertidos, os parâmetros devem ser recalculados.

## 5. Linearização da equação potencial

Aplicando logaritmo natural aos dois lados:

```text
ln(Tx) = ln(k) + b * ln(x)
```

Definindo:

```text
Y = ln(Tx)
X = ln(x)
A = ln(k)
```

obtém-se uma equação linear:

```text
Y = A + b * X
```

Portanto:

- `b` é o coeficiente angular da reta;
- `A` é o intercepto;
- `k = exp(A)` quando for utilizado logaritmo natural.

### Regra importante para a aplicação

O ponto `x = 0` não pode ser usado na linearização porque `ln(0)` não existe. O registro pode ser mantido na tabela original, mas deve ser excluído da regressão logarítmica.

## 6. Método dos dois pontos

O método dos dois pontos utiliza:

- o tempo de avanço até a metade do comprimento (`T0,5x`);
- o tempo de avanço até o comprimento total (`Tx`).

### Fórmulas

```text
b = [ln(T0,5x) - ln(Tx)] / ln(0,5)
```

Como `ln(0,5)` é negativo, o resultado de `b` tende a ser positivo quando `T0,5x < Tx`.

Depois de calcular `b`, o parâmetro `k` é obtido por:

```text
k = Tx / x^b
```

> Correção importante: a fórmula correta é `k = Tx / x^b`. Não é `Tx / b`.

### Condições de validade

- `x > 0`;
- `Tx > 0`;
- `T0,5x > 0`;
- os dois pontos devem pertencer ao mesmo ensaio;
- as unidades de distância e tempo devem ser as mesmas nas duas medições.

## 7. Exemplo do método dos dois pontos

### Dados do ensaio

| Estaca | Distância `x` (m) | Tempo de avanço `Tx` (min) |
|---:|---:|---:|
| 0 | 0 | 0 |
| 1 | 20 | 5,0 |
| 2 | 40 | 10,5 |
| 3 | 60 | 19,2 |
| 4 | 80 | 30,0 |
| 5 | 100 | 37,9 |
| 6 | 120 | 48,0 |
| 7 | 140 | 60,5 |
| 8 | 160 | 68,0 |
| 9 | 180 | 81,3 |
| 10 | 200 | 93,5 |

Para o método dos dois pontos, são usados:

```text
x = 200 m
T0,5x = 37,9 min  (x = 100 m)
Tx = 93,5 min     (x = 200 m)
```

### Cálculo de `b`

```text
b = [ln(37,9) - ln(93,5)] / ln(0,5)
b = 1,3027685166039074
```

Arredondamento para apresentação:

```text
b ≈ 1,30
```

### Cálculo de `k`

```text
k = 93,5 / 200^1,3027685166039074
k = 0,09399444259216042
```

Arredondamento para apresentação:

```text
k ≈ 0,0940
```

### Equação resultante

Com os valores completos:

```text
Tx = 0,09399444259216042 * x^1,3027685166039074
```

Para exibição simplificada:

```text
Tx ≈ 0,0940 * x^1,30
```

Usando os valores não arredondados, a equação retorna `Tx = 37,9 min` quando `x = 100 m` e `Tx = 93,5 min` quando `x = 200 m`.

## 8. Interpolação do tempo de avanço

Se o tempo de avanço para uma distância necessária não estiver registrado, a aplicação pode interpolar entre dois pontos conhecidos.

Para interpolação linear entre `(x1, T1)` e `(x2, T2)`:

```text
T(x) = T1 + [(x - x1) / (x2 - x1)] * (T2 - T1)
```

### Exemplo

Para estimar o tempo em `x = 110 m`, usando `100 m = 37,9 min` e `120 m = 48,0 min`:

```text
T(110) = 37,9 + [(110 - 100) / (120 - 100)] * (48,0 - 37,9)
T(110) = 42,95 min
```

Use interpolação apenas dentro do intervalo conhecido. Fora dele, o cálculo é extrapolação e deve receber um aviso na aplicação.

## 9. Método dos mínimos quadrados

O método dos mínimos quadrados estima `A` e `b` usando todos os pontos válidos da curva linearizada:

```text
Yi = A + b * Xi
```

com:

```text
Xi = ln(xi)
Yi = ln(Txi)
```

O ponto com `x = 0` ou `Tx = 0` deve ser excluído, pois não possui logaritmo definido.

### Fórmula do coeficiente angular

```text
b = [N * Σ(Xi * Yi) - ΣXi * ΣYi]
    / [N * Σ(Xi^2) - (ΣXi)^2]
```

### Fórmula do intercepto

```text
A = média(Y) - b * média(X)
```

### Conversão de `A` para `k`

Se foi usado logaritmo natural:

```text
k = exp(A)
```

Se foi usado logaritmo na base 10:

```text
k = 10^A
```

> A expressão genérica “antilog(A)” só é segura quando a base do logaritmo estiver registrada junto com o cálculo.

## 10. Resultado de referência da regressão do exemplo

Aplicando regressão linear em escala logarítmica aos pontos do exemplo, excluindo `x = 0` e `Tx = 0`, a forma aproximada apresentada no material é:

```text
Tx ≈ 0,0978 * x^1,2944
```

Essa equação é uma estimativa por todos os pontos e, portanto, não precisa coincidir exatamente com a equação do método dos dois pontos.

Para armazenamento, manter os valores completos retornados pelo cálculo, além dos valores arredondados exibidos.

## 11. Estrutura de dados para os cálculos

```json
{
  "tipo_calculo": "curva_avanco",
  "unidades": {
    "distancia": "m",
    "tempo": "min",
    "vazao": "L/s"
  },
  "dados_ensaio": [
    { "x": 0.0, "tx": 0.0 },
    { "x": 20.0, "tx": 5.0 },
    { "x": 40.0, "tx": 10.5 },
    { "x": 60.0, "tx": 19.2 },
    { "x": 80.0, "tx": 30.0 },
    { "x": 100.0, "tx": 37.9 },
    { "x": 120.0, "tx": 48.0 },
    { "x": 140.0, "tx": 60.5 },
    { "x": 160.0, "tx": 68.0 },
    { "x": 180.0, "tx": 81.3 },
    { "x": 200.0, "tx": 93.5 }
  ],
  "parametros_dois_pontos": {
    "x_metade_m": 100.0,
    "tempo_metade_min": 37.9,
    "x_total_m": 200.0,
    "tempo_total_min": 93.5,
    "b": 1.3027685166039074,
    "k": 0.09399444259216042
  },
  "precisao": {
    "casas_internas": 15,
    "arredondamento_apenas_na_exibicao": true
  }
}
```

## 12. Regras de precisão e validação

### Armazenamento

- Armazene os dados originais sem arredondar;
- Armazene `k` e `b` com pelo menos 15 casas decimais quando o tipo numérico permitir;
- Armazene a unidade de cada grandeza;
- Armazene o método usado: `dois_pontos`, `minimos_quadrados` ou `interpolacao`;
- Armazene a base do logaritmo: `e` ou `10`;
- Armazene a data, a origem e o identificador do ensaio;
- Nunca substitua o valor original pelo valor formatado para a tela.

### Validações mínimas

- `x` deve ser maior ou igual a zero;
- `Tx` deve ser maior ou igual a zero;
- para regressão logarítmica, `x > 0` e `Tx > 0`;
- as distâncias devem estar em ordem crescente;
- os tempos de avanço não devem diminuir à medida que `x` aumenta, salvo se houver justificativa experimental;
- o método dos dois pontos exige dois pontos positivos e distintos;
- o denominador da fórmula de `b` não pode ser zero;
- o denominador da regressão linear não pode ser zero;
- valores ausentes devem ser tratados como `null`, nunca como zero;
- valores extrapolados devem ser identificados e receber um aviso.

### Exibição

- Mostre valores arredondados apenas na interface;
- permita consultar o valor completo usado no cálculo;
- indique o método utilizado;
- informe quando o ponto foi interpolado ou extrapolado;
- exiba as unidades ao lado dos valores;
- mantenha a equação gerada associada ao ensaio que originou seus parâmetros.

## 13. Campos recomendados para a tela

- Comprimento do sulco;
- Distância medida (`x`);
- Tempo de avanço (`Tx`);
- Vazão aplicada;
- Declividade;
- Tipo de solo;
- Cultura;
- Método de ajuste;
- Tempo de reposição/infiltração;
- Tempo de depleção;
- Tempo de recesso;
- Tempo de oportunidade;
- Parâmetros calculados `k` e `b`;
- Equação da curva;
- Eficiência de aplicação;
- Alertas de validação.

## 14. Resumo da implementação

1. Cadastrar os pontos originais do ensaio;
2. Validar unidades, ordem das distâncias e valores positivos;
3. Manter o ponto `(0, 0)` na série original;
4. Excluir o ponto `(0, 0)` somente da regressão logarítmica;
5. Calcular `k` e `b` pelo método escolhido;
6. Guardar os valores completos e o método utilizado;
7. Gerar a equação da curva;
8. Calcular ou estimar tempos de avanço apenas dentro do domínio validado;
9. Aplicar arredondamento somente na visualização;
10. Exibir avisos quando houver extrapolação, dados insuficientes ou inconsistência.

## 15. Exemplo real enviado — método dos dois pontos

As três últimas imagens enviadas apresentam um exemplo real de teste de avanço. Os dados são:

| Ponto | Distância | Tempo de avanço |
|---|---:|---:|
| Ponto médio | `60 m` | `22 min` |
| Ponto máximo | `120 m` | `58 min` |

O objetivo do exercício é:

1. determinar a equação de avanço pelo método dos dois pontos;
2. calcular o tempo de avanço para um sulco de `80 m`;
3. calcular o comprimento do sulco quando o tempo de avanço for `53 min`.

### 15.1 Cálculo preciso de `b`

Como `60 m` corresponde à metade de `120 m`:

```text
b = [ln(22) - ln(58)] / ln(0,5)
b = 1,3985493764902743
```

Valor arredondado para apresentação:

```text
b ≈ 1,39
```

### 15.2 Cálculo preciso de `k`

Usando o ponto máximo:

```text
k = 58 / 120^1,3985493764902743
k = 0,07171175618605942
```

Portanto, usando os valores completos, a equação é:

```text
Tx = 0,07171175618605942 * x^1,3985493764902743
```

### 15.3 Tempo para um sulco de `80 m`

```text
T80 = 0,07171175618605942 * 80^1,3985493764902743
T80 = 32,89695289843265 min
```

Resultado para apresentação:

```text
T80 ≈ 32,90 min
```

### 15.4 Comprimento correspondente a `53 min`

Partindo da equação:

```text
53 = k * x^b
```

Isolando `x`:

```text
x = (53 / k)^(1 / b)
```

Substituindo os valores completos:

```text
x = (53 / 0,07171175618605942)^(1 / 1,3985493764902743)
x = 112,50878536999546 m
```

Resultado para apresentação:

```text
x ≈ 112,51 m
```

### 15.5 Diferença entre o cálculo preciso e o cálculo arredondado do material

As imagens apresentam a equação arredondada:

```text
Tx = 0,0747 * x^1,39
```

Essa forma produz aproximadamente:

```text
T80 ≈ 33,01 min
x53 ≈ 112,47 m
```

Os resultados são próximos, mas não idênticos. A diferença ocorre porque `b` e `k` foram arredondados antes das etapas seguintes. Para a aplicação, recomenda-se:

- guardar `b = 1,3985493764902743`;
- guardar `k = 0,07171175618605942`;
- calcular usando os valores completos;
- mostrar `b = 1,39`, `k = 0,0717`, `T80 = 32,90 min` e `x53 = 112,51 m` apenas na interface.

> Regra de precisão: não recalcule `k` usando `b = 1,39` se o objetivo for reproduzir o resultado de alta precisão. O valor de `k` depende do valor completo de `b`.

## 16. Registro do exemplo real em JSON

```json
{
  "tipo_calculo": "curva_avanco",
  "origem": "exemplo_real_enviado",
  "metodo": "dois_pontos",
  "unidades": {
    "distancia": "m",
    "tempo": "min"
  },
  "pontos_referencia": {
    "distancia_metade_m": 60.0,
    "tempo_metade_min": 22.0,
    "distancia_total_m": 120.0,
    "tempo_total_min": 58.0
  },
  "parametros": {
    "b": 1.3985493764902743,
    "k": 0.07171175618605942
  },
  "equacao": "Tx = k * x^b",
  "resultados": [
    {
      "tipo": "tempo_para_distancia",
      "distancia_m": 80.0,
      "tempo_min": 32.89695289843265
    },
    {
      "tipo": "distancia_para_tempo",
      "tempo_min": 53.0,
      "distancia_m": 112.50878536999546
    }
  ],
  "precisao": {
    "calcular_com_valores_completos": true,
    "arredondar_apenas_na_exibicao": true
  }
}
```

## 17. Registro dos cálculos apresentados nas imagens de regressão

As imagens anteriores apresentam outro ensaio, com os tempos de avanço:

| Distância (m) | Tempo (min) |
|---:|---:|
| 20 | 2 |
| 40 | 5 |
| 60 | 9 |
| 80 | 14 |
| 100 | 21 |
| 120 | 30 |
| 140 | 40 |
| 160 | 53 |
| 180 | 69 |
| 200 | 93 |

Nesse material foi usado logaritmo na base 10:

```text
X = log10(x)
Y = log10(Tx)
```

Os valores exibidos foram aproximadamente:

```text
ΣX = 19,57
ΣY = 13,03
ΣXY = 27,02
ΣX² = 39,21
N = 10
```

Com esses valores arredondados, o material apresenta:

```text
b ≈ 1,65
a ≈ -1,93
k = 10^a ≈ 0,011
Tx ≈ 0,011 * x^1,65
```

O cálculo interno deve usar os valores de `log10` sem arredondamento. As somas mostradas nas imagens servem apenas para conferência visual e não devem ser reutilizadas como entrada de um cálculo de alta precisão.

### Observação sobre o exemplo real

O exemplo das três últimas imagens é independente do ensaio de regressão. Ele deve ser salvo como um ensaio separado, com seu próprio método, pontos de referência, parâmetros `k` e `b`, equação e resultados.

## 18. Determinação da equação de infiltração — método da entrada e saída

As novas imagens apresentam um ensaio de infiltração pelo método da entrada e saída. O método compara a vazão que entra no trecho com a vazão que sai dele. A diferença representa a água infiltrada no trecho monitorado.

### 18.1 Dados do ensaio

- **Vazão de entrada:** `Qentrada = 1 L/s`;
- **Comprimento monitorado:** `100 m`;
- **Espaçamento entre sulcos:** `1 m`;
- **Área considerada:** `100 m × 1 m = 100 m²`;
- **Vazão de saída:** valores medidos na estaca 5;
- **Tempo:** em minutos.

### 18.2 Vazão infiltrada

Para cada instante:

```text
Qinfiltrada = Qentrada - Qsaida
```

Com `Qentrada = 1 L/s`, por exemplo, quando `Qsaida = 0,19 L/s`:

```text
Qinfiltrada = 1,00 - 0,19 = 0,81 L/s
```

### 18.3 Conversão para intensidade de infiltração

Para uma área de `100 m²`:

```text
1 L/s em 100 m² = 36 mm/h
```

Logo:

```text
VI(mm/h) = Qinfiltrada(L/s) * 36
```

Exemplo:

```text
VI = 0,81 * 36 = 29,16 mm/h ≈ 29,2 mm/h
```

## 19. Tabela do ensaio de infiltração

Os dados abaixo foram transcritos das imagens. Os valores em `mm/h` foram recalculados a partir da vazão infiltrada para preservar a precisão.

| Tempo (min) | Vazão entrada (L/s) | Vazão saída (L/s) | Vazão infiltrada (L/s) | Infiltração instantânea (mm/h) |
|---:|---:|---:|---:|---:|
| 0 | 1,00 | 0,00 | — | — |
| 2 | 1,00 | 0,19 | 0,81 | 29,16 |
| 9 | 1,00 | 0,50 | 0,50 | 18,00 |
| 19 | 1,00 | 0,63 | 0,37 | 13,32 |
| 29 | 1,00 | 0,66 | 0,34 | 12,24 |
| 49 | 1,00 | 0,71 | 0,29 | 10,44 |
| 64 | 1,00 | 0,73 | 0,27 | 9,72 |
| 79 | 1,00 | 0,75 | 0,25 | 9,00 |
| 89 | 1,00 | 0,76 | 0,24 | 8,64 |
| 101 | 1,00 | 0,77 | 0,23 | 8,28 |
| 119 | 1,00 | 0,78 | 0,22 | 7,92 |
| 149 | 1,00 | 0,78 | 0,22 | 7,92 |

> O registro em `t = 0` é mantido para representar o início do ensaio, mas não deve entrar na regressão logarítmica.

## 20. Equação potencial da infiltração instantânea

A forma potencial usada nas imagens é:

```text
VI = K * T^n
```

Onde:

| Símbolo | Significado | Unidade neste ensaio |
|---|---|---|
| `VI` | infiltração instantânea | mm/h |
| `T` | tempo desde o início do ensaio | min |
| `K` | coeficiente de infiltração | depende das unidades |
| `n` | expoente de ajuste | adimensional |

Como `T` está em minutos e `VI` em mm/h, o valor de `K` é válido somente nesse sistema de unidades.

## 21. Regressão logarítmica da infiltração

Aplicando logaritmo na base 10:

```text
log10(VI) = log10(K) + n * log10(T)
```

Definindo:

```text
X = log10(T)
Y = log10(VI)
a = log10(K)
```

obtém-se:

```text
Y = a + n * X
```

Depois da regressão:

```text
K = 10^a
```

### Quantidade correta de observações

A tabela possui **11 tempos positivos** (`2, 9, 19, ..., 149`). Portanto:

```text
N = 11
```

O valor `N = 10` mostrado em algumas imagens é uma inconsistência e não deve ser usado para recalcular o ensaio completo.

### Resultado recalculado com valores não arredondados

Usando `VI` em `mm/h`, calculado por `VI = (1 - Qsaida) * 36`, e os 11 pontos positivos:

```text
n = -0,31077526032565167
a = 1,5465798831706001
K = 35,203016822389664
```

Equação precisa:

```text
VI = 35,203016822389664 * T^-0,31077526032565167
```

Equação para apresentação:

```text
VI ≈ 35,20 * T^-0,31
```

## 22. Infiltração acumulada

A infiltração acumulada é obtida integrando a infiltração instantânea:

```text
VI(T) = K * T^n
```

Como `VI` está em `mm/h` e `T` está em minutos, é necessário converter o tempo para horas:

```text
I(T) = [K / (60 * (n + 1))] * T^(n + 1)
```

Substituindo os valores precisos:

```text
n + 1 = 0,6892247396743483
K / [60 * (n + 1)] = 0,8505421902886259
```

Equação precisa da infiltração acumulada:

```text
I = 0,8505421902886259 * T^0,6892247396743483
```

Equação para apresentação:

```text
I ≈ 0,85 * T^0,69
```

Onde `I` é dado em `mm` e `T` em minutos.

> Não confundir `VI`, que é uma taxa instantânea em `mm/h`, com `I`, que é uma lâmina acumulada em `mm`.

## 23. Diferenças e correções identificadas nas imagens

### 23.1 Unidade usada na regressão

As imagens mostram a coluna `y = log VI` com valores como `-0,09`, que correspondem a `log10(0,81)`, enquanto a equação final `VI = 35,23 * T^-0,32` corresponde à infiltração em `mm/h`, isto é, a valores como `29,2`.

Para evitar ambiguidade, a aplicação deve:

- converter primeiro a vazão infiltrada para `mm/h`;
- depois calcular `Y = log10(VI_mm_h)`;
- registrar explicitamente a unidade usada na regressão.

### 23.2 Intercepto

Se `VI` estiver em `mm/h`, o intercepto é aproximadamente `a = 1,54658` e `K ≈ 35,2030`.

Se forem usados os valores de `VI` em `L/s por 100 m`, o intercepto e `K` serão diferentes. Não se deve misturar os dois sistemas de unidade na mesma equação.

### 23.3 Arredondamento

As imagens apresentam `n ≈ -0,32`, `K ≈ 35,23` e `I ≈ 0,85 * T^0,68`. Esses valores são adequados para exibição, mas os valores completos devem ser mantidos no armazenamento.

## 24. Estrutura JSON do ensaio de infiltração

```json
{
  "tipo_calculo": "equacao_infiltracao",
  "metodo": "entrada_saida",
  "unidades": {
    "tempo": "min",
    "vazao": "L/s",
    "infiltracao_instantanea": "mm/h",
    "infiltracao_acumulada": "mm",
    "comprimento": "m",
    "espacamento": "m"
  },
  "configuracao": {
    "vazao_entrada_l_s": 1.0,
    "comprimento_monitorado_m": 100.0,
    "espacamento_sulcos_m": 1.0,
    "area_m2": 100.0,
    "fator_conversao_l_s_para_mm_h": 36.0
  },
  "pontos": [
    { "tempo_min": 2.0, "vazao_saida_l_s": 0.19, "vazao_infiltrada_l_s": 0.81, "vi_mm_h": 29.16 },
    { "tempo_min": 9.0, "vazao_saida_l_s": 0.50, "vazao_infiltrada_l_s": 0.50, "vi_mm_h": 18.0 },
    { "tempo_min": 19.0, "vazao_saida_l_s": 0.63, "vazao_infiltrada_l_s": 0.37, "vi_mm_h": 13.32 },
    { "tempo_min": 29.0, "vazao_saida_l_s": 0.66, "vazao_infiltrada_l_s": 0.34, "vi_mm_h": 12.24 },
    { "tempo_min": 49.0, "vazao_saida_l_s": 0.71, "vazao_infiltrada_l_s": 0.29, "vi_mm_h": 10.44 },
    { "tempo_min": 64.0, "vazao_saida_l_s": 0.73, "vazao_infiltrada_l_s": 0.27, "vi_mm_h": 9.72 },
    { "tempo_min": 79.0, "vazao_saida_l_s": 0.75, "vazao_infiltrada_l_s": 0.25, "vi_mm_h": 9.0 },
    { "tempo_min": 89.0, "vazao_saida_l_s": 0.76, "vazao_infiltrada_l_s": 0.24, "vi_mm_h": 8.64 },
    { "tempo_min": 101.0, "vazao_saida_l_s": 0.77, "vazao_infiltrada_l_s": 0.23, "vi_mm_h": 8.28 },
    { "tempo_min": 119.0, "vazao_saida_l_s": 0.78, "vazao_infiltrada_l_s": 0.22, "vi_mm_h": 7.92 },
    { "tempo_min": 149.0, "vazao_saida_l_s": 0.78, "vazao_infiltrada_l_s": 0.22, "vi_mm_h": 7.92 }
  ],
  "regressao": {
    "base_logaritmo": 10,
    "observacoes_validas": 11,
    "n": -0.31077526032565167,
    "a": 1.5465798831706001,
    "k": 35.203016822389664
  },
  "equacoes": {
    "infiltracao_instantanea": "VI = K * T^n",
    "infiltracao_acumulada": "I = [K / (60 * (n + 1))] * T^(n + 1)"
  },
  "resultado": {
    "vi": "VI = 35.203016822389664 * T^-0.31077526032565167",
    "i": "I = 0.8505421902886259 * T^0.6892247396743483"
  }
}
```

## 25. Validações específicas da infiltração

- `Qentrada` e `Qsaida` devem usar a mesma unidade;
- `Qsaida` não deve ser maior que `Qentrada` sem um aviso de inconsistência;
- `VI` deve ser não negativa;
- `T = 0` deve ser excluído da regressão logarítmica;
- devem existir pelo menos dois pontos válidos para estimar a curva;
- a base do logaritmo deve ser armazenada;
- a unidade de `VI` deve ser armazenada junto com `K`;
- se `T` estiver em minutos, a integração para `I` deve conter o fator `1/60`;
- `n + 1` não pode ser igual a zero na fórmula da infiltração acumulada;
- os valores completos devem ser usados nos cálculos posteriores;
- arredondamentos devem ser aplicados somente na apresentação.

## 26. Fases de reposição, depleção e recesso

### 26.1 Processo de reposição

Quando a frente de avanço atinge o final da parcela, pode começar o escoamento superficial nessa extremidade. Esse escoamento pode representar perda de água ou água passível de reutilização, dependendo da existência de um sistema de coleta e reaproveitamento.

A fase de reposição compreende o intervalo entre:

1. o início do escoamento no final da parcela;
2. o instante em que a derivação de água para a parcela é interrompida.

O segundo instante define o **tempo de corte**.

Ao final da reposição, o manejo deve buscar que a maior parte da área tenha recebido a lâmina de irrigação necessária. Como a distribuição da água ao longo do sulco não é perfeitamente uniforme, alguns pontos podem permanecer com deficiência de água mesmo após o encerramento da fase.

O desempenho do sistema depende fortemente da duração da reposição:

- reposição curta pode deixar o final do sulco com deficiência;
- reposição longa pode aumentar a infiltração excessiva no início;
- o tempo de corte deve equilibrar atendimento da cultura, percolação e escoamento superficial;
- a reutilização do escoamento altera o diagnóstico de perda de água.

### 26.2 Tempo de oportunidade em um ponto

Para um ponto `i` ao longo do sulco, o tempo de oportunidade é o intervalo entre a chegada da água e o fim do recesso nesse ponto.

A forma apresentada nas imagens é:

```text
To(i) = Tc - Tx(i) + Td(i) + Trec(i)
```

Onde:

- `To(i)`: tempo de oportunidade no ponto `i`;
- `Tc`: tempo de corte ou tempo total até a interrupção da aplicação;
- `Tx(i)`: tempo de avanço até o ponto `i`;
- `Td(i)`: duração da depleção no ponto `i`;
- `Trec(i)`: duração do recesso no ponto `i`.

Uma forma equivalente, usando instantes absolutos, é:

```text
To(i) = Tfim_agua(i) - Tx(i)
Tfim_agua(i) = Tc + Td(i) + Trec(i)
```

Portanto:

```text
To(i) = Tc + Td(i) + Trec(i) - Tx(i)
```

Se a depleção e o recesso forem desprezados, como aproximação simplificada para sulcos:

```text
To(i) ≈ Tc - Tx(i)
```

### 26.3 Relação entre as fases

Para cada ponto do sulco:

```text
avanço → reposição/infiltração → corte → depleção → recesso
```

O tempo de avanço pode ser diferente em cada ponto. Por isso, o tempo de oportunidade também varia ao longo do sulco, normalmente sendo maior no início e menor no final.

### 26.4 Dados necessários para modelar as fases

O aplicativo deve permitir registrar:

- tempo de avanço em cada estaca;
- instante de início do escoamento no final;
- tempo de corte;
- duração da depleção por estaca;
- duração do recesso por estaca;
- tempo de oportunidade resultante;
- vazão de entrada;
- vazão de saída ou escoamento superficial;
- existência de reutilização do escoamento.

## 27. Comprimento do sulco

O comprimento adequado depende de fatores hidráulicos, agronômicos, operacionais e econômicos.

### 27.1 Fatores de dimensionamento

- tamanho e forma da área;
- tipo de solo;
- vazão disponível;
- declividade do solo;
- mão de obra disponível;
- perda de área de cultivo;
- dificuldades de mecanização;
- perdas por percolação;
- perdas por escoamento superficial;
- uniformidade da lâmina infiltrada;
- tempo de avanço e tempo de oportunidade.

### 27.2 Regra prática de Criddle

Uma regra prática apresentada no material é:

```text
Ta = To / 4
```

Essa relação pode ser usada como estimativa inicial do comprimento máximo, mas não substitui o dimensionamento com dados de campo. O comprimento deve ser verificado pela perda por percolação, pelo escoamento final, pela lâmina infiltrada e pela eficiência de aplicação.

## 28. Espaçamento entre sulcos

O espaçamento depende de:

- espaçamento entre fileiras de plantas;
- tipo de solo;
- equipamentos utilizados nos tratos culturais;
- profundidade efetiva das raízes;
- largura do bulbo ou faixa umedecida;
- geometria do sulco.

### 28.1 Valores e regras de referência

- Para culturas em fileiras, o material apresenta espaçamento entre fileiras de aproximadamente `90 cm` a `110 cm`;
- o espaçamento entre sulcos não deve ser maior que `2 ×` a profundidade efetiva das raízes;
- solos arenosos tendem a apresentar faixa de umedecimento mais estreita;
- solos médios apresentam faixa intermediária;
- solos argilosos tendem a apresentar faixa de umedecimento mais larga.

> A regra `espaçamento ≤ 2 × profundidade efetiva das raízes` é uma regra prática. O aplicativo deve tratá-la como alerta de referência, não como substituição de ensaio de campo.

## 29. Geometria do sulco

A geometria depende principalmente da cultura irrigada e das condições de operação. A seção em V é comum.

### 29.1 Valores médios apresentados

- **Largura:** aproximadamente `20 cm` a `30 cm`;
- **Profundidade:** aproximadamente `15 cm` a `25 cm`;
- **Forma comum:** V.

Esses valores devem ser armazenados como faixa de referência. A geometria real pode exigir outros valores conforme solo, cultura, implemento e vazão.

### 29.2 Campos geométricos

```text
forma
largura_superior_m
profundidade_m
largura_base_m
area_seccao_m2
perimetro_molhado_m
raio_hidraulico_m
```

Quando a seção for aproximada por um triângulo:

```text
area_seccao = largura_superior * profundidade / 2
```

## 30. Vazão aplicada e vazão máxima não erosiva

A vazão colocada no sulco varia conforme as características do solo. O material apresenta uma faixa geral de referência entre `0,5 L/s` e `2,0 L/s`, com uso comum de aproximadamente `1,0 L/s`.

A vazão máxima deve ser limitada para não provocar erosão no sulco.

### 30.1 Equação por textura do solo

Uma forma apresentada no material é:

```text
qmax = C / S0^a
```

Onde:

- `qmax`: vazão máxima não erosiva, em `L/s`;
- `S0`: declividade do sulco, em `%`;
- `C` e `a`: parâmetros dependentes da textura do solo.

### 30.2 Parâmetros de referência

| Textura | `C` | `a` |
|---|---:|---:|
| Muito fina | 0,892 | 0,937 |
| Fina | 0,988 | 0,550 |
| Média | 0,613 | 0,733 |
| Grossa | 0,644 | 0,704 |
| Muito grossa | 0,665 | 0,548 |

> Os parâmetros devem ser versionados no aplicativo, pois dependem da fonte técnica e das unidades usadas. Não misture declividade em porcentagem com declividade decimal sem recalibrar a equação.

### 30.3 Fórmula prática simplificada

O material também apresenta:

```text
qmax = 0,631 / S
```

Essa forma é uma regra prática simplificada. O aplicativo deve identificar se o usuário está usando a equação específica por textura ou a aproximação simplificada.

### 30.4 Validações de vazão

- `q_aplicada` não deve ultrapassar `qmax` sem um alerta de risco de erosão;
- se `q_aplicada > qmax`, classificar como condição potencialmente erosiva;
- se a vazão estiver abaixo da faixa operacional da cultura, sinalizar possível avanço lento;
- registrar se a vazão é constante ou se há redução programada;
- considerar a vazão de saída no cálculo de perdas e reutilização.

## 31. Lâminas infiltradas e lâmina média aplicada

### 31.1 Lâmina no início e no final do sulco

- A lâmina infiltrada no início pode ser obtida pela curva ou equação de infiltração acumulada usando o tempo de oportunidade no início;
- a lâmina infiltrada no final deve ser comparada com a lâmina real necessária para a irrigação;
- excesso no início e deficiência no final indicam baixa uniformidade de distribuição.

### 31.2 Lâmina média aplicada com vazão constante

Quando a vazão é constante:

```text
Lm = (Tt * qc / (C * L)) * 3600
```

Onde:

- `Lm`: lâmina média aplicada por sulco, em `mm`;
- `Tt`: tempo total de aplicação, em `h`;
- `qc`: vazão constante aplicada por sulco, em `L/s`;
- `C`: comprimento do sulco, em `m`;
- `L`: largura da faixa umedecida por sulco, em `m`.

Para sulcos próximos, `L` pode ser aproximado pelo espaçamento entre sulcos.

O fator `3600` converte `L/s` para volume aplicado durante um tempo em horas, considerando a conversão do volume por área para milímetros.

### 31.3 Lâmina média infiltrada por estacas

Quando existem lâminas medidas ou estimadas em várias estacas:

```text
Lmi = (Σ yi) / n
```

Uma aproximação apresentada no material para uma distribuição linear entre o início e o final é:

```text
Lmi = (Li + Lf) / 2
```

Onde:

- `Lmi`: lâmina média infiltrada, em `mm`;
- `yi`: lâmina infiltrada na estaca `i`;
- `n`: quantidade de estacas;
- `Li`: lâmina no início do sulco;
- `Lf`: lâmina no final do sulco.

Para maior precisão, o aplicativo deve preferir a média das estacas ou uma integração espacial, em vez da média simples entre apenas início e final.

### 31.4 Lâmina média aplicada com redução de vazão

Quando a vazão é reduzida durante a aplicação:

```text
Lm = [((Tt - Tr) * qi) + (Tr * qr)] / (C * L) * 3600
```

Onde:

- `Tt`: tempo total de aplicação, em `h`;
- `Tr`: tempo durante o qual a vazão reduzida é aplicada, em `h`;
- `qi`: vazão inicial, em `L/s`;
- `qr`: vazão reduzida, em `L/s`;
- `C`: comprimento do sulco, em `m`;
- `L`: largura da faixa umedecida, em `m`.

Para facilitar o manejo, o material recomenda que `Tr` seja múltiplo de `Tt`. Na implementação, essa regra deve ser tratada como recomendação operacional, não como restrição matemática obrigatória.

## 32. Eficiência da irrigação por sulcos

Os principais parâmetros apresentados são:

- eficiência de condução (`Ec`);
- eficiência de distribuição (`Ed`);
- eficiência de aplicação (`Ea`);
- grau de adequação (`GA`).

### 32.1 Excesso e déficit de água

**Excesso de água** pode resultar em:

- percolação profunda;
- escoamento superficial;
- lixiviação de nutrientes;
- afloramento ou elevação do lençol freático.

**Déficit de água** pode ocorrer quando há excesso de infiltração no início e deficiência no final, reduzindo a uniformidade de distribuição e o atendimento da cultura.

### 32.2 Eficiência de condução

Estima a perda de água entre a captação e a entrada na parcela:

```text
Ec = (Va / Vd) * 100
```

Onde:

- `Ec`: eficiência de condução, em `%`;
- `Va`: volume de água aplicado na área, em `m³`;
- `Vd`: volume derivado do reservatório para irrigação, em `m³`.

É especialmente importante quando há bombeamento, longas distâncias entre a fonte e a área ou disponibilidade limitada de água.

### 32.3 Eficiência de distribuição

Estima a uniformidade da infiltração ao longo do sulco:

```text
Ed = Lf / ((Li + Lf) / 2) * 100
```

Onde:

- `Ed`: eficiência de distribuição, em `%`;
- `Lf`: lâmina infiltrada no final do sulco, em `mm`;
- `Li`: lâmina infiltrada no início do sulco, em `mm`.

Como referência do material, valores acima de `70%` podem indicar condição adequada, exceto em solos muito permeáveis. Em irrigação por sulcos, `Ed` deve ser analisada junto com `Ea`, pois a eficiência de aplicação pode ser mais determinante.

### 32.4 Eficiência de aplicação

O material lista `Ea` como parâmetro principal, mas não apresenta uma única fórmula nas imagens recebidas. A aplicação deve deixar a fórmula configurável conforme o método adotado e registrar qual definição foi usada.

Uma forma geral é:

```text
Ea = (volume ou lâmina útil recebido pela zona radicular
      / volume ou lâmina aplicada) * 100
```

O numerador deve ser definido de acordo com o critério agronômico adotado, evitando misturar lâmina infiltrada, lâmina armazenada e lâmina necessária.

### 32.5 Grau de adequação

`GA` indica quanto da área recebeu pelo menos a lâmina mínima necessária. Deve ser calculado a partir da distribuição espacial das lâminas e do limite de atendimento definido para a cultura.

## 33. Estrutura de dados para reposição e dimensionamento

```json
{
  "fase_reposicao": {
    "inicio": "inicio_escoamento_final_parcela",
    "fim": "tempo_corte",
    "tempo_corte_h": null,
    "escoamento_reutilizado": false,
    "observacao": "Verificar atendimento da lamina necessaria no final do sulco"
  },
  "tempos_por_estaca": [
    {
      "estaca_m": 0.0,
      "tempo_avanco_min": null,
      "tempo_deplecao_min": null,
      "tempo_recesso_min": null,
      "tempo_oportunidade_min": null
    }
  ],
  "geometria": {
    "forma": "V",
    "largura_superior_m": null,
    "profundidade_m": null,
    "espacamento_sulcos_m": null
  },
  "dimensionamento": {
    "comprimento_sulco_m": null,
    "declividade_percentual": null,
    "textura_solo": null,
    "vazao_aplicada_l_s": null,
    "vazao_maxima_nao_erosiva_l_s": null,
    "metodo_qmax": "por_textura"
  },
  "laminas_mm": {
    "inicio": null,
    "final": null,
    "media_infiltrada": null,
    "media_aplicada": null,
    "necessaria": null
  },
  "eficiencias_percentual": {
    "conducao": null,
    "distribuicao": null,
    "aplicacao": null,
    "grau_adequacao": null
  }
}
```

## 34. Regras de validação para o aplicativo completo

- o tempo de corte deve ser posterior ao início do escoamento final quando houver escoamento;
- `T_o(i)` não pode ser negativo;
- `T_o(i)` deve ser calculado com os instantes e durações na mesma unidade;
- o comprimento deve ser compatível com o tempo de avanço medido ou estimado;
- a vazão aplicada deve ser comparada com a vazão máxima não erosiva;
- a fórmula de `qmax` deve registrar a textura e a unidade da declividade;
- `L`, `C` e as vazões devem usar unidades compatíveis nas fórmulas de lâmina;
- valores de lâmina devem registrar se são infiltrados, aplicados ou necessários;
- a eficiência deve exibir sua definição e seus dados de entrada;
- resultados derivados devem manter os valores originais que os produziram;
- alertas de deficiência no final e excesso no início devem ser gerados a partir das lâminas por estaca;
- o sistema deve diferenciar regra prática, estimativa de campo e resultado de modelo;
- fórmulas com parâmetros de fonte bibliográfica devem manter a referência e a versão dos parâmetros.

## 35. Eficiência de aplicação

A eficiência de aplicação (`Ea`) estima a porcentagem da água aplicada que é considerada útil para a cultura.

```text
Ea = (Lf / Lm) * 100
```

Onde:

- `Ea`: eficiência de aplicação, em `%`;
- `Lf`: lâmina infiltrada no final do sulco, em `mm`;
- `Lm`: lâmina média aplicada por sulco, em `mm`.

### 35.1 Referências de interpretação

As imagens apresentam:

- **valor mínimo aceitável:** `60%`;
- **valor ideal:** acima de `70%`;
- em um exemplo posterior, aparece a referência de eficiência ideal acima de `75%` e aceitável acima de `60%`.

Como os limites variam conforme a fonte ou o critério adotado, o aplicativo deve guardar os limites como parâmetros configuráveis, vinculados à referência usada.

Uma configuração possível:

```json
{
  "eficiencia_aplicacao": {
    "minimo_aceitavel_percentual": 60.0,
    "ideal_percentual": 75.0,
    "fonte_limite": "parametro_configuravel"
  }
}
```

## 36. Grau de adequação

O grau de adequação (`GA`) indica quanto da lâmina aplicada atende às necessidades da cultura ao longo do sulco.

```text
GA = (lâmina infiltrada útil / lâmina requerida) * 100
```

### Interpretação

- `GA = 100%`: atendimento ideal da lâmina requerida;
- `GA < 100%`: déficit de água em parte da área;
- `GA > 100%`: excesso de água em relação à necessidade, potencialmente associado à percolação profunda.

> Em aplicações mais completas, o GA deve ser calculado espacialmente, considerando a lâmina útil em cada ponto. Uma razão entre duas lâminas médias é uma aproximação e não representa sozinha a uniformidade.

## 37. Perdas de água

### 37.1 Perdas por percolação profunda

```text
Pp = [(Lmi - LL) / Lm] * 100
```

Onde:

- `Pp`: perdas por percolação profunda, em `%`;
- `Lmi`: lâmina média infiltrada no sulco, em `mm`;
- `LL`: lâmina líquida necessária, em `mm`;
- `Lm`: lâmina média aplicada, em `mm`.

Se `Lmi < LL`, a expressão produz valor negativo. Nesse caso, o resultado deve ser classificado como déficit e não como uma perda negativa. Para exibição:

```text
Pp_exibida = max(0, Pp)
```

mantendo o valor matemático original em um campo separado para auditoria.

### 37.2 Perdas por escoamento superficial

```text
Pe = [(Lm - Lmi) / Lm] * 100
```

Onde:

- `Pe`: perdas por escoamento superficial, em `%`;
- `Lm`: lâmina média aplicada, em `mm`;
- `Lmi`: lâmina média infiltrada, em `mm`.

Essa fórmula representa a parcela aplicada que não foi infiltrada, assumindo que a diferença seja atribuída ao escoamento superficial. Em um balanço completo, outras parcelas devem ser consideradas, como armazenamento superficial e perdas de condução.

## 38. Exemplo completo de eficiência

### 38.1 Dados do exemplo

| Variável | Valor |
|---|---:|
| Lâmina necessária no final (`Lf`) | `30,0 mm` |
| Comprimento do sulco | `200 m` |
| Espaçamento entre sulcos | `1 m` |
| Vazão | `1 L/s` |
| Tempo de avanço | `60 min` |
| Tempo de infiltração após o avanço | `140 min` |
| Tempo total de irrigação | `200 min` |

O tempo total em horas é:

```text
Tt = 200 / 60 = 3,3333333333333335 h
```

### 38.2 Lâmina média aplicada

Para vazão constante:

```text
Lm = (Tt * qc / (C * L)) * 3600
Lm = (3,3333333333333335 * 1 / (200 * 1)) * 3600
Lm = 60,0 mm
```

### 38.3 Lâmina no início do sulco

Usando a equação aproximada de infiltração acumulada apresentada no exemplo:

```text
Li = 0,85 * 200^0,68
Li ≈ 31,2 mm
```

Usando os parâmetros de alta precisão do ensaio de infiltração deste documento, o valor deve ser recalculado com a equação precisa e pode apresentar pequena diferença.

### 38.4 Lâmina média infiltrada

Usando a média entre início e final:

```text
Lmi = (Li + Lf) / 2
Lmi = (31,2 + 30,0) / 2
Lmi = 30,6 mm
```

### 38.5 Eficiência de distribuição

```text
Ed = [Lf / ((Li + Lf) / 2)] * 100
Ed = [30,0 / 30,6] * 100
Ed = 98,0392156862745%
```

Resultado para apresentação:

```text
Ed ≈ 98%
```

### 38.6 Eficiência de aplicação

```text
Ea = (Lf / Lm) * 100
Ea = (30,0 / 60,0) * 100
Ea = 50%
```

Interpretação:

- `Ea = 50%` está abaixo do mínimo aceitável de `60%` indicado no material;
- aproximadamente `50%` da lâmina aplicada não é contabilizada como lâmina útil no final do sulco;
- o sistema possui boa uniformidade aproximada (`Ed ≈ 98%`), mas baixa eficiência de aplicação (`Ea = 50%`);
- uniformidade alta não significa necessariamente uso eficiente da água.

### 38.7 Perdas estimadas no exemplo

Considerando `LL = 30,0 mm`:

```text
Pp = [(30,6 - 30,0) / 60,0] * 100
Pp = 1,0%
```

```text
Pe = [(60,0 - 30,6) / 60,0] * 100
Pe = 49,0%
```

Esses valores são uma aproximação baseada nas fórmulas apresentadas. A separação real entre percolação, escoamento e armazenamento deve usar um balanço de água medido.

## 39. Principais causas de desempenho insatisfatório

### 39.1 Problemas de uniformidade

Problemas de uniformidade resultam de variações da quantidade de água infiltrada ao longo da área irrigada. As causas incluem:

- dimensionamento inadequado, como comprimento excessivo, vazão muito reduzida ou tempo de aplicação muito reduzido;
- sistematização grosseira, com variação acentuada do gradiente de declive;
- variação do solo, incluindo textura, estrutura, condição superficial e teor de água;
- compactação diferencial natural ou causada por veículos, máquinas, implementos e equipamentos;
- variação da seção de escoamento por erosão ou tratos culturais;
- erosão superficial provocada pela irrigação ou por chuvas;
- variação da resistência ao escoamento, causada pelo desenvolvimento de plantas ou pelos tratos culturais.

### 39.2 Problemas de eficiência

As causas destacadas são:

- comprimento muito reduzido ou muito longo;
- vazão muito reduzida ou muito elevada;
- tempo de aplicação muito reduzido ou muito elevado;
- variação das características de infiltração;
- operação inadequada do sistema.

## 40. Práticas de manejo

### 40.1 Para aumentar a uniformidade de distribuição

- aumentar a vazão, respeitando o limite não erosivo;
- aumentar o tempo de aplicação quando houver deficiência no final;
- reduzir o comprimento das parcelas;
- aumentar o gradiente de declive dentro dos limites seguros;
- construir diques para contenção de água no final das parcelas;
- adotar fluxo pulsante, também chamado `surge flow`, com aplicação em períodos curtos e alternados.

### 40.2 Para reduzir perdas por percolação profunda

- aumentar a vazão para aumentar a razão de avanço;
- reduzir o tempo de aplicação para reduzir o tempo de infiltração;
- reduzir o comprimento das parcelas;
- aumentar o gradiente de declive dentro do limite de erosão;
- reduzir a razão de infiltração por manejo ou compactação controlada da superfície;
- reduzir o perímetro molhado alterando a forma da seção transversal do sulco.

### 40.3 Para reduzir perdas por escoamento superficial

- reduzir a vazão após a água atingir o final da parcela;
- reduzir o tempo de aplicação;
- aumentar o comprimento das parcelas quando isso não comprometer a uniformidade;
- reduzir o gradiente de declive quando possível;
- aumentar a infiltração por incorporação de matéria orgânica ou revolvimento da superfície;
- aumentar o perímetro molhado da seção de escoamento;
- conter a água no final das parcelas;
- reutilizar a água excedente do deflúvio.

### 40.4 Para aumentar o armazenamento no solo

Esta estratégia é indicada quando a deficiência de água disponível no solo é o principal problema e as perdas do processo de aplicação não são o fator limitante:

- reduzir a vazão para reduzir a razão de avanço;
- aumentar o tempo de aplicação para aumentar o tempo de infiltração;
- reduzir o comprimento das parcelas;
- reduzir o gradiente de declive;
- aumentar a razão de infiltração;
- aumentar o perímetro molhado da seção de escoamento;
- conter a água no final das parcelas.

## 41. Regras de diagnóstico e recomendação

| Diagnóstico | Indicadores | Ações candidatas |
|---|---|---|
| Boa uniformidade, baixa eficiência | `Ed` alto e `Ea` baixo | reduzir tempo de aplicação, ajustar vazão, reduzir comprimento ou reutilizar escoamento |
| Baixa lâmina no final | `Lf < LL` ou `GA < 100%` | aumentar tempo de aplicação, aumentar vazão com segurança ou reduzir comprimento |
| Excesso no início | `Li` muito maior que `Lf` | reduzir tempo de aplicação, aumentar avanço ou ajustar comprimento |
| Escoamento superficial elevado | `Pe` alto | reduzir vazão após chegada ao final, conter ou reutilizar água |
| Percolação elevada | `Pp` alto | reduzir tempo de oportunidade, ajustar vazão e melhorar o manejo da infiltração |
| Risco de erosão | `q_aplicada > qmax` | reduzir vazão, alterar declividade ou modificar a geometria |
| Variabilidade entre estacas | grande dispersão de `yi` | verificar nivelamento, solo, compactação, erosão e seção do sulco |

As ações são candidatas de manejo. O aplicativo deve apresentar o motivo do alerta e os dados que levaram à recomendação, evitando indicar uma alteração isolada sem verificar seus efeitos sobre os demais indicadores.

## 42. Estrutura JSON de eficiência e diagnóstico

```json
{
  "eficiencia": {
    "lamina_necessaria_mm": 30.0,
    "lamina_final_mm": 30.0,
    "lamina_inicio_mm": 31.2,
    "lamina_media_infiltrada_mm": 30.6,
    "lamina_media_aplicada_mm": 60.0,
    "eficiencia_distribuicao_percentual": 98.0392156862745,
    "eficiencia_aplicacao_percentual": 50.0,
    "grau_adequacao_percentual": null,
    "perda_percolacao_percentual": 1.0,
    "perda_escoamento_percentual": 49.0
  },
  "criterios": {
    "eficiencia_aplicacao_minima_percentual": 60.0,
    "eficiencia_aplicacao_ideal_percentual": 75.0,
    "grau_adequacao_ideal_percentual": 100.0
  },
  "diagnostico": {
    "uniformidade": "alta",
    "eficiencia_aplicacao": "inaceitavel",
    "principal_problema": "excesso_de_agua_aplicada",
    "acoes_sugeridas": [
      "reduzir_tempo_de_aplicacao",
      "ajustar_vazao",
      "avaliar_reutilizacao_do_escoamento"
    ]
  }
}
```

## 43. Redução de vazão após a chegada ao final

Quando o escoamento superficial no final do sulco é elevado, pode-se reduzir a vazão depois que a água alcança o final da parcela. Essa estratégia reduz o volume que sai pelo final sem interromper completamente a infiltração.

### 43.1 Estimativa da vazão reduzida

A forma apresentada nas imagens é:

```text
Qr = (1,1 * f0 * L * E) / 3600
```

Onde:

- `Qr`: vazão reduzida, em `L/s`;
- `f0`: taxa de infiltração considerada no final do sulco, em `mm/h`;
- `L`: comprimento do sulco, em `m`;
- `E`: espaçamento entre sulcos ou largura representativa, em `m`;
- `1,1`: fator de ajuste apresentado no material;
- `3600`: conversão de horas para segundos.

O fator `1,1` deve ser tratado como parâmetro configurável, pois sua aplicação depende do critério de dimensionamento adotado.

### 43.2 Exemplo da vazão reduzida

Dados usados no exemplo:

```text
f0 = 7,9 mm/h
L = 200 m
E = 1 m
```

Usando a forma exibida no material:

```text
Qr = (7,9 * 200 * 1) / 3600
Qr = 0,4388888888888889 L/s
Qr ≈ 0,44 L/s
```

> A imagem apresenta a expressão com o fator `1,1`, mas substitui numericamente `7,9 * 200 * 1 / 3600`, sem multiplicar explicitamente por `1,1`. O aplicativo deve registrar qual versão foi aplicada para evitar divergência de resultados.

## 44. Lâmina média aplicada com redução de vazão — exemplo

Dados:

```text
Tt = 3,33 h
Tr = 2,33 h
qi = 1,00 L/s
qr = 0,44 L/s
C = 200 m
L = 1 m
```

Fórmula:

```text
Lm = [((Tt - Tr) * qi) + (Tr * qr)] / (C * L) * 3600
```

Substituindo os valores arredondados do exemplo:

```text
Lm = [((3,33 - 2,33) * 1,00) + (2,33 * 0,44)] / (200 * 1) * 3600
Lm ≈ 36,45 mm
```

Para maior precisão, use os tempos convertidos diretamente de minutos e a vazão reduzida sem arredondar:

```text
Tt = 200 / 60 = 3,3333333333333335 h
Tr = 140 / 60 = 2,3333333333333335 h
Qr = 0,4388888888888889 L/s
Lm = 36,41666666666667 mm
```

Assim, `36,45 mm` é o resultado do exemplo com valores arredondados, enquanto `36,41666666666667 mm` é o resultado com os valores não arredondados dessa interpretação.

## 45. Eficiências após a redução de vazão

Usando os valores do exemplo da imagem (`Lm = 36,45 mm`, `Lmi = 30,6 mm`, `Lf = LL = 30,0 mm`):

### 45.1 Eficiência de aplicação

```text
Ea = (Lf / Lm) * 100
Ea = (30,0 / 36,45) * 100
Ea = 82,3045267489712%
```

Resultado para apresentação:

```text
Ea ≈ 82,3%
```

### 45.2 Perda por percolação profunda

```text
Pp = [(Lmi - LL) / Lm] * 100
Pp = [(30,6 - 30,0) / 36,45] * 100
Pp = 1,64609053497942%
```

Resultado para apresentação:

```text
Pp ≈ 1,64%
```

### 45.3 Perda por escoamento superficial

```text
Pe_escoamento = [(Lm - Lmi) / Lm] * 100
Pe_escoamento = [(36,45 - 30,6) / 36,45] * 100
Pe_escoamento = 16,0493827160494%
```

Resultado para apresentação:

```text
Pe_escoamento ≈ 16,04%
```

### 45.4 Diagnóstico do exemplo

Comparando com os limites apresentados nas imagens:

- `Ea ≈ 82,3%`: acima do ideal indicado de `75%`;
- `Pp ≈ 1,64%`: abaixo do limite de `15%` apresentado;
- `Pe_escoamento ≈ 16,04%`: acima do limite de `10%` apresentado;
- a redução de vazão melhora muito a eficiência de aplicação, mas ainda pode exigir contenção ou reutilização do escoamento final.

## 46. Tempo de irrigação

Quando as fases de depleção e recesso são desprezíveis, pode-se aproximar o tempo total de irrigação por:

```text
Ti = To + Ta
```

Onde:

- `Ti`: tempo de irrigação, em `h`;
- `To`: tempo de oportunidade, em `h`;
- `Ta`: tempo de avanço até o final da parcela, em `h`.

Essa relação deve ser usada apenas quando a curva de recesso puder ser considerada aproximadamente constante ou quando depleção e recesso forem desprezíveis.

> Para evitar conflito com o tempo de infiltração usado em outras partes do documento, o código deve preferir `tempo_irrigacao_h`, `tempo_oportunidade_h` e `tempo_avanco_h` em vez de armazenar apenas `Ti`, `To` e `Ta`.

## 47. Turno de rega

O turno de rega pode ser estimado por:

```text
TR = CRA / (ETc - Pef)
```

Onde:

- `TR`: turno de rega, em dias;
- `CRA`: capacidade real de água no solo, em `mm`;
- `ETc`: evapotranspiração da cultura, em `mm/dia`;
- `Pef`: precipitação efetiva, em `mm/dia`, quando houver contribuição de chuva.

### 47.1 Validações

- `ETc - Pef` deve ser maior que zero;
- se `Pef >= ETc`, não há necessidade líquida de irrigação no período, mas a decisão deve considerar armazenamento no solo;
- `CRA` deve estar na mesma unidade de lâmina usada por `ETc` e `Pef`;
- o resultado deve ser armazenado com casas decimais, mas apresentado em dias e horas conforme necessário.

> Atenção à sigla: neste documento, `Pe_escoamento` representa perda por escoamento superficial. Para precipitação efetiva, usar `Pef` para não confundir os conceitos.

## 48. Número total de sulcos

O número total de sulcos depende do comprimento e da largura total da área, do comprimento do sulco e do espaçamento entre sulcos:

```text
NTS = (Lt * Wt) / (L * E)
```

Onde:

- `NTS`: número total de sulcos ou unidades equivalentes;
- `Lt`: comprimento total da área, em `m`;
- `Wt`: largura total da área, em `m`;
- `L`: comprimento de cada sulco, em `m`;
- `E`: espaçamento entre sulcos, em `m`.

### 48.1 Arredondamento operacional

O resultado pode não ser inteiro. Para planejamento físico, o aplicativo deve oferecer:

- `ceil`: arredondar para cima quando for necessário cobrir toda a área;
- `floor`: arredondar para baixo quando houver limite de capacidade;
- valor decimal: manter para análise teórica.

O modo de arredondamento deve ser registrado no resultado.

## 49. Número de sulcos por dia

```text
NSD = NTS / PI
```

Onde:

- `NSD`: número de sulcos por dia;
- `NTS`: número total de sulcos;
- `PI`: período de irrigação, em dias.

Para planejamento operacional, o número efetivo de sulcos por dia deve considerar a capacidade real de trabalho e ser arredondado de acordo com o objetivo do projeto.

## 50. Tempo de irrigação por parcela

Além do tempo de irrigação de cada sulco, deve-se considerar o tempo necessário para mudar o sistema de distribuição de água de uma parcela para outra:

```text
TIP = ti + tmud
```

Onde:

- `TIP`: tempo de irrigação por parcela, em `h`;
- `ti`: tempo de irrigação do sulco ou da parcela, em `h`;
- `tmud`: tempo de mudança do sistema de distribuição, em `h`.

O tempo de mudança inclui deslocamento, reposicionamento de tubulações, abertura e fechamento de entradas e estabilização da vazão.

## 51. Número de parcelas irrigadas por dia

Conhecendo a jornada diária de funcionamento:

```text
NPD = TDF / TIP
```

Onde:

- `NPD`: número de parcelas que podem ser irrigadas por dia;
- `TDF`: tempo de funcionamento diário, em `h`;
- `TIP`: tempo de irrigação por parcela, em `h`.

O valor teórico pode ser decimal. Para operação, o número de parcelas completas deve normalmente ser arredondado para baixo, salvo quando houver planejamento de uma parcela parcial.

## 52. Número de sulcos por parcela

```text
NSP = NSD / NPD
```

Onde:

- `NSP`: número de sulcos por parcela;
- `NSD`: número de sulcos que devem ser atendidos por dia;
- `NPD`: número de parcelas irrigáveis por dia.

O resultado deve ser compatível com a geometria real da parcela. Se houver necessidade de atender uma fração de parcela, o aplicativo deve mostrar a quantidade inteira planejada e o restante.

## 53. Vazão necessária no projeto

A vazão de projeto depende do número de sulcos irrigados simultaneamente e das perdas no sistema de distribuição:

```text
Q = NSP * Q0 + PC
```

Onde:

- `Q`: vazão necessária no projeto, em `L/s`;
- `NSP`: número de sulcos irrigados simultaneamente ou por parcela, conforme o arranjo adotado;
- `Q0`: vazão de entrada por sulco, em `L/s`;
- `PC`: perdas no sistema, em `L/s`.

As perdas podem incluir infiltração em canais, vazamentos em tubulações e outras perdas de condução. O aplicativo deve indicar se `PC` foi fornecida diretamente em `L/s` ou calculada como percentual.

## 54. Estrutura JSON para operação e projeto

```json
{
  "manejo_vazao": {
    "vazao_inicial_l_s": 1.0,
    "vazao_reduzida_l_s": 0.4388888888888889,
    "fator_ajuste_qr": 1.1,
    "reducao_apos_chegada_final": true
  },
  "eficiencia_com_reducao": {
    "lamina_media_aplicada_mm": 36.41666666666667,
    "eficiencia_aplicacao_percentual": 82.37986270022883,
    "perda_percolacao_percentual": 1.6475972540045805,
    "perda_escoamento_percentual": 15.972540045766598
  },
  "operacao": {
    "tempo_avanco_h": null,
    "tempo_oportunidade_h": null,
    "tempo_irrigacao_h": null,
    "tempo_mudanca_h": null,
    "tempo_irrigacao_parcela_h": null,
    "tempo_funcionamento_diario_h": null
  },
  "planejamento": {
    "capacidade_real_agua_solo_mm": null,
    "evapotranspiracao_cultura_mm_dia": null,
    "precipitacao_efetiva_mm_dia": null,
    "turno_rega_dias": null,
    "comprimento_total_area_m": null,
    "largura_total_area_m": null,
    "comprimento_sulco_m": null,
    "espacamento_sulcos_m": null,
    "numero_total_sulcos": null,
    "numero_sulcos_dia": null,
    "numero_parcelas_dia": null,
    "numero_sulcos_parcela": null,
    "vazao_projeto_l_s": null,
    "perdas_conducao_l_s": null
  }
}
```

## 55. Validações adicionais

- não misturar `Pe_escoamento` com `Pef` de precipitação efetiva;
- registrar se a vazão reduzida foi calculada com ou sem o fator `1,1`;
- usar minutos ou horas de forma consistente em cada fórmula;
- não arredondar `Qr` antes de calcular a lâmina, quando for necessária alta precisão;
- `Tt` deve ser maior ou igual a `Tr`;
- `qi` e `qr` devem ser não negativos e `qr ≤ qi` em uma redução de vazão;
- `NTS`, `NSD`, `NPD` e `NSP` devem guardar o valor teórico e o valor operacional arredondado;
- `TIP` deve incluir o tempo de mudança quando o sistema atende parcelas diferentes;
- `Q` deve incluir perdas apenas uma vez;
- `ETc - Pef` não pode ser negativo sem tratamento explícito;
- valores de eficiência devem ser acompanhados dos limites usados para classificação;
- toda recomendação de manejo deve indicar quais indicadores pretende melhorar e quais podem piorar.

## 56. Caso de teste principal — projeto de milho

As imagens desta etapa apresentam um projeto completo de irrigação por sulcos para milho. Este caso deve ser armazenado no aplicativo como **caso de teste de integração**, pois percorre várias etapas do dimensionamento: solo, cultura, lâmina necessária, turno de rega, avanço, infiltração, comprimento, vazão, eficiência e operação.

### 56.1 Dados da área e da cultura

| Parâmetro | Valor |
|---|---:|
| Cultura | Milho |
| Área retangular | `540 m × 200 m` |
| Espaçamento entre fileiras | `0,90 m` |
| Espaçamento entre plantas | `0,20 m` |
| Profundidade efetiva das raízes (`z`) | `0,50 m` |
| Declividade indicada no esquema | `0,5%` |
| Período | Segunda quinzena de janeiro |
| Evapotranspiração de referência (`ETo`) | `6,4 mm/dia` |
| Evapotranspiração da cultura (`ETc`) | `7,0 mm/dia` |
| Coeficiente de cultura (`Kc`) | `1,1` |
| Precipitação provável efetiva | `3,0 mm/dia` |
| Demanda líquida diária de irrigação | `4,0 mm/dia` |

### 56.2 Dados do solo

| Parâmetro | Valor |
|---|---:|
| Textura | Argilosa |
| Umidade na capacidade de campo (`UCC`) | `30,5%` |
| Umidade no ponto de murcha permanente (`UPMP`) | `18,0%` |
| Densidade do solo (`Ds`) | `1,12 g/cm³` |
| Velocidade básica de infiltração (`VIB`) | `9,0 mm/h` |
| Fração de água disponível utilizada (`f`) | `0,60` |

### 56.3 Entradas obrigatórias no formulário

Para que o caso seja reproduzível, o aplicativo deve pedir explicitamente:

- largura do sulco;
- profundidade do sulco;
- declividade do sulco em `%`;
- espaçamento entre sulcos;
- comprimento ou dimensões da área;
- textura do solo;
- UCC, UPMP e densidade do solo;
- profundidade efetiva das raízes;
- fração de água disponível utilizada;
- vazões testadas e vazão escolhida;
- equação ou dados da curva de avanço;
- equação de infiltração;
- demanda líquida de irrigação;
- jornada de trabalho e tempo de mudança entre parcelas.

> Largura e profundidade são dados geométricos do sulco. A declividade em porcentagem é um dado topográfico separado. O formulário não deve inferir um desses valores a partir dos outros.

### 56.4 Equações de campo do caso

As imagens fornecem as seguintes equações para o cenário:

```text
VI = 1,411 * T^-0,446
```

Unidade indicada:

```text
VI: L/min por metro de sulco
T: min
```

```text
I = 2,547 * T^0,554
```

Unidade indicada:

```text
I: L por metro de sulco
T: min
```

Essas unidades são diferentes das equações de infiltração em `mm/h` apresentadas anteriormente. O aplicativo deve armazenar a unidade junto com cada equação e não reutilizar os parâmetros sem conversão.

### 56.5 Lâmina requerida líquida

A fórmula usada nas imagens é:

```text
IRN = [(UCC - UPMP) / 10] * Ds * z_cm * f
```

Com os valores do caso:

```text
IRN = [(30,5 - 18,0) / 10] * 1,12 * 50 * 0,60
IRN = 42,0 mm
```

Onde `z_cm = 50 cm`. Se `z` for armazenado em metros, a implementação deve converter para centímetros ou usar uma fórmula equivalente com fator de conversão explícito.

### 56.6 Turno de rega do caso

```text
TR = IRN / demanda_diaria
TR = 42,0 / 4,0
TR = 10,5 dias
```

O material apresenta `10 dias` como resultado operacional. O sistema deve preservar:

```text
valor_calculado = 10,5 dias
valor_operacional = 10 dias
```

O arredondamento para baixo é mais conservador para evitar que a cultura ultrapasse o intervalo de disponibilidade de água.

### 56.7 Teste de avanço e seleção de vazão

Foram testadas as vazões:

```text
0,4; 0,6; 0,8; 1,0; 1,5 L/s
```

A vazão de `1,5 L/s` provocou erosão nos sulcos e deve ser marcada como **reprovada** para esse solo e essa geometria.

O aplicativo deve registrar os testes como dados experimentais, não apenas como uma lista de opções:

| Vazão (L/s) | Resultado |
|---:|---|
| 0,4 | Testada |
| 0,6 | Testada |
| 0,8 | Testada |
| 1,0 | Testada e escolhida no exemplo |
| 1,5 | Reprovada: erosão observada |

### 56.8 Tempo de oportunidade para infiltrar `42 mm`

Como o espaçamento entre fileiras é `0,90 m`, a equação usada no material é:

```text
42 = (2,547 / 0,9) * T^0,554
```

Resolvendo:

```text
T = [42 * 0,9 / 2,547]^(1 / 0,554)
T = 130,1828843687218 min
```

Resultado de apresentação:

```text
To ≈ 130 min
```

### 56.9 Comparação de comprimento: `100 m` e `200 m`

O teste de avanço indica aproximadamente:

| Comprimento | Tempo de avanço informado |
|---:|---:|
| `100 m` | `35 min` |
| `200 m` | `90 min` |

O tempo total de aplicação é:

```text
Ti = Ta + To
```

#### Alternativa de `100 m`

```text
Ti = 35 + 130,1828843687218
Ti = 165,1828843687218 min
```

Com `q = 1 L/s`, `C = 100 m` e `L = 0,90 m`:

```text
Lm = [q * (Ti / 60) / (C * L)] * 3600
Lm = 110,1219229124812 mm
```

```text
Ea = 42 / 110,1219229124812 * 100
Ea = 38,13954468755442%
```

Resultado aproximado do material:

```text
Lm ≈ 110 mm
Ea ≈ 38%
```

#### Alternativa de `200 m`

```text
Ti = 90 + 130,1828843687218
Ti = 220,1828843687218 min
```

```text
Lm = [1 * (Ti / 60) / (200 * 0,90)] * 3600
Lm = 73,39429478957395 mm
```

```text
Ea = 42 / 73,39429478957395 * 100
Ea = 57,22515642451042%
```

Resultado aproximado do material:

```text
Lm ≈ 73 mm
Ea ≈ 57%
```

O comprimento de `200 m` apresenta eficiência melhor que `100 m`, mas ainda fica abaixo do limite de aceitação usado no material. Por isso, é avaliada a redução de vazão após a chegada da água ao final.

### 56.10 Redução de vazão no sulco de `200 m`

O método da soma das infiltrações parciais estima vazão de saída de aproximadamente:

```text
44,81 L/min = 0,7468333333333333 L/s
```

O material arredonda para `0,75 L/s`.

Manejo indicado no exemplo:

- vazão inicial: `1,0 L/s` durante `90 min`;
- vazão reduzida: `0,75 L/s` durante `20 min`;
- tempo total: `110 min`.

Com os valores arredondados do material:

```text
Lm = [((3,66 - 1,83) * 1,0) + (1,83 * 0,75)] / (200 * 0,9) * 3600
Lm ≈ 64,0 mm
```

```text
Ea = 42 / 64,0 * 100
Ea ≈ 65,6%
```

O material apresenta `Ea = 66%`. O valor deve ser classificado como aceitável quando o limite adotado for `60%`.

> O tempo `110 min` dessa etapa é o período de aplicação usado para calcular a lâmina com redução de vazão. Ele não deve ser confundido com o tempo de oportunidade total de `130 min` usado para atingir a lâmina requerida.

### 56.11 Saída esperada do caso de teste principal

```json
{
  "id": "caso_teste_milho_540x200",
  "cultura": "milho",
  "area": {
    "comprimento_m": 540.0,
    "largura_m": 200.0,
    "declividade_percentual": 0.5
  },
  "sulco": {
    "espacamento_m": 0.9,
    "largura_m": null,
    "profundidade_m": null,
    "vazao_inicial_l_s": 1.0,
    "comprimento_escolhido_m": 200.0,
    "vazao_reduzida_l_s": 0.75
  },
  "solo": {
    "textura": "argilosa",
    "ucc_percentual": 30.5,
    "upmp_percentual": 18.0,
    "densidade_g_cm3": 1.12,
    "vib_mm_h": 9.0,
    "fracao_agua_disponivel": 0.6
  },
  "necessidade": {
    "irn_mm": 42.0,
    "demanda_mm_dia": 4.0,
    "turno_calculado_dias": 10.5,
    "turno_operacional_dias": 10
  },
  "resultado_com_reducao": {
    "tempo_avanco_min": 90.0,
    "tempo_aplicacao_min": 110.0,
    "lamina_media_aplicada_mm_aproximada": 64.0,
    "eficiencia_aplicacao_percentual_aproximada": 65.6,
    "classificacao": "aceitavel"
  },
  "testes_vazao": [
    { "vazao_l_s": 0.4, "status": "testada" },
    { "vazao_l_s": 0.6, "status": "testada" },
    { "vazao_l_s": 0.8, "status": "testada" },
    { "vazao_l_s": 1.0, "status": "selecionada" },
    { "vazao_l_s": 1.5, "status": "reprovada", "motivo": "erosao" }
  ]
}
```

## 57. Segundo cenário de teste — área de `16 ha`

As últimas imagens também apresentam um cenário complementar, com dados diferentes. Ele deve ser armazenado como outro caso de teste, sem sobrescrever o caso do milho de `540 m × 200 m`.

### 57.1 Entradas do cenário

| Parâmetro | Valor |
|---|---:|
| Área | `16 ha` (`400 m × 400 m`) |
| Cultura | Milho |
| Espaçamento entre sulcos | `1,0 m` |
| Profundidade das raízes (`z`) | `0,50 m` |
| Fração de água disponível (`f`) | `0,50` |
| Evapotranspiração da cultura | `4,2 mm/dia` |
| UCC | `28%` |
| UPMP | `17%` |
| Densidade do solo | `1,4 g/cm³` |
| VIB | `9,0 mm/h` |
| Vazão utilizada | `1,0 L/s` |
| Parâmetros práticos de vazão | `C = 0,631`, `a = 1` |
| Declividades mostradas no esquema | `0,1%` e `0,5%` |

Equações informadas para o cenário:

```text
Ta(min) = 0,0019 * L(m)^1,96
VI(mm/h) = 36 * T(min)^-0,32
```

### 57.2 Lâmina líquida e turno de rega do cenário

Aplicando a mesma estrutura de cálculo:

```text
IRN = [(28 - 17) / 10] * 1,4 * 50 * 0,5
IRN = 38,5 mm
```

```text
TR = 38,5 / 4,2
TR = 9,166666666666666 dias
```

Resultado operacional possível, se o manejo arredondar para baixo:

```text
TR_operacional = 9 dias
```

### 57.3 Validação do segundo cenário

Como as imagens não fornecem um comprimento final escolhido nem um teste completo de avanço para cada declividade, o aplicativo deve marcar este cenário como **parcialmente especificado**. Não deve inventar comprimento, tempo de avanço, tempo de oportunidade ou eficiência final.

Campos pendentes:

- largura do sulco;
- profundidade do sulco;
- declividade efetivamente escolhida;
- comprimento do sulco;
- tempo de oportunidade desejado;
- curva de avanço medida;
- tempo de irrigação;
- vazão de projeto;
- eficiência de aplicação e distribuição.

## 58. Especificação do formulário de entrada

Para evitar entradas incompletas, o formulário deve ser dividido em grupos.

### 58.1 Geometria e topografia

- comprimento total da área (`m`);
- largura total da área (`m`);
- comprimento do sulco (`m`);
- espaçamento entre sulcos (`m`);
- largura superior do sulco (`m` ou `cm`);
- profundidade do sulco (`m` ou `cm`);
- forma da seção;
- declividade do sulco (`%`).

### 58.2 Solo e cultura

- textura;
- UCC (`%`);
- UPMP (`%`);
- densidade do solo (`g/cm³`);
- profundidade efetiva das raízes (`m` ou `cm`);
- fração de água disponível;
- VIB (`mm/h`);
- espaçamento entre fileiras;
- cultura e fase de desenvolvimento.

### 58.3 Clima e necessidade hídrica

- ETo (`mm/dia`);
- Kc;
- ETc (`mm/dia`);
- precipitação efetiva (`mm/dia`);
- demanda líquida (`mm/dia`);
- período do ano.

### 58.4 Operação e ensaio

- vazão inicial (`L/s`);
- vazão reduzida (`L/s`);
- tempos de avanço por estaca;
- tempo de corte;
- tempo de mudança de parcela;
- horas disponíveis por dia;
- perdas de condução;
- existência de reutilização do escoamento.

## 59. Regras de caso de teste

Cada caso de teste deve guardar:

- entradas originais;
- unidades originais;
- equações escolhidas;
- parâmetros das equações;
- valores intermediários;
- resultados completos;
- resultados arredondados para apresentação;
- alertas e reprovações;
- versão do método ou da fonte;
- campos que ficaram pendentes.

O caso principal deve passar pelas seguintes verificações automatizadas:

1. calcular `IRN = 42 mm`;
2. calcular `TR = 10,5 dias`;
3. reprovar `q = 1,5 L/s` por erosão;
4. calcular `To ≈ 130 min`;
5. comparar comprimentos de `100 m` e `200 m`;
6. identificar que `200 m` com vazão constante produz eficiência aproximada de `57%`;
7. aplicar redução para `0,75 L/s`;
8. obter eficiência aproximada de `66%`;
9. preservar largura e profundidade como entradas pendentes, pois não foram fornecidas no exemplo;
10. não misturar as equações de infiltração deste caso com as equações dos outros ensaios.

## Observação técnica

Este documento organiza e verifica a matemática apresentada nos materiais enviados. O dimensionamento definitivo de um sistema de irrigação deve considerar dados de campo, propriedades hidráulicas e validação por profissional habilitado.

---

# 60. Plano de implementação por issues — OpenCode

Esta seção converte o conteúdo técnico do documento em tarefas implementáveis. Cada issue deve ser executada isoladamente, com testes automatizados e sem alterar fórmulas de outras issues sem registrar a mudança.

## 60.1 Regras para execução no OpenCode

Antes de implementar qualquer issue:

1. inspecionar a estrutura atual do projeto;
2. localizar modelos, serviços, telas e testes existentes;
3. reutilizar padrões já usados no projeto;
4. não criar dados fictícios quando o campo deve ser informado pelo usuário;
5. manter unidades explícitas em todos os cálculos;
6. preservar os valores completos e arredondar somente na apresentação;
7. adicionar ou atualizar testes antes de concluir a issue;
8. não misturar equações que usam unidades diferentes;
9. informar no resultado quais entradas, equações e parâmetros foram usados;
10. executar os testes existentes antes e depois da alteração.

## 60.2 Ordem recomendada

```text
ISSUE-001 → ISSUE-002 → ISSUE-003 → ISSUE-004
                         ↓
ISSUE-005 → ISSUE-006 → ISSUE-007 → ISSUE-008
                                      ↓
ISSUE-009 → ISSUE-010 → ISSUE-011 → ISSUE-012
                                      ↓
ISSUE-013 → ISSUE-014 → ISSUE-015
```

## 60.3 ISSUE-001 — Modelar os dados do projeto de irrigação

**Objetivo:** criar os modelos de domínio para armazenar um projeto completo.

**Escopo:**

- área e dimensões;
- geometria do sulco;
- declividade;
- solo;
- cultura;
- clima;
- vazões;
- ensaios;
- parâmetros de equações;
- resultados;
- alertas;
- unidades e precisão.

**Critérios de aceite:**

- largura e profundidade do sulco são campos independentes;
- declividade é armazenada em `%`;
- nenhum resultado depende de texto formatado;
- valores ausentes são `null`, nunca zero;
- cada projeto possui um identificador e uma versão do cálculo.

**Testes:** criação do modelo completo, modelo com dados pendentes e serialização JSON.

## 60.4 ISSUE-002 — Criar sistema de unidades e validação de entradas

**Objetivo:** impedir cálculos com unidades incompatíveis.

**Escopo:**

- `mm`, `mm/h`, `mm/dia`;
- `L/s`, `L/min`;
- `m`, `cm`;
- `%` e valores decimais;
- `g/cm³`;
- conversões de tempo entre minutos e horas.

**Critérios de aceite:**

- cada campo informa sua unidade;
- conversões são centralizadas em um serviço;
- o sistema rejeita tempo, vazão ou distância incompatíveis;
- a fórmula de infiltração registra sua unidade de saída;
- declividade não é convertida silenciosamente de `%` para decimal.

**Testes:** conversão `200 min → 3,3333333333333335 h`, `0,81 L/s → 29,16 mm/h` em `100 m²` e rejeição de entrada negativa.

## 60.5 ISSUE-003 — Implementar cálculo da lâmina requerida e turno de rega

**Objetivo:** calcular automaticamente a lâmina necessária e o intervalo entre irrigações.

**Fórmulas principais:**

```text
IRN = [(UCC - UPMP) / 10] * Ds * z_cm * f
TR = IRN / demanda_diaria
```

**Critérios de aceite:**

- retorna `IRN` em `mm`;
- retorna turno calculado e turno operacional;
- exige UCC, UPMP, densidade, profundidade, fração e demanda;
- alerta quando a demanda diária é zero ou negativa;
- guarda todos os valores intermediários.

**Teste obrigatório:** caso principal: `IRN = 42 mm` e `TR = 10,5 dias`.

## 60.6 ISSUE-004 — Implementar curvas e equações de infiltração

**Objetivo:** suportar infiltração instantânea e acumulada.

**Escopo:**

- equação potencial;
- regressão logarítmica;
- integração para infiltração acumulada;
- método de entrada e saída;
- parâmetros e unidades por ensaio.

**Critérios de aceite:**

- `T = 0` é excluído da regressão logarítmica;
- base do logaritmo é armazenada;
- equações em `mm/h` não reutilizam parâmetros em `L/min/m`;
- `K`, `n`, `a` e os dados originais são preservados;
- há indicação da origem: ensaio, modelo ou valor informado.

**Testes:** reproduzir as equações dos ensaios deste documento e verificar que resultados com unidades diferentes não são misturados.

## 60.7 ISSUE-005 — Implementar ensaio e simulação do tempo de avanço

**Objetivo:** calcular ou registrar o tempo necessário para a água alcançar cada ponto do sulco.

**Escopo:**

- entrada de pontos medidos;
- simulação por `Tx = k * x^b`;
- comparação entre vazões;
- curva distância × tempo;
- marcação de vazão erosiva.

**Critérios de aceite:**

- suporta ensaio e simulação como métodos diferentes;
- informa o tempo de avanço no final do sulco;
- permite comparar `100 m` e `200 m`;
- preserva pontos medidos;
- exibe alerta quando uma vazão foi reprovada por erosão.

**Teste obrigatório:** caso principal com `Ta(100 m) = 35 min`, `Ta(200 m) = 90 min` e `1,5 L/s` reprovado.

## 60.8 ISSUE-006 — Implementar seleção do maior comprimento viável

**Objetivo:** selecionar o maior comprimento que atende às restrições do projeto.

**Regra:** não escolher o maior comprimento cegamente. Avaliar sequencialmente comprimento, declividade, erosão, tempo de avanço, uniformidade, eficiência e operação.

**Critérios de aceite:**

- testa os comprimentos candidatos;
- elimina comprimentos com risco de erosão;
- elimina comprimentos com eficiência abaixo do limite configurado;
- informa por que cada alternativa foi aprovada ou rejeitada;
- retorna o maior comprimento aprovado;
- permite ao usuário alterar o limite de eficiência.

**Teste obrigatório:** o caso principal deve comparar `100 m` e `200 m` e registrar o efeito da redução de vazão.

## 60.9 ISSUE-007 — Implementar vazão não erosiva e manejo de redução

**Objetivo:** determinar vazão segura e vazão reduzida.

**Escopo:**

- `qmax = C / S0^a`;
- fórmula prática `qmax = 0,631 / S`;
- tabela por textura;
- vazão reduzida após chegada ao final;
- registro do fator de ajuste.

**Critérios de aceite:**

- textura e declividade são informadas;
- a unidade da declividade é exibida;
- `q_aplicada > qmax` gera alerta;
- o sistema registra se o fator `1,1` foi aplicado;
- a vazão reduzida nunca é maior que a vazão inicial.

## 60.10 ISSUE-008 — Implementar tempo de oportunidade e tempo de irrigação

**Objetivo:** calcular o tempo de oportunidade por ponto e o tempo de aplicação.

**Fórmulas:**

```text
To(i) = Tc + Td(i) + Trec(i) - Tx(i)
Ti = To + Ta
```

**Critérios de aceite:**

- depleção e recesso podem ser informados ou desprezados;
- `To(i)` nunca pode ser negativo;
- as curvas de avanço e recesso podem ser exibidas juntas;
- a unidade de cada tempo é explícita;
- o resultado informa se foi simulado ou simplificado.

## 60.11 ISSUE-009 — Implementar lâminas e parâmetros de desempenho

**Objetivo:** calcular lâmina aplicada, lâmina infiltrada, eficiência e perdas.

**Escopo:**

- `Lm` com vazão constante;
- `Lm` com redução de vazão;
- `Ed`, `Ea`, `GA`;
- `Pp` e `Pe_escoamento`;
- classificação por limites configuráveis.

**Critérios de aceite:**

- distingue lâmina necessária, infiltrada e aplicada;
- permite informar `Lf`, `Li`, `Lmi` e `LL`;
- mostra excesso, déficit e perdas separadamente;
- usa valores completos nos cálculos;
- classifica o caso principal com `Ea ≈ 66%` após redução.

## 60.12 ISSUE-010 — Implementar planejamento operacional

**Objetivo:** calcular a operação diária do sistema.

**Fórmulas:**

```text
NTS = (Lt * Wt) / (L * E)
NSD = NTS / PI
TIP = ti + tmud
NPD = TDF / TIP
NSP = NSD / NPD
Q = NSP * Q0 + PC
```

**Critérios de aceite:**

- mostra valores teóricos e valores inteiros operacionais;
- contabiliza tempo de mudança;
- calcula vazão simultânea e perdas de condução;
- não confunde sulcos totais com sulcos simultâneos;
- trata jornadas incompletas e parcelas parciais.

## 60.13 ISSUE-011 — Criar tela de entrada em etapas

**Objetivo:** evitar um formulário único e confuso.

**Etapas:**

1. área e geometria;
2. sulco: largura, profundidade, forma, espaçamento e declividade;
3. solo;
4. cultura e raízes;
5. clima e demanda;
6. ensaio ou simulação;
7. operação;
8. revisão antes de calcular.

**Critérios de aceite:**

- largura, profundidade e declividade aparecem no mesmo grupo visual;
- campos obrigatórios são claros;
- campos não fornecidos permanecem pendentes;
- unidades aparecem nos campos;
- o usuário pode voltar sem perder dados;
- a tela de revisão mostra todas as entradas antes do cálculo.

## 60.14 ISSUE-012 — Criar gráficos do resultado

**Objetivo:** tornar o dimensionamento compreensível visualmente.

### Gráfico A — curva de avanço

- eixo X: distância do sulco (`m`);
- eixo Y: tempo (`min`);
- uma linha para cada vazão testada;
- destaque para a vazão escolhida;
- marcador de erosão nas vazões reprovadas;
- linhas verticais nos comprimentos candidatos.

### Gráfico B — tempo de oportunidade

- eixo X: distância;
- eixo Y: tempo de oportunidade;
- faixa entre avanço e recesso;
- destaque para o tempo necessário de infiltração;
- alerta em pontos com `To` insuficiente.

### Gráfico C — lâmina ao longo do sulco

- eixo X: distância;
- eixo Y: lâmina em `mm`;
- linha da lâmina infiltrada;
- linha da lâmina requerida;
- faixa de tolerância;
- identificação visual de excesso no início e déficit no final.

### Gráfico D — comparação de cenários

Comparar, em barras ou tabela visual:

- comprimento;
- vazão;
- tempo de avanço;
- tempo de aplicação;
- lâmina média;
- `Ea`;
- `Ed`;
- `Pp`;
- `Pe_escoamento`.

### Gráfico E — indicadores de desempenho

Usar cartões ou barras horizontais para:

- eficiência de condução;
- eficiência de distribuição;
- eficiência de aplicação;
- grau de adequação;
- perdas por percolação;
- perdas por escoamento.

## 60.15 ISSUE-013 — Criar representação visual do terreno e dos sulcos

**Objetivo:** mostrar no Flutter como os sulcos ficam distribuídos na área.

**Implementação recomendada:** usar um widget próprio com `CustomPainter`, sem renderizar uma imagem fixa.

**Representação mínima:**

- retângulo proporcional à área;
- linhas paralelas para os sulcos;
- seta indicando o sentido do escoamento;
- indicação da declividade;
- marcador da entrada de água;
- marcador do final do sulco;
- escala visual;
- cores diferentes para sulcos aprovados, reprovados ou pendentes.

**Representação avançada:**

- gradiente de cor mostrando o tempo de avanço;
- animação da frente de água;
- faixa de umedecimento ao redor de cada sulco;
- pontos de medição nas estacas;
- indicação de excesso no início e déficit no final;
- opção de visualizar a parcela inteira ou um sulco ampliado.

**Regras visuais:**

- a largura e o comprimento devem respeitar a proporção da área;
- exagerar verticalmente a declividade apenas se houver legenda “declividade ampliada”;
- a cor nunca deve ser o único indicador: usar legenda, ícone ou padrão;
- o desenho deve atualizar ao mudar comprimento, espaçamento ou declividade.

## 60.16 ISSUE-014 — Criar tela de resultado auditável

**Objetivo:** mostrar dados completos, não apenas o resultado final.

**A tela deve conter:**

- resumo da recomendação;
- comprimento escolhido e alternativas rejeitadas;
- vazão inicial e reduzida;
- tempo de avanço e oportunidade;
- lâmina necessária, infiltrada e aplicada;
- eficiência e perdas;
- turno de rega;
- vazão de projeto;
- gráficos;
- representação da parcela;
- fórmulas usadas;
- unidades;
- valores completos e valores exibidos;
- avisos e dados pendentes.

## 60.17 ISSUE-015 — Persistência, exportação e rastreabilidade

**Objetivo:** permitir recuperar e auditar cada cálculo.

**Critérios de aceite:**

- salvar entradas e resultados como um caso de teste;
- guardar versão das equações e parâmetros;
- guardar data do cálculo;
- permitir duplicar um cenário;
- exportar JSON e relatório Markdown ou PDF;
- preservar dados originais de ensaios;
- permitir comparar duas versões do mesmo projeto.

## 60.18 ISSUE-016 — Testes de integração do caso principal

**Objetivo:** garantir que o fluxo completo reproduza o material.

**Cenário mínimo:**

```text
Área: 540 m × 200 m
Cultura: milho
Espaçamento: 0,90 m
Declividade: 0,5%
IRN esperado: 42 mm
Turno calculado esperado: 10,5 dias
Comprimentos: 100 m e 200 m
Tempo de oportunidade: aproximadamente 130 min
Vazão de teste reprovada: 1,5 L/s
Vazão reduzida: aproximadamente 0,75 L/s
Eficiência após redução: aproximadamente 66%
```

**Critérios de aceite:**

- o fluxo não calcula sem largura e profundidade quando esses campos forem definidos como obrigatórios;
- o caso pode ser executado mesmo com largura e profundidade pendentes somente no modo “dados incompletos”;
- os resultados são reproduzíveis;
- as diferenças entre valores precisos e arredondados são identificadas;
- o aplicativo não mistura o segundo cenário de `16 ha` com o caso principal.

## 60.19 Prompt padrão para executar uma issue no OpenCode

Usar este formato ao enviar uma issue para implementação:

```text
Implemente a ISSUE-XXX deste documento.

Antes de alterar:
1. inspecione a estrutura atual do projeto;
2. identifique os arquivos e padrões existentes;
3. não altere fórmulas fora do escopo;
4. mantenha unidades e precisão descritas no documento.

Implemente:
- [descrever o escopo da issue]

Critérios de aceite:
- [copiar os critérios da issue]

Testes obrigatórios:
- [copiar os testes da issue]

Ao finalizar:
- execute os testes;
- informe arquivos alterados;
- informe decisões e limitações;
- não esconda campos pendentes ou dados insuficientes.
```

## 60.20 Definição de pronto

Uma issue só está concluída quando:

- o código compila;
- os testes novos passam;
- os testes existentes continuam passando;
- as unidades estão explícitas;
- os valores completos são preservados;
- há tratamento para dados ausentes;
- o resultado pode ser explicado ao usuário;
- a alteração não quebra os casos de teste anteriores;
- a documentação da issue foi atualizada quando necessário.
