import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/services/cenario_importador.dart';
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
  final importador = CenarioImportador();

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

  group('importarCsv (round-trip com exportarCsv)', () {
    test('reconstrói método, nome e parâmetros principais', () {
      final original = cenario('Faixa ida e volta');
      final importado = importador.importarCsv(store.exportarCsv(original));

      expect(importado.metodo, MetodoIrrigacao.faixa);
      expect(importado.nome, 'Faixa ida e volta');
      // Id fica vazio: a UI gera o id real no momento de salvar.
      expect(importado.id, '');

      final p = importado.parametros;
      final po = original.parametros;
      expect(p.comprimento, closeTo(po.comprimento, 0.5));
      expect(p.larguraOuEspacamento, closeTo(po.larguraOuEspacamento, 0.005));
      expect(p.vazao, closeTo(po.vazao, 0.005));
      expect(p.declividade, closeTo(po.declividade, 0.0005));
      expect(p.tempoAplicacao, closeTo(po.tempoAplicacao, 0.5));
      expect(p.laminaRequerida, closeTo(po.laminaRequerida, 0.5));
      expect(p.k, closeTo(po.k, 0.005));
      expect(p.a, closeTo(po.a, 0.005));
      expect(p.areaHectares, closeTo(po.areaHectares, 0.005));
      expect(p.periodoIrrigacaoDias, po.periodoIrrigacaoDias);
      expect(p.texturaSolo, po.texturaSolo);
      expect(p.manejoSulco, po.manejoSulco);
    });

    test('reconstrói os indicadores-chave do resultado', () {
      final original = cenario('Faixa resultados');
      final importado = importador.importarCsv(store.exportarCsv(original));
      final r = importado.resultado;
      final ro = original.resultado;

      expect(r.eficiencia, closeTo(ro.eficiencia, 0.005));
      expect(r.eficienciaRequerimento, closeTo(ro.eficienciaRequerimento, 0.005));
      expect(r.cuc, closeTo(ro.cuc, 0.005));
      expect(r.du, closeTo(ro.du, 0.005));
      // O CSV registra a lâmina em mm (2 casas): tolerância de 1e-5 m.
      expect(r.laminaMedia, closeTo(ro.laminaMedia, 0.00001));
      expect(r.tempoAvanco, closeTo(ro.tempoAvanco, 0.005));
      expect(r.perdaPercolacao, closeTo(ro.perdaPercolacao, 0.005));
      expect(r.perdaEscoamento, closeTo(ro.perdaEscoamento, 0.005));
    });

    test('aceita BOM, CRLF e células escapadas com separador', () {
      final original = cenario('Nome; com "aspas"');
      final csv = '\uFEFF${store.exportarCsv(original)}'.replaceAll(
        '\n',
        '\r\n',
      );
      final importado = importador.importarCsv(csv);
      expect(importado.nome, 'Nome; com "aspas"');
      expect(importado.metodo, MetodoIrrigacao.faixa);
    });

    test('usa o nome do arquivo quando o CSV não traz o campo Nome', () {
      final semNome = store
          .exportarCsv(cenario('Descartável'))
          .split('\n')
          .where((linha) => !linha.startsWith('Cenário;Nome;'))
          .join('\n');
      final importado = importador.importarCsv(
        semNome,
        nomeArquivo: 'cenario-da-fazenda.csv',
      );
      expect(importado.nome, 'cenario-da-fazenda');
    });

    test('rejeita conteúdo que não é CSV do IrrigaSim', () {
      expect(
        () => importador.importarCsv('a;b;c\n1;2;3\n'),
        throwsFormatException,
      );
      expect(() => importador.importarCsv(''), throwsFormatException);
    });

    test('rejeita método desconhecido com mensagem específica', () {
      final csv = store
          .exportarCsv(cenario('Troca método'))
          .replaceFirst('Método;Faixa', 'Método;Gotejamento');
      expect(
        () => importador.importarCsv(csv),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Gotejamento'),
          ),
        ),
      );
    });
  });
}
