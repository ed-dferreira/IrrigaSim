import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/ensaios_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/modelo_curva_avanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

void main() {
  group('planejamento de comprimento e avanço', () {
    test('seleciona o maior comprimento viável em incrementos de 50 m', () {
      final controller = ControladorParametrosSulco();
      controller.atualizarCampo(campo: 'comprimentoMaximoTerrenoM', valor: '300');

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
        final controller = ControladorParametrosSulco();
        controller.definirOrigemAvanco(OrigemAvanco.ensaio);
        controller.atualizarCampo(campo: 'vazaoEnsaioAvancoLs', valor: '1');
        controller.definirCondicoesEnsaioAvanco(
          'Solo médio, seção em V e orientação ensaiada',
        );
        controller.definirPontosEnsaioAvanco(const [
          PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
          PontoEnsaioAvanco(distanciaM: 50, tempoMin: 20),
          PontoEnsaioAvanco(distanciaM: 150, tempoMin: 60),
          PontoEnsaioAvanco(distanciaM: 200, tempoMin: 90),
        ]);

        expect(controller.validarEnsaio(), isNull);
        final result = ModeloCurvaAvanco.ajustarDoisPontosPorEstacas(
          controller.state.pontosEnsaioAvanco,
        );
        expect(
          ModeloCurvaAvanco.tempoAvanco(distanciaM: 100, parametros: result),
          closeTo(40, 1e-9),
        );
      },
    );

    test('dimensiona comprimento por Criddle com curva de avanço estimada', () {
      final controller = ControladorParametrosSulco();

      controller.dimensionarComprimentoCriddle();

      final state = controller.state;
      expect(state.mensagemPlanejamento, contains('regra prática de Criddle'));
      expect(state.tempoAplicacao, closeTo(130.2, 0.5));
      expect(
        state.tempoAvancoFinalMin,
        closeTo(state.tempoAplicacao / 4, 1e-8),
      );
      expect(state.comprimento, greaterThan(0));
      expect(state.provenienciaGeometria, ProvenienciaDado.calculado);
      expect(
        state.comprimento,
        lessThanOrEqualTo(state.comprimentoMaximoTerrenoM),
      );
    });

    test('dimensiona pela curva ajustada e rejeita falta de cobertura', () {
      final controller = ControladorParametrosSulco();
      controller.atualizarCampo(campo: 'comprimentoMaximoTerrenoM', valor: '200');
      controller.definirOrigemAvanco(OrigemAvanco.ensaio);
      controller.atualizarCampo(campo: 'vazaoEnsaioAvancoLs', valor: '1');
      controller.definirCondicoesEnsaioAvanco('Solo, seção e orientação do ensaio');
      controller.definirPontosEnsaioAvanco(const [
        PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
        PontoEnsaioAvanco(distanciaM: 50, tempoMin: 20),
        PontoEnsaioAvanco(distanciaM: 100, tempoMin: 40),
        PontoEnsaioAvanco(distanciaM: 150, tempoMin: 60),
        PontoEnsaioAvanco(distanciaM: 200, tempoMin: 90),
      ]);

      controller.dimensionarComprimentoCriddle();

      expect(controller.state.mensagemPlanejamento, contains('L='));
      expect(
        controller.state.tempoAvancoFinalMin,
        closeTo(controller.state.tempoAplicacao / 4, 1e-8),
      );
      expect(controller.state.comprimento, lessThanOrEqualTo(200));

      controller.atualizarCampo(campo: 'k', valor: '0.05');
      controller.atualizarCampo(campo: 'a', valor: '0.5');
      controller.dimensionarComprimentoCriddle();
      expect(
        controller.state.mensagemPlanejamento,
        contains('excede o último tempo medido'),
      );
    });
  });
}
