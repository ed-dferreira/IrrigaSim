import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

/// Aba de um card de gráficos de irrigação.
class IrrigationChartTab {
  const IrrigationChartTab({required this.label, required this.icon, this.semanticsLabel});

  /// Texto exibido na aba.
  final String label;

  /// Rótulo de acessibilidade; cai para [label] quando não informado.
  final String? semanticsLabel;

  final IconData icon;
}

/// Shell comum dos gráficos: card, cabeçalho, abas horizontais e IndexedStack.
class IrrigationChartSection extends StatelessWidget {
  const IrrigationChartSection({
    super.key,
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.children,
    this.height = 340,
  });

  final String title;
  final List<IrrigationChartTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastTab = tabs.isEmpty ? 0 : tabs.length - 1;
    final clampedIndex = selectedIndex.clamp(0, lastTab);
    final lastChild = children.isEmpty ? 0 : children.length - 1;
    final childIndex = clampedIndex.clamp(0, lastChild);

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
                Icon(AppIcons.chart, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = index == clampedIndex;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: tab.semanticsLabel ?? tab.label,
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 18,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tab.label,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: IndexedStack(index: childIndex, children: children),
            ),
          ],
        ),
      ),
    );
  }
}
