# IrrigaSIM — Contexto do Domínio

## Glossário

### Termos de Negócio

**Método de Irrigação**
Classificação do sistema de irrigação por superfície simulado. Três valores possíveis: `sulco` (furrow), `faixa` (border), `bacia` (basin). Cada método define geometria e comportamento hidráulico distintos.

**Simulação**
Processo de cálculo que recebe parâmetros de entrada (geometria, solo, manejo) e produce resultados numéricos (eficiência, uniformidade, avanço da lâmina). É a ação central do sistema.

**Parâmetros de Entrada**
Conjunto de dados numéricos que alimenta a simulação. Organizados em três categorias:
- *Geometria*: comprimento, declividade, largura/espacamento
- *Solo (Kostiakov)*: coeficiente k, expoente a
- *Manejo*: vazão de entrada, tempo de aplicação, lâmina requerida

**Resultado da Simulação**
Saída numérica produzida pela simulação. Inclui:
- Eficiência de aplicação (Ea)
- Uniformidade de distribuição (CU/CUC)
- Lâmina média infiltrada
- Tempo de avanço
- Balanço hídrico (aproveitado, percolação, escoamento)
- Dados para gráficos (avanço × tempo, lâmina longitudinal)

**Cenário**
Registro persistente de uma simulação realizada. Contém: identificador único, nome descritivo, método de irrigação, data de criação, parâmetros de entrada e resultados. Associado a um usuário.

**Modo Aula**
Conjunto de cenários pré-configurados com parâmetros realistas, organizados por nível de dificuldade (Introdutório, Intermediário, Avançado). Destinado a uso didático guiado em sala de aula.

**Usuário**
Conta autenticada com dados pessoais (nome, e-mail, instituição, curso). Possui cenários salvos e configurações de acessibilidade.

**Acessibilidade**
Configurações de interface que adaptam a experiência ao usuário: tamanho de fonte, alto contraste, redução de animações, espaçamento de texto, modo leitor de tela, negrito.

### Termos Técnicos

**Kostiakov (Kostiakov-Lewis modificada)**
Equação empírica para modelagem de infiltração no solo: `F = k × t^a`, onde F é a lâmina infiltrada, t é o tempo, k e a são coeficientes do solo.

**Balanço de Volume (Volume Balance Model)**
Modelo hidráulico que representa avanço, armazenamento e recessão da lâmina d'água sem resolver numericamente as equações de Saint-Venant. Consistente com SIRMOD e WinSRFR.

**Eficiência de Aplicação (Ea)**
Razão entre lâmina requerida e lâmina aplicada, expressa em percentual. Indica quanto da água aplicada foi efetivamente aproveitada pela cultura.

**Uniformidade de Distribuição (CU/CUC)**
Coefficient of Uniformity — mede a uniformidade da distribuição da água ao longo do terreno. Valores ≥ 85% são considerados bons.

**Avanço da Lâmina**
Fase em que a água percorre o comprimento do sulco/faixa/bacia até atingir o ponto mais distante.

**Recessão**
Fase posterior ao corte de vazão em que a água remanescente infiltra ou escoa até o solo ficar livre de lâmina superficial.

**Percolação Profunda**
Perda de água por infiltração abaixo da zona radicular da cultura. Indesejável economicamente.

**Runoff (Escoamento Superficial)**
Perda de água que escoa para fora do terreno irrigado, sem infiltrar.

## Regras de Negócio

1. **Autenticação obrigatória**: todo acesso ao sistema requer conta de usuário autenticada
2. **Offline first**: cálculos de simulação funcionam sem conexão; sincronização occurs when online
3. **Um método por simulação**: cada cenário é associado a exatamente um método de irrigação
4. **Limitação de comparação**: máximo de 2 cenários selecionáveis para comparação lado a lado
5. **Modo aula read-only**: cenários de aula são pré-configurados e não editáveis pelo usuário
6. **Dados mínimos**: coleta de dados restrita ao necessário para fins de pesquisa (LGPD)

## Limites do Contexto

- **Idioma único**: português (Brasil) — sem i18n nesta fase
- **Plataforma**: mobile (Android + iOS) via KMP
- **Modelo matemático**: apenas Kostiakov + balanço de volume (não Saint-Venant completo)
- **Validação**: referência WinSRFR (USDA-ARS)
