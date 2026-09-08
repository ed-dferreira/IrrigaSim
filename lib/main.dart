import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/perfil/data/preferencias_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciasApp.init();

  // Inicializar Firebase apenas em plataformas suportadas
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  runApp(const ProviderScope(child: App()));
}
