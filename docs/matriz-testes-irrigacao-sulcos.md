# Matriz de testes: irrigação por sulcos

Esta matriz transforma `calculos-validados-irrigacao-sulcos.md` em cobertura verificável. Valores de exemplos marcados como divergentes na fonte devem testar a detecção da inconsistência, nunca se tornar resultados esperados de produção.

## Cálculos de domínio

| ID | Caso | Resultado esperado | Automação |
| --- | --- | --- | --- |
| CAL-01 | Avanço por dois pontos, 100/37,9 e 200/93,5 | `b=1,3027685166`, `k=0,0939944426` | `domain_calculation_regressions_test.dart` |
| CAL-02 | Avanço por regressão com o ponto `(0,0)` | Ponto inicial excluído somente do logaritmo; precisão preservada | Teste unitário |
| CAL-03 | Infiltração entrada/saída com 11 observações positivas | `n=-0,3107752603`, `K=35,2030168224` em mm/h | `integration_corn_project_test.dart` |
| CAL-04 | Infiltração acumulada | `I=K/[60*(n+1)]*T^(n+1)`; minutos convertidos uma vez | Teste unitário |
| CAL-05 | Ponto de infiltração inválido | Rejeitar valores negativos, `VI=0` com `T>0` e `(0,VI>0)` | `domain_calculation_regressions_test.dart` |
| CAL-06 | Vazão máxima não erosiva | Usar `qmax=C/S0^a`, com `S0` em porcentagem e tabela por textura | `domain_calculation_regressions_test.dart` |
| CAL-07 | Vazão reduzida | Diferenciar explicitamente `Qr` com fator `1,0` e `1,1` | `domain_calculation_regressions_test.dart` |
| CAL-08 | Lâmina com vazão reduzida | Somar os volumes de `qi` e `qr`; atraso zero reduz no fim do avanço | `domain_calculation_regressions_test.dart` |
| CAL-09 | Atraso de redução | Atraso positivo prolonga `qi` após o avanço e altera `Lm` | `domain_calculation_regressions_test.dart` |
| CAL-10 | Tempo de oportunidade | `To(x)=Tc+Td(x)+Trec(x)-Tx(x)`; nunca negativo | Teste unitário |
| CAL-11 | Eficiência e perdas | `Ea=Lf/Lm`, `Pp=(Lmi-LL)/Lm`, `Pe=(Lm-Lmi)/Lm` | `domain_calculation_regressions_test.dart` |
| CAL-12 | Lâmina requerida e turno | Rejeitar `UCC<=UPMP`; calcular IRN e TR para `UCC>UPMP` | Teste unitário |
| CAL-13 | Surtirção | Rejeitar o cálculo até existir curva calibrada de infiltração/ciclos | `domain_calculation_regressions_test.dart` |

## Interface

| ID | Caso | Resultado esperado | Tipo |
| --- | --- | --- | --- |
| UI-01 | Campos de avanço e infiltração | Rótulos, unidades e valores obrigatórios visíveis; erro junto ao campo inválido | Widget |
| UI-02 | Seleção de manejo reduzido | Mostrar vazão reduzida e `Atraso para redução após avanço`; aceitar zero como redução no fim do avanço | Widget |
| UI-03 | Resultado de manejo reduzido | Mostrar a lâmina calculada, o instante efetivo de mudança e as unidades | Widget |
| UI-04 | Surtirção | Informar que não há modelo calibrado, sem apresentar eficiência ou lâmina estimada | Widget/integrado |
| UI-05 | Resultado de erosão | Exibir alerta quando `q > qmax`, com vazão e limite em L/s | Widget |
| UI-06 | Gráfico de oportunidade | Mostrar estado indisponível sem dados de recesso; não usar a curva de avanço como oportunidade | Widget |
| UI-07 | Cenários e persistência | Restaurar manejo, vazão reduzida, atraso e geometria sem arredondar os dados armazenados | Integração |
| UI-08 | Acessibilidade | Campos têm rótulo semântico, unidades legíveis, escala de texto ampliada e foco navegável | Widget |
| UI-09 | Layout responsivo | Etapas, erros e resultados permanecem utilizáveis em larguras mobile e desktop | Golden/widget |

## Critérios de execução

- Comparar números com tolerância, não com texto formatado.
- Executar `flutter analyze` e `flutter test` antes de aceitar mudanças de cálculo.
- Manter os casos de divergência documental separados dos casos de aceitação.
- A cobertura de interface acima ainda deve ser implementada: o repositório não possui testes `testWidgets` ou `integration_test` para este fluxo.
