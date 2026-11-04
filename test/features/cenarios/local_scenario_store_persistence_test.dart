import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/persistence/local_scenario_store.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/executar_simulacao_faixa.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    registrarCodecs();
    sqfliteFfiInit();
  });

  CenarioSalvo cenario(String id, String nome) {
    final parametros = BorderProject.ilustrativo.toCompatParameters();
    final resultado = const RunBorderSimulation()(parametros);
    return CenarioSalvo(
      id: id,
      nome: nome,
      metodo: MetodoIrrigacao.faixa,
      parametros: parametros,
      resultado: resultado,
      dataCriacao: DateTime(2024, 1, 2, 8),
      dataModificacao: DateTime(2024, 1, 2, 8),
    );
  }

  /// Devolve uma fábrica que conecta ao mesmo arquivo SQLite; chamar
  /// `conectar()` de novo simula reabrir o app.
  Future<(LocalScenarioStore Function(), Directory)> criarBanco() async {
    final diretorio = await Directory.systemTemp.createTemp('cenarios_test');
    final arquivo = p.join(diretorio.path, 'cenarios_test.db');
    addTearDown(() async {
      try {
        await diretorio.delete(recursive: true);
      } catch (_) {}
    });
    LocalScenarioStore conectar() => LocalScenarioStore(
      abrirBanco: () => databaseFactoryFfi.openDatabase(arquivo),
    );
    return (conectar, diretorio);
  }

  test('cenário salvo sobrevive a uma nova instância (app reaberto)', () async {
    final (conectar, _) = await criarBanco();
    final original = cenario('a1', 'Faixa drenagem lenta');
    await conectar().salvar(original);

    final permanentes = await conectar().listar();
    expect(permanentes, hasLength(1));
    expect(permanentes.single.id, 'a1');
    expect(permanentes.single.nome, 'Faixa drenagem lenta');
    expect(
      permanentes.single.resultado.eficiencia,
      closeTo(original.resultado.eficiencia, 1e-9),
    );
  });

  test('atualização e exclusão são gravadas no banco', () async {
    final (conectar, _) = await criarBanco();
    await conectar().salvar(cenario('a1', 'Original'));
    await conectar().salvar(cenario('a1', 'Renomeado'));
    await conectar().salvar(cenario('a2', 'Outro'));

    var lidos = await conectar().listar();
    expect(lidos.map((c) => c.nome), ['Renomeado', 'Outro']);

    await conectar().excluir('a1');
    lidos = await conectar().listar();
    expect(lidos.map((c) => c.id), ['a2']);
  });

  test('cenários de shared_preferences são migrados e a chave descartada',
      () async {
    final mapaMigracao = cenario('antigo', 'Recuperado').toMap();
    mapaMigracao['id'] = 'antigo';
    SharedPreferences.setMockInitialValues({
      LocalScenarioStore.chaveMigracao: jsonEncode([mapaMigracao]),
    });

    final (conectar, _) = await criarBanco();
    final lidos = await conectar().listar();
    expect(lidos.single.id, 'antigo');
    expect(lidos.single.nome, 'Recuperado');

    expect(
      (await SharedPreferences.getInstance()).getString(
        LocalScenarioStore.chaveMigracao,
      ),
      isNull,
    );
    expect((await conectar().listar()).map((c) => c.id), ['antigo']);
  });

  test('falha ao abrir o banco degrada para memória sem lançar erro', () async {
    final store = LocalScenarioStore(
      abrirBanco: () => Future.error(const OSError('caminho inexistente', 2)),
    );

    expect(await store.listar(), isEmpty);
    await store.salvar(cenario('em_memoria', 'Sobreviveu'));
    expect((await store.buscarPorId('em_memoria'))!.nome, 'Sobreviveu');
  });
}
