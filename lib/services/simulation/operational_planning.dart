import 'dart:math';

/// Modos de arredondamento para valores operacionais.
enum ModoArredondamento {
  ceil, // Para cima (cobrir toda a área)
  floor, // Para baixo (limite de capacidade)
  decimal, // Para análise teórica
}

/// Resultado do cálculo de planejamento operacional.
class PlanejamentoOperacionalResultado {
  // Valores teóricos
  final double ntsTeorico;
  final double nsdTeorico;
  final double npdTeorico;
  final double nspTeorico;
  final double qProjetoTeorico;

  // Valores inteiros operacionais
  final int ntsOperacional;
  final int nsdOperacional;
  final int npdOperacional;
  final int nspOperacional;
  final double qProjetoOperacional;

  // Parâmetros de entrada
  final double areaTotalM2;
  final double comprimentoSulcoM;
  final double espacamentoM;
  final int pi;
  final double tempoAplicacaoH;
  final double tempoMudancaH;
  final double tempoDiarioDisponivelH;
  final double vazaoInicialLs;
  final double? perdasConducaoLs;
  final ModoArredondamento modoArredondamento;

  const PlanejamentoOperacionalResultado({
    required this.ntsTeorico,
    required this.nsdTeorico,
    required this.npdTeorico,
    required this.nspTeorico,
    required this.qProjetoTeorico,
    required this.ntsOperacional,
    required this.nsdOperacional,
    required this.npdOperacional,
    required this.nspOperacional,
    required this.qProjetoOperacional,
    required this.areaTotalM2,
    required this.comprimentoSulcoM,
    required this.espacamentoM,
    required this.pi,
    required this.tempoAplicacaoH,
    required this.tempoMudancaH,
    required this.tempoDiarioDisponivelH,
    required this.vazaoInicialLs,
    this.perdasConducaoLs,
    required this.modoArredondamento,
  });

  double get areaHectares => areaTotalM2 / 10000;

  double get comprimentoTotalSulcosM => ntsOperacional * comprimentoSulcoM;

  Map<String, dynamic> toMap() {
    return {
      'nts_teorico': ntsTeorico,
      'nsd_teorico': nsdTeorico,
      'npd_teorico': npdTeorico,
      'nsp_teorico': nspTeorico,
      'q_projeto_teorico': qProjetoTeorico,
      'nts_operacional': ntsOperacional,
      'nsd_operacional': nsdOperacional,
      'npd_operacional': npdOperacional,
      'nsp_operacional': nspOperacional,
      'q_projeto_operacional': qProjetoOperacional,
      'area_m2': areaTotalM2,
      'comprimento_sulco_m': comprimentoSulcoM,
      'espacamento_m': espacamentoM,
      'pi': pi,
      'tempo_aplicacao_h': tempoAplicacaoH,
      'tempo_mudanca_h': tempoMudancaH,
      'tempo_diario_disponivel_h': tempoDiarioDisponivelH,
      'vazao_inicial_ls': vazaoInicialLs,
      'perdas_conducao_ls': perdasConducaoLs,
      'modo_arredondamento': modoArredondamento.name,
    };
  }
}

/// Calcula o planejamento operacional do sistema de irrigação.
///
/// Referências: §48 do documento de implementação.
///
/// Fórmulas:
/// ```
/// NTS = (Lt * Wt) / (L * E)
/// NSD = NTS / PI
/// TIP = ti + tmud
/// NPD = TDF / TIP
/// NSP = NSD / NPD
/// Q = NSP * Q0 + PC
/// ```
class OperationalPlanning {
  const OperationalPlanning._();

  /// Calcula o planejamento operacional completo.
  ///
  /// [areaTotalM2] — Área total a ser irrigada (m²)
  /// [comprimentoSulcoM] — Comprimento de cada sulco (m)
  /// [espacamentoM] — Espaçamento entre sulcos (m)
  /// [pi] — Parcelas de irrigação simultâneas (default: 1)
  /// [tempoAplicacaoH] — Tempo de aplicação por sulco (h)
  /// [tempoMudancaH] — Tempo de mudança entre sulcos (h)
  /// [tempoDiarioDisponivelH] — Tempo diário disponível para irrigação (h)
  /// [vazaoInicialLs] — Vazão inicial por sulco (L/s)
  /// [perdasConducaoLs] — Perdas de condução (L/s)
  /// [modo] — Modo de arredondamento
  static PlanejamentoOperacionalResultado calcular({
    required double areaTotalM2,
    required double comprimentoSulcoM,
    required double espacamentoM,
    int pi = 1,
    required double tempoAplicacaoH,
    required double tempoMudancaH,
    required double tempoDiarioDisponivelH,
    required double vazaoInicialLs,
    double? perdasConducaoLs,
    ModoArredondamento modo = ModoArredondamento.ceil,
  }) {
    if (areaTotalM2 <= 0) {
      throw ArgumentError('Área total deve ser positiva');
    }
    if (comprimentoSulcoM <= 0) {
      throw ArgumentError('Comprimento do sulco deve ser positivo');
    }
    if (espacamentoM <= 0) {
      throw ArgumentError('Espaçamento deve ser positivo');
    }
    if (pi <= 0) {
      throw ArgumentError('PI deve ser maior que zero');
    }
    if (tempoAplicacaoH <= 0) {
      throw ArgumentError('Tempo de aplicação deve ser positivo');
    }
    if (tempoDiarioDisponivelH <= 0) {
      throw ArgumentError('Tempo diário disponível deve ser positivo');
    }
    if (tempoMudancaH < 0 ||
        vazaoInicialLs < 0 ||
        (perdasConducaoLs != null && perdasConducaoLs < 0)) {
      throw ArgumentError('Tempo de mudança e vazões não podem ser negativos');
    }

    // NTS = (Lt * Wt) / (L * E)
    final ntsTeorico = areaTotalM2 / (comprimentoSulcoM * espacamentoM);

    // NSD = NTS / PI
    final nsdTeorico = ntsTeorico / pi;

    // TIP = ti + tmud
    final tip = tempoAplicacaoH + tempoMudancaH;

    // NPD = TDF / TIP
    final npdTeorico = tempoDiarioDisponivelH / tip;

    // NSP = NSD / NPD
    final nspTeorico = nsdTeorico / npdTeorico;

    // Q = NSP * Q0 + PC
    final qProjetoTeorico =
        nspTeorico * vazaoInicialLs + (perdasConducaoLs ?? 0);

    // Valores inteiros operacionais
    int ntsOperacional;
    int nsdOperacional;
    int npdOperacional;
    int nspOperacional;

    switch (modo) {
      case ModoArredondamento.ceil:
        ntsOperacional = ntsTeorico.ceil();
        nsdOperacional = nsdTeorico.ceil();
        npdOperacional = npdTeorico.floor().clamp(1, 999);
        nspOperacional = nspTeorico.ceil();
        break;
      case ModoArredondamento.floor:
        ntsOperacional = ntsTeorico.floor();
        nsdOperacional = nsdTeorico.floor();
        npdOperacional = npdTeorico.floor().clamp(1, 999);
        nspOperacional = nspTeorico.floor();
        break;
      case ModoArredondamento.decimal:
        ntsOperacional = ntsTeorico.round();
        nsdOperacional = nsdTeorico.round();
        npdOperacional = npdTeorico.round().clamp(1, 999);
        nspOperacional = nspTeorico.round();
        break;
    }

    // Garantir valores mínimos
    ntsOperacional = max(1, ntsOperacional);
    nsdOperacional = max(1, nsdOperacional);
    nspOperacional = max(1, nspOperacional);

    // Q operacional
    final qProjetoOperacional =
        nspOperacional * vazaoInicialLs + (perdasConducaoLs ?? 0);

    return PlanejamentoOperacionalResultado(
      ntsTeorico: ntsTeorico,
      nsdTeorico: nsdTeorico,
      npdTeorico: npdTeorico,
      nspTeorico: nspTeorico,
      qProjetoTeorico: qProjetoTeorico,
      ntsOperacional: ntsOperacional,
      nsdOperacional: nsdOperacional,
      npdOperacional: npdOperacional,
      nspOperacional: nspOperacional,
      qProjetoOperacional: qProjetoOperacional,
      areaTotalM2: areaTotalM2,
      comprimentoSulcoM: comprimentoSulcoM,
      espacamentoM: espacamentoM,
      pi: pi,
      tempoAplicacaoH: tempoAplicacaoH,
      tempoMudancaH: tempoMudancaH,
      tempoDiarioDisponivelH: tempoDiarioDisponivelH,
      vazaoInicialLs: vazaoInicialLs,
      perdasConducaoLs: perdasConducaoLs,
      modoArredondamento: modo,
    );
  }

  /// Calcula o tempo total diário de irrigação (em horas).
  static double tempoDiarioIrrigacao({
    required int nsp,
    required double tempoAplicacaoH,
    required double tempoMudancaH,
  }) {
    return nsp * (tempoAplicacaoH + tempoMudancaH);
  }

  /// Verifica se a jornada diária comporta o número de parcelas.
  static bool verificarJornada({
    required double tempoDiarioDisponivelH,
    required int nsp,
    required double tempoAplicacaoH,
    required double tempoMudancaH,
  }) {
    final tempoNecessario = tempoDiarioIrrigacao(
      nsp: nsp,
      tempoAplicacaoH: tempoAplicacaoH,
      tempoMudancaH: tempoMudancaH,
    );
    return tempoNecessario <= tempoDiarioDisponivelH;
  }

  /// Calcula o número de dias para completar uma irrigação.
  static int diasParaCompletar({required int nsd, required int npd}) {
    if (npd <= 0) return nsd;
    return (nsd / npd).ceil();
  }
}
