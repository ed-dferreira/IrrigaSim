# ADR-0005: Estrutura modular do projeto

## Status

Aceito

## Contexto

O projeto KMP requer organização clara entre código compartilhado e específico de plataforma.

## Decisão

Estrutura modular hierárquica:

```
IrrigaSIM/
├── shared/                  # Módulo KMP compartilhado
│   ├── domain/               # Modelos de simulação
│   ├── data/                 # Persistência e sincronização
│   ├── auth/                  # Autenticação
│   └── usecase/               # Casos de uso
├── androidApp/                # Entry point Android
├── iosApp/                    # Entry point iOS
└── docs/                       # Documentação
```

## Módulos do shared/domain

- `Simulacao.kt` — Orquestração do cálculo
- `Kostiakov.kt` — Equação de infiltração
- `BalancoDeVolume.kt` — Modelo hidráulico
- `Parametros.kt` — Dados de entrada
- `Resultado.kt` — Dados de saída
- `MetodoIrrigacao.kt` — Enum: sulco, faixa, bacia

## Módulos do shared/data

- `CenarioRepository.kt` — CRUD de cenários
- `FirestoreSync.kt` — Sincronização com Firebase
- `LocalStore.kt` — Persistência offline

## Módulos do shared/auth

- `AuthRepository.kt` — Gerenciamento de autenticação
- `UserSession.kt` — Sessão do usuário

## Módulos do shared/usecase

- `SimularUseCase.kt` — Executa simulação
- `SalvarCenarioUseCase.kt` — Persiste cenário
- `CompararCenariosUseCase.kt` — Compara cenários
- `ListarAulasUseCase.kt` — Lista cenários de aula

## Consequências

**Positivas:**
- Separação clara de responsabilidades
- Facilita testes unitários (domain puro)
- Reutilização entre Android e iOS
- Manutenção organizada

**Negativas:**
- Mais arquivos para gerenciar
- Curva de aprendizado para novos contribuidores
- Complexidade inicial maior
