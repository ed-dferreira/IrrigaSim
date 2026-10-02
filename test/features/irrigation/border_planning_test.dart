import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';
import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';

void main() {
  const planning = BorderPlanning();
  const base = BorderProject(
    comprimentoAreaM: 400,
    larguraAreaM: 400,
    comprimentoM: 400,
    larguraM: 10,
    desnivelLongitudinalM: .4,
    baseLongitudinalM: 400,
    desnivelTransversalM: .05,
    baseTransversalM: 10,
    laminaSuperficialM: .1,
    k: .0034,
    a: .45,
    vibMMin: .0001,
    rugosidadeN: .04,
    vazaoUnitariaLsM: 10 / 3,
    irnMm: 56,
    vazaoDisponivelLs: 400,
    diasFornecimento: [1, 2, 3, 4, 5, 6, 7],
    inicioFornecimentoH: 8,
  );

  test('geometria usa hn superficial e St percentual convertido pela base', () {
    final r = const BorderHydraulics().dimensionar(base);
    final geo = planning.geometry(base, r);
    expect(geo.limiteDesnivelM, closeTo(.04, 1e-10));
    expect(geo.larguraMaximaM, closeTo(8, 1e-10));
    final level = planning.geometry(base.copyWith(desnivelTransversalM: 0), r);
    expect(level.larguraMaximaM, isNull);
  });

  test('cronograma contabiliza lote final parcial e compara oferta', () {
    final r = const BorderHydraulics().dimensionar(base);
    final op = planning.operation(
      base,
      r,
      dias: 7,
      jornadaHoras: 12,
      mudancaMin: 10,
      simultaneas: 12,
      janelaFornecimentoHorasDia: 12,
    );
    expect(op.faixasTotais, 40);
    expect(op.grupos, 4);
    expect(op.ultimoLote, 4);
    expect(op.vazaoSimultaneaLs, closeTo(400, 1e-8));
    expect(op.gruposPorDia.reduce((a, b) => a + b), 4);
    expect(op.agenda.length, 4);
    expect(op.vazoesPorGrupoLs.last, closeTo(133.3333333, 1e-5));
  });

  test('busca isolada testa submúltiplos, mantém exclusões e retorna melhor da grade', () async {
    final ready = base.copyWith(desnivelTransversalM: 0, alturaDiqueM: .1);
    final grid = await buscarAlternativas(ready);
    expect(
      grid.candidatos.map((c) => c.comprimentoM).toSet(),
      containsAll([400, 200, 50]),
    );
    final withRejections = planning.explore(ready, menorLsM: .5, maiorLsM: 4);
    expect(
      withRejections.candidatos.any((c) => c.motivoRejeicao != null),
      isTrue,
    );
    // Toda exclusão da grade carrega código canônico e mensagem humana.
    for (final c in withRejections.candidatos) {
      expect(c.motivoRejeicao == null, c.status == null);
      if (c.status != null) {
        expect(c.status!.codigo, isNotEmpty);
        expect(c.status, isNot(BorderStatus.validoNoModelo));
      }
    }
    final registros = withRejections.toRecords();
    for (var i = 0; i < registros.length; i++) {
      expect(
        registros[i].status?.codigo,
        withRejections.candidatos[i].status?.codigo,
      );
    }
    expect(grid.melhor, isNotNull);
    expect(grid.toRecords().length, grid.candidatos.length);
  });
}
