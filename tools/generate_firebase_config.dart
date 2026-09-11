// Gera arquivos de configuração do Firebase a partir de firebase.json.
//
// Uso:
//   dart run tools/generate_firebase_config.dart
//   dart run tools/generate_firebase_config.dart --dry-run
//
// ARQUIVO ÚNICO FONTE: firebase.json
// Todos os caminhos abaixo são derivados dele.

import 'dart:convert';
import 'dart:io';

const _placeholder = 'COLE_AQUI_O_IOS_CLIENT_ID_DO_FIREBASE';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final root = Directory.current;
  final firebaseFile = File('${root.path}/firebase.json');

  if (!firebaseFile.existsSync()) {
    stderr.writeln('Erro: firebase.json não encontrado em ${root.path}');
    exit(1);
  }

  final config =
      jsonDecode(firebaseFile.readAsStringSync()) as Map<String, dynamic>;

  _generateDartOptions(root, config, dryRun);
  _generateGoogleServices(root, config, dryRun);
  _updatePlist(
    root,
    'ios/Runner/Info.plist',
    config['ios']['iosClientId'] as String,
    dryRun,
  );
  _updatePlist(
    root,
    'macos/Runner/Info.plist',
    config['ios']['iosClientId'] as String,
    dryRun,
  );

  if (dryRun) {
    stdout.writeln('\n[dry-run] Nenhum arquivo foi modificado.');
  } else {
    stdout.writeln('\n✓ Configuração do Firebase gerada com sucesso.');
  }
}

// ─── firebase_options.dart ──────────────────────────────────────────────────

void _generateDartOptions(
  Directory root,
  Map<String, dynamic> config,
  bool dryRun,
) {
  final p = config['project'] as Map<String, dynamic>;
  final android = config['android'] as Map<String, dynamic>;
  final ios = config['ios'] as Map<String, dynamic>;
  final web = config['web'] as Map<String, dynamic>;
  final windows = config['windows'] as Map<String, dynamic>;
  final linux = config['linux'] as Map<String, dynamic>;

  final buf = StringBuffer('''
// Gerado automaticamente por tools/generate_firebase_config.dart
// NÃO EDITE ESTE ARQUIVO — altere firebase.json e rode:
//   dart run tools/generate_firebase_config.dart
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

''');

  buf.writeln(_dartOptionsBlock('web', web, p));
  buf.writeln(_dartOptionsBlock('android', android, p));
  buf.writeln(_dartOptionsBlock('ios', ios, p, isIos: true));
  buf.writeln(_dartOptionsBlock('windows', windows, p));
  buf.writeln(_dartOptionsBlock('linux', linux, p));
  buf.writeln('}');

  _writeFile(root, 'lib/firebase_options.dart', buf.toString(), dryRun);
}

String _dartOptionsBlock(
  String name,
  Map<String, dynamic> cfg,
  Map<String, dynamic> project, {
  bool isIos = false,
}) {
  final lines = <String>[
    "  static const FirebaseOptions $name = FirebaseOptions(",
    "    apiKey: '${cfg['apiKey']}',",
    "    appId: '${cfg['appId']}',",
    "    messagingSenderId: '${project['number']}',",
    "    projectId: '${project['id']}',",
  ];

  if (project.containsKey('authDomain')) {
    lines.add("    authDomain: '${project['authDomain']}',");
  }
  lines.add("    storageBucket: '${project['storageBucket']}',");

  if (cfg.containsKey('measurementId')) {
    lines.add("    measurementId: '${cfg['measurementId']}',");
  }
  if (isIos) {
    lines.add("    androidClientId: '${cfg['androidClientId'] ?? ''}',");
    lines.add("    iosClientId: '${cfg['iosClientId'] ?? ''}',");
    lines.add("    iosBundleId: '${cfg['bundleId'] ?? ''}',");
  }

  lines.add('  );');
  return lines.join('\n');
}

// ─── google-services.json ───────────────────────────────────────────────────

void _generateGoogleServices(
  Directory root,
  Map<String, dynamic> config,
  bool dryRun,
) {
  final project = config['project'] as Map<String, dynamic>;
  final android = config['android'] as Map<String, dynamic>;
  final ios = config['ios'] as Map<String, dynamic>;
  final web = config['web'] as Map<String, dynamic>;

  final json = {
    'project_info': {
      'project_number': project['number'],
      'project_id': project['id'],
      'storage_bucket': project['storageBucket'],
    },
    'client': [
      {
        'client_info': {
          'mobilesdk_app_id': android['appId'],
          'android_client_info': {
            'package_name': android['package'],
          },
        },
        'oauth_client': [
          {
            'client_id': '${project['number']}-bi1dfhv5fks1vh1ar8br5jdb24onigua.apps.googleusercontent.com',
            'client_type': 1,
            'android_info': {
              'package_name': android['package'],
              'certificate_hash': 'd490df97f2674679ac062588af929dd67a453d19',
            },
          },
          {
            'client_id': web['androidWebClientId'] ??
                '${project['number']}-a322irkvho4c48d8pvlhli90pev2e1le.apps.googleusercontent.com',
            'client_type': 3,
          },
        ],
        'api_key': [
          {'current_key': android['apiKey']},
        ],
        'services': {
          'appinvite_service': {
            'other_platform_oauth_client': [
              {
                'client_id': web['androidWebClientId'] ??
                    '${project['number']}-a322irkvho4c48d8pvlhli90pev2e1le.apps.googleusercontent.com',
                'client_type': 3,
              },
              {
                'client_id': ios['iosClientId'],
                'client_type': 2,
                'ios_info': {
                  'bundle_id': ios['bundleId'],
                },
              },
            ],
          },
        },
      },
    ],
    'configuration_version': '1',
  };

  final encoder = JsonEncoder.withIndent('  ');
  _writeFile(
    root,
    'android/app/google-services.json',
    encoder.convert(json),
    dryRun,
  );
}

// ─── Info.plist ─────────────────────────────────────────────────────────────

void _updatePlist(
  Directory root,
  String relativePath,
  String iosClientId,
  bool dryRun,
) {
  final file = File('${root.path}/$relativePath');
  if (!file.existsSync()) {
    stdout.writeln('  ⚠ $relativePath não encontrado — pulando');
    return;
  }

  var content = file.readAsStringSync();
  final shortId = _extractShortId(iosClientId);

  // Ordem importa: substituir o padrão mais específico primeiro
  content = content.replaceAll(
    'com.googleusercontent.apps.$_placeholder',
    'com.googleusercontent.apps.$shortId',
  );
  content = content.replaceAll(_placeholder, iosClientId);

  _writeFile(root, relativePath, content, dryRun);
}

String _extractShortId(String fullClientId) {
  // "123456789-abcdef.apps.googleusercontent.com" → "123456789-abcdef"
  const suffix = '.apps.googleusercontent.com';
  if (fullClientId.endsWith(suffix)) {
    return fullClientId.substring(0, fullClientId.length - suffix.length);
  }
  return fullClientId;
}

// ─── Utilitário ─────────────────────────────────────────────────────────────

void _writeFile(Directory root, String relativePath, String content, bool dryRun) {
  final file = File('${root.path}/$relativePath');
  if (dryRun) {
    stdout.writeln('  [dry-run] Geraria: $relativePath');
  } else {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    stdout.writeln('  ✓ $relativePath');
  }
}
