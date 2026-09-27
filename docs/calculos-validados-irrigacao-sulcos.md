# Cálculos validados: irrigação por sulcos

Este documento consolida as equações e exemplos revisados de `fases-avanco-irrigacao-sulcos.md`, do plano de implementação e da aula de irrigação por sulcos. Ele é a referência para implementar os cálculos; resultados identificados como divergentes não devem ser usados como casos de aceitação sem corrigir os dados de origem.

## Convenções obrigatórias

| Símbolo | Significado | Unidade de cálculo |
| --- | --- | --- |
| `x`, `L` | distância e comprimento do sulco | m |
| `Tx`, `To`, `Tc`, `Td`, `Trec` | avanço, oportunidade, corte, depleção e recesso | min ou h, conforme a equação |
| `q`, `Qr`, `qmax` | vazão por sulco | L/s |
| `VI` | velocidade de infiltração | mm/h |
| `I`, `Lr`, `Lm` | infiltração, lâmina requerida e lâmina média aplicada | mm |
| `S0` | declividade longitudinal para a equação por textura | % |

As equações de avanço e infiltração calibradas neste material usam minutos. Converter minutos para horas somente nas equações de volume que explicitamente exigem horas. Arredondar apenas para exibição, mantendo a precisão usada nos cálculos intermediários.

## Avanço

O modelo de avanço é:

```text
Tx(x) = k * x^b
```

Com dois pares observados `(x1, Tx1)` e `(x2, Tx2)`:

```text
b = ln(Tx2 / Tx1) / ln(x2 / x1)
k = Tx1 / x1^b
```

Com mais de dois pares, ajustar a regressão linear de `ln(Tx)` por `ln(x)`. Se `a` for o intercepto e `b` a inclinação, então `k = exp(a)`. Todos os valores de distância e tempo devem ser positivos.

### Exemplo conferido por dois pontos

Para `x1 = 100 m`, `Tx1 = 37,9 min`, `x2 = 200 m` e `Tx2 = 93,5 min`:

```text
b = ln(93,5 / 37,9) / ln(200 / 100) = 1,3027685166
k = 37,9 / 100^1,3027685166 = 0,0939944426
Tx(x) = 0,0939944426 * x^1,3027685166
```

O cálculo alternativo `k = Tx / b` é dimensionalmente incorreto e não deve ser usado.

## Infiltração acumulada

Para a lei de infiltração:

```text
VI(T) = K * T^n
```

a infiltração acumulada é:

```text
I(T) = K / (60 * (n + 1)) * T^(n + 1)
```

Nesta calibração, `T` é dado em minutos e `VI` em `mm/h`; o fator `60` converte o diferencial de tempo para horas. Para ajustar `K` e `n`, usar regressão de `ln(VI)` por `ln(T)` com todos os pontos válidos. O conjunto analisado possui `N = 11` observações; usar `N = 10` altera o ajuste e é um erro de origem.

## Tempo de oportunidade

Para cada posição no sulco:

```text
To(x) = Tc + Td(x) + Trec(x) - Tx(x)
```

O caso simplificado abaixo somente vale quando depleção e recesso são desprezíveis:

```text
Ti(x) = To(x) + Ta(x)
```

Não confundir `Ti`/tempo de irrigação com `To`/tempo de oportunidade. O primeiro é uma duração operacional; o segundo é o intervalo durante o qual há infiltração em uma posição.

## Vazões de projeto

A vazão máxima não erosiva indicada para o sulco é:

```text
qmax = C / S0^a
```

Na aproximação apresentada no material:

```text
qmax = 0,631 / S
```

Na equação por textura, `S0` é expresso em porcentagem. Os parâmetros `C` e `a` dependem da textura e não podem ser misturados com uma declividade em razão decimal sem recalibração. A fórmula simplificada usa a convenção de unidade definida pela respectiva fonte e deve registrar essa configuração.

Para a vazão reduzida, a expressão de referência é:

```text
Qr = 1,1 * f0 * C * E / 3600
```

onde `f0` é a taxa de infiltração no final em `mm/h`, `C` é o comprimento do sulco em metros e `E` é o espaçamento entre sulcos em metros. Se o fator de majoração `1,1` for adotado, ele precisa aparecer tanto na fórmula quanto no resultado numérico.

### Divergência no exemplo de vazão reduzida

Com `f0 = 7,9 mm/h`, `C = 200 m` e `E = 1 m`, a fração sem majoração resulta em:

```text
(7,9 * 200 * 1) / 3600 = 0,4388888889 L/s
```

Com o fator `1,1`, o resultado é `0,4827777778 L/s`. A fonte que declara o fator e apresenta o resultado sem ele é inconsistente. A implementação deve tornar o fator explícito e configurável, com valor padrão definido pelo critério de projeto adotado.

## Lâminas, eficiência e perdas

```text
Lm = (Tt * qc / (C * E)) * 3600
Lmi = soma(yi) / n
Ea = (Lf / Lm) * 100
GA = (lamina_infiltrada_util / lamina_requerida) * 100
Pp = ((Lmi - LL) / Lm) * 100
Pe = ((Lm - Lmi) / Lm) * 100
```

`Tt` é dado em horas, `qc` em `L/s`, `C` é o comprimento e `E` a largura representativa da faixa em metros. As lâminas devem estar na mesma unidade antes dos quocientes. Os resultados de eficiência e perdas são percentuais. Se `Lmi < LL`, `Pp` representa déficit, não perda negativa.

## Exemplo de lâmina média aplicada

Para `Tt = 200 min`, `Tr = 140 min`, `qi = 1 L/s`, `qr = 0,4388888889 L/s`, `C = 200 m` e `E = 1 m`:

```text
Lm = [((200 - 140) / 60) * 1 + (140 / 60) * 0,4388888889] / (200 * 1) * 3600
Lm = 36,4333333333 mm
```

Com `Lf = 30 mm`, a eficiência de aplicação correspondente é:

```text
Ea = 30 / 36,4333333333 * 100 = 82,34 %
```

Com tempos e vazão arredondados, a fonte apresenta `Lm = 36,45 mm` e `Ea = 82,3%`. A fonte também lista `36,4166666667 mm` como cálculo preciso, mas a substituição de `Qr = 0,4388888889 L/s` na fórmula resulta em `36,4333333333 mm`; usar este último valor como referência numérica.

### Resultado de origem não validado

No caso de sulco de `200 m` e espaçamento de `0,9 m`, a fonte declara `90 min` a `1,0 L/s` e `20 min` a `0,75 L/s`, mas substitui na fórmula os períodos de `110 min` a cada vazão. O cronograma declarado produziria `35 mm`; os valores substituídos produzem aproximadamente `64 mm`. Portanto, não usar os resultados `Lm = 64 mm` e `Ea = 66%` até que a duração de cada etapa seja corrigida na fonte.

## Turno de rega e planejamento operacional

```text
TR = CRA / (ETc - Pef)
Nf = AreaTotal / AreaSetor
Tsetor = AreaSetor / (N * E * L) * Ti
Ttotal = Nf * Tsetor
```

`ETc - Pef` deve ser estritamente positivo. Para `Tsetor`, `N` é o número de sulcos irrigados simultaneamente e `Ti` deve estar em unidade compatível com a duração desejada.

## Regras de implementação e teste

- Rejeitar valores não positivos onde a equação usa logaritmo, divisão ou expoente de tempo.
- Exigir unidades explícitas na interface e converter para as unidades de cálculo antes de avaliar a fórmula.
- Exibir os valores intermediários relevantes: `k`, `b`, `To`, infiltração acumulada, duração em cada vazão e lâmina média.
- Cobrir os exemplos deste documento com tolerância numérica, sem comparar strings arredondadas.
- Manter a divergência do exemplo de redução como teste de validação de dados, e não como valor esperado de produção.

## Fontes consultadas

- `docs/fases-avanco-irrigacao-sulcos.md`
- `docs/plano-implementacao-irrigacao-sulcos.md`
- `docs/materiais_origem/Aula 6 - Irrigação por sulcos.pdf`
