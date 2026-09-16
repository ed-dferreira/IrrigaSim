import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/auth_controller.dart';
import 'services/auth_service.dart';

export 'controllers/auth_controller.dart' show AuthState;

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
