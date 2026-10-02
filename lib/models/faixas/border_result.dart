import 'border_numeric.dart';

/// Status canônicos da extração §10.3. O código snake_case é o que circula em
/// CSV, cenário salvo e camada de entrada/candidato/ensaio/célula de tabela;
/// a mensagem humana fica ao lado do código, nunca no lugar dele.
enum BorderStatus {
  validoNoModelo('valido_no_modelo'),
  avisoOrientativo('aviso_orientativo'),
  entradaInvalida('entrada_invalida'),
  foraDoDominio('fora_do_dominio'),
  semConvergencia('sem_convergencia'),
  balancoInconsistente('balanco_inconsistente'),
  dadoFonteSuspeito('dado_fonte_suspeito'),
  modeloNaoImplementado('modelo_nao_implementado');

  const BorderStatus(this.codigo);

  final String codigo;

  /// Lê código canônico ou nome de enum legado (resultados das versões 0/1).
  static BorderStatus deNome(String? nome) {
    if (nome == null) return validoNoModelo;
    for (final status in values) {
      if (status.codigo == nome || status.name == nome) return status;
    }
    return switch (nome) {
      'calculado' => validoNoModelo,
      'geometriaPendente' => entradaInvalida,
      'geometriaIncompativel' => foraDoDominio,
      _ => validoNoModelo,
    };
  }

  /// Ordem de gravidade usada para combinar avisos de uma mesma execução.
  static const severidade = <BorderStatus>[
    entradaInvalida,
    foraDoDominio,
    balancoInconsistente,
    semConvergencia,
    modeloNaoImplementado,
    dadoFonteSuspeito,
    avisoOrientativo,
    validoNoModelo,
  ];

  /// Pior status presente; lista vazia resulta em `valido_no_modelo`.
  static BorderStatus pior(Iterable<BorderStatus> statuses) {
    for (final status in severidade) {
      if (statuses.contains(status)) return status;
    }
    return validoNoModelo;
  }

  /// Somente `valido_no_modelo` e `aviso_orientativo` deixam o resultado
  /// utilizável sem ressalva bloqueante.
  bool get bloqueia => this != validoNoModelo && this != avisoOrientativo;
}

/// Aviso tipado: status + mensagem + página da fonte quando houver.
class BorderNotice {
  final BorderStatus status;
  final String mensagem;
  final String? pagina;
  const BorderNotice(this.status, this.mensagem, {this.pagina});

  String get codigo => status.codigo;

  Map<String, dynamic> toMap() => {
    'status': status.codigo,
    'mensagem': mensagem,
    'pagina': pagina,
  };

  /// Aceita mapa novo e texto de aviso legado (que vira aviso orientativo).
  factory BorderNotice.fromMap(Object? data) {
    if (data is String) return BorderNotice(BorderStatus.avisoOrientativo, data);
    if (data is! Map) {
      throw const FormatException('Aviso de faixa em formato desconhecido.');
    }
    final map = Map<String, dynamic>.from(data);
    final mensagem = map['mensagem'];
    if (mensagem is! String) {
      throw const FormatException('Aviso de faixa sem mensagem.');
    }
    return BorderNotice(
      BorderStatus.deNome(map['status'] as String?),
      mensagem,
      pagina: map['pagina'] as String?,
    );
  }
}

/// Erro de domínio/convergência do motor de faixas com código canônico e
/// página da fonte; continua sendo `FormatException` para os tratadores
/// existentes que só precisam da mensagem.
class BorderModelException extends FormatException {
  final BorderStatus status;
  final String? pagina;
  const BorderModelException(this.status, String mensagem, {this.pagina})
    : super(mensagem);

  String get mensagem => message;
  String get codigo => status.codigo;
  BorderNotice get aviso => BorderNotice(status, mensagem, pagina: pagina);
}

/// Origem declarada do valor/fórmula conforme §10.1.
enum BorderOrigemFonte { medida, assumida, derivada }

/// Proveniência de uma fórmula usada: documento, página, versão e origem.
class BorderFormulaFonte {
  final String id;
  final String descricao;
  final String pagina;
  final String versao;
  final BorderOrigemFonte origem;
  const BorderFormulaFonte(
    this.id,
    this.descricao,
    this.pagina,
    this.versao,
    this.origem,
  );
}

class BorderProfilePoint {
  final double xM, avancoMin, recessaoMin, oportunidadeMin, infiltracaoM;
  const BorderProfilePoint(
    this.xM,
    this.avancoMin,
    this.recessaoMin,
    this.oportunidadeMin,
    this.infiltracaoM,
  );
}

/// Divisão do volume infiltrado (por metro de largura) em relação à IRN.
class BorderVolumes {
  final double utilM3M, percoladoM3M, deficitM3M;
  /// Comprimento total (inclusive blocos não contíguos) com infiltração ≥ IRN.
  final double comprimentoAdequadoM;
  const BorderVolumes(this.utilM3M, this.percoladoM3M, this.deficitM3M,
      [this.comprimentoAdequadoM = 0]);
}

/// Resultado hidráulico por metro de largura; volumes totais multiplicam W uma vez.
class BorderResult {
  /// Selo do escopo realmente executado (F01–F32), com a versão dos expoentes
  /// da recessão adotada na p.43.
  static const versaoEquacoes = 'faixas-F01-F32-p43-v2';
  static const documentoFonte = 'Aula 7 - Irrigação por faixas.pdf';
  static const paginasFonte = 'Aula 7, pp. 12–73 por bloco';

  /// Páginas da extração por bloco de fórmulas executadas.
  static const blocosFonte = <String, String>{
    'F01–F05 vazão, comprimento e profundidade': 'pp. 53–55',
    'F06–F07 infiltração e oportunidade': 'pp. 47, 56',
    'F09–F12 avanço': 'pp. 45, 57–62',
    'F14–F20 depleção e recessão': 'pp. 43–45, 62–66',
    'F22–F25 perfil, integração e eficiência': 'pp. 46–47, 64, 67–68',
    'F26 busca em vazão': 'p. 67',
    'F27–F32 organização do projeto': 'pp. 69–71',
    'Tabelas Marr e Booher': 'pp. 20, 26',
  };

  /// Proveniência das fórmulas usadas por este motor.
  static const proveniencia = <BorderFormulaFonte>[
    BorderFormulaFonte(
      'F01',
      'Hart et al. (1980) — vazão de projeto, reprodução literal',
      'p. 53',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F03',
      'Walker e Skogerboe (1984) — vazão mínima sugerida',
      'pp. 53–55',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F04',
      'Limite de comprimento L ≤ qmax/VIB',
      'pp. 53–55',
      'única',
      BorderOrigemFonte.assumida,
    ),
    BorderFormulaFonte(
      'F05',
      'Profundidade na entrada y0',
      'pp. 53–55',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F06',
      'Kostiakov–Lewis I(τ) = k τ^a + VIB τ',
      'pp. 47, 56',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F07',
      'Oportunidade alvo por Newton–Raphson',
      'pp. 47, 56',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F08',
      'Lei de avanço ajustada a dados de campo (ensaio medido)',
      'pp. 45, 57–62',
      'única',
      BorderOrigemFonte.medida,
    ),
    BorderFormulaFonte(
      'F09',
      'Balanço volumétrico do avanço até a distância X',
      'pp. 45, 57–62',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F10',
      'Fator de forma σz',
      'pp. 45, 57–62',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F11',
      'Newton para o avanço',
      'pp. 45, 57–62',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F12',
      'Iteração de r por ln 2 / ln(ta/tm)',
      'p. 58',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F14',
      'Relação entre corte ti e término da depleção td',
      'p. 64',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F15',
      'Velocidade média no instante td',
      'pp. 43–45, 62–66',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F16',
      'Vazão residual qf, profundidade final e Sy',
      'p. 44',
      'divisão',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F17',
      'Duração da recessão, Strelkoff (1977)',
      'p. 43',
      'p43',
      BorderOrigemFonte.assumida,
    ),
    BorderFormulaFonte(
      'F18',
      'Recessão alvo tr = td + Δtr',
      'p. 66',
      'p43',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F19',
      'Iteração de td até o alvo de oportunidade',
      'p. 66',
      'p43',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F20',
      'Verificação e correção de oportunidade na entrada',
      'pp. 62, 64',
      'p43',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F22',
      'Recessão linear e perfil τ(x)',
      'pp. 45, 68',
      'única',
      BorderOrigemFonte.assumida,
    ),
    BorderFormulaFonte(
      'F23',
      'Regra dos trapézios sobre I(x)',
      'p. 47',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F24',
      'Avaliação por regiões (déficit e área atendida)',
      'p. 46',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F25',
      'Eficiência simplificada de dimensionamento',
      'pp. 64, 67',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'F26',
      'Busca discreta em vazão por Δq',
      'p. 67',
      'única',
      BorderOrigemFonte.assumida,
    ),
    BorderFormulaFonte(
      'F27–F32',
      'TIP, NPD, APP, W0, NTF e Qt da organização do projeto',
      'pp. 69–71',
      'única',
      BorderOrigemFonte.assumida,
    ),
    BorderFormulaFonte(
      'Marr',
      'Tabela de sugestões de dimensionamento (1958)',
      'p. 20',
      'única',
      BorderOrigemFonte.medida,
    ),
    BorderFormulaFonte(
      'Booher',
      'Vazão em sifões ou tubos',
      'p. 26',
      'única',
      BorderOrigemFonte.medida,
    ),
    BorderFormulaFonte(
      'Geometria',
      'D = St·W, Dmax = 0,4 hn e Wmax = Dmax/|St|',
      'pp. 13, 19',
      'única',
      BorderOrigemFonte.derivada,
    ),
    BorderFormulaFonte(
      'Exemplo',
      'Entradas do exemplo da aula (cenários primeira/terceira)',
      'p. 73',
      'única',
      BorderOrigemFonte.medida,
    ),
  ];

  final double t0Min, taMetadeMin, taFinalMin, tiMin, tdMin, trFinalMin;
  final double y0M, r, sigmaZ, qfM3MinM, residualOportunidadeM;
  final double residualAvancoM3M, residualRecessaoMin;
  final double volumeEntradaM3M, volumeUtilM3M, volumePercoladoM3M;
  final double volumeEscoadoM3M, volumeDeficitM3M;
  final double ea, er, pp, pe;
  final double comprimentoAdequadoM, volumeAdequadoM3M, volumeDeficitarioM3M;
  final double infiltracaoFinalM;
  final double larguraM;
  final List<BorderProfilePoint> perfil;
  final BorderStatus status;
  final List<BorderNotice> avisos;

  /// Grupo numérico efetivamente usado nesta execução.
  final BorderNumericConfig numerico;

  const BorderResult({
    required this.t0Min,
    required this.taMetadeMin,
    required this.taFinalMin,
    required this.tiMin,
    required this.tdMin,
    required this.trFinalMin,
    required this.y0M,
    required this.r,
    required this.sigmaZ,
    required this.qfM3MinM,
    required this.residualOportunidadeM,
    required this.residualAvancoM3M,
    required this.residualRecessaoMin,
    required this.volumeEntradaM3M,
    required this.volumeUtilM3M,
    required this.volumePercoladoM3M,
    required this.volumeEscoadoM3M,
    required this.volumeDeficitM3M,
    required this.ea,
    required this.er,
    required this.pp,
    required this.pe,
    this.comprimentoAdequadoM = 0,
    this.volumeAdequadoM3M = 0,
    this.volumeDeficitarioM3M = 0,
    this.infiltracaoFinalM = 0,
    required this.larguraM,
    required this.perfil,
    required this.status,
    required this.avisos,
    this.numerico = BorderNumericConfig.padrao,
  });

  double get volumeEntradaTotalM3 => volumeEntradaM3M * larguraM;
  double get volumeUtilTotalM3 => volumeUtilM3M * larguraM;
  double get volumePercoladoTotalM3 => volumePercoladoM3M * larguraM;
  double get volumeEscoadoTotalM3 => volumeEscoadoM3M * larguraM;

  Map<String, dynamic> toMap() => {
    'versaoEquacoes': versaoEquacoes,
    'paginasFonte': paginasFonte,
    'status': status.codigo,
    't0Min': t0Min,
    'taMetadeMin': taMetadeMin,
    'taFinalMin': taFinalMin,
    'tiMin': tiMin,
    'tdMin': tdMin,
    'trFinalMin': trFinalMin,
    'y0M': y0M,
    'r': r,
    'sigmaZ': sigmaZ,
    'qfM3MinM': qfM3MinM,
    'residualOportunidadeM': residualOportunidadeM,
    'residualAvancoM3M': residualAvancoM3M,
    'residualRecessaoMin': residualRecessaoMin,
    'volumeEntradaM3M': volumeEntradaM3M,
    'volumeUtilM3M': volumeUtilM3M,
    'volumePercoladoM3M': volumePercoladoM3M,
    'volumeEscoadoM3M': volumeEscoadoM3M,
    'volumeDeficitM3M': volumeDeficitM3M,
    'ea': ea,
    'er': er,
    'pp': pp,
    'pe': pe,
    'comprimentoAdequadoM': comprimentoAdequadoM,
    'volumeAdequadoM3M': volumeAdequadoM3M,
    'volumeDeficitarioM3M': volumeDeficitarioM3M,
    'infiltracaoFinalM': infiltracaoFinalM,
    'larguraM': larguraM,
    'numerico': numerico.toMap(),
    'avisos': avisos.map((notice) => notice.toMap()).toList(),
    'perfil': perfil
        .map(
          (p) => {
            'xM': p.xM,
            'avancoMin': p.avancoMin,
            'recessaoMin': p.recessaoMin,
            'oportunidadeMin': p.oportunidadeMin,
            'infiltracaoM': p.infiltracaoM,
          },
        )
        .toList(),
  };

  factory BorderResult.fromMap(Map<String, dynamic> map) {
    double n(String key) => (map[key] as num).toDouble();
    return BorderResult(
      t0Min: n('t0Min'),
      taMetadeMin: n('taMetadeMin'),
      taFinalMin: n('taFinalMin'),
      tiMin: n('tiMin'),
      tdMin: n('tdMin'),
      trFinalMin: n('trFinalMin'),
      y0M: n('y0M'),
      r: n('r'),
      sigmaZ: n('sigmaZ'),
      qfM3MinM: n('qfM3MinM'),
      residualOportunidadeM: n('residualOportunidadeM'),
      residualAvancoM3M: n('residualAvancoM3M'),
      residualRecessaoMin: n('residualRecessaoMin'),
      volumeEntradaM3M: n('volumeEntradaM3M'),
      volumeUtilM3M: n('volumeUtilM3M'),
      volumePercoladoM3M: n('volumePercoladoM3M'),
      volumeEscoadoM3M: n('volumeEscoadoM3M'),
      volumeDeficitM3M: n('volumeDeficitM3M'),
      ea: n('ea'),
      er: n('er'),
      pp: n('pp'),
      pe: n('pe'),
      comprimentoAdequadoM: (map['comprimentoAdequadoM'] as num?)?.toDouble() ?? 0,
      volumeAdequadoM3M: (map['volumeAdequadoM3M'] as num?)?.toDouble() ?? 0,
      volumeDeficitarioM3M: (map['volumeDeficitarioM3M'] as num?)?.toDouble() ?? 0,
      infiltracaoFinalM: (map['infiltracaoFinalM'] as num?)?.toDouble() ?? 0,
      larguraM: n('larguraM'),
      status: BorderStatus.deNome(map['status'] as String?),
      numerico: map['numerico'] is Map
          ? BorderNumericConfig.fromMap(
              Map<String, dynamic>.from(map['numerico'] as Map),
            )
          : BorderNumericConfig.padrao,
      avisos: (map['avisos'] as List?)
              ?.map(BorderNotice.fromMap)
              .toList() ??
          const [],
      perfil: (map['perfil'] as List).map((item) {
        final p = Map<String, dynamic>.from(item as Map);
        return BorderProfilePoint(
          (p['xM'] as num).toDouble(),
          (p['avancoMin'] as num).toDouble(),
          (p['recessaoMin'] as num).toDouble(),
          (p['oportunidadeMin'] as num).toDouble(),
          (p['infiltracaoM'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}
