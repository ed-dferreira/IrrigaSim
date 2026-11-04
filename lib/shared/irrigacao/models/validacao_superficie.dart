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
    if (data is String) {
      return BorderNotice(BorderStatus.avisoOrientativo, data);
    }
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
