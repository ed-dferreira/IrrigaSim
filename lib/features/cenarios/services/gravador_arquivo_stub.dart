/// Fallback do export condicional (plataformas sem `dart:io` nem
/// `dart:js_interop`): nunca deve ser alcançado pelos builds do app.
Future<String> gravarArquivo(String caminho, List<int> bytes) async {
  throw UnsupportedError(
    'Gravação de arquivo não suportada nesta plataforma: $caminho',
  );
}
