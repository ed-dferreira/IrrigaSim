# ADR-0004: Modelo matemático intermediário (Kostiakov + Balanço de Volume)

## Status

Aceito

## Contexto

O IrrigaSIM precisa de um modelo matemático para simular irrigação por superfície que equilibre:
- Rigor científico (validação pedagógica)
- Viabilidade computacional em mobile
- Consistência com softwares de referência (SIRMOD, WinSRFR)

## Decisão

Usar **equação de Kostiakov** para infiltração + **modelo de balanço de volume** para hidráulica.

### Especificação

**Infiltração (Kostiakov):**
```
F = k × t^a
```
Onde:
- F = lâmina infiltrada (mm)
- t = tempo (h)
- k = coeficiente de infiltração
- a = expoente de infiltração

**Hidráulica (Balanço de Volume):**
- Equação de continuidade: Q₀ = dV/dt + dF/dt
- Avanço: progressão da frente de água
- Recessão: após corte de vazão

## Consequências

**Positivas:**
- Modelo validado na literatura de irrigação
- Consistente com SIRMOD e WinSRFR
- Custo computacional baixo (sem EDOs)
- Parâmetros de entrada simples e mensuráveis

**Negativas:**
- Não captura efeitos hidrodinâmicos complexos
- Valores de k e a variam entre solos (requer calibração)
- Precisão menor que modelo completo de Saint-Venant

## Alternativas Consideradas

1. **Saint-Venant completo**: Precisão superior, mas complexidade computacional proibitiva para mobile
2. **Kostiakov puro**: Apenas infiltração, sem modelagem de avanço
3. **Philip**: Mais complexo, menos usado na prática
