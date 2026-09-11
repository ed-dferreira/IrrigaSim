# Fontes duplicidades e ressalvas

## Materiais analisados

| Arquivo | Conteúdo usado |
| --- | --- |
| `Aula 5 - Métodos de irrigação.pdf` | classificação geral e panorama dos métodos |
| `Aula 5 - Métodos de irrigação.docx` | mesmo conteúdo textual da Aula 5 em formato editável |
| `Aula 6 - Irrigação por sulcos.pdf` | conceitos, critérios, equações e exemplo de sulcos |
| `Aula 7 - Irrigação por faixas.pdf` | dimensionamento, avanço, recessão e operação de faixas |
| `Aula 8 - Irrigação por Inundação.pdf` | inundação intermitente, permanente e balanço para arroz |
| `Projeto faixas - Dimensionamento exemplo.xlsx` | fórmulas iterativas e cenário numérico de faixas |
| `Projeto faixas - Dimensionamento exemplo(1).xlsx` | segunda cópia do mesmo conteúdo de células e fórmulas |
| `Projeto Inundação intermitente - Dimensionamento exemplo.xlsx` | fórmulas iterativas e cenário numérico intermitente |
| `Projeto Inundação permanente - Dimensionamento exemplo.xlsx` | vazões de enchimento, manutenção e eficiências |

## Duplicidades

As duas planilhas de faixas têm hashes de arquivo diferentes, mas apresentam os mesmos valores e fórmulas em todas as células. A diferença está no pacote do arquivo, em estilos ou metadados, e não no modelo de cálculo. Uma única versão é suficiente como referência lógica.

A versão DOCX da Aula 5 repete o conteúdo textual do PDF. O PDF foi mantido como referência de paginação e composição visual.

## Ressalvas identificadas

### Inundação intermitente

No fechamento da planilha:

- a vazão total calculada é aproximadamente `222,22 L/s`, menor que os `400 L/s` disponíveis;
- a observação afirma que a vazão é maior que a disponível;
- o perfil gera `Pp` próxima de `71,60%` e `Pe` próxima de `-50,90%`.

A perda negativa é fisicamente inválida e revela que as fórmulas ou unidades dessa seção não fecham o balanço. Esses resultados não devem ser usados como referência esperada. As equações precisam ser revisadas contra o material teórico e, idealmente, contra a bibliografia original antes da implementação.

### Inundação permanente

O exemplo da aula informa área de 20 ha, enquanto a planilha usa 2 ha. Os resultados da planilha correspondem a 2 ha e não reproduzem literalmente o enunciado do slide.

A planilha define perda adicional `Pp = 0`, mas a equação de enchimento já inclui a condutividade hidráulica `K0`. O significado de `Pp` nessa planilha deve ser esclarecido antes de virar campo do produto.

### Faixas

O exemplo compara a primeira e a terceira irrigação, mas a seleção final e grande parte das simulações usam os parâmetros da terceira irrigação. A interface deve pedir a condição do solo ou explicar qual conjunto será adotado.

O arquivo usa abreviações como `tr`, `ti` e `td` tanto para instantes como para durações em diferentes contextos. A implementação deve usar nomes semânticos, por exemplo `instanteRecessaoMin` e `duracaoVazaoReduzidaMin`.

### Sulcos

O material apresenta dois patamares narrativos para eficiência de aplicação: acima de 70% como ideal e, num exemplo posterior, acima de 75%. Deve-se escolher uma referência técnica única antes de classificar resultados.

Os coeficientes da equação de avanço e os coeficientes de Kostiakov-Lewis usam letras semelhantes. O domínio deve diferenciá-los, por exemplo `advanceCoefficient` e `infiltrationK`.

## Nível de confiança

- Alto: distinção entre métodos, fases hidráulicas, lista de entradas e relações diretas de balanço.
- Médio: equações empíricas com unidades conferidas nas planilhas e slides.
- Pendente de validação: fórmulas empíricas de depleção e recessão, resultados finais da inundação intermitente e limiares de classificação.

## Antes de usar em produção

1. Confirmar a bibliografia-base citada nas aulas, especialmente Criddle, Hart, Walker e Skogerboe e Strelkoff.
2. Revisar as unidades originais de cada equação empírica.
3. Obter do responsável técnico a interpretação correta das células inconsistentes.
4. Transformar exemplos aprovados em testes automatizados versionados.
5. Registrar a versão do modelo em cada cenário salvo.

