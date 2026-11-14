import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_results_screen.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_results_screen.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results_screen.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Exibe um cenário salvo nas telas de resultados completas do seu método,
/// sem disparar novo cálculo:
///
/// - faixa e inundação usam a tela de resultados com `projectOverride` /
///   `resultOverride` alimentados pelo projeto tipado e pelo resultado
///   persistidos no próprio cenário;
/// - sulco carrega as entradas no provedor (mesmo fluxo da tela de projeto)
///   e injeta o resultado salvo via `atribuirResultado`, pois a tela de
///   resultados de sulcos depende do estado do controlador.
class CenarioResultadosView extends ConsumerStatefulWidget {
  final CenarioSalvo cenario;

  const CenarioResultadosView({super.key, required this.cenario});

  @override
  ConsumerState<CenarioResultadosView> createState() =>
      _CenarioResultadosViewState();
}

class _CenarioResultadosViewState extends ConsumerState<CenarioResultadosView> {
  @override
  void initState() {
    super.initState();
    if (widget.cenario.metodo == MetodoIrrigacao.sulco) {
      final notifier = ref.read(provedorParametrosSulco.notifier);
      notifier.resetar();
      notifier.carregarDeParametros(widget.cenario.parametros);
      notifier.atribuirResultado(widget.cenario.resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.cenario.metodo) {
      case MetodoIrrigacao.sulco:
        return const ProjectResultsScreen();
      case MetodoIrrigacao.faixa:
        return BorderResultsScreen(
          projectOverride: widget.cenario.parametros.projetoFaixa,
          resultOverride: widget.cenario.resultado,
        );
      case MetodoIrrigacao.inundacao:
        return BasinResultsScreen(
          projectOverride: widget.cenario.parametros.projetoInundacao,
          resultOverride: widget.cenario.resultado,
        );
    }
  }
}
