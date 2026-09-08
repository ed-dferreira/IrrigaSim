import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/tutorial/presentation/wizard_view_model.dart';

class TutorialScreen extends ConsumerWidget {
  const TutorialScreen({super.key});

  static const _titulosEtapa = [
    'Método de Irrigação (Superfície)',
    'Solo & Requerimento de Água',
    'Geometria & Topografia',
    'Manejo Hidráulico & Operação',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            color: colors.primaryContainer,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guia Didático — Aula 5',
                      style: textStyles.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.pularTutorial,
                            color: colors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pular Tutorial',
                            style: textStyles.labelMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Etapa ${state.etapa} de 4: ${_titulosEtapa[state.etapa - 1]}',
                  style: textStyles.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.etapa / 4,
                    minHeight: 6,
                    backgroundColor: colors.primaryContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: switch (state.etapa) {
                1 => _etapa1Metodo(context, state, notifier, colors, textStyles),
                2 => _etapa2Solo(context, state, notifier, colors, textStyles),
                3 => _etapa3Geometria(context, state, notifier, colors, textStyles),
                _ => _etapa4Manejo(context, ref, state, notifier, colors, textStyles),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _etapa1Metodo(
    BuildContext context,
    WizardState state,
    WizardViewModel notifier,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final metodos = [
      (MetodoIrrigacao.sulco, 'Sulcos (Furrow)', 'Água escoa em canais paralelos entre as fileiras da cultura.'),
      (MetodoIrrigacao.faixa, 'Faixa (Border)', 'Água escoa em lâmina contínua em faixas delimitadas.'),
      (MetodoIrrigacao.inundacao, 'Inundação / Bacia', 'Talhões nivelados cercados por taipas (ex.: arroz irrigado).'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fundamentos da Aula 5 — Irrigação por Superfície',
          style: textStyles.titleMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'A água é aplicada diretamente no solo, escoando por gravidade ao longo do terreno.',
          style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ...metodos.map((m) {
          final (enumVal, titulo, desc) = m;
          final selected = state.metodo == enumVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: selected
                    ? BorderSide(color: colors.primary, width: 2)
                    : BorderSide.none,
              ),
              color: selected
                  ? colors.primaryContainer.withValues(alpha: 0.5)
                  : colors.surface,
              child: InkWell(
                onTap: () => notifier.selecionarMetodo(enumVal),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: selected ? colors.primary : colors.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: textStyles.titleMedium?.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              desc,
                              style: textStyles.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => notifier.avancarEtapa(),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Avançar: Solo & Cultura →',
              style: textStyles.titleMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _etapa2Solo(
    BuildContext context,
    WizardState state,
    WizardViewModel notifier,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final presets = [
      ('arenoso', 'Arenoso'),
      ('franco', 'Franco'),
      ('argiloso', 'Argiloso'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa 2 — Solo & Requerimento da Cultura',
          style: textStyles.titleMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione um perfil de solo ou insira os parâmetros do modelo Kostiakov-Lewis.',
          style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text('Presets de Solo Agrícola', style: textStyles.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: presets.map((p) {
            final (preset, label) = p;
            final selected = state.tipoSoloPreset == preset;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => notifier.aplicarPresetSolo(preset),
                  selectedColor: colors.primaryContainer,
                  checkmarkColor: colors.onPrimaryContainer,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _campo(context, 'Coeficiente k (mm/hᵃ)', state.k, (v) => notifier.atualizarK(v)),
        _campo(context, 'Expoente a (0 < a < 1)', state.a, (v) => notifier.atualizarA(v)),
        _campo(context, 'Taxa de Infiltração Básica VIB (mm/h)', state.vib, (v) => notifier.atualizarVib(v)),
        const SizedBox(height: 4),
        Container(width: double.infinity, height: 1, color: colors.outlineVariant),
        const SizedBox(height: 4),
        _campo(context, 'Lâmina Líquida Requerida LN (mm)', state.lamina, (v) => notifier.atualizarLamina(v)),
        const SizedBox(height: 16),
        _botoesVoltarAvancar(notifier.voltarEtapa, notifier.avancarEtapa),
      ],
    );
  }

  Widget _etapa3Geometria(
    BuildContext context,
    WizardState state,
    WizardViewModel notifier,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa 3 — Geometria & Declividade do Terreno',
          style: textStyles.titleMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Meça o desnível vertical e a distância horizontal entre pontos para o cálculo exato da declividade.',
          style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _campo(context, 'Comprimento do terreno L (m)', state.comprimento, (v) => notifier.atualizarComprimento(v)),
        Row(
          children: [
            Expanded(
              child: _campo(context, 'Desnível ΔH (m)', state.desnivelM, (v) => notifier.atualizarDesnivel(v)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campo(context, 'Distância horiz. L (m)', state.distanciaHorizontalM, (v) => notifier.atualizarDistanciaHorizontal(v)),
            ),
          ],
        ),
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text('📐', style: textStyles.headlineSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Declividade S₀ = ${state.declividadeCalculada.toStringAsFixed(3)}%',
                        style: textStyles.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Fórmula: (ΔH / L) × 100 = (${state.desnivelValor.toStringAsFixed(2)} / ${state.distanciaValor.toStringAsFixed(0)}) × 100',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _campo(
          context,
          state.metodo == MetodoIrrigacao.sulco
              ? 'Espaçamento entre sulcos (m)'
              : 'Largura (m)',
          state.larguraOuEspacamento,
          (v) => notifier.atualizarLarguraOuEspacamento(v),
        ),
        const SizedBox(height: 16),
        _botoesVoltarAvancar(notifier.voltarEtapa, notifier.avancarEtapa),
      ],
    );
  }

  Widget _etapa4Manejo(
    BuildContext context,
    WidgetRef ref,
    WizardState state,
    WizardViewModel notifier,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa 4 — Manejo Hidráulico & Operação',
          style: textStyles.titleMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 16),
        _campo(
          context,
          state.metodo == MetodoIrrigacao.sulco
              ? 'Vazão por sulco Q (L/s)'
              : state.metodo == MetodoIrrigacao.faixa
                  ? 'Vazão unitária qu (L/s/m)'
                  : 'Vazão total da bacia Q (L/s)',
          state.vazao,
          (v) => notifier.atualizarVazao(v),
        ),
        _campo(context, 'Tempo de aplicação Tap (min)', state.tempo, (v) => notifier.atualizarTempo(v)),
        _campo(context, 'Coeficiente de Manning n', state.manningN, (v) => notifier.atualizarManningN(v)),
        const SizedBox(height: 16),
        Card(
          color: colors.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo da Configuração',
                  style: textStyles.titleSmall?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 6),
                Text('• Método: ${state.metodo.displayName}', style: textStyles.bodyMedium),
                Text(
                  '• Terreno: ${state.comprimento}m de extensão, S₀ = ${state.declividadeCalculada.toStringAsFixed(2)}%',
                  style: textStyles.bodyMedium,
                ),
                Text(
                  '• Solo: k=${state.k}, a=${state.a}, VIB=${state.vib} mm/h',
                  style: textStyles.bodyMedium,
                ),
                Text(
                  '• Operação: Q = ${state.vazao} L/s por ${state.tempo} min | LN = ${state.lamina} mm',
                  style: textStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.voltarEtapa(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('← Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  final params = state.toIrrigationParameters();
                  ref.read(parametersProvider.notifier).setMetodo(state.metodo);
                  ref.read(parametersProvider.notifier).loadFromParams(params);
                  context.go('/home/irrigation/parameters');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Executar Simulação',
                  style: textStyles.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botoesVoltarAvancar(VoidCallback onVoltar, VoidCallback onAvancar) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onVoltar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('← Voltar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onAvancar,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Avançar →'),
          ),
        ),
      ],
    );
  }

  Widget _campo(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
