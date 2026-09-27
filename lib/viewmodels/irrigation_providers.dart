import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:irrigasim/viewmodels/auth_providers.dart';

import '../services/persistence/local_scenario_store.dart';
import '../services/persistence/firestore_scenario_store.dart';
import '../services/scenario_service.dart';
import '../models/cenario_salvo.dart';

final localScenarioStoreProvider = Provider<LocalScenarioStore>((ref) {
  final store = LocalScenarioStore();
  ref.onDispose(store.dispose);
  return store;
});

final firestoreScenarioStoreProvider = Provider<FirestoreScenarioStore?>((ref) {
  final authState = ref.watch(authProvider);
  final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  if (!authState.isAuthenticated || isLinux) return null;
  final userId = authState.user!.uid;
  return FirestoreScenarioStore(
    firestore: FirebaseFirestore.instance,
    userId: userId,
  );
});

final scenarioServiceProvider = Provider<ScenarioService>((ref) {
  final local = ref.watch(localScenarioStoreProvider);
  final remote = ref.watch(firestoreScenarioStoreProvider);
  return ScenarioService(local, remote);
});

final cenariosProvider = StreamProvider.autoDispose<List<CenarioSalvo>>((ref) {
  final service = ref.watch(scenarioServiceProvider);
  return service.observar();
});
