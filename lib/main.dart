import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/app.dart';
import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/perfil/services/preferencias_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registrarCodecs();
  await PreferenciasApp.init();
  runApp(const ProviderScope(child: App()));
}
