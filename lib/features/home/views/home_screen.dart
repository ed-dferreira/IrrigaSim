import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/perfil/perfil.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final userName = ref.watch(perfilProvider.select((state) => state.nome));
    final firstName = userName.trim().isEmpty
        ? 'Usuário'
        : userName.trim().split(' ').first;
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHero(firstName: firstName, portrait: portrait),
                      SizedBox(height: horizontal < 24 ? 18 : 28),
                      Semantics(
                        header: true,
                        child: Text(
                          'Escolha o método',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acesse diretamente a configuração do seu projeto.',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (portrait) ...[
                        const SizedBox(height: 12),
                        const _ChooseGuide(compact: true),
                      ],
                      const SizedBox(height: 12),
                      _MethodsGrid(portrait: portrait),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final String firstName;
  final bool portrait;

  const _HomeHero({required this.firstName, required this.portrait});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final foreground = colors.onPrimaryContainer;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.secondaryContainer],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600 || portrait;
            final wide = constraints.maxWidth >= 760 && !portrait;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: compact ? 40 : 48,
                        height: compact ? 40 : 48,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(
                            compact ? 13 : 15,
                          ),
                        ),
                        child: Icon(AppIcons.logoApp, color: colors.onPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        container: true,
                        header: true,
                        excludeSemantics: true,
                        label: 'Olá, $firstName',
                        child: Text(
                          'Olá, $firstName',
                          style: text.headlineSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 14),
                Text(
                  compact
                      ? 'Simule irrigação por superfície e planeje antes de ir '
                            'a campo.'
                      : 'Simule irrigação por superfície, compare o desempenho '
                            'e planeje antes de ir a campo.',
                  style: (compact ? text.bodyMedium : text.bodyLarge)?.copyWith(
                    color: foreground.withValues(alpha: .85),
                    height: 1.35,
                  ),
                ),
              ],
            );
            return Padding(
              padding: EdgeInsets.all(compact ? 14 : 24),
              child: portrait
                  ? header
                  : wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: header),
                        const SizedBox(width: 28),
                        SizedBox(width: 360, child: const _ChooseGuide()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        SizedBox(height: compact ? 12 : 22),
                        _ChooseGuide(compact: compact),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _ChooseGuide extends StatelessWidget {
  final bool compact;

  const _ChooseGuide({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    final gap = compact ? 8.0 : 12.0;
    return Container(
      key: const Key('home-choose-guide'),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como escolher',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 8 : 12),
          _GuideItem(
            icon: AppIcons.sulco,
            title: 'Sulcos',
            hint: 'Culturas em linha',
            accent: colors.primary,
            onAccent: colors.onPrimary,
            compact: compact,
          ),
          SizedBox(height: gap),
          _GuideItem(
            icon: AppIcons.faixa,
            title: 'Faixas',
            hint: 'Terreno inclinado',
            accent: colors.secondary,
            onAccent: colors.onSecondary,
            compact: compact,
          ),
          SizedBox(height: gap),
          _GuideItem(
            icon: AppIcons.inundacao,
            title: 'Inundação',
            hint: 'Talhões nivelados',
            accent: colors.tertiary,
            onAccent: colors.onTertiary,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Color accent;
  final Color onAccent;
  final bool compact;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.hint,
    required this.accent,
    required this.onAccent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final foreground = colors.onSurface;
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: onAccent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: compact
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hint,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hint,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MethodsGrid extends StatelessWidget {
  final bool portrait;

  const _MethodsGrid({required this.portrait});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final cardHeight = portrait
            ? null
            : 330.0 * (textScale < 1 ? 1 : textScale);
        final columns = portrait
            ? 1
            : constraints.maxWidth >= 840
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MethodCard(
              width: width,
              height: cardHeight,
              compact: portrait,
              route: AppRoutes.sulcosTipo,
              title: 'Sulcos',
              description:
                  'Água conduzida em canais entre as linhas de cultivo.',
              ideal: 'Ideal para culturas em linha',
              icon: AppIcons.sulco,
              tone: _CardTone.primary,
            ),
            _MethodCard(
              width: width,
              height: cardHeight,
              compact: portrait,
              route: AppRoutes.faixasProjeto,
              title: 'Faixas',
              description: 'Lâmina contínua aplicada em faixas do terreno.',
              ideal: 'Ideal para terrenos inclinados',
              icon: AppIcons.faixa,
              tone: _CardTone.secondary,
            ),
            _MethodCard(
              width: width,
              height: cardHeight,
              compact: portrait,
              route: AppRoutes.inundacaoProjeto,
              title: 'Inundação',
              description: 'Alagamento controlado em talhões nivelados.',
              ideal: 'Ideal para áreas niveladas',
              icon: AppIcons.inundacao,
              tone: _CardTone.tertiary,
            ),
          ],
        );
      },
    );
  }
}

enum _CardTone { primary, secondary, tertiary }

class _MethodCard extends StatelessWidget {
  final double width;
  final double? height;
  final bool compact;
  final String route;
  final String title;
  final String description;
  final String ideal;
  final IconData icon;
  final _CardTone tone;

  const _MethodCard({
    required this.width,
    required this.height,
    required this.compact,
    required this.route,
    required this.title,
    required this.description,
    required this.ideal,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (background, foreground) = switch (tone) {
      _CardTone.primary => (colors.primaryContainer, colors.onPrimaryContainer),
      _CardTone.secondary => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      _CardTone.tertiary => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
    };
    void open() => context.push(route);
    final descriptionLabel = description.endsWith('.')
        ? description.substring(0, description.length - 1)
        : description;

    final content = compact
        ? Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: text.titleMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: foreground,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: text.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: .82),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: foreground,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ideal,
                            style: text.labelSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: foreground),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: foreground),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: text.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: text.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: .82),
                  height: 1.35,
                ),
              ),
              if (height != null)
                const Spacer()
              else
                const SizedBox(height: 14),
              if (height != null) const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: foreground,
                    ),
                    Text(
                      ideal,
                      style: text.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: '$title. $descriptionLabel. $ideal. Iniciar simulação.',
        onTap: open,
        child: Card(
          color: background,
          child: InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(compact ? 14 : 20),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
