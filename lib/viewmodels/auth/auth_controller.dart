import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user/user.dart';
import '../../services/auth/auth_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? erro;

  const AuthState({this.user, this.isLoading = false, this.erro});

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? erro,
    bool clearUser = false,
    bool clearErro = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      erro: clearErro ? null : (erro ?? this.erro),
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _service;
  late final StreamSubscription<User?> _authSubscription;

  AuthController(this._service) : super(const AuthState()) {
    _authSubscription = _service.authStateChanges.listen((user) {
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _service.loginWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _service.loginWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> register(String nome, String email, String senha) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _service.cadastrar(nome, email, senha);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      await _service.logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(clearErro: true);
  }
}
