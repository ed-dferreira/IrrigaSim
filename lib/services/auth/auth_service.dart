import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firebase_options.dart';
import '../../models/user/user_model.dart';
import 'firebase_auth_rest_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final firebase.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  final FirebaseFirestore? _firestore;
  late final FirebaseAuthRestClient _restAuth = FirebaseAuthRestClient(
    apiKey: DefaultFirebaseOptions.linux.apiKey,
  );

  AuthService({this._firebaseAuth, this._googleSignIn, this._firestore});

  bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  firebase.FirebaseAuth get _auth =>
      _firebaseAuth ?? firebase.FirebaseAuth.instance;
  GoogleSignIn get _google => _googleSignIn ?? GoogleSignIn();
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges {
    if (_isLinux) return _restAuth.authStateChanges;
    return _auth.authStateChanges().map(
      (user) => user == null ? null : _mapFirebaseUser(user),
    );
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    if (_isLinux) {
      return _runRest(() => _restAuth.loginWithEmail(email, password));
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_traduzirErro(e.code));
    }
  }

  Future<UserModel> loginWithGoogle() async {
    if (_isLinux) {
      throw AuthException(
        'Login com Google no Linux requer um OAuth Client Desktop. '
        'Use email e senha nesta versão.',
      );
    }
    try {
      if (kIsWeb) {
        final result = await _auth.signInWithPopup(
          firebase.GoogleAuthProvider(),
        );
        final user = _mapFirebaseUser(result.user!);
        await _salvarUsuarioFirestore(user);
        return user;
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final result = await _auth.signInWithProvider(
          firebase.GoogleAuthProvider(),
        );
        final user = _mapFirebaseUser(result.user!);
        await _salvarUsuarioFirestore(user);
        return user;
      }
      final googleUser = await _google.signIn();
      if (googleUser == null) throw AuthException('Login com Google cancelado');

      final googleAuth = await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user!);

      await _salvarUsuarioFirestore(user);
      return user;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_traduzirErro(e.code));
    } catch (e) {
      throw AuthException('Erro ao fazer login com Google. Tente novamente');
    }
  }

  Future<UserModel> cadastrar(String nome, String email, String senha) async {
    if (_isLinux) return _runRest(() => _restAuth.register(nome, email, senha));
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      await credential.user!.updateDisplayName(nome);
      final user = _mapFirebaseUser(credential.user!);

      await _salvarUsuarioFirestore(user);
      return user;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_traduzirErro(e.code));
    }
  }

  Future<void> logout() async {
    if (_isLinux) {
      _restAuth.signOut();
      return;
    }
    await _google.signOut();
    await _auth.signOut();
  }

  UserModel? getCurrentUser() {
    if (_isLinux) return _restAuth.currentUser;
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  Future<UserModel> _runRest(Future<UserModel> Function() operation) async {
    try {
      return await operation();
    } on FirebaseRestAuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  UserModel _mapFirebaseUser(firebase.User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      nome: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
      dataCriacao: firebaseUser.metadata.creationTime,
    );
  }

  Future<void> _salvarUsuarioFirestore(UserModel user) async {
    await _db.collection('usuarios').doc(user.uid).set(user.toMap());
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'invalid-login-credentials':
        return 'Email ou senha incorretos';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta conta foi desativada';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      case 'operation-not-allowed':
        return 'Método de login não habilitado no Firebase';
      default:
        return 'Erro ao autenticar. Tente novamente';
    }
  }
}
