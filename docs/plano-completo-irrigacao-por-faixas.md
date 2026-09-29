# Plano completo de implementação — irrigação por faixas

## Objetivo e referências

Entregar **um projeto novo de faixas abertas em declive, com escoamento livre e vazão constante**, desde a entrada de dados até a simulação, avaliação espacial e planejamento de operação. A especificação agronômica, as ressalvas de fonte e as equações F01–F32 estão em [`Extracao_completa_irrigacao_por_faixas.md`](Extracao_completa_irrigacao_por_faixas.md), extraída de `docs/materiais_origem/Aula 7 - Irrigação por faixas.pdf`. Usar [`plano-completo-irrigacao-por-sulcos.md`](plano-completo-irrigacao-por-sulcos.md) como **modelo de organização do fluxo e dos critérios de aceite**, não como fonte de fórmulas para faixas.

**Fluxo real hoje:** `IrrigationScreen` → `ParametersScreen` → `ParametersController` → `RunBorderSimulation` → `ResultsScreen`. O fluxo em etapas `TipoSulcoScreen` → `ProjectScreen` → `ProjectResultsScreen` é de sulcos; as rotas de projeto já existem em `app_router.dart`, mas faixas não as utilizam. Antes do percurso novo, executar a Etapa 0 para organizar `lib/models/`, `lib/services/simulation/` e `lib/viewmodels/` por método (`sulcos/`, `faixas/`, `inundacao/`); manter as telas e rotas atuais durante essa reorganização e iniciar a navegação de faixas na Etapa 1. Usar `flutter_riverpod` e `go_router` e compartilhar componentes visuais e serviços matemáticos somente quando as hipóteses e as unidades coincidirem.

## Inventário e lacunas verificadas no código

| Assunto | Estado observado | Referência |
| --- | --- | --- |
| Seleção | O cartão “Faixa” abre diretamente o formulário rápido; não há escolha da condição de jusante nem descrição do domínio simulado. | `irrigation_screen.dart`, `app_router.dart` |
| Entradas | Comprimento, largura, dois declives, `k`, `a`, VIB, vazão unitária, IRN, `n` e `r` inicial já aparecem. `tempoAplicacao` é editável, mas o motor calcula seu próprio corte; padrão de largura 50 m é maior que a faixa usual 4–20 m do PDF. | `parameters_screen.dart`, `parameters_controller.dart` |
| Estado | `ParametersState`/`IrrigationParameters` misturam campos genéricos, de sulco e de inundação. `sigmaZ` funciona como palpite inicial de `r`; `tempoAplicacao` não expressa o mesmo significado em todos os métodos. | `parameters_controller.dart`, `irrigation_parameters.dart` |
| Núcleo | `RunBorderSimulation` resolve um candidato; usa Vmax=8 m/min, ρ2=3,3 sem confirmação do PDF; oportunidade recebe só duas iterações; avanço atualiza `r` uma vez; depleção roda quatro vezes e não expõe resíduos nem condições de domínio. | `run_border_simulation.dart` |
| Perfil e perdas | Onze amostras, Ea simplificada mesmo se houver déficit, Pp/Pe pelo excesso médio com `clamp`, Er pelo último ponto. Não há balanço integral verificado nem curva de recessão exposta. | `run_border_simulation.dart`, `simulation_result.dart` |
| Resultados | O formulário rápido leva a `ResultsScreen`; o projeto de sulcos tem auditoria em `ProjectResultsScreen`. Este último apresenta fórmulas de sulco e até `TerrainView` com “sulcos” para métodos não sulco, portanto não pode ser reutilizado sem ramificar o conteúdo. | `results_screen.dart`, `project_results_screen.dart`, `terrain_view.dart` |
| Persistência | `CenarioSalvo` e `SimulationResultModel` serializam os contratos atuais; `ResultsController` salva cenários e as telas exportam CSV. Campos novos exigem leitura retrocompatível. | `cenario_salvo.dart`, `simulation_result_model.dart`, `results_controller.dart` |
| Referência | Há dois arquivos `Projeto faixas - Dimensionamento exemplo*.xlsx` em `docs/materiais_origem/`. A extração foi redigida sem essas planilhas como gabarito conferido: auditar origem, fórmulas e unidades antes de usá-las para validar cálculos. | `docs/materiais_origem/`, extração §8 e §13 |

## Etapa 0 — Organizar modelos, serviços e viewmodels por método

**Objetivo:** preparar o código existente antes de adicionar funcionalidades de faixas, com uma migração estrutural verificável e sem modificar as fórmulas, resultados, rotas ou dados persistidos. Adotar nomes de diretório **pelo método**, em português e sem acento: `sulcos/`, `faixas/` e `inundacao/`. A pasta pai já informa a camada, portanto `models/sulcos/` é preferível a `models/sulcos_models/`; o mesmo vale para `services/simulation/faixas/` e `viewmodels/faixas/`. Escolher `inundacao/` em vez de `bacias/` alinha a pasta com `MetodoIrrigacao.inundacao` e reúne os regimes intermitente e permanente sem parecer um método adicional.

Estrutura-alvo mínima dentro das pastas que o projeto já utiliza:

```text
lib/
├── models/
│   ├── sulcos/       # tipos, entradas e resultados exclusivos de sulcos
│   ├── faixas/       # novos contratos exclusivos de faixas
│   ├── inundacao/    # contratos exclusivos da inundação
│   └── ...           # contratos compartilhados: método, cenário e resultado comum
├── services/
│   ├── simulation/
│   │   ├── sulcos/   # RunFurrowSimulation e cálculos específicos
│   │   ├── faixas/   # RunBorderSimulation e cálculos específicos
│   │   ├── inundacao/  # RunBasinSimulation / RunPermanentBasinSimulation
│   │   └── ...       # cálculos comprovadamente compartilhados
│   └── persistence/  # permanece transversal aos três métodos
├── viewmodels/
    ├── sulcos/       # coordenação e estado específicos
    ├── faixas/       # coordenação e estado específicos
    ├── inundacao/    # coordenação e estado específicos
    └── ...           # providers e despacho entre métodos, quando comuns
└── views/
    └── irrigation/
        ├── sulcos/      # telas específicas de sulcos
        ├── faixas/      # telas específicas de faixas
        ├── inundacao/   # telas específicas de inundação
        └── ...          # telas e componentes compartilhados
```

- Inventariar importadores antes de mover arquivos. Começar pelos serviços inequívocos (`run_furrow_simulation.dart`, `run_border_simulation.dart`, `run_basin_simulation.dart`, `run_permanent_basin_simulation.dart`); classificar os demais pelo uso real. `surface_irrigation_math.dart`, `performance_indicators.dart`, `lamina_requerida.dart`, contratos de cenário e persistência ficam na raiz compartilhada enquanto servirem a mais de um método. Só mover `operational_planning.dart`, `infiltration_model.dart` e similares depois de conferir consumidores e semântica: se tiverem funções de métodos diferentes, separar as funções primeiro, não duplicar o arquivo inteiro.
- Desmembrar gradualmente `IrrigationParameters`/`SimulationResult` e `ParametersState`/`ParametersController` nos tipos e coordenadores específicos; manter um contrato/adapter compartilhado e o `parametersProvider` como ponto de entrada para seleção e telas existentes durante a migração. A distribuição por pastas **não** implica converter silenciosamente `tempoAplicacao`, `vazao`, `sigmaZ` ou valores salvos. Não criar camadas adicionais só para espelhar as três pastas.
- Ajustar imports em telas, `app_router.dart`, providers, `CenarioSalvo`/`SimulationResultModel` e testes; confirmar que Firestore/local continuam lendo cenários anteriores. Migrar em incrementos: serviços → contratos específicos → viewmodels, executando testes e análise a cada incremento; adiar mudanças de comportamento hidráulico para as etapas seguintes.

**Aceite:** os três métodos executam os mesmos casos de regressão antes/depois da movimentação; sulcos, faixas e inundação intermitente/permanente ainda navegam, salvam e restauram os mesmos cenários. Arquivos específicos estão em sua subpasta, compartilhados continuam acessíveis a todos sem imports cruzados entre métodos; `flutter analyze` e `flutter test` passam após a reorganização.

## Contrato e decisões antes de integrar

1. **Domínio explícito:** primeira entrega numérica somente para faixa **aberta, S0>0, escoamento livre, entrada constante até o avanço completo e perfil longitudinal representado por declive único**. Faixa fechada, nível (S0=0), redução de vazão, reuso, trecho final plano e corte com frente ainda em trânsito permanecem identificáveis na interface, mas sem resultado desse motor (extração §§2, 6.3, 7, 11). Não reaproveitar enum `ManejoSulco` nem alterar `RunFurrowSimulation` para isso.
2. **Contrato próprio dentro do fluxo atual:** adicionar em `lib/models/faixas/` dados tipados (condição jusante, cobertura, dimensões da área, altura real do dique quando informada, origem de IRN, vazão unitária, cenário de infiltração e operação) e resultado tipado com tempos, perfil, volumes, status, fórmula/página/versão. Manter `SimulationResult` como contrato de compatibilidade onde necessário, sem fazer `metricas` de texto a única fonte dos indicadores. Distinguir `rInicial` do `sigmaZ` calculado; migrar `sigmaZ` legado apenas na leitura de faixa.
3. **Unidades na fronteira:** `q0` informado em L/s/m → m³/min/m (`×0,06`); com `q0` interno, `Qfaixa=q0×W` em m³/min (ou, diretamente com a entrada em L/s/m, em L/s). `S0`/`St` decimais no núcleo, lâminas em m e tempos em min. Nomear `W` largura da faixa, `L` comprimento, `t0` oportunidade alvo, `ta` chegada ao final, `ti` instante de corte, `td` término da depleção e `tr` recessão final. Nunca multiplicar W dentro do balanço unitário; multiplicar volumes unitários por W **uma vez** na saída (extração §5).
4. **Referência numérica e fonte:** usar F01 de Hart somente como limite *literal do slide, com unidade empírica sinalizada*; F03/F04 como critérios distintos. Não usar F02 com Vmax=8 e ρ2=3,3 como limite confirmado; o PDF não estabelece a unidade de Vmax nessa expressão (extração §6.1). A tabela Marr gera sugestões, não `k/a/VIB`. Na tabela Booher, preservar os três valores anômalos e excluir essas células de recomendações automáticas (extração §4).
5. **Proveniência e cenários:** IRN pode ser informada ou calculada pelo serviço existente `lamina_requerida.dart` com entradas agronômicas suficientes; não substituir 56 mm do exemplo pela IRN calculada a partir dos defaults de sulco. Primeira e terceira irrigação da p.73 são cenários diferentes; comparar sem misturar `k/a/VIB`. A referência reconstruída da extração §8.4 **não é o gabarito da professora**.

## Etapa 1 — Percurso de faixas e contratos de entrada

**Alterar/criar:** contratos em `lib/models/faixas/` e adaptadores comuns em `lib/models/`, coordenação em `lib/viewmodels/faixas/` e despacho no `lib/viewmodels/parameters_controller.dart` (conforme a Etapa 0), `lib/views/irrigation/irrigation_screen.dart`, `lib/app/router/app_router.dart`, `lib/views/irrigation/project_screen.dart` ou uma tela de projeto de faixa em `lib/views/irrigation/`. Ajustar `parameters_screen.dart` se permanecer como modo rápido.

- Ligar “Faixa” a um percurso de projeto por etapas equivalente, em hierarquia e navegação, ao de sulcos: **área e geometria → faixa/solo → cultura e IRN → avanço/manejo → operação → revisão**. Usar componentes reaproveitáveis do `ProjectScreen` somente depois de desacoplar os rótulos e validadores de sulco; não mostrar “Dimensões do sulco” para faixas. Preservar acesso e significado dos cenários rápidos salvos anteriormente.
- Na revisão, indicar o modelo disponível e explicar escolhas ainda não simuláveis. Solicitar comprimento, largura, declives longitudinais/transversais com base de medida explícita, infiltração, cobertura, rugosidade, vazão unitária, diques e oferta de água; itens de cronograma são opcionais até a etapa operacional. Substituir defaults de sulco por exemplo de faixa identificado como **ilustrativo**, sem insinuar adequação de W=50 m ou de Vmax presumida.
- Tratar o tempo de corte como **saída calculada** para o modo de dimensionamento; se a entrada manual for mantida em modo de avaliação, separá-la do cálculo dimensionado e só habilitar quando o modelo suportar o respectivo corte. Remover a falsa indicação de que editar `tempoAplicacao` muda o cálculo de faixa se ainda não mudar.
- Versionar a leitura de dados de faixa no cenário salvo; ao restaurar registros antigos, mapear explicitamente `vazao` como L/s/m e `larguraOuEspacamento` como W (m), conservar a semântica legada de `tempoAplicacao` e marcar parâmetros ausentes como não informados.

**Aceite:** ao escolher faixa, o usuário percorre etapas com títulos de faixa; a revisão mostra `q0` em L/s/m e `Qfaixa` em L/s; entrada incompatível com o motor não executa cálculo. Registros antigos de sulco/inundação continuam abrindo com seus valores e unidade originais.

## Etapa 2 — Núcleo unitário de avanço e oportunidade

**Alterar/criar:** `lib/services/simulation/faixas/run_border_simulation.dart` e funções próprias em `lib/services/simulation/faixas/`; `lib/services/simulation/surface_irrigation_math.dart` só para operações realmente comuns; testes em `test/features/irrigation/`.

- Validar valores finitos, `L,q0,IRN,manning_n>0`, `0<a<1`, `k>0`, `VIB≥0`, `S0>0`; computar `y0` (F05), `I(τ)` e `t0` (F06–F07) com Newton salvaguardado, tolerância de passo **e resíduo**, teto de iterações e bisseção quando necessário. Não avaliar derivada singular em zero.
- Resolver F09–F12 iterando conjuntamente `r`, `σz`, `ta(L/2)` e `ta(L)` até convergir; recalcular termos dependentes de X em cada posição. Guardar `p=L/ta(L)^r` e produzir `ta(x)` apenas dentro do domínio; diferenciar `sem_convergencia` de candidato fora do domínio (`q0≤VIB·L/(1+r)` quando aplicável).
- Oferecer avaliação **por ensaio medido** como ramo distinto: estacas `(x, instante de avanço)` espaçadas aproximadamente 10–30 m, ajuste F08 por pontos positivos, dados brutos e erro de ajuste preservados; se houver recessão medida, usar seus instantes locais explicitando interpolação. Não aplicar uma curva medida em uma vazão à grade de otimização de outra vazão sem novo modelo/ensaio, nem apresentar extrapolação como medição (extração §§3, 6.3).
- Remover do caminho automático F02 sem convenção confirmada. Expor Hart F01 com ressalva, qmin F03, limite L F04 e incompatibilidade entre critérios. L usual (50–400 m), declive usual (0,2–6%) e dados Marr são **avisos**, não barreiras absolutas; S0=0 bloqueia o motor completo, embora F13 forneça avanço especial.

**Aceite:** `t0` da extração §8.3 ≈161,71965 min (primeira) e ≈195,13612 min (terceira), `qmin` em L=400 m ≈1,88156 L/s/m; `ta(L/2)<ta(L)` e resíduos dentro da tolerância declarada. Nenhum cálculo com entrada inválida retorna NaN ou valor truncado apresentado como sucesso.

## Etapa 3 — Depleção, recessão e balanço espacial

**Alterar/criar:** `lib/services/simulation/faixas/run_border_simulation.dart`, modelos em `lib/models/faixas/` e serviço de integração em `lib/services/simulation/faixas/`; testes em `test/features/irrigation/`.

- Calcular F14–F22 com `tr_alvo=t0+ta(L)`, iteração de `td`, VIM, `qf`, `yf`, `Sy=yf/L`, duração da recessão pela versão de expoentes da p.43 e `ti=td−y0L/(2q0)`. Aplicar a correção de entrada quando `I0<IRN` e recalcular dependências. Validar `td>ta`, `qf>0`, `ti>0`, `ti≥ta(L)` neste motor e `τ(x)≥0`; registrar condição/etapa que rejeitou o candidato.
- No ramo simulado, construir `tr(x)` linear; no ramo medido, usar os instantes de recessão efetivamente coletados e a interpolação declarada. Então calcular `τ(x)=tr(x)−ta(x)` e `I(x)`; integrar `min(I,IRN)`, `max(I−IRN,0)` e `max(IRN−I,0)` com trapézios, incluindo cruzamentos da linha IRN, e obter `Ventrada`, `Vutil`, `Vpercolado`, `Vescoado`, `Vdeficit`, Ea/Er/Pp/Pe (extração §6.5). No ramo medido, solicitar vazão e instante de corte para obter `Ventrada`; sem esses dados, exibir somente os indicadores calculáveis. Não usar a Ea simplificada F25 quando houver déficit; conferir conservação e não aplicar `clamp` para esconder balanço inconsistente.
- Expor resultado e unidades tipados: `t0`, `ta(L/2)`, `ta(L)`, `ti`, `td`, `tr`, `y0`, `r`, `σz`, `qf`, perfis, volumes unitários e totais, avisos/status, resíduos e versão de equações. Indicadores CUC/DU, se exibidos, devem ser identificados como adicionais calculados sobre o perfil, não substitutos de Ea/Er.

**Aceite:** caso reconstruído da extração §8.4 com L=400 m, q0=0,20 m³/min/m e cenários separados reproduz tempos/Ea dentro da tolerância numérica explicitada; `Ea+Pp+Pe≈100%` e volumes fecham o balanço. Casos de déficit, `qf≤0`, `td≤ta`, `τ<0` ou corte antes do fim do avanço não produzem “dimensionamento aprovado”.

## Etapa 4 — Geometria, alternativas de vazão e instrumentos

**Alterar/criar:** serviços de dimensionamento em `lib/services/simulation/faixas/`, estado de comparação em `lib/viewmodels/faixas/` e cartões de recomendação no projeto e resultados.

- Calcular `D=|St|W`, `Dmax=0,4hn` e `Wmax` somente com `hn` **superficial** conhecido; quando St=0, informar “sem restrição por este critério”, nunca W infinito. Verificar `y0≤alturaDique` apenas se a **altura real** foi informada; bases ilustrativas da p.23 não são alturas. Sem `hn` ou altura, informar pendência, não “aprovado” (extração §§2.2, 3.1).
- Explorar `L` submúltiplo do comprimento da área e grade declarada de `q0` (passo identificado em L/s/m, p.ex. 0,05 L/s/m). Para cada candidato refazer etapas 2–3; verificar F03, F04, disponibilidade `Qfaixa=q0W`, geometria e balanceamento. Informar Hart literal como referência condicionada, sem usá-lo como bloqueio erosivo confirmado; mostrar melhor **entre os candidatos viáveis testados** pelo critério de Ea e listar rejeições/alertas; sem promessa de ótimo contínuo nem adoção automática de valor empírico ambíguo (extração §6.6).
- Incorporar Marr como consulta orientativa por textura/declive com duas linhas em limites compartilhados. Incorporar Booher como consulta tabulada com valor impresso, proposta não confirmada e estado; bloquear dimensionamento automático nas três células suspeitas. Recomendar sulcos transversais e alertar declive >3% sem dizer que foram hidraulicamente modelados.

**Aceite:** `hn=0,10 m`, `St=0,5%` → `Dmax=0,04 m`, `Wmax=8 m`; `St=0` não divide por zero; 0,05 L/s/m equivale a 0,003 m³/min/m. A interface informa unidade e motivo de exclusão de cada alternativa e nunca usa as células 1,03/505,5/993,1 como sugestão automática.

## Etapa 5 — Parcelas e disponibilidade operacional

**Alterar/criar:** planejamento próprio em `lib/services/simulation/faixas/` (reaproveitar `lib/services/simulation/operational_planning.dart` somente para funções de fato comuns), contratos em `lib/models/faixas/`, estado em `lib/viewmodels/faixas/` e etapas Operação e Revisão do projeto.

- Solicitar `Lt`, `Wt`, período PI em dias, jornada TDF em horas/dia, mudança `tmu` em min, número simultâneo NFP, vazão disponível e **janela real de fornecimento**. Derivar TIP, quociente bruto NPD, parcelas completas/dia, APP, W0, NTF e Qt conforme F27–F32; enumerar contagens inteiras e verificar submúltiplos de Lt/Wt e lote final parcial.
- Comparar capacidade da jornada e do fornecimento com área atendida e simultaneidade; “água disponível a cada sete dias” não define horas diárias nem cronograma executável. Separar tempo de corte `ti` de tempo de mudança e de PI; não forçar uma parcela diária se `TIP>TDF`.

**Aceite:** para W=10 m, L=400 m, q0=0,20 m³/min/m → 33,333 L/s por faixa; 12 simultâneas → 400 L/s, 40 faixas em 400×400 m, com lote final de 4 no agrupamento de 12. Sem TDF/tmu/janela, o resultado permanece “cronograma pendente” (extração §8.4).

## Etapa 6 — Interface visual, persistência e entrega integrada

**Alterar/criar:** `project_screen.dart`/tela de faixa, `project_results_screen.dart`/visão de resultado de faixa, widgets de `lib/views/irrigation/widgets/`, `lib/app/theme/app_icons.dart` somente se faltar ícone semântico, contratos em `lib/models/faixas/`, adaptadores `lib/models/cenario_salvo.dart` e `lib/models/simulation_result_model.dart`, CSV das telas e testes de integração.

- Reaproveitar a linguagem visual do projeto: cards e progressão em etapas do fluxo de sulcos, `Theme.of(context).colorScheme`/`textTheme`, `AppIcons.faixa`, `AppTheme` claro/escuro/alto contraste e componentes de `lib/core/widgets/`. Não clonar `TerrainView` de sulcos com rótulo trocado: representar diques paralelos, canal/entrada, faixa W×L, sentido do avanço e saída quando houver dados; caso contrário omitir o esquema.
- Organizar a leitura em **dados e hipóteses → avanço e recessão → perfil e balanço → alternativas e operação → auditoria**. Gráfico compartilhado de avanço pode ser reutilizado; adicionar recessão no mesmo eixo somente com instantes efetivos, perfil `I(x)` com IRN e regiões de déficit/percolação, volumes e comparação de cenários. Substituir no contexto de faixas os rótulos/fórmulas de sulcos em `ProjectResultsScreen` (inclusive `Ea=Lf/Lm`, segurança com limites fixos e “sulcos” no desenho) pelos indicadores e ressalvas do modelo de faixas.
- Mostrar carregamento, vazio, entrada pendente, aviso orientativo, fora de domínio, falha numérica e balanço inconsistente com **texto + ícone**, não apenas cor. Rótulos/unidades visíveis nos eixos, texto escalável e negrito do tema, alto contraste, toque ≥48×48 e animações respeitando a preferência de redução. Sem `0` como substituto de resultado ausente. Inspecionar mobile e telas largas.
- Salvar/recuperar/exportar hipóteses, origem da IRN e infiltração, cenário, unidade original, versão do modelo, status, medições (se houver), perfil e razões de rejeição; ler cenários antigos sem aplicar novos defaults como se fossem medições. Usar `ResultsController`/serviço de cenários existentes.

**Aceite:** resultados de faixa não exibem fórmulas ou ilustrações de sulcos, unidade da vazão aparece consistentemente como L/s/m e L/s conforme o campo, avisos são compreensíveis por leitor de tela e em alto contraste; salvar, restaurar e exportar preserva exatamente o tipo/versão de modelo e as entradas usadas.

## Sequência de verificação e limites da entrega

1. **Etapa 0, primeiro:** migrar imports e separar código por método sem mudar cálculos; confirmar navegação, persistência e regressão dos três métodos antes de começar a Etapa 1.
2. **Etapa 1:** confirmar navegação, campos tipados, restauração legada e impedimento de tipos ainda não suportados.
3. **Etapas 2–3:** validar separadamente raízes, avanço, recessão e balanço com os casos da extração §§8.3–8.5; testar condições de falha, tolerância e conservação, não apenas repetir as fórmulas na asserção.
4. **Etapas 4–5:** testar fronteiras de tabela, critérios orientativos, alternativas rejeitadas, contagens inteiras e lote parcial.
5. **Etapa 6:** testar widgets de navegação, rótulos, estado pendente e acessibilidade; round-trip de persistência/CSV e regressão de sulco e inundação. Ao concluir cada etapa com código Dart alterado, executar `flutter analyze` e `flutter test`.
6. **Conferência de fonte:** examinar as duas planilhas de faixas existentes em `docs/materiais_origem/` e comparar fórmulas, unidades e resultados com a extração antes de promover qualquer célula a gabarito; documentar divergências e revisões no próprio material técnico.

O marco de conclusão é o percurso completo **de faixa aberta em declive com vazão constante**, que calcula e explica seus resultados sem extrapolar o domínio da aula. Outros regimes só entram em marcos posteriores mediante metodologia própria e critérios de aceite novos.
