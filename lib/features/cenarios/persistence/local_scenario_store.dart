import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import '../models/cenario_salvo.dart';

/// Guarda os cenários em um banco SQLite local do app.
///
/// Mantém em memória uma cópia dos registros (para emitir rápidos updates no
/// stream e servir `listar/observar` sem tocar em disco) e grava cada
/// operação na tabela `cenarios` do banco `cenarios_irrigasim.db`, no
/// diretório de suporte da aplicação. Cenários do formato anterior
/// (`shared_preferences`) são importados na primeira abertura.
/// Qualquer falha de acesso a disco ou ao banco degrada o store para uso
/// em memória, sem interromper o app.
class LocalScenarioStore {
  LocalScenarioStore({this.abrirBanco});

  /// Injetável para testes; quando nulo, abre o banco padrão do app.
  final Future<sqflite.Database> Function()? abrirBanco;

  static const String _nomeBanco = 'cenarios_irrigasim.db';
  static const String _tabela = 'cenarios';

  /// Chave legada em `shared_preferences` gravada antes do banco SQLite;
  /// usada na migração e nos testes dessa migração.
  static const String chaveMigracao = 'cenarios_salvos_v1';

  final List<CenarioSalvo> _cenarios = [];
  final _controller = StreamController<List<CenarioSalvo>>.broadcast();
  sqflite.Database? _banco;
  bool _carregado = false;
  bool _falhaPersistente = false;

  Future<List<CenarioSalvo>> listar() async {
    await _garantirCarregado();
    return List.unmodifiable(_cenarios);
  }

  Future<void> salvar(CenarioSalvo cenario) async {
    await _garantirCarregado();
    final index = _cenarios.indexWhere((c) => c.id == cenario.id);
    if (index >= 0) {
      _cenarios[index] = cenario;
    } else {
      _cenarios.add(cenario);
    }
    await _gravar(cenario);
    _controller.add(List.unmodifiable(_cenarios));
  }

  Future<CenarioSalvo?> buscarPorId(String id) async {
    await _garantirCarregado();
    try {
      return _cenarios.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> excluir(String id) async {
    await _garantirCarregado();
    _cenarios.removeWhere((c) => c.id == id);
    final banco = _banco;
    if (banco != null && !_falhaPersistente) {
      try {
        await banco.delete(
          _tabela,
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
        // Sem acesso ao banco: segue operando em memória.
      }
    }
    _controller.add(List.unmodifiable(_cenarios));
  }

  Stream<List<CenarioSalvo>> observar() async* {
    await _garantirCarregado();
    yield List.unmodifiable(_cenarios);
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
    final banco = _banco;
    if (banco != null) {
      banco.close();
      _banco = null;
      _carregado = false;
    }
  }

  Future<void> _garantirCarregado() async {
    if (_carregado) return;
    _carregado = true;
    if (_falhaPersistente) return;
    try {
      final banco = _banco ?? await _conectar();
      final registros = await banco.query(_tabela);
      final lidos = [
        for (final registro in registros)
          CenarioSalvo.fromMap(
            jsonDecode(registro['payload'] as String) as Map<String, dynamic>,
          ),
      ];
      _cenarios
        ..clear()
        ..addAll(lidos);
    } catch (_) {
      // Banco indisponível ou tabela ilegível: segue em memória.
      _falhaPersistente = true;
    }
  }

  Future<sqflite.Database> _conectar() async {
    final banco = await (abrirBanco ?? _abrirBancoPadrao)();
    await banco.execute('''
      CREATE TABLE IF NOT EXISTS $_tabela (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        metodo TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await _migrarRegistrosAntigos(banco);
    _banco = banco;
    return banco;
  }

  Future<void> _gravar(CenarioSalvo cenario) async {
    if (_falhaPersistente) return;
    try {
      final banco = _banco ?? await _conectar();
      await banco.insert(
        _tabela,
        {
          'id': cenario.id,
          'nome': cenario.nome,
          'metodo': cenario.metodo.name,
          'payload': jsonEncode({
            ...cenario.toMap(),
            'id': cenario.id,
          }),
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Sem acesso ao banco: o cenário segue disponível em memória.
    }
  }

  /// Importa os cenários gravados em `shared_preferences` (formato
  /// anterior a este banco) e descarta a chave para não migrar de novo.
  Future<void> _migrarRegistrosAntigos(sqflite.Database banco) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(chaveMigracao);
      if (bruto == null || bruto.isEmpty) return;
      final mappings = (jsonDecode(bruto) as List<Object?>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final existentes = {
        for (final linha in await banco.query(_tabela)) linha['id'] as String,
      };
      for (final mapa in mappings) {
        final id = mapa['id'] as String?;
        if (id == null || existentes.contains(id)) continue;
        await banco.insert(_tabela, {
          'id': id,
          'nome': mapa['nome'] as String? ?? '',
          'metodo': mapa['metodo'] as String? ?? 'sulco',
          'payload': jsonEncode(mapa),
        });
      }
      await prefs.remove(chaveMigracao);
    } catch (_) {
      // Migração é best-effort; nunca impede a abertura do banco.
    }
  }

  Future<sqflite.Database> _abrirBancoPadrao() async {
    final suporte = await getApplicationSupportDirectory();
    final caminho = p.join(suporte.path, _nomeBanco);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqflite_ffi.sqfliteFfiInit();
      return sqflite_ffi.databaseFactoryFfi.openDatabase(caminho);
    }
    return sqflite.openDatabase(caminho);
  }
}
