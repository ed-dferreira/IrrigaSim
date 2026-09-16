import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/controllers/parameters_controller.dart';
import 'package:irrigasim/features/perfil/controllers/perfil_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final userName = ref.watch(authProvider).user?.nome ?? 'Usuário';
    final firstName = userName.trim().split(' ').first;
    final isDark = ref.watch(
      perfilProvider.select((state) => state.temaEscuro),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Olá, $firstName',
                                    style: text.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'O que você deseja simular hoje?',
                                  style: text.bodyLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: isDark
                                ? 'Usar tema claro'
                                : 'Usar tema escuro',
                            child: IconButton.filledTonal(
                              onPressed: () => ref
                                  .read(perfilProvider.notifier)
                                  .alternarTemaEscuro(!isDark),
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _StartCard(onStart: () => context.push('/home/tutorial')),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        child: Text(
                          'Ou comece pelo método',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Para quem já conhece os parâmetros e quer ir direto à configuração.',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MethodsGrid(
                        onSelect: (method) =>
                            _startSimulation(context, ref, method),
                      ),
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

  void _startSimulation(
    BuildContext context,
    WidgetRef ref,
    MetodoIrrigacao method,
  ) {
    ref.read(parametersProvider.notifier).setMetodo(method);
    context.push('/home/irrigation/parameters');
  }
}

class _StartCard extends StatelessWidget {
  final VoidCallback onStart;
  const _StartCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Iniciar uma nova simulação de irrigação',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(AppIcons.logoApp, color: colors.onPrimary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nova simulação guiada',
                  style: text.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Responda um passo de cada vez. Nós explicamos os parâmetros e preparamos a configuração para você.',
                  style: text.bodyLarge?.copyWith(
                    color: colors.onPrimary.withValues(alpha: .86),
                    height: 1.4,
                  ),
                ),
              ],
            );
            final button = ElevatedButton.icon(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.onPrimary,
                foregroundColor: colors.primary,
              ),
              icon: const Icon(AppIcons.simular),
              label: const Text('Começar com ajuda'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, const SizedBox(height: 24), button],
              );
            }
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 40),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 190),
                  child: button,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MethodsGrid extends StatelessWidget {
  final ValueChanged<MetodoIrrigacao> onSelect;
  const _MethodsGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 840
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
              method: MetodoIrrigacao.sulco,
              title: 'Sulcos',
              description: 'Canais entre as linhas de cultivo',
              icon: AppIcons.sulco,
              tone: _CardTone.primary,
              onTap: onSelect,
            ),
            _MethodCard(
              width: width,
              method: MetodoIrrigacao.faixa,
              title: 'Faixas',
              description: 'Lâmina contínua em terreno inclinado',
              icon: AppIcons.faixa,
              tone: _CardTone.secondary,
              onTap: onSelect,
            ),
            _MethodCard(
              width: width,
              method: MetodoIrrigacao.inundacao,
              title: 'Bacia',
              description: 'Talhões nivelados com alagamento controlado',
              icon: AppIcons.inundacao,
              tone: _CardTone.tertiary,
              onTap: onSelect,
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
  final MetodoIrrigacao method;
  final String title;
  final String description;
  final IconData icon;
  final _CardTone tone;
  final ValueChanged<MetodoIrrigacao> onTap;
  const _MethodCard({
    required this.width,
    required this.method,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    required this.onTap,
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
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: '$title. $description. Iniciar simulação.',
        child: Card(
          color: background,
          child: InkWell(
            onTap: () => onTap(method),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
