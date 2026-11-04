import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardrail da Etapa 9: `lib/shared/` não pode depender de nenhuma feature.
void main() {
  test('lib/shared não importa nem reexporta lib/features', () {
    final diretivas = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');
    final infratores = <String>[];

    final arquivos = Directory('lib/shared')
        .listSync(recursive: true)
        .whereType<File>()
        .where((arquivo) => arquivo.path.endsWith('.dart'));

    for (final arquivo in arquivos) {
      for (final linha in arquivo.readAsLinesSync()) {
        final match = diretivas.firstMatch(linha);
        if (match == null) continue;
        final destino = match.group(1)!;
        if (destino.startsWith('package:irrigasim/features/') ||
            destino.contains('/features/')) {
          infratores.add('${arquivo.path}: $destino');
        }
      }
    }

    expect(infratores, isEmpty, reason: infratores.join('\n'));
  });
}
