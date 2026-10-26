import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/parameters_controller.dart';

import 'project_step_widgets.dart';

class CulturaPreset {
  const CulturaPreset(
    this.nome,
    this.kc,
    this.fileiras,
    this.plantas,
    this.raizes,
    this.fracao,
  );

  final String nome;
  final double kc;
  final double fileiras;
  final double plantas;
  final double raizes;
  final double fracao;
}

const culturaPresets = <CulturaPreset>[
  CulturaPreset('Soja', 1.15, 0.45, 0.07, 60, 0.50),
  CulturaPreset('Arroz irrigado', 1.20, 0.17, 0.03, 20, 0.20),
  CulturaPreset('Milho', 1.20, 0.80, 0.20, 100, 0.55),
  CulturaPreset('Trigo', 1.15, 0.17, 0.02, 100, 0.55),
  CulturaPreset('Fumo', 1.10, 1.10, 0.50, 60, 0.30),
  CulturaPreset('Feijão', 1.15, 0.45, 0.07, 50, 0.45),
  CulturaPreset('Cevada', 1.15, 0.17, 0.02, 100, 0.55),
  CulturaPreset('Aveia', 1.15, 0.17, 0.02, 100, 0.55),
  CulturaPreset('Mandioca', 0.80, 1.00, 0.60, 80, 0.35),
  CulturaPreset('Cana-de-açúcar', 1.25, 1.40, 0.50, 120, 0.65),
  CulturaPreset('Uva', 0.70, 2.50, 1.20, 100, 0.35),
  CulturaPreset('Batata', 1.15, 0.80, 0.30, 40, 0.35),
  CulturaPreset('Cebola', 1.05, 0.30, 0.10, 30, 0.30),
  CulturaPreset('Canola', 1.15, 0.35, 0.04, 100, 0.60),
  CulturaPreset('Sorgo', 1.00, 0.50, 0.05, 100, 0.55),
  CulturaPreset('Tomate', 1.15, 1.00, 0.50, 70, 0.40),
  CulturaPreset('Melancia', 1.00, 2.00, 1.00, 80, 0.40),
  CulturaPreset('Amendoim', 1.15, 0.50, 0.10, 50, 0.50),
  CulturaPreset('Triticale', 1.15, 0.17, 0.02, 100, 0.55),
  CulturaPreset('Azevém (forragem)', 1.05, 0.17, 0.02, 40, 0.60),
];

CulturaPreset? culturaPreset(ParametersState state) {
  for (final preset in culturaPresets) {
    if (preset.nome == state.nomeCultura &&
        preset.kc == state.kc &&
        preset.fileiras == state.espacamentoFileirasM &&
        preset.plantas == state.espacamentoPlantasM &&
        preset.raizes == state.profundidadeRaizesCm &&
        preset.fracao == state.fracaoAguaDisponivel) {
      return preset;
    }
  }
  return null;
}

// ──────────────────────── Step 3: Cultura ────────────────────────

class CulturaStep extends ConsumerWidget {
  const CulturaStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StepBentoCard(
    title: 'Cultura e sistema radicular',
    subtitle: 'Informações da cultura para estimativa de demanda hídrica.',
    icon: AppIcons.projetoCultura,
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CulturaPreset?>(
          isExpanded: true,
          initialValue: culturaPreset(state),
          decoration: const InputDecoration(
            labelText: 'Predefinição de cultura',
            helperText: 'Selecione uma cultura para preencher os parâmetros; eles podem ser ajustados depois.',
          ),
          items: [
            const DropdownMenuItem<CulturaPreset?>(
              value: null,
              child: Text('Personalizada / sem predefinição'),
            ),
            ...culturaPresets.map(
              (preset) => DropdownMenuItem<CulturaPreset?>(
                value: preset,
                child: Text(preset.nome),
              ),
            ),
          ],
          onChanged: (preset) {
            if (preset == null) return;
            final controller = ref.read(parametersProvider.notifier);
            controller.setNomeCultura(preset.nome);
            for (final entry in {
              'kc': preset.kc,
              'espacamentoFileirasM': preset.fileiras,
              'espacamentoPlantasM': preset.plantas,
              'profundidadeRaizesCm': preset.raizes,
              'fracaoAguaDisponivel': preset.fracao,
            }.entries) {
              controller.updateField(
                campo: entry.key,
                valor: entry.value.toString(),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        StepFieldGrid(
          key: ValueKey(
            '${state.nomeCultura}-${state.kc}-${state.espacamentoFileirasM}-${state.espacamentoPlantasM}-${state.profundidadeRaizesCm}-${state.fracaoAguaDisponivel}',
          ),
          wide: wide,
          fields: [
            StepStringField(
              name: 'nomeCultura',
              label: 'Nome da cultura',
              value: state.nomeCultura,
              helper: 'Ex: Milho, Soja, Algodão',
            ),
            StepField(
              name: 'kc',
              label: 'Coeficiente da cultura (Kc)',
              value: state.kc,
              helper: '0 a 1,4',
            ),
            StepField(
              name: 'espacamentoFileirasM',
              label: 'Espaçamento entre fileiras',
              value: state.espacamentoFileirasM,
              suffix: 'm',
            ),
            StepField(
              name: 'espacamentoPlantasM',
              label: 'Espaçamento entre plantas',
              value: state.espacamentoPlantasM,
              suffix: 'm',
            ),
            StepField(
              name: 'profundidadeRaizesCm',
              label: 'Profundidade das raízes',
              value: state.profundidadeRaizesCm,
              suffix: 'cm',
            ),
            StepField(
              name: 'fracaoAguaDisponivel',
              label: 'Fração de água disponível',
              value: state.fracaoAguaDisponivel,
              helper: 'Entre 0 e 1',
            ),
          ],
        ),
        const SizedBox(height: 8),
        LaminaRequeridaCard(
          resultado: state.laminaRequeridaResultado,
          areaHectares: state.areaHectares,
        ),
      ],
    ),
  );
}
