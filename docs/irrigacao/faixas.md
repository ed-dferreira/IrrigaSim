# Irrigação por faixas

## Finalidade e condições de uso

A água escoa como lâmina superficial entre diques paralelos. A faixa tem pouca ou nenhuma declividade transversal e uma declividade longitudinal que orienta o avanço.

Parâmetros gerais apresentados:

- declividade longitudinal normalmente entre 0,2% e 6%;
- comprimento geralmente entre 50 e 400 m;
- largura geralmente entre 4 e 20 m;
- os últimos 30 a 50 m podem ser planos para reduzir o escoamento;
- em declividades longitudinais acima de 3%, recomendam-se sulcos transversais sem declividade para distribuir melhor a água;
- o corte costuma ocorrer quando a frente alcança de dois terços a três quartos da faixa, desde que a lâmina desejada já possa ser aplicada.

A velocidade de avanço depende de largura, comprimento, vazão, declividade, cobertura vegetal, rugosidade e infiltração.

## Diferenças em relação aos sulcos

- a vazão é expressa por unidade de largura, não por sulco;
- a seção é tratada como canal muito largo;
- as fases de depleção e recessão são importantes e não podem ser descartadas;
- o tempo de oportunidade resulta da diferença entre as curvas de recessão e avanço;
- a vazão precisa ser otimizada junto com o tempo de aplicação.

## Entradas essenciais

- largura e comprimento total da área;
- comprimento adotado da faixa;
- declividade longitudinal e desnível transversal;
- coeficiente de rugosidade de Manning;
- parâmetros `k`, `a` e `VIB`, com unidade e condição da irrigação;
- irrigação real necessária `IRN`;
- vazão total disponível;
- velocidade máxima não erosiva ou critério alternativo de vazão;
- parâmetros empíricos `p1` e `p2` quando usados pela equação geral;
- tempo de mudança, jornada de trabalho e período de irrigação.

## Cálculos principais

### Vazão não erosiva

Hart et al. é apresentado para solos sem cobertura completa:

```text
Qmax = 0,01059 * S0 ^ -0,75
```

O material indica dobrar o valor para culturas que cobrem toda a superfície. A planilha também usa uma formulação geral dependente de velocidade máxima, Manning, declividade e parâmetros `p1` e `p2`:

```text
Qmax = [Vmax ^ p2 * n² / (3600 * S0 * p1)] ^ [1 / (p2 - 2)]
```

Walker e Skogerboe são citados para uma vazão mínima:

```text
Qmin = 0,000357 * L * S0 ^ 0,5 / n
```

Antes de implementar, é necessário fixar as unidades de cada uma dessas relações conforme a referência adotada. A planilha trabalha com `Q0` em m³/min por metro de largura e também o converte para L/s/m.

### Comprimento e profundidade na entrada

```text
L <= Qmax / VIB
y0 = [Q0² * n² / (3600 * S0)] ^ 0,3
```

O comprimento adotado deve ser um submúltiplo do comprimento da área. A profundidade `y0` não pode ultrapassar a altura útil dos diques.

### Tempo de oportunidade

Resolve-se `I(to) = IRN` pelo método descrito em [Fundamentos](fundamentos-superficie.md). O exemplo calcula valores diferentes para a primeira e a terceira irrigação, demonstrando que o estado superficial do solo altera o resultado.

### Simulação do avanço

O exemplo usa balanço volumétrico e Newton-Raphson para resolver conjuntamente o tempo de avanço `tx` e o expoente de forma `r`. Entre as grandezas intermediárias estão:

```text
sigmaZ = [a + r * (1 - a) + 1] / [(1 + a) * (1 + r)]
r_novo = ln(2) / [ln(tx_total) - ln(tx_metade)]
```

A equação de avanço resultante pode ser escrita como:

```text
x = p * tx ^ r
p = L / ta ^ r
```

Se o cálculo não convergir, a interpretação indicada é vazão insuficiente para o comprimento, exigindo aumento de `Q0` ou redução de `L`.

### Depleção e recessão

Para cada vazão candidata, o modelo calcula `ta`, `tr`, `td`, `ti` e `Ea`. A irrigação é adequada quando a infiltração acumulada no início atende a `IRN`, equivalente no procedimento a `td > to`. Se `td < to`, o tempo de aplicação precisa ser corrigido e a recessão recalculada.

O perfil final usa:

```text
to(x) = tr(x) - ta(x)
I(x) = k * to(x) ^ a + VIB * to(x)
```

A integração numérica do perfil deve usar regra trapezoidal ou método equivalente com extremos ponderados uma vez.

### Desempenho e projeto

```text
Ea = IRN * L / (Q0 * ti) * 100
Pp = (Vi - IRN * L) / (Q0 * ti) * 100
Pe = 100 - Ea - Pp
TIP = ti + tmud
NPD = TDF / TIP
APP = Wt * Lt / (NPD * PI)
W0 = APP / (NFP * L)
NTF = NFP * NPD * PI
Qt = NFP * W0 * Q0
```

As unidades precisam estar normalizadas antes da aplicação dessas fórmulas.

## Estratégia de seleção

1. Calcular o limite de vazão.
2. Testar uma série decrescente de vazões por unidade de largura.
3. Rejeitar cenários sem convergência, com profundidade acima do dique ou que não atendam `IRN`.
4. Calcular balanço e eficiência para os cenários válidos.
5. Escolher a maior eficiência que também respeite a vazão total disponível e a operação diária.
6. Mostrar ao usuário os cenários próximos do ótimo e o motivo de descarte dos demais.

No exemplo de 400 m, a planilha encontra `Ea` máxima próxima de 66,3% para 1,8 L/s/m e vazão total de 360 L/s, inferior aos 400 L/s disponíveis.

