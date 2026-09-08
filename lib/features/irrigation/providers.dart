import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'domain/repositories/irrigation_repository.dart';
import 'data/datasources/local/simulacoes_local_datasource.dart';
import 'data/datasources/remote/firestore_datasource.dart';
import 'data/repositories/irrigation_repository_impl.dart';
import 'data/models/cenario_salvo.dart';

final simulacoesLocalDatasourceProvider =
    Provider<SimulacoesLocalDatasource>((ref) {
  return SimulacoesLocalDatasource();
});

final firestoreDatasourceProvider = Provider<FirestoreDatasource?>((ref) {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  final userId = authState.user!.uid;
  return FirestoreDatasource(
    firestore: FirebaseFirestore.instance,
    userId: userId,
  );
});

final irrigationRepositoryProvider = Provider<IrrigationRepository>((ref) {
  final local = ref.watch(simulacoesLocalDatasourceProvider);
  final remote = ref.watch(firestoreDatasourceProvider);
  return IrrigationRepositoryImpl(local, remote: remote);
});

final cenariosProvider =
    StreamProvider.autoDispose<List<CenarioSalvo>>((ref) {
  final repository = ref.watch(irrigationRepositoryProvider);
  final stream = repository.observar();
  ref.onDispose(() => stream.drain());
  return stream;
});
