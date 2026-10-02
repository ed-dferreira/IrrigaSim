import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/models/user/user_model.dart';
import 'package:irrigasim/services/perfil/preferencias_app.dart';
import 'package:irrigasim/services/auth/auth_service.dart';
import 'package:irrigasim/viewmodels/auth/auth_providers.dart';
import 'package:irrigasim/views/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('selecionar Faixas na tela inicial abre o novo projeto', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await PreferenciasApp.init();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/home/irrigation/border-project',
          builder: (_, _) =>
              const Scaffold(body: Text('Projeto novo de faixas')),
        ),
        GoRoute(
          path: '/home/irrigation/parameters',
          builder: (_, _) =>
              const Scaffold(body: Text('Formulário rápido legado')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_TestAuthService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final faixas = find.text('Faixas').first;
    await tester.ensureVisible(faixas);
    await tester.tap(faixas);
    await tester.pumpAndSettle();

    expect(find.text('Projeto novo de faixas'), findsOneWidget);
    expect(find.text('Formulário rápido legado'), findsNothing);
  });
}

class _TestAuthService extends AuthService {
  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();
}
