import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'package:irrigasim/features/authentication/presentation/login_screen.dart';
import 'package:irrigasim/features/authentication/presentation/screens/register_screen.dart';
import 'package:irrigasim/features/home/presentation/home_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/irrigation_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/irrigation_method_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/parameters_screen.dart';
import 'package:irrigasim/features/irrigation/presentation/screens/results_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/irrigation',
        builder: (context, state) => const IrrigationScreen(),
      ),
      GoRoute(
        path: '/irrigation/method',
        builder: (context, state) => const IrrigationMethodScreen(),
      ),
      GoRoute(
        path: '/irrigation/parameters',
        builder: (context, state) => const ParametersScreen(),
      ),
      GoRoute(
        path: '/irrigation/results',
        builder: (context, state) => const ResultsScreen(),
      ),
    ],
  );
});
