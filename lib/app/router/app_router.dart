import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'package:irrigasim/features/authentication/presentation/login_screen.dart';
import 'package:irrigasim/features/authentication/presentation/screens/register_screen.dart';
import 'package:irrigasim/features/home/presentation/home_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/irrigation_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/parameters_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/results_screen.dart';
import 'package:irrigasim/features/cenarios/presentation/cenarios_screen.dart';
import 'package:irrigasim/features/tutorial/presentation/tutorial_screen.dart';
import 'package:irrigasim/features/perfil/presentation/perfil_screen.dart';
import 'package:irrigasim/core/navigation/main_shell.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'irrigation',
                    builder: (context, state) => const IrrigationScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/parameters',
                    builder: (context, state) => const ParametersScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/results',
                    builder: (context, state) => const ResultsScreen(),
                  ),
                  GoRoute(
                    path: 'tutorial',
                    builder: (context, state) => const TutorialScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cenarios',
                builder: (context, state) => const CenariosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
