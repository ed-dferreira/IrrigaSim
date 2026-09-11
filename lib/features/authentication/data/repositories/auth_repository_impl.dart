import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<User> loginWithEmail(String email, String password) {
    return _dataSource.loginWithEmail(email, password);
  }

  @override
  Future<User> loginWithGoogle() {
    return _dataSource.loginWithGoogle();
  }

  @override
  Future<User> cadastrar(String nome, String email, String senha) {
    return _dataSource.cadastrar(nome, email, senha);
  }

  @override
  Future<void> logout() {
    return _dataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() {
    return Future.value(_dataSource.getCurrentUser());
  }

  @override
  Stream<User?> get authStateChanges {
    return _dataSource.authStateChanges;
  }
}
