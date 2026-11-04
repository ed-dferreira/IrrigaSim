import 'package:flutter_test/flutter_test.dart';

import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/services/cenarios_exemplo.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

void main() {
  setUpAll(registrarCodecs);

  test('exemplos de teste trazem 2 cenários por método com dados completos', () {
    final exemplos = const CenariosDeExemplo().gerar();

    expect(exemplos.length, 6);
    final nomes = exemplos.map((cenario) => cenario.nome).toSet();
    expect(nomes.length, 6, reason: 'os 6 exemplos devem ter nomes únicos');

    for (final metodo in MetodoIrrigacao.values) {
      final doMetodo = exemplos
          .where((cenario) => cenario.metodo == metodo)
          .toList();
      expect(
        doMetodo.length,
        2,
        reason: 'método ${metodo.name}',
      );
      for (final cenario in doMetodo) {
        expect(cenario.resultado.curvaAvanco, isNotEmpty);
        expect(cenario.resultado.perfilLongitudinal, isNotEmpty);
        expect(cenario.resultado.eficiencia, greaterThan(0));
        expect(cenario.resultado.eficiencia, lessThanOrEqualTo(100));
        // Roundtrip de persistência: gráficos e resultados sobrevivem.
        final restaurado = CenarioSalvo.fromMap(cenario.toMap(), id: cenario.id);
        expect(restaurado.resultado.curvaAvanco, isNotEmpty);
        expect(restaurado.metodo, metodo);
      }
    }
  });
}
