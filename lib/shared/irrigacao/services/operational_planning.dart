import 'dart:math';

enum ModoArredondamento { ceil, floor, decimal }

/// Resultado auditável do planejamento dos lotes de irrigação.
class PlanejamentoOperacionalResultado {
  final double ntsTeorico;
  final double nsdTeorico;
  final double tipH;
  final double npdTeorico;
  final double nspTeorico;
  final double qProjetoTeorico;
  final int ntsOperacional;
  final int nsdOperacional;
  final int npdOperacional;
  final int nspOperacional;
  final double qProjetoOperacional;
  final int diasNecessariosOperacional;
  final bool agendaViavel;
  final bool vazaoDisponivelSuficiente;
  final String? motivoInviabilidade;
  final double areaTotalM2;
  final double comprimentoSulcoM;
  final double espacamentoM;
  final int periodoIrrigacaoDias;
  final double tempoFornecimentoH;
  final double tempoMudancaParcelaH;
  final double jornadaDiariaH;
  final double vazaoInicialLs;
  final double? perdasConducaoLs;
  final double? vazaoDisponivelLs;
  final ModoArredondamento modoArredondamento;

  const PlanejamentoOperacionalResultado({
    required this.ntsTeorico,
    required this.nsdTeorico,
    required this.tipH,
    required this.npdTeorico,
    required this.nspTeorico,
    required this.qProjetoTeorico,
    required this.ntsOperacional,
    required this.nsdOperacional,
    required this.npdOperacional,
    required this.nspOperacional,
    required this.qProjetoOperacional,
    required this.diasNecessariosOperacional,
    required this.agendaViavel,
    required this.vazaoDisponivelSuficiente,
    required this.motivoInviabilidade,
    required this.areaTotalM2,
    required this.comprimentoSulcoM,
    required this.espacamentoM,
    required this.periodoIrrigacaoDias,
    required this.tempoFornecimentoH,
    required this.tempoMudancaParcelaH,
    required this.jornadaDiariaH,
    required this.vazaoInicialLs,
    required this.perdasConducaoLs,
    required this.vazaoDisponivelLs,
    required this.modoArredondamento,
  });

  double get areaHectares => areaTotalM2 / 10000;

  double get comprimentoTotalSulcosM => ntsOperacional * comprimentoSulcoM;

  Map<String, dynamic> toMap() => {
    'nts_teorico': ntsTeorico,
    'nsd_teorico': nsdTeorico,
    'tip_h': tipH,
    'npd_teorico': npdTeorico,
    'nsp_teorico': nspTeorico,
    'q_projeto_teorico': qProjetoTeorico,
    'nts_operacional': ntsOperacional,
    'nsd_operacional': nsdOperacional,
    'npd_operacional': npdOperacional,
    'nsp_operacional': nspOperacional,
    'q_projeto_operacional': qProjetoOperacional,
    'dias_necessarios_operacional': diasNecessariosOperacional,
    'agenda_viavel': agendaViavel,
    'vazao_disponivel_suficiente': vazaoDisponivelSuficiente,
    'motivo_inviabilidade': motivoInviabilidade,
    'area_m2': areaTotalM2,
    'comprimento_sulco_m': comprimentoSulcoM,
    'espacamento_m': espacamentoM,
    'periodo_irrigacao_dias': periodoIrrigacaoDias,
    'tempo_fornecimento_h': tempoFornecimentoH,
    'tempo_mudanca_parcela_h': tempoMudancaParcelaH,
    'jornada_diaria_h': jornadaDiariaH,
    'vazao_inicial_ls': vazaoInicialLs,
    'perdas_conducao_ls': perdasConducaoLs,
    'vazao_disponivel_ls': vazaoDisponivelLs,
    'modo_arredondamento': modoArredondamento.name,
  };

  factory PlanejamentoOperacionalResultado.fromMap(Map<String, dynamic> map) {
    double number(String key) => (map[key] as num?)?.toDouble() ?? 0;
    int integer(String key) => (map[key] as num?)?.toInt() ?? 0;
    return PlanejamentoOperacionalResultado(
      ntsTeorico: number('nts_teorico'),
      nsdTeorico: number('nsd_teorico'),
      tipH: number('tip_h'),
      npdTeorico: number('npd_teorico'),
      nspTeorico: number('nsp_teorico'),
      qProjetoTeorico: number('q_projeto_teorico'),
      ntsOperacional: integer('nts_operacional'),
      nsdOperacional: integer('nsd_operacional'),
      npdOperacional: integer('npd_operacional'),
      nspOperacional: integer('nsp_operacional'),
      qProjetoOperacional: number('q_projeto_operacional'),
      diasNecessariosOperacional: integer('dias_necessarios_operacional'),
      agendaViavel: map['agenda_viavel'] as bool? ?? false,
      vazaoDisponivelSuficiente:
          map['vazao_disponivel_suficiente'] as bool? ?? true,
      motivoInviabilidade: map['motivo_inviabilidade'] as String?,
      areaTotalM2: number('area_m2'),
      comprimentoSulcoM: number('comprimento_sulco_m'),
      espacamentoM: number('espacamento_m'),
      periodoIrrigacaoDias: integer('periodo_irrigacao_dias'),
      tempoFornecimentoH: number('tempo_fornecimento_h'),
      tempoMudancaParcelaH: number('tempo_mudanca_parcela_h'),
      jornadaDiariaH: number('jornada_diaria_h'),
      vazaoInicialLs: number('vazao_inicial_ls'),
      perdasConducaoLs: (map['perdas_conducao_ls'] as num?)?.toDouble(),
      vazaoDisponivelLs: (map['vazao_disponivel_ls'] as num?)?.toDouble(),
      modoArredondamento: ModoArredondamento.values.firstWhere(
        (value) => value.name == map['modo_arredondamento'],
        orElse: () => ModoArredondamento.ceil,
      ),
    );
  }
}

class OperationalPlanning {
  const OperationalPlanning._();

  /// Calcula NTS, lotes/dia, parcelas simultâneas e vazão da parcela.
  static PlanejamentoOperacionalResultado calcular({
    required double areaTotalM2,
    required double comprimentoSulcoM,
    required double espacamentoM,
    required int periodoIrrigacaoDias,
    required double tempoFornecimentoH,
    required double tempoMudancaParcelaH,
    required double jornadaDiariaH,
    required double vazaoInicialLs,
    double? perdasConducaoLs,
    double? vazaoDisponivelLs,
    ModoArredondamento modo = ModoArredondamento.ceil,
  }) {
    if (!areaTotalM2.isFinite ||
        areaTotalM2 <= 0 ||
        !comprimentoSulcoM.isFinite ||
        comprimentoSulcoM <= 0 ||
        !espacamentoM.isFinite ||
        espacamentoM <= 0 ||
        periodoIrrigacaoDias <= 0 ||
        !tempoFornecimentoH.isFinite ||
        tempoFornecimentoH <= 0 ||
        !tempoMudancaParcelaH.isFinite ||
        tempoMudancaParcelaH < 0 ||
        !jornadaDiariaH.isFinite ||
        jornadaDiariaH <= 0 ||
        !vazaoInicialLs.isFinite ||
        vazaoInicialLs <= 0 ||
        (perdasConducaoLs != null &&
            (!perdasConducaoLs.isFinite || perdasConducaoLs < 0)) ||
        (vazaoDisponivelLs != null &&
            (!vazaoDisponivelLs.isFinite || vazaoDisponivelLs < 0))) {
      throw ArgumentError(
        'Revise área, período, tempos e vazões do planejamento operacional.',
      );
    }

    final nts = areaTotalM2 / (comprimentoSulcoM * espacamentoM);
    final nsd = nts / periodoIrrigacaoDias;
    final tip = tempoFornecimentoH + tempoMudancaParcelaH;
    final npd = jornadaDiariaH / tip;
    final nsp = nsd / npd;
    final qTheo = nsp * vazaoInicialLs + (perdasConducaoLs ?? 0);

    int roundValue(double value, ModoArredondamento rounding) =>
        switch (rounding) {
          ModoArredondamento.ceil => value.ceil(),
          ModoArredondamento.floor => value.floor(),
          ModoArredondamento.decimal => value.round(),
        };

    final ntsOp = max(1, roundValue(nts, ModoArredondamento.ceil));
    final nsdOp = max(1, (ntsOp / periodoIrrigacaoDias).ceil());
    final npdFloor = (jornadaDiariaH / tip).floor();
    final npdOp = max(0, npdFloor);
    final feasibleNpd = npdOp > 0;
    final nspExact = feasibleNpd ? nsdOp / npdOp : 0.0;
    final nspOp = feasibleNpd ? max(1, roundValue(nspExact, modo)) : 0;
    final daysNeeded = feasibleNpd
        ? (ntsOp / (npdOp * nspOp)).ceil()
        : periodoIrrigacaoDias + 1;
    final qOp = nspOp * vazaoInicialLs + (perdasConducaoLs ?? 0);
    final agendaOk = feasibleNpd && daysNeeded <= periodoIrrigacaoDias;
    final flowOk = vazaoDisponivelLs == null || qOp <= vazaoDisponivelLs;
    final reason = !feasibleNpd
        ? 'TIP (${tip.toStringAsFixed(4)} h) excede a jornada diária (${jornadaDiariaH.toStringAsFixed(4)} h); nenhuma parcela cabe na jornada.'
        : !agendaOk
        ? 'A agenda requer $daysNeeded dias, acima do período de $periodoIrrigacaoDias dias.'
        : !flowOk
        ? 'Qprojeto (${qOp.toStringAsFixed(3)} L/s) excede a vazão disponível (${vazaoDisponivelLs.toStringAsFixed(3)} L/s).'
        : null;

    return PlanejamentoOperacionalResultado(
      ntsTeorico: nts,
      nsdTeorico: nsd,
      tipH: tip,
      npdTeorico: npd,
      nspTeorico: nsp,
      qProjetoTeorico: qTheo,
      ntsOperacional: ntsOp,
      nsdOperacional: nsdOp,
      npdOperacional: npdOp,
      nspOperacional: nspOp,
      qProjetoOperacional: qOp,
      diasNecessariosOperacional: daysNeeded,
      agendaViavel: agendaOk,
      vazaoDisponivelSuficiente: flowOk,
      motivoInviabilidade: reason,
      areaTotalM2: areaTotalM2,
      comprimentoSulcoM: comprimentoSulcoM,
      espacamentoM: espacamentoM,
      periodoIrrigacaoDias: periodoIrrigacaoDias,
      tempoFornecimentoH: tempoFornecimentoH,
      tempoMudancaParcelaH: tempoMudancaParcelaH,
      jornadaDiariaH: jornadaDiariaH,
      vazaoInicialLs: vazaoInicialLs,
      perdasConducaoLs: perdasConducaoLs,
      vazaoDisponivelLs: vazaoDisponivelLs,
      modoArredondamento: modo,
    );
  }

  static double tempoDiarioIrrigacao({
    required int parcelasPorDia,
    required double tempoFornecimentoH,
    required double tempoMudancaParcelaH,
  }) => parcelasPorDia * (tempoFornecimentoH + tempoMudancaParcelaH);

  static bool verificarJornada({
    required double jornadaDiariaH,
    required int parcelasPorDia,
    required double tempoFornecimentoH,
    required double tempoMudancaParcelaH,
  }) =>
      tempoDiarioIrrigacao(
        parcelasPorDia: parcelasPorDia,
        tempoFornecimentoH: tempoFornecimentoH,
        tempoMudancaParcelaH: tempoMudancaParcelaH,
      ) <=
      jornadaDiariaH;

  static int diasParaCompletar({required int nsd, required int npd}) =>
      npd <= 0 ? nsd : (nsd / npd).ceil();
}
