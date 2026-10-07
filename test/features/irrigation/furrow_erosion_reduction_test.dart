import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/cenarios/cenario_salvo.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/services/persistence/project_store.dart';
import 'package:irrigasim/services/simulation/sulcos/flow_management.dart';
import 'package:irrigasim/services/simulation/sulcos/run_furrow_simulation.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

void main() {
  const conditions = 'Solo médio, seção V e orientação do projeto';
  const stakes = [
    MedicaoAvanco(distanciaM: 0, tempoMin: 0),
    MedicaoAvanco(distanciaM: 20, tempoMin: 5),
    MedicaoAvanco(distanciaM: 40, tempoMin: 9),
    MedicaoAvanco(distanciaM: 60, tempoMin: 16),
    MedicaoAvanco(distanciaM: 80, tempoMin: 25),
    MedicaoAvanco(distanciaM: 100, tempoMin: 35),
    MedicaoAvanco(distanciaM: 120, tempoMin: 45),
    MedicaoAvanco(distanciaM: 140, tempoMin: 56),
    MedicaoAvanco(distanciaM: 160, tempoMin: 67),
    MedicaoAvanco(distanciaM: 180, tempoMin: 79),
    MedicaoAvanco(distanciaM: 200, tempoMin: 90),
  ];
  const base = IrrigationParameters(
    comprimento: 200,
    larguraOuEspacamento: .9,
    declividade: .002,
    k: 2.83,
    a: .554,
    vib: .0001,
    vazao: 1,
    vazaoDisponivelLps: 36,
    tempoAplicacao: 130,
    laminaRequerida: 42,
    tempoAvancoMetadeMin: 35,
    tempoAvancoFinalMin: 90,
  );

  test('erosão observada no campo prevalece sobre qmax empírico', () {
    final params = base.copyWith(
      ensaioErosao: const EnsaioErosaoSulco(
        vazaoLs: 1,
        condicoes: conditions,
        erosaoObservada: true,
      ),
    );
    expect(
      FlowManagement.calcularVazaoMaxima(
        declividadePercent: .2,
        textura: params.texturaSolo,
      ).qmaxLs,
      greaterThan(1),
    );
    expect(
      () => RunFurrowSimulation()(params),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'campo',
          contains('Erosão observada'),
        ),
      ),
    );
    expect(
      RunFurrowSimulation()(
        params.copyWith(
          ensaioErosao: const EnsaioErosaoSulco(
            vazaoLs: 1,
            condicoes: conditions,
            erosaoObservada: false,
          ),
        ),
      ).alertaVazaoExcedida,
      isNull,
    );
  });

  test('medição de avanço exige vazão e condições iguais às do projeto', () {
    final measured = base.copyWith(
      usarEnsaioAvanco: true,
      medicoesAvanco: stakes,
    );
    expect(() => RunFurrowSimulation()(measured), throwsFormatException);
    expect(
      () => RunFurrowSimulation()(
        measured.copyWith(
          vazaoEnsaioAvancoLs: .8,
          condicoesEnsaioAvanco: conditions,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'vazão',
          contains('difere'),
        ),
      ),
    );
    expect(
      RunFurrowSimulation()(
        measured.copyWith(
          vazaoEnsaioAvancoLs: 1,
          condicoesEnsaioAvanco: conditions,
        ),
      ).extrapolouAvanco,
      isFalse,
    );
    expect(
      RunFurrowSimulation()(
        measured.copyWith(
          vazaoEnsaioAvancoLs: 1,
          condicoesEnsaioAvanco: conditions,
          comprimento: 220,
        ),
      ).extrapolouAvanco,
      isTrue,
    );
  });

  test(
    'somatório F24 p.96 usa somente estacas no domínio e não a derivada final',
    () {
      final sum = FlowManagement.estimarSomatorioEspacial(
        estacas: stakes,
        comprimentoM: 200,
        espacamentoM: .9,
        instanteMudancaMin: 110,
        coeficienteAcumuladoMmMinA: 2.83,
        expoenteAcumulado: .554,
      );
      expect(sum.vazaoReduzidaLs, closeTo(.7472335436, .00005));
      expect(
        () => FlowManagement.estimarSomatorioEspacial(
          estacas: stakes,
          comprimentoM: 220,
          espacamentoM: .9,
          instanteMudancaMin: 110,
          coeficienteAcumuladoMmMinA: 2.83,
          expoenteAcumulado: .554,
        ),
        throwsFormatException,
      );
      final params = base.copyWith(
        manejoSulco: ManejoSulco.reduzida,
        origemVazaoReduzida: OrigemVazaoReduzida.somatorioEspacial,
        usarEnsaioAvanco: true,
        medicoesAvanco: stakes,
        vazaoEnsaioAvancoLs: 1,
        condicoesEnsaioAvanco: conditions,
        tempoMudancaMin: 20,
      );
      final result = RunFurrowSimulation()(params);
      expect(
        result.metricas['Vazão reduzida pelo somatório espacial'],
        closeTo(.7472335436, .00005),
      );
      expect(result.metricas['Tempo com vazão inicial'], 110);
      expect(result.metricas['Tempo com vazão reduzida'], 110);
      expect(result.laminaAplicadaMediaMm, closeTo(64.0655, .005));
      expect(result.resumoTextual, contains('condicionado'));
    },
  );

  test('F23 registra VIB, fator opcional e bloqueia falta de oferta', () {
    final params = base.copyWith(
      k: .5,
      a: .5,
      vib: 7.9 / 60000,
      larguraOuEspacamento: 1,
      manejoSulco: ManejoSulco.reduzida,
      origemVazaoReduzida: OrigemVazaoReduzida.vib,
    );
    final without = RunFurrowSimulation()(params);
    final withFactor = RunFurrowSimulation()(params.copyWith(fator11Vib: true));
    expect(
      without.metricas['Vazão reduzida estimada por VIB'],
      closeTo(.4388888889, 1e-9),
    );
    expect(
      withFactor.metricas['Vazão reduzida estimada por VIB'],
      closeTo(.4827777778, 1e-9),
    );
    expect(withFactor.metricas['Fator da estimativa VIB'], 1.1);
    expect(withFactor.metricas['VIB usada na redução'], closeTo(7.9, 1e-9));
    expect(
      () => RunFurrowSimulation()(params.copyWith(vazaoDisponivelLps: .9)),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'oferta',
          contains('Oferta'),
        ),
      ),
    );
    expect(
      () => RunFurrowSimulation()(params.copyWith(tempoMudancaMin: -1)),
      throwsFormatException,
    );
  });

  test(
    'vazão informada abaixo da demanda espacial medida não mantém a hipótese',
    () {
      expect(
        () => RunFurrowSimulation()(
          base.copyWith(
            manejoSulco: ManejoSulco.reduzida,
            origemVazaoReduzida: OrigemVazaoReduzida.informada,
            vazaoReduzidaLs: .5,
            usarEnsaioAvanco: true,
            medicoesAvanco: stakes,
            vazaoEnsaioAvancoLs: 1,
            condicoesEnsaioAvanco: conditions,
            tempoMudancaMin: 20,
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'demanda',
            contains('não cobre'),
          ),
        ),
      );
    },
  );

  test(
    'cenário preserva origem, fator e observações; legado mantém significado',
    () {
      final params = base.copyWith(
        manejoSulco: ManejoSulco.reduzida,
        origemVazaoReduzida: OrigemVazaoReduzida.informada,
        vazaoReduzidaLs: .75,
        fator11Vib: true,
        vazaoEnsaioAvancoLs: 1,
        condicoesEnsaioAvanco: conditions,
        ensaioErosao: const EnsaioErosaoSulco(
          vazaoLs: 1.5,
          condicoes: conditions,
          erosaoObservada: true,
        ),
      );
      final now = DateTime(2026, 10, 6);
      final saved = CenarioSalvo(
        id: 'test',
        nome: 'sulco',
        metodo: MetodoIrrigacao.sulco,
        parametros: params,
        resultado: RunFurrowSimulation()(params),
        dataCriacao: now,
        dataModificacao: now,
      );
      final map = saved.toMap();
      final restored = CenarioSalvo.fromMap(map).parametros;
      expect(restored.origemVazaoReduzida, OrigemVazaoReduzida.informada);
      expect(restored.ensaioErosao!.erosaoObservada, isTrue);
      expect(restored.ensaioErosao!.condicoes, conditions);
      expect(restored.fator11Vib, isTrue);
      expect(restored.vazaoEnsaioAvancoLs, 1);
      final legacy = Map<String, dynamic>.from(map);
      final legacyParams = Map<String, dynamic>.from(map['parametros'] as Map);
      legacyParams.remove('origemVazaoReduzida');
      legacyParams.remove('ensaioErosao');
      legacyParams.remove('vazaoEnsaioAvancoLs');
      legacy['parametros'] = legacyParams;
      expect(
        CenarioSalvo.fromMap(legacy).parametros.origemVazaoReduzida,
        OrigemVazaoReduzida.informada,
      );
      expect(CenarioSalvo.fromMap(legacy).parametros.ensaioErosao, isNull);
    },
  );

  test('exportação identifica F23 e usa qr calculada no relatório', () async {
    final params = base.copyWith(
      k: .5,
      a: .5,
      vib: 7.9 / 60000,
      manejoSulco: ManejoSulco.reduzida,
      origemVazaoReduzida: OrigemVazaoReduzida.vib,
      fator11Vib: true,
      ensaioErosao: const EnsaioErosaoSulco(
        vazaoLs: 1.5,
        condicoes: conditions,
        erosaoObservada: true,
      ),
    );
    final result = RunFurrowSimulation()(params);
    final saved = CenarioSalvo(
      id: 'vib',
      nome: 'F23',
      metodo: MetodoIrrigacao.sulco,
      parametros: params,
      resultado: result,
      dataCriacao: DateTime(2026),
      dataModificacao: DateTime(2026),
    );
    final store = ProjectStore(
      listar: () async => [saved],
      salvar: (_) async {},
      buscarPorId: (_) async => saved,
      excluir: (_) async {},
    );
    final inputs =
        (await store.exportarJson(saved))['parametros'] as Map<String, dynamic>;
    expect(inputs['origem_vazao_reduzida'], 'vib');
    expect(inputs['fator_1_1_vib'], true);
    expect((inputs['ensaio_erosao'] as Map)['erosao_observada'], true);
    final exportedResult =
        (await store.exportarJson(saved))['resultado'] as Map<String, dynamic>;
    expect(exportedResult['indicadores_balanco_sulco'], isA<Map>());
    final report = await store.exportarRelatorio(saved);
    expect(
      report,
      contains(
        'Vazão reduzida (vib): ${result.metricas['Vazão reduzida']!.toStringAsFixed(3)} L/s',
      ),
    );
    expect(report, contains('Perfil condicionado'));
    expect(report, contains('Ea do slide (Lf/Lm):'));
    expect(report, contains('Ea integral (Lútil/Lm, domínio 0–L):'));
  });

  test('trocar a origem limpa vazão informada antiga antes de estimar', () {
    final controller = ParametersController();
    controller.setManejoSulco(ManejoSulco.reduzida);
    controller.setOrigemVazaoReduzida(OrigemVazaoReduzida.informada);
    controller.updateField(campo: 'vazaoReduzidaLs', valor: '0.75');
    controller.setOrigemVazaoReduzida(OrigemVazaoReduzida.vib);
    expect(controller.state.vazaoReduzidaLs, 0);
    final params = controller.state.toIrrigationParameters().copyWith(
      k: .5, a: .5,
    );
    expect(params.origemVazaoReduzida, OrigemVazaoReduzida.vib);
    expect(
      RunFurrowSimulation()(params).metricas['Vazão reduzida estimada por VIB'],
      isNotNull,
    );
  });
}
