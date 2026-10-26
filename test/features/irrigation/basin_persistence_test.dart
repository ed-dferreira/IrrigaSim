// Persistência do projeto de inundação (Fase 6): projeto versionado e anexos
// (planejamento, seleção de vazão, volumes do arroz) atravessam o
// CenarioSalvo e o exportarJson. Espelha border_persistence_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_annexes.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_project.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result_model.dart';
import 'package:irrigasim/shared/cenarios/services/project_store.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_simulation_coordinator.dart';

void main() {
  final project = BasinProject.exemploAula8Intermitente();
  final result = const BasinSimulationCoordinator().executarProjeto(project);
  final params = project.toCompatParameters();
  final scenario = CenarioSalvo(
    id: 'x',
    nome: 'Teste inundação',
    metodo: MetodoIrrigacao.inundacao,
    parametros: params,
    resultado: result,
    dataCriacao: DateTime(2020),
    dataModificacao: DateTime(2020),
  );

  test('projeto tipado atravessa o CenarioSalvo', () {
    final loaded = CenarioSalvo.fromMap(scenario.toMap());
    final restored = loaded.parametros.projetoInundacao!;

    expect(restored.versao, BasinProject.versaoAtual);
    expect(restored.regime, project.regime);
    expect(restored.comprimentoM, project.comprimentoM);
    expect(restored.k, project.k);
    expect(restored.laminaRequeridaMm, project.laminaRequeridaMm);
    expect(loaded.metodo, MetodoIrrigacao.inundacao);
  });

  test('cenário legado sem projetoInundacao migra por fromLegacy', () {
    final saved = scenario.toMap();
    (saved['parametros'] as Map<String, dynamic>).remove('projetoInundacao');
    final restored = CenarioSalvo.fromMap(saved).parametros.projetoInundacao!;

    expect(restored.versao, 0, reason: 'fromLegacy não inventa versão nova');
    expect(restored.regime, project.regime);
    expect(restored.comprimentoM, project.comprimentoM);
  });

  test('anexos de inundação persistem no resultado serializado', () {
    // Intermitente: planejamento em parcelas; seleção só com candidatas.
    expect(result.planejamentoParcelas, isNotNull);
    expect(result.selecaoVazao, isNull);
    // G3 preenchida nos dois regimes.
    expect(result.checagemOperacional, isNotNull);
    expect(result.checagemOperacional!.viavel, isTrue);
    // Permanente: volumes do arroz com lacunas da p. 84.
    final permanente = BasinProject.exemploAula8Permanente();
    final rPermanente = const BasinSimulationCoordinator().executarProjeto(
      permanente,
    );
    expect(rPermanente.volumesArroz, isNotNull);
    expect(rPermanente.volumesArroz!.volumes.v1M3Ha, isNull);
    expect(rPermanente.checagemOperacional, isNotNull);
    // Aula 8 contínuo: Qe = 166,6 L/s contra 36 L/s de fonte (G3).
    expect(rPermanente.checagemOperacional!.atendeVazao, isFalse);
    expect(rPermanente.checagemOperacional!.geometriaCabeNaArea, isTrue);
    expect(rPermanente.checagemOperacional!.viavel, isFalse);
    expect(
      rPermanente.volumesArroz!.volumes.dadosAusentes,
      contains(contains('umidade')),
    );

    final map = SimulationResultModel.toMap(result);
    final restored = SimulationResultModel.fromMap(map);

    expect(restored.planejamentoParcelas, isNotNull);
    expect(
      restored.planejamentoParcelas!.tppMin,
      closeTo(result.planejamentoParcelas!.tppMin, 1e-9),
    );
    expect(
      restored.planejamentoParcelas!.ntt,
      result.planejamentoParcelas!.ntt,
    );
    expect(restored.checagemOperacional, isNotNull);
    expect(
      restored.checagemOperacional!.vazaoPlanejadaLs,
      closeTo(result.checagemOperacional!.vazaoPlanejadaLs, 1e-9),
    );
    expect(
      restored.checagemOperacional!.areaDeclaradaM2,
      closeTo(result.checagemOperacional!.areaDeclaradaM2, 1e-9),
    );
    expect(restored.checagemOperacional!.viavel, isTrue);

    final mapPermanente = SimulationResultModel.toMap(rPermanente);
    final restoredPermanente = SimulationResultModel.fromMap(mapPermanente);
    expect(restoredPermanente.volumesArroz, isNotNull);
    expect(
      restoredPermanente.volumesArroz!.volumes.pt,
      closeTo(rPermanente.volumesArroz!.volumes.pt, 1e-12),
    );
    expect(
      restoredPermanente.volumesArroz!.volumes.dadosAusentes,
      rPermanente.volumesArroz!.volumes.dadosAusentes,
    );
    expect(restoredPermanente.checagemOperacional, isNotNull);
    expect(
      restoredPermanente.checagemOperacional!.viavel,
      rPermanente.checagemOperacional!.viavel,
    );
  });

  test('anexos isolados fazem roundtrip pelo mapa', () {
    final parcelas = BasinParcelasAnexo.fromMap(
      result.planejamentoParcelas!.toMap(),
    );
    expect(parcelas.tppMin, result.planejamentoParcelas!.tppMin);
    expect(parcelas.npdInteiro, result.planejamentoParcelas!.npdInteiro);

    // Seleção de vazão: exige candidatas explícitas no projeto (p. 60).
    final comCandidatas = BasinProject.exemploAula8Intermitente().copyWith(
      candidatasVazaoLs: const [100, 150, 200],
    );
    final rSelecao = const BasinSimulationCoordinator().executarProjeto(
      comCandidatas,
    );
    expect(rSelecao.selecaoVazao, isNotNull);
    final selecao = BasinSelecaoVazaoAnexo.fromMap(
      rSelecao.selecaoVazao!.toMap(),
    );
    expect(selecao.vazaoEscolhidaLs, rSelecao.selecaoVazao!.vazaoEscolhidaLs);
    expect(
      selecao.candidatasAvaliadas,
      rSelecao.selecaoVazao!.candidatasAvaliadas,
    );
    expect(selecao.eficienciaPercent, rSelecao.selecaoVazao!.eficienciaPercent);

    final volumesOrigem = const BasinSimulationCoordinator()
        .executarProjeto(BasinProject.exemploAula8Permanente())
        .volumesArroz!;
    final volumes = BasinVolumesAnexo.fromMap(volumesOrigem.toMap());
    expect(volumes.pagina, volumesOrigem.pagina);
    expect(volumes.volumes.v2M3Ha, volumesOrigem.volumes.v2M3Ha);
  });

  test('roundtrip v2 preserva agronomia, método de ETc e origens', () {
    final base = BasinProject.exemploAula8Intermitente();
    final projeto = base.copyWith(
      agronomia: base.agronomia!.withValue('kc', 1.2),
      metodoEtc: MetodoEtc.etoVezesKc,
      etoMmDia: 7,
      origemChuva: OrigemChuva.observada,
      precipitacaoEfetivaMmDia: 1.5,
      origemIrn: OrigemIrnBasin.calculada,
      temperaturaMediaC: 24,
      latitudeGraus: -30.5,
      mesReferencia: 9,
    );
    final loaded = BasinProject.fromMap(projeto.toMap());

    expect(loaded.versao, BasinProject.versaoAtual);
    expect(loaded.agronomia?.toMap(), projeto.agronomia?.toMap());
    expect(loaded.metodoEtc, MetodoEtc.etoVezesKc);
    expect(loaded.etoMmDia, 7);
    expect(loaded.origemChuva, OrigemChuva.observada);
    expect(loaded.precipitacaoEfetivaMmDia, 1.5);
    expect(loaded.origemIrn, OrigemIrnBasin.calculada);
    expect(loaded.temperaturaMediaC, 24);
    expect(loaded.latitudeGraus, -30.5);
    expect(loaded.mesReferencia, 9);
    // G14: com origem calculada a efetiva é a calculada (~56 mm).
    expect(loaded.irnEfetivaMm, closeTo(56, 1e-9));
  });

  test('carga de mapa v1 sem campos de clima usa defaults conscientes', () {
    final mapa = BasinProject.exemploAula8Intermitente().toMap()
      ..['versao'] = 1
      ..remove('agronomia')
      ..remove('metodo_etc')
      ..remove('origem_chuva')
      ..remove('origem_irn')
      ..remove('eto_mm_dia')
      ..remove('precipitacao_efetiva_mm_dia')
      ..remove('temperatura_media_c')
      ..remove('latitude_graus')
      ..remove('mes_referencia');
    final loaded = BasinProject.fromMap(mapa);

    expect(loaded.versao, 1, reason: 'carga v1 não é promovida para v2');
    expect(loaded.agronomia, isNull);
    expect(loaded.metodoEtc, MetodoEtc.adotada);
    expect(loaded.origemChuva, OrigemChuva.naoInformada);
    expect(loaded.origemIrn, OrigemIrnBasin.informada);
    expect(loaded.etoMmDia, isNull);
    expect(loaded.precipitacaoEfetivaMmDia, isNull);
    expect(loaded.temperaturaMediaC, isNull);
    expect(loaded.latitudeGraus, isNull);
    expect(loaded.mesReferencia, isNull);
    // Cultura legada permanece visível e a ETc segue o campo do regime (G4).
    expect(loaded.cultura, project.cultura);
    expect(loaded.etcMmDia, 8);
    expect(loaded.irnEfetivaMm, 56, reason: 'IRN informada intacta (G16)');
  });

  test('exportarJson inclui o projeto de inundação versionado', () async {
    final store = ProjectStore(
      listar: () async => [],
      salvar: (_) async {},
      buscarPorId: (_) async => null,
      excluir: (_) async {},
    );
    final json = await store.exportarJson(scenario);
    final projeto = json['projeto_inundacao'] as Map<String, dynamic>;

    expect(projeto['versao'], BasinProject.versaoAtual);
    expect(projeto['regime'], project.regime.name);
    expect(projeto['comprimento_m'], project.comprimentoM);
    expect(json['tipo_calculo'], 'irrigacao_inundacao');
  });
}
