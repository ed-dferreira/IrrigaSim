import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRemoteDataSource {
  final firebase.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  final FirebaseFirestore? _firestore;

  AuthRemoteDataSource({
    this._firebaseAuth,
    GoogleSignIn? googleSignIn,
    this._firestore,
  }) : _googleSignIn = googleSignIn;

  bool get _isFirebaseAvailable {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.linux) return false;
    return true;
  }

  firebase.FirebaseAuth get _auth =>
      _firebaseAuth ?? firebase.FirebaseAuth.instance;
  GoogleSignIn get _google => _googleSignIn ?? GoogleSignIn();
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  firebase.User? get currentFirebaseUser {
    if (!_isFirebaseAvailable) return null;
    return _auth.currentUser;
  }

  Stream<firebase.User?> get authStateChanges {
    if (!_isFirebaseAvailable) {
      return const Stream.empty();
    }
    return _auth.authStateChanges();
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    if (!_isFirebaseAvailable) {
      throw AuthException(
        'Login não disponível no Linux. Use Android, iOS ou Web.',
      );
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
    if (!_isFirebaseAvailable) {
      throw AuthException('Login com Google não disponível no Linux.');
    }
    try {
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
    if (!_isFirebaseAvailable) {
      throw AuthException('Cadastro não disponível no Linux.');
    }
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
    if (!_isFirebaseAvailable) return;
    await _google.signOut();
    await _auth.signOut();
  }

  UserModel? getCurrentUser() {
    if (!_isFirebaseAvailable) return null;
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
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
