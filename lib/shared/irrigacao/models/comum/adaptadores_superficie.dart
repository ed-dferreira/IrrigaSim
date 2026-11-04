import 'irrigacao_comum.dart';

import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/services/registro_codecs.dart';

/// Cenários rápidos usam IrrigationParameters em vez do projeto tipado.
/// A identificação vem do método escolhido, nunca de um padrão implícito.
extension BaseParametrosSuperficie on IrrigationParameters {
  BaseIrrigacao baseComumPara(MetodoIrrigacao metodo) =>
      registroCodecs.obrigatorio(metodo).baseComum(this);
}
