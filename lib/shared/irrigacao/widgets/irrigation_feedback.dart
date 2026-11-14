import 'package:material_ui/material_ui.dart';

/// Tom semântico dos banners do design system de irrigação.
enum IrrigationBannerTone { success, warning, error, info }

/// Banner comum aos resultados dos métodos de irrigação.
class IrrigationBanner extends StatelessWidget {
  const IrrigationBanner({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
    this.semanticsLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final IrrigationBannerTone tone;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      IrrigationBannerTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      IrrigationBannerTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      IrrigationBannerTone.error => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      IrrigationBannerTone.info => (
        colors.surfaceContainerHigh,
        colors.onSurface,
      ),
    };

    final banner = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final label = semanticsLabel;
    if (label == null || label.trim().isEmpty) return banner;
    return Semantics(label: label, container: true, child: banner);
  }
}
