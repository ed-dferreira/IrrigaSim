import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/core/widgets/app_text_field.dart';
import 'package:irrigasim/core/widgets/app_button.dart';
import '../../providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ref.read(authProvider.notifier).clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha email e senha')),
      );
      return;
    }

    ref.read(authProvider.notifier).loginWithEmail(email, senha);
  }

  void _handleGoogleLogin() {
    ref.read(authProvider.notifier).loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState?>(authProvider, (prev, next) {
      if (next != null && next.erro != null && next.erro!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.erro!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: 'Email',
          hint: 'seu@email.com',
          value: _emailController.text,
          onChanged: (v) => _emailController.text = v,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Senha',
          value: _senhaController.text,
          onChanged: (v) => _senhaController.text = v,
          prefixIcon: Icons.lock_outlined,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Entrar',
          expanded: true,
          isLoading: authState.isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Entrar com Google',
          variant: AppButtonVariant.outline,
          icon: Icons.g_mobiledata,
          expanded: true,
          isLoading: authState.isLoading,
          onPressed: _handleGoogleLogin,
        ),
      ],
    );
  }
}
