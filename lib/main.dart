import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/perfil/services/preferencias_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciasApp.init();

  // FlutterFire não fornece plugins nativos para Linux. A autenticação
  // nessa plataforma usa a API REST oficial do Firebase.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: App()));
}
