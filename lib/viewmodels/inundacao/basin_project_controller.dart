// Controller do projeto de inundação (Fase 6 e Fase 2 do plano de
// cultura/clima). Espelha lib/viewmodels/faixas/border_project_controller.dart:
// StateNotifier com o projeto versionado como estado, setters tipados, edição
// numérica por nome de campo, aplicação dos presets da Aula 8 (G5) e providers
// que resetam o resultado sempre que o projeto muda.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/models/comum/clima_demanda.dart';
import 'package:irrigasim/models/inundacao/basin_agronomy.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/viewmodels/inundacao/basin_simulation_coordinator.dart';

/// Comparação primeira × terceira irrigação pelo método da aula, para o
/// gráfico de cenários (dadosPrimeira/dadosTerceira do projeto).
class BasinScenarioComparison {
  const BasinScenarioComparison({
    required this.primeira,
    required this.terceira,
  });

  final SimulationResult primeira;
  final SimulationResult terceira;
}

/// Compara os dois cenários de infiltração armazenados no projeto usando a
/// mesma simulação do regime; lança [FormatException] quando falta dado.
BasinScenarioComparison calcularComparacaoCenarios(BasinProject projeto) {
  final primeira = projeto.dadosPrimeira;
  final terceira = projeto.dadosTerceira;
  final k1 = primeira?.k, a1 = primeira?.a, v1 = primeira?.vibMMin;
  final k3 = terceira?.k, a3 = terceira?.a, v3 = terceira?.vibMMin;
  if (k1 == null ||
      a1 == null ||
      v1 == null ||
      k3 == null ||
      a3 == null ||
      v3 == null) {
    throw const FormatException(
      'Informe separadamente k, a e VIB da primeira e da terceira irrigação '
      'para comparar os cenários.',
    );
  }
  if (projeto.regime != TipoInundacao.intermitente) {
    throw const FormatException(
      'A comparação de cenários de infiltração usa o regime intermitente.',
    );
  }
  final base = projeto.copyWith(
    cenarioInfiltracao: CenarioInfiltracaoBasin.primeira,
    k: k1,
    a: a1,
    vibMMin: v1,
  );
  final outra = base.copyWith(
    cenarioInfiltracao: CenarioInfiltracaoBasin.terceira,
    k: k3,
    a: a3,
    vibMMin: v3,
  );
  final r1 = const BasinSimulationCoordinator().executarProjeto(base);
  final r2 = const BasinSimulationCoordinator().executarProjeto(outra);
  return BasinScenarioComparison(primeira: r1, terceira: r2);
}

class BasinProjectController extends StateNotifier<BasinProject> {
  BasinProjectController() : super(BasinProject.exemploAula8Intermitente());

  void carregar(BasinProject projeto) => state = projeto;

  void setRegime(TipoInundacao regime) =>
      state = state.copyWith(regime: regime);

  /// Aplica o preset didático da Aula 8 do regime ativo (G5).
  void aplicarExemploAula8() => state = state.regime == TipoInundacao.permanente
      ? BasinProject.exemploAula8Permanente()
      : BasinProject.exemploAula8Intermitente();

  void setCenarioInfiltracao(CenarioInfiltracaoBasin value) {
    var project = _rememberActiveInfiltration(state);
    final stored = switch (value) {
      CenarioInfiltracaoBasin.primeira => project.dadosPrimeira,
      CenarioInfiltracaoBasin.terceira => project.dadosTerceira,
      CenarioInfiltracaoBasin.informado => null,
    };
    final data = project.toMap()
      ..['cenario_infiltracao'] = value.name
      ..['k'] = stored?.k
      ..['a'] = stored?.a
      ..['vib_m_min'] = stored?.vibMMin;
    state = BasinProject.fromMap(data);
  }

  /// Candidatas em L/s separadas por vírgula (p. 60). Texto inválido é
  /// ignorado; vazio limpa a lista.
  void setCandidatasVazao(String value) {
    if (value.trim().isEmpty) {
      state = state.copyWith(candidatasVazaoLs: const []);
      return;
    }
    final candidatas = value
        .split(',')
        .map((item) => double.tryParse(item.replaceAll(',', '.').trim()))
        .toList();
    if (candidatas.any((item) => item == null || !item.isFinite)) return;
    state = state.copyWith(
      candidatasVazaoLs: List.unmodifiable(candidatas.cast<double>()),
    );
  }

  void setTexturaSolo(TexturaSolo value) =>
      state = state.copyWith(texturaSolo: value);

  /// Cultura do tabuleiro; texto vazio limpa o campo (G4: nada inventado).
  /// A agronomia existente espelha a cultura para a etapa 5 ficar coerente.
  void setCultura(String value) {
    final trimmed = value.trim();
    final cultura = trimmed.isEmpty ? null : trimmed;
    final agronomia = state.agronomia;
    state = BasinProject.fromMap({
      ...state.toMap(),
      'cultura': cultura,
      'agronomia': agronomia == null
          ? null
          : BasinAgronomy.fromMap({...agronomia.toMap(), 'cultura': cultura})
                .toMap(),
    });
  }

  /// Campos numéricos de BasinAgronomy editáveis pela etapa de Cultura.
  static const _camposAgronomia = {
    'kc',
    'uccPercentual',
    'upmpPercentual',
    'densidadeGcm3',
    'profundidadeRaizesCm',
    'fracaoDisponivel',
  };

  /// Valor numérico de um campo da agronomia; texto vazio limpa o campo
  /// (G4: ausente nunca vira zero). [setNumero] delega para cá.
  void setAgronomia(String campo, String texto) {
    if (!_camposAgronomia.contains(campo)) return;
    final base = state.agronomia ?? const BasinAgronomy();
    if (texto.trim().isEmpty) {
      state = state.copyWith(
        agronomia: BasinAgronomy.fromMap({...base.toMap(), campo: null}),
      );
      return;
    }
    final value = double.tryParse(texto.replaceAll(',', '.'));
    if (value == null || !value.isFinite) return;
    state = state.copyWith(agronomia: base.withValue(campo, value));
  }

  /// Método de estimação da ETc (etapa de Clima e demanda).
  void setMetodoEtc(MetodoEtc value) =>
      state = state.copyWith(metodoEtc: value);

  /// Origem da precipitação registrada (etapa de Clima e demanda).
  void setOrigemChuva(OrigemChuva value) =>
      state = state.copyWith(origemChuva: value);

  /// Origem da IRN do balanço: informada prevalece (G14).
  void setOrigemIrn(OrigemIrnBasin value) =>
      state = state.copyWith(origemIrn: value);

  /// Mês de referência do Blaney–Criddle (1–12); null limpa.
  void setMesReferencia(int? value) {
    if (value != null && (value < 1 || value > 12)) return;
    state = state.copyWith(mesReferencia: value);
  }

  /// Chave do mapa serializado para cada campo editável do wizard.
  static const _chavesMap = <String, String>{
    'k': 'k',
    'a': 'a',
    'vibMMin': 'vib_m_min',
    'rugosidadeN': 'rugosidade_n',
    'comprimentoAreaM': 'comprimento_area_m',
    'larguraAreaM': 'largura_area_m',
    'comprimentoM': 'comprimento_m',
    'larguraM': 'largura_m',
    'areaUtilM2': 'area_util_m2',
    'declividade': 'declividade',
    'alturaDiqueM': 'altura_dique_m',
    'baseDiqueM': 'base_dique_m',
    'margemLivreM': 'margem_livre_m',
    'rho1F02': 'rho1_f02',
    'rho2F02': 'rho2_f02',
    'vmaxF02': 'vmax_f02',
    'laminaRequeridaMm': 'lamina_requerida_mm',
    'etIntermitenteMmDia': 'et_intermitente_mm_dia',
    'etoMmDia': 'eto_mm_dia',
    'precipitacaoEfetivaMmDia': 'precipitacao_efetiva_mm_dia',
    'temperaturaMediaC': 'temperatura_media_c',
    'latitudeGraus': 'latitude_graus',
    'vazaoTotalLs': 'vazao_total_l_s',
    'vmaxMMin': 'vmax_m_min',
    'laminaInicialMm': 'lamina_inicial_mm',
    'laminaFinalMm': 'lamina_final_mm',
    'rInicial': 'r_inicial',
    'areaHectares': 'area_hectares',
    'porosidade': 'porosidade',
    'profundidadeCamadaMm': 'profundidade_camada_mm',
    'condutividadeHidraulicaMmDia': 'condutividade_hidraulica_mm_dia',
    'dtaMmCm': 'dta_mm_cm',
    'fatorDisponibilidade': 'fator_disponibilidade',
    'evapotranspiracaoMmDia': 'evapotranspiracao_mm_dia',
    'laminaSuperficialMm': 'lamina_superficial_mm',
    'vazaoDisponivelLps': 'vazao_disponivel_l_s',
    'dsGcm3': 'ds_g_cm3',
    'dpGcm3': 'dp_g_cm3',
    'pciM': 'pci_m',
    'alturaLaminaRiceM': 'altura_lamina_rice_m',
    'evaporacaoTanqueMmDia': 'evaporacao_tanque_mm_dia',
    'ksatMDia': 'ksat_m_dia',
    'produtividadeSacosHa': 'produtividade_sacos_ha',
    'umidadeGraos': 'umidade_graos',
    'indiceColheita': 'indice_colheita',
    'uaGravimetrica': 'ua_gravimetrica',
    'massaSacoKg': 'massa_saco_kg',
    'areaArrozHa': 'area_arroz_ha',
    'tdDias': 'td_dias',
    'trDias': 'tr_dias',
    'jornadaHoras': 'jornada_horas',
    'mudancaParcelaMin': 'mudanca_parcela_min',
    'periodoArrozDias': 'periodo_arroz_dias',
    'intervaloDias': 'intervalo_dias',
  };

  /// Editáveis como inteiros no wizard (arredondados).
  static const _camposInteiros = {
    'periodoDias',
    'tabuleirosPorParcela',
    'intervaloDias',
  };

  void setNumero(String campo, String texto) {
    if (_camposAgronomia.contains(campo)) {
      setAgronomia(campo, texto);
      return;
    }
    if (texto.trim().isEmpty) {
      final chave = _chavesMap[campo];
      if (chave != null) {
        state = BasinProject.fromMap({...state.toMap(), chave: null});
      } else if (campo == 'periodoDias') {
        state = state.copyWith(periodoDias: 10);
      } else if (campo == 'tabuleirosPorParcela') {
        state = state.copyWith(tabuleirosPorParcela: 1);
      }
      state = _rememberActiveInfiltration(state);
      return;
    }
    final value = double.tryParse(texto.replaceAll(',', '.'));
    if (value == null || !value.isFinite) return;
    if (_camposInteiros.contains(campo)) {
      if (value != value.roundToDouble() || value <= 0) return;
      state = switch (campo) {
        'periodoDias' => state.copyWith(periodoDias: value.toInt()),
        'tabuleirosPorParcela' => state.copyWith(
          tabuleirosPorParcela: value.toInt(),
        ),
        'intervaloDias' => state.copyWith(intervaloDias: value.toInt()),
        _ => state,
      };
      return;
    }
    state = switch (campo) {
      'k' => state.copyWith(k: value),
      'a' => state.copyWith(a: value),
      'vibMMin' => state.copyWith(vibMMin: value),
      'rugosidadeN' => state.copyWith(rugosidadeN: value),
      'comprimentoAreaM' => state.copyWith(comprimentoAreaM: value),
      'larguraAreaM' => state.copyWith(larguraAreaM: value),
      'comprimentoM' => state.copyWith(comprimentoM: value),
      'larguraM' => state.copyWith(larguraM: value),
      'areaUtilM2' => state.copyWith(areaUtilM2: value),
      'declividade' => state.copyWith(declividade: value),
      'alturaDiqueM' => state.copyWith(alturaDiqueM: value),
      'baseDiqueM' => state.copyWith(baseDiqueM: value),
      'margemLivreM' => state.copyWith(margemLivreM: value),
      'rho1F02' => state.copyWith(rho1F02: value),
      'rho2F02' => state.copyWith(rho2F02: value),
      'vmaxF02' => state.copyWith(vmaxF02: value),
      'laminaRequeridaMm' => state.copyWith(laminaRequeridaMm: value),
      'etIntermitenteMmDia' => state.copyWith(etIntermitenteMmDia: value),
      'etoMmDia' => state.copyWith(etoMmDia: value),
      'precipitacaoEfetivaMmDia' => state.copyWith(
        precipitacaoEfetivaMmDia: value,
      ),
      'temperaturaMediaC' => state.copyWith(temperaturaMediaC: value),
      'latitudeGraus' => state.copyWith(latitudeGraus: value),
      'vazaoTotalLs' => state.copyWith(vazaoTotalLs: value),
      'vmaxMMin' => state.copyWith(vmaxMMin: value),
      'laminaInicialMm' => state.copyWith(laminaInicialMm: value),
      'laminaFinalMm' => state.copyWith(laminaFinalMm: value),
      'rInicial' => state.copyWith(rInicial: value),
      'areaHectares' => state.copyWith(areaHectares: value),
      'porosidade' => state.copyWith(porosidade: value),
      'profundidadeCamadaMm' => state.copyWith(profundidadeCamadaMm: value),
      'condutividadeHidraulicaMmDia' => state.copyWith(
        condutividadeHidraulicaMmDia: value,
      ),
      'dtaMmCm' => state.copyWith(dtaMmCm: value),
      'fatorDisponibilidade' => state.copyWith(fatorDisponibilidade: value),
      'evapotranspiracaoMmDia' => state.copyWith(evapotranspiracaoMmDia: value),
      'laminaSuperficialMm' => state.copyWith(laminaSuperficialMm: value),
      'vazaoDisponivelLps' => state.copyWith(vazaoDisponivelLps: value),
      'dsGcm3' => state.copyWith(dsGcm3: value),
      'dpGcm3' => state.copyWith(dpGcm3: value),
      'pciM' => state.copyWith(pciM: value),
      'alturaLaminaRiceM' => state.copyWith(alturaLaminaRiceM: value),
      'evaporacaoTanqueMmDia' => state.copyWith(evaporacaoTanqueMmDia: value),
      'ksatMDia' => state.copyWith(ksatMDia: value),
      'periodoArrozDias' => state.copyWith(periodoArrozDias: value),
      'produtividadeSacosHa' => state.copyWith(produtividadeSacosHa: value),
      'umidadeGraos' => state.copyWith(umidadeGraos: value),
      'indiceColheita' => state.copyWith(indiceColheita: value),
      'uaGravimetrica' => state.copyWith(uaGravimetrica: value),
      'massaSacoKg' => state.copyWith(massaSacoKg: value),
      'areaArrozHa' => state.copyWith(areaArrozHa: value),
      'tdDias' => state.copyWith(tdDias: value),
      'trDias' => state.copyWith(trDias: value),
      'jornadaHoras' => state.copyWith(jornadaHoras: value),
      'mudancaParcelaMin' => state.copyWith(mudancaParcelaMin: value),
      _ => state,
    };
    state = _rememberActiveInfiltration(state);
  }

  BasinProject _rememberActiveInfiltration(BasinProject project) {
    final values = BasinInfiltrationScenario(
      k: project.k,
      a: project.a,
      vibMMin: project.vibMMin,
    );
    return switch (project.cenarioInfiltracao) {
      CenarioInfiltracaoBasin.primeira => project.copyWith(
        dadosPrimeira: values,
      ),
      CenarioInfiltracaoBasin.terceira => project.copyWith(
        dadosTerceira: values,
      ),
      CenarioInfiltracaoBasin.informado => project,
    };
  }
}

final basinProjectProvider =
    StateNotifierProvider<BasinProjectController, BasinProject>(
      (ref) => BasinProjectController(),
    );

final basinProjectResultProvider = StateProvider<SimulationResult?>((ref) {
  ref.watch(basinProjectProvider);
  return null;
});

final basinScenarioComparisonProvider = StateProvider<BasinScenarioComparison?>(
  (ref) {
    ref.watch(basinProjectProvider);
    return null;
  },
);

SimulationResult calcularProjetoInundacao(BasinProject projeto) =>
    const BasinSimulationCoordinator().executarProjeto(projeto);
