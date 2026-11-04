import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

/// Escala de espaçamento das telas de projeto e resultado por superfície.
class IrrigationSpacing {
  const IrrigationSpacing._();

  static const compact = 8.0;
  static const field = 12.0;
  static const section = 16.0;
  static const major = 20.0;
  static const page = 24.0;
}

/// Padrão comum da etapa atual nos projetos de sulcos e faixas.
class IrrigationProjectStepCard extends StatelessWidget {
  const IrrigationProjectStepCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: IrrigationSpacing.compact / 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: IrrigationSpacing.major),
          child,
        ],
      ),
    ),
  );
}

/// Navegação responsiva e acessível compartilhada pelos projetos de irrigação.
class IrrigationStepIndicator extends StatefulWidget {
  const IrrigationStepIndicator({
    super.key,
    required this.titles,
    required this.icons,
    required this.currentStep,
    required this.completedSteps,
    required this.accent,
    required this.onStepTapped,
  });

  final List<String> titles;
  final List<IconData> icons;
  final int currentStep;
  final Set<int> completedSteps;
  final Color accent;
  final ValueChanged<int> onStepTapped;

  @override
  State<IrrigationStepIndicator> createState() =>
      _IrrigationStepIndicatorState();
}

class _IrrigationStepIndicatorState extends State<IrrigationStepIndicator> {
  final _controller = ScrollController();
  late final _keys = List.generate(widget.titles.length, (_) => GlobalKey());
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollAvailability);
  }

  @override
  void didUpdateWidget(covariant IrrigationStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final target = _keys[widget.currentStep].currentContext;
        if (target == null) return;
        Scrollable.ensureVisible(
          target,
          duration: _animationDuration(context),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    }
  }

  Duration _animationDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 250);

  void _updateScrollAvailability() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final back = position.pixels > position.minScrollExtent;
    final forward = position.pixels < position.maxScrollExtent;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
  }

  void _scroll(int direction) {
    final position = _controller.position;
    _controller.animateTo(
      (position.pixels + direction * position.viewportDimension * .7).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: _animationDuration(context),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showArrows = MediaQuery.sizeOf(context).width >= 760;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          if (showArrows)
            IconButton(
              tooltip: 'Ver etapas anteriores',
              onPressed: _canScrollBack ? () => _scroll(-1) : null,
              icon: const Icon(AppIcons.etapasAnteriores),
            ),
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updateScrollAvailability();
                });
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.titles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _step(context, colors, i),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showArrows)
            IconButton(
              tooltip: 'Ver próximas etapas',
              onPressed: _canScrollForward ? () => _scroll(1) : null,
              icon: const Icon(AppIcons.etapasSeguintes),
            ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, ColorScheme colors, int index) {
    final current = index == widget.currentStep;
    final completed = widget.completedSteps.contains(index);
    return Semantics(
      key: _keys[index],
      button: true,
      selected: current,
      label:
          '${completed
              ? 'Preenchida: '
              : current
              ? 'Etapa atual: '
              : ''}'
          '${widget.titles[index]}',
      child: InkWell(
        onTap: () => widget.onStepTapped(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: _animationDuration(context),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: current
                ? widget.accent.withValues(alpha: .12)
                : completed
                ? colors.primaryContainer
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: current
                  ? widget.accent
                  : completed
                  ? colors.primary
                  : colors.outlineVariant,
              width: current ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed ? AppIcons.sucesso : widget.icons[index],
                size: 18,
                color: current
                    ? widget.accent
                    : completed
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${index + 1}. ${widget.titles[index]}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: current
                      ? widget.accent
                      : completed
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
