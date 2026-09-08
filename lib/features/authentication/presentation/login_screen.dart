import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import '../providers.dart';
import 'widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState?>(authProvider, (prev, next) {
      if (next != null && next.isAuthenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text('IrrigaSim', style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                Text(
                  'Simulação de irrigação superficial',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 48),
                const LoginForm(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
