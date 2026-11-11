import 'package:shared_preferences/shared_preferences.dart';

import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/services/scenario_service.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/executar_simulacao_faixa.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_simulation_coordinator.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/coordenador_simulacao_sulcos.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

final _chaveExemplos = 'cenarios_exemplos_carregados_v1';
Future<void>? _semeaduraAndamento;

/// Gera cenários de exemplo — dois por método de irrigação — executando os
/// simuladores reais de cada método, para testar a interface (comparação,
/// detalhes e resultados completos) com dados completos.
class CenariosDeExemplo {
  const CenariosDeExemplo();

  List<CenarioSalvo> gerar() {
    final exemplos = <CenarioSalvo>[];

    void adicionar(CenarioSalvo Function() criar) {
      try {
        exemplos.add(criar());
      } catch (_) {
        // Um exemplo inválido não pode derrubar a interface; fica de fora.
      }
    }

    adicionar(
      () => _sulco(
        'exemplo-sulco-1',
        'Exemplo Sulco · básico 1 L/s',
        _paramsSulcoBase,
      ),
    );
    adicionar(
      () => _sulco(
        'exemplo-sulco-2',
        'Exemplo Sulco · vazão 1,3 L/s',
        _paramsSulcoBase.copyWith(
          vazao: 1.3,
          tempoAplicacao: 110,
          tempoAvancoMetadeMin: 30,
          tempoAvancoFinalMin: 80,
        ),
      ),
    );
    adicionar(
      () => _faixa(
        'exemplo-faixa-1',
        'Exemplo Faixa · perfil ilustrativo',
        BorderProject.ilustrativo,
      ),
    );
    adicionar(
      () => _faixa(
        'exemplo-faixa-2',
        'Exemplo Faixa · vazão 10/3 L/s/m',
        BorderProject.ilustrativo.copyWith(
          desnivelLongitudinalM: 0.4,
          vazaoUnitariaLsM: 10 / 3,
        ),
      ),
    );
    adicionar(
      () => _inundacao(
        'exemplo-inundacao-1',
        'Exemplo Inundação · intermitente',
        ProjetoInundacao.exemploAula8Intermitente(),
      ),
    );
    adicionar(
      () => _inundacao(
        'exemplo-inundacao-2',
        'Exemplo Inundação · permanente',
        ProjetoInundacao.exemploAula8Permanente(),
      ),
    );
    return exemplos;
  }

  CenarioSalvo _sulco(
    String id,
    String nome,
    IrrigationParameters parametros,
  ) {
    final now = DateTime.now();
    final resultado = const CoordenadorSimulacaoSulcos().executar(parametros);
    return CenarioSalvo(
      id: id,
      nome: nome,
      metodo: MetodoIrrigacao.sulco,
      parametros: parametros,
      resultado: resultado,
      dataCriacao: now,
      dataModificacao: now,
    );
  }

  CenarioSalvo _faixa(String id, String nome, BorderProject projeto) {
    final now = DateTime.now();
    final resultado = const RunBorderSimulation()(
      projeto.toCompatParameters(),
    );
    return CenarioSalvo(
      id: id,
      nome: nome,
      metodo: MetodoIrrigacao.faixa,
      parametros: projeto.toCompatParameters(),
      resultado: resultado,
      dataCriacao: now,
      dataModificacao: now,
    );
  }

  CenarioSalvo _inundacao(String id, String nome, ProjetoInundacao projeto) {
    final now = DateTime.now();
    final resultado = const BasinSimulationCoordinator().executarProjeto(
      projeto,
    );
    return CenarioSalvo(
      id: id,
      nome: nome,
      metodo: MetodoIrrigacao.inundacao,
      parametros: projeto.toCompatParameters(),
      resultado: resultado,
      dataCriacao: now,
      dataModificacao: now,
    );
  }

  /// Parâmetros base de sulco — mesmos valores já validados nos testes do
  /// balanço de sulco (resultados determinísticos e completos).
  static const _paramsSulcoBase = IrrigationParameters(
    projetoMetodo: EntradasProjeto(desnivelLongitudinalM: 1.0, baseLongitudinalM: 200),
    comprimento: 200,
    declividade: 0.005,
    larguraOuEspacamento: 0.9,
    k: 2.83,
    a: 0.554,
    vib: 0.0001,
    vazao: 1,
    tempoAplicacao: 130,
    laminaRequerida: 42,
    tipoSulco: 'sulcos_comuns',
    tempoAvancoMetadeMin: 35,
    tempoAvancoFinalMin: 90,
  );
}

/// Semeia os cenários de exemplo na primeira execução com a base vazia.
class SemeadorDeExemplos {
  final ScenarioService service;

  const SemeadorDeExemplos(this.service);

  /// Executa uma única vez por instalação: grava a marca em
  /// `shared_preferences` e nunca repopula cenários excluídos pelo usuário.
  Future<void> semearUmaVez() async {
    return _semeaduraAndamento ??= _executar();
  }

  Future<void> _executar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_chaveExemplos) ?? false) return;
      final existentes = await service.listar();
      if (existentes.isNotEmpty) {
        await prefs.setBool(_chaveExemplos, true);
        return;
      }
      for (final cenario in const CenariosDeExemplo().gerar()) {
        await service.salvar(cenario);
      }
      await prefs.setBool(_chaveExemplos, true);
    } catch (_) {
      // Falha ao semear (simulador ou prefs) jamais impede a listagem.
    }
  }
}
