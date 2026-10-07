import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/sulcos/curva_infiltracao_sulco.dart';
import 'package:irrigasim/models/sulcos/entradas_projeto_sulco.dart';
import 'package:irrigasim/services/simulation/blaney_criddle.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

void main() {
  group('Blaney–Criddle', () {
    test('estima ETo positiva a partir de temperatura, latitude e mês', () {
      final eto = BlaneyCriddle.etoMmDia(
        temperaturaMediaC: 25,
        latitudeGraus: -23.5,
        mes: 1,
      );

      expect(eto, greaterThan(0));
      expect(eto, lessThan(15));
    });

    test('rejeita latitude e mês fora do domínio', () {
      expect(
        () => BlaneyCriddle.etoMmDia(
          temperaturaMediaC: 25,
          latitudeGraus: 90,
          mes: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BlaneyCriddle.etoMmDia(
          temperaturaMediaC: 25,
          latitudeGraus: 0,
          mes: 13,
        ),
        throwsArgumentError,
      );
    });

    test('estima água e dimensiona o comprimento no modo Blaney–Criddle', () {
      final controller = ParametersController();
      controller.setDimensionarComprimentoCriddle(true);
      controller.setMetodoEtc(MetodoEtcSulco.blaneyCriddle);
      controller.updateField(campo: 'temperaturaMediaC', valor: '25');
      controller.updateField(campo: 'latitudeGraus', valor: '-23.5');
      controller.setMesReferencia(1);

      final state = controller.state;
      expect(state.etoBlaneyCriddle, greaterThan(0));
      expect(state.laminaRequeridaResultado, isNotNull);
      expect(state.origemGeometria, ProvenienciaSulco.calculado);
      expect(state.dimensionarComprimentoCriddle, isTrue);
      expect(state.mensagemPlanejamento, contains('regra prática de Criddle'));
    });

    test('redimensiona automaticamente quando muda a curva de infiltração', () {
      final controller = ParametersController();
      controller.setDimensionarComprimentoCriddle(true);
      final comprimentoInicial = controller.state.comprimento;

      controller.updateField(campo: 'k', valor: '5');

      expect(controller.state.dimensionarComprimentoCriddle, isTrue);
      expect(controller.state.origemGeometria, ProvenienciaSulco.calculado);
      expect(controller.state.comprimento, isNot(comprimentoInicial));
    });

    test('persiste as entradas climatológicas e o método', () {
      const inputs = EntradasProjetoSulco(
        metodoEtc: MetodoEtcSulco.blaneyCriddle,
        dimensionarComprimentoCriddle: true,
        temperaturaMediaC: 25,
        latitudeGraus: -23.5,
        mesReferencia: 1,
      );

      final decoded = EntradasProjetoSulco.fromMap(inputs.toMap());

      expect(decoded.metodoEtc, MetodoEtcSulco.blaneyCriddle);
      expect(decoded.dimensionarComprimentoCriddle, isTrue);
      expect(decoded.temperaturaMediaC, 25);
      expect(decoded.latitudeGraus, -23.5);
      expect(decoded.mesReferencia, 1);
    });
  });
}
