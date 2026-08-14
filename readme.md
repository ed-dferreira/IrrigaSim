# IrrigaSIM
### Ferramenta inovadora para simulação de sistemas de irrigação por superfície aplicada ao ensino de irrigação e drenagem agrícola

**Especificação técnica / README do projeto**
Versão 1.0 — Julho de 2026

---

## 1. Visão geral

O **IrrigaSIM** é um aplicativo móvel multiplataforma (Android e iOS) desenvolvido em **Kotlin Multiplatform (KMP)**, com interface **em português (Brasil)**, voltado à simulação didática de sistemas de **irrigação por superfície** (sulco, faixa/border e bacia/inundação). É desenvolvido no âmbito de um **projeto de pesquisa**, com o objetivo de oferecer a estudantes e professores de cursos de Agronomia, Engenharia Agrícola e áreas correlatas uma ferramenta interativa para visualizar, calcular e compreender os fenômenos hidráulicos envolvidos na irrigação por superfície — como avanço da lâmina d'água, infiltração no solo, recessão, eficiência de aplicação e uniformidade de distribuição — sem depender de planilhas complexas ou softwares acadêmicos de difícil acesso e interface pouco amigável. Por se tratar de projeto de pesquisa, o app conta com **sistema de contas de usuário e sincronização em nuvem**, permitindo o acompanhamento do uso da ferramenta e a coleta de dados para fins de avaliação pedagógica e científica do instrumento.

## 2. Justificativa e motivação pedagógica

A irrigação por superfície é um dos métodos mais utilizados no mundo, especialmente em regiões com agricultura familiar e baixo investimento tecnológico. No entanto, seu dimensionamento envolve conceitos hidráulicos e de física do solo (infiltração, escoamento em lâmina livre, geometria do sulco/faixa) que costumam ser abstratos para estudantes em formação. Ferramentas de referência como **SIRMOD** e **WinSRFR** são amplamente usadas na pesquisa e no ensino superior, mas:

- Rodam apenas em desktop (Windows), limitando o uso em sala de aula ou em campo;
- Possuem interfaces voltadas a pesquisadores, não a iniciantes;
- Não são gratuitas ou de fácil acesso em todos os contextos institucionais.

O IrrigaSIM propõe preencher essa lacuna com uma ferramenta **mobile, gratuita, de interface simplificada e propósito explicitamente didático**, permitindo que o aluno simule cenários, altere parâmetros e visualize o comportamento do sistema em tempo real, inclusive em campo, durante aulas práticas.

## 3. Público-alvo

- Estudantes de graduação em Agronomia, Engenharia Agrícola e Zootecnia;
- Estudantes de cursos técnicos em agropecuária;
- Professores de disciplinas de Irrigação e Drenagem, como apoio didático em sala de aula;
- Produtores rurais e técnicos de extensão interessados em noções básicas de dimensionamento (uso secundário).

## 4. Métodos de irrigação contemplados

O app permitirá a simulação dos três principais métodos de irrigação por superfície, selecionáveis pelo usuário:

1. **Irrigação por sulcos** (furrow irrigation)
2. **Irrigação por faixas** (border irrigation)
3. **Irrigação por bacias/inundação** (basin irrigation)

## 5. Modelo matemático da simulação

Após avaliação de diferentes níveis de complexidade, optou-se por um **modelo intermediário**, que equilibra rigor científico e viabilidade computacional em ambiente mobile:

- **Infiltração:** equação empírica de **Kostiakov** (ou Kostiakov-Lewis modificada), amplamente validada na literatura de irrigação por superfície;
- **Hidráulica do avanço/recessão:** modelo de **balanço de volume** (volume balance model), que representa a fase de avanço, armazenamento e recessão da lâmina d'água ao longo do sulco/faixa/bacia sem exigir a solução numérica completa das equações de Saint-Venant;
- Essa abordagem é consistente com a adotada por softwares de referência como SIRMOD e WinSRFR, garantindo validade pedagógica e cientificamente defensável, com custo computacional compatível com dispositivos móveis.

### 5.1 Parâmetros de entrada (inputs)

| Categoria | Parâmetros |
|---|---|
| Geometria | Comprimento do sulco/faixa/bacia, declividade, espaçamento, largura |
| Solo | Coeficientes de infiltração de Kostiakov (k, a), infiltração básica |
| Manejo | Vazão de entrada, tempo de aplicação, lâmina requerida |
| Cultura | Lâmina líquida necessária, profundidade radicular (opcional) |

### 5.2 Parâmetros de saída (outputs)

- Tempo de avanço e recessão da lâmina d'água
- Lâmina infiltrada ao longo do comprimento
- Eficiência de aplicação (Ea)
- Uniformidade de distribuição (UD / CUC)
- Perdas por percolação profunda e escoamento superficial (runoff)
- Gráfico de avanço da frente de água ao longo do tempo/espaço

## 6. Arquitetura técnica

### 6.1 Stack tecnológica

- **Kotlin Multiplatform (KMP)** — compartilhamento de lógica de negócio e modelo de simulação entre Android e iOS
- **Compose Multiplatform** — interface de usuário nativa compartilhada (Android + iOS)
- **Kotlinx.serialization** — persistência de cenários/configurações do usuário
- **Kotlinx.coroutines** — processamento assíncrono dos cálculos de simulação
- Módulo de gráficos: **Vico** — biblioteca de charts para Compose Multiplatform, com suporte nativo Android/iOS e sem dependências pesadas
- **Backend de autenticação e sincronização em nuvem: Firebase (Auth + Firestore)** — possui SDK oficial para Kotlin Multiplatform, plano gratuito adequado ao orçamento de um projeto de pesquisa e dispensa manutenção de servidor próprio

### 6.2 Estrutura modular sugerida

```
IrrigaSIM/
├── shared/                  # Módulo KMP compartilhado
│   ├── domain/               # Modelos de simulação (Kostiakov, balanço de volume)
│   ├── data/                 # Persistência local e sincronização via Firebase Firestore
│   ├── auth/                  # Autenticação via Firebase Auth
│   └── usecase/               # Casos de uso (simular, comparar cenários, exportar)
├── androidApp/                # Camada Android (entry point, integrações específicas)
├── iosApp/                    # Camada iOS (entry point, integrações específicas)
└── docs/                       # Documentação pedagógica e técnica
```

### 6.3 Requisitos não funcionais

- Funcionamento **offline** para a simulação em si (cálculos não dependem de internet)
- **Conta de usuário obrigatória**, com autenticação (e-mail/senha e, opcionalmente, login social) e sincronização em nuvem dos cenários salvos entre dispositivos — requisito relevante para um projeto de pesquisa, pois viabiliza coleta de dados de uso, acompanhamento de participantes (ex. alunos de turma piloto) e persistência de resultados entre sessões
- Interface responsiva, adequada a uso em sala de aula e em campo
- Baixo consumo de bateria e processamento (cálculos leves, sem necessidade de GPU)
- Acessibilidade: suporte a diferentes tamanhos de tela e leitura por voz (a avaliar)
- **Idioma único: português (Brasil)** — sem necessidade de internacionalização (i18n) nesta fase

## 7. Funcionalidades principais (MVP)

1. Criação de conta e login do usuário, com sincronização de dados em nuvem
2. Seleção do método de irrigação (sulco, faixa ou bacia)
3. Formulário de entrada de parâmetros de solo, geometria e manejo
4. Execução da simulação e exibição de resultados numéricos
5. Visualização gráfica do avanço da lâmina d'água ao longo do tempo
6. Cálculo automático de eficiência de aplicação e uniformidade
7. Salvamento de cenários (associados à conta do usuário) para comparação posterior
8. Modo "aula" com cenários pré-configurados para uso didático guiado

## 8. Funcionalidades futuras (roadmap pós-MVP)

- Exportação de relatórios em PDF para entrega de atividades
- Comparação lado a lado de múltiplos cenários
- Banco de dados de solos e culturas de referência (offline)
- Modo colaborativo/professor (compartilhamento de cenários com a turma)
- Animação em tempo real do avanço da lâmina (visualização 2D do perfil do sulco/faixa)

## 9. Validação e avaliação pedagógica

A validação do IrrigaSIM será conduzida em duas etapas:

1. **Validação numérica:** comparação dos resultados do IrrigaSIM (tempo de avanço/recessão, lâmina infiltrada, eficiência, uniformidade) com os do **WinSRFR** (software gratuito mantido pelo USDA-ARS, escolhido por ser de acesso livre e referência consolidada na literatura de irrigação por superfície), utilizando os mesmos cenários de entrada. Divergências devem ser documentadas e justificadas tecnicamente.
2. **Validação pedagógica:** aplicação do aplicativo em turma piloto da disciplina de Irrigação e Drenagem, com aplicação de questionário pré/pós-teste para avaliar ganho de aprendizagem e escala de usabilidade (ex. System Usability Scale — SUS) para avaliar a experiência do usuário.

### 9.1 Cronograma-modelo (a adaptar ao edital/programa específico)

| Fase | Atividades | Duração estimada |
|---|---|---|
| 1. Fundamentação e modelagem | Revisão de literatura, definição final dos modelos matemáticos (Kostiakov + balanço de volume) | 1–2 meses |
| 2. Desenvolvimento do MVP | Implementação em KMP: módulo de simulação, interface, autenticação/Firebase | 3–4 meses |
| 3. Validação numérica | Comparação com WinSRFR, ajustes no modelo | 1 mês |
| 4. Validação pedagógica | Aplicação em turma piloto, coleta de questionários pré/pós-teste e SUS | 1–2 meses |
| 5. Análise de dados e redação | Análise estatística dos resultados, redação de relatório/artigo final | 1–2 meses |

*Cronograma ilustrativo, independente de instituição — deve ser ajustado ao calendário letivo e às exigências específicas do edital, programa de pós-graduação ou orientação ao qual o projeto estiver vinculado.*

### 9.2 Ética e tratamento de dados (LGPD)

- Aplicação de **Termo de Consentimento Livre e Esclarecido (TCLE)** no primeiro acesso ao aplicativo, informando finalidade de pesquisa, coleta de dados de uso e direitos do participante;
- **Minimização de dados:** coleta restrita ao necessário para fins de pesquisa (uso da ferramenta, cenários simulados, respostas a questionários), sem dados sensíveis;
- **Anonimização/pseudonimização** dos dados de uso antes de qualquer análise ou publicação de resultados;
- Submissão do projeto a **Comitê de Ética em Pesquisa (CEP)**, conforme exigido para pesquisas com seres humanos no Brasil.

## 10. Decisões técnicas registradas

As lacunas anteriores foram resolvidas com as seguintes decisões:

| Ponto | Decisão |
|---|---|
| Biblioteca de gráficos | Vico (Compose Multiplatform) |
| Backend de autenticação/nuvem | Firebase (Auth + Firestore) |
| Referência de validação numérica | WinSRFR (USDA-ARS, gratuito) |
| Tratamento de dados | TCLE, minimização, anonimização, submissão ao CEP |
| Cronograma | Modelo em 5 fases (ver seção 9.1), a vincular ao calendário da instituição/edital real |

**Ainda pendente (depende de informação que só a instituição/orientação pode fornecer):**
- Nome da instituição, curso/programa e edital de fomento associados ao projeto, para vinculação formal do cronograma da seção 9.1 às datas reais.

---

*Documento gerado como especificação inicial. Ajustável conforme definições institucionais e evolução do desenvolvimento.*
