import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
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

  test('valida opcionais operacionais quando informados e preserva seleção de equipamento', () {
    expect(
      base.copyWith(alturaDiqueM: 0).impedimento?.status,
      BorderStatus.entradaInvalida,
    );
    expect(
      base.copyWith(laminaSuperficialM: double.nan).impedimento?.status,
      BorderStatus.entradaInvalida,
    );
    expect(
      base.copyWith(vazaoDisponivelLs: -1).impedimento?.status,
      BorderStatus.entradaInvalida,
    );
    expect(
      base
          .copyWith(inicioFornecimentoH: 23, janelaFornecimentoHorasDia: 2)
          .impedimento
          ?.status,
      BorderStatus.entradaInvalida,
    );
    expect(
      base.copyWith(rho2F02: 2).impedimento?.status,
      BorderStatus.entradaInvalida,
    );
    expect(
      base.copyWith(fracaoCortePlanejada: .7).impedimento?.status,
      BorderStatus.modeloNaoImplementado,
    );
    expect(
      base.copyWith(fracaoCortePlanejada: .8).impedimento?.status,
      BorderStatus.entradaInvalida,
    );
    final project = base.copyWith(
      dispositivoDiametroCm: 12.5,
      dispositivoCargaCm: 10,
      rho1F02: 1,
      rho2F02: 3.33,
      vmaxF02: 2.5,
      unidadeVmaxF02: 'sem convenção confirmada',
      areaUtilM2: 150000,
      orientacaoArea: 'Norte–Sul',
      tipoDique: 'permanente',
      dataEnsaioIso: '2025-09-29',
      referenciaRelogioEnsaio: 'cronômetro iniciado no corte da comporta',
      observacoesEnsaio: 'vento moderado',
    );
    final restored = BorderProject.fromMap(project.toMap());
    expect(restored.dispositivoDiametroCm, 12.5);
    expect(restored.dispositivoCargaCm, 10);
    expect(restored.vmaxF02, 2.5);
    expect(restored.areaUtilM2, 150000);
    expect(restored.orientacaoArea, 'Norte–Sul');
    expect(restored.dataEnsaioIso, '2025-09-29');
    expect(restored.observacoesEnsaio, 'vento moderado');
  });

  test('mantém k, a e VIB próprios por cenário e os calcula em paralelo', () {
    final controller = BorderProjectController();
    controller.setCenarioInfiltracao(CenarioInfiltracaoFaixa.primeira);
    controller.setNumero('k', '0.004');
    controller.setNumero('a', '0.5');
    controller.setNumero('vibMMin', '0.0002');
    controller.setCenarioInfiltracao(CenarioInfiltracaoFaixa.terceira);
    expect(controller.state.k, BorderProject.ilustrativo.k);
    controller.setNumero('k', '0.003');
    controller.setNumero('a', '0.4');
    controller.setNumero('vibMMin', '0.0001');
    final project = BorderProject.fromMap(controller.state.toMap());
    expect(project.dadosPrimeira?.k, .004);
    expect(project.dadosTerceira?.k, .003);
    final comparison = calcularComparacaoCenarios(project);
    expect(
      comparison.primeira.perfil.last.infiltracaoM,
      isNot(comparison.terceira.perfil.last.infiltracaoM),
    );
    controller.dispose();
  });

  test(
    'registra topografia uniforme e bloqueia perfil variável/terminal plano',
    () {
      final uniform = base.copyWith(
        perfilLongitudinal: const [
          BorderTerrainPoint(0, .4),
          BorderTerrainPoint(200, .2),
          BorderTerrainPoint(400, 0),
        ],
      );
      expect(uniform.impedimento, isNull);
      final restored = BorderProject.fromMap(uniform.toMap());
      expect(restored.perfilLongitudinal.length, 3);
      final flatTerminal = base.copyWith(
        perfilLongitudinal: const [
          BorderTerrainPoint(0, .4),
          BorderTerrainPoint(350, .05),
          BorderTerrainPoint(400, .05),
        ],
      );
      expect(
        flatTerminal.impedimento?.status,
        BorderStatus.modeloNaoImplementado,
      );
    },
  );

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
    final erGrid = planning.explore(
      ready,
      menorLsM: 2.5,
      maiorLsM: 3.5,
      passoLsM: .5,
      objetivo: 'Er',
    );
    expect(erGrid.objetivo, 'Er');
    expect(erGrid.menorLsM, 2.5);
    expect(erGrid.maiorLsM, 3.5);
    expect(erGrid.passoLsM, .5);
    expect(
      erGrid.melhor!.resultado!.er,
      erGrid.candidatos
          .where((candidate) => candidate.resultado != null)
          .map((candidate) => candidate.resultado!.er)
          .reduce((a, b) => a > b ? a : b),
    );
    final savedProject = ready.copyWith(alternativas: erGrid.toRecords());
    final restored = BorderProject.fromMap(savedProject.toMap());
    final selected = restored.alternativas.singleWhere(
      (record) => record.selecionada,
    );
    expect(selected.objetivo, 'Er');
    expect(selected.gradeMenorLsM, 2.5);
    expect(selected.gradeMaiorLsM, 3.5);
    expect(selected.gradePassoLsM, .5);
    expect(selected.erPercentual, isNotNull);
    expect(selected.ppPercentual, isNotNull);
    expect(selected.pePercentual, isNotNull);
    expect(selected.demandaLs, isNotNull);
  });
}
