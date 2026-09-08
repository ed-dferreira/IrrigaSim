import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/use_cases/login_with_email.dart';
import 'domain/use_cases/login_with_google.dart';
import 'domain/use_cases/register.dart';
import 'domain/use_cases/logout.dart';
import 'presentation/viewmodels/auth_view_model.dart';

export 'presentation/viewmodels/auth_view_model.dart' show AuthState;

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final loginWithEmailProvider = Provider<LoginWithEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginWithEmail(repository);
});

final loginWithGoogleProvider = Provider<LoginWithGoogle>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginWithGoogle(repository);
});

final registerProvider = Provider<Register>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return Register(repository);
});

final logoutProvider = Provider<Logout>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return Logout(repository);
});

final authProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    loginWithEmail: ref.watch(loginWithEmailProvider),
    loginWithGoogle: ref.watch(loginWithGoogleProvider),
    register: ref.watch(registerProvider),
    logout: ref.watch(logoutProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});
