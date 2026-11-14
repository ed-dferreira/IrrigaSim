import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

/// Cartão de salvamento de cenário na tela de resultados de sulcos.
class SaveCard extends StatelessWidget {
  const SaveCard({
    super.key,
    required this.state,
    required this.saving,
    required this.onNameChanged,
    required this.onSave,
  });
  final EstadoParametrosSulco state;
  final bool saving;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.salvarCenario, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  'Salvar este projeto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              onChanged: onNameChanged,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: saving ? null : (_) => onSave(),
              decoration: InputDecoration(
                labelText: 'Nome do cenário',
                hintText:
                    'Sulco - ${state.comprimento.toStringAsFixed(0)} m (${state.vazao.toStringAsFixed(2)} L/s)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.salvarCenario),
              label: Text(saving ? 'Salvando...' : 'Salvar na minha conta'),
            ),
          ],
        ),
      ),
    );
  }
}
