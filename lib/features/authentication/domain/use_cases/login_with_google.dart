import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogle {
  final AuthRepository _repository;

  LoginWithGoogle(this._repository);

  Future<User> call() {
    return _repository.loginWithGoogle();
  }
}
