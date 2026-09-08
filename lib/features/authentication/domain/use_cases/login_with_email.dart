import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmail {
  final AuthRepository _repository;

  LoginWithEmail(this._repository);

  Future<User> call(String email, String password) {
    return _repository.loginWithEmail(email, password);
  }
}
