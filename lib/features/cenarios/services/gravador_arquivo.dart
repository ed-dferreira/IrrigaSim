/// Grava bytes de exportação no destino adequado à plataforma.
///
/// Nas plataformas nativas (Android, iOS, desktop) escreve no caminho
/// escolhido pelo usuário no diálogo do sistema; no navegador, dispara
/// o download do arquivo (o destino é a pasta de downloads do navegador,
/// não escolhível pela app).
///
/// A implementação é resolvida em tempo de compilação via export
/// condicional: `gravador_arquivo_io.dart` para alvos com `dart:io` e
/// `gravador_arquivo_web.dart` para o navegador.
library;

export 'gravador_arquivo_stub.dart'
    if (dart.library.js_interop) 'gravador_arquivo_web.dart'
    if (dart.library.io) 'gravador_arquivo_io.dart';
