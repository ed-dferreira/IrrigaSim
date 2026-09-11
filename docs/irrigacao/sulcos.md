# Irrigação por sulcos

## Finalidade e condições de uso

A água escoa em pequenos canais paralelos às fileiras das plantas e infiltra lateral e verticalmente até a zona radicular. O método normalmente molha de 30% a 80% da superfície e exige terreno sistematizado, solo relativamente homogêneo ao longo do sulco e controle operacional de vazão.

Parâmetros práticos apresentados:

- espécies cultivadas em linha;
- declividade dos sulcos comuns ideal de 0,1%, aconselhável de 0,05% a 0,5% e utilizável de 0,02% a 1,0%;
- comprimento prático de sulcos comuns entre 100 e 500 m;
- vazão usual entre 0,5 e 2,0 L/s por sulco, com 1,0 L/s como valor comum;
- largura típica de 20 a 30 cm e profundidade de 15 a 25 cm;
- espaçamento nunca maior que duas vezes a profundidade efetiva das raízes, como regra prática.

Há variações em contorno, corrugadas, em nível e em zigue-zague. Elas não devem compartilhar automaticamente os mesmos limites geométricos dos sulcos comuns.

## Entradas essenciais

### Área cultura e manejo

- comprimento e largura total da área;
- comprimento adotado do sulco;
- espaçamento entre sulcos ou fileiras;
- profundidade efetiva das raízes;
- lâmina líquida necessária;
- evapotranspiração da cultura e precipitação efetiva, quando o turno de rega for calculado;
- jornada diária, período disponível para irrigar e tempo de mudança entre parcelas.

### Solo e hidráulica

- declividade do sulco em porcentagem;
- parâmetros de infiltração e suas unidades;
- dados do teste de avanço ou equação de avanço ajustada;
- vazão por sulco;
- classe de textura, quando usada para a vazão não erosiva;
- eficiência ou perda na condução até a parcela.

## Cálculos essenciais

### Vazão máxima não erosiva

O material apresenta uma forma dependente da textura:

```text
qmax = c / S0 ^ a_textura
```

`qmax` é dada em L/s e `S0` em porcentagem. A tabela fornecida usa:

| Textura | `c` | `a_textura` |
| --- | ---: | ---: |
| Muito fina | 0,892 | 0,937 |
| Fina | 0,988 | 0,550 |
| Média | 0,613 | 0,733 |
| Grossa | 0,644 | 0,704 |
| Muito grossa | 0,665 | 0,548 |

Também aparece a simplificação de Criddle:

```text
qmax = 0,631 / S
```

Esses critérios devem ser opções explícitas do modelo. Não são equivalentes a limitar a vazão somente pelo número de Froude.

### Comprimento e avanço

O comprimento deve equilibrar percolação no início, escoamento no final, mecanização e custo. A regra de Criddle `ta = 1/4 de to` é apresentada apenas como aproximação histórica; a aula recomenda maximizar a eficiência com dados de campo quando possível.

O avanço pode usar a equação potencial descrita em [Fundamentos](fundamentos-superficie.md), ajustada ao teste de campo.

### Lâminas

Para vazão constante:

```text
Lm = [Tt * qc / (C * L)] * 3600
```

Onde `Lm` está em mm, `Tt` em horas, `qc` em L/s, `C` em m e `L` é a largura umedecida ou o espaçamento entre sulcos, em m.

Quando a vazão é reduzida durante a aplicação:

```text
Lm = {[(Tt - Tr) * qi + Tr * qr] / (C * L)} * 3600
```

`Tr` é a duração de aplicação da vazão reduzida, não o instante final da recessão. O material usa o mesmo símbolo em contextos diferentes; o código deve empregar nomes distintos.

A lâmina média infiltrada é aproximada pelas lâminas das estacas:

```text
Lmi = soma(yi) / n ≈ (Li + Lf) / 2
```

### Indicadores apresentados

```text
Ec = Va / Vd * 100
Ed = Lf / [(Li + Lf) / 2] * 100
Ea = Lf / Lm * 100
GA = lâmina infiltrada útil / lâmina requerida * 100
Pp = (Lmi - LL) / Lm * 100
Pe = (Lm - Lmi) / Lm * 100
```

O material considera `Ea >= 60%` aceitável e valores acima de 70% ideais. Em outro exemplo aparece a indicação de ideal acima de 75%; essa diferença deve ser resolvida antes de criar uma classificação rígida na interface.

## Sequência de dimensionamento

1. Validar espaçamento e declividade.
2. Determinar a vazão máxima não erosiva.
3. Selecionar ou testar comprimentos de sulco.
4. Obter `to` pela equação de infiltração.
5. Obter `ta` pelo teste de avanço ou por simulação validada.
6. Calcular `ti = ta + to` quando a aproximação de sulcos for aplicável.
7. Calcular lâminas e indicadores.
8. Testar redução de vazão após o avanço se houver escoamento elevado.
9. Dimensionar número de sulcos, parcelas por dia e vazão total do projeto.

## Saídas úteis para o usuário

- vazão adotada e limite não erosivo;
- tempo de avanço, oportunidade e aplicação;
- perfil de infiltração ao longo do sulco;
- `Ec`, `Ed`, `Ea`, `GA`, `Pp` e `Pe`;
- recomendação de manter ou reduzir a vazão após o avanço;
- quantidade de sulcos por parcela e vazão total necessária;
- alertas de erosão, déficit no final, percolação e escoamento excessivos.

