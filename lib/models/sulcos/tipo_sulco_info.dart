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

enum FaixaDeclividade { ideal, aconselhavel, usavel, fora, naoInformada }

String formatarPercentual(double valor) {
  final fix2 = valor.toStringAsFixed(2);
  if (fix2.endsWith('00')) {
    final fix0 = valor.toStringAsFixed(0);
    if (double.parse(fix0) == valor) return fix0;
  }
  if (fix2.endsWith('0')) return fix2.substring(0, fix2.length - 1);
  return fix2;
}

class DeclividadeRange {
  final double? idealMin;
  final double? idealMax;
  final double? aconselhavelMin;
  final double? aconselhavelMax;
  final double? usavelMin;
  final double? usavelMax;

  const DeclividadeRange({
    this.idealMin,
    this.idealMax,
    this.aconselhavelMin,
    this.aconselhavelMax,
    this.usavelMin,
    this.usavelMax,
  });

  /// Tolerância para limites como 0,05 / 0,1 / 0,02, que não são
  /// representáveis com exatidão em ponto flutuante.
  static const _eps = 1e-9;

  FaixaDeclividade classificar(double percent) {
    if (_contido(percent, idealMin, idealMax)) return FaixaDeclividade.ideal;
    if (_contido(percent, aconselhavelMin, aconselhavelMax)) {
      return FaixaDeclividade.aconselhavel;
    }
    if (usavelMin == null &&
        aconselhavelMin != null &&
        percent < aconselhavelMin! - _eps) {
      return FaixaDeclividade.naoInformada;
    }
    if (_contido(percent, usavelMin, usavelMax)) {
      return FaixaDeclividade.usavel;
    }
    if (usavelMin == null && usavelMax == null) {
      return FaixaDeclividade.naoInformada;
    }
    return FaixaDeclividade.fora;
  }

  String get faixaIdealLabel =>
      _formatarFaixa(idealMin, idealMax) ?? 'Não informado';

  String get faixaAconselhavelLabel =>
      _formatarFaixa(aconselhavelMin, aconselhavelMax) ?? 'Não informado';

  String get faixaUsavelLabel =>
      _formatarFaixa(usavelMin, usavelMax) ?? 'Não informado';

  String? alertaDeclividade({
    required TipoSulco tipo,
    required double percent,
  }) {
    final faixa = classificar(percent);
    if (faixa == FaixaDeclividade.ideal ||
        faixa == FaixaDeclividade.aconselhavel) {
      return null;
    }
    final atual = '${formatarPercentual(percent)}%';
    return switch (faixa) {
      FaixaDeclividade.usavel =>
        'Declividade de $atual fora da faixa aconselhável para '
            '${tipo.displayName} (aconselhável: $faixaAconselhavelLabel; '
            'usável: $faixaUsavelLabel). O cálculo não será bloqueado, '
            'mas atenção ao dimensionamento.',
      FaixaDeclividade.fora =>
        'Declividade de $atual fora da faixa usável para ${tipo.displayName} '
            '(usável: $faixaUsavelLabel). O cálculo não será bloqueado, '
            'mas o resultado pode não ser representativo.',
      FaixaDeclividade.naoInformada =>
        'Faixa usável de declividade não informada para ${tipo.displayName}; não é possível classificá-la automaticamente.',
      FaixaDeclividade.ideal || FaixaDeclividade.aconselhavel => null,
    };
  }

  static bool _contido(double valor, double? min, double? max) {
    if (min == null && max == null) return false;
    if (min != null && valor < min - _eps) return false;
    if (max != null && valor > max + _eps) return false;
    return true;
  }

  static String? _formatarFaixa(double? min, double? max) {
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      if (min == max) return '${formatarPercentual(min)}%';
      return '${formatarPercentual(min)}% a ${formatarPercentual(max)}%';
    }
    if (max != null) return 'até ${formatarPercentual(max)}%';
    return 'a partir de ${formatarPercentual(min!)}%';
  }
}

class TipoSulcoInfo {
  final TipoSulco tipo;
  final DeclividadeRange declividade;
  final String alinhamento;
  final List<String> formas;
  final String comprimentoFaixa;
  final List<String> culturasIndicadas;
  final List<String> potencialidades;
  final List<String> limitacoes;
  final List<String> necessidadesEspeciais;

  const TipoSulcoInfo({
    required this.tipo,
    required this.declividade,
    required this.alinhamento,
    required this.formas,
    required this.comprimentoFaixa,
    required this.culturasIndicadas,
    required this.potencialidades,
    required this.limitacoes,
    required this.necessidadesEspeciais,
  });

  static const Map<TipoSulco, TipoSulcoInfo> dados = {
    TipoSulco.sulcos_comuns: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_comuns,
      declividade: DeclividadeRange(
        idealMin: 0.1,
        idealMax: 0.1,
        aconselhavelMin: 0.05,
        aconselhavelMax: 0.5,
        usavelMin: 0.02,
        usavelMax: 1.0,
      ),
      alinhamento: 'Retilíneo',
      formas: ['V'],
      comprimentoFaixa: '100 m a 500 m',
      culturasIndicadas: ['Culturas em fileiras'],
      potencialidades: [
        'Permite uso de diferentes vazões',
        'Menor custo por ser sistema longo e reto',
        'Exige menos mão de obra',
        'Favorece tratos culturais mecanizados',
      ],
      limitacoes: ['Requer terreno plano ou com declividade muito baixa'],
      necessidadesEspeciais: [
        'Requer terreno plano ou declividade muito baixa',
        'Dimensionar conforme solo, cultura e vazão disponível',
        'Limitar comprimento quando infiltração se tornar desuniforme',
      ],
    ),
    TipoSulco.sulcos_contorno: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_contorno,
      declividade: DeclividadeRange(
        idealMin: 1.0,
        idealMax: 1.0,
        aconselhavelMin: 0.5,
        aconselhavelMax: 2.0,
      ),
      alinhamento: 'Na direção das curvas de nível',
      formas: ['Entalhe com banco no lado de baixo'],
      comprimentoFaixa: '70 m a 150 m',
      culturasIndicadas: ['Videiras', 'Pomares', 'Culturas em curvas de nível'],
      potencialidades: [
        'Permite irrigação em terrenos com declividade',
        'Adapta-se a superfícies desuniformes',
        'Utilizado onde sulcos comuns não são adequados',
      ],
      limitacoes: [
        'Não deve ser utilizado em regiões com precipitações intensas',
        'Exige atenção ao dimensionamento da capacidade de retenção',
        'Alinhamento deve acompanhar curvas de nível',
      ],
      necessidadesEspeciais: [
        'Levantamento da topografia e curvas de nível',
        'Previsão de capacidade adicional para água de chuva',
        'Verificação do risco de erosão e transbordamento',
      ],
    ),
    TipoSulco.sulcos_corrugados: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_corrugados,
      declividade: DeclividadeRange(
        idealMin: 1.0,
        idealMax: 2.0,
        aconselhavelMin: 0.5,
        aconselhavelMax: 12.0,
        usavelMax: 15.0,
      ),
      alinhamento: 'Perpendicular às curvas de nível (maior declividade)',
      formas: ['V', 'U'],
      comprimentoFaixa: '30 m a 180 m',
      culturasIndicadas: [
        'Pastagem',
        'Alfafa',
        'Forrageiras',
        'Cobertura total do solo',
      ],
      potencialidades: [
        'Adapta-se a culturas de alta densidade de plantio',
        'Indicado para culturas sem capinas frequentes',
        'Reduz formação de crosta na superfície',
        'Adequado para pastagens e forrageiras',
      ],
      limitacoes: [
        'Requer dimensionamento conforme textura do solo',
        'Espaçamento deve ser compatível com a cultura',
        'Controlar vazão para evitar erosão em terrenos inclinados',
      ],
      necessidadesEspeciais: [
        'Dimensionar conforme textura do solo, cultura e declividade',
        'Espaçamento compatível com a cultura',
        'Controlar vazão para evitar erosão',
      ],
    ),
    TipoSulco.sulcos_nivel_tabuleiros: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_nivel_tabuleiros,
      declividade: DeclividadeRange(),
      alinhamento: 'Dentro de tabuleiros ou bacias',
      formas: ['Sulcos com água circulando entre canteiros'],
      comprimentoFaixa: 'Variável (conforme tabuleiro)',
      culturasIndicadas: [
        'Trigo',
        'Cevada',
        'Cebola',
        'Hortaliças',
        'Fora da época do arroz',
      ],
      potencialidades: [
        'Aproveitamento intensivo do terreno',
        'Boa adaptação a áreas de arroz irrigado',
        'Redução de perdas por escoamento',
      ],
      limitacoes: [
        'Requer tabuleiros ou bacias previamente construídos',
        'Comunicação entre sulcos deve permanecer desobstruída',
        'Nivelamento do tabuleiro é essencial',
      ],
      necessidadesEspeciais: [
        'Tabuleiros ou bacias previamente construídos',
        'Comunicação da água entre sulcos desobstruída',
        'Nivelamento do tabuleiro para uniformizar lâmina',
      ],
    ),
    TipoSulco.sulcos_nivel_fechados: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_nivel_fechados,
      declividade: DeclividadeRange(),
      alinhamento: 'Sem declividade ou muito pequena',
      formas: ['Sulcos largos fechados nas duas extremidades'],
      comprimentoFaixa: 'Curto (variável)',
      culturasIndicadas: ['Citros', 'Banana', 'Uva', 'Culturas permanentes'],
      potencialidades: [
        'Simples de construir e operar',
        'Adequado para culturas permanentes',
        'Controle fácil do volume aplicado',
      ],
      limitacoes: [
        'Extremidades precisam ser fechadas',
        'Terreno deve ser nivelado ou declividade muito pequena',
        'Necessário controlar momento de reduzir vazão',
      ],
      necessidadesEspeciais: [
        'Duas extremidades fechadas',
        'Terreno nivelado ou declividade muito pequena',
        'Controlar momento de reduzir ou interromper vazão',
        'Definir tempo de permanência conforme quantidade desejada',
      ],
    ),
    TipoSulco.sulcos_em_zigue_zague: TipoSulcoInfo(
      tipo: TipoSulco.sulcos_em_zigue_zague,
      declividade: DeclividadeRange(),
      alinhamento: 'Zigue-zague ao longo do terreno',
      formas: ['Disposição em zigue-zague'],
      comprimentoFaixa: 'Variável conforme traçado',
      culturasIndicadas: ['Frutíferas', 'Videiras', 'Pomares'],
      potencialidades: [
        'Distribui melhor água em solos com baixa infiltração',
        'Adapta-se a terrenos irregulares',
        'Reduz concentração de água em um ponto',
      ],
      limitacoes: [
        'Requer planejamento do traçado',
        'Avaliar capacidade de infiltração do solo',
        'Evitar excesso de vazão que provoque erosão',
      ],
      necessidadesEspeciais: [
        'Planejamento do traçado para distribuição uniforme',
        'Avaliação da capacidade de infiltração',
        'Definir comprimento e distância entre segmentos conforme cultura e relevo',
        'Evitar excesso de vazão',
      ],
    ),
  };

  static TipoSulcoInfo getInfo(TipoSulco tipo) => dados[tipo]!;
}
