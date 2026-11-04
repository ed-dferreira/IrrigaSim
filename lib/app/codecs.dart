import 'package:irrigasim/features/irrigacao_faixas/services/codec_faixa.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/codec_inundacao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/codec_sulco.dart';
import 'package:irrigasim/shared/irrigacao/services/registro_codecs.dart';

/// Composition root dos codecs dos métodos de irrigação. A ordem define a
/// ordem das chaves de anexo no JSON persistido.
void registrarCodecs() {
  registroCodecs
    ..registrar(const CodecFaixa())
    ..registrar(const CodecSulco())
    ..registrar(const CodecInundacao());
}
