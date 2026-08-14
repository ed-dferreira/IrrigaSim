# IrrigaSIM — Arquitetura Completa do Sistema

## Visão Geral

O IrrigaSIM é um aplicativo mobile multiplataforma para simulação didática de irrigação por superfície, voltado ao ensino de Agronomia e Engenharia Agrícola.

## Fluxo de Telas (baseado no Figma Prototype)

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUXO PRINCIPAL                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐               │
│  │  Login   │───▶│ Cadastro │    │          │               │
│  └────┬─────┘    └────┬─────┘    │          │               │
│       │               │          │          │               │
│       ▼               ▼          │          │               │
│  ┌──────────┐    ┌──────────┐    │          │               │
│  │ Método   │◀───│          │    │          │               │
│  │ (Home)   │    │          │    │          │               │
│  └────┬─────┘    │          │    │          │               │
│       │          │          │    │          │               │
│       ▼          │          │    │          │               │
│  ┌──────────┐    │          │    │          │               │
│  │Parâmetros│    │          │    │          │               │
│  └────┬─────┘    │          │    │          │               │
│       │          │          │    │          │               │
│       ▼          │          │    │          │               │
│  ┌──────────┐    │          │    │          │               │
│  │Resultados│───▶│ Cenários │    │          │               │
│  └──────────┘    │          │    │          │               │
│                  └────┬─────┘    │          │               │
│                       │          │          │               │
│                       ▼          │          │               │
│                  ┌──────────┐    │          │               │
│                  │Comparação│    │          │               │
│                  └──────────┘    │          │               │
│                                  │          │               │
│  ┌──────────┐                   │          │               │
│  │ Modo Aula│──────────────────▶│          │               │
│  └──────────┘                   │          │               │
│                                  │          │               │
│  ┌──────────┐                   │          │               │
│  │ Perfil   │                   │          │               │
│  │(A11y)    │                   │          │               │
│  └──────────┘                   │          │               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Navegação (Bottom Nav)

```
┌─────────────────────────────────────────────────┐
│  Início  │  Cenários  │  Aulas  │  Perfil      │
│  (Home)  │            │         │  (A11y)      │
└─────────────────────────────────────────────────┘
```

## Telas do Prototype Figma

### 1. Login (TelaLogin)
- E-mail institucional + Senha
- Botão "Entrar"
- Link "Esqueci minha senha"
- Botão "Criar conta"
- Crédito: "Projeto de pesquisa — UFLA/DEG · 2026"

### 2. Cadastro (TelaCadastro)
- Nome completo
- E-mail
- Instituição (ex.: UFLA, UFV, ESALQ)
- Curso (Agronomia / Eng. Agrícola)
- Senha + Confirmação
- Termos de uso + LGPD
- Botão "Criar conta"

### 3. Método / Home (TelaMetodo)
- Saudação com nome do usuário
- Resumo: "3 simulações realizadas"
- Seleção de método:
  - Sulco (furrow)
  - Faixa (border)
  - Bacia / Inundação (basin)

### 4. Parâmetros (TelaParametros)
- **Geometria**: Comprimento (m), Declividade (%), Largura/Espaçamento (m)
- **Solo — Kostiakov**: Coef. k (mm/hᵃ), Exp. a
- **Manejo**: Vazão (L/s), Tempo de aplicação (min), Lâmina requerida (mm)
- Botão "Simular →"

### 5. Resultados (TelaResultados)
- **KPIs**: Eficiência Ea (%), Uniformidade CU (%), Lâmina média (mm), Tempo de avanço (min)
- **Balanço hídrico**: Aproveitado, Percolação, Escoamento
- **Gráficos** (abas):
  - Avanço × Tempo
  - Lâmina Longitudinal
- **Recomendação**: Eficiência satisfatória / Otimização recomendada
- Botão "Salvar"

### 6. Cenários Salvos (TelaCenarios)
- Lista de cenários com checkbox
- Seleção de até 2 para comparação
- **Comparação lado a lado**: Ea, CU, Lâmina média

### 7. Modo Aula (TelaAula)
- 4 cenários pré-configurados:
  1. Aula 1 — Infiltração Básica (Introdutório)
  2. Aula 2 — Avanço da Lâmina (Intermediário)
  3. Aula 3 — Eficiência de Aplicação (Intermediário)
  4. Aula 4 — Perdas por Percolação (Avançado)
- Cada aula expande para descrição + botão "Iniciar esta aula"

### 8. Perfil + Acessibilidade (TelaPerfil)
- Dados do usuário (nome, e-mail, instituição, curso)
- **Configurações de Acessibilidade**:
  - Tamanho do texto: Normal / Grande / Extra grande
  - Alto contraste
  - Texto em negrito
  - Espaçamento de texto
  - Reduzir animações
  - Modo leitor de tela
- **Sobre o app**: Versão, Instituição, Disciplina, Modelo
- Botão "Sair da conta"

## Arquitetura Técnica (KMP)

```
┌─────────────────────────────────────────────────────────────┐
│                      Camada de Apresentação                  │
├─────────────────────────────────────────────────────────────┤
│  Compose Multiplatform (UI compartilhada)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Android App │  │  iOS App    │  │  (Desktop)  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      shared/ (KMP)                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    domain/                           │   │
│  │  • Simulacao.kt                                     │   │
│  │  • Kostiakov.kt                                     │   │
│  │  • BalancoDeVolume.kt                               │   │
│  │  • Parametros.kt                                    │   │
│  │  • Resultado.kt                                     │   │
│  │  • MetodoIrrigacao.kt                               │   │
│  │  • Cenario.kt                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   usecase/                           │   │
│  │  • SimularUseCase.kt                                │   │
│  │  • SalvarCenarioUseCase.kt                          │   │
│  │  • CompararCenariosUseCase.kt                       │   │
│  │  • ListarAulasUseCase.kt                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    data/                             │   │
│  │  • CenarioRepository.kt                             │   │
│  │  • FirestoreSync.kt                                 │   │
│  │  • LocalStore.kt                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    auth/                             │   │
│  │  • AuthRepository.kt                                │   │
│  │  • UserSession.kt                                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Camada de Serviços                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │Firebase Auth    │  │ Firestore       │                   │
│  │(Autenticação)   │  │ (Sincronização) │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## Modelo de Dados (Firestore)

```
users/{userId}
├── nome: string
├── email: string
├── instituicao: string
├── curso: string
├── criadoEm: timestamp
├── a11yConfig: {
│   ├── tamanhoFonte: "normal" | "grande" | "extragrande"
│   ├── altoContraste: boolean
│   ├── negrito: boolean
│   ├── espacamentoTexto: boolean
│   ├── reducaoMovimento: boolean
│   └── leitorTela: boolean
│   }
└── cenarios/{cenarioId}
    ├── nome: string
    ├── metodo: "sulco" | "faixa" | "bacia"
    ├── criadoEm: timestamp
    ├── parametros: {
    │   ├── comprimento: number
    │   ├── declividade: number
    │   ├── largura: number
    │   ├── k: number
    │   ├── a: number
    │   ├── vazao: number
    │   ├── tempoAplicacao: number
    │   └── laminaRequerida: number
    │   }
    └── resultado: {
        ├── eficiencia: number
        ├── uniformidade: number
        ├── laminaMedia: number
        ├── tempoAvanco: number
        ├── perdaPercolacao: number
        ├── perdaEscoamento: number
        └── dadosGraficos: {...}
        }

lessons/{aulaId}  ← (read-only, pré-configurado)
├── titulo: string
├── descricao: string
├── metodo: string
├── dificuldade: "Introdutório" | "Intermediário" | "Avançado"
└── parametros: {...}
```

## Requisitos Não-Funcionais

| Requisito | Implementação |
|-----------|---------------|
| Offline first | Firestore persistência local + sync automático |
| Conta obrigatória | Firebase Auth (e-mail/senha) |
| Acessibilidade | Configurações no perfil (fonte, contraste, animações) |
| Idioma único | Português (Brasil), sem i18n |
| Baixo consumo | Cálculos leves, sem GPU |
| Multiplataforma | KMP + Compose Multiplatform |

## Decisões Técnicas (ADRs)

- [ADR-0001](adr/0001-kotlin-multiplatform.md): Kotlin Multiplatform
- [ADR-0002](adr/0002-firebase-backend.md): Firebase Backend
- [ADR-0003](adr/0003-vico-charts.md): Vico para Gráficos
- [ADR-0004](adr/0004-modelo-matematico.md): Modelo Matemático
- [ADR-0005](adr/0005-estrutura-modular.md): Estrutura Modular
