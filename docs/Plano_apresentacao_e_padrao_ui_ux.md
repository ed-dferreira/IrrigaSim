# Plano por etapas — apresentação de sulcos e faixas e padrão de UI/UX

## Objetivo

Revisar a apresentação de resultados de **sulcos e faixas** para que ambos priorizem as informações necessárias à decisão e mantenham detalhes técnicos acessíveis sem sobrecarregar a leitura. O design de sulcos é a referência visual e de interação a ser consolidada e aplicada às duas experiências.

Este plano trata da **camada de apresentação**. Os backends de cálculo são considerados disponíveis; qualquer divergência encontrada entre os resultados calculados e o que a interface consegue exibir deve ser registrada como lacuna de integração, sem alterar a matemática silenciosamente.

## Princípios de produto

1. **Decisão antes de auditoria:** status, desempenho, perdas e ação recomendada aparecem antes de parâmetros numéricos internos.
2. **Uma fonte de verdade por conceito:** evitar repetir o mesmo indicador em cartões, linhas e mensagens sem acrescentar interpretação.
3. **Dado ausente não é zero:** distinguir valor calculado, não informado, não aplicável e cálculo bloqueado.
4. **Gráfico acompanhado de interpretação:** título, unidades, legenda e resumo acessível devem comunicar a mesma informação.
5. **Progressive disclosure:** fórmulas e detalhes de solver continuam disponíveis, mas recolhidos ou em área de auditoria.
6. **Sulcos como padrão visual e de navegação:** reutilizar hierarquia, espaçamento, cartões, etapas, estados e componentes já estabelecidos na experiência de sulcos; o conteúdo e os termos específicos de faixas permanecem próprios do método.
7. **Não ocultar ressalvas do modelo:** bloqueios, hipóteses e limites de validade devem estar visíveis junto ao resultado afetado.

## Etapa 0 — Inventário e contrato de apresentação para os dois métodos

**Objetivo:** definir a relação entre os resultados do backend e as informações que a interface apresenta.

**Atividades**

- Mapear campos de entrada, resultados, status, avisos e indicadores usados nos modelos de sulcos (`SimulationResult` e modelos específicos do projeto) e de faixas (`BorderResult`, `BorderProject` e `SimulationResult`).
- Registrar diferenças de significado entre métricas com nomes parecidos; não presumir que Ea, perdas ou tempos tenham definição idêntica nos dois métodos.
- Classificar cada item como: essencial para decisão, explicativo, auditoria, exportação ou não apresentar.
- Para cada item visível, registrar unidade, regra de arredondamento, condição de exibição e mensagem quando indisponível.
- Conferir que percentuais, volumes totais e volumes por metro de largura não sejam confundidos.
- Identificar indicadores repetidos entre resumo, cartões e seções detalhadas.

**Entregável:** tabela de contrato de apresentação por método, revisada com domínio/engenharia antes das mudanças de tela.

**Critério de conclusão:** todo campo atualmente apresentado tem classificação e regra explícitas; nenhuma alteração exige inferir ou recalcular um resultado no widget.

### Contrato inicial levantado no código

Esta tabela registra os dados já disponíveis nos modelos. Valores nulos devem ser exibidos como indisponíveis com o motivo correspondente; não converter para zero. Arredondamento abaixo é apenas de apresentação e não modifica o valor exportado.

| Método/campo | Classe | Unidade / apresentação | Regra de exibição e indisponibilidade |
|---|---|---|---|
| Faixas: `status`, `avisos` | Essencial/ressalva | Código canônico + texto humano | Sempre; status bloqueante deve anteceder KPIs como ressalva de uso. |
| Faixas: `ea`, `er`, `pp`, `pe` | Essencial | %; 2 casas na tela | KPI quando hidráulica calculada; não confundir eficiência de aplicação com requerimento. |
| Faixas: `taFinalMin` | Essencial | min; 2 casas | KPI quando calculado; nulo = não calculado. |
| Faixas: `volumeUtilM3M`, `comprimentoAdequadoM` | Essencial | m³/m de largura e m | Não rotular volume por metro de largura como volume total; distinguir comprimento adequado de contínuo. |
| Faixas: operação/cronograma | Essencial condicional | min, grupos/dia, L/s | Mostrar resultado quando cronograma completo; caso contrário informar “Cronograma pendente”. |
| Faixas: geometria, vazões, declividade, IRN, infiltração | Explicativo | m, L/s/m, L/s, %, mm | Mostrar entradas e origem/hipótese; entrada ausente = “Não informado”. |
| Faixas: perfil amostrado | Explicativo/exportação | m, min, mm | Resumo recolhido; CSV preserva os dados. |
| Faixas: resíduos, tolerâncias, iterações, segmentos, proveniência e fórmulas | Auditoria/exportação | Unidades declaradas no rótulo | Recolhidos; manter acessíveis e exportados. |
| Sulcos: Ea simplificada (`eficiencia`) e Ea integral (`balancoSulco.eaIntegral`) | Essencial | % | Identificar explicitamente a definição; Ea integral indisponível não deve ser substituída silenciosamente pela simplificada. |
| Sulcos: CUC, DU, adequação útil e lâmina infiltrada | Essencial quando calculados | %, mm | `balancoSulco`/campos opcionais definem disponibilidade; não apresentar zeros artificiais. |
| Sulcos: percolação, escoamento e déficit | Essencial | % para perdas e unidade/volume identificado para balanço | Não somar déficit de demanda como perda do balanço aplicado; esclarecer hipótese de manejo do escoamento. |
| Sulcos: tempos, curvas e alertas de extrapolação/infiltração | Essencial/explicativo | min, m, mm | Manter alerta junto ao resultado afetado; mostrar tempo de oportunidade/fornecimento só quando calculado. |
| Sulcos: solver, regressão, medições brutas e fórmulas completas | Auditoria/exportação | Unidade própria | Recolhidos; exportação e rastreabilidade preservadas. |

**Lacunas de integração:** `SimulationResult` usa campos numéricos obrigatórios não anuláveis para alguns indicadores de sulcos e não carrega uma disponibilidade por métrica; portanto, a camada de apresentação não consegue distinguir com segurança zero calculado de não calculado apenas por esses campos. Os resultados de faixas têm `BorderStatus` e métricas tipadas, mas parte da operação ainda é derivada na tela via `BorderPlanning`. Revisar esses contratos com domínio/engenharia antes de alterar a semântica ou a matemática.

## Etapa 1 — Hierarquia das telas de resultados

**Objetivo:** consolidar o fluxo de resultados de sulcos e usá-lo como padrão de hierarquia para faixas, preservando as particularidades de cada método.

**Ordem proposta**

1. Resumo do resultado: status, principal ressalva e recomendação objetiva.
2. Gráficos e visualização da faixa.
3. Cartões de indicadores principais.
4. Resumo operacional e viabilidade, quando houver dados suficientes.
5. Entradas e hipóteses essenciais.
6. Detalhes de perfil e balanço, inicialmente recolhidos quando forem extensos.
7. Auditoria técnica, fontes e fórmulas, inicialmente recolhidas.
8. Salvar cenário e exportar dados.

**Indicadores prioritários de faixas**

- Eficiência de aplicação (Ea) e eficiência de requerimento (Er).
- Percolação (Pp) e escoamento (Pe).
- Tempo de avanço até o final.
- Lâmina útil média e comprimento adequadamente irrigado.
- Viabilidade operacional, prazo e oferta de vazão, se o cronograma estiver configurado.

Mostrar somente os indicadores calculados e aplicáveis. Um status bloqueante deve explicar por que os valores não devem ser usados como recomendação, mesmo quando a hidráulica produziu números intermediários.

**Indicadores prioritários de sulcos**

- Eficiência de aplicação, identificando explicitamente quando se trata de Ea integral ou de um indicador simplificado.
- Uniformidade (CUC e DU) e adequação útil, quando calculada.
- Lâmina média infiltrada, perdas por percolação e escoamento e eficiência de requerimento.
- Tempo de avanço e, quando aplicável, oportunidade/fornecimento e manejo de vazão reduzida.
- Alertas que mudem a interpretação, incluindo extrapolação de ensaio ou limites da curva de infiltração.

Evitar apresentar o mesmo indicador como KPI, linha de auditoria e mensagem de recomendação sem explicar a diferença. Em sulcos, deixar especialmente clara a distinção entre Ea simplificada e Ea integral, e entre escoamento previsto pelo balanço e resíduo condicionado por hipótese de manejo.

**Critério de conclusão:** em uma leitura rápida, a pessoa consegue responder “o cálculo é utilizável?”, “qual foi o desempenho?” e “o que devo revisar?”.

## Etapa 2 — Conteúdo principal e conteúdo avançado nos dois métodos

**Objetivo:** reduzir ruído sem perder rastreabilidade.

**Manter no fluxo principal**

- Status humano e código canônico quando útil para suporte.
- Geometria efetiva, vazão, declividade, IRN e cenário de infiltração.
- Tempos essenciais de avanço, corte e recessão, com rótulos compreensíveis.
- Indicadores de desempenho, perdas, déficit e operação.
- Avisos que alterem a confiança, validade ou interpretação do resultado.

**Mover para “Detalhes técnicos e auditoria” ou exportação**

- Resíduos das equações, tolerâncias, número de iterações e segmentos.
- Valores intermediários do solver, como `r`, `σz`, `qf` e histórico completo de convergência.
- Método de integração e metadados numéricos que não orientem uma ação do usuário.
- Lista extensa de fórmulas, páginas e proveniência das fontes.
- Perfil amostrado completo; manter no principal apenas uma síntese e oferecer expansão/tabela ou CSV.
- Leituras ou alternativas explicitamente não confirmadas, bloqueadas ou não utilizadas, como F02 e Hart literal. Se forem relevantes para transparência, explicar em uma seção avançada que não interferem no dimensionamento apresentado.
- Em sulcos, coeficientes e expoentes ajustados, R², equações de regressão, medições brutas por estaca e detalhes completos de ajuste; manter visível qualquer aviso de baixa cobertura ou extrapolação que afete a confiança do resultado.
- Em sulcos, catálogo completo de fórmulas e derivação dos indicadores; manter a explicação curta dos conceitos necessários para interpretar o resultado.

**Regras de indisponibilidade**

- “Não informado” para entrada ausente.
- “Não calculado” para cálculo ainda não executado ou dependência incompleta.
- “Não aplicável” quando a métrica não fizer sentido para o cenário.
- “Bloqueado” acompanhado do motivo quando o status impedir uso do resultado.
- Evitar substituir qualquer uma dessas situações por `0`, `0%` ou hífen sem explicação.

**Critério de conclusão:** os dados de auditoria continuam consultáveis e exportáveis; a primeira leitura da tela deixa de ser dominada por parâmetros internos.

## Etapa 3 — Revisão dos gráficos por método

**Objetivo:** manter gráficos que apoiem decisões e tornar seus significados claros.

| Gráfico | Uso esperado | Ação de interface |
|---|---|---|
| Avanço e recessão | Verificar tempos e evolução espacial | Preservar; mostrar legenda, unidade e síntese dos tempos finais |
| Infiltração e IRN | Localizar trechos acima/abaixo da necessidade | Preservar; destacar a referência de IRN e resumir o déficit espacial |
| Volumes | Comparar água útil, percolada e escoada | Preservar; deixar explícito que déficit de demanda não é componente do balanço da água aplicada |
| Velocidade de infiltração (VI) | Análise técnica da taxa | Manter como gráfico secundário/avançado, com unidades e premissas visíveis |
| Métricas por vazão | Comparar candidatas configuradas | Exibir apenas quando existirem alternativas; informar critério de seleção e vazões consideradas |
| Operação | Avaliar grupos programados por dia | Exibir quando o cronograma estiver completo; explicitar dias sem fornecimento e resultado de prazo/oferta |
| Convergência | Diagnóstico numérico | Mover para “Detalhes técnicos”; não ocupar posição de destaque no conjunto padrão |

**Gráficos de sulcos**

| Gráfico | Uso esperado | Ação de interface |
|---|---|---|
| Balanço hídrico | Entender lâmina requerida/aplicada e distribuição espacial | Preservar; indicar referências e destacar déficit/excesso sem misturar definições de Ea |
| Avanço | Verificar chegada da água ao longo do sulco | Preservar; incluir unidade, tempo final e ressalva quando houver extrapolação |
| Infiltração | Entender a lâmina infiltrada ao longo do perfil | Preservar; informar origem da curva e sinalizar domínio calibrado quando relevante |
| Oportunidade | Comparar tempo de oportunidade por posição | Preservar quando calculado; explicar a relação com infiltração e manejo |
| Desempenho | Comparar os indicadores de eficiência e uniformidade | Preservar; usar os mesmos nomes e valores apresentados nos KPIs |
| Perfil de lâmina | Localizar déficit, adequação e excesso ao longo do sulco | Preservar; identificar IRN e diferenciar lâmina útil de lâmina total |
| Comparação de cenários | Apoiar escolha entre cenários salvos | Mostrar quando houver cenário comparável; estado vazio deve orientar como salvar/adicionar um cenário |

Gráficos de convergência e ajustes internos de curvas devem ficar em auditoria, salvo quando um problema de convergência ou ajuste exigir alerta direto ao usuário.

**Acessibilidade e legibilidade**

- Fornecer descrição semântica textual para cada gráfico com os principais valores e conclusão.
- Não depender exclusivamente de cor para diferenciar séries; combinar cores com legenda, rótulos e texto.
- Usar unidades nos eixos e precisão proporcional à decisão; evitar casas decimais sem utilidade prática.
- Garantir estados vazios explicativos quando faltarem dados e não desenhar séries artificiais.
- Respeitar animações reduzidas, escalas de texto e contraste do tema.

**Critério de conclusão:** cada gráfico responde a uma pergunta concreta e pode ser compreendido sem depender apenas da inspeção visual das cores.

**Registro da implementação (etapa 3):** descrições semânticas dos gráficos de balanço, desempenho, cenário e infiltração agora anunciam unidades e valores relevantes; as animações dos gráficos de sulcos respeitam a preferência por animações reduzidas. O balanço hídrico não desenha mais uma fatia neutra quando não há componentes positivos e informa o estado vazio, mantendo eventual déficit de demanda separado da água aplicada. Na experiência de faixas, a convergência fica em detalhes técnicos, as abas de comparação/operação são condicionais aos dados e os volumes têm síntese acessível com unidades. Verificação automatizada feita nos testes de resultados de sulcos/faixas; inspeção visual em telas estreitas/largas e leitor de tela ainda requer validação manual.

## Etapa 4 — Consolidar sulcos como padrão de UI/UX

**Objetivo:** estabelecer os padrões observados em sulcos como referência reutilizável para faixas e demais fluxos de irrigação relacionados.

**Formalizar em componentes e convenções compartilhadas**

- Mesma largura máxima de conteúdo, margens e ritmo vertical.
- Mesmo padrão de cartão de etapa: ícone, título, orientação curta e campos agrupados por assunto.
- Mesmo comportamento responsivo, navegação de etapas, confirmação, revisão e ação principal.
- Mesmos componentes para alertas, campos calculados, indicadores, seções auditáveis e fórmulas.
- Mesmos estados de carregamento, vazio, erro e bloqueio, com texto e ícone além de cor.
- Mesma linguagem para salvar cenário, exportar e confirmar ações.

**Aplicar em faixas**

- Adaptar o formulário de etapas, confirmação e revisão para seguir o mesmo padrão de sulcos.
- Padronizar apresentação de status, resumo, cartões de indicadores, gráficos e auditoria.
- Preservar a navegação, responsividade, espaçamento, tipografia, estados e ações consistentes entre as telas.

**Limite da padronização:** não forçar campos, fórmulas ou etapas específicas de sulcos em faixas. O padrão compartilhado é de navegação, hierarquia e componentes; a semântica continua específica de cada método.

**Critério de conclusão:** alternar entre projetos de sulcos e faixas não exige reaprender os padrões de navegação e leitura, e os componentes compartilhados continuam parametrizáveis para cada método.

**Registro da implementação (etapa 4):** extraídos `IrrigationStepIndicator` e `IrrigationProjectStepCard` para uso pelos dois métodos. O indicador compartilha rolagem responsiva, setas em telas largas, estados preenchido/atual, semântica e animação reduzida; cartão compartilha ícone, título, orientação, espaçamento e contorno, mantendo o conteúdo de cada método próprio. Faixas agora também oferece “Pular para revisão” e usa os mesmos rótulos “Voltar”, “Confirmar”, “Próximo” e “Calcular projeto” usados em sulcos.

## Etapa 5 — Implementação incremental e revisão

**Sequência recomendada**

1. Consolidar o contrato de apresentação e validar nomes/unidades.
2. Reorganizar os resultados de faixas sem alterar o cálculo.
3. Recolher auditoria e reduzir duplicações.
4. Revisar gráficos, estados vazios e descrições semânticas.
5. Formalizar e, quando adequado, extrair os componentes e convenções já usados em sulcos.
6. Alinhar formulário, revisão e navegação de faixas ao padrão consolidado.
7. Aplicar o padrão validado às demais telas relacionadas, sem alterar o significado próprio de cada método.

**Verificações por etapa**

- Executar `flutter analyze` e os testes relevantes ao finalizar cada conjunto de mudanças.
- Conferir ao menos um cenário válido, um cenário com aviso, um status bloqueante e um resultado antigo restaurado.
- Conferir gráficos com e sem alternativas, cronograma completo e cronograma pendente.
- Revisar telas estreitas e largas, escala de fonte ampliada e navegação por leitor de tela.
- Comparar exportação CSV com os dados exibidos, garantindo que simplificar a tela não remova informação auditável.

**Registro da implementação (etapa 5):** primeira fatia incremental aplicada à navegação/formulário: controles compartilhados extraídos e formulários de faixa alinhados; auditoria continua acessível e recolhida onde é técnica; gráficos revisados na etapa 3. Testes automatizados de navegação e formulários em ambas as experiências executados. Conferência manual de cenários em dispositivos reais, escala de fonte/leitor de tela e comparação visual CSV ainda precisa ser feita antes de considerar concluída toda a etapa de revisão.

## Fora do escopo deste plano

- Alterar equações hidráulicas, critérios agronômicos ou status do backend.
- Tratar valores empíricos não confirmados como recomendações oficiais.
- Remover dados de auditoria ou proveniência já disponíveis.
- Unificar à força os modelos de dados de sulcos e faixas.

## Resultado esperado

Uma experiência coerente para sulcos e faixas, na qual a pessoa usuária encontre primeiro a validade do resultado, o desempenho e a próxima decisão; possa explorar os gráficos de forma acessível; e ainda tenha acesso completo à auditoria técnica quando precisar. Sulcos serve como padrão de UI/UX para os dois métodos, sem apagar as particularidades hidráulicas de cada um.
