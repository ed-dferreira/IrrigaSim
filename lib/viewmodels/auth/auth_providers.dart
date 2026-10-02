import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import '../../services/auth/auth_service.dart';

export 'auth_controller.dart' show AuthState;

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
