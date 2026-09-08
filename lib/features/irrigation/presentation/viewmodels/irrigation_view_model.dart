import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';

class IrrigationState {
  final List<IrrigationParameters> historico;
  final MetodoIrrigacao? metodoSelecionado;

  const IrrigationState({
    this.historico = const [],
    this.metodoSelecionado,
  });

  IrrigationState copyWith({
    List<IrrigationParameters>? historico,
    MetodoIrrigacao? metodoSelecionado,
  }) {
    return IrrigationState(
      historico: historico ?? this.historico,
      metodoSelecionado: metodoSelecionado ?? this.metodoSelecionado,
    );
  }
}

class IrrigationViewModel extends StateNotifier<IrrigationState> {
  IrrigationViewModel() : super(const IrrigationState());

  void setMetodo(MetodoIrrigacao metodo) {
    state = state.copyWith(metodoSelecionado: metodo);
  }
}

final irrigationProvider =
    StateNotifierProvider<IrrigationViewModel, IrrigationState>((ref) {
  return IrrigationViewModel();
});
