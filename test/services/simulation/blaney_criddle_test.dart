import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto.dart';
import 'package:irrigasim/shared/irrigacao/services/blaney_criddle.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

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
      final controller = ControladorParametrosSulco();
      controller.definirDimensionarComprimentoCriddle(true);
      controller.definirMetodoEtc(MetodoEtc.blaneyCriddle);
      controller.atualizarCampo(campo: 'temperaturaMediaC', valor: '25');
      controller.atualizarCampo(campo: 'latitudeGraus', valor: '-23.5');
      controller.definirMesReferencia(1);

      final state = controller.state;
      expect(state.etoBlaneyCriddle, greaterThan(0));
      expect(state.laminaRequeridaResultado, isNotNull);
      expect(state.provenienciaGeometria, ProvenienciaDado.calculado);
      expect(state.dimensionarComprimentoCriddle, isTrue);
      expect(state.mensagemPlanejamento, contains('regra prática de Criddle'));
    });

    test('redimensiona automaticamente quando muda a curva de infiltração', () {
      final controller = ControladorParametrosSulco();
      controller.definirDimensionarComprimentoCriddle(true);
      final comprimentoInicial = controller.state.comprimento;

      controller.atualizarCampo(campo: 'k', valor: '5');

      expect(controller.state.dimensionarComprimentoCriddle, isTrue);
      expect(
        controller.state.provenienciaGeometria,
        ProvenienciaDado.calculado,
      );
      expect(controller.state.comprimento, isNot(comprimentoInicial));
    });

    test('persiste as entradas climatológicas e o método', () {
      const inputs = EntradasProjeto(
        metodoEtc: MetodoEtc.blaneyCriddle,
        dimensionarComprimentoCriddle: true,
        temperaturaMediaC: 25,
        latitudeGraus: -23.5,
        mesReferencia: 1,
      );

      final decoded = EntradasProjeto.fromMap(inputs.toMap());

      expect(decoded.metodoEtc, MetodoEtc.blaneyCriddle);
      expect(decoded.dimensionarComprimentoCriddle, isTrue);
      expect(decoded.temperaturaMediaC, 25);
      expect(decoded.latitudeGraus, -23.5);
      expect(decoded.mesReferencia, 1);
    });
  });
}
