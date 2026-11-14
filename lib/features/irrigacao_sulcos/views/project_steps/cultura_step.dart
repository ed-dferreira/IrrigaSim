import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/cultura/models/crop_presets.dart';
import 'package:irrigasim/shared/cultura/widgets/cultura_step_form.dart';

import 'project_step_widgets.dart';

// ──────────────────────── Step 3: Cultura ────────────────────────

class CulturaStep extends ConsumerWidget {
  const CulturaStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final EstadoParametrosSulco state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(provedorParametrosSulco.notifier);
    // A grade só precisa ser reinicializada quando a predefinição preenche
    // os campos programaticamente; a record com os valores atuais muda de
    // igualdade estrutural exatamente nesses casos (e a cada edição).
    final revision = (
      state.nomeCultura,
      state.kc,
      state.espacamentoFileirasM,
      state.espacamentoPlantasM,
      state.profundidadeRaizesCm,
      state.fracaoAguaDisponivel,
    );
    return StepBentoCard(
      title: 'Cultura e sistema radicular',
      subtitle: 'Informações da cultura para estimativa de demanda hídrica.',
      icon: AppIcons.projetoCultura,
      accent: accent,
      child: CulturaStepForm(
      nomeCultura: state.nomeCultura,
      kc: state.kc,
      espacamentoFileirasM: state.espacamentoFileirasM,
      espacamentoPlantasM: state.espacamentoPlantasM,
      profundidadeRaizesCm: state.profundidadeRaizesCm,
      // Nome canônico do form difere do campo do estado do sulcos.
      fracaoDisponivel: state.fracaoAguaDisponivel,
      presetInicial: _presetSelecionado(state),
      revision: revision,
      onPresetSelecionado: (preset) {
        controller.definirNomeCultura(preset.name);
        for (final entry in {
          'kc': preset.kc,
          'espacamentoFileirasM': preset.rows,
          'espacamentoPlantasM': preset.plants,
          'profundidadeRaizesCm': preset.roots,
          'fracaoAguaDisponivel': preset.fraction,
        }.entries) {
          controller.atualizarCampo(
            campo: entry.key,
            valor: entry.value.toString(),
          );
        }
      },
      onCampoAlterado: (campo, texto) => controller.atualizarCampo(
        campo: campo == 'fracaoDisponivel' ? 'fracaoAguaDisponivel' : campo,
        valor: texto,
      ),
      onNomeAlterado: controller.definirNomeCultura,
      footer: LaminaRequeridaCard(
        resultado: state.laminaRequeridaResultado,
        areaHectares: state.areaHectares,
      ),
      ),
    );
  }
}

/// Predefinição correspondente ao estado atual, via matcher compartilhado.
CropPreset? _presetSelecionado(EstadoParametrosSulco state) =>
    selectedCropPreset(
      cultura: state.nomeCultura,
      kc: state.kc,
      rows: state.espacamentoFileirasM,
      plants: state.espacamentoPlantasM,
      roots: state.profundidadeRaizesCm,
      fraction: state.fracaoAguaDisponivel,
    );
