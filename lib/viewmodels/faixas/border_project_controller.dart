import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_agronomy.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';

class BorderScenarioComparison {
  final BorderResult primeira, terceira;
  const BorderScenarioComparison(this.primeira, this.terceira);
}

BorderScenarioComparison calcularComparacaoCenarios(BorderProject project) {
  final first = project.dadosPrimeira, third = project.dadosTerceira;
  if (first?.k == null ||
      first?.a == null ||
      first?.vibMMin == null ||
      third?.k == null ||
      third?.a == null ||
      third?.vibMMin == null) {
    throw const BorderModelException(
      BorderStatus.entradaInvalida,
      'Informe separadamente k, a e VIB da primeira e da terceira irrigação.',
    );
  }
  final hydraulics = const BorderHydraulics();
  return BorderScenarioComparison(
    hydraulics.dimensionar(
      project.copyWith(
        cenarioInfiltracao: CenarioInfiltracaoFaixa.primeira,
        k: first!.k,
        a: first.a,
        vibMMin: first.vibMMin,
      ),
    ),
    hydraulics.dimensionar(
      project.copyWith(
        cenarioInfiltracao: CenarioInfiltracaoFaixa.terceira,
        k: third!.k,
        a: third.a,
        vibMMin: third.vibMMin,
      ),
    ),
  );
}

class BorderProjectController extends StateNotifier<BorderProject> {
  BorderProjectController() : super(BorderProject.ilustrativo);

  void carregar(BorderProject projeto) => state = projeto;
  void setJusante(CondicaoJusanteFaixa value) =>
      state = state.copyWith(jusante: value);
  void setCobertura(CoberturaFaixa value) =>
      state = state.copyWith(cobertura: value);
  void setTextura(TexturaSolo value) => state = state.copyWith(textura: value);
  void setManejo(ManejoFaixa value) => state = state.copyWith(manejo: value);
  void setCenarioInfiltracao(CenarioInfiltracaoFaixa value) {
    var project = _rememberActiveInfiltration(state);
    final stored = switch (value) {
      CenarioInfiltracaoFaixa.primeira => project.dadosPrimeira,
      CenarioInfiltracaoFaixa.terceira => project.dadosTerceira,
      CenarioInfiltracaoFaixa.informado => null,
    };
    final data = project.toMap()
      ..['cenarioInfiltracao'] = value.name
      ..['k'] = stored?.k
      ..['a'] = stored?.a
      ..['vibMMin'] = stored?.vibMMin;
    project = BorderProject.fromMap(data);
    state = project;
  }

  void setOrigemIrn(OrigemIrnFaixa value) =>
      state = state.copyWith(origemIrn: value);
  void setCultura(String value) => state = state.copyWith(cultura: value);
  void setTipoDique(String value) => state = state.copyWith(tipoDique: value);
  void setFracaoCorte(double? value) => state = BorderProject.fromMap({
    ...state.toMap(),
    'fracaoCortePlanejada': value,
  });
  void setEstacas(List<BorderStake> values) =>
      state = state.copyWith(estacas: List.unmodifiable(values));
  void setPerfilLongitudinal(List<BorderTerrainPoint> points) =>
      state = state.copyWith(perfilLongitudinal: List.unmodifiable(points));
  void setDataEnsaio(String value) => state = BorderProject.fromMap({
    ...state.toMap(),
    'dataEnsaioIso': value.trim().isEmpty ? null : value.trim(),
  });
  void setReferenciaRelogioEnsaio(String value) =>
      state = state.copyWith(referenciaRelogioEnsaio: value);
  void setObservacoesEnsaio(String value) =>
      state = state.copyWith(observacoesEnsaio: value);
  void setOrientacaoArea(String value) =>
      state = state.copyWith(orientacaoArea: value);
  void setUnidadeVmaxF02(String value) =>
      state = state.copyWith(unidadeVmaxF02: value);
  void setDispositivo({required double diametroCm, required double cargaCm}) =>
      state = state.copyWith(
        dispositivoDiametroCm: diametroCm,
        dispositivoCargaCm: cargaCm,
      );
  void setDiasFornecimento(String value) {
    if (value.trim().isEmpty) {
      state = state.copyWith(diasFornecimento: const []);
      return;
    }
    final days = value.split(',').map((s) => int.tryParse(s.trim())).toList();
    if (days.any((d) => d == null)) return;
    state = state.copyWith(
      diasFornecimento: List.unmodifiable(days.cast<int>()),
    );
  }

  void setNumero(String campo, String texto) {
    if (texto.trim().isEmpty) {
      final data = state.toMap();
      if (data.containsKey(campo)) {
        state = BorderProject.fromMap({...data, campo: null});
      } else if ((data['agronomia'] as Map?)?.containsKey(campo) ?? false) {
        state = BorderProject.fromMap({
          ...data,
          'agronomia': {
            ...(data['agronomia'] as Map<String, dynamic>),
            campo: null,
          },
        });
      }
      state = _rememberActiveInfiltration(state);
      return;
    }
    final value = double.tryParse(texto.replaceAll(',', '.'));
    if (value == null || !value.isFinite) return;
    if (const {
      'uccPercentual',
      'upmpPercentual',
      'densidadeGcm3',
      'profundidadeRaizesCm',
      'fracaoDisponivel',
      'kc',
      'espacamentoFileirasM',
      'espacamentoPlantasM',
      'evapotranspiracaoMmDia',
      'precipitacaoEfetivaMmDia',
    }.contains(campo)) {
      state = state.copyWith(
        agronomia: (state.agronomia ?? const BorderAgronomy()).withValue(
          campo,
          value,
        ),
      );
      return;
    }
    state = switch (campo) {
      'comprimentoAreaM' => state.copyWith(comprimentoAreaM: value),
      'larguraAreaM' => state.copyWith(larguraAreaM: value),
      'areaUtilM2' => state.copyWith(areaUtilM2: value),
      'comprimentoM' => state.copyWith(comprimentoM: value),
      'larguraM' => state.copyWith(larguraM: value),
      'desnivelLongitudinalM' => state.copyWith(desnivelLongitudinalM: value),
      'baseLongitudinalM' => state.copyWith(baseLongitudinalM: value),
      'desnivelTransversalM' => state.copyWith(desnivelTransversalM: value),
      'baseTransversalM' => state.copyWith(baseTransversalM: value),
      'alturaDiqueM' => state.copyWith(alturaDiqueM: value),
      'laminaSuperficialM' => state.copyWith(laminaSuperficialM: value),
      'k' => state.copyWith(k: value),
      'a' => state.copyWith(a: value),
      'vibMMin' => state.copyWith(vibMMin: value),
      'rugosidadeN' => state.copyWith(rugosidadeN: value),
      'rho1F02' => state.copyWith(rho1F02: value),
      'rho2F02' => state.copyWith(rho2F02: value),
      'vmaxF02' => state.copyWith(vmaxF02: value),
      'vazaoUnitariaLsM' => state.copyWith(vazaoUnitariaLsM: value),
      'irnMm' => state.copyWith(irnMm: value),
      'rInicial' => state.copyWith(rInicial: value),
      'vazaoDisponivelLs' => state.copyWith(vazaoDisponivelLs: value),
      'corteEnsaioMin' => state.copyWith(corteEnsaioMin: value),
      'jornadaHoras' => state.copyWith(jornadaHoras: value),
      'janelaFornecimentoHorasDia' => state.copyWith(
        janelaFornecimentoHorasDia: value,
      ),
      'inicioFornecimentoH' => state.copyWith(inicioFornecimentoH: value),
      'mudancaMin' => state.copyWith(mudancaMin: value),
      'periodoDias' =>
        value == value.roundToDouble()
            ? state.copyWith(periodoDias: value.toInt())
            : state,
      'faixasSimultaneas' =>
        value == value.roundToDouble()
            ? state.copyWith(faixasSimultaneas: value.toInt())
            : state,
      _ => state,
    };
    state = _rememberActiveInfiltration(state);
  }

  BorderProject _rememberActiveInfiltration(BorderProject project) {
    final values = BorderInfiltrationScenario(
      k: project.k,
      a: project.a,
      vibMMin: project.vibMMin,
    );
    return switch (project.cenarioInfiltracao) {
      CenarioInfiltracaoFaixa.primeira => project.copyWith(
        dadosPrimeira: values,
      ),
      CenarioInfiltracaoFaixa.terceira => project.copyWith(
        dadosTerceira: values,
      ),
      CenarioInfiltracaoFaixa.informado => project,
    };
  }
}

final borderProjectProvider =
    StateNotifierProvider<BorderProjectController, BorderProject>(
      (ref) => BorderProjectController(),
    );

final borderProjectResultProvider = StateProvider<SimulationResult?>((ref) {
  ref.watch(borderProjectProvider);
  return null;
});
final borderAlternativesProvider = StateProvider<BorderAlternatives?>((ref) {
  ref.watch(borderProjectProvider);
  return null;
});
final borderAlternativesLoadingProvider = StateProvider<bool>((ref) => false);
final borderSelectedAlternativeProvider = StateProvider<BorderCandidate?>((
  ref,
) {
  ref.watch(borderProjectProvider);
  return null;
});

Future<BorderAlternatives> buscarAlternativas(
  BorderProject projeto, {
  double? menorLsM,
  double? maiorLsM,
  double passoLsM = .05,
  String objetivo = 'Ea',
}) {
  final q = projeto.vazaoUnitariaLsM!;
  return compute(_buscarAlternativas, (
    projeto,
    menorLsM ?? q * .75,
    maiorLsM ?? q * 1.25,
    passoLsM,
    objetivo,
  ));
}

BorderAlternatives _buscarAlternativas(
  (BorderProject, double, double, double, String) input,
) => const BorderPlanning().explore(
  input.$1,
  menorLsM: input.$2,
  maiorLsM: input.$3,
  passoLsM: input.$4,
  objetivo: input.$5,
);
final borderTrialProvider = StateProvider<BorderTrialResult?>((ref) {
  ref.watch(borderProjectProvider);
  return null;
});
final borderTrialSimulationProvider = StateProvider<BorderResult?>((ref) {
  ref.watch(borderProjectProvider);
  return null;
});
final borderScenarioComparisonProvider =
    StateProvider<BorderScenarioComparison?>((ref) {
      ref.watch(borderProjectProvider);
      return null;
    });

SimulationResult calcularProjetoFaixa(BorderProject projeto) =>
    const RunBorderSimulation()(projeto.toCompatParameters());
