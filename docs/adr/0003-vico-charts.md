# ADR-0003: Vico para gráficos

## Status

Aceito

## Contexto

O app precisa exibir gráficos de:
- Avanço da lâmina × tempo
- Lâmina infiltrada × distância

A solução deve funcionar em Android e iOS via Compose Multiplatform.

## Decisão

Usar **Vico** como biblioteca de gráficos para Compose Multiplatform.

## Consequências

**Positivas:**
- Compatível nativamente com Compose Multiplatform
- Suporte a Android e iOS
- Sem dependências externas pesadas
- Interface declarativa (estilo Compose)
- Boa documentação e comunidade ativa

**Negativas:**
- Biblioteca relativamente nova (pode ter bugs)
- Menos opções de customização que bibliotecas maduras
- Dependência de manutenção contínua da comunidade

## Alternativas Consideradas

1. **MPAndroidChart**: Não suporta iOS nativamente
2. **Charts do Google**: Apenas Android
3. **Canvas customizado**: Mais trabalho, menos manutenção
4. **WebView com Chart.js**: Performance inferior, menos nativo
