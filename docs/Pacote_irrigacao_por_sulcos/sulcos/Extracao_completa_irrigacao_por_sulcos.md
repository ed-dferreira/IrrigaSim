# Irrigação por sulcos: extração integral, auditoria e base para simulador

**Fonte:** Aula 6 - Irrigação por sulcos.pdf, 101 páginas, Universidade Federal do Pampa, Prof.ª Chaiane Guerra da Conceição. Análise de 30/09/2026. As referências indicam a página física do PDF, coincidente com o número do slide. Foram examinados o texto e as páginas renderizadas, incluindo fórmulas, gráficos e tabelas em imagens.

Este relatório é independente da análise de irrigação por faixas. Não importa coeficientes, resultados ou algoritmos daquele outro documento. O objetivo é aproveitar todo o conteúdo técnico desta aula e deixar claro o que pode ser implementado, o que precisa ser corrigido e o que não está especificado.

## 1. Convenções de leitura e limites

- **Extraído:** afirmação, fórmula, dado ou resultado efetivamente presente no PDF.
- **Recalculado:** resultado obtido aqui com os dados e expressões da aula, preservando mais casas decimais.
- **Derivado:** conversão de unidades, rearranjo algébrico ou consequência matemática explicitamente identificada.
- **Proposto:** decisão de implementação que o PDF não define.

Nenhuma divergência foi corrigida silenciosamente. O documento contém resultados arredondados, erros aritméticos, ambiguidades de notação e inconsistências entre hipóteses e exemplos. Não houve verificação bibliográfica externa das equações empíricas; esta é uma auditoria interna da aula, acompanhada de código reprodutível. Testes do código não equivalem a validação agronômica ou hidráulica em campo.

O PDF permite construir calculadoras de avanço, infiltração, lâminas, indicadores e organização de parcelas, além de uma simulação empírica de perfil com curvas de avanço fornecidas. Não apresenta um solucionador completo de escoamento nem uma relação geral que preveja uma nova curva de avanço quando a vazão, a seção, o declive ou o solo mudam.

## 2. Definição e características do método [pp.2–4]

Água conduzida em pequenos canais paralelos às fileiras de plantas, durante tempo suficiente para umedecer a zona radicular. O terreno precisa estar adequadamente sistematizado para boa eficiência.

Características expressas na aula:

- Uso em espécies plantadas em linha.
- Molhamento de aproximadamente **30–80% da superfície**, reduzindo perdas por evaporação em relação ao molhamento de toda a superfície.
- Maior necessidade de mão de obra e experiência para derivar/controlar água.
- Alta disponibilidade de água e vazões suficientes para reduzir desuniformidade.
- Orientação geral de pequenas declividades, **<2%**, e superfície uniforme; há exceções específicas na classificação dos corrugados.
- Solo de textura homogênea ao longo do sulco.
- Água não precisa ser limpa segundo o texto; vento não afeta diretamente a aplicação como em métodos com jato.
- Se não houver necessidade de sistematização, custo indicado de **US$400–800/ha**. É um valor do material, sem data-base ou composição de custos; não é orçamento atual e não deve alimentar estimativa financeira atual sem atualização.

O intervalo de molhamento não é automaticamente a fração de raiz atendida, a eficiência de aplicação ou um desconto sobre a lâmina necessária. Não multiplicar a IRN por 0,3 ou 0,8 sem um modelo adicional.

## 3. Tipos, declividades e geometrias

### 3.1 Classificação completa [pp.5–14]

| Tipo | Ideal, conforme PDF | Aconselhável | Usável | Comprimento | Outras características |
|---|---|---|---|---|---|
| Comuns / terras planas | 0,1% | 0,05–0,5% | 0,02–1,0% | Limites práticos 100–500 m | Retilíneos, seção V; cultivos em fileiras |
| Em contorno | 1,0% | 0,5–2% | Não informado | 70–150 m | Direção das curvas de nível; entalhe com banco no lado inferior |
| Corrugados | 1–2% | 0,5–12% | Até 15%; limite inferior não informado nesta categoria | 30–180 m | Pequenos V/U, direção da maior declividade |
| Em nível, dentro de tabuleiros/bacias | Não há intervalo numérico | Não informado | Não informado | Não informado | Espaçamento em torno de 1 m; todos os sulcos do tabuleiro se enchem |
| Em nível, largos e fechados nas extremidades | Sem declive ou declive muito pequeno, sem faixa numérica | Não informado | Não informado | Curtos, sem número | Encher e cortar/reduzir vazão conforme necessidade |
| Em zigue-zague | Não informado | Não informado | Não informado | Não informado | Baixa capacidade de infiltração; frutíferas, uva e pomares |

**Não inventar classes numéricas para tabuleiros, fechados ou zigue-zague.** “Em nível” permite registrar a configuração nominal de nível, mas não justifica preencher faixas de tolerância que a aula não apresenta. Zigue-zague não é definido pelo PDF como sinônimo de sulco em nível.

As declividades da classificação são reproduzidas como aparecem; o slide de contorno não separa numericamente declive geral do terreno e declive ao longo do eixo do sulco. O cadastro deve distinguir esses dois campos, evitando transferir automaticamente uma declividade de encosta para o canal.

**Comuns:** capacidade depende do solo, declive e cultura. Longos e retos reduzem custos e trabalho, favorecendo operações mecanizadas. Comprimento efetivo depende de irrigar eficientemente, não apenas de respeitar 100–500 m.

**Contorno:** capacidade extra para retenção de enxurrada; videiras e pomares em curvas de nível; aproveitam áreas com declividade e irregularidade inadequadas a sulcos comuns. O PDF desaconselha regiões com precipitações intensas. Não fornece volume de retenção ou chuva de projeto.

**Corrugados:** vazões indicadas de **0,05 a 0,5 L/s**; profundidade em torno de **10 cm**; espaçamento **40–75 cm**. Culturas densas que não exigem capina, como pastagem, alfafa e forrageiras. O movimento radial de água umedece lentamente a superfície e reduz formação de crosta. A recomendação geral <2% não pode bloquear os corrugados, que possuem limites próprios.

**Em nível, primeiro método:** sulcos em antigos tabuleiros de arroz; água circula entre canteiros e enche os sulcos; uso fora da época do arroz com trigo, cevada, cebola e olerícolas; aproveitamento intensivo do terreno. O texto indica ausência de saída de água no final dos sulcos nessa configuração. Isso não significa ausência de percolação, evaporação, extravasamento ou perdas do sistema inteiro.

**Em nível, segundo método:** sulcos largos, fechados nas duas extremidades, geralmente curtos; citros, banana e uva. A vazão pode ser cortada ou reduzida após enchimento. Não há algoritmo completo de armazenamento/enchimento no PDF.

**Zigue-zague e variantes gráficas:** p.13 mostra (A) videira em declividade moderada, (B) videira em pouca declividade, (C) árvores frutíferas. P.14 mostra sulcos em **quadras** (A) e em **dentes** (B) na fruticultura. Não há dimensões nem perdas localizadas nas curvas especificadas.

### 3.2 Distribuição, seção e espaçamento [pp.15–16,51–56]

Dispositivos: **sifões, bacias auxiliares e tubos janelados**. As fotografias ilustram derivação e distribuição, sem tabelas de vazão desses equipamentos.

Comprimento depende de forma/dimensões da área, solo, vazão, declive, mão de obra, perda de área cultivável, mecanização e perdas por percolação/escoamento.

Espaçamento depende das fileiras, do solo e dos equipamentos. O texto cita fileiras de **90–110 cm** e regra prática **E≤2z**, com z=profundidade efetiva de raízes e ambas as medidas na mesma unidade. Não é uma lei hidráulica universal. O exemplo da p.89 usa E=0,9 m e z=0,5 m, atendendo 0,9≤1,0 m. O da p.101 fica na igualdade, E=1 m e z=0,5 m.

P.53 ilustra maior penetração vertical relativa em solo arenoso e maior espalhamento lateral relativo em argiloso, com intermediário no solo médio. É informação qualitativa; não fornece função para prever raio de molhamento.

Seção mais comum em V; largura média **20–30 cm**, profundidade **15–25 cm** [p.54]. Essas dimensões gerais diferem dos minissulcos corrugados. A largura superficial do canal não é o espaçamento E nem a largura de solo representada por sulco na conversão de lâmina.

Vazão usual geral **0,5–2 L/s**, comum **1 L/s** [pp.55–56]; preservar o intervalo específico menor dos corrugados. A maior vazão aceitável é a que não provoca erosão.

## 4. Todas as tabelas quantitativas

### 4.1 Comprimento e espaçamento de corrugados, adaptado por Booher [p.9]

Cada célula traz **comprimento / espaçamento, em m**. Traço significa não informado; no JSON é `null`, nunca zero.

| Raízes | Declive (%) | Textura fina | Textura média | Textura grossa |
|---|---:|---:|---:|---:|
| Profundas | 2 | 180 / 0,75 | 130 / 0,70 | 70 / 0,60 |
| Profundas | 4 | 120 / 0,65 | 90 / 0,65 | 45 / 0,55 |
| Profundas | 6 | 90 / 0,60 | 75 / 0,60 | 40 / 0,50 |
| Profundas | 8 | 80 / 0,55 | 60 / 0,55 | 30 / 0,45 |
| Profundas | 10 | 70 / 0,50 | 50 / 0,50 | — |
| Profundas | 12 | 60 / 0,45 | 40 / 0,45 | — |
| Rasas | 2 | 120 / 0,65 | 90 / 0,55 | 45 / 0,45 |
| Rasas | 4 | 85 / 0,60 | 60 / 0,50 | 30 / 0,45 |
| Rasas | 6 | 70 / 0,55 | 50 / 0,45 | — |
| Rasas | 8 | 60 / 0,50 | 45 / 0,45 | — |
| Rasas | 10 | 55 / 0,45 | 40 / 0,40 | — |
| Rasas | 12 | 50 / 0,40 | 35 / 0,40 | — |

São 36 combinações de classe de raiz, declive e textura, das quais 30 possuem comprimento/espaçamento e seis não informam valores. Não extrapolar para 15% apenas porque essa declividade aparece como “usável” na classificação. Interpolação entre linhas seria uma escolha do software, não procedimento dado pela aula.

### 4.2 Coeficientes de vazão não erosiva [p.55]

Tabela atribuída a Hamad e Stringham (1978), na página que também cita Criddle (1956):

| Textura | C | a |
|---|---:|---:|
| Muito fina | 0,892 | 0,937 |
| Fina | 0,988 | 0,550 |
| Média | 0,613 | 0,733 |
| Grossa | 0,644 | 0,704 |
| Muito grossa | 0,665 | 0,548 |

Fórmula: `qmax=C/S_percent^a`, qmax em L/s. Os parâmetros dependem da unidade de S; **usar % como a página manda**, não decimal. Não confundir C com comprimento e a com expoente de infiltração. O slide não fornece critérios para mapear automaticamente uma descrição livre de solo às cinco classes.

### 4.3 Dados de avanço: dois conjuntos diferentes [pp.25–34]

| Estaca | Distância (m) | Tempo A, pp.25–26 (min) | Tempo B, pp.29–33 (min) |
|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 1 | 20 | 5 | 2 |
| 2 | 40 | 10,5 | 5 |
| 3 | 60 | 19,2 | 9 |
| 4 | 80 | 30 | 14 |
| 5 | 100 | 37,9 | 21 |
| 6 | 120 | 48 | 30 |
| 7 | 140 | 60,5 | 40 |
| 8 | 160 | 68 | 53 |
| 9 | 180 | 81,3 | 69 |
| 10 | 200 | 93,5 | 93 |

Não são duas técnicas aplicadas ao mesmo conjunto. A p.26 contém também a regressão do conjunto A. Comparar o ajuste de dois pontos de A com mínimos quadrados de B como se fossem o mesmo ensaio seria errado.

Colunas transformadas impressas para B, repetidas nas pp.29–33:

| x físico (m) | log10 x | log10 T | Produto | (log10 x)² |
|---:|---:|---:|---:|---:|
| 20 | 1,30 | 0,30 | 0,39 | 1,69 |
| 40 | 1,60 | 0,70 | 1,12 | 2,57 |
| 60 | 1,78 | 0,95 | 1,70 | 3,16 |
| 80 | 1,90 | 1,15 | 2,18 | 3,62 |
| 100 | 2,00 | 1,32 | 2,64 | 4,00 |
| 120 | 2,08 | 1,48 | 3,07 | 4,32 |
| 140 | 2,15 | 1,60 | 3,44 | 4,61 |
| 160 | 2,20 | 1,72 | 3,80 | 4,86 |
| 180 | 2,26 | 1,84 | 4,15 | 5,09 |
| 200 | 2,30 | 1,97 | 4,53 | 5,29 |
| Soma impressa | 19,57 | 13,03 | 27,02 | 39,21 |
| Média impressa | 1,96 | 1,30 | 2,70 | 3,92 |

Recalcular a partir dos pares físicos, sem acumular os arredondamentos das colunas. (0,0) pode permanecer no gráfico, mas não participa da transformação logarítmica.

### 4.4 Ensaio de entrada e saída [pp.39–47]

Comprimento observado **100 m**, espaçamento **1 m**, entrada **1 L/s** em todas as linhas.

| Tempo (min) | Saída (L/s) | Diferença impressa (L/s no trecho) | VI impressa (mm/h) |
|---:|---:|---:|---:|
| 0 | 0 | — | — |
| 2 | 0,19 | 0,81 | 29,2 |
| 9 | 0,50 | 0,50 | 18,0 |
| 19 | 0,63 | 0,37 | 13,3 |
| 29 | 0,66 | 0,34 | 12,2 |
| 49 | 0,71 | 0,29 | 10,4 |
| 64 | 0,73 | 0,27 | 9,7 |
| 79 | 0,75 | 0,25 | 9,0 |
| 89 | 0,76 | 0,24 | 8,6 |
| 101 | 0,77 | 0,23 | 8,3 |
| 119 | 0,78 | 0,22 | 7,9 |
| 149 | 0,78 | 0,22 | 7,9 |

O cabeçalho “L/s*100m” é ambíguo: os valores representam a diferença de vazão do trecho inteiro, e não uma multiplicação física da unidade por 100 m. Conversão usada: `VI=3600 Δq/(100×1)=36 Δq`. Exemplos: 0,81 →29,16≈29,2 mm/h; 0,22 →7,92≈7,9 mm/h.

As colunas logarítmicas impressas usam **log da diferença de vazão**, não log dos números em mm/h:

| T (min) | log T | log Δq | Produto | (log T)² |
|---:|---:|---:|---:|---:|
| 2 | 0,30 | −0,09 | −0,03 | 0,09 |
| 9 | 0,95 | −0,30 | −0,29 | 0,91 |
| 19 | 1,28 | −0,43 | −0,55 | 1,64 |
| 29 | 1,46 | −0,47 | −0,69 | 2,14 |
| 49 | 1,69 | −0,54 | −0,91 | 2,86 |
| 64 | 1,81 | −0,57 | −1,03 | 3,26 |
| 79 | 1,90 | −0,60 | −1,14 | 3,60 |
| 89 | 1,95 | −0,62 | −1,21 | 3,80 |
| 101 | 2,00 | −0,64 | −1,28 | 4,02 |
| 119 | 2,08 | −0,66 | −1,36 | 4,31 |
| 149 | 2,17 | −0,66 | −1,43 | 4,72 |
| Soma | 17,59 | −5,57 | −9,91 | 31,34 |
| Média | 1,60 | −0,51 | −0,90 | 2,85 |

Há **11 pares positivos**, embora a p.40 use N=10. As médias impressas são compatíveis com 11. A correção da contagem e da unidade deve preceder qualquer uso no aplicativo.

### 4.5 Somatório das infiltrações parciais [p.96]

Instante global **110 min**; `VI=1,411 τ^−0,446` em L/min/m. A coluna τ é tempo desde chegada da água em cada posição.

| x (m) | ta (min) | τ (min) | VI impressa (L/min/m) | Média do trecho (L/min/m) | Vazão no trecho de 20 m (L/min) |
|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 110 | 0,173 | — | — |
| 20 | 5 | 105 | 0,177 | 0,175 | 3,50 |
| 40 | 9 | 101 | 0,180 | 0,179 | 3,57 |
| 60 | 16 | 94 | 0,186 | 0,183 | 3,66 |
| 80 | 25 | 85 | 0,195 | 0,191 | 3,81 |
| 100 | 35 | 75 | 0,206 | 0,201 | 4,01 |
| 120 | 45 | 65 | 0,219 | 0,213 | 4,25 |
| 140 | 56 | 54 | 0,238 | 0,229 | 4,57 |
| 160 | 67 | 43 | 0,264 | 0,251 | 5,02 |
| 180 | 79 | 31 | 0,305 | 0,285 | 5,69 |
| 200 | 90 | 20 | 0,371 | 0,338 | 6,76 |

Total impresso: **44,81 L/min**, adotado **0,75 L/s**. É uma vazão infiltrada naquele instante, apesar do rótulo “Total infiltrado”; não é volume acumulado. Recalculando sem arredondar: **44,83401262 L/min =0,74723354 L/s**. A soma dos trechos já arredondados dá 44,84 L/min, também diferente de 44,81; registrar a pequena diferença em vez de forçar igualdade.

## 5. Dicionário de grandezas e unidades

| Notação no aplicativo | Significado | Unidade sugerida |
|---|---|---|
| x, L | Posição e comprimento de sulco | m |
| Lt, Wt | Dimensões da área | m |
| E | Espaçamento / largura de terreno atribuída ao sulco | m |
| largura_canal, profundidade_canal | Geometria do canal | m |
| S_percent | Declive usado na fórmula de erosão | % |
| q, qi, qr | Vazão por sulco; inicial; reduzida | L/s |
| Qprojeto, perdas_vazao | Vazão do conjunto e perdas de condução | L/s |
| k_av, b_av | Coeficientes de ta=k_av x^b_av | min/m^b_av; adimensional |
| K_vi, n_vi | Coeficientes da taxa de infiltração | Dependem da unidade da taxa e do tempo |
| k_I, a_I | Coeficientes da infiltração acumulada | mm/min^a_I ou L/m/min^a_I |
| ta(x), tc | Instante de chegada e de corte | min desde início |
| τ(x), t0 | Oportunidade local e necessária no final | min |
| t_reduzida | Duração com vazão reduzida | min; não instante de mudança |
| Li, Lf | Lâminas infiltradas na entrada e no final | mm |
| Lm, Lmi | Lâmina média aplicada e média infiltrada | mm |
| LL, IRN, CRA | Lâmina líquida necessária/capacidade real | mm; distinguir usos |
| UCC, UPMP | Umidades gravimétricas em capacidade de campo e murcha | % em massa no cálculo dado |
| Ds | Densidade do solo | g/cm³ |
| z, f | Profundidade radicular e fração utilizável | cm no cálculo do slide; fração |
| ETc, Pef | Evapotranspiração e precipitação efetiva | mm/dia |
| TR, PI | Turno de rega e período operacional de irrigação | dias |
| Ec, Ed, Ea, GA, Pp, Pe | Indicadores definidos abaixo | % |
| NTS, NSD, NSP, NPD | Sulcos totais, por dia, por parcela e parcelas/dia | contagem ou taxa |
| TIP, TDF, tmud | Tempo por parcela, jornada e mudança | min internamente |

**Colisões do PDF a resolver:** L ora é comprimento, ora largura molhada; C ora comprimento, ora coeficiente de erosão; k/a aparecem em ajuste, infiltração e erosão; Tr pode ser reposição, recessão ou duração da vazão reduzida; Pe pode ser perda por escoamento ou precipitação efetiva. Usar nomes explícitos e unidades em cada campo.

Conversões: `1 L/m²=1 mm`; `1 L/s=60 L/min=0,06 m³/min`; `1 h=60 min`; `1 ha=10.000 m²`; `S_decimal=S_percent/100`. Nas fórmulas de qmax desta aula usar S_percent, mesmo que o sistema também armazene S_decimal.

## 6. Catálogo de cálculos e algoritmos

Os IDs F01–F32 correspondem ao arquivo `catalogo_formulas.json`. As formas normalizadas e derivações são explicadas aqui; não devem ser confundidas com transcrição literal sem alterações.

### 6.1 Avanço potencial e ajuste [pp.21–38]

**F01:** `ta(x)=k_av x^b_av`. Linearização: `log ta=log k_av+b_av log x`. Inversa derivada: `x=(ta/k_av)^(1/b_av)`. Exigir k_av>0 e b_av>0 para avanço físico monotônico.

**F02, dois pontos:**

```text
b_av = ln(t2/t1)/ln(x2/x1)
k_av = t2/x2^b_av
```

Para ponto médio x1=0,5x2, a aula escreve `[ln(t1)−ln(t2)]/ln(0,5)`. É equivalente. Se não houver medição no ponto médio, a p.25 orienta interpolar; o método de interpolação não é especificado. Proposta: interpolação linear entre vizinhos, identificada como interpolação, sem extrapolação.

**F03, mínimos quadrados nos logaritmos:** usar Xi=log10(xi), Yi=log10(ti), N=pares positivos.

```text
b = [ΣXiYi−(ΣXi)(ΣYi)/N] / [ΣXi²−(ΣXi)²/N]
A = média(Y)−b média(X)
k = 10^A
```

A p.28 troca símbolos na fórmula do intercepto: escreve `a=ȳ−n x̄`; a versão consistente é A=ȳ−b x̄. Este ajuste minimiza erros quadráticos no espaço logarítmico, não erros em minutos. Não garante ser o melhor ajuste em escala original. O app deve mostrar dados, curva, resíduos e R² identificado como logarítmico, e não apenas repetir “melhores estimativas”. Excluir zeros do log com aviso, sem transformá-los em números pequenos arbitrários; os arquivos mantêm (0,0) como origem observada.

### 6.2 Infiltração, integração e oportunidade [pp.39–47,91–93]

**F04, conversão do ensaio:** `VI_mm_h=3600(qentrada−qsaida)/(L E)`. É a conversão derivada dos dados da p.39. Pressupõe que a diferença corresponda à infiltração; durante enchimento, variação do armazenamento superficial também consome vazão. O balanço geral contém `Qentrada−Qsaida−dVsuperficie/dt`. Não interpretar automaticamente uma série de tempos globais de ensaio como uma lei local de oportunidade sem considerar como o ensaio foi conduzido.

Lei potencial apresentada: `VI(T)=K_vi T^n_vi`. Para n_vi<0, VI diminui; para integrar desde zero com volume finito, exigir n_vi>−1. A taxa é singular em T=0 se n_vi<0, embora sua integral seja finita.

**F05, se VI está em mm/h e T em min:**

```text
I_mm(T) = K_vi/[60(n_vi+1)] × T^(n_vi+1)
```

**F06, se VI está em L/min/m e T em min:**

```text
I_L_m(T) = K_vi/(n_vi+1) × T^(n_vi+1)
```

**F07:** `I_mm=I_L_m/E`, pois um litro por metro longitudinal repartido por E metros de largura resulta em L/m². Não aplicar fator 60 novamente nesse ramo.

Inversa derivada: para `I=k_I T^a_I`, `t0=(IRN/k_I)^(1/a_I)`. Não precisa de Newton para esta potência simples. Diferenciar o coeficiente k de avanço do de infiltração.

A lei potencial simples tende a zero quando T cresce, enquanto VIB positiva representa taxa básica não nula. Este PDF informa VIB e também usa leis potenciais sem termo básico. Não adicionar silenciosamente `VIB×T`: isso mudaria o modelo e seus coeficientes. Informar a faixa de calibração e sinalizar a incompatibilidade quando a taxa calculada ficar abaixo da VIB informada.

### 6.3 Fases e duração [pp.18–21,48–50,79]

| Fase | Definição | Duração/instante |
|---|---|---|
| Avanço | Entrada de água até chegar ao final | ta(L) |
| Reposição | Final do avanço até interrupção | tc−ta(L) |
| Depleção | Corte até exposição de algum ponto da superfície | Duração geralmente desprezada em sulcos no modelo da aula |
| Recessão | Progressão da exposição até não restar água superficial | Geralmente desprezada no modelo simplificado |

**F08, forma p.50:** `To(i)=Tc−Tx(i)+Td+Trec(i)`. Para essa soma ser coerente, Td e Trec(i) devem ser durações adicionais após corte, e não instantes absolutos. A identidade sem ambiguidade é `τ(x)=t_recessao_absoluto(x)−t_avanco_absoluto(x)`. A linha `Tr=Tc−Tx` nessa página descreve a reposição no final, não o instante absoluto de recessão.

**F09, simplificação da p.79:** `ti=t0+ta(L)`, considerando recessão instantânea no corte; `τ(x)=ti−ta(x)`. A simplificação não deve ser aplicada como física universal a sulcos fechados, com empoçamento ou recessão significativa.

**F10, regra prática de Criddle [pp.21,51]:** `ta(L)=t0/4`; invertendo a curva, `Lmax=(t0/(4 k_av))^(1/b_av)`. A própria aula diz que modelos podem dimensionar por eficiência sem usar a regra. Não transformar seu atendimento em prova de ótimo nem reprovar automaticamente toda alternativa que não a segue.

### 6.4 Espaçamento, erosão e vazão [pp.52,55–56]

**F11:** `E≤2z`, regra prática. **F12:** `qmax=C/S_percent^a`, com tabela da seção 4.2. **F13:** `qmax=0,631/S_percent`, versão simplificada.

Exemplos derivados: a 0,5%, qmax=1,262 L/s; a 0,1%, 6,31 L/s. qmax não é vazão recomendada: apenas limite empírico segundo a expressão. O ensaio de campo que produz erosão deve gerar rejeição independentemente de limites tabulados mais permissivos. S=0 torna essas expressões indefinidas; não atribuir vazão infinita aos sulcos em nível.

### 6.5 Lâminas e volumes [pp.57–59]

**F14, vazão constante:**

```text
Lm_mm = 3600 q_L_s T_h/(L E)
      = 60 q_L_s T_min/(L E)
```

**F15, redução de vazão:**

```text
Lm_mm = 60 [(Ttotal−Treduzida) qi + Treduzida qr]/(L E)
```

Tempos em min; se em h, usar 3600. O instante de troca é Ttotal−Treduzida. Forma geral derivada por blocos: `Lm=60 Σ(qj Δtj)/(L E)`. Volume aplicado `V_m3=Lm_mm L E/1000`.

A nota p.59 diz que Tr deve ser “múltiplo” de Tt, embora Tr seja parte do total. Para 0<Tr<Tt, um múltiplo inteiro positivo de Tt é impossível. Provável intenção de submúltiplo/fração conveniente, mas sem correção silenciosa. O exemplo posterior usa metade.

**F16, média infiltrada:** p.58 iguala `Σyi/n` e `(Li+Lf)/2`. Não são identidades para perfil arbitrário. A segunda é aproximação de perfil linear. Para nós igualmente espaçados, uma média aritmética de amostras e uma média espacial integrada também podem diferir pelo peso dos extremos.

Proposta consistente: `Lmi=(1/L)∫I(x)dx`, com regra dos trapézios `ΣΔx(Ij+Ij+1)/2`, dividida por L. Usar também para estações irregulares. Não usar a largura da seção do canal no lugar de E.

### 6.6 Indicadores e perdas [pp.60–65]

**F17:** `Ec=100 V_aplicado_na_area/V_derivado_da_fonte`. Condução mede perdas entre captação e parcela; especialmente relevante em bombeamento, disponibilidade limitada e grandes distâncias. Não confundir os símbolos Va/Vd desta aula com volumes por regiões usados em outros materiais.

**F18:** `Ed=100 Lf/[(Li+Lf)/2]`. É o índice simplificado definido pela aula; não é automaticamente coeficiente de Christiansen ou uniformidade do quarto inferior.

**F19:** `Ea_slide=100 Lf/Lm`. É útil no caso-alvo Lf≈LL com atendimento do restante; não substitui avaliação do volume útil sob déficit, excesso ou perfil irregular.

**F20:** `GA=100 lâmina_infiltrada_útil/lâmina_requerida`. O texto interpreta >100% como excesso, <100% como déficit e =100% como ideal. Há ambiguidade: água útil limitada à necessidade não deveria exceder 100%. Separar no software `razao_infiltrada_requerida=I/IRN` (pode exceder 1) de `fracao_necessidade_atendida=min(I,IRN)/IRN` (não excede 1). Uma média de 100% não prova uniformidade nem ausência simultânea de excesso e déficit. O PDF não define se GA é local, médio ou percentual da área.

**F21:** `Pp_slide=100(Lmi−LL)/Lm`. **F22:** `Pe_slide=100(Lm−Lmi)/Lm`. Essas expressões pressupõem que a lâmina útil média seja LL. Sob déficit, a primeira pode produzir perda negativa, sinal de uso indevido; não corrigir apenas truncando o valor.

**Proposta integral, explicitamente adicional à aula:**

```text
Lutil = média espacial de min(I(x),IRN)
Lperc = média espacial de max(I(x)−IRN,0)
Ldef = média espacial de max(IRN−I(x),0)
Lesc = Lm−Lmi                         [balanço ao final, sem água armazenada]
Ea_integral = 100 Lutil/Lm
Er = 100 Lutil/IRN
Pp_integral = 100 Lperc/Lm
Pe_integral = 100 Lesc/Lm
```

Checar Lmi=Lutil+Lperc, IRN=Lutil+Ldef, Lm=Lutil+Lperc+Lesc. Os três percentuais Ea+Pp+Pe devem somar 100 dentro da tolerância. Lesc negativo significativo aponta balanço inconsistente. Uma igualdade algébrica não valida o modelo de avanço/infiltração usado.

Critérios impressos, mantendo diferenças internas:

| Página | Orientação |
|---|---|
| 62 | Ed>70%, exceto solos muito permeáveis |
| 63 | Ea mínimo aceitável 60%, ideal >70% |
| 75 | No exemplo: Ed>80% “OK”; Ea aceitável >60%, ideal >75% |
| 76 | Pp até 15% aceitável; Pe até 10% |

Não unificar “ideal” em um único limite sem escolher e exibir qual referência interna foi adotada. São critérios da aula, não norma atual verificada.

### 6.7 Redução de vazão [pp.77,95–98]

**F23, vazão reduzida pela taxa básica:** `qr=1,1 fo L E/3600`, fo em mm/h, qr em L/s. A substituição numérica da p.77 omite o fator 1,1; ver auditoria do exemplo.

**F24, somatório instantâneo:** no instante de redução t*, τj=t*−ta(xj), calcular VIj=K_vi τj^n_vi em L/min/m. `Qinf_L_min≈ΣΔxj(VIj+VIj+1)/2`; dividir por 60 para L/s. Exigir τj>0 para expoente negativo.

Essa conta estima a vazão infiltrada naquele instante, aproximando a necessária para manter a cobertura sem saída excessiva. Não resolve o transiente de armazenamento superficial nem a mudança de perímetro molhado quando a vazão é reduzida. O app deve mostrar essa hipótese e não afirmar que o perfil permanece idêntico em qualquer redução.

### 6.8 Demanda, turno e organização [pp.80–86,89–100]

**F25, IRN do exemplo:** `IRN_mm=(UCC−UPMP)/10 × Ds × z_cm × f`. UCC/UPMP em percentuais gravimétricos, Ds em g/cm³, z em cm. A capacidade total sem f é a mesma expressão com f=1. Se a entrada já for umidade volumétrica, não multiplicar novamente por Ds.

**F26:** `TR=CRA/(ETc−Pef)` em dias. Derivação contextual: ETc≈kc ETo. O projeto usa precipitação provável como abatimento; o app deve distinguir precipitação provável, observada e efetiva. Se ETc−Pef≤0, não há turno positivo por essa expressão: retornar “sem demanda líquida positiva”, não divisão por zero ou dias negativos.

**F27–F32:**

```text
NTS = Lt Wt/(L E)
NSD = NTS/PI
TIP = ti+tmud
NPD = TDF/TIP
NSP = NSD/NPD
Qprojeto = NSP q0 + PC
```

PC deve ser uma vazão se somada nessa fórmula; a legenda apenas diz “perdas”. Se perdas forem fração p da vazão captada, derivar `Qfonte=Qparcela/(1−p)`; se usar Ec%, `Qfonte=Qparcela/(Ec/100)`. Não somar 10% como se fossem 10 L/s, nem aplicar margem duas vezes.

TR limita a frequência agronômica; PI é o período operacional destinado a completar a área e pode ser menor. A igualdade PI=TR precisa ser uma escolha declarada. Para grupos inteiros por dia, usar piso em NPD e dimensionar NSP por teto para atender NTS no PI. O software deve conferir fechamento das dimensões, área residual, número de grupos e último grupo incompleto.

## 7. Exemplos recalculados e casos de referência

### 7.1 Ajuste por dois pontos do conjunto A [pp.25–26]

Usando (100 m,37,9 min) e (200 m,93,5 min):

```text
b = ln(93,5/37,9)/ln(2) = 1,3027685166
k = 93,5/200^b = 0,09399444259
ta(x) = 0,09399444259 x^1,3027685166
```

A aula arredonda b para 1,30, calcula k≈0,095 e mostra `ta=0,095 x^1,30`. A regressão da p.26 sobre os **dez pontos positivos de A** é outro ajuste: `ta=0,09780307638 x^1,2944313738`, concordando com o gráfico 0,0978 e 1,2944. Não chamar essa diferença de erro; são métodos e precisões diferentes.

### 7.2 Mínimos quadrados do conjunto B [pp.29–34]

Com dados originais e N=10:

```text
ΣX = 19,57006298952
ΣY = 13,03337899479
ΣXY = 27,02043550127
ΣX² = 39,21084684386
b = 1,65992063426
A = −1,94513723753
k = 0,01134652208
ta(x) = 0,01134652208 x^1,65992063426
```

O gráfico da p.34 mostra `0,0113 x^1,6599`, compatível. A sequência manual mostra b=1,65, A=−1,93, k=0,011. Além dos arredondamentos, `10^−1,93≈0,01174898`, que não é 0,011 por arredondamento usual a três casas; o aplicativo deve calcular k a partir de A em precisão completa.

### 7.3 Exercício dos 60/120 m [pp.35–38]

Dados (60 m,22 min), (120 m,58 min). Pedidos: equação, tempo em 80 m e comprimento para 53 min.

| Resultado | Coeficientes sem arredondamento | Reprodução da equação impressa |
|---|---:|---:|
| b | 1,39854937649 | 1,39 |
| k | 0,07171175619 | 0,0747 |
| ta(80 m) | 32,89695290 min | 33,00773194 min; slide 33 min |
| x(53 min) | 112,50878537 m | 112,47265711 m; slide 112,47 m |

Guardar dois testes: cálculo com precisão completa e reprodução do slide arredondado. Comparar ambos com uma única tolerância ultrarrestrita produziria falsos erros.

### 7.4 Ajuste de infiltração do ensaio de entrada e saída [pp.39–47]

Recalculando os 11 pares positivos:

```text
Δq_L_s = 0,97786157840 T^−0,31077526033
VI_mm_h = 35,20301682239 T^−0,31077526033
```

Essa segunda forma usa VI=36Δq sem arredondamento e concorda com o gráfico da p.44: `35,203 x^−0,311`. O rótulo gráfico “I” deveria distinguir velocidade de infiltração de infiltração acumulada.

Se ajustar os números mm/h já arredondados na tabela: `VI=35,23646737041 T^−0,31144266188`. Diferença esperada de arredondamento dos dados.

Já a sequência manual tem erros identificáveis:

1. N=10, mas há 11 pares positivos.
2. Os logaritmos Y são de Δq em L/s; a conversão para mm/h não é mostrada na passagem ao intercepto.
3. A expressão da p.40, avaliada literalmente com os somatórios e N=10, resulta em **−0,28149503**, não −0,32.
4. A p.41 escreve `−0,51−(−0,32)×1,60=1,546`; o lado esquerdo é **0,002**, não 1,546. O intercepto 1,546 é próximo do ajuste em mm/h, mas não sai da conta impressa.
5. Pp.43/47 apresentam `VI=35,23 T^−0,32`.
6. Integrar essa última expressão com T em min dá `I=0,86348039216 T^0,68`, e não o coeficiente **0,85** impresso nas pp.46/47.

O relatório e JSON preservam as variantes: não misturar expoente de um ajuste com coeficiente de outro e chamar o resultado de reprodução exata.

### 7.5 Exemplo de manejo com 30 mm [pp.72–78]

Entradas: L=200 m, E=1 m, q=1 L/s, avanço=60 min, oportunidade indicada=140 min, total=200 min, lâmina necessária/final declarada=30 mm. Equação usada: `I=0,85 T^0,68`.

**Resultados impressos e cálculos correspondentes:**

| Grandeza | Aula | Auditoria |
|---|---:|---|
| Lm | 60 mm | Exato com 200 min; 3,33 h é arredondamento |
| Li | 31,2 mm | 0,85×200^0,68=31,19746619 mm |
| Lf | 30 mm | Incompatível com τfinal=140 min e a equação |
| Lmi | 30,6 mm | Média dos extremos adotados, não perfil integrado |
| Ed | 98% | 30/30,6×100=98,0392% |
| Ea | 50% | 30/60×100, usando Lf declarado |
| Pp | 1% | (30,6−30)/60×100 |
| Pe | 49% | (60−30,6)/60×100 |

**Inconsistência principal:** `I(140)=24,47856699 mm`. Para realmente atingir 30 mm por essa equação, `t0=(30/0,85)^(1/0,68)=188,81341045 min` e, mantendo avanço de 60 min/recessão desprezada, total **248,81341045 min**. A soma dos indicadores impressos fecha em 100%, mas isso não resolve a incompatibilidade de infiltração.

Para os tempos originais, os extremos coerentes com a equação são Li=31,19747 e Lf=24,47857 mm. Não há curva completa de avanço desse exemplo, apenas o tempo final; portanto não existe perfil exato integral dedutível sem uma hipótese adicional. Não foi inventado um perfil como se estivesse na fonte.

**Redução proposta no slide:** usar fo=7,9 mm/h, qr≈0,44 L/s, durante 140 min, após 60 min a 1 L/s.

- Sem o fator 1,1: qr=7,9×200×1/3600=0,43888889 L/s, arredondado 0,44.
- Com o fator 1,1 impresso: qr=0,48277778 L/s. A substituição numérica omite o fator.
- Com qr=0,44 e minutos exatos: Lm=60(60×1+140×0,44)/200=**36,48 mm**.
- Com 3,33 h e 2,33 h do slide: 36,4536≈**36,45 mm**.
- Com fator 1,1 e tempos exatos: Lm=**38,27666667 mm**.

Resultados impressos após redução: Ea=82,3%, Pp=1,64%, Pe=16,04%, usando Lf=30, Lmi=30,6, Lm=36,45. São reproduzíveis nessa base, mas continuam herdando o problema de Lf. Pe=16,04% também supera o limite de 10% que a própria aula indicou. A redução não deve ser marcada como atendimento integral validado apenas por Ea elevada.

### 7.6 Projeto resolvido de milho, 540×200 m [pp.89–100]

**Todos os dados de entrada:**

| Grupo | Dados |
|---|---|
| Área/relevo | 540×200 m =108.000 m²=10,8 ha; declive 0,5% na direção indicada |
| Cultura | Milho; 0,9 m entre fileiras; 0,2 m entre plantas; raiz z=50 cm; segunda quinzena de janeiro |
| Clima | ETo=6,4 mm/dia; kc=1,1; ETc adotada=7,0 mm/dia; precipitação provável=3,0 mm/dia a 80% de probabilidade |
| Demanda | 7−3=4 mm/dia, como aula |
| Solo | UCC=30,5%; UPMP=18%; Ds=1,12 g/cm³; argiloso; VIB=9 mm/h; f=0,6 |
| Ensaios | q=0,4;0,6;0,8;1,0;1,5 L/s; **1,5 L/s causou erosão** |
| Infiltração | VI=1,411 T^−0,446 L/min/m; I=2,547 T^0,554 L/m, determinados com 1 L/s |
| Operação | Jornada=14 h/dia; mudança=30 min; período adotado=10 dias |

Derivações úteis, não resultados adicionais publicados: cerca de 5,5556 plantas/m² (55.555,6 plantas/ha), supondo malha regular sem cabeceiras; 600.000 plantas na área idealizada. Esse espaçamento entre plantas não altera diretamente o NTS.

**Solo e demanda:**

```text
Capacidade total = (30,5−18)/10×1,12×50 =70 mm
IRN =70×0,6 =42 mm
TR =42/(7−3) =10,5 dias → adotados 10 dias
ETc sem arredondamento =6,4×1,1=7,04 mm/dia
TR correspondente =42/(7,04−3)=10,39603960 dias
Volume líquido =108.000×0,042=4.536 m³
```

10,5→10 dias é escolha operacional conservadora, não igualdade matemática. A precipitação provável não se converte em chuva efetiva automaticamente para outros projetos.

**Infiltração:** integrar 1,411 T^−0,446 dá coeficiente 1,411/0,554≈2,54693 L/m, coerente com 2,547. Dividir por E=0,9 para mm. `t0=(42×0,9/2,547)^(1/0,554)=130,18288437 min`, adotados 130 min. Em 130 min, a lâmina é 41,96730225 mm.

**Escolha de comprimento:** a aula compara 100 e 200 m com avanço observado/adotado de 35 e 90 min, respectivamente, para 1 L/s.

| Candidato | Tempo total adotado | Lm exata com esses tempos | Ea simplificada com 42 mm | Aula |
|---|---:|---:|---:|---|
| L=100 m | 165 min | 110 mm | 38,181818% | 110 mm;38% |
| L=200 m | 220 min | 73,333333 mm | 57,272727% | 73 mm;57% |

As fórmulas escritas na p.94 omitem o fator **60** ao usar q em L/s e T em min. Os resultados indicam que a conversão foi considerada implicitamente. Implementação deve incluí-la explicitamente.

O gráfico das pp.90/93 mostra quatro curvas para 0,4;0,6;0,8;1 L/s, mas não fornece suas equações nem séries exatas completas. O eixo horizontal está rotulado “Diâmetro”, embora seja distância/comprimento. Preservam-se as imagens e a tabela exata da p.96; não se fabricam coeficientes para as demais vazões a partir de leitura visual aproximada. A p.93 adota 35 min em 100 m, enquanto a curva ilustrada parece ficar abaixo desse ponto; para testes numéricos, prevalecem os valores escritos e tabulados, e o gráfico não é um gabarito de precisão.

**Redução de vazão:** a aula estima a demanda instantânea por trapézios na tabela p.96: aproximadamente 0,75 L/s aos 110 min. Mantém 1 L/s nos primeiros 110 min e 0,75 L/s nos últimos 110 min, total 220 min.

```text
Vaplicado =60(110×1+110×0,75)=11.550 L por sulco
Lm =11.550/(200×0,9)=64,16666667 mm
Ea simplificada =42/64,16666667×100=65,45454545%
```

Aula: Lm=64,0 mm, Ea=66%, com arredondamentos intermediários. O quadro-resumo da p.98 diz **1 L/s por 90 min e 0,75 L/s por 20 min**. Isso totaliza 110 min, contradiz pp.97/100 e gera apenas **35 mm aplicados**, abaixo dos 42 mm líquidos requeridos, mesmo com eficiência perfeita. A correção coerente com o cálculo e a narrativa é **110 min +110 min**; 90+20 é o tempo até a troca, não o evento inteiro.

**Organização operacional:**

```text
NTS =540/0,9=600 sulcos de 200 m
NSD =600/10=60 sulcos/dia
TIP =220+30=250 min=4,1666667 h
NPD contínuo =840/250=3,36
NPD adotado =3 grupos completos/dia
NSP =60/3=20 sulcos simultâneos
Q inicial =20×1=20 L/s, sem perdas de condução acrescentadas
Q reduzida =20×0,75=15 L/s
```

Três grupos com 250 min ocupam 750 min=12,5 h, restando 1,5 h da jornada de 14 h, conforme essa contagem de mudanças. 30 grupos completam a área em 10 dias. O consumo total do cronograma de redução é 600×11,55=6.930 m³ por ciclo; o líquido necessário é 4.536 m³. Não é correto usar 20 L/s como vazão média constante durante todo o evento reduzido.

**Perfil adicional para teste:** o pacote inclui interpolação linear entre os 11 pontos de avanço da p.96, recessão desprezada em 220 min e I=(2,547/0,9)τ^0,554. Isso é hipótese de reconstrução identificada. Em 1.000 segmentos: Lmi≈50,39121 mm; no caso constante, Ea_integral≈57,27269%, Pp≈11,44260%, Pe≈31,28471%; na redução, mantendo condicionalmente o mesmo perfil, Ea≈65,45450%, Pp≈13,07726%, Pe≈21,46824%. Esses indicadores adicionais não estão nos slides. O mínimo final 41,9673 mm revela pequeno déficit em relação a 42 por arredondamento do tempo. A manutenção do perfil após redução exige água suficiente ao longo do sulco; não é previsão hidrodinâmica resolvida.

### 7.7 Exercício de projeto da p.101: solução formal e limitações

Entradas: área 400×400 m=16 ha; milho E=1 m, z=50 cm, f=0,5, ETm=4,2 mm/dia; UCC=28%, UPMP=17%, Ds=1,4 g/cm³, VIB=9 mm/h. Duas direções indicadas: 0,5% e 0,1%. q=1 L/s, C=0,631, a_erosão=1. `ta=0,0019 L^1,96` em min; `VI=36 T^−0,32` em mm/h, T em min. Não há solução fornecida, jornada, tempo de mudança, chuva efetiva ou vazão disponível total.

**Recalculado a partir das expressões:**

```text
Capacidade total =(28−17)/10×1,4×50=77 mm
IRN =77×0,5=38,5 mm
I(T)=36/[60×0,68] T^0,68=0,88235294118 T^0,68 mm
t0=(38,5/0,88235294118)^(1/0,68)=257,92749189 min
TR sem chuva =38,5/4,2=9,16666667 dias
qmax(0,5%)=1,262 L/s; qmax(0,1%)=6,31 L/s
Lmax pela regra de 1/4≈204,91487771 m
```

Adotar comprimento submúltiplo de 400 m abaixo desse limite levaria a **200 m**, como decisão operacional derivada, não resposta oficial. Ambos os declives permitem 1 L/s pela expressão simplificada; o PDF não resolve qual direção selecionar, nem informa a qual declive foi calibrada a equação de avanço. Não usar a mesma curva para ambas as orientações sem ressalva.

| L candidato | ta (min) | ti formal (min) | Lm (mm) | Ea simplificada | NTS |
|---:|---:|---:|---:|---:|---:|
| 100 m | 15,80351 | 273,73100 | 164,23860 | 23,44150% | 1.600 |
| 200 m | 61,48546 | 319,41295 | 95,82388 | 40,17787% | 800 |
| 400 m | 239,21653 | 497,14402 | 74,57160 | 51,62823% | 400 |

Todos são cálculos formais com a mesma curva fornecida. O de 400 m não atende a regra prática de 1/4, mas tem Ea simplificada maior que 200 m; isso ilustra por que a regra não equivale a otimização. Não é seleção automática de projeto.

**Inconsistência física interna importante:** VI=36 T^−0,32 cai abaixo de VIB=9 mm/h a partir de **76,10925536 min**. No t0 calculado, VI≈**6,09008365 mm/h**, inferior à VIB informada. Portanto, a lei potencial e a VIB não são simultaneamente compatíveis nessa duração como modelo assintótico. O aplicativo deve marcar os resultados como formais sob a lei da aula e pedir calibração/definição do modelo; não acrescentar uma parcela básica sem recalibrar.

É possível calcular IRN, oportunidade formal, limites empíricos, tempos e contagens. Não é possível fechar a vazão total do projeto/cronograma sem jornada, mudança, PI adotado e informações de disponibilidade. O pacote não inventa esses dados para obter uma resposta única.

## 8. Diagnóstico e manejo: todo o conteúdo qualitativo aproveitável

### 8.1 Causas de desempenho insatisfatório [pp.60,66–67]

Excesso pode causar percolação, escoamento, lixiviação de nutrientes e elevação do lençol freático. Déficit/desuniformidade pode combinar excesso no início e deficiência no final.

Problemas de uniformidade listados: comprimento excessivo, vazão ou tempo reduzidos; sistematização grosseira e gradiente variável; variação de textura, estrutura, superfície e umidade; compactação diferencial natural ou por tráfego; mudanças na seção por erosão/tratos culturais; erosão de irrigação/chuva; resistência variável por plantas e manejo da superfície.

Problemas de eficiência: comprimento muito curto ou longo; vazão muito baixa ou alta; duração insuficiente ou excessiva; alteração da infiltração entre irrigações; operação inadequada. O app pode guardar histórico por evento, em vez de tratar um único ensaio como invariável para toda a safra.

### 8.2 Ações listadas e seus objetivos [pp.68–71]

| Objetivo | Medidas sugeridas no PDF |
|---|---|
| Aumentar uniformidade | Aumentar vazão; aumentar duração; reduzir comprimento; aumentar gradiente; diques ao final; fluxo pulsante com períodos curtos alternados |
| Reduzir percolação | Aumentar vazão para avanço mais rápido; reduzir duração e comprimento; aumentar gradiente; reduzir infiltração por compactação superficial; reduzir perímetro molhado |
| Reduzir escoamento | Reduzir vazão após chegada ao final; reduzir duração; aumentar comprimento; reduzir gradiente; aumentar infiltração com matéria orgânica/revolvimento; aumentar perímetro molhado; conter água ao final; reutilizar deflúvio |
| Aumentar armazenamento | Reduzir vazão conforme orientação do slide; aumentar duração; reduzir comprimento e gradiente; aumentar infiltração/perímetro molhado; contenção ao final |

São direções de manejo sujeitas a compensações, não comandos automaticamente benéficos. Aumentar vazão pode reduzir percolação e aumentar escoamento; aumentar duração pode melhorar atendimento e aumentar perdas. Só recomendar uma alteração quantitativa após reavaliar domínio, erosão, perfil, balanço e atendimento. O PDF não fornece coeficientes que permitam prever numericamente a mudança de infiltração por compactação ou matéria orgânica.

Reuso muda a interpretação da saída superficial: saída do sulco continua sendo deflúvio, mas pode não ser perda definitiva do projeto. Separar balanço da parcela e do sistema. Fluxo pulsante aparece como opção de manejo, sem equações de ciclos, razão ligado/desligado ou infiltração alterada; não habilitar como simulação completa apenas com esta aula.

## 9. Requisitos concretos para o aplicativo

### 9.1 Módulos possíveis com o material

1. Catálogo de tipos e consulta de declividade/geométricas com origem por página.
2. Consulta de corrugação por classe de raízes, textura e declive.
3. Ajuste de avanço por dois pontos ou regressão logarítmica, com inversa e interpolação.
4. Processamento de ensaio de entrada/saída e conversão de unidade de infiltração.
5. Integração da taxa potencial e cálculo da oportunidade para uma lâmina.
6. Verificação empírica de vazão não erosiva.
7. Cálculo da lâmina aplicada com vazão constante ou por etapas.
8. Perfil empírico com curva de avanço fornecida e hipótese explícita de recessão.
9. Indicadores simplificados da aula e indicadores integrais identificados separadamente.
10. Vazão reduzida estimada por taxa básica ou somatório espacial.
11. Balanço de solo, turno e organização inteira de sulcos/parcelas.
12. Auditoria dos exemplos, com “valor da aula” e “recalculado” lado a lado.

### 9.2 Dados a cadastrar

Área e orientação; declive de terreno e de sulco; tipo; comprimento; seção/profundidade/largura; espaçamento E; classe de solo; infiltração e suas unidades; profundidade radicular; base gravimétrica/volumétrica da umidade; UCC/UPMP/Ds/f; cultura e ET; chuva efetiva; vazão disponível; erosão observada; hidrograma; dispositivos; pontos de avanço/recessão; jornada; mudança; PI; perdas de condução; fonte de cada valor; tolerâncias e método.

Preservar valor bruto, valor normalizado, unidade, página, status e hipótese. Não depender de nomes ambíguos como `a`, `L` e `Tr` na interface ou API.

### 9.3 Validações obrigatórias propostas

- Valores finitos; dimensões, coeficientes positivos quando exigidos; f em (0,1]; UCC>UPMP; unidade da umidade explícita.
- Logaritmos apenas para pares positivos; N calculado a partir das observações efetivamente utilizadas; não usar N digitado do slide.
- Distâncias crescentes e tempos de avanço não decrescentes. Dois pontos exigem x2>x1 e t2>t1.
- Sem extrapolação silenciosa das tabelas/curvas. Extrapolação de ensaio deve vir marcada, com domínio de calibração.
- τ≥0 para acumulada; τ>0 para taxa de expoente negativo. Se recessão vier antes do avanço, rejeitar.
- Expoente de VI>−1 para integrar a partir de zero; valores singulares não são zeros.
- S_percent>0 no limite erosivo. Não aplicar a expressão a sulcos em nível.
- 0≤Treduzida≤Ttotal e soma das etapas igual ao tempo total; vazões não negativas.
- Mudança de vazão antes da chegada ao final exige modelo capaz de recalcular avanço; não reutilizar a curva de vazão constante sem hipótese.
- Vazão com erosão observada deve ser rejeitada para aquele ensaio/condição.
- Comparar VI e VIB no domínio simulado; alertar quando conflitarem.
- Indicadores de perda negativos ou balanço impossível devem gerar diagnóstico, não arredondamento/clamp corretivo.
- Verificar atendimento local da IRN, não apenas média ou soma dos percentuais.
- Condução: 0<Ec≤100, perdas em unidade definida. Reuso registrado em balanço separado.
- NTS/NSP/grupos devem ser inteiros; NPD bruto pode ser real, mas grupos completos usam piso; dimensionar capacidade suficiente com teto.
- PI não deve exceder o turno adotado sem justificativa; TDF deve comportar TIP; demanda de vazão não deve exceder disponibilidade.
- Ausência de parâmetro é `null/nao_informado`, nunca zero implícito.

### 9.4 Saídas e visualizações recomendadas

Curva de avanço medida e ajustada; resíduos; curva VI e I em painéis separados; perfil espacial e linha IRN; déficit/percolação; hidrograma antes/depois da redução; volumes útil/percolado/escoado; comparação de candidatos; mapa de sulcos/parcelas; cronograma por grupo; quadro de avisos com página e fórmula. Não apresentar animação empírica interpolada como solução de dinâmica de fluidos.

Status: `valor_transcrito`, `recalculado`, `hipotese`, `fora_da_faixa_orientativa`, `dado_ausente`, `conflito_na_fonte`, `fora_do_dominio`, `balanco_inconsistente`, `formal_com_alerta_VIB`, `valido_no_modelo`. Este último significa somente consistência nas hipóteses declaradas.

## 10. Registro consolidado de inconsistências

| ID | Páginas | Achado | Ação |
|---|---|---|---|
| S01 | 3,7 | <2% geral versus corrugados até 15% | Critérios por tipo |
| S02 | 10–14 | Sem limites ideal/aconselhável/usável para nível/zigue-zague | Manter não informado |
| S03 | 25–26 | Dois pontos e regressão têm coeficientes diferentes | Identificar método; não tratar como mesmo ajuste |
| S04 | 28 | Intercepto com n em vez de b | Normalizar A=ȳ−b x̄ |
| S05 | 29–34 | Arredondamentos e 10^−1,93≠0,011 como escrito | Recalcular dos dados brutos |
| S06 | 36–38 | b=1,39 truncado altera k e resultados | Preservar versão do slide e precisão completa |
| S07 | 40 | N=10 para 11 pares positivos | N automático=11 |
| S08 | 40–44 | Log de Δq misturado com coeficiente em mm/h | Converter unidades explicitamente |
| S09 | 40 | Conta impressa dá −0,281495, não −0,32 | Expor erro aritmético |
| S10 | 41 | −0,51+0,512=0,002, não 1,546 | Não usar a conta como teste esperado correto |
| S11 | 43–47 | Lei VI e acumulada não integram exatamente | 35,23/(60×0,68)=0,86348039; guardar 0,85 como impresso |
| S12 | 44 | Gráfico chama taxa de “I” | Separar taxa e acumulada |
| S13 | 50 | Tr/Td podem significar duração ou instante | Usar tempos absolutos e durações distintos |
| S14 | 58 | Igualdade entre médias não geral | Integrar perfil; aproximação dos extremos identificada |
| S15 | 59 | Tr “múltiplo” de Tt, embora duração parcial | Não impor condição impossível; fração operacional explícita |
| S16 | 63,75 | Ideal >70% versus >75% | Critério versionado por página |
| S17 | 64 | “Útil” com GA>100% e média ideal ambígua | Separar razão e fração atendida |
| S18 | 72–74 | 140 min não infiltram 30 mm pela equação | Resultado 24,47857 mm; tempo-alvo 188,81341 min |
| S19 | 77 | Fator 1,1 desaparece na substituição | Duas variantes rastreadas |
| S20 | 77–78 | Arredondamento de horas altera Lm | Calcular internamente em minutos |
| S21 | 90,93 | Eixo “Diâmetro” e curva ilustrativa sem dados exatos | Tratar como distância; usar pontos explícitos |
| S22 | 92 | 10,5 dias=10 dias | Registrar adoção operacional, não igualdade |
| S23 | 94 | Falta fator 60 escrito | Conversão obrigatória |
| S24 | 96 | “Total infiltrado” é vazão; soma ligeiramente diferente | Unidade L/min; recomputar sem arredondar |
| S25 | 98 | Parênteses omitidos na forma de Lm | Usar [(Tt−Tr)qi+Tr qr] |
| S26 | 98 | Resumo 90+20 min contradiz 220 min e troca aos110 | Corrigir para110+110, identificado como correção |
| S27 | 98 | 66% com arredondamentos versus65,4545% exato | Dois valores identificados |
| S28 | 101 | VI potencial abaixo da VIB em tempos relevantes | Resultado formal; modelo/calibração pendente |
| S29 | 101 | Duas direções de declive sem escolha/calibração da curva | Não atribuir curva automaticamente a ambas |
| S30 | 86 | PC sem unidade explícita | Exigir unidade de vazão ou eficiência de condução |

## 11. Limitações que impedem promessas excessivas

Não há modelo numérico completo para tabuleiros, sulcos fechados, zigue-zague, quadras/dentes, pulso, reuso ou recessão detalhada. Não há Manning, rugosidade, equação de seção para dimensionamento hidráulico completo ou erosão por tensão de arraste. Não há relação geral q→curva de avanço; ensaios são específicos. Não há limites de velocidade, dimensionamento de tubos/sifões, perdas de carga, bombeamento, chuva de projeto, drenagem ou volume de reservatório de reuso. Não há modelo de variabilidade espacial do solo, salinidade ou transporte de nutrientes. As práticas qualitativas não fornecem efeitos quantitativos calibrados.

O exemplo resolvido permite reconstituir o cronograma. O exercício final permite uma solução matemática parcial, mas não fechar o projeto operacional nem resolver a incompatibilidade VI/VIB sem informação adicional. Nenhum dado ausente foi preenchido com um suposto valor oficial.

## 12. Cobertura página a página

| Páginas | Conteúdo capturado |
|---|---|
| 1 | Autoria, instituição, título |
| 2 | Definição, infiltração na zona radicular e sistematização |
| 3–4 | Características,30–80%,<2%,custo histórico e condições |
| 5 | Sulcos comuns, três classes de declive e dimensões |
| 6 | Contorno, declives,70–150 m, enxurrada e restrição de chuva |
| 7–8 | Corrugados, declives,vazão,seção,profundidade,espaçamento,culturas |
| 9 | Tabela completa por raiz,textura e declive |
| 10 | Primeiro tipo em nível,tabuleiros,E≈1 m,culturas e saída |
| 11 | Segundo tipo em nível,fechamento e enchimento |
| 12–14 | Zigue-zague, usos, variantes de videiras/frutíferas,quadras e dentes |
| 15–16 | Distribuição por sifões,bacias auxiliares,tubos janelados; fotografias |
| 17 | Separador de dimensionamento |
| 18–19 | Fases,instantes e oportunidade local; diagrama qualitativo |
| 20 | Separador da fase de avanço |
| 21 | Criddle,ta=t0/4 e alternativa por eficiência |
| 22–24 | Potência,linearização e dois pontos |
| 25–26 | Conjunto A, solução arredondada e regressão gráfica |
| 27–28 | Mínimos quadrados,intercepto e antilog |
| 29–34 | Conjunto B, tabela transformada, cálculos e curva |
| 35–38 | Exercício 60/120 m e resultados de80 m/53 min |
| 39 | Ensaio entrada/saída,100 m,E=1 m,tabela de taxas |
| 40–44 | Tabela logarítmica,regressão e erros de contagem/unidade |
| 45–47 | Integração da taxa e equações finais |
| 48 | Separador reposição/depleção/recesso |
| 49–50 | Reposição,reuso,tempo de corte e oportunidade |
| 51 | Fatores de comprimento e regra prática |
| 52–53 | Espaçamento,regra2z e molhamento qualitativo por solo |
| 54 | Seção V,20–30 cm de largura,15–25 cm de profundidade |
| 55–56 | Vazão usual,coeficientes por textura e expressão simplificada |
| 57–59 | Lâminas constante,média infiltrada,redução e nota sobre tempos |
| 60 | Excesso/déficit e indicadores |
| 61–65 | Ec,Ed,Ea,GA,Pp,Pe e critérios |
| 66–67 | Causas de uniformidade/eficiência insatisfatórias |
| 68–71 | Manejo por objetivo,fluxo pulsante,contenção e reuso |
| 72–78 | Exemplo30 mm,índices,redução e auditoria |
| 79 | ti=t0+ta sob recessão desprezada |
| 80 | Turno por CRA,ETc e chuva efetiva |
| 81–86 | NTS,NSD,TIP,NPD,NSP e vazão do projeto |
| 87–88 | Separador e sequência de dimensionamento |
| 89 | Entradas completas do projeto de milho540×200 m |
| 90 | Vazões de ensaio,erosão em1,5 L/s e curvas ilustrativas |
| 91 | VI e I em base por metro de sulco |
| 92 | IRN42 mm e turno10,5→10 dias |
| 93–95 | Comparação100/200 m,t0,ti,Lm,Ea e redução proposta |
| 96 | Tabela integral do somatório aos110 min |
| 97–98 | Troca aos110 min,qr0,75,índices e resumo contraditório |
| 99–100 |600 sulcos,60/dia,20 simultâneos,20 L/s |
| 101 | Exercício400×400 m,curvas e dados,sem solução impressa |

## 13. Arquivos, reprodução e testes

O pacote inclui este relatório, `dados_extraidos.json`, `catalogo_formulas.json`, `resultados_referencia.json`, quatro perfis em CSV, `nucleo_sulcos.py`, `gerar_referencias.py`, `testar_sulcos.py`, saída dos testes, texto extraível organizado por página e evidências visuais das páginas técnicas. O texto bruto não contém todas as fórmulas em imagem; a transcrição técnica está neste relatório.

Com Python 3, na pasta do pacote:

```bash
python3 gerar_referencias.py
python3 testar_sulcos.py
```

Nenhuma biblioteca externa é necessária. O núcleo calcula ajustes, integra taxas, converte unidades, avalia perfis e organiza contagens inteiras. Não resolve dinamicamente o escoamento nem altera automaticamente a curva quando q muda. Os perfis reconstruídos e os indicadores integrais são extensões identificadas.

Os testes conferem casos exatos, conversões, inversão, integração/derivação, balanço, contagens, domínios inválidos e divergências do documento. Há testes que **confirmam que um número do slide não coincide com sua própria fórmula**; passar nesses testes significa detectar o problema, não validar o número incorreto.
