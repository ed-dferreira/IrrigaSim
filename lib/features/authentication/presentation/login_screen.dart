import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import '../providers.dart';
import 'widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary,
                    colors.primaryContainer,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '💧',
                        style: TextStyle(fontSize: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'IrrigaSIM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulação de Irrigação por Superfície',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrar na sua conta',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const LoginForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
