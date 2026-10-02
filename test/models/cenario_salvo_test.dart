import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/cenarios/cenario_salvo.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/services/simulation/operational_planning.dart';
import 'package:irrigasim/services/persistence/project_store.dart';

void main() {
  test(
    'round-trips reduced-flow operation and optional furrow geometry',
    () async {
      final now = DateTime(2026, 9, 23);
      const parameters = IrrigationParameters(
        comprimento: 200,
        declividade: 0.005,
        larguraOuEspacamento: 0.9,
        k: 2.83,
        a: 0.554,
        vib: 0.0001,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        manejoSulco: ManejoSulco.reduzida,
        vazaoReduzidaLs: 0.75,
        tempoMudancaMin: 90,
        jornadaDiariaH: 12,
        periodoIrrigacaoDias: 10,
        tempoMudancaParcelaMin: 25,
        coeficienteAvancoK: .095,
        expoenteAvancoB: 1.3,
        distanciaReferenciaAvancoM: 80,
        perdasConducaoLs: 0.2,
        nomeCultura: 'Milho',
        kc: 1.15,
        espacamentoFileirasM: 0.9,
        espacamentoPlantasM: 0.25,
        larguraSulcoM: 0.25,
        metodoCurvaAvanco: MetodoCurvaAvanco.minimosQuadrados,
        usarEnsaioAvanco: true,
        medicoesAvanco: [
          MedicaoAvanco(distanciaM: 0, tempoMin: 0),
          MedicaoAvanco(distanciaM: 100, tempoMin: 40),
          MedicaoAvanco(distanciaM: 200, tempoMin: 90),
        ],
        origemCurvaInfiltracao: OrigemCurvaInfiltracao.ensaioEntradaSaida,
        distanciaEnsaioInfiltracaoM: 100,
        espacamentoEnsaioInfiltracaoM: 0.9,
        medicoesEntradaSaida: [
          MedicaoEntradaSaida(
            tempoMin: 10,
            vazaoEntradaLs: 1.2,
            vazaoSaidaLs: 0.4,
          ),
          MedicaoEntradaSaida(
            tempoMin: 20,
            vazaoEntradaLs: 1.2,
            vazaoSaidaLs: 0.5,
          ),
        ],
        hipoteseRecessao: HipoteseRecessao.medidaPorEstaca,
        medicoesRecessao: [
          MedicaoRecessao(distanciaM: 0, instanteRecessaoMin: 200),
          MedicaoRecessao(distanciaM: 200, instanteRecessaoMin: 260),
        ],
      );
      final scenario = CenarioSalvo(
        id: 'scenario-1',
        nome: 'Milho reduzida',
        metodo: MetodoIrrigacao.sulco,
        parametros: parameters,
        resultado: SimulationResult(
          eficiencia: 0,
          eficienciaRequerimento: 0,
          cuc: 0,
          du: 0,
          laminaMedia: 0,
          laminaRequerida: 0,
          tempoAvanco: 0,
          perdaPercolacao: 0,
          perdaEscoamento: 0,
          curvaAvanco: [],
          curvaOportunidade: [PontoGrafico(0, 220), PontoGrafico(200, 130)],
          perfilLongitudinal: [],
          resumoTextual: '',
          origemCurvaAvanco: 'ensaio',
          metodoCurvaAvanco: 'minimosQuadrados',
          origemCurvaInfiltracao: 'ensaioEntradaSaida',
          hipoteseRecessao: 'medidaPorEstaca',
          planejamentoOperacional: OperationalPlanning.calcular(
            areaTotalM2: 120000,
            comprimentoSulcoM: 200,
            espacamentoM: 1,
            periodoIrrigacaoDias: 10,
            tempoFornecimentoH: 220 / 60,
            tempoMudancaParcelaH: .5,
            jornadaDiariaH: 14,
            vazaoInicialLs: 1,
          ),
        ),
        dataCriacao: now,
        dataModificacao: now,
      );

      final restored = CenarioSalvo.fromMap(scenario.toMap(), id: scenario.id);

      expect(restored.parametros.manejoSulco, ManejoSulco.reduzida);
      expect(restored.parametros.vazaoReduzidaLs, 0.75);
      expect(restored.parametros.tempoMudancaMin, 90);
      expect(restored.parametros.jornadaDiariaH, 12);
      expect(restored.parametros.periodoIrrigacaoDias, 10);
      expect(restored.parametros.tempoMudancaParcelaMin, 25);
      expect(restored.parametros.coeficienteAvancoK, .095);
      expect(restored.parametros.expoenteAvancoB, 1.3);
      expect(restored.parametros.distanciaReferenciaAvancoM, 80);
      expect(restored.parametros.perdasConducaoLs, 0.2);
      expect(restored.parametros.nomeCultura, 'Milho');
      expect(restored.parametros.larguraSulcoM, 0.25);
      expect(restored.parametros.profundidadeSulcoM, isNull);
      expect(
        restored.parametros.metodoCurvaAvanco,
        MetodoCurvaAvanco.minimosQuadrados,
      );
      expect(restored.parametros.medicoesAvanco, hasLength(3));
      expect(restored.parametros.usarEnsaioAvanco, isTrue);
      expect(
        restored.parametros.origemCurvaInfiltracao,
        OrigemCurvaInfiltracao.ensaioEntradaSaida,
      );
      expect(restored.parametros.medicoesEntradaSaida, hasLength(2));
      expect(
        restored.parametros.hipoteseRecessao,
        HipoteseRecessao.medidaPorEstaca,
      );
      expect(restored.parametros.medicoesRecessao, hasLength(2));
      expect(restored.resultado.curvaOportunidade, hasLength(2));
      expect(restored.resultado.origemCurvaAvanco, 'ensaio');
      expect(restored.resultado.extrapolouAvanco, isFalse);
      expect(
        restored.resultado.planejamentoOperacional?.tipH,
        closeTo(4.1666667, 1e-6),
      );
      expect(
        restored.resultado.planejamentoOperacional?.qProjetoOperacional,
        20,
      );

      final exporter = ProjectStore(
        listar: () async => [],
        salvar: (_) async {},
        buscarPorId: (_) async => null,
        excluir: (_) async {},
      );
      final exported = await exporter.exportarJson(restored);
      final exportedParameters = exported['parametros'] as Map<String, dynamic>;
      final exportedResult = exported['resultado'] as Map<String, dynamic>;
      expect(exportedParameters['medicoes_avanco'], hasLength(3));
      expect(exportedParameters['medicoes_entrada_saida'], hasLength(2));
      expect(exportedParameters['medicoes_recessao'], hasLength(2));
      expect(
        exportedResult['resultado_completo'],
        contains('curvaOportunidade'),
      );
      expect(exportedResult['planejamento_operacional'], contains('tip_h'));
    },
  );
}
