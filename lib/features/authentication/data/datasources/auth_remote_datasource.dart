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
  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  firebase.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<firebase.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_traduzirErro(e.code));
    }
  }

  Future<UserModel> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw AuthException('Login com Google cancelado');

      final googleAuth = await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user!);

      await _salvarUsuarioFirestore(user);
      return user;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_traduzirErro(e.code));
    }
  }

  Future<UserModel> cadastrar(String nome, String email, String senha) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
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
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  UserModel? getCurrentUser() {
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
    await _firestore.collection('usuarios').doc(user.uid).set(user.toMap());
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
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
      default:
        return 'Erro ao autenticar. Tente novamente';
    }
  }
}
