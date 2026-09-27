# Funcionamento da tela Simular sulco

## Objetivo

A tela **Simular sulco** dimensiona e avalia uma irrigação por sulcos antes da operação em campo. Ela reúne os dados da parcela, solo, cultura, clima, avanço, infiltração e manejo para calcular a lâmina requerida, o avanço da água, a lâmina infiltrada e os indicadores de desempenho.

O fluxo usa valores com precisão interna. Arredondamentos são aplicados somente na apresentação da tela, relatórios e gráficos.

## Fluxo da tela

1. Selecionar o método `Sulco` e, quando aplicável, o tipo de sulco.
2. Informar a área, geometria, desnível e limite físico de comprimento do terreno.
3. Informar a textura (sulco) e os parâmetros de infiltração do solo.
4. Informar os dados de solo (água disponível), cultura (raízes, fração de água disponível) e clima para calcular a lâmina requerida.
5. Escolher a origem do avanço: estimativa ou ensaio de campo.
6. Definir o manejo de vazão e executar a simulação.
7. Consultar indicadores, balanço hídrico, curva de avanço e perfil de infiltração.

## Área, geometria e declividade

### Entradas

| Campo | Unidade | Uso |
| --- | --- | --- |
| Comprimento do sulco | m | Comprimento usado na simulação atual. |
| Limite de comprimento do terreno | m | Limite máximo para a recomendação automática. |
| Espaçamento entre sulcos | m | Largura representativa da área atendida por cada sulco. |
| Desnível longitudinal | m | Diferença de cota usada no cálculo da declividade. |
| Distância longitudinal | m | Distância horizontal correspondente ao desnível. |
| Largura e profundidade do sulco | m | Dados geométricos opcionais para registro do projeto. |

A declividade longitudinal é calculada por:

```text
S0 = desnível longitudinal / distância longitudinal
```

Para as fórmulas de erosão, a aplicação converte `S0` para porcentagem. Cada tipo de sulco possui faixas de declividade (ideal, aconselhável e usável). Valores fora da faixa esperada **não bloqueiam** o cálculo: a tela exibe um alerta na parte inferior da etapa de área/declividade, logo abaixo do card com declividade e desnível total.

### Faixas de declividade por tipo de sulco

| Tipo | Ideal | Aconselhável | Usável |
| --- | --- | --- | --- |
| Sulcos comuns | 0,1% | 0,05% a 0,5% | 0,02% a 1,0% |
| Sulcos em contorno | 1,0% | 0,5% a 2,0% | 0,5% a 2,0% |
| Sulcos corrugados | 1,0% a 2,0% | 0,5% a 12% | até 15% |
| Sulcos em nível (tabuleiros, fechados e zigue-zague) | 0% (em nível) | até 0,1% | até 0,2% |

Classificação aplicada pela tela:

- **Ideal**: dentro da faixa ideal — nenhum alerta.
- **Aconselhável**: fora do ideal, dentro do aconselhável — nenhum alerta (faixa esperada).
- **Usável**: fora do aconselhável, dentro do usável — alerta âmbar.
- **Fora**: além da faixa usável — alerta vermelho, informando que o resultado pode não ser representativo.

Os limites usam tolerância numérica (`1e-9`) para evitar falso positivo em valores como `0,05%`, `0,1%` e `0,02%`, que não são representáveis com exatidão em ponto flutuante. Exemplo: `0,0050 m/m` (`0,50%`) em sulcos comuns classifica como aconselhável e não gera alerta.

São referências práticas, não limites universais. O espaçamento e o comprimento também dependem da textura e infiltração do solo, chuva, relevo e manejo.

### Maior comprimento viável

O botão **Usar maior comprimento viável** avalia candidatos de `50 m` em `50 m`, até o limite de comprimento do terreno. Um candidato só é aceito se:

- a vazão não ultrapassar a vazão máxima não erosiva;
- a simulação for válida;
- a eficiência de aplicação for de pelo menos `60%`.

O maior candidato aprovado substitui o comprimento e atualiza os tempos de avanço conforme a curva potencial. Se nenhum candidato for aprovado, a tela exibe uma mensagem e mantém os dados atuais.

## Solo e infiltração

### Textura e vazão não erosiva

A textura do só é selecionável apenas no fluxo de **sulco** (etapa Solo). Ela define os parâmetros `C` e `a` usados exclusivamente na equação da vazão máxima não erosiva:

```text
qmax = C / S0^a
```

Onde `qmax` é dado em `L/s` e `S0` deve estar em porcentagem. A tela alerta quando a vazão adotada excede `qmax`.

Tabela de parâmetros por textura (§30.2):

| Textura | C | a |
| --- | --- | --- |
| Muito fina | 0,892 | 0,937 |
| Fina | 0,988 | 0,550 |
| Média | 0,613 | 0,733 |
| Grossa | 0,644 | 0,704 |
| Muito grossa | 0,665 | 0,548 |

O `qmax` calculado a partir da textura é usado em três pontos:

1. **Alerta de erosão** na simulação — se `vazão > qmax`, exibe aviso de risco erosivo;
2. **Recomendação de maior comprimento viável** — candidatos com vazão erosiva são recusados;
3. **Resultados** — exibe a “Vazão máxima não erosiva” com a textura usada.

A textura **não** altera infiltração (`aI`, `n`), lâmina requerida (IRN), avanço nem eficiências. Trocar a textura muda apenas o limite de vazão erosiva.

### Curva de infiltração

Para o fluxo de sulcos, a lâmina infiltrada em cada posição é calculada pela curva acumulada:

```text
I(To) = aI * To^n
```

Onde:

- `aI` é o coeficiente de infiltração, em `mm/min^n`;
- `n` é o expoente de infiltração;
- `To` é o tempo de oportunidade local, em minutos;
- `I` é a lâmina infiltrada, em milímetros.

Os valores de `aI` e `n` devem ser calibrados com dados de campo ou um ensaio representativo — **não são derivados da textura**. A tela rejeita coeficiente ou expoente não positivos.

## Lâmina requerida e turno de rega

A lâmina requerida é automática. Ela não é digitada manualmente na tela de projeto, pois é calculada a partir dos dados de solo, raízes e demanda hídrica.

### Entradas agronômicas

Os campos vêm de três etapas da tela de projeto:

| Campo | Unidade | Etapa |
| --- | --- | --- |
| UCC, umidade na capacidade de campo | % | Solo |
| UPMP, umidade no ponto de murcha permanente | % | Solo |
| Densidade aparente | g/cm³ | Solo |
| Profundidade efetiva das raízes | cm | Cultura e raízes |
| Fração de água disponível | 0 a 1 | Cultura e raízes |
| ETc, evapotranspiração da cultura | mm/dia | Clima e demanda |
| Pef, precipitação efetiva | mm/dia | Clima e demanda |

### Fórmulas

```text
Demanda líquida = ETc - Pef
IRN = [(UCC - UPMP) / 10] * Ds * z * f
TR = IRN / demanda líquida
```

Onde `Ds` é a densidade aparente, `z` é a profundidade de raízes e `f` é a fração de água disponível.

### Fração de água disponível (`f`)

A fração de água disponível (intervalo `0 a 1`, padrão `0,5`) representa **quanto da água total disponível no solo é considerada efetivamente aproveitável** pela cultura antes de a irrigação ser necessária.

A água total disponível entre capacidade de campo e ponto de murcha permanente é:

```text
FAAD = UCC - UPMP   (em decimal)
```

Nem toda essa água é igualmente acessível às raízes ao longo do ciclo. O fator `f` reduz a parcela gerenciável:

```text
água útil = FAAD * f
```

Assim, com `UCC = 30%`, `UPMP = 15%` e `f = 0,5`:

```text
FAAD = 0,30 - 0,15 = 0,15
água útil = 0,15 * 0,5 = 0,075  (7,5% em volume, na profundidade das raízes)
```

Valores típicos:

| `f` | Significado |
| --- | --- |
| `0,5` (padrão) | Gestão conservadora — metade da água disponível é considerada útil |
| `0,3` a `0,4` | Culturas sensíveis a déficit ou solos com disponibilidade restrita |
| `0,7` a `1,0` | Margem ampla — mais água entre irrigações, maior lâmina e turno |

Quanto **maior** `f`:

- maior a lâmina requerida (IRN);
- maior o turno de rega (TR = IRN / demanda líquida).

Quanto **menor** `f`:

- irrigações mais frequentes;
- menor lâmina por ciclo.

Validação: `f` deve estar entre `0` e `1`; `UCC > UPMP`; demanda líquida positiva. O resultado exibe IRN, demanda líquida, turno calculado e turno operacional (arredondado para baixo, mínimo 1 dia).

A profundidade das raízes (`z`) e a fração de água disponível (`f`) são informadas na etapa **Cultura e raízes** — são propriedades da cultura/sistema radicular, não do solo. UCC, UPMP e densidade aparente ficam na etapa **Solo**.

A recalculação é feita ao alterar UCC, UPMP, densidade, profundidade, fração disponível, ETc ou Pef. O cálculo exige `UCC > UPMP` e demanda líquida positiva. A tela apresenta:

- IRN em `mm`, usada diretamente como lâmina requerida da simulação;
- demanda líquida em `mm/dia`;
- turno calculado em dias;
- turno operacional em dias inteiros, arredondado para baixo e limitado a no mínimo um dia.

## Avanço e tempo de oportunidade

### Origem do avanço

A tela oferece duas fontes para a curva de avanço.

| Origem | Entradas |
| --- | --- |
| Estimativa | Tempo até a metade do comprimento e tempo até o final. |
| Ensaio de campo | Distância intermediária medida, tempo nessa distância e tempo no final. |

Nos dois casos, a curva potencial é ajustada por:

```text
Tx(x) = k * x^b
```

Para o ensaio, a distância intermediária deve ser maior que zero e menor que o comprimento. O tempo final deve ser maior que o tempo intermediário. A curva calculada preserva a série de pontos de tempo e distância para o gráfico de avanço.

### Tempo de oportunidade usado no modelo

O usuário informa o tempo de oportunidade desejado no final do sulco. O tempo total até o corte é:

```text
Tc = Ta(final) + To(final)
```

Para cada posição do sulco, o modelo simplificado usa:

```text
To(x) = Tc - Tx(x)
```

Assim, o início do sulco possui normalmente maior oportunidade de infiltração que o final. Esse tempo local alimenta o perfil longitudinal de lâmina infiltrada.

## Manejo de vazão

### Vazão constante

A vazão por sulco permanece igual durante todo o tempo de aplicação. A lâmina média aplicada é calculada pelo volume aplicado dividido pela área representativa:

```text
Lm = q * Tt * 60 / (comprimento * espaçamento)
```

Com `q` em `L/s`, `Tt` em minutos e resultado em milímetros.

### Vazão reduzida após o avanço

No manejo reduzido, a vazão original é aplicada até o avanço chegar ao final. O campo **Atraso para redução após avanço** pode prolongar a vazão original na fase de reposição. Em seguida é aplicada a vazão reduzida.

```text
T inicial = Ta(final) + atraso
T reduzido = T total - T inicial
Volume = qi * T inicial * 60 + qr * T reduzido * 60
```

A vazão reduzida deve ser positiva, não pode ser maior que a vazão original e o atraso não pode superar o tempo de oportunidade informado.

### Surtirção

Surtirção aparece como alternativa de manejo, mas a simulação é bloqueada. O aplicativo não usa fator empírico arbitrário para estimar infiltração em pulsos. Um modelo calibrado por ciclos de aplicação e pausa é necessário antes de liberar esse resultado.

## Resultados

### Indicadores principais

| Indicador | Definição no aplicativo |
| --- | --- |
| Ea, eficiência de aplicação | Lâmina infiltrada no final dividida pela lâmina média aplicada. |
| Er, eficiência de requerimento | Lâmina útil média dividida pela lâmina requerida. |
| CUC | Coeficiente de uniformidade de Christiansen do perfil infiltrado. |
| DU | Uniformidade de distribuição do perfil infiltrado. |
| Ec, eficiência de condução | `q / (q + perdas de condução) * 100`; sem perdas informadas, é `100%`. |
| GA, grau de adequação | Média espacial de `min(lâmina infiltrada, lâmina requerida) / lâmina requerida`. |
| Percolação | Excesso de lâmina infiltrada sobre a requerida, em relação à lâmina aplicada. |
| Escoamento | Parcela aplicada não infiltrada, em relação à lâmina aplicada. |

Além dos KPIs, o resultado registra vazões, tempos, declividade, lâmina aplicada, lâmina média infiltrada, resíduo de balanço, eficiência de distribuição e valores específicos do manejo reduzido.

### Gráficos

| Gráfico | Eixos e finalidade |
| --- | --- |
| Balanço hídrico | Resume lâminas, perdas e eficiência. |
| Curva de avanço | Tempo, em minutos, no eixo horizontal e distância, em metros, no eixo vertical. |
| Perfil de infiltração | Distância ao longo do sulco e lâmina infiltrada em cada ponto. |

A curva de avanço é mantida no resultado e na persistência do cenário para auditoria e comparação posterior.

## Validações e alertas

- comprimento, espaçamento, vazão, declividade, lâmina requerida e parâmetros de infiltração devem ser positivos;
- tempos de avanço devem ser positivos e o tempo da metade deve ser menor que o tempo final;
- declividade fora da faixa do tipo de sulco gera alerta na etapa de área (não bloqueia o cálculo);
- vazão acima de `qmax` gera alerta de risco de erosão;
- dados de ensaio inválidos impedem a recomendação automática de comprimento;
- UCC deve ser maior que UPMP;
- demanda líquida deve ser positiva para calcular IRN e turno;
- surtirção não produz resultado enquanto não houver modelo calibrado.

## Limitações atuais

- Os campos de início e fim da recessão são registrados na tela, mas ainda não compõem o cálculo espacial de oportunidade. Portanto, o modelo usa a aproximação `To(x) = Tc - Tx(x)`.
- Não há gráfico de oportunidade/recesso por estaca. Ele depende de registrar tempos de recesso em cada posição do sulco.
- O planejamento automático usa candidatos de `50 m`; uma resolução diferente exigirá alteração do critério de projeto.
- O maior comprimento recomendado é uma decisão do modelo e não substitui levantamento topográfico, ensaio de infiltração ou validação de campo.
- Surtirção permanece indisponível para evitar um resultado hidráulico sem calibração.

## Referências internas

- `docs/calculos-validados-irrigacao-sulcos.md`
- `docs/fases-avanco-irrigacao-sulcos.md`
- `docs/matriz-testes-irrigacao-sulcos.md`
