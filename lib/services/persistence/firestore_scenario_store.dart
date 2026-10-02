import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cenarios/cenario_salvo.dart';

class FirestoreScenarioStore {
  final FirebaseFirestore _firestore;
  final String _userId;

  FirestoreScenarioStore({required this._firestore, required this._userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('usuarios').doc(_userId).collection('cenarios');

  Future<List<CenarioSalvo>> listar() async {
    final snapshot = await _collection
        .orderBy('dataCriacao', descending: true)
        .get();
    return snapshot.docs.map((doc) => CenarioSalvo.fromFirestore(doc)).toList();
  }

  Future<void> salvar(CenarioSalvo cenario) async {
    await _collection.doc(cenario.id).set(cenario.toMap());
  }

  Future<CenarioSalvo?> buscarPorId(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return CenarioSalvo.fromFirestore(doc);
  }

  Future<void> excluir(String id) async {
    await _collection.doc(id).delete();
  }

  Stream<List<CenarioSalvo>> observar() {
    return _collection
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CenarioSalvo.fromFirestore(doc))
              .toList(),
        );
  }
}
