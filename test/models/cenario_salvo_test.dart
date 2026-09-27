import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/cenario_salvo.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';

void main() {
  test('round-trips reduced-flow operation and optional furrow geometry', () {
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
      perdasConducaoLs: 0.2,
      nomeCultura: 'Milho',
      kc: 1.15,
      espacamentoFileirasM: 0.9,
      espacamentoPlantasM: 0.25,
      larguraSulcoM: 0.25,
    );
    final scenario = CenarioSalvo(
      id: 'scenario-1',
      nome: 'Milho reduzida',
      metodo: MetodoIrrigacao.sulco,
      parametros: parameters,
      resultado: const SimulationResult(
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
        perfilLongitudinal: [],
        resumoTextual: '',
      ),
      dataCriacao: now,
      dataModificacao: now,
    );

    final restored = CenarioSalvo.fromMap(scenario.toMap(), id: scenario.id);

    expect(restored.parametros.manejoSulco, ManejoSulco.reduzida);
    expect(restored.parametros.vazaoReduzidaLs, 0.75);
    expect(restored.parametros.tempoMudancaMin, 90);
    expect(restored.parametros.jornadaDiariaH, 12);
    expect(restored.parametros.perdasConducaoLs, 0.2);
    expect(restored.parametros.nomeCultura, 'Milho');
    expect(restored.parametros.larguraSulcoM, 0.25);
    expect(restored.parametros.profundidadeSulcoM, isNull);
  });
}
