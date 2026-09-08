import 'package:flutter/material.dart';
import 'package:irrigasim/app/app.dart';
import 'package:irrigasim/app/theme/app_animations.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';

class CustomChip<T> extends StatelessWidget {
  final T value;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? selectedColor;

  const CustomChip({
    super.key,
    required this.value,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = selectedColor ?? colorScheme.primary;
    final reduced = AppAccessibility.reducedAnimations(context);

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: animationDuration(reduced, normal: const Duration(milliseconds: 200)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor.withValues(alpha: 0.15) : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? chipColor : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
