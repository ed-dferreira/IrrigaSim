import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';
import 'package:irrigasim/models/sulcos/curva_infiltracao_sulco.dart';
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
        controller.updateField(campo: 'vazaoEnsaioAvancoLs', valor: '1');
        controller.setCondicoesEnsaioAvanco(
          'Solo médio, seção em V e orientação ensaiada',
        );
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

    test('dimensiona comprimento por Criddle com curva de avanço estimada', () {
      final controller = ParametersController();

      controller.dimensionarComprimentoCriddle();

      final state = controller.state;
      expect(state.mensagemPlanejamento, contains('regra prática de Criddle'));
      expect(state.tempoAplicacao, closeTo(130.2, 0.5));
      expect(
        state.tempoAvancoFinalMin,
        closeTo(state.tempoAplicacao / 4, 1e-8),
      );
      expect(state.comprimento, greaterThan(0));
      expect(state.origemGeometria, ProvenienciaSulco.calculado);
      expect(
        state.comprimento,
        lessThanOrEqualTo(state.comprimentoMaximoTerrenoM),
      );
    });

    test('dimensiona pela curva ajustada e rejeita falta de cobertura', () {
      final controller = ParametersController();
      controller.updateField(campo: 'comprimentoMaximoTerrenoM', valor: '200');
      controller.setOrigemAvanco(OrigemAvanco.ensaio);
      controller.updateField(campo: 'vazaoEnsaioAvancoLs', valor: '1');
      controller.setCondicoesEnsaioAvanco('Solo, seção e orientação do ensaio');
      controller.setPontosEnsaioAvanco(const [
        PontoEnsaio(distanciaM: 0, tempoMin: 0),
        PontoEnsaio(distanciaM: 50, tempoMin: 20),
        PontoEnsaio(distanciaM: 100, tempoMin: 40),
        PontoEnsaio(distanciaM: 150, tempoMin: 60),
        PontoEnsaio(distanciaM: 200, tempoMin: 90),
      ]);

      controller.dimensionarComprimentoCriddle();

      expect(controller.state.mensagemPlanejamento, contains('L='));
      expect(
        controller.state.tempoAvancoFinalMin,
        closeTo(controller.state.tempoAplicacao / 4, 1e-8),
      );
      expect(controller.state.comprimento, lessThanOrEqualTo(200));

      controller.updateField(campo: 'k', valor: '0.05');
      controller.updateField(campo: 'a', valor: '0.5');
      controller.dimensionarComprimentoCriddle();
      expect(
        controller.state.mensagemPlanejamento,
        contains('excede o último tempo medido'),
      );
    });
  });
}
