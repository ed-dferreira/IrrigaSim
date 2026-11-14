import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

import '../models/calculos_simulacao.dart';

/// Seção informativa da tela de perfil: lista os cálculos expostos na
/// interface, agrupados pelos três métodos de irrigação e pela base comum.
///
/// Com [expansivel] (padrão), cada método é um card que abre individualmente.
/// Sem ele, todo o conteúdo é renderizado de uma vez, para ficar dentro de um
/// único card expansível.
class CalculosConteudoSection extends StatelessWidget {
  final bool expansivel;

  const CalculosConteudoSection({super.key, this.expansivel = true});

  @override
  Widget build(BuildContext context) {
    if (!expansivel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, modulo) in CalculosSimulacao.modulos.indexed) ...[
            if (index > 0) const SizedBox(height: 22),
            _ModuloHeader(metodo: modulo.metodo, icone: _icone(modulo.metodo)),
            const SizedBox(height: 10),
            for (final calculo in modulo.calculos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CalculoRow(calculo: calculo),
              ),
          ],
        ],
      );
    }

    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final modulo in CalculosSimulacao.modulos) ...[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _icone(modulo.metodo),
                    color: colors.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                title: Text(
                  modulo.metodo,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                iconColor: colors.onSurfaceVariant,
                collapsedIconColor: colors.onSurfaceVariant,
                childrenPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  for (final calculo in modulo.calculos)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _CalculoRow(calculo: calculo),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  IconData _icone(String metodo) => switch (metodo) {
    'Sulcos' => AppIcons.sulco,
    'Faixas' => AppIcons.faixa,
    'Inundação' => AppIcons.inundacao,
    _ => Icons.calculate_outlined,
  };
}

class _ModuloHeader extends StatelessWidget {
  final String metodo;
  final IconData icone;

  const _ModuloHeader({required this.metodo, required this.icone});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: colors.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            metodo,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CalculoRow extends StatelessWidget {
  final CalculoModulo calculo;
  const _CalculoRow({required this.calculo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            calculo.titulo,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            calculo.descricao,
            style: text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (calculo.formula case final formula?) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .5),
                ),
              ),
              child: Text(
                formula,
                style: text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
