# Irrigação por inundação

## Condições gerais

A água é aplicada em bacias ou tabuleiros quase planos, limitados por diques. O método exige, em geral, solos de textura média a fina, terreno uniforme com declividade inferior a 2% e culturas tolerantes ao excesso hídrico.

O tabuleiro pode ser retangular ou acompanhar curvas de nível. Para inundação permanente, a diferença de elevação dentro do tabuleiro não deve superar dois terços da lâmina média mantida. Os diques devem conservar margem livre acima da água.

O domínio precisa distinguir dois regimes.

## Inundação intermitente

A água é aplicada até que a zona radicular alcance a condição desejada, permanece no tabuleiro até infiltrar ou drenar e só é reaplicada quando o solo atinge o limite hídrico inferior da cultura.

### Hipóteses do modelo apresentado

1. O escoamento ocorre em uma direção numa bacia regular.
2. A superfície do solo é praticamente horizontal.
3. A recessão é desprezível, mas a depleção é importante.
4. Após o corte da vazão, a superfície líquida é horizontal e infiltra verticalmente.
5. O dimensionamento busca aplicar `IRN` no final da bacia, onde ocorre a menor lâmina.

### Entradas

- parâmetros de infiltração da primeira e da terceira irrigação;
- comprimento e largura da área;
- rugosidade de Manning;
- `IRN` e evapotranspiração da cultura;
- vazão total disponível;
- velocidade máxima não erosiva;
- jornada diária, tempo de mudança e geometria dos tabuleiros.

### Procedimento

1. Determinar uma vazão de entrada próxima do limite não erosivo.
2. Calcular a profundidade da água e validar a altura dos diques.
3. Simular o avanço por balanço volumétrico e Newton-Raphson.
4. Calcular o tempo de aplicação que garante `IRN` no final; se `ti < ta`, usar `ti = ta`.
5. Calcular `Ea`.
6. Repetir para outras vazões e escolher o melhor cenário válido.
7. Dimensionar largura, número de tabuleiros e vazão total.

A planilha usa, para terreno em nível:

```text
A0 = [Q0² * n² * L / 3600] ^ (3 / 13)
sigmaZ = [a + r * (1 - a) + 1] / [(1 + a) * (1 + r)]
r_novo = ln(2) / [ln(ta_total) - ln(ta_metade)]
```

O tempo e a eficiência são avaliados para cada vazão candidata. O balanço volumétrico precisa ser validado antes que `Pp` e `Pe` sejam mostrados.

## Inundação permanente ou contínua

A lâmina é estabelecida e mantida durante o desenvolvimento da cultura, principalmente no arroz. O dimensionamento é diferente do intermitente: calcula primeiro a vazão de enchimento e depois a vazão contínua de manutenção.

### Entradas

- área irrigada;
- porosidade do solo;
- profundidade até a camada impermeável;
- condutividade hidráulica saturada;
- lâmina superficial desejada;
- evapotranspiração potencial da cultura;
- água disponível total, fator de disponibilidade e turno de rega;
- vazão derivada da fonte, para eficiência de condução.

### Turno de rega e vazões

```text
TR = DTA * f * Z / ETc
Qe = 0,116 * [phi * Z + Lm + ETpc * TR + K0 * TR] * A / TR
Qm = 0,116 * (ETpc + K0) * A
Ec = Qm / Qd * 100
```

Na formulação apresentada, `Z`, `Lm`, `ETpc` e `K0` estão em unidades compatíveis com milímetros, `A` em hectares e as vazões resultam em L/s. O fator `0,116` corresponde à conversão aproximada de `1 mm por hectare por dia` para L/s.

### Eficiência semanal

```text
Ea = Les / Las * 100
Las = Qm * ti / A * 3600
```

`Les` é a lâmina evapotranspirada na semana, `Las` a lâmina aplicada, `Qm` em L/s, `ti` em horas e `A` em m².

### Balanço de volume para arroz

O material também apresenta um balanço por hectare:

```text
V1 = (Us - Ua) * PCI * 10000 * Ds
V2 = h1 * 10000
V3 = h2 * PI * 10000
V4 = Ksat * [(h1 + PCI) / PCI] * PI * 10000
V5 = 0,4 * MS_total
VT = V1 + V2 + V3 + V4 + V5
Q1 = [(V1 + V2) / (Td * 86400)] * A
Q2 = [(V3 + V4 + V5) / (Tr * 86400)] * A
```

`V1` a `V5` estão em m³/ha; alturas e profundidades devem estar em metros nessa formulação. `Q1` forma a lâmina no tempo disponível e `Q2` mantém a lâmina no tempo restante.

## Saídas separadas na interface

### Intermitente

- vazão recomendada por unidade de largura;
- `ta`, `ti`, profundidade máxima e eficiência;
- perfil de infiltração;
- número e dimensões dos tabuleiros;
- vazão total e duração do ciclo operacional.

### Permanente

- turno de rega;
- vazão e tempo de enchimento;
- vazão de manutenção;
- volume total e componentes `V1` a `V5`;
- eficiência de condução e aplicação;
- alerta quando a fonte não atende `Q1` ou `Q2`.

