import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/cenarios/models/simulation_result_model.dart';
import 'package:irrigasim/shared/irrigacao/services/registro_codecs.dart';

class _AnexoFalso implements AnexoSimulacao {
  const _AnexoFalso(this.chave);
  final String chave;
  @override
  Map<String, Object?> toMap() => {'chave': chave};
}

SimulationResult _resultado(Map<String, AnexoSimulacao> anexos) =>
    SimulationResult(
      eficiencia: 0,
      eficienciaRequerimento: 0,
      cuc: 0,
      du: 0,
      laminaMedia: 0,
      laminaRequerida: 0,
      tempoAvanco: 0,
      perdaPercolacao: 0,
      perdaEscoamento: 0,
      curvaAvanco: const [],
      perfilLongitudinal: const [],
      resumoTextual: '',
      anexos: anexos,
    );

void main() {
  setUpAll(registrarCodecs);

  test('ordem das chaves de anexo é a histórica do JSON', () {
    expect(registroCodecs.chavesAnexosIniciais, [
      'resultadoFaixa',
      'balancoSulco',
    ]);
    expect(registroCodecs.chavesAnexosFinais, [
      'planejamentoParcelas',
      'selecaoVazao',
      'volumesArroz',
      'checagemOperacional',
    ]);
  });

  test('toMap posiciona anexos no topo e no fim, como antes', () {
    final chavesAnexos = [
      ...registroCodecs.chavesAnexosIniciais,
      ...registroCodecs.chavesAnexosFinais,
    ];
    final mapa = SimulationResultModel.toMap(
      _resultado({
        for (final chave in chavesAnexos) chave: _AnexoFalso(chave),
      }),
    );
    final chaves = mapa.keys.toList();

    expect(chaves.take(2), ['resultadoFaixa', 'balancoSulco']);
    expect(chaves.indexOf('eficiencia'), 2);
    expect(chaves.skip(chaves.length - 4), [
      'planejamentoParcelas',
      'selecaoVazao',
      'volumesArroz',
      'checagemOperacional',
    ]);
    expect(chaves.indexOf('planejamentoOperacional'), chaves.length - 5);
  });

  test('anexo sem codec registrado falha alto', () {
    expect(
      () => SimulationResultModel.toMap(
        _resultado({'orfa': const _AnexoFalso('orfa')}),
      ),
      throwsStateError,
    );
  });
}
