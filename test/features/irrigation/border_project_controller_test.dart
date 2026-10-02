import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';

void main() {
  test('IRN calculada usa somente agronomia informada; campo removido volta a pendente', () {
    final container = ProviderContainer();
    final controller = container.read(borderProjectProvider.notifier);
    controller.setOrigemIrn(OrigemIrnFaixa.calculada);
    expect(container.read(borderProjectProvider).irnEfetivaMm, isNull);
    expect(container.read(borderProjectProvider).impedimentoModelo, isNotNull);
    for (final entry in {
      'uccPercentual': 30,
      'upmpPercentual': 15,
      'densidadeGcm3': 1.4,
      'profundidadeRaizesCm': 40,
      'fracaoDisponivel': .5,
      'evapotranspiracaoMmDia': 7.2,
      'precipitacaoEfetivaMmDia': 0,
    }.entries) {
      controller.setNumero(entry.key, entry.value.toString());
    }
    expect(container.read(borderProjectProvider).irnEfetivaMm, closeTo(42, 1e-8));
    controller.setNumero('uccPercentual', '');
    expect(container.read(borderProjectProvider).irnEfetivaMm, isNull);
    container.dispose();
  });

  test('apagar oferta ou altura não reaproveita dado anterior', () {
    final container = ProviderContainer();
    final controller = container.read(borderProjectProvider.notifier);
    controller.setNumero('alturaDiqueM', '.1');
    controller.setNumero('alturaDiqueM', '');
    expect(container.read(borderProjectProvider).alturaDiqueM, isNull);
    container.dispose();
  });
}
