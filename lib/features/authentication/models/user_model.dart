import 'package:cloud_firestore/cloud_firestore.dart';

import 'user.dart';

class UserModel extends User {
  const UserModel({
    required super.uid,
    super.nome,
    super.email,
    super.photoUrl,
    super.instituicao,
    super.curso,
    super.dataCriacao,
  });

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      nome: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
      dataCriacao: firebaseUser.metadata?.creationTime,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nome: map['nome'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      instituicao: map['instituicao'],
      curso: map['curso'],
      dataCriacao: map['dataCriacao'] != null
          ? (map['dataCriacao'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'photoUrl': photoUrl,
      'instituicao': instituicao,
      'curso': curso,
      'dataCriacao': dataCriacao != null
          ? Timestamp.fromDate(dataCriacao!)
          : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? photoUrl,
    String? instituicao,
    String? curso,
    DateTime? dataCriacao,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      instituicao: instituicao ?? this.instituicao,
      curso: curso ?? this.curso,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
