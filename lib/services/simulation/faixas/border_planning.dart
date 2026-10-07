import 'dart:math' as math;

import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

import 'border_hydraulics.dart';

class BorderGeometry {
  final double desnivelM;
  final double? limiteDesnivelM, larguraMaximaM;
  final bool? diqueSuficiente;
  const BorderGeometry(
    this.desnivelM,
    this.limiteDesnivelM,
    this.larguraMaximaM,
    this.diqueSuficiente,
  );
}

class BorderCandidate {
  final double comprimentoM, vazaoLsM;
  final double larguraM;
  final BorderResult? resultado;
  final String? motivoRejeicao;

  /// Código canônico da exclusão; null quando a candidata ficou viável.
  final BorderStatus? status;
  const BorderCandidate(
    this.comprimentoM,
    this.vazaoLsM,
    this.resultado,
    this.motivoRejeicao, [
    this.status,
    this.larguraM = 0,
  ]);
}

class BorderAlternatives {
  final List<BorderCandidate> candidatos;
  final BorderCandidate? melhor;
  final double menorLsM, maiorLsM, passoLsM;
  final String objetivo;
  const BorderAlternatives(
    this.candidatos,
    this.melhor, {
    this.menorLsM = 0,
    this.maiorLsM = 0,
    this.passoLsM = 0,
    this.objetivo = 'Ea',
  });
  List<BorderAlternativeRecord> toRecords({BorderCandidate? selected}) =>
      candidatos
          .map(
            (c) => BorderAlternativeRecord.withMetrics(
              c.comprimentoM,
              c.vazaoLsM,
              c.resultado?.ea,
              c.motivoRejeicao,
              status: c.status,
              erPercentual: c.resultado?.er,
              ppPercentual: c.resultado?.pp,
              pePercentual: c.resultado?.pe,
              demandaLs: c.vazaoLsM * c.larguraM,
              gradeMenorLsM: menorLsM,
              gradeMaiorLsM: maiorLsM,
              gradePassoLsM: passoLsM,
              objetivo: objetivo,
              selecionada: identical(c, selected ?? melhor),
            ),
          )
          .toList();
}

class BorderOperation {
  final double tempoParcelaMin,
      parcelasDiaBruto,
      areaParcelaM2,
      larguraTeoricaM;
  final int parcelasCompletasDia, faixasTotais, grupos, ultimoLote;
  final double vazaoSimultaneaLs;
  final bool atendePrazo, atendeOferta;
  final List<int> gruposPorDia;
  final List<String> agenda;
  final List<double> vazoesPorGrupoLs;
  const BorderOperation(
    this.tempoParcelaMin,
    this.parcelasDiaBruto,
    this.areaParcelaM2,
    this.larguraTeoricaM,
    this.parcelasCompletasDia,
    this.faixasTotais,
    this.grupos,
    this.ultimoLote,
    this.vazaoSimultaneaLs,
    this.atendePrazo,
    this.atendeOferta,
    this.gruposPorDia,
    this.agenda,
    this.vazoesPorGrupoLs,
  );
}

class BorderPlanning {
  const BorderPlanning();

  BorderGeometry geometry(BorderProject p, BorderResult r) {
    final st = p.declividadeTransversal;
    if (st == null || !st.isFinite || p.larguraM == null) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Informe a base transversal e a largura.',
        pagina: 'pp. 13, 19',
      );
    }
    final hn = p.laminaSuperficialM;
    return BorderGeometry(
      st.abs() * p.larguraM!,
      hn == null ? null : .4 * hn,
      hn == null || st == 0 ? null : .4 * hn / st.abs(),
      p.alturaDiqueM == null ? null : r.y0M <= p.alturaDiqueM!,
    );
  }

  BorderAlternatives explore(
    BorderProject p, {
    required double menorLsM,
    required double maiorLsM,
    double passoLsM = .05,
    String objetivo = 'Ea',
  }) {
    final lt = p.comprimentoAreaM, wt = p.larguraAreaM, l = p.comprimentoM;
    if (lt == null ||
        wt == null ||
        l == null ||
        l <= 0 ||
        lt <= 0 ||
        wt <= 0 ||
        menorLsM <= 0 ||
        maiorLsM < menorLsM ||
        passoLsM <= 0 ||
        !{'Ea', 'Er'}.contains(objetivo) ||
        [lt, wt, l, menorLsM, maiorLsM, passoLsM].any((v) => !v.isFinite)) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Área e grade de vazão inválidas.',
      );
    }
    final firstDivision = math.max(1, (lt / 400).ceil());
    final lastDivision = math.max(firstDivision, (lt / 50).floor());
    final flowSteps = ((maiorLsM - menorLsM) / passoLsM + 1e-9).floor() + 1;
    if (lastDivision > 100 ||
        flowSteps > 200 ||
        (lastDivision - firstDivision + 1) * flowSteps > 2000) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Grade muito extensa; reduza o intervalo.',
      );
    }
    final candidates = <BorderCandidate>[];
    for (
      var divisions = firstDivision;
      divisions <= lastDivision;
      divisions++
    ) {
      final length = lt / divisions;
      for (var i = 0; i < flowSteps; i++) {
        final flow = menorLsM + i * passoLsM;
        final candidate = p.copyWith(
          comprimentoM: length,
          vazaoUnitariaLsM: flow,
        );
        String? reason;
        BorderStatus? reasonStatus;
        BorderResult? result;
        try {
          if (p.vazaoDisponivelLs != null &&
              flow * p.larguraM! > p.vazaoDisponivelLs!) {
            reason = 'Oferta de água insuficiente';
            reasonStatus = BorderStatus.foraDoDominio;
          } else if (p.laminaSuperficialM == null || p.alturaDiqueM == null) {
            reason = 'Pendente: informe hn superficial e altura real do dique';
            reasonStatus = BorderStatus.entradaInvalida;
          } else {
            result = const BorderHydraulics().dimensionar(candidate);
            final geo = geometry(candidate, result);
            if (geo.larguraMaximaM != null &&
                p.larguraM! > geo.larguraMaximaM!) {
              reason = 'Desnível transversal acima de 0,4 hn';
              reasonStatus = BorderStatus.foraDoDominio;
            }
            if (geo.diqueSuficiente == false) {
              reason = 'y0 acima da altura real do dique';
              reasonStatus = BorderStatus.foraDoDominio;
            }
          }
        } on BorderModelException catch (e) {
          reason = e.mensagem;
          reasonStatus = e.status;
        } on FormatException catch (e) {
          reason = e.message;
          reasonStatus = BorderStatus.entradaInvalida;
        }
        candidates.add(
          BorderCandidate(
            length,
            flow,
            reason == null ? result : null,
            reason,
            reasonStatus,
            p.larguraM!,
          ),
        );
      }
    }
    final viable = candidates.where((c) => c.resultado != null).toList()
      ..sort(
        (a, b) => (objetivo == 'Ea'
            ? b.resultado!.ea.compareTo(a.resultado!.ea)
            : b.resultado!.er.compareTo(a.resultado!.er)),
      );
    return BorderAlternatives(
      candidates,
      viable.firstOrNull,
      menorLsM: menorLsM,
      maiorLsM: maiorLsM,
      passoLsM: passoLsM,
      objetivo: objetivo,
    );
  }

  BorderOperation operation(
    BorderProject p,
    BorderResult r, {
    required int dias,
    required double jornadaHoras,
    required double mudancaMin,
    required int simultaneas,
    required double janelaFornecimentoHorasDia,
  }) {
    final lt = p.comprimentoAreaM, wt = p.larguraAreaM;
    if (lt == null ||
        wt == null ||
        p.larguraM == null ||
        p.comprimentoM == null ||
        dias <= 0 ||
        jornadaHoras <= 0 ||
        mudancaMin < 0 ||
        simultaneas <= 0 ||
        janelaFornecimentoHorasDia <= 0 ||
        p.inicioFornecimentoH == null ||
        p.inicioFornecimentoH! < 0 ||
        !p.inicioFornecimentoH!.isFinite ||
        p.inicioFornecimentoH! + janelaFornecimentoHorasDia > 24 ||
        p.diasFornecimento.isEmpty ||
        p.diasFornecimento.toSet().length != p.diasFornecimento.length ||
        p.diasFornecimento.any((d) => d < 1 || d > dias) ||
        [
          lt,
          wt,
          jornadaHoras,
          mudancaMin,
          janelaFornecimentoHorasDia,
        ].any((n) => !n.isFinite)) {
      throw const BorderModelException(
        BorderStatus.entradaInvalida,
        'Cronograma pendente: informe área, PI, TDF, tmu, NFP e janela de fornecimento.',
      );
    }
    final nL = lt / p.comprimentoM!, nW = wt / p.larguraM!;
    if ((nL - nL.round()).abs() > 1e-8 || (nW - nW.round()).abs() > 1e-8) {
      throw const BorderModelException(
        BorderStatus.modeloNaoImplementado,
        'L e W devem dividir as dimensões da área; lote parcial não modelado.',
        pagina: 'pp. 69–71',
      );
    }
    final tip = r.tiMin + mudancaMin;
    final npd = jornadaHoras * 60 / tip;
    final complete = math.min(
      (jornadaHoras * 60 / tip).floor(),
      (janelaFornecimentoHorasDia * 60 / tip).floor(),
    );
    final total = nL.round() * nW.round(),
        groups = (total / simultaneas).ceil();
    final q = simultaneas * p.vazaoFaixaLs!;
    var remaining = groups;
    final groupsPerDay = List<int>.generate(dias, (index) {
      if (!p.diasFornecimento.contains(index + 1)) return 0;
      final count = math.min(remaining, complete);
      remaining -= count;
      return count;
    });
    final agenda = <String>[
      for (var day = 0; day < dias; day++)
        for (var group = 0; group < groupsPerDay[day]; group++)
          'Dia ${day + 1}, grupo ${groupsPerDay.take(day).fold<int>(0, (a, b) => a + b) + group + 1}: '
              '${(p.inicioFornecimentoH! + group * tip / 60).toStringAsFixed(2)}–'
              '${(p.inicioFornecimentoH! + (group + 1) * tip / 60).toStringAsFixed(2)} h',
    ];
    final groupFlows = List<double>.generate(
      groups,
      (index) =>
          (index == groups - 1
              ? total - (groups - 1) * simultaneas
              : simultaneas) *
          p.vazaoFaixaLs!,
    );
    final atendeOferta =
        p.vazaoDisponivelLs != null &&
        groupFlows.every((flow) => flow <= p.vazaoDisponivelLs!);
    return BorderOperation(
      tip,
      npd,
      wt * lt / (npd * dias),
      wt * lt / (npd * dias * simultaneas * p.comprimentoM!),
      complete,
      total,
      groups,
      total % simultaneas == 0 ? simultaneas : total % simultaneas,
      q,
      complete > 0 && remaining == 0 && atendeOferta,
      atendeOferta,
      groupsPerDay,
      agenda,
      groupFlows,
    );
  }
}
