import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_reference_tables.dart';

void main() {
  const tables = BorderReferenceTables();
  test('limite compartilhado Marr apresenta duas sugestões sem infiltração inventada', () {
    expect(tables.suggest(TexturaSolo.fina, .6).length, 2);
    expect(tables.suggest(TexturaSolo.grossa, .6), isEmpty);
  });
  test('células Booher impressas suspeitas não são usadas automaticamente', () {
    expect(tables.booher(12.5, 10)!.impressoLs, 1.03);
    expect(tables.booher(25, 15)!.revisaoPendente, isTrue);
    expect(tables.booher(35, 15)!.propostoLs, 99.1);
    expect(tables.booher(15, 10)!.revisaoPendente, isFalse);
    expect(tables.booher(16, 10), isNull);
  });

  test('três células suspeitas carregam dado_fonte_suspeito e nunca são sugestão', () {
    final suspeitas = [
      tables.booher(12.5, 10)!,
      tables.booher(25, 15)!,
      tables.booher(35, 15)!,
    ];
    for (final cell in suspeitas) {
      expect(cell.status, BorderStatus.dadoFonteSuspeito);
      expect(cell.status.codigo, 'dado_fonte_suspeito');
      expect(tables.sugestao(cell.diametroCm, cell.cargaCm), isNull);
    }
    // Nenhuma das 49 células é suspeita fora das três conhecidas.
    for (final d in BorderReferenceTables.diametrosCm) {
      for (final c in BorderReferenceTables.cargasCm) {
        final cell = tables.booher(d, c)!;
        final suspeita = cell.status == BorderStatus.dadoFonteSuspeito;
        expect(suspeita, cell.revisaoPendente);
        expect(tables.sugestao(d, c) == null, suspeita);
      }
    }
    expect(tables.sugestao(15, 10), isNotNull);
    expect(tables.sugestao(16, 10), isNull);
    // Marr é orientativa, nunca coeficiente de infiltração.
    expect(tables.suggest(TexturaSolo.fina, .6).first.status,
        BorderStatus.avisoOrientativo);
  });
}
