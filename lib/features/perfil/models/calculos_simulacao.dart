/// Catálogo dos cálculos que a interface expõe, agrupados por método.
///
/// O texto é estático: serve para o usuário entender, na tela de perfil,
/// o que cada módulo de irrigação calcula e com qual(s) equação(ões).
class CalculoModulo {
  final String titulo;
  final String descricao;

  /// Equações do cálculo, em texto plano (uma linha por equação).
  final String? formula;

  const CalculoModulo(this.titulo, this.descricao, {this.formula});
}

class ConteudoCalculos {
  final String metodo;
  final List<CalculoModulo> calculos;

  const ConteudoCalculos({required this.metodo, required this.calculos});
}

class CalculosSimulacao {
  CalculosSimulacao._();

  static const List<ConteudoCalculos> modulos = [
    ConteudoCalculos(
      metodo: 'Sulcos',
      calculos: [
        CalculoModulo(
          'Curva de avanço',
          'Advance com a lei potencial tempo × distância, ajustada por dois '
              'pontos ou por regressão de mínimos quadrados sobre o ensaio de '
              'estacas.',
          formula: 'Tx = k · xᵇ',
        ),
        CalculoModulo(
          'Infiltração acumulada (Kostiakov–Lewis)',
          'Conversões de velocidade conforme a unidade informada e a largura '
              'entre sulcos; calibrável por ensaio de entrada e saída.',
          formula:
              'I = k·tᵃ + f0·t\n'
              'VI = K·Tⁿ\n'
              'I = K/(60·(n+1)) · Tⁿ⁺¹',
        ),
        CalculoModulo(
          'Desempenho da irrigação',
          'Eficiência com vazão constante ou reduzida, eficiência de condução '
              '(Ec) e de distribuição (Ed), além das perdas por percolação e '
              'escoamento.',
          formula:
              'Ec = (Va/Vd) · 100\n'
              'Ed = Lf / ((Li+Lf)/2) · 100\n'
              'Ea = (Lf/Lm) · 100\n'
              'Pp = (Lmi − LL)/Lm · 100\n'
              'Pe = (Lm − Lmi)/Lm · 100',
        ),
        CalculoModulo(
          'Seleção do comprimento',
          'Compara alternativas de comprimento usando a regra prática de '
              'Criddle: tempo de aplicação × tempo de oportunidade requerido no '
              'final.',
          formula: 'Ta = ¼ · To',
        ),
        CalculoModulo(
          'Teto de vazão não erosiva',
          'qmax por classe de textura e declive; o ensaio de erosão medido em '
              'campo prevalece sobre a estimativa empírica.',
          formula:
              'qmax = c / Sᵅ\n'
              'qmax ≈ 0,631 / S',
        ),
        CalculoModulo(
          'Manejo com vazão reduzida',
          'Demanda instantânea estimada por trapézios; após a troca de vazão '
              'o perfil considera apenas a manutenção da cobertura.',
          formula:
              'Lm = ((Tt − Tr)·qi + Tr·qr)/(C·L) · 3600\n'
              'Qr = 1,1 · f0·L·E / 3600',
        ),
        CalculoModulo(
          'Planejamento operacional',
          'Integrados com jornada diária, tempo de mudança entre parcelas e '
              'perdas de condução.',
          formula:
              'NTS = (Lt·Wt)/(L·E)\n'
              'NSD = NTS/PI\n'
              'NPD = TDF/TIP\n'
              'Q = NSP·Q0 + PC',
        ),
      ],
    ),
    ConteudoCalculos(
      metodo: 'Faixas',
      calculos: [
        CalculoModulo(
          'Simulação hidráulica da faixa',
          'Evolução da lâmina durante o avanço e a recessão, com integração '
              'numérica configurável por passos, tolerâncias e método de '
              'integração definidos no projeto.',
          formula:
              'Q0·tx = 0,77·A0·L + σz·k·txᵃ·L + VIB·tx·L/(1+r)\n'
              'σz = (a + r(1−a) + 1)/((1+a)(1+r))',
        ),
        CalculoModulo(
          'Recessão e tempos da lâmina',
          'Recessão com expoentes da revisão e a separação entre tr = t0 + ta '
              'e ti calculado em separado.',
          formula:
              'tr − td = 0,095·n^0,476·Sy^0,207·L^0,683 / (VIM^0,524·S0^0,238)\n'
              'tr = ti = to + ta',
        ),
        CalculoModulo(
          'Infiltração e lâmina alvo',
          'Curva de Kostiakov–Lewis para o tempo de oportunidade alvo e '
              'infiltração final If do balanço.',
          formula:
              'I = k·toᵃ + VIB·to\n'
              'If = k·(tr − ta)ᵃ + VIB·(tr − ta)',
        ),
        CalculoModulo(
          'Ensaio de campo',
          'Estacas de avanço medidas em campo entrando na avaliação sem '
              'depender do modelo simulado.',
          formula: 'x = p · taʳ',
        ),
        CalculoModulo(
          'Verificação espacial do aproveitamento',
          'Aproveitamento da água aplicada por metro de largura da faixa.',
          formula: 'Er = ((IRN·Xa + Vd)/(IRN·L)) · 100',
        ),
        CalculoModulo(
          'Limite não erosivo (auditoria)',
          'A alternativa de velocidade máxima fica bloqueada no cálculo por '
              'falta de unidades e é mostrada apenas como auditoria.',
          formula: 'Qmax = 0,01059 · S0^−0,75',
        ),
        CalculoModulo(
          'Balanço, IRN e turno de rega',
          'Precipitação efetiva, ETo pelo Blaney–Criddle, IRN e intervalo '
              'mínimo entre irrigações; IRN interpretada como lâmina após '
              'conversão de unidades.',
          formula:
              'Ea = (IRN·L)/(Q0·ti) · 100\n'
              'Pp = (Va − IRN·Xa)/(Q0·ti) · 100',
        ),
        CalculoModulo(
          'Limites geométricos',
          'Desnível transversal e largura máxima quando há declive '
              'transversal; agenda do planejamento operacional.',
          formula:
              'D ≤ 2/5 · hm ≤ 4 cm\n'
              'L = D/St',
        ),
      ],
    ),
    ConteudoCalculos(
      metodo: 'Inundação',
      calculos: [
        CalculoModulo(
          'IRN calculada',
          'Lâmina requerida integrada ao balanço demanda × precipitação '
              'efetiva, com turno de rega por DTA e profundidade do solo.',
          formula:
              'I0 = k·taᵃ + VIB·ta + 0,80·y0 + Q0·(ti − ta)/L\n'
              'ti = (IRN·L − 0,8·y0·L)/Q0 + ta',
        ),
        CalculoModulo(
          'Guia de área × vazão e Henderson',
          'Classes de solo como guia inicial e relação de Henderson para a '
              'área em m²; nenhuma delas substitui o cálculo.',
          formula: 'A = 100 · Q/VIB',
        ),
        CalculoModulo(
          'Tabela de sifões e tubos',
          'Vazões de referência de sifões/tubos para a derivação por '
              'dispositivos.',
        ),
        CalculoModulo(
          'Recessão e desnível admissível',
          'Regra dos 2/3 do desnível e comprimento com exemplos de '
              'declividade.',
          formula:
              'Z < ⅔ · Lm\n'
              'L = Δz/S\n'
              'Lm = (Li + Lf)/2',
        ),
        CalculoModulo(
          'Volume residual (bisseção / Newton)',
          'Balanço por metro de largura na taxa final da curva, resolvido por '
              'bisseção com alternativa de Newton–Raphson.',
          formula: 'tx(i+1) = tx(i) − corr',
        ),
        CalculoModulo(
          'Infiltração e lâminas do tabuleiro',
          'Infiltração no início do tabuleiro, lâmina média e limite de '
              'erosão.',
          formula:
              'y0 = (Q0²·n²·X/3600)^0,23\n'
              'Lm = (Li + Lf)/2\n'
              'Q0max = (Vmax^13/3·n²·L/3600)^3/7',
        ),
        CalculoModulo(
          'Regime permanente',
          'Ea com período semanal e Ec pela vazão de manutenção, com '
              'declividade validada abaixo de 2%.',
          formula:
              'Ea = (Les/Las) · 100\n'
              'Ec = Qm/Qd · 100\n'
              'Las = Qm·ti/A · 3600',
        ),
        CalculoModulo(
          'Seleção de vazão e agenda',
          'Candidatas informadas ou derivadas, escolhidas pela melhor Ea; '
              'planejamento em parcelas e turno de rega.',
          formula:
              'Q = W0·NTP·Q0\n'
              'NTT = NTP·NPD·PI\n'
              'APP = área/(NPD·PI)',
        ),
        CalculoModulo(
          'Volumes de água do arroz',
          'Transformação da produção em sacos/ha e volumes por ciclo de '
              'cultivo.',
        ),
      ],
    ),
    ConteudoCalculos(
      metodo: 'Base comum',
      calculos: [
        CalculoModulo(
          'Classificação dos métodos',
          'Grupos de irrigação, sistemas de cada grupo e fatores de escolha.',
        ),
        CalculoModulo(
          'Demanda hídrica',
          'ETo pelo Blaney–Criddle em base diária (fator p pelo fotoperíodo), '
              'coeficiente de cultura, precipitação efetiva, IRN e turno de rega.',
          formula:
              'TR = CRA/(ETc − Pe)\n'
              'IRN = Σ demanda − Pe',
        ),
        CalculoModulo(
          'Infiltração e indicadores de desempenho',
          'Kostiakov–Lewis e os pares Ea/CUC/DU exibidos em todas as telas de '
              'resultado.',
          formula: 'I = k·tᵃ + f0·t',
        ),
        CalculoModulo(
          'Transparência de cálculo',
          'Os módulos não presumem dado ausente: lacunas ficam visíveis e '
              'cada resultado indica a hipótese adotada.',
        ),
      ],
    ),
  ];
}
