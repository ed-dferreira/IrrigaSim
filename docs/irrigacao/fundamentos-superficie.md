# Fundamentos da irrigação por superfície

## Método e sistema

O método define como a água é aplicada. O sistema reúne equipamentos, acessórios, operação e manejo usados para executar o método. Na irrigação por superfície, a água é distribuída por gravidade e o próprio solo funciona como meio de transporte.

A infiltração varia com textura, estrutura, condição superficial, umidade inicial e compactação. Por isso, o simulador deve tratar os parâmetros de infiltração como dados de campo vinculados à condição da irrigação, e não como constantes universais do solo.

## Fases hidráulicas

| Fase | Início | Fim | Relevância |
| --- | --- | --- | --- |
| Avanço | entrada da água na parcela | frente alcança o final | define `ta` e influencia a desuniformidade |
| Reposição | fim do avanço | corte da vazão | completa a lâmina necessária |
| Depleção | corte da vazão | primeiro ponto da superfície fica exposto | pequena em sulcos, importante em faixas e inundação intermitente |
| Recessão | fim da depleção | desaparecimento da água superficial | pequena em sulcos, indispensável em faixas |

O tempo de oportunidade em uma posição `x` é o intervalo durante o qual há água disponível para infiltrar. Em termos gerais:

```text
to(x) = tempo de recessão em x - tempo de avanço em x
```

Em sulcos, quando depleção e recessão são desprezadas, usa-se a aproximação:

```text
ti = ta + to
```

Essa aproximação não deve ser reutilizada automaticamente em faixas ou inundação intermitente.

## Equação de avanço observada em campo

A forma potencial apresentada nas aulas é:

```text
Tx = k_avanco * x ^ b
```

Onde `Tx` é o tempo para a frente alcançar a distância `x`. Os coeficientes podem ser obtidos por regressão linear de `log(Tx)` contra `log(x)` ou pelo método de dois pontos.

Para um ponto na metade do comprimento e outro no comprimento total:

```text
b = [ln(T_0,5L) - ln(T_L)] / ln(0,5)
k_avanco = T_L / L ^ b
```

O material recomenda mínimos quadrados quando há uma série de medições, pois utiliza todos os pontos. Pontos com `x = 0` ou `T = 0` não entram no logaritmo.

## Infiltração de Kostiakov Lewis

As planilhas usam a infiltração acumulada:

```text
I(t) = k * t ^ a + VIB * t
```

E sua derivada, a velocidade instantânea de infiltração:

```text
VI(t) = k * a * t ^ (a - 1) + VIB
```

No exemplo de sulcos, a regressão da velocidade gera `VI = 35,23 * T^-0,32`; a integração gera `I = 0,85 * T^0,68`. Nos exemplos de faixas e inundação intermitente, `I` é expressa em `m³ por metro de largura`, com `t` em minutos. Portanto, `k` e `VIB` só podem ser usados depois que o sistema confirmar o conjunto de unidades associado.

## Solução do tempo de oportunidade

Para encontrar o tempo que infiltra a lâmina requerida, resolve-se numericamente:

```text
f(t) = k * t ^ a + VIB * t - IRN = 0
```

Newton-Raphson:

```text
t_novo = t - f(t) / [k * a * t ^ (a - 1) + VIB]
```

O exemplo parte de 100 min e aceita a solução quando a diferença entre iterações é menor que 0,1 min. Uma implementação robusta deve ainda impor `t > 0`, limite de iterações, faixa de busca e alternativa por bisseção.

## Balanço e indicadores

Os indicadores centrais dos materiais são:

- `Ec`: água que chega à parcela em relação à água derivada da fonte;
- `Ed`: uniformidade longitudinal da infiltração;
- `Ea`: fração da água aplicada que atende o objetivo da cultura;
- `GA`: lâmina útil em relação à lâmina necessária;
- `Pp`: excesso infiltrado abaixo da zona radicular;
- `Pe`: água que deixa a parcela por escoamento superficial.

Os materiais não estabelecem faixas gerais para CUC e DU nos métodos estudados. Se esses indicadores forem mantidos no produto, sua definição, amostragem e referência técnica devem ser documentadas separadamente.

## Regras de consistência

- `0 <= eficiência <= 100`;
- `Pp >= 0` e `Pe >= 0`;
- volumes aplicados, infiltrados, armazenados e escoados devem fechar o balanço dentro de uma tolerância definida;
- `ta`, `to`, `ti`, `td` e `tr` não podem ser confundidos entre duração e instante acumulado;
- vazão por sulco, vazão por unidade de largura e vazão total são grandezas diferentes;
- todo valor convertido deve preservar a unidade original para auditoria.

