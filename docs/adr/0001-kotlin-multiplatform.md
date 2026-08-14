# ADR-0001: Kotlin Multiplatform para lógica compartilhada

## Status

Aceito

## Contexto

O IrrigaSIM precisa rodar em Android e iOS com lógica de simulação idêntica. A equipe é reduzida (projeto de pesquisa) e o orçamento limitado.

## Decisão

Usar **Kotlin Multiplatform (KMP)** com **Compose Multiplatform** para compartilhar:
- Lógica de simulação (Kostiakov + balanço de volume)
- Modelos de dados
- Casos de uso
- Interface de usuário

## Consequências

**Positivas:**
- Código compartilhado entre Android e iOS (~80-90%)
- Compose Multiplatform para UI nativa em ambas as plataformas
- Ecossistema Kotlin maduro (serialization, coroutines)
- Manutenção única da lógica de negócio

**Negativas:**
- Curva de aprendizado se a equipe não conhec KMP
- Dependência do estado atual doCompose Multiplatform (ainda em evolução)
- Debugging cross-platform pode ser mais complexo
- Tamanho do binário iOS pode ser maior que Swift nativo

## Alternativas Consideradas

1. **Flutter**: Dart é linguagem nova,生态 menor que Kotlin
2. **React Native**: Performance inferior para cálculos numéricos
3. **Código nativo separado**: Duplicação de lógica, manutenção dupla
