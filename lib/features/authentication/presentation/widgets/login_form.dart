import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
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
  bool _fieldsFilled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFields);
    _senhaController.addListener(_checkFields);
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkFields);
    _senhaController.removeListener(_checkFields);
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _checkFields() {
    final filled =
        _emailController.text.trim().isNotEmpty && _senhaController.text.isNotEmpty;
    if (filled != _fieldsFilled) {
      setState(() => _fieldsFilled = filled);
    }
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
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (authState.erro != null && authState.erro!.isNotEmpty)
          Card(
            color: colors.errorContainer,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '⚠ ${authState.erro}',
                    style: AppTextStyles.body.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(authProvider.notifier).clearError(),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '✕',
                        style: TextStyle(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'E-mail',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senhaController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.primary,
                width: 2,
              ),
            ),
            suffixIcon: IconButton(
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
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (authState.isLoading)
                ? null
                : (_fieldsFilled && _senhaController.text.length >= 6)
                    ? _handleLogin
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authState.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : Text(
                    'Entrar',
                    style: AppTextStyles.titleMedium,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: colors.outlineVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: colors.outlineVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: (authState.isLoading) ? null : _handleGoogleLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Entrar com Google',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Não tem conta? ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.go('/register');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Criar conta',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
