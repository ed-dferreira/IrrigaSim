import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/use_cases/login_with_email.dart';
import '../../domain/use_cases/login_with_google.dart';
import '../../domain/use_cases/register.dart';
import '../../domain/use_cases/logout.dart';
import '../../domain/repositories/auth_repository.dart';

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
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      erro: erro,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginWithEmail _loginWithEmail;
  final LoginWithGoogle _loginWithGoogle;
  final Register _register;
  final Logout _logout;
  final AuthRepository _repository;

  AuthViewModel({
    required this._loginWithEmail,
    required LoginWithGoogle loginWithGoogle,
    required this._register,
    required this._logout,
    required this._repository,
  }) : _loginWithGoogle = loginWithGoogle,
       super(const AuthState()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((user) {
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _loginWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _loginWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> register(String nome, String email, String senha) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final user = await _register(nome, email, senha);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      await _logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(erro: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(erro: null);
  }
}
