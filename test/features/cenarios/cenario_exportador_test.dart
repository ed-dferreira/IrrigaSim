import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/services/cenario_exportador.dart';
import 'package:irrigasim/features/cenarios/services/project_store.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/executar_simulacao_faixa.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

void main() {
  setUpAll(registrarCodecs);

  final store = ProjectStore(
    listar: () async => const [],
    salvar: (_) async {},
    buscarPorId: (_) async => null,
    excluir: (_) async {},
  );
  final exportador = CenarioExportador(projectStore: store);

  CenarioSalvo cenario(String nome) {
    final parametros = BorderProject.ilustrativo.toCompatParameters();
    final resultado = const RunBorderSimulation()(parametros);
    return CenarioSalvo(
      id: 'x',
      nome: nome,
      metodo: MetodoIrrigacao.faixa,
      parametros: parametros,
      resultado: resultado,
      dataCriacao: DateTime(2024, 1, 2, 8),
      dataModificacao: DateTime(2024, 1, 2, 8),
    );
  }

  group('exportarCsv', () {
    test('inclui cabeçalho, seções e dados do cenário', () {
      final csv = store.exportarCsv(cenario('Faixa headland'));

      expect(csv.startsWith('Seção;Campo;Valor'), isTrue);
      expect(csv, contains('Cenário'));
      expect(csv, contains('Dados de entrada'));
      expect(csv, contains('Resultados'));
      expect(csv, contains('Faixa headland'));
      expect(csv, contains('Espaçamento/largura (m)'));
      expect(csv, contains('Eficiência de aplicação Ea (%)'));
    });

    test('usa vírgula decimal e escapa célula com separador ou aspas', () {
      final csv = store.exportarCsv(cenario('Nome; com "aspas"'));

      final linhaNome = csv
          .split('\n')
          .firstWhere((linha) => linha.startsWith('Cenário;Nome;'));
      expect(linhaNome, 'Cenário;Nome;"Nome; com ""aspas"""');
    });

    test('valores numéricos não carregam ponto decimal', () {
      final csv = store.exportarCsv(cenario('Faixa numérica'));
      final valores = csv
          .split('\n')
          .where(
            (linha) =>
                linha.contains('(m)') ||
                linha.contains('(%)') ||
                linha.contains('(mm)'),
          )
          .map((linha) => linha.split(';').last)
          .join(' ');
      expect(valores, contains(','));
      expect(valores, isNot(contains('.')));
    });
  });

  group('gerarPdf', () {
    test('produz bytes de PDF válido', () async {
      final bytes = await exportador.gerarPdf(cenario('Faixa ensaio'));

      expect(
        String.fromCharCodes(bytes.sublist(0, 5)),
        '%PDF-',
      );
      // Relatório com dezenas de linhas nunca cabe em 2 KB.
      expect(bytes.length, greaterThan(2000));
    });
  });

  group('exportarCsv/exportarPdf com destino escolhido', () {
    late Directory temporario;

    setUp(() async {
      temporario = await Directory.systemTemp.createTemp('irrigasim_export');
    });

    tearDown(() async {
      await temporario.delete(recursive: true);
    });

    // Exportador com destino fake em diretório temporário.
    CenarioExportador exportadorComDestino() {
      return CenarioExportador(
        projectStore: store,
        escolherDestino: (nome, _) async => '${temporario.path}/$nome',
      );
    }

    test('exportarCsv grava o arquivo com BOM e conteúdo do relatório',
        () async {
      final caminho = await exportadorComDestino()
          .exportarCsv(cenario('Faixa destino csv'));

      expect(caminho, endsWith('.csv'));
      expect(File(caminho!).existsSync(), isTrue);
      final bytes = File(caminho).readAsBytesSync();
      // BOM UTF-8 para o Excel respeitar a codificação.
      expect(bytes.first, 0xEF);
      expect(utf8.decode(bytes), contains('Seção;Campo;Valor'));
    });

    test('exportarPdf grava um PDF válido no destino escolhido', () async {
      final caminho = await exportadorComDestino()
          .exportarPdf(cenario('Faixa destino pdf'));

      expect(caminho, endsWith('.pdf'));
      final bytes = File(caminho!).readAsBytesSync();
      expect(
        String.fromCharCodes(bytes.sublist(0, 5)),
        '%PDF-',
      );
      expect(bytes.length, greaterThan(2000));
    });

    test('cancelar o destino devolve null sem gravar arquivo', () async {
      final cancelado = CenarioExportador(
        projectStore: store,
        escolherDestino: (_, _) async => null,
      );

      expect(await cancelado.exportarCsv(cenario('Cancela csv')), isNull);
      expect(await cancelado.exportarPdf(cenario('Cancela pdf')), isNull);
    });
  });
}
