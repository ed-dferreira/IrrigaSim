# Modelo de domínio e plano de refatoração

## Diagnóstico da implementação atual

A implementação atual oferece sulco, faixa e inundação por meio de `IrrigationParameters` e `SimulationResult` compartilhados. Essa estrutura simplifica a interface, mas não representa as diferenças dos materiais.

Principais lacunas observadas:

1. `inundacao` reúne dois modelos incompatíveis: intermitente e permanente.
2. `vazao` é rotulada em L/s na interface, mas algumas equações hidráulicas a utilizam como se estivesse em m³/s.
3. tempos calculados em segundos são apresentados como minutos em alguns caminhos.
4. os parâmetros `k`, `a` e `VIB` não carregam a unidade nem a condição da irrigação.
5. `sigmaZ` é entrada com valor padrão, embora nas planilhas seja derivado de `a` e `r`.
6. o fluxo de sulcos usa o tempo de avanço como tempo total e não representa claramente a fase de reposição.
7. o fluxo de faixas aproxima a recessão por um fator fixo, enquanto o material exige solução da depleção e da recessão.
8. a vazão máxima do sulco é calculada pelo número de Froude, mas o material fornece critérios de vazão não erosiva por declividade e textura.
9. a aplicação calcula CUC e DU sem que os materiais enviados definam esses indicadores para os modelos estudados.
10. a perda por escoamento é obtida como resíduo, podendo ficar negativa quando o balanço anterior já está inconsistente.

Esses itens são um inventário preliminar para a refatoração, não uma autorização para alterar o cálculo sem testes de referência.

## Entidades propostas

```text
SurfaceIrrigationScenario
  id
  method
  field
  soil
  cropWaterRequirement
  operation
  infiltrationModel

method:
  FurrowInput
  BorderInput
  IntermittentBasinInput
  PermanentBasinInput
```

### Tipos compartilhados

```text
FieldGeometry
  lengthM
  widthM
  longitudinalSlopePercent
  transverseSlopePercent?

KostiakovLewisParameters
  k
  a
  basicInfiltration
  timeUnit
  accumulatedInfiltrationUnit
  irrigationCondition

OperationWindow
  workHoursPerDay
  changeTimeMinutes
  irrigationPeriodDays
  availableFlowLps
```

O tipo de unidade deve ser parte do domínio. Campos `double` sem unidade tornam combinações inválidas indistinguíveis de valores corretos.

## Serviços de cálculo

```text
InfiltrationService
  accumulatedInfiltration
  instantaneousInfiltration
  solveOpportunityTime

AdvanceCurveService
  fitPowerCurve
  solveVolumeBalance

FurrowDesignService
BorderDesignService
IntermittentBasinDesignService
PermanentBasinDesignService

PerformanceService
  waterBalance
  applicationEfficiency
  distributionEfficiency
  adequacy
```

Cada serviço deve receber e retornar tipos normalizados. Conversões ficam nas bordas do sistema, não espalhadas pelas equações.

## Resultado proposto

```text
SimulationResult<TDesign>
  status: success | warning | invalid | noConvergence
  selectedDesign
  alternatives
  waterBalance
  performance
  curves
  assumptions
  diagnostics
```

`diagnostics` deve guardar iterações, tolerância, resíduos do balanço e regras aplicadas. Isso permite explicar o resultado ao usuário e reproduzir falhas.

## Validações por método

### Compartilhadas

- dimensões, vazões e tempos positivos;
- `0 < a < 1` para o uso usual de Kostiakov-Lewis;
- declividade informada com unidade explícita;
- parâmetros e lâmina na mesma base dimensional;
- vazão disponível maior que zero;
- fechamento do balanço de água.

### Sulcos

- vazão menor ou igual ao critério não erosivo selecionado;
- espaçamento compatível com raízes e fileiras;
- comprimento dentro do intervalo aplicável ao tipo de sulco;
- lâmina final atendida sem percolação ou escoamento inválidos.

### Faixas

- profundidade de entrada abaixo da altura útil do dique;
- convergência para avanço total e metade do comprimento;
- `td` e `tr` coerentes com `ta` e `ti`;
- vazão total requerida dentro da disponível;
- largura adotada como submúltiplo operacional da área.

### Inundação intermitente

- superfície em nível dentro da tolerância do modelo;
- `ti >= ta`;
- vazão e profundidade compatíveis com o tabuleiro;
- balanço sem escoamento final negativo.

### Inundação permanente

- camada impermeável e condutividade hidráulica conhecidas;
- cultura tolerante ao encharcamento;
- `Q1` e `Q2` atendidos pela fonte;
- todas as parcelas de volume expressas na mesma base por hectare.

## Estratégia de testes

### Testes unitários

- conversões L/s, m³/s, m³/min e L/s/m;
- conversões mm, m e m³/ha;
- Kostiakov-Lewis e derivada;
- Newton-Raphson com convergência, fallback e falha;
- regra trapezoidal do perfil;
- balanço e limites dos indicadores.

### Testes de referência

- reproduzir as entradas e resultados intermediários das planilhas;
- comparar cada iteração relevante, não apenas o resultado final;
- manter casos separados para primeira e terceira irrigação;
- marcar como exceção conhecida qualquer inconsistência da planilha, sem transformá-la em valor esperado.

### Testes de propriedades

- aumentar vazão não pode reduzir o volume aplicado para o mesmo tempo;
- nenhuma perda pode ser negativa;
- os componentes do balanço devem somar o volume aplicado;
- a solução de `I(to) = IRN` deve retornar resíduo dentro da tolerância;
- alterar a unidade de apresentação sem alterar a grandeza física deve preservar o resultado.

## Ordem recomendada

1. Introduzir tipos e conversões de unidade sem mudar a interface.
2. Criar testes de caracterização do comportamento atual.
3. Separar os quatro modelos de entrada.
4. Consolidar Kostiakov-Lewis e solucionadores numéricos.
5. Reimplementar sulcos e validar com exemplos manuais.
6. Reimplementar faixas com depleção e recessão.
7. Separar inundação intermitente e permanente.
8. Atualizar formulários, resultados e persistência de cenários.
9. Migrar cenários antigos com versão explícita do modelo.

