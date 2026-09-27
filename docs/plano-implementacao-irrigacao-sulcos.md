# Plano de Implementação — Fases de Avanço e Irrigação por Sulcos

## Referência

Este plano é derivado de `fases-avanco-irrigacao-sulcos.md` e deve ser implementado em conjunto com ele.

---

## Análise do que já existe no projeto

### Modelos existentes (`lib/models/`)

| Arquivo | Conteúdo | Reutilizável |
|---------|----------|:---:|
| `irrigation_parameters.dart` | 27 campos (comprimento, declividade, k, a, vazão, etc.) | Parcial — faltam campos do doc |
| `simulation_result.dart` | Resultado simplificado (eficiência, CUC, DU, curva avanço, perfil) | Parcial — faltam campos de auditoria |
| `simulation_result_model.dart` | Serialização `toMap`/`fromMap` | Sim |
| `cenario_salvo.dart` | Cenário salvo com Firestore mapping | Sim |
| `tipo_sulco_info.dart` | Enum TipoSulco + dados de referência | Sim |
| `irrigation_parameters.dart` enums | TexturaSolo, MetodoIrrigacao, TipoInundacao | Sim |

### Simulação existente (`lib/services/simulation/`)

| Arquivo | Conteúdo | Reutilizável |
|---------|----------|:---:|
| `surface_irrigation_math.dart` | `fitAdvanceCurve` (dois pontos), `infiltrationM` (Kostiakov-Lewis), `solveOpportunityTimeMin` (bisseção), `trapezoidalMean`, `balance` | Sim — extender |
| `run_furrow_simulation.dart` | Simulação de sulco com dois pontos, balanço hídrico, vazão não erosiva | Sim — extender |
| `kostiakov_lewis.dart` | Infiltração acumulada e taxa (Kostiakov-Lewis) | Parcial — unidades diferentes |
| `performance_indicators.dart` | Ea, Er, CUC, DU, perdas, classificações | Sim |
| `run_border_simulation.dart` | Simulação de faixa | Sim (referência) |

### UI existente (`lib/views/irrigation/`)

| Arquivo | Conteúdo | Reutilizável |
|---------|----------|:---:|
| `parameters_screen.dart` | Formulário de parâmetros (BentoCards) | Parcial — reescrever em etapas |
| `results_screen.dart` | KPIs, gráficos, salvar, CSV | Parcial — extender |
| `widgets/advance_chart.dart` | Gráfico de avanço (fl_chart) | Sim |
| `widgets/infiltration_chart.dart` | Gráfico de infiltração | Sim |
| `widgets/water_balance_chart.dart` | Gráfico de balanço hídrico | Sim |

### Testes existentes

| Arquivo | Conteúdo |
|---------|----------|
| `surface_methods_test.dart` | Testes unitários dos 4 motores de simulação |

### Dependências relevantes

- `fl_chart: ^1.2.0` — gráficos (já instalado)
- `flutter_riverpod: ^2.6.1` — state management
- `go_router: ^14.8.1` — rotas

---

## O que o documento exige e NÃO existe

1. **Modelos de domínio completos** — projeto, ensaio, infiltração por entrada/saída, eficiência com limites configuráveis
2. **Sistema de unidades e validação de entradas** — conversões centralizadas, rejeição de incompatibilidades
3. **Cálculo de lâmina requerida (IRN) e turno de rega (TR)** — fórmula `(UCC-UPMP)/10 * Ds * z * f`
4. **Equação de infiltração por método de entrada/saída** — `VI = K * T^n` com regressão logarítmica base 10
5. **Infiltração acumulada** — `I = [K/(60*(n+1))] * T^(n+1)`
6. **Tempo de oportunidade por ponto** — `To(i) = Tc + Td(i) + Trec(i) - Tx(i)`
7. **Lâmina com redução de vazão** — fórmula com `qi`, `qr`, `Tt`, `Tr`
8. **Planejamento operacional** — NTS, NSD, TIP, NPD, NSP, Q projeto
9. **Seleção do maior comprimento viável** — avaliação sequencial com critérios
10. **Tela de entrada em etapas** — Stepper com 8 etapas
11. **Gráficos expandidos** — 5 tipos (oportunidade, lâmina, comparativo, indicadores)
12. **Representação visual do terreno** — CustomPainter com sulcos
13. **Tela de resultado auditável** — fórmulas, unidades, valores completos vs exibidos
14. **Persistência e exportação** — JSON, relatório, rastreabilidade
15. **Testes de integração** — caso milho 540×200

---

## Issues de implementação

### Ordem e dependências

```
BLOCO 1 — Fundação
  ISSUE-001 → ISSUE-002 → ISSUE-003 → ISSUE-004
                                   ↓
BLOCO 2 — Simulação de avanço e vazão
  ISSUE-005 → ISSUE-006 → ISSUE-007
                                   ↓
BLOCO 3 — Tempo, lâminas e eficiência
  ISSUE-008 → ISSUE-009
                                   ↓
BLOCO 4 — Planejamento e operação
  ISSUE-010
                                   ↓
BLOCO 5 — Interface e persistência
  ISSUE-011 → ISSUE-012 → ISSUE-013 → ISSUE-014 → ISSUE-015
                                   ↓
BLOCO 6 — Validação final
  ISSUE-016
```

---

### ISSUE-001 — Modelar os dados do projeto de irrigação

**Objetivo:** criar os modelos de domínio para armazenar um projeto completo.

**Arquivos a criar:**
- `lib/models/irrigation_project.dart`

**Estrutura:**

```dart
class IrrigationProject {
  final String id;
  final String versaoCalculo;
  final Area area;
  final GeometriaSulco geometria;
  final Solo solo;
  final Cultura cultura;
  final Clima clima;
  final EnsaioAvanco? ensaioAvanco;
  final EnsaioInfiltracao? ensaioInfiltracao;
  final ParametrosOperacao operacao;
  final ResultadosProjeto? resultados;
  final List<Alerta> alertas;
}

class Area {
  final double comprimentoM;
  final double larguraM;
  final double declividadePercentual;
  double get hectares => (comprimentoM * larguraM) / 10000;
}

class GeometriaSulco {
  final String forma; // "V", "trapezoidal", "retangular"
  final double? larguraSuperiorM;
  final double? profundidadeM;
  final double? larguraBaseM;
  final double espacamentoM;
  // Cálculos
  double? get areaSecaoM2 => ...;
  double? get perimetroMolhadoM => ...;
  double? get raioHidraulicoM => ...;
  // Regra de referência §28.1: espaçamento ≤ 2 × profundidade raízes
  bool get espacamentoValido => ...;
}

class Solo {
  final TexturaSolo textura;
  final double uccPercentual;
  final double upmpPercentual;
  final double densidadeGcm3;
  final double vibMmH;
  final double fracaoAguaDisponivel;
  final double profundidadeRaizesM;
}

class Cultura {
  final String nome;
  final double espacamentoFileirasM;
  final double espacamentoPlantasM;
  final double? kc;
}

class Clima {
  final double? etoMmDia;
  final double? etcMmDia;
  final double? precipitacaoEfetivaMmDia;
  final double demandaLiquidaMmDia;
}

class EnsaioAvanco {
  final List<PontoEnsaio> pontos;
  final MetodoAjusteAvanco metodo; // dois_pontos, minimos_quadrados
  final ParametrosAvanco? parametros; // k, b calculados
}

class EnsaioInfiltracao {
  final ConfiguracaoEnsaioInfiltracao configuracao;
  final List<PontoInfiltracao> pontos;
  final ParametrosInfiltracao? parametros; // K, n calculados
}

class ParametrosOperacao {
  final double vazaoInicialLs;
  final double? vazaoReduzidaLs;
  final double? tempoMudancaH;
  final double jornadaDiariaH;
  final double? perdasConducaoLs;
  final bool escoamentoReutilizado;
}

// Dados por estaca (§26.4)
class DadosEstaca {
  final double estacaM;
  final double? tempoAvancoMin;
  final double? tempoDeplecaoMin;
  final double? tempoRecessoMin;
  final double? tempoOportunidadeMin;
  final double? laminaInfiltradaMm;
}

// Fase de reposição (§26.1)
class FaseReposicao {
  final double? tempoCorteH;
  final bool escoamentoReutilizado;
  final double? instanteInicioEscoamentoFinalMin;
}

class ResultadosProjeto {
  final double irnMm;
  final double turnoRegaCalculadoDias;
  final int turnoRegaOperacionalDias;
  final double? laminaMediaAplicadaMm;
  final double? eficienciaAplicacaoPercentual;
  final double? eficienciaDistribuicaoPercentual;
  final double? perdaPercolacaoPercentual;
  final double? perdaEscoamentoPercentual;
  final Diagnostico? diagnostico;
}

class Alerta {
  final TipoAlerta tipo;
  final String mensagem;
  final Map<String, dynamic>? dados;
}
```

**Critérios de aceite:**
- largura e profundidade do sulco são campos independentes
- declividade armazenada em `%`
- nenhum resultado depende de texto formatado
- valores ausentes são `null`, nunca zero
- cada projeto possui identificador e versão do cálculo

**Testes:** criação do modelo completo, modelo com dados pendentes, serialização JSON.

---

### ISSUE-002 — Criar sistema de unidades e validação de entradas

**Objetivo:** impedir cálculos com unidades incompatíveis.

**Arquivo a criar:**
- `lib/services/units_service.dart`

**Conversões a suportar:**
- `min → h` (÷60)
- `L/s → mm/h` em área: `VI = Qinfiltrada * (3600 / area_m2)`
- `cm → m` (÷100)
- `% → decimal` (÷100)
- `g/cm³` (sem conversão, mas validar faixa)

**Validações:**
- cada campo informa sua unidade
- conversões centralizadas
- rejeição de tempo, vazão ou distância incompatíveis
- declividade não convertida silenciosamente de `%` para decimal

**Testes:**
- `200 min → 3.333333 h`
- `0.81 L/s → 29.16 mm/h` em `100 m²`
- Rejeição de entrada negativa

---

### ISSUE-003 — Implementar cálculo da lâmina requerida e turno de rega

**Objetivo:** calcular automaticamente a lâmina necessária e o intervalo entre irrigações.

**Arquivo a criar:**
- `lib/services/simulation/lamina_requerida.dart`

**Fórmulas:**
```
IRN = [(UCC - UPMP) / 10] * Ds * z_cm * f
TR = IRN / demanda_diaria
```

**Critérios de aceite:**
- retorna IRN em mm
- retorna turno calculado e turno operacional
- exige UCC, UPMP, densidade, profundidade, fração e demanda
- alerta quando demanda diária é zero ou negativa
- guarda todos os valores intermediários

**Teste obrigatório:** caso milho → `IRN = 42 mm`, `TR = 10.5 dias`

---

### ISSUE-004 — Implementar curvas e equações de infiltração

**Objetivo:** suportar infiltração instantânea e acumulada.

**Arquivo a criar:**
- `lib/services/simulation/infiltration_model.dart`

**Escopo:**
- equação potencial `VI = K * T^n`
- regressão logarítmica — **o documento usa base 10** (`log10(VI) = log10(K) + n·log10(T)` → `K = 10^a`)
- integração para infiltração acumulada `I = [K/(60*(n+1))] * T^(n+1)`
- método de entrada e saída (Q entrada - Q saída → mm/h)
- fator de conversão: `VI(mm/h) = Qinfiltrada(L/s) * (3600 / area_m2)`
- parâmetros e unidades por ensaio

**Critérios de aceite:**
- `T = 0` excluído da regressão logarítmica
- base do logaritmo armazenada (base 10 para infiltração, conforme documento)
- equações em `mm/h` não reutilizam parâmetros em `L/min/m`
- K, n, a e dados originais preservados com **15 casas decimais**
- indicação da origem: ensaio, modelo ou valor informado
- `n + 1 ≠ 0` na fórmula da infiltração acumulada
- pelo menos 2 pontos válidos para estimar a curva
- `Qsaída > Qentrada` gera aviso de inconsistência
- VI deve ser não negativa
- unidade de VI armazenada junto com K

**Validações do documento (§25):**
- Qentrada e Qsaida usam a mesma unidade
- Qsaida não deve ser maior que Qentrada sem aviso
- VI não negativa
- T=0 excluído da regressão
- pelo menos 2 pontos válidos
- base do log armazenada
- unidade de VI armazenada com K
- se T em minutos, integração usa fator 1/60
- n+1 ≠ 0
- valores completos usados em cálculos posteriores
- arredondamento apenas na apresentação

**Testes obrigatórios:**
- Ensaio §19: VI = 35.203016822389664 * T^-0.31077526032565167
- Infiltração acumulada: I = 0.8505421902886259 * T^0.6892247396743483
- Equação do caso milho §56.4: VI = 1.411 * T^-0.446 (unidade: L/min por metro de sulco)
- Verificar que unidades não são misturadas entre ensaios

---

### ISSUE-005 — Implementar ensaio e simulação do tempo de avanço

**Objetivo:** calcular ou registrar o tempo necessário para a água alcançar cada ponto do sulco.

**Arquivo a criar:**
- `lib/services/simulation/advance_curve_model.dart`

**Escopo:**
- entrada de pontos medidos
- simulação por `Tx = k * x^b`
- dois pontos: `b = [ln(T0.5x) - ln(Tx)] / ln(0.5)`, `k = Tx / x^b`
- mínimos quadrados: regressão linear em log
- interpolação linear
- extrapolação com aviso
- comparação entre vazões
- curva distância × tempo
- marcação de vazão erosiva

**Regras de precisão (§12):**
- armazenar dados originais sem arredondar
- k e b com **pelo menos 15 casas decimais**
- armazenar unidade de cada grandeza
- armazenar método usado: `dois_pontos`, `minimos_quadrados` ou `interpolacao`
- armazenar base do logaritmo: `e` ou `10`
- armazenar data, origem e identificador do ensaio
- nunca substituir valor original pelo valor formatado para tela

**Condições de validade do método dos dois pontos (§6):**
- x > 0
- Tx > 0
- T0.5x > 0
- os dois pontos pertencem ao mesmo ensaio
- unidades de distância e tempo idênticas nas duas medições
- denominador da fórmula de b não pode ser zero

**Validações (§12):**
- x ≥ 0; Tx ≥ 0
- para regressão logarítmica: x > 0 e Tx > 0
- distâncias em ordem crescente
- tempos de avanço não diminuem com x (salvo justificativa)
- método dos dois pontos: dois positivos e distintos
- denominador da regressão linear não pode ser zero
- valores ausentes = null, nunca zero
- valores extrapolados identificados com aviso

**O que reutilizar:**
- `SurfaceIrrigationMath.fitAdvanceCurve` (já faz dois pontos)
- `AdvanceCurve` (já tem `timeAt`)

**Critérios de aceite:**
- suporta ensaio e simulação como métodos diferentes
- informa o tempo de avanço no final do sulco
- permite comparar 100m e 200m
- preserva pontos medidos
- exibe alerta quando vazão foi reprovada por erosão

**Testes obrigatórios:**
- Caso documento: b=1.3027..., k=0.0939...
- Caso real: b=1.3985..., k=0.0717...
- Ta(80m) = 32.90 min
- x(53min) = 112.51 m

---

### ISSUE-006 — Implementar seleção do maior comprimento viável

**Objetivo:** selecionar o maior comprimento que atende às restrições do projeto.

**Arquivo a criar:**
- `lib/services/simulation/length_selector.dart`

**Regra:** não escolher o maior comprimento cegamente. Avaliar sequencialmente: comprimento, declividade, erosão, tempo de avanço, uniformidade, eficiência e operação.

**Critérios de aceite:**
- testa comprimentos candidatos
- elimina comprimentos com risco de erosão
- elimina comprimentos com eficiência abaixo do limite configurado
- informa por que cada alternativa foi aprovada ou rejeitada
- retorna o maior comprimento aprovado
- permite ao usuário alterar o limite de eficiência

**Teste obrigatório:** caso principal deve comparar 100m e 200m e registrar o efeito da redução de vazão.

---

### ISSUE-007 — Implementar vazão não erosiva e manejo de redução

**Objetivo:** determinar vazão segura e vazão reduzida.

**Arquivo a criar:**
- `lib/services/simulation/flow_management.dart`

**Escopo:**
- `qmax = C / S0^a` por textura
- `qmax = 0.631 / S` (simplificada)
- tabela de parâmetros C/a (§30.2)
- vazão reduzida: `Qr = (f0 * L * E) / 3600`
  - **Ambiguidade do documento:** §43.1 apresenta fator 1.1, mas §43.2 não o aplica no exemplo numérico
  - **Decisão:** tratar fator 1.1 como parâmetro configurável (default: 1.0), registrar se aplicado
- validações de vazão (§30.4):
  - `q_aplicada > qmax` → alerta de erosão
  - vazão abaixo da faixa operacional → sinalizar avanço lento
  - registrar se vazão é constante ou reduzida
  - considerar vazão de saída no cálculo de perdas

**O que reutilizar:**
- `_calcularVazaoMaxima` em `RunFurrowSimulation`

**Critérios de aceite:**
- textura e declividade informadas
- unidade da declividade exibida (sem conversão silenciosa)
- `q_aplicada > qmax` gera alerta
- registra se fator 1.1 foi aplicado e qual versão da fórmula
- vazão reduzida nunca maior que vazão inicial

---

### ISSUE-008 — Implementar tempo de oportunidade e tempo de irrigação

**Objetivo:** calcular o tempo de oportunidade por ponto e o tempo de aplicação.

**Arquivo a criar:**
- `lib/services/simulation/opportunity_time.dart`

**Fórmulas:**
```
To(i) = Tc + Td(i) + Trec(i) - Tx(i)
Ti = To + Ta
```

**Critérios de aceite:**
- depleção e recesso podem ser informados ou desprezados
- `To(i)` nunca pode ser negativo
- curvas de avanço e recesso podem ser exibidas juntas
- unidade de cada tempo é explícita
- resultado informa se foi simulado ou simplificado

---

### ISSUE-009 — Implementar lâminas e parâmetros de desempenho

**Objetivo:** calcular lâmina aplicada, lâmina infiltrada, eficiência e perdas.

**Arquivo a criar:**
- `lib/services/simulation/depth_performance.dart`

**Escopo:**
- Lm com vazão constante: `Lm = (Tt * qc / (C * L)) * 3600`
- Lm com redução: `Lm = [((Tt-Tr)*qi) + (Tr*qr)] / (C*L) * 3600`
- 4 eficiências:
  - **Ec** (condução): `Ec = (Va / Vd) * 100` — perda entre captação e entrada na parcela
  - **Ed** (distribuição): `Ed = (Lf / ((Li + Lf) / 2)) * 100`
  - **Ea** (aplicação): `Ea = (Lf / Lm) * 100`
  - **GA** (adequação): `GA = (lâmina infiltrada útil / lâmina requerida) * 100`
- Perdas:
  - `Pp = [(Lmi - LL) / Lm] * 100` (percolação — se negativo, classificar como déficit)
  - `Pe = [(Lm - Lmi) / Lm] * 100` (escoamento)
- Lâmina média infiltrada por estacas: `Lmi = (Σ yi) / n` ou aproximação `(Li + Lf) / 2`
- diagnóstico automático (§41)
- limites configuráveis com defaults do documento:
  - Ea mínima aceitável: 60%
  - Ea ideal: 75%
  - Pp limite: 15%
  - Pe limite: 10%

**O que reutilizar:**
- `PerformanceIndicators` existente

**Testes:**
- Caso §38: Lm=60mm, Ed≈98%, Ea=50%, Pp=1%, Pe=49%
- Caso §45 (com redução): Lm≈36.45mm, Ea≈82.3%, Pp≈1.64%, Pe≈16%
- Caso milho §56.10: Ea≈66% após redução

---

### ISSUE-010 — Implementar planejamento operacional

**Objetivo:** calcular a operação diária do sistema.

**Arquivo a criar:**
- `lib/services/simulation/operational_planning.dart`

**Fórmulas:**
```
NTS = (Lt * Wt) / (L * E)
NSD = NTS / PI
TIP = ti + tmud
NPD = TDF / TIP
NSP = NSD / NPD
Q = NSP * Q0 + PC
```

**Critérios de aceite:**
- mostra valores teóricos e valores inteiros operacionais
- contabiliza tempo de mudança
- calcula vazão simultânea e perdas de condução
- não confunde sulcos totais com sulcos simultâneos
- trata jornadas incompletas e parcelas parciais
- modos de arredondamento (§48.1):
  - `ceil`: para cima (cobrir toda a área)
  - `floor`: para baixo (limite de capacidade)
  - decimal: para análise teórica
  - registrar modo de arredondamento no resultado

---

### ISSUE-011 — Criar tela de entrada em etapas

**Objetivo:** evitar um formulário único e confuso.

**Arquivo a criar:**
- `lib/views/irrigation/project_screen.dart`

**Etapas:**
1. Área e geometria
2. Sulco: largura, profundidade, forma, espaçamento e declividade
3. Solo
4. Cultura e raízes
5. Clima e demanda
6. Origem do avanço
7. Operação
8. Revisão antes de calcular

**Critérios de aceite:**
- largura, profundidade e declividade no mesmo grupo visual
- campos obrigatórios claros
- campos não fornecidos permanecem pendentes
- unidades aparecem nos campos
- usuário pode voltar sem perder dados
- tela de revisão mostra todas as entradas antes do cálculo

---

### ISSUE-012 — Criar gráficos do resultado

**Objetivo:** tornar o dimensionamento compreensível visualmente.

**Gráficos:**
- A: Curva de avanço (distância × tempo, múltiplas vazões)
- B: Tempo de oportunidade (faixa avanço↔recesso)
- C: Lâmina ao longo do sulco (infiltrada vs requerida)
- D: Comparação de cenários (barras)
- E: Indicadores de desempenho (barras horizontais)

**O que reutilizar:**
- `AdvanceChart`, `InfiltrationChart`, `WaterBalanceChart` existentes

---

### ISSUE-013 — Criar representação visual do terreno

**Objetivo:** mostrar como os sulcos ficam distribuídos na área.

**Arquivos a criar:**
- `lib/views/irrigation/widgets/terrain_painter.dart` — CustomPainter
- `lib/views/irrigation/widgets/terrain_view.dart` — widget

**Representação mínima:**
- retângulo proporcional à área
- linhas paralelas para os sulcos
- seta indicando sentido do escoamento
- indicação da declividade
- marcador da entrada e final do sulco
- cores diferentes para status

---

### ISSUE-014 — Criar tela de resultado auditável

**Objetivo:** mostrar dados completos, não apenas o resultado final.

**Arquivo a criar:**
- `lib/views/irrigation/project_results_screen.dart`

**A tela deve conter:**
- resumo da recomendação
- comprimento escolhido e alternativas rejeitadas
- vazão inicial e reduzida
- tempo de avanço e oportunidade
- lâmina necessária, infiltrada e aplicada
- eficiência e perdas
- turno de rega
- vazão de projeto
- gráficos
- representação da parcela
- fórmulas usadas, unidades, valores completos vs exibidos
- avisos e dados pendentes

---

### ISSUE-015 — Persistência, exportação e rastreabilidade

**Objetivo:** permitir recuperar e auditar cada cálculo.

**Arquivo a criar:**
- `lib/services/persistence/project_store.dart`

**Critérios de aceite:**
- salvar entradas e resultados como caso de teste
- guardar versão das equações e parâmetros
- guardar data do cálculo
- permitir duplicar um cenário
- exportar JSON e relatório
- preservar dados originais de ensaios
- permitir comparar duas versões

---

### ISSUE-016 — Testes de integração do caso principal

**Objetivo:** garantir que o fluxo completo reproduza o material.

**Arquivo a criar:**
- `test/features/irrigation/integration_corn_project_test.dart`

**Cenário mínimo:**
```
Área: 540 m × 200 m
Cultura: milho
Espaçamento: 0,90 m
Declividade: 0,5%
IRN esperado: 42 mm
Turno calculado: 10,5 dias
Comprimentos: 100 m e 200 m
Tempo de oportunidade: ≈130 min
Vazão reprovada: 1,5 L/s
Vazão reduzida: ≈0,75 L/s
Eficiência após redução: ≈66%
```

**10 verificações obrigatórias (§59):**
1. IRN = 42 mm
2. TR calculado = 10.5 dias
3. q = 1.5 L/s reprovado por erosão
4. To ≈ 130 min
5. Comprimentos 100m e 200m comparados
6. 200m com vazão constante → Ea ≈ 57%
7. Redução para 0.75 L/s aplicada
8. Ea após redução ≈ 66%
9. Largura e profundidade permanecem pendentes (não fornecidas no exemplo)
10. Equações de infiltração deste caso não misturadas com outros ensaios

**Valores intermediários (§56.9):**
- 100m: Ti = 165.18 min, Lm ≈ 110 mm, Ea ≈ 38%
- 200m: Ti = 220.18 min, Lm ≈ 73 mm, Ea ≈ 57%
- 200m com redução: Lm ≈ 64 mm, Ea ≈ 66%

**Critérios de aceite:**
- fluxo não calcula sem largura e profundidade quando obrigatórios
- caso pode ser executado com campos pendentes no modo "dados incompletos"
- resultados são reproduzíveis
- diferenças entre valores precisos e arredondados são identificadas
- segundo cenário (16 ha) não misturado com caso principal

---

## Estruturas JSON de referência

O documento define 6 estruturas JSON que devem ser suportadas pela persistência:

| Seção | Tipo | Campos aprox. | ISSUE |
|-------|------|:---:|:---:|
| §11 | Curva de avanço | ~30 | ISSUE-005 |
| §24 | Ensaio de infiltração | ~50 | ISSUE-004 |
| §33 | Reposição e dimensionamento | ~40 | ISSUE-008, ISSUE-009 |
| §42 | Eficiência e diagnóstico | ~30 | ISSUE-009 |
| §54 | Operação e projeto | ~40 | ISSUE-010 |
| §56.11 | Saída caso milho | ~50 | ISSUE-016 |

**Regra:** cada JSON deve incluir:
- tipo_calculo
- metodo
- unidades (explícitas)
- dados originais (sem arredondar)
- parametros_completos (15 casas decimais)
- parametros_arredondados (para exibição)
- equacoes
- resultados
- alertas
- data, versão, origem

---

## Práticas de manejo (referência — §39, §40)

O documento lista causas de desempenho insatisfatório e práticas de manejo. Essas são **referências de domínio**, não cálculos. Devem ser implementadas como:

1. **Tabela de diagnóstico** em `lib/data/diagnostico_manejo.dart` — mapeia indicadores para causas e ações candidatas
2. **Regras de alerta** no ISSUE-009 — gerar diagnóstico automático baseado nos limites configuráveis

**Causas de problemas de uniformidade (§39.1):**
- dimensionamento inadequado
- sistematização grosseira
- variação do solo
- compactação diferencial
- variação da seção por erosão
- erosão superficial
- variação da resistência ao escoamento

**Causas de problemas de eficiência (§39.2):**
- comprimento inadequado
- vazão inadequada
- tempo de aplicação inadequado
- variação da infiltração
- operação inadequada

**Práticas de manejo (§40):**
- §40.1: aumentar uniformidade (aumentar vazão, tempo, reduzir comprimento, diques, surge flow)
- §40.2: reduzir percolação (aumentar vazão, reduzir tempo/comprimento, aumentar declive)
- §40.3: reduzir escoamento (reduzir vazão/tempo, aumentar comprimento, conter água, reutilizar)
- §40.4: aumentar armazenamento (reduzir vazão/tempo/comprimento, aumentar infiltração)

---

## Regras de validação consolidadas

### §12 — Precisão e armazenamento
- dados originais sem arredondar
- k, b, K, n com 15+ casas decimais
- unidade de cada grandeza armazenada
- método e base do log armazenados
- data, origem, identificador do ensaio
- nunca substituir valor original pelo formatado

### §25 — Infiltração
- Qentrada e Qsaida mesma unidade
- Qsaida ≤ Qentrada (senão aviso)
- VI não negativa
- T=0 excluído da regressão
- ≥ 2 pontos válidos
- base do log armazenada
- unidade de VI com K
- fator 1/60 se T em minutos
- n+1 ≠ 0
- valores completos em cálculos
- arredondamento apenas na apresentação

### §34 — Aplicativo completo
- tempo de corte posterior ao início do escoamento
- To(i) ≥ 0
- To(i) calculado com mesma unidade
- comprimento compatível com tempo de avanço
- vazão comparada com qmax
- fórmula de qmax com textura e unidade
- L, C, vazões compatíveis
- lâminas registram se infiltradas/aplicadas/necessárias
- eficiência com definição e dados de entrada
- resultados derivados mantêm valores originais
- alertas de déficit/excesso por estaca
- diferenciar regra prática, estimativa e modelo
- fórmulas com referência e versão

### §55 — Adicionais
- não misturar Pe_escoamento com Pef
- registrar se Qr calculada com/sem fator 1.1
- minutos/horas consistentes em cada fórmula
- não arredondar Qr antes de calcular lâmina
- Tt ≥ Tr
- qi, qr ≥ 0 e qr ≤ qi
- NTS, NSD, NPD, NSP guardam valor teórico e operacional
- TIP inclui tempo de mudança
- Q inclui perdas apenas uma vez
- ETc - Pef não negativo sem tratamento
- eficiências com limites de classificação
- recomendações indicam indicadores alvo e impactos

---

## Decisões técnicas

| Questão | Decisão |
|---------|---------|
| Novos modelos | `lib/models/` (padrão existente) |
| Novos serviços | `lib/services/simulation/` (pure Dart) |
| State management | Riverpod StateNotifier |
| Serialização | Hand-written `toMap`/`fromMap` |
| Gráficos | fl_chart (já dependência) |
| Testes | flutter_test |
| Breaking changes | Criar `IrrigationProject` paralelo a `IrrigationParameters` |

## Riscos

1. **ISSUE-001 é bloqueante** — todas as demás dependem do modelo
2. **ISSUE-004 e ISSUE-005** podem avançar em paralelo após ISSUE-001/002
3. **Telas (011-014)** dependem de todos os serviços estarem prontos
4. **Caso de teste do milho (ISSUE-016)** é a validação final
