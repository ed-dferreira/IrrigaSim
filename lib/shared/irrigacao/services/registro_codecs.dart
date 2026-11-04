import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Registry singleton: a ordem de registro define a ordem das chaves de
/// anexo no JSON persistido.
class RegistroCodecs {
  final Map<MetodoIrrigacao, CodecMetodo> _porMetodo = {};

  /// Sobrescreve o codec do método; chamadas repetidas são seguras.
  void registrar(CodecMetodo codec) => _porMetodo[codec.metodo] = codec;

  CodecMetodo? para(MetodoIrrigacao metodo) => _porMetodo[metodo];

  CodecMetodo obrigatorio(MetodoIrrigacao metodo) =>
      _porMetodo[metodo] ??
      (throw StateError(
        'Nenhum codec registrado para o método ${metodo.name}. '
        'Chame registrarCodecs() na inicialização.',
      ));

  List<String> get chavesAnexosIniciais => [
    for (final codec in _porMetodo.values) ...codec.chavesAnexosIniciais,
  ];

  List<String> get chavesAnexosFinais => [
    for (final codec in _porMetodo.values) ...codec.chavesAnexosFinais,
  ];

  Map<String, AnexoSimulacao> decodificarAnexos(Map<String, Object?> mapa) {
    final anexos = <String, AnexoSimulacao>{};
    for (final codec in _porMetodo.values) {
      anexos.addAll(codec.decodificarAnexos(mapa));
    }
    return anexos;
  }
}

final registroCodecs = RegistroCodecs();
