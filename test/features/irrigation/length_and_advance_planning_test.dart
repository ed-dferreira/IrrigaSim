import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';
import 'package:irrigasim/services/simulation/sulcos/advance_curve_model.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

void main() {
  group('planejamento de comprimento e avanço', () {
    test('seleciona o maior comprimento viável em incrementos de 50 m', () {
      final controller = ParametersController();
      controller.updateField(campo: 'comprimentoMaximoTerrenoM', valor: '300');

      controller.recomendarMaiorComprimento();

      expect(controller.state.comprimento, 300);
      expect(controller.state.tempoAvancoFinalMin, greaterThan(90));
      expect(controller.state.mensagemPlanejamento, contains('300 m'));
      expect(controller.state.mensagemPlanejamento, contains('50 m:'));
      expect(controller.state.mensagemPlanejamento, contains('Q ≤ qmax'));
    });

    test(
      'valida estacas e interpola o ponto médio para o método de dois pontos',
      () {
        final controller = ParametersController();
        controller.setOrigemAvanco(OrigemAvanco.ensaio);
        controller.setPontosEnsaioAvanco(const [
          PontoEnsaio(distanciaM: 0, tempoMin: 0),
          PontoEnsaio(distanciaM: 50, tempoMin: 20),
          PontoEnsaio(distanciaM: 150, tempoMin: 60),
          PontoEnsaio(distanciaM: 200, tempoMin: 90),
        ]);

        expect(controller.validarEnsaio(), isNull);
        final result = AdvanceCurveModel.ajustarDoisPontosPorEstacas(
          controller.state.pontosEnsaioAvanco,
        );
        expect(
          AdvanceCurveModel.tempoAvanco(distanciaM: 100, parametros: result),
          closeTo(40, 1e-9),
        );
      },
    );
  });
}
