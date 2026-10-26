// Coordenação da simulação de inundação (Fase 6). Além do despacho por
// regime, anexa ao resultado o planejamento em parcelas (pp. 61–62), a
// seleção entre vazões candidatas (p. 60) e os volumes de água do arroz
// (pp. 74–84), sempre preservando as lacunas de dados (G4) e converte erros
// de domínio em FormatException amigável para a interface.
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_annexes.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_project.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_planning.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_math.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/rice_volumes_service.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/run_basin_simulation.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/run_permanent_basin_simulation.dart';

/// Coordena os regimes intermitente e permanente da irrigação por inundação.
class BasinSimulationCoordinator {
  const BasinSimulationCoordinator();

  SimulationResult executar(IrrigationParameters parametros) =>
      executarProjeto(BasinProject.fromParameters(parametros));

  SimulationResult executarProjeto(BasinProject projeto) {
    final params = projeto.toCompatParameters();
    var result = projeto.regime == TipoInundacao.permanente
        ? RunPermanentBasinSimulation()(params)
        : RunBasinSimulation()(params);

    final extras = <String, double>{};
    final unidades = <String, String>{};
    BasinParcelasAnexo? parcelas;
    BasinSelecaoVazaoAnexo? selecao;
    BasinVolumesAnexo? volumes;
    var alertas = result.alertaInfiltracao;

    if (projeto.regime == TipoInundacao.intermitente) {
      final q0 = result.metricas['Vazão unitária Q0'];
      final ti = result.metricas['Tempo de oportunidade'];
      if (q0 != null && ti != null) {
        try {
          final p = const BasinPlanning().planejarParcelasProjeto(
            params,
            q0M3MinM: q0,
            tiMin: ti,
            tabuleirosPorParcela: projeto.tabuleirosPorParcela,
            areaTotalM2: projeto.areaTotalM2 ?? params.areaHectares * 10000,
          );
          parcelas = BasinParcelasAnexo(
            tppMin: p.tppMin,
            npdTeorico: p.npdTeorico,
            npdInteiro: p.npdInteiro,
            appM2: p.appM2,
            larguraTabuleiroM: p.larguraTabuleiroM,
            tabuleirosPorParcela: projeto.tabuleirosPorParcela,
            ntt: p.ntt,
            qTotalLS: p.qTotalLS,
          );
          void anexar(String chave, double valor, String unidade) {
            extras[chave] = valor;
            unidades[chave] = unidade;
          }

          anexar('Planejamento - tempo por parcela TPP', p.tppMin, 'min');
          anexar('Planejamento - NPD teórico', p.npdTeorico, 'parcelas/dia');
          anexar(
            'Planejamento - parcelas por dia NPD',
            p.npdInteiro.toDouble(),
            'parcelas/dia',
          );
          anexar('Planejamento - área por parcela APP', p.appM2, 'm²');
          anexar(
            'Planejamento - largura do tabuleiro W0',
            p.larguraTabuleiroM,
            'm',
          );
          anexar(
            'Planejamento - tabuleiros totais NTT',
            p.ntt.toDouble(),
            'tabuleiros',
          );
          anexar('Planejamento - vazão total Q', p.qTotalLS, 'L/s');
        } on FormatException catch (e) {
          alertas = [alertas, e.message].whereType<String>().join(' ');
        }
      }

      selecao = _selecionarVazao(projeto, extras, unidades);
    }

    final checagem = projeto.regime == TipoInundacao.intermitente
        ? _checagemOperacao(projeto, extras, unidades)
        : result.checagemOperacional;

    volumes = _volumesArroz(projeto, extras, unidades);

    final alertasVazao = [
      result.alertaVazaoExcedida,
      if (checagem != null && !checagem.viavel) checagem.motivo,
    ].whereType<String>().join(' ');

    return result.comAnexosInundacao(
      parcelas: parcelas,
      selecao: selecao,
      volumes: volumes,
      checagem: checagem,
      metricasExtras: extras,
      unidadesExtras: unidades,
      alertaInfiltracao: alertas,
      alertaVazaoExcedida: alertasVazao.isEmpty ? null : alertasVazao,
    );
  }

  /// Checagem operacional obrigatória (G3) do regime intermitente: a vazão
  /// total aplicada não pode superar a disponível e a geometria do tabuleiro
  /// precisa caber na área declarada. Sem os dados mínimos não há o que
  /// comparar e o resultado fica nulo.
  BasinChecagemOperacional? _checagemOperacao(
    BasinProject projeto,
    Map<String, double> extras,
    Map<String, String> unidades,
  ) {
    final planejada = projeto.vazaoAplicadaLs;
    final disponivel = projeto.vazaoDisponivelLps;
    final areaTabuleiro = projeto.areaTabuleiroM2;
    final areaDeclarada =
        projeto.areaTotalM2 ??
        projeto.areaUtilM2 ??
        (projeto.areaHectares == null ? null : projeto.areaHectares! * 10000);
    if (planejada == null ||
        disponivel == null ||
        areaTabuleiro == null ||
        areaDeclarada == null ||
        disponivel <= 0 ||
        areaDeclarada <= 0) {
      return null;
    }
    final checagem = const BasinPlanning().checarOperacao(
      vazaoPlanejadaLs: planejada,
      vazaoDisponivelLs: disponivel,
      areaTabuleiroM2: areaTabuleiro,
      areaDeclaradaM2: areaDeclarada,
    );
    extras['Checagem operacional - vazão'] = checagem.atendeVazao ? 1.0 : 0.0;
    unidades['Checagem operacional - vazão'] = 'flag (1 = sim)';
    extras['Checagem operacional - geometria'] = checagem.geometriaCabeNaArea
        ? 1.0
        : 0.0;
    unidades['Checagem operacional - geometria'] = 'flag (1 = sim)';
    return checagem;
  }

  /// Melhor vazão entre as candidatas explícitas em L/s (p. 60). A seleção
  /// informa; não substitui a vazão simulada e não afirma ótimo global.
  BasinSelecaoVazaoAnexo? _selecionarVazao(
    BasinProject projeto,
    Map<String, double> extras,
    Map<String, String> unidades,
  ) {
    final candidatas = projeto.candidatasVazaoLs;
    final largura = projeto.larguraM;
    final comprimento = projeto.comprimentoM;
    final n = projeto.rugosidadeN;
    final k = projeto.k;
    final a = projeto.a;
    final vib = projeto.vibMMin;
    final irnM = projeto.laminaMediaPlanaltoM;
    final altura = projeto.alturaDiqueM;
    final margem = projeto.margemLivreM;
    if (candidatas.isEmpty ||
        largura == null ||
        comprimento == null ||
        n == null ||
        k == null ||
        a == null ||
        vib == null ||
        irnM == null ||
        altura == null ||
        margem == null) {
      return null;
    }
    final solo = Infiltracao(k, a, vib);
    var avaliadas = 0;
    var rejeitadas = 0;
    BasinDimensioningResult? melhor;
    double? melhorLs;
    for (final qLs in candidatas) {
      avaliadas++;
      final q0 = qLs * 60 / 1000 / largura;
      BasinDimensioningResult atual;
      try {
        atual = dimensionar(
          solo,
          l: comprimento,
          n: n,
          irn: irnM,
          vmax: projeto.vmaxMMin,
          vazao: q0,
          rInicial: projeto.rInicial,
        );
      } on ArgumentError {
        rejeitadas++;
        continue;
      } on StateError {
        rejeitadas++;
        continue;
      }
      if (!diqueComporta(altura, atual.y0M, margem) ||
          atual.eficienciaPercent > 100) {
        rejeitadas++;
        continue;
      }
      if (melhor == null ||
          atual.eficienciaPercent > melhor.eficienciaPercent) {
        melhor = atual;
        melhorLs = qLs;
      }
    }
    if (melhor == null || melhorLs == null) return null;
    extras['Vazão selecionada entre candidatas'] = melhorLs;
    unidades['Vazão selecionada entre candidatas'] = 'L/s';
    extras['Q0 da vazão selecionada'] = melhor.q0M3MinM;
    unidades['Q0 da vazão selecionada'] = 'm³/(min·m)';
    extras['Ea da vazão selecionada'] = melhor.eficienciaPercent;
    unidades['Ea da vazão selecionada'] = '%';
    return BasinSelecaoVazaoAnexo(
      vazaoEscolhidaLs: melhorLs,
      q0M3MinM: melhor.q0M3MinM,
      eficienciaPercent: melhor.eficienciaPercent,
      candidatasAvaliadas: avaliadas,
      candidatasRejeitadas: rejeitadas,
    );
  }

  /// Volumes do arroz (p. 84) quando o projeto traz os dados mínimos do
  /// enunciado; lacunas (Ua, massa do saco, área, Td, Tr) permanecem null.
  BasinVolumesAnexo? _volumesArroz(
    BasinProject projeto,
    Map<String, double> extras,
    Map<String, String> unidades,
  ) {
    final ds = projeto.dsGcm3;
    final dp = projeto.dpGcm3;
    final pci = projeto.pciM;
    final altura = projeto.alturaLaminaRiceM;
    final evaporacao = projeto.evaporacaoTanqueMmDia;
    final ksat = projeto.ksatMDia;
    final periodo = projeto.periodoArrozDias;
    if (ds == null ||
        dp == null ||
        pci == null ||
        altura == null ||
        evaporacao == null ||
        ksat == null ||
        periodo == null) {
      return null;
    }
    final RiceVolumesResultado r;
    try {
      r = const RiceVolumesService().calcular(
        ds: ds,
        dp: dp,
        uaGravimetrica: projeto.uaGravimetrica,
        pciM: pci,
        alturaLaminaM: altura,
        evaporacaoDiaM: evaporacao / 1000,
        ksatDiaM: ksat,
        periodoDias: periodo,
        produtividadeSacosHa: projeto.produtividadeSacosHa,
        umidadeGraos: projeto.umidadeGraos,
        indiceColheita: projeto.indiceColheita,
        massaSacoKg: projeto.massaSacoKg,
        areaHa:
            projeto.areaArrozHa ??
            (projeto.regime == TipoInundacao.permanente
                ? projeto.areaHectares
                : null),
        tdDias: projeto.tdDias,
        trDias: projeto.trDias,
      );
    } on ArgumentError catch (e) {
      throw FormatException('Volumes do arroz: ${e.message}');
    } on StateError catch (e) {
      throw FormatException('Volumes do arroz: ${e.message}');
    }
    void anexar(String chave, double? valor, String unidade) {
      if (valor == null) return;
      extras[chave] = valor;
      unidades[chave] = unidade;
    }

    anexar('Arroz - porosidade total PT', r.pt, 'adimensional');
    anexar('Arroz - umidade de saturação Us', r.us, 'adimensional');
    anexar('Arroz - V1 saturação', r.v1M3Ha, 'm³/ha');
    anexar('Arroz - V2 formação da lâmina', r.v2M3Ha, 'm³/ha');
    anexar('Arroz - V3 evaporação', r.v3M3Ha, 'm³/ha');
    anexar('Arroz - V4 infiltração', r.v4M3Ha, 'm³/ha');
    anexar('Arroz - V5 transpiração/MS', r.v5M3Ha, 'm³/ha');
    anexar('Arroz - volume total VT', r.vtM3Ha, 'm³/ha');
    anexar('Arroz - matéria seca total', r.materiaSecaTotalKgHa, 'kg/ha');
    anexar('Arroz - Q1 formação', r.q1M3S, 'm³/s');
    anexar('Arroz - Q2 manutenção', r.q2M3S, 'm³/s');
    return BasinVolumesAnexo(r);
  }
}
