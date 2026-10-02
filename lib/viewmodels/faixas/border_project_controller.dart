import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_agronomy.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';

class BorderProjectController extends StateNotifier<BorderProject> {
  BorderProjectController() : super(BorderProject.ilustrativo);

  void carregar(BorderProject projeto) => state = projeto;
  void setJusante(CondicaoJusanteFaixa value) =>
      state = state.copyWith(jusante: value);
  void setCobertura(CoberturaFaixa value) =>
      state = state.copyWith(cobertura: value);
  void setTextura(TexturaSolo value) => state = state.copyWith(textura: value);
  void setManejo(ManejoFaixa value) => state = state.copyWith(manejo: value);
  void setCenarioInfiltracao(CenarioInfiltracaoFaixa value) =>
      state = state.copyWith(cenarioInfiltracao: value);
  void setOrigemIrn(OrigemIrnFaixa value) =>
      state = state.copyWith(origemIrn: value);
  void setCultura(String value) => state = state.copyWith(cultura: value);
  void setEstacas(List<BorderStake> values) =>
      state = state.copyWith(estacas: List.unmodifiable(values));
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

Future<BorderAlternatives> buscarAlternativas(BorderProject projeto) =>
    compute(_buscarAlternativas, projeto);

BorderAlternatives _buscarAlternativas(BorderProject projeto) =>
    const BorderPlanning().explore(
      projeto,
      menorLsM: projeto.vazaoUnitariaLsM! * .75,
      maiorLsM: projeto.vazaoUnitariaLsM! * 1.25,
    );
final borderTrialProvider = StateProvider<BorderTrialResult?>((ref) {
  ref.watch(borderProjectProvider);
  return null;
});

SimulationResult calcularProjetoFaixa(BorderProject projeto) =>
    const RunBorderSimulation()(projeto.toCompatParameters());
