// Os nomes deste enum fazem parte do formato persistido dos cenários existentes.
// ignore_for_file: constant_identifier_names

enum TipoSulco {
  sulcos_comuns,
  sulcos_contorno,
  sulcos_corrugados,
  sulcos_nivel_tabuleiros,
  sulcos_nivel_fechados,
  sulcos_em_zigue_zague,
}

extension TipoSulcoExtension on TipoSulco {
  /// O motor de sulco aberto representa uma saída pelo final do sulco.
  bool get suportaEscoamentoTerminal => switch (this) {
    TipoSulco.sulcos_comuns ||
    TipoSulco.sulcos_contorno ||
    TipoSulco.sulcos_corrugados => true,
    TipoSulco.sulcos_nivel_tabuleiros ||
    TipoSulco.sulcos_nivel_fechados ||
    TipoSulco.sulcos_em_zigue_zague => false,
  };

  String get motivoSemSuporteTerminal => switch (this) {
    TipoSulco.sulcos_nivel_tabuleiros => 'Sulcos em nível/tabuleiros requerem balanço de armazenamento compatível com declividade nula.',
    TipoSulco.sulcos_nivel_fechados => 'Sulcos fechados não têm escoamento de saída pelo final; o motor de sulco aberto não é aplicável.',
    TipoSulco.sulcos_em_zigue_zague => 'O traçado hidráulico em zigue-zague não pode ser representado pelo comprimento retilíneo informado.',
    _ => '',
  };

  String get displayName => switch (this) {
    TipoSulco.sulcos_comuns => 'Sulcos Comuns',
    TipoSulco.sulcos_contorno => 'Sulcos em Contorno',
    TipoSulco.sulcos_corrugados => 'Sulcos Corrugados',
    TipoSulco.sulcos_nivel_tabuleiros => 'Sulcos em Nível (Tabuleiros)',
    TipoSulco.sulcos_nivel_fechados => 'Sulcos em Nível (Fechados)',
    TipoSulco.sulcos_em_zigue_zague => 'Sulcos em Zigue-zague',
  };

  String get descricao => switch (this) {
    TipoSulco.sulcos_comuns =>
      'Sulcos retilíneos em V para terrenos planos, culturas em fileiras.',
    TipoSulco.sulcos_contorno =>
      'Sulcos na direção das curvas de nível para terrenos com declividade.',
    TipoSulco.sulcos_corrugados => 'Pequenos sulcos na direção da maior declividade para culturas de cobertura total.',
    TipoSulco.sulcos_nivel_tabuleiros => 'Sulcos dentro de tabuleiros ou bacias de arroz, com água circulando entre canteiros.',
    TipoSulco.sulcos_nivel_fechados => 'Sulcos largos fechados nas duas extremidades, para irrigação por preenchimento.',
    TipoSulco.sulcos_em_zigue_zague => 'Sulcos dispostos em zigue-zague para terrenos com baixa capacidade de infiltração.',
  };

  static TipoSulco fromString(String value) {
    return TipoSulco.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoSulco.sulcos_comuns,
    );
  }
}
