import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/viewmodels/perfil/perfil_controller.dart';

import 'package:irrigasim/viewmodels/auth/auth_providers.dart';
import 'widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) context.go('/home');
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            if (wide) {
              final height = constraints.maxHeight < 700
                  ? 700.0
                  : constraints.maxHeight;
              return SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _BrandPanel(
                            onToggleTheme: () => _toggleTheme(ref),
                            rounded: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 32,
                            ),
                            child: const _LoginContent(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: _BrandPanel(
                      onToggleTheme: () => _toggleTheme(ref),
                      rounded: false,
                      compact: true,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 36),
                    child: _LoginContent(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleTheme(WidgetRef ref) {
    final current = ref.read(perfilProvider).temaEscuro;
    ref.read(perfilProvider.notifier).alternarTemaEscuro(!current);
  }
}

class _BrandPanel extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool rounded;
  final bool compact;
  const _BrandPanel({
    required this.onToggleTheme,
    required this.rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final foreground = colors.onPrimaryContainer;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: rounded
            ? BorderRadius.circular(32)
            : const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -70,
            child: _DecorativeCircle(
              size: 220,
              color: foreground.withValues(alpha: .05),
            ),
          ),
          Positioned(
            left: -55,
            bottom: -70,
            child: _DecorativeCircle(
              size: 180,
              color: foreground.withValues(alpha: .05),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 24 : 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: foreground,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        AppIcons.logoApp,
                        color: colors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'IrrigaSim',
                      style: text.titleLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: Theme.of(context).brightness == Brightness.dark
                          ? 'Usar tema claro'
                          : 'Usar tema escuro',
                      onPressed: onToggleTheme,
                      color: foreground,
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decisões melhores começam com uma boa simulação.',
                        style: text.headlineMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Planeje a irrigação por superfície com orientação, indicadores claros e cenários salvos.',
                        style: text.bodyLarge?.copyWith(
                          color: foreground.withValues(alpha: .78),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      _Benefit(
                        icon: Icons.route_outlined,
                        label: 'Simulação guiada passo a passo',
                        color: foreground,
                      ),
                      const SizedBox(height: 12),
                      _Benefit(
                        icon: Icons.insights_rounded,
                        label: 'Resultados fáceis de interpretar',
                        color: foreground,
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Text(
                    'Simule a irrigação com clareza e confiança.',
                    style: text.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Benefit({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Bem-vindo de volta',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Entre para acessar suas simulações e cenários.',
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          const LoginForm(),
        ],
      ),
    );
  }
}
