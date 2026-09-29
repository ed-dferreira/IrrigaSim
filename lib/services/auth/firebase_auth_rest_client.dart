import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/user/user_model.dart';

class FirebaseRestAuthException implements Exception {
  const FirebaseRestAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firebase Auth para plataformas sem plugin FlutterFire nativo, como Linux.
class FirebaseAuthRestClient {
  FirebaseAuthRestClient({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final _authChanges = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
    yield* _authChanges.stream;
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    final json = await _post('accounts:signInWithPassword', {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    return _setUser(_userFromResponse(json));
  }

  Future<UserModel> register(String name, String email, String password) async {
    final created = await _post('accounts:signUp', {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    final updated = await _post('accounts:update', {
      'idToken': created['idToken'],
      'displayName': name,
      'returnSecureToken': true,
    });
    return _setUser(_userFromResponse(updated));
  }

  void signOut() {
    _currentUser = null;
    _authChanges.add(null);
  }

  UserModel _setUser(UserModel user) {
    _currentUser = user;
    _authChanges.add(user);
    return user;
  }

  UserModel _userFromResponse(Map<String, dynamic> json) => UserModel(
    uid: json['localId'] as String,
    nome: json['displayName'] as String?,
    email: json['email'] as String?,
    photoUrl: json['photoUrl'] as String?,
    dataCriacao: DateTime.now(),
  );

  Future<Map<String, dynamic>> _post(
    String operation,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(
        Uri.https('identitytoolkit.googleapis.com', '/v1/$operation', {
          'key': apiKey,
        }),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        final error = json['error'] as Map<String, dynamic>?;
        throw FirebaseRestAuthException(
          _translateError(error?['message'] as String?),
        );
      }
      return json;
    } on FirebaseRestAuthException {
      rethrow;
    } on Exception {
      throw const FirebaseRestAuthException(
        'Erro de conexão. Verifique sua internet',
      );
    }
  }

  String _translateError(String? message) {
    final code = message?.split(' : ').first;
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou senha incorretos';
      case 'EMAIL_EXISTS':
        return 'Este email já está em uso';
      case 'WEAK_PASSWORD':
        return 'Senha muito fraca. Use pelo menos 6 caracteres';
      case 'INVALID_EMAIL':
        return 'Email inválido';
      case 'USER_DISABLED':
        return 'Esta conta foi desativada';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'OPERATION_NOT_ALLOWED':
        return 'Método de login não habilitado no Firebase';
      default:
        return 'Erro ao autenticar no Firebase${message == null ? '' : ': $message'}';
    }
  }
}
