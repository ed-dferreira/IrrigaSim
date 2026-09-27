import 'package:flutter_test/flutter_test.dart';
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
    });

    test('valida a distância e a ordem dos tempos do ensaio', () {
      final controller = ParametersController();
      controller.setOrigemAvanco(OrigemAvanco.ensaio);
      controller.updateField(
        campo: 'distanciaEnsaioIntermediariaM',
        valor: '200',
      );

      expect(controller.validarEnsaio(), contains('menor que o comprimento'));

      controller.updateField(
        campo: 'distanciaEnsaioIntermediariaM',
        valor: '100',
      );
      controller.updateField(campo: 'tempoEnsaioIntermediarioMin', valor: '90');

      expect(controller.validarEnsaio(), contains('positivos e crescentes'));

      controller.updateField(campo: 'tempoEnsaioIntermediarioMin', valor: '35');

      expect(controller.validarEnsaio(), isNull);
    });
  });
}
