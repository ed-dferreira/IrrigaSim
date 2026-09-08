import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';

class WizardState {
  final int etapa;
  final MetodoIrrigacao metodo;
  final String tipoSoloPreset;
  final String k;
  final String a;
  final String vib;
  final String lamina;
  final String comprimento;
  final String desnivelM;
  final String distanciaHorizontalM;
  final String larguraOuEspacamento;
  final String vazao;
  final String tempo;
  final String manningN;

  const WizardState({
    this.etapa = 1,
    this.metodo = MetodoIrrigacao.sulco,
    this.tipoSoloPreset = 'franco',
    this.k = '45.0',
    this.a = '0.55',
    this.vib = '2.0',
    this.lamina = '50.0',
    this.comprimento = '100',
    this.desnivelM = '0.50',
    this.distanciaHorizontalM = '100',
    this.larguraOuEspacamento = '0.8',
    this.vazao = '0.6',
    this.tempo = '90',
    this.manningN = '0.04',
  });

  double get desnivelValor => double.tryParse(desnivelM) ?? 0.0;
  double get distanciaValor => double.tryParse(distanciaHorizontalM) ?? 1.0;
  double get declividadeCalculada =>
      distanciaValor > 0 ? (desnivelValor / distanciaValor) * 100.0 : 0.0;

  WizardState copyWith({
    int? etapa,
    MetodoIrrigacao? metodo,
    String? tipoSoloPreset,
    String? k,
    String? a,
    String? vib,
    String? lamina,
    String? comprimento,
    String? desnivelM,
    String? distanciaHorizontalM,
    String? larguraOuEspacamento,
    String? vazao,
    String? tempo,
    String? manningN,
  }) {
    return WizardState(
      etapa: etapa ?? this.etapa,
      metodo: metodo ?? this.metodo,
      tipoSoloPreset: tipoSoloPreset ?? this.tipoSoloPreset,
      k: k ?? this.k,
      a: a ?? this.a,
      vib: vib ?? this.vib,
      lamina: lamina ?? this.lamina,
      comprimento: comprimento ?? this.comprimento,
      desnivelM: desnivelM ?? this.desnivelM,
      distanciaHorizontalM: distanciaHorizontalM ?? this.distanciaHorizontalM,
      larguraOuEspacamento: larguraOuEspacamento ?? this.larguraOuEspacamento,
      vazao: vazao ?? this.vazao,
      tempo: tempo ?? this.tempo,
      manningN: manningN ?? this.manningN,
    );
  }

  IrrigationParameters toIrrigationParameters() {
    return IrrigationParameters(
      comprimento: (double.tryParse(comprimento) ?? 100.0).clamp(10.0, 999999.0),
      declividade: (declividadeCalculada / 100.0).clamp(0.001, 1.0),
      larguraOuEspacamento:
          (double.tryParse(larguraOuEspacamento) ?? 0.8).clamp(0.1, 999.0),
      k: (double.tryParse(k) ?? 45.0).clamp(1.0, 9999.0),
      a: (double.tryParse(a) ?? 0.55).clamp(0.01, 0.99),
      vib: (double.tryParse(vib) ?? 2.0).clamp(0.1, 999.0),
      vazao: (double.tryParse(vazao) ?? 0.6).clamp(0.01, 9999.0),
      tempoAplicacao: (double.tryParse(tempo) ?? 90.0).clamp(1.0, 99999.0),
      laminaRequerida: (double.tryParse(lamina) ?? 50.0).clamp(1.0, 9999.0),
      manningN: (double.tryParse(manningN) ?? 0.04).clamp(0.01, 0.5),
    );
  }
}

class WizardViewModel extends StateNotifier<WizardState> {
  WizardViewModel() : super(const WizardState());

  void avancarEtapa() {
    if (state.etapa < 4) {
      state = state.copyWith(etapa: state.etapa + 1);
    }
  }

  void voltarEtapa() {
    if (state.etapa > 1) {
      state = state.copyWith(etapa: state.etapa - 1);
    }
  }

  void selecionarMetodo(MetodoIrrigacao metodo) {
    final larguraAjustada =
        metodo == MetodoIrrigacao.sulco && state.larguraOuEspacamento == '0.8'
            ? '0.75'
            : state.larguraOuEspacamento;
    state = state.copyWith(metodo: metodo, larguraOuEspacamento: larguraAjustada);
  }

  void aplicarPresetSolo(String preset) {
    final (k, a, vib) = switch (preset) {
      'arenoso' => ('65.0', '0.65', '5.0'),
      'argiloso' => ('30.0', '0.45', '0.8'),
      _ => ('45.0', '0.55', '2.0'),
    };
    state = state.copyWith(tipoSoloPreset: preset, k: k, a: a, vib: vib);
  }

  void atualizarK(String v) => state = state.copyWith(k: v, tipoSoloPreset: 'custom');
  void atualizarA(String v) => state = state.copyWith(a: v, tipoSoloPreset: 'custom');
  void atualizarVib(String v) => state = state.copyWith(vib: v, tipoSoloPreset: 'custom');
  void atualizarLamina(String v) => state = state.copyWith(lamina: v);
  void atualizarComprimento(String v) => state = state.copyWith(comprimento: v);
  void atualizarDesnivel(String v) => state = state.copyWith(desnivelM: v);
  void atualizarDistanciaHorizontal(String v) => state = state.copyWith(distanciaHorizontalM: v);
  void atualizarLarguraOuEspacamento(String v) => state = state.copyWith(larguraOuEspacamento: v);
  void atualizarVazao(String v) => state = state.copyWith(vazao: v);
  void atualizarTempo(String v) => state = state.copyWith(tempo: v);
  void atualizarManningN(String v) => state = state.copyWith(manningN: v);
}

final wizardProvider =
    StateNotifierProvider.autoDispose<WizardViewModel, WizardState>((ref) {
  return WizardViewModel();
});
