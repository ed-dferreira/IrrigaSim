import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';

class ParameterForm extends ConsumerWidget {
  const ParameterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secaoTitulo('Geometria'),
          _campo(
            label: 'Comprimento (m)',
            value: state.comprimento,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'comprimento', valor: v),
          ),
          _campo(
            label: 'Declividade (m/m)',
            value: state.declividade,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'declividade', valor: v),
          ),
          _campo(
            label: 'Largura / Espaçamento (m)',
            value: state.larguraOuEspacamento,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'larguraOuEspacamento', valor: v),
          ),
          const SizedBox(height: 16),
          _secaoTitulo('Solo (Kostiakov-Lewis)'),
          _campo(
            label: 'k',
            value: state.k,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'k', valor: v),
          ),
          _campo(
            label: 'a',
            value: state.a,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'a', valor: v),
          ),
          _campo(
            label: 'vib (mm/min)',
            value: state.vib,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'vib', valor: v),
          ),
          const SizedBox(height: 16),
          _secaoTitulo('Operação'),
          _campo(
            label: 'Vazão (L/s)',
            value: state.vazao,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'vazao', valor: v),
          ),
          _campo(
            label: 'Tempo de Aplicação (min)',
            value: state.tempoAplicacao,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'tempoAplicacao', valor: v),
          ),
          _campo(
            label: 'Lâmina Requerida (mm)',
            value: state.laminaRequerida,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'laminaRequerida', valor: v),
          ),
          const SizedBox(height: 16),
          _secaoTitulo('Hidráulica'),
          _campo(
            label: 'Manning N',
            value: state.manningN,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'manningN', valor: v),
          ),
          _campo(
            label: 'SigmaZ',
            value: state.sigmaZ,
            onChanged: (v) => ref.read(parametersProvider.notifier).updateField(campo: 'sigmaZ', valor: v),
          ),
        ],
      ),
    );
  }

  Widget _secaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(titulo, style: AppTextStyles.heading3),
    );
  }

  Widget _campo({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (text) {
          final parsed = double.tryParse(text.replaceAll(',', '.'));
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }
}
