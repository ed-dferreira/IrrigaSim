# Design — Nomenclatura pt-BR da inundação + desacoplamento `shared/ ✖ features/` (Etapa 9)

**Data:** 2026-11-03
**Referência de domínio:** `lib/features/irrigacao_inundacao/formulas_inundacao.md.md` (número das equações citadas).
**Referência de migração:** `docs/Plano_migracao_features.md` — Etapa 9 (linha 763) e regra 5 do §4.1.

**Decisões do usuário (2026-11-03):**

1. Isolamento: **as três features** (faixas, sulcos, inundação) — `lib/shared/` passa a
   importar **zero** arquivos de `lib/features/`.
2. Persistência: **ordem literal de chaves** — o JSON exportado deve ser byte a byte
   idêntico ao de hoje, inclusive na ordem das chaves.

---

## 1. Intenção e porquê

A feature de inundação mistura inglês e português (`basin_*.dart`, tipos `Basin*`/`Run*`,
campos e comentários já em português) e precisa de uma passada de nomenclatura + clean
code ancorada nas fórmulas.

Em paralelo, `shared/` importa as três features em **8 arquivos** (inventário na §5.3.1),
invertendo a regra de dependência do plano de migração. A Etapa 9 do plano manda remover
essa dependência ("`shared/` sem imports de `features/`" é critério de aceite). O usuário
escolheu atacar as três features de uma vez, mantendo a camada comum "bem pontual":
contratos pequenos + registry de codecs, sem envelope de mapa opaco.

---

## 2. Metas / Não-metas / Anti-metas

**Metas**

- Todos os arquivos e símbolos públicos de `irrigacao_inundacao/{models,services}` em
  português, com nomes ancorados nas equações (Q0, y0, tx, ti/ta, IRN, Ea, W0, NTT, TPP,
  NPD, APP, TR, Qe, Qm, Ec, Las, Les).
- `lib/shared/` com **zero** imports de `lib/features/` (critério da Etapa 9).
- JSON/CSV persistido **byte a byte idêntico** (ordem de chaves incluída), verificado
  com fixtures geradas **antes** da refatoração.
- Fórmulas, defaults numéricos, mensagens ao usuário e chaves de serialização intactos.
- Guardrail automatizado que impede o acoplamento de voltar.

**Não-metas (fora do recorte)**

- **Envelope `CenarioSalvo` + `CenarioResumo`** (item 1 da estratégia Etapa 9): adiado.
  Nosso caminho atinge o critério de aceite da etapa (imports zerados) sem essa
  reestruturação; `CenarioSalvo.parametros` continua tipado. Fica como follow-up.
- **Aposentar `IrrigationParameters`/`SimulationResult`** (item 4 do plano): mantidos como
  DTOs de transporte, com as partes de feature atrás de contrato.
- Renomear arquivos/classes de `views/`, `viewmodels/`, `routes.dart` de qualquer feature
  (só atualização mecânica de referências).
- Renomear faixas/sulcos (`Border*`, `ProjetoSulco` …) — a passada de nomenclatura é só
  da inundação.
- Alterar `formulas_inundacao.md.md`, as regras de guardrail de feature↔feature
  (Etapa 10 completa) ou outros pontos do plano.

**Anti-metas**

- Não "melhorar" a matemática, não unificar classes duplicadas (ex.: núcleo × serviço de
  volumes do arroz) — só renomear.
- Não introduzir framework de injeção; o registry é um singleton simples.
- Não mudar nenhum valor esperado de teste de regressão.

---

## 3. Restrições globais

- Comportamento de cálculo, valores padrão e textos exibidos não mudam.
- Chaves de `toMap`/`fromMap`, de `exportarJson` e do CSV não mudam
  (`'vib_m_min'`, `'projetoInundacao'`, `'projeto_faixa'`, `'entradasProjeto'`,
  `'planejamentoParcelas'`, `campo;valor;unidade`, …) — nem a **ordem** em que aparecem.
- Tipos de `shared/` usados por outras features não mudam de nome.
- Uma feature não passa a importar `views/`/`viewmodels/` de outra.
- Não commitar sem o usuário pedir.

---

## 4. Abordagens consideradas

| # | Descrição | Prós | Contras |
|---|-----------|------|---------|
| 1 | **Mapa opaco**: projetos/anexos viram `Map` cru em `shared/`; a feature tipa na leitura. | Zero contrato novo. | Leitura com cast espalhado; perde tipagem no contrato; já rejeitado. |
| 2 | **Contrato mínimo tipado + registry** (escolhido, agora para as 3 features) | `shared/` conhece só `ProjetoMetodo`/`AnexoSimulacao`/`CodecMetodo`; features continuam donas dos tipos; JSON idêntico. | Exige registro dos codecs em `main()` e nos testes que (de)codificam. |
| 3 | **Etapa 9 completa com envelope** (item 1 do plano: `CenarioSalvo` vira mapas + `CenarioResumo`) | `cenarios` lista sem decodificar. | Quebra todo consumidor tipado de `cenario.parametros.*` (views/viewmodels); não é necessário para zerar imports. **Adiado.** |

**Escolha: 2**, estendida às três features. Os itens 2–5 da estratégia do plano
(codecs, compatibilidade com JSON antigo, adaptadores, `ProjectStore` via registry) são
cumpridos; o item 1 (envelope) fica para follow-up.

---

## 5. Decisões

### 5.1 Escopo — as três features, inundação renomeada

- **Isolamento:** cortar `shared/ → {irrigacao_faixas, irrigacao_sulcos,
  irrigacao_inundacao}` por inteiro (8 arquivos, §5.3.1).
- **Nomenclatura:** apenas `irrigacao_inundacao/{models,services}` (§5.2). Faixas e
  sulcos são tocados apenas pelo isolamento (mudança de imports/posições), sem renomeio.

### 5.2 Nomenclatura

**Padrão adotado:** sufixo `Inundacao` para tipos públicos (espelha `ProjetoSulco` de
sulcos), arquivos `*_inundacao.dart`, funções já em português mantidas.

#### 5.2.1 Arquivos — `models/`

| De | Para |
|---|---|
| `basin_agronomy.dart` | `agronomia_inundacao.dart` |
| `basin_annexes.dart` | `anexos_inundacao.dart` |
| `basin_project.dart` | `projeto_inundacao.dart` |

#### 5.2.2 Arquivos — `services/`

| De | Para |
|---|---|
| `basin_csv.dart` | `csv_inundacao.dart` |
| `basin_planning.dart` | `planejamento_inundacao.dart` |
| `basin_reference_math.dart` | `nucleo_referencia_inundacao.dart` |
| `basin_reference_tables.dart` | `tabelas_referencia_inundacao.dart` |
| `rice_volumes_service.dart` | `volumes_arroz.dart` |
| `run_basin_simulation.dart` | `simulador_inundacao.dart` |
| `run_permanent_basin_simulation.dart` | `simulador_inundacao_permanente.dart` |

#### 5.2.3 Tipos e membros públicos

| De | Para | Nota |
|---|---|---|
| `BasinAgronomy` | `AgronomiaInundacao` | |
| `BasinAgronomy.withValue` | `AgronomiaInundacao.comValor(campo, valor)` | parâmetro `field` → `campo` |
| `BasinProject` | `ProjetoInundacao` | casa com o campo/extensão `projetoInundacao` |
| `BasinInfiltrationScenario` | `DadosInfiltracao` | casa com `dadosPrimeira`/`dadosTerceira` |
| `CenarioInfiltracaoBasin` | `CenarioInfiltracaoInundacao` | sufixo único (faixas usa `…Faixa`) |
| `OrigemIrnBasin` | `OrigemIrnInundacao` | |
| `BasinParcelasAnexo` | `AnexoParcelas` | |
| `BasinSelecaoVazaoAnexo` | `AnexoSelecaoVazao` | |
| `BasinVolumesAnexo` | `AnexoVolumesArroz` | |
| `BasinDimensioningResult` | `ResultadoDimensionamento` | |
| `BasinContinuaResult` | `ResultadoContinua` | |
| `ParcelasResult` | `ResultadoParcelas` | |
| `RiceVolumesResult` (núcleo) | `ResultadoVolumesArrozNucleo` | evita colisão com o do serviço |
| `RiceVolumesResultado` (serviço) | `ResultadoVolumesArroz` | |
| `RiceVolumesService` | `ServicoVolumesArroz` | |
| `BasinPlanning` | `PlanejamentoInundacao` | |
| `BasinChecagemOperacional` | `ChecagemOperacional` | |
| `BasinSoilGuideRow` | `LinhaGuiaSolo` | |
| `BasinBooherCell` | `CelulaBooher` | |
| `basinBooherCelulasSuspeitas` | `celulasBooherSuspeitas` | |
| `BasinHendersonReference` | `ReferenciaHenderson` | |
| `BasinPresetIntermitente/Continua/Arroz` | `PredefinicaoIntermitente/Continua/Arroz` | |
| `BasinReferenceTables` | `TabelasReferencia` | |
| `RunBasinSimulation` | `SimuladorInundacao` | invocação `SimuladorInundacao()(params)` mantida |
| `RunPermanentBasinSimulation` | `SimuladorInundacaoPermanente` | |
| `basinCsv` | `csvInundacao` | |

#### 5.2.4 Funções do núcleo (`nucleo_referencia_inundacao.dart`)

| De | Para | Âncora |
|---|---|---|
| `pot` | `potencia` | — |
| `vazaoMaxima` | `vazaoNaoErosivaMaxima` | eq. (5) Q0max |
| `profundidade` | `profundidadeEntrada` | eq. (12)/(2) y0 |
| `tempoNaDistancia` | `tempoAvancoNaDistancia` | eq. (6) tx |
| `tempoNaDistanciaNewton` | `tempoAvancoNewtonRaphson` | eq. (9)–(11) |
| `dimensionar`, `parcelas`, `continua`, `turnoRega`, `sigmaZ`, `infiltracaoInicio`, `desnivelAdmissivel`, `laminaMediaPlanalto`, `comprimentoMaximoPorDesnivel`, `diqueComporta`, `eficienciaRazao`, `laminaAplicada`, `areaHenderson`, `areaGuiaSolo`, `declividadeLiquida`, `selecionarMelhorVazao`, `materiaSecaTotal`, `vazaoVolume` | mantêm | já em português, âncora nas eq. (3), (4), (7), (14), (15)–(20) |

#### 5.2.5 Privados e locais em inglês

| Onde | De | Para |
|---|---|---|
| `csv_inundacao` | `_escaped` | `_escapar` |
| `simulador_*` | `_validate` | `_validar` |
| `simulador_inundacao` | `_trapezoidalMean` | `_mediaTrapezoidal` |
| `simulador_inundacao` | `lengthM`, `widthM`, `requiredDepthM`, `applicationEfficiency`, `deepPercolationPercent`, `runoffPercent`, `flowWarning`, `avanco`, `profile` | `comprimentoM`, `larguraM`, `laminaRequeridaM`, `eficienciaAplicacao`, `perdaPercolacaoPercent`, `escoamentoPercent`, `alertaVazao`, `curva`, `perfil` |
| `simulador_inundacao_permanente` | `rootDepthCm`, `turnDays`, `fillFlowLps`, `maintenanceFlowLps`, `conductionEfficiency`, `soilStorageM3`, `surfaceStorageM3`, `fillVolumeM3`, `fillTimeHours`, `waterDepthM`, `boardGeometryM2` | `profundidadeCamadaCm`, `turnoDias`, `vazaoEnchimentoLs`, `vazaoManutencaoLs`, `eficienciaConducao`, `armazenamentoSoloM3`, `armazenamentoSuperficialM3`, `volumeEnchimentoM3`, `tempoEnchimentoH`, `profundidadeAguaM`, `areaGeometriaM2` |

`q0M3MinM`, `lasMm`, `lesMm`, `checagem` são PT/abreviação de fórmula — mantêm.
Locais `point`/`distance`/`fraction`/`values` → `ponto`/`distancia`/`fracao`/`valores`.

#### 5.2.6 O que **não** muda

- Chaves de serialização e campos do CSV; literais de UI e mensagens de erro.
- Campos já em português com âncora de fórmula: `q0M3MinM`, `y0M`, `taMin`, `tiMin`,
  `s0`, `r`, `tppMin`, `npdTeorico`, `npdInteiro`, `appM2`, `ntt`, `qTotalLS`,
  `larguraTabuleiroM`, `qeLS`, `qmLS`, `vibMMin`, `rugosidadeN`, …
- Nomes de `views/`, `viewmodels/`, `routes.dart` e do barrel da feature (só
  referências atualizadas).
- `PontoGrafico`, `AdvanceCurve`, `MetodoIrrigacao`, `ManejoSulco`, `TexturaSolo`,
  `TipoInundacao` e demais tipos já residentes em `shared/`.

### 5.3 Desacoplamento — contrato pontual + registry (três features)

#### 5.3.1 Inventário do acoplamento (hoje)

| Arquivo em `shared/` | Importa de `features/` | Uso |
|---|---|---|
| `irrigacao/models/irrigation_parameters.dart` | sulco (`tipo_sulco_info`, `medicoes_campo`, `entradas_projeto`), faixa (`faixa_projeto`), inundação (`basin_project`) | tipos dos campos `entradasProjeto`, `projetoFaixa`, `projetoInundacao`, `tipoSulco`, `ensaioErosao`, `medicoes*`, enums |
| `irrigacao/models/simulation_result.dart` | faixa (`faixa_resultado`), sulco (`indicadores_balanco`), inundação (`basin_annexes`, `basin_planning`) | campos `borderResult`, `balancoSulco`, 4 anexos + `comAnexosInundacao` |
| `irrigacao/models/simulation_result_model.dart` | mesmos 4 | `toMap`/`fromMap` desses campos |
| `cenarios/models/cenario_salvo.dart` | faixa, inundação, sulco (`tipo_sulco_info`, `medicoes_campo`, `entradas_projeto`) | encode/decode completo (inclui blocos legados) |
| `cenarios/services/project_store.dart` | faixa, inundação, sulco | `projeto_faixa`/`projeto_inundacao` com `fromLegacy`, `base_comum`, `TipoSulco.displayName` |
| `irrigacao/models/comum/adaptadores_superficie.dart` | faixa (`faixa_projeto`), sulco (`projeto_sulco`) | extensões `baseComum` nos projetos + `baseComumPara` |
| `irrigacao/widgets/terrain/terrain_view.dart` | sulco (`tipo_sulco_info`) | enum `TipoSulco` |
| `irrigacao/widgets/terrain/terrain_painter.dart` | sulco (`tipo_sulco_info`) | enum `TipoSulco` |

Não há exports nem imports relativos de features fora dessa lista.

#### 5.3.2 Tipos "contrato comum" que descem para `shared/`

Critério: **registro bobo que é superfície do DTO comum** desce para `shared/`;
**objeto com comportamento da feature** fica e vai para o contrato/codec.

| Tipo | De | Para | Por quê |
|---|---|---|---|
| `medicoes_campo.dart` (7 tipos: `MetodoAjusteAvanco`, `OrigemCurvaInfiltracao`, `HipoteseRecessao`, `EnsaioErosao`, `MedicaoAvanco`, `MedicaoEntradaSaida`, `MedicaoRecessao`) | `features/irrigacao_sulcos/models/` | `shared/irrigacao/models/medicoes_campo.dart` | **zero imports**; são campos do `IrrigationParameters`. Precedente: `ManejoSulco`, `OrigemVazaoReduzida`, `TexturaSolo` já moram em `shared/`. |
| `TipoSulco` + `TipoSulcoExtension` | `features/irrigacao_sulcos/models/tipo_sulco_info.dart` | `shared/irrigacao/models/tipo_sulco.dart` | tipo de campo do DTO + usado pelos widgets de terreno de `shared/`. |

- O arquivo `medicoes_campo.dart` **move por inteiro**; importadores são atualizados
  (`rg`).
- `tipo_sulco_info.dart` mantém `FaixaDeclividade`, `LimitesDeclividade`,
  `TipoSulcoInfo` e ganha `export 'package:irrigasim/shared/irrigacao/models/tipo_sulco.dart';`
  — re-export deliberado para não quebrar os ~N importadores existentes.
- **Não descem:** `EntradasProjeto`, `ProjetoSulco`, `BorderProject`, `BorderResult`,
  `IndicadoresBalancoSulco`, anexos de inundação (comportamento/deps na feature) — vão
  para o contrato (§5.3.3). `IndicadoresBalancoSulco` *poderia* descer (registro bobo),
  mas opta-se pelo mecanismo único de anexos para não misturar dois regimes.

#### 5.3.3 Contratos e registry (novos arquivos em `shared/`)

**`lib/shared/irrigacao/models/comum/contratos_metodo.dart`**

```dart
/// Payload de projeto versionado de um método; opaco para o compartilhado.
abstract interface class ProjetoMetodo {
  Map<String, Object?> toMap();
}

/// Anexo de resultado de um método; opaco para o compartilhado.
abstract interface class AnexoSimulacao {
  Map<String, Object?> toMap();
}

/// Ponte que cada feature registra para o compartilhado (de)codificar
/// sem importar `features/`.
abstract interface class CodecMetodo {
  MetodoIrrigacao get metodo;

  /// Payload do projeto a partir dos parâmetros; null grava null (sulco
  /// sem entradas). Faixas/inundação nunca retornam null (incluem legado).
  Map<String, Object?>? codificarProjeto(IrrigationParameters base);

  /// Projeto tipado a partir do mapa plano de `parametros` (lê a própria
  /// chave e aplica o adaptador legado); null só quando não há projeto.
  ProjetoMetodo? decodificarProjeto(Map<String, Object?> parametros);

  /// Chaves de anexo escritas ANTES das métricas em `SimulationResultModel.toMap`.
  List<String> get chavesAnexosIniciais;

  /// Chaves de anexo escritas DEPOIS de `planejamentoOperacional`.
  List<String> get chavesAnexosFinais;

  /// Anexos deste método presentes no mapa do resultado.
  Map<String, AnexoSimulacao> decodificarAnexos(Map<String, Object?> resultado);

  /// Projeção comum de leitura (hoje `baseComumPara`).
  BaseIrrigacao baseComum(IrrigationParameters base);
}
```

**`lib/shared/irrigacao/services/registro_codecs.dart`**

```dart
class RegistroCodecs {
  void registrar(CodecMetodo codec);              // sobrescreve por metodo
  CodecMetodo? para(MetodoIrrigacao metodo);
  CodecMetodo obrigatorio(MetodoIrrigacao metodo); // StateError se ausente
  List<String> get chavesAnexosIniciais;           // concatena codecs na ordem de registro
  List<String> get chavesAnexosFinais;
  Map<String, AnexoSimulacao> decodificarAnexos(Map<String, dynamic> mapa);
}

final registroCodecs = RegistroCodecs();
```

Chaves de anexo vivem **só nas features** (declaradas no codec); `shared/` não conhece
nenhuma chave de anexo — só as posições (inícios/fins) pedidas ao registry.

#### 5.3.4 `IrrigationParameters` — campo único de projeto

- Os três campos `entradasProjeto` (sulco), `projetoFaixa`, `projetoInundacao` viram
  **um**: `final ProjetoMetodo? projetoMetodo;` (+ `copyWith(projetoMetodo:)` e
  `clearProjetoMetodo`). `copyWith` com os nomes antigos tem **zero** chamadores
  (varredura exaustiva) — colapsar é seguro.
- Cada feature publica a leitura tipada como extensão, **no arquivo da própria classe
  do projeto** (os leitores já importam esse arquivo → quase zero churn de import):

```dart
// faixa_projeto.dart
extension ProjetoFaixaEmParametros on IrrigationParameters {
  BorderProject? get projetoFaixa =>
      projetoMetodo is BorderProject ? projetoMetodo as BorderProject : null;
}
// basin_project.dart (→ projeto_inundacao.dart)  → getter projetoInundacao
// entradas_projeto.dart                         → getter entradasProjeto
```

- Escritas (`toCompatParameters`, `EstadoParametrosSulco`) passam `projetoMetodo: this`
  (~4–8 pontos, mecânicos).
- Leituras existentes (`params.projetoFaixa ?? BorderProject.fromLegacy(p)`,
  `params.projetoInundacao?.rInicial`, `params.entradasProjeto?.curvaInfiltracao`,
  `cenarios_screen`) **não mudam**.

#### 5.3.5 `SimulationResult` — mapa de anexos

- Somem os 6 campos (`borderResult`, `balancoSulco`, `planejamentoParcelas`,
  `selecaoVazao`, `volumesArroz`, `checagemOperacional`) e `comAnexosInundacao` da
  classe. Entra:

```dart
final Map<String, AnexoSimulacao> anexos;   // default const {}
```

- `comPlanejamentoOperacional` copia `anexos: anexos`.
- **Extensões devolvem os nomes antigos** (leitores não mudam), colocadas no arquivo
  que declara o tipo do anexo (os leitores já o importam):

```dart
// faixa_resultado.dart      → BorderResult? get borderResult      (chave 'resultadoFaixa')
// indicadores_balanco.dart  → IndicadoresBalancoSulco? get balancoSulco (chave 'balancoSulco')
// anexos_inundacao.dart     → get planejamentoParcelas / selecaoVazao / volumesArroz
//                             + get checagemOperacional
//                             + SimulationResult comAnexosInundacao(...)  (corpo movido daqui)
```

- **Escritas** nas 3 features passam a montar o mapa com a chave-canonidade do próprio
  codec (`anexos: {CodecFaixa.chaveResultado: r}`), preservando a ordem de inserção que
  o `toMap` espera; sites: `executar_simulacao_faixa.dart:22`,
  `simulador_sulcos.dart:530`, `run_permanent_basin_simulation.dart:124`,
  `basin_simulation_coordinator.dart:101` (via `comAnexosInundacao`, nome mantido).
- **Ordem literal no `toMap`** (decisão do usuário): `SimulationResultModel.toMap`
  escreve `registroCodecs.chavesAnexosIniciais` no topo (hoje: `resultadoFaixa`,
  `balancoSulco`), as métricas compartilhadas no meio, e
  `registroCodecs.chavesAnexosFinais` após `planejamentoOperacional` (hoje: os 4 da
  inundação). Chave presente em `anexos` e **não** alegada por nenhum codec →
  `StateError` (falha barulhenta, nunca perda silenciosa).
- `fromMap` → `anexos: registroCodecs.decodificarAnexos(map)`; `exportarJson` lê
  `r.anexos['balancoSulco']` (string literal — chave de persistência, sem tipo).

#### 5.3.6 Pontos de serialização — chamadas via registry

| Arquivo | Mudança |
|---|---|
| `cenario_salvo.dart` `toMap` | condicionais e posições **idênticos**; só o valor muda: `entradasProjeto: registroCodecs.obrigatorio(sulco).codificarProjeto(parametros)`, `projetoFaixa: registroCodecs.obrigatorio(faixa).…`, `projetoInundacao: registroCodecs.obrigatorio(inundacao).…`. Os `?? fromLegacy` saem daqui (vivem nos codecs). |
| `cenario_salvo.dart` `fromMap` | `projetoMetodo: registroCodecs.obrigatorio(metodo).decodificarProjeto(paramData)`; **os dois blocos legados** (faixa ~L167–193, inundação ~L194–247, construção temporária de `IrrigationParameters`) movem-se **literalmente** para os codecs. Sulco: `fromMap` do payload ou null (sem legado). |
| `project_store.dart` `exportarJson` | `base_comum` → `p.baseComumPara(metodo)` (agora despacha para `codec.baseComum`); `projeto_faixa`/`projeto_inundacao`/`entradas_projeto_sulco` → `codificarProjeto` via `obrigatorio(metodo)`, mantendo condição e posição. |
| `simulation_result_model.dart` | `toMap`/`fromMap` conforme §5.3.5. |
| `adaptadores_superficie.dart` | as extensões `BaseProjetoFaixas`/`BaseProjetoSulcos` **movem-se para as features** (viram getters `baseComum` nas próprias classes `BorderProject`/`ProjetoSulco`); `baseComumPara` fica em `shared/` só como despacho: `registroCodecs.obrigatorio(metodo).baseComum(this)`. Os ramos por método (incluindo o `fromLegacy` de faixas) copiam-se para os codecs com comportamento idêntico. |

#### 5.3.7 Codecs (novos arquivos nas features)

| Arquivo | Classe | Conteúdo |
|---|---|---|
| `features/irrigacao_faixas/services/codec_faixa.dart` | `CodecFaixa` | `codificarProjeto` = `(base.projetoMetodo as BorderProject? ?? BorderProject.fromLegacy(base)).toMap()`; `decodificarProjeto` = payload → `fromMap`, ausente → `fromLegacy(temporário)` **verbatim**; `chavesAnexosIniciais = ['resultadoFaixa']`, `finais = []`; `decodificarAnexos`; `baseComum`. |
| `features/irrigacao_sulcos/services/codec_sulco.dart` | `CodecSulco` | `codificarProjeto` = `(base.projetoMetodo as EntradasProjeto?)?.toMap()` (null sem entradas, como hoje); `decodificarProjeto` = `EntradasProjeto.fromMap` ou null; `chavesAnexosIniciais = ['balancoSulco']`; `decodificarAnexos`; `baseComum` (ramo de sulcos de `baseComumPara`). |
| `features/irrigacao_inundacao/services/codec_inundacao.dart` | `CodecInundacao` | `codificarProjeto` = `(base.projetoMetodo as ProjetoInundacao? ?? ProjetoInundacao.fromLegacy(base)).toMap()`; `decodificarProjeto` = payload → `fromMap`, ausente → `fromLegacy(temporário)` **verbatim**; `chavesAnexosFinais = ['planejamentoParcelas','selecaoVazao','volumesArroz','checagemOperacional']`; `decodificarAnexos`; `baseComum`. |

Constantes de chave (`chaveResultado`, `chavesAnexos…`) são a **fonte única** usada
pelo codec e pelos sites de construção; a consistência chave-construção-decodificação é
garantida pelos testes de round-trip/fixtures.

#### 5.3.8 Registro (composition root)

- **`lib/app/codecs.dart`** (novo): `void registrarCodecs()` registra `CodecFaixa`,
  `CodecSulco`, `CodecInundacao` **nesse ordem** (a ordem define a ordem das chaves
  iniciais no JSON). `lib/main.dart` chama `registrarCodecs()` antes de `runApp`.
- **Testes:** todo teste que chama `CenarioSalvo.toMap/fromMap`,
  `SimulationResultModel.toMap/fromMap`, `exportarJson` ou `baseComumPara` chama
  `registrarCodecs()` em `setUpAll` (varredura `rg` no plano). Registry idempotente
  (sobrescreve por método) — múltiplas chamadas são seguras.
- **Falha explícita:** caminhos de `CenarioSalvo`/`project_store` usam
  `obrigatorio(metodo)` → `StateError` com mensagem clara se faltar registro;
  `SimulationResultModel.toMap` lança em chave de anexo órfã; `fromMap` sem codec
  descarta o anexo (coberto pelo teste de round-trip/fixtures).

### 5.4 Clean code pontual da inundação (ancorado nas fórmulas)

1. `AgronomiaInundacao.irnMm` repete a checagem de nulos do getter `completa` →
   `if (!completa) return null;` (comportamento idêntico).
2. `simulador_inundacao_permanente`: extrair `_volumeM3(laminaMm, areaHa)` para os
   quatro cálculos `mm × ha × 10` repetidos.
3. Doc comments do núcleo passam a citar a **numeração do `formulas_inundacao.md.md`**
   (eq. 1–20) além dos slides.
4. Helpers em português em `csv_inundacao` (§5.2.5).

Nada de extração maior: os métodos grandes já têm responsabilidade única.

---

## 6. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Registro esquecido → projeto/anexos nulos ou `StateError` | `registrarCodecs()` em `main()` + `setUpAll` de todos os testes de persistência; `obrigatorio()` barulhento; round-trip + fixtures. |
| Ordem de chaves JSON mudar silenciosamente | **Fixtures geradas antes da refatoração** (passo 0) comparadas byte a byte; registro em ordem fixa. |
| Blocos legados movidos para os codecs mudarem defaults | Mover literalmente (faixa L167–193, inundação L194–247); testes legados existentes (`basin_persistence_test`, `border_persistence_test`, `furrow_erosion_reduction_test`) seguem verdes sem alterar valores. |
| Colisão de nome nova (`ChecagemOperacional`, `CenarioInfiltracaoInundacao`) | `flutter analyze` completo; baseline hoje tem 2 ocorrências pré-existentes (1 warning sulcos, 1 info) que não são nossas. |
| Renomeio/realocação quebrar chamadas fora do recorte | Varredura `rg` de resíduos (§7) + análise completa. |
| Escopo grande demais para uma passada | Fases do plano (§8) com `analyze`+`test` ao fim de cada uma; fixtures antes de qualquer mudança. |
| `cenarios_screen` (view transversal) ler extensões de duas features | Extensões vivem nos arquivos das classes que essa view já importa — verificar com `analyze` na fase. |

---

## 7. Validação

```bash
# 0) fixtures (ANTES de qualquer mudança — ver §8, fase 0)
#    gerar test/fixtures/cenarios/{sulco,faixa,inundacao}{,_legado}.json com o código atual

flutter analyze                                        # baseline: 2 ocorrências pré-existentes
flutter test                                           # suíte completa (escopo repo-wide)
rg -n "package:irrigasim/features/" lib/shared         # zero  → guardrail também automatizado
rg -n "Basin|RiceVolumes|RunBasin|run_basin|basin_" \
  lib/features/irrigacao_inundacao/{models,services} lib/shared test --glob '*.dart'   # zero, c/ exenções
```

- **Guardrail novo:** `test/architecture/shared_sem_features_test.dart` — falha se
  qualquer arquivo de `lib/shared/` importar/exportar `package:irrigasim/features/`.
  (Regra 5 do §4.1 do plano; as demais regras da Etapa 10 ficam para o plano original.)
- **Byte-identidade:** teste novo compara `jsonEncode(cenario.toMap())` e
  `jsonEncode(await store.exportarJson(...))` às fixtures commitadas, para os três
  métodos, em versão completa e legada.
- **Exenções do comando de resíduos** (mantidas de propósito, §5.2.6): símbolos e
  arquivos de `views/`, `viewmodels/`, `routes.dart`, os nomes dos testes dessas camadas
  (ex.: `basin_results_screen_test.dart`) e o nome `basin_persistence_test.dart`
  (testa models/services; renomear é opcional). Testes de units renomeadas usam os
  nomes novos.
- Números de referência (ta, Ea, PT, V2–V4, TR, Qe/Qm) inalterados nos testes golden.

---

## 8. Deixa para o implementador (ordem das fases do plano)

1. **Fase 0 — Fixtures de referência:** com o código *atual*, gerar e versionar JSONs
   dos três métodos (cenário completo + legado) a partir de `CenarioSalvo.toMap()` e
   `ProjectStore.exportarJson`; criar o teste de comparação byte a byte. Nada muda em
   `lib/`.
2. **Fase 1 — Nomenclatura + clean code da inundação** (§5.2, §5.4): renomear
   models/services + atualizar referências em views/viewmodels/shared/testes.
3. **Fase 2 — Tipos sulco para `shared/`** (§5.3.2): mover `medicoes_campo.dart`,
   extrair `TipoSulco`, re-export, atualizar imports.
4. **Fase 3 — Contratos, registry e codecs** (§5.3.3–5.3.7): campo `projetoMetodo`,
   mapa `anexos`, extensões, codecs, rewiring de `cenario_salvo`, `project_store`,
   `simulation_result*`, `adaptadores_superficie`.
5. **Fase 4 — Registro + guardrail + validação** (§5.3.8, §7): `app/codecs.dart`,
   `main()`, `setUpAll` nos testes, teste de arquitetura, suíte completa, resíduos.

Cada fase termina com `flutter analyze` + `flutter test` verdes antes da próxima.
Detalhamento tarefa a tarefa (arquivos por tarefa, comandos) fica para o
`writing-plans`, no formato de
`docs/superpowers/plans/2026-10-28-nomenclatura-viewmodels-sulcos.md`.
