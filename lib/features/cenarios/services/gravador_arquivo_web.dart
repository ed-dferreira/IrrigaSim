import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Dispara o download de `bytes` no navegador, usando `nomeArquivo` como
/// nome sugerido; o destino é a pasta de downloads configurada pelo
/// navegador (a app não consegue escolher caminhos no disco remoto).
///
/// Retorna o nome do arquivo, para exibição na interface.
Future<String> gravarArquivo(String nomeArquivo, List<int> bytes) async {
  final dados = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob(
    [dados].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);

  final ancora = web.HTMLAnchorElement()
    ..href = url
    ..download = nomeArquivo;
  // Alguns navegadores ignoram o clique em elementos fora do documento,
  // então a âncora é anexada antes de disparar o download.
  web.document.body?.appendChild(ancora);
  ancora.click();
  ancora.remove();

  web.URL.revokeObjectURL(url);
  return nomeArquivo;
}
