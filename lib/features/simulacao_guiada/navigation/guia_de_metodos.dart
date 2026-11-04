import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Métodos apresentados pela simulação guiada.
///
/// A feature guiada só conhece o destino de cada método; ela não calcula,
/// não salva cenário e não lê o estado dos controllers das outras features.
enum MetodoGuiado { sulcos, faixas, inundacao }

extension MetodoGuiadoDestino on MetodoGuiado {
  String get rota => switch (this) {
    MetodoGuiado.sulcos => AppRoutes.sulcosTipo,
    MetodoGuiado.faixas => AppRoutes.faixasProjeto,
    MetodoGuiado.inundacao => AppRoutes.inundacaoProjeto,
  };
}

extension MetodoGuiadoConversao on MetodoIrrigacao {
  MetodoGuiado get guiado => switch (this) {
    MetodoIrrigacao.sulco => MetodoGuiado.sulcos,
    MetodoIrrigacao.faixa => MetodoGuiado.faixas,
    MetodoIrrigacao.inundacao => MetodoGuiado.inundacao,
  };
}

/// Único lugar que traduz a escolha do método em navegação.
void abrirMetodoGuiado(BuildContext context, MetodoIrrigacao metodo) {
  context.push(metodo.guiado.rota);
}
