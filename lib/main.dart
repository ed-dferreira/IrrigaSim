import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/app.dart';
import 'package:irrigasim/firebase_options.dart';
import 'package:irrigasim/services/preferencias_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    PreferenciasApp.init(),
  ]);
  runApp(const ProviderScope(child: App()));
}
