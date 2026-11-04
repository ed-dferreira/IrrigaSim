import 'dart:io';

/// Grava `bytes` no arquivo em `caminho`, com flush para garantir a
/// persistência. Retorna o caminho gravado.
Future<String> gravarArquivo(String caminho, List<int> bytes) async {
  await File(caminho).writeAsBytes(bytes, flush: true);
  return caminho;
}
