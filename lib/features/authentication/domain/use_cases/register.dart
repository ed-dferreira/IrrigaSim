import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Register {
  final AuthRepository _repository;

  Register(this._repository);

  Future<User> call(String nome, String email, String senha) {
    return _repository.cadastrar(nome, email, senha);
  }
}
