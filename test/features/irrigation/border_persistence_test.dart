import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/cenarios/cenario_salvo.dart';
import 'package:irrigasim/models/faixas/border_numeric.dart';
import 'package:irrigasim/models/faixas/border_agronomy.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';

void main() {
  const project = BorderProject.ilustrativo;
  final params = project.toCompatParameters();
  final result = const RunBorderSimulation()(params);
  CenarioSalvo scenario(MetodoIrrigacao method) => CenarioSalvo(
    id: 'x',
    nome: 'Teste',
    metodo: method,
    parametros: params,
    resultado: result,
    dataCriacao: DateTime(2020),
    dataModificacao: DateTime(2020),
  );

  test('projeto tipado e perfil de resultados atravessam o cenário', () {
    final loaded = CenarioSalvo.fromMap(
      scenario(MetodoIrrigacao.faixa).toMap(),
    );
    expect(loaded.parametros.projetoFaixa!.versao, BorderProject.versaoAtual);
    expect(
      loaded.parametros.projetoFaixa!.vazaoUnitariaLsM,
      project.vazaoUnitariaLsM,
    );
    expect(
      loaded.resultado.borderResult!.volumeEntradaTotalM3,
      closeTo(result.borderResult!.volumeEntradaTotalM3, 1e-7),
    );
  });

  test('dados adicionais da cultura de faixa persistem no projeto', () {
    final projectWithCrop = project.copyWith(
      cultura: 'Milho',
      agronomia: const BorderAgronomy(
        kc: 1.2,
        espacamentoFileirasM: .8,
        espacamentoPlantasM: .2,
        profundidadeRaizesCm: 100,
        fracaoDisponivel: .55,
      ),
    );
    final loaded = BorderProject.fromMap(projectWithCrop.toMap());
    expect(loaded.cultura, 'Milho');
    expect(loaded.agronomia?.kc, 1.2);
    expect(loaded.agronomia?.espacamentoFileirasM, .8);
    expect(loaded.agronomia?.espacamentoPlantasM, .2);
    expect(loaded.agronomia?.profundidadeRaizesCm, 100);
    expect(loaded.agronomia?.fracaoDisponivel, .55);
  });

  test(
    'contrato versionado preserva revisão de alternativas e janela de água',
    () {
      final changed = project.copyWith(
        diasFornecimento: [1, 3, 5],
        periodoDias: 7,
        janelaFornecimentoHorasDia: 8,
        alternativas: [
          const BorderAlternativeRecord(400, 2.5, null, 'Oferta insuficiente'),
        ],
      );
      final loaded = BorderProject.fromMap(changed.toMap());
      expect(loaded.diasFornecimento, [1, 3, 5]);
      expect(loaded.alternativas.single.motivoRejeicao, 'Oferta insuficiente');
      expect(loaded.versao, BorderProject.versaoAtual);
    },
  );

  test(
    'faixa legada interpreta q0 e W sem novos defaults ou converter tempo',
    () {
      final saved = scenario(MetodoIrrigacao.faixa).toMap();
      final map = saved['parametros'] as Map<String, dynamic>;
      map.remove('projetoFaixa');
      map['larguraOuEspacamento'] = 50;
      map['vazao'] = 1.8;
      map['sigmaZ'] = .66;
      map['tempoAplicacao'] = 130;
      final restored = CenarioSalvo.fromMap(saved).parametros.projetoFaixa!;
      expect(restored.legado, isTrue);
      expect(restored.versao, 0);
      expect(restored.larguraM, 50);
      expect(restored.vazaoUnitariaLsM, 1.8);
      expect(restored.rInicial, .66);
      expect(restored.tempoAplicacaoLegadoMin, 130);
      expect(restored.alturaDiqueM, isNull);
    },
  );

  test('outros métodos não recebem contrato de faixas na leitura', () {
    for (final method in [MetodoIrrigacao.sulco, MetodoIrrigacao.inundacao]) {
      final saved = scenario(method).toMap();
      final loaded = CenarioSalvo.fromMap(saved);
      expect(loaded.parametros.projetoFaixa, isNull);
      expect(loaded.parametros.vazao, params.vazao);
      expect(loaded.parametros.tempoAplicacao, params.tempoAplicacao);
    }
  });

  test('grupo numérico atravessa o cenário; registro antigo usa defaults', () {
    expect(project.nSegmentos, BorderProject.nSegmentosPadrao);
    expect(project.numerico.toleranciaPasso, 1e-10);
    expect(project.numerico.toleranciaResiduo, 1e-12);
    expect(project.numerico.maxIteracoes, 250);
    expect(project.numerico.versaoExpoentesRecessao, 'p43');
    expect(
      project.numerico.metodoIntegracao,
      BorderNumericConfig.metodoIntegracaoPadrao,
    );
    final withSegments = project.copyWith(
      numerico: const BorderNumericConfig(nSegmentos: 1000),
    );
    final reloaded = BorderProject.fromMap(withSegments.toMap());
    expect(reloaded.nSegmentos, 1000);
    expect(reloaded.numerico.toleranciaPasso, 1e-10);
    // Mapa do grupo serializado como campo próprio do projeto.
    final saved = scenario(MetodoIrrigacao.faixa).toMap();
    final parametros = saved['parametros'] as Map<String, dynamic>;
    final projeto = Map<String, dynamic>.from(
      parametros['projetoFaixa'] as Map,
    );
    final numericoSalvo = Map<String, dynamic>.from(projeto['numerico'] as Map);
    expect(numericoSalvo['nSegmentos'], BorderProject.nSegmentosPadrao);
    expect(numericoSalvo['versaoExpoentesRecessao'], 'p43');
    // Registro legado sem o grupo lê os defaults explícitos.
    projeto.remove('numerico');
    parametros['projetoFaixa'] = projeto;
    final legado = CenarioSalvo.fromMap(saved).parametros.projetoFaixa!;
    expect(legado.nSegmentos, BorderProject.nSegmentosPadrao);
    expect(legado.numerico.maxIteracoes, 250);
    // Chave plana antiga (nSegmentos na raiz) continua sendo aceita.
    expect(BorderProject.fromMap(const {'nSegmentos': 1000}).nSegmentos, 1000);
  });

  test(
    'resultado legado (status de enum e avisos em texto) abre com defaults',
    () {
      final atual = BorderResult.fromMap(result.borderResult!.toMap());
      expect(atual.status.codigo, result.borderResult!.status.codigo);
      expect(atual.numerico.nSegmentos, BorderProject.nSegmentosPadrao);
      expect(
        atual.avisos.first.codigo,
        result.borderResult!.avisos.first.codigo,
      );

      // Formato antigo: status em camelCase e avisos como lista de strings.
      final legado = BorderResult.fromMap(
        {
          ...result.borderResult!.toMap(),
          'status': 'geometriaIncompativel',
          'avisos': ['Profundidade na entrada excede a altura do dique.'],
        }..remove('numerico'),
      );
      expect(legado.status, BorderStatus.foraDoDominio);
      expect(legado.avisos.single.status, BorderStatus.avisoOrientativo);
      expect(legado.avisos.single.mensagem, contains('excede'));
      expect(legado.numerico.toleranciaPasso, 1e-10);
      expect(legado.numerico.maxIteracoes, 250);

      final pendente = BorderResult.fromMap(
        {
          ...result.borderResult!.toMap(),
          'status': 'geometriaPendente',
          'avisos': ['Altura real do dique não informada.'],
        }..remove('numerico'),
      );
      expect(pendente.status, BorderStatus.entradaInvalida);
      expect(result.borderResult!.status, BorderStatus.entradaInvalida);
    },
  );

  test('alternativa rejeitada preserva texto e código no cenário', () {
    const record = BorderAlternativeRecord(
      400,
      2.5,
      null,
      'Oferta de água insuficiente',
      BorderStatus.foraDoDominio,
    );
    final loaded = BorderProject.fromMap(
      BorderProject.ilustrativo.copyWith(alternativas: const [record]).toMap(),
    );
    expect(
      loaded.alternativas.single.motivoRejeicao,
      'Oferta de água insuficiente',
    );
    expect(loaded.alternativas.single.status, BorderStatus.foraDoDominio);
    expect(loaded.alternativas.single.status!.codigo, 'fora_do_dominio');
    // Registro antigo sem código continua legível.
    final antigo = BorderProject.fromMap(const {
      'alternativas': [
        {
          'comprimentoM': 400.0,
          'vazaoLsM': 2.5,
          'eficienciaPercentual': null,
          'motivoRejeicao': 'antigo',
        },
      ],
    });
    expect(antigo.alternativas.single.status, isNull);
  });
}
