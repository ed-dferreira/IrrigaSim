import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> loginWithGoogle();
  Future<User> cadastrar(String nome, String email, String senha);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;
}
