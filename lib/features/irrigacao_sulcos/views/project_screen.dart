import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/shared/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/parameters_controller.dart';

import 'project_steps/area_step.dart';
import 'project_steps/avanco_step.dart';
import 'project_steps/clima_step.dart';
import 'project_steps/cultura_step.dart';
import 'project_steps/operacao_step.dart';
import 'project_steps/project_step_widgets.dart';
import 'project_steps/revisao_step.dart';
import 'project_steps/solo_step.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final Set<int> _completedSteps = <int>{};
  bool _cenarioCarregado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cenarioCarregado) return;
    _cenarioCarregado = true;
    final cenarioId = GoRouter.maybeOf(context)
        ?.state
        .uri
        .queryParameters[AppRoutes.cenarioId];
    if (cenarioId != null) _carregarCenario(cenarioId);
  }

  Future<void> _carregarCenario(String id) async {
    final cenario = await ref.read(scenarioServiceProvider).buscarPorId(id);
    if (!mounted || cenario == null) return;
    ref.read(parametersProvider.notifier)
      ..resetar()
      ..loadFromParams(cenario.parametros);
  }

  static const _stepTitles = [
    'Área, geometria e sulco',
    'Solo',
    'Cultura e raízes',
    'Clima e demanda',
    'Origem do avanço',
    'Operação',
    'Revisão',
  ];

  static const _stepIcons = [
    AppIcons.projetoArea,
    AppIcons.projetoSolo,
    AppIcons.projetoCultura,
    AppIcons.projetoClima,
    AppIcons.curvaAvanco,
    AppIcons.projetoOperacao,
    AppIcons.projetoRevisao,
  ];

  /// Navega para [step] sem validar — livre entre subtelas.
  void _goToStep(int step) {
    if (step == _currentStep) return;
    setState(() => _currentStep = step);
  }

  /// Valida a etapa atual e, se válida, marca como confirmada.
  bool _confirmCurrentStep() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    if (_currentStep == 4) {
      final error = ref.read(parametersProvider.notifier).validarEnsaio();
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return false;
      }
    }
    setState(() => _completedSteps.add(_currentStep));
    return true;
  }

  /// Etapas 0..5 precisam estar confirmadas para liberar o cálculo.
  bool get _allStepsConfirmed =>
      _completedSteps.containsAll(const {0, 1, 2, 3, 4, 5});

  List<int> get _unconfirmedSteps =>
      [0, 1, 2, 3, 4, 5].where((s) => !_completedSteps.contains(s)).toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parametersProvider);
    final accent = AppColors.sulco;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    ref.listen(parametersProvider, (previous, next) {
      if (next.resultado != null && previous?.resultado == null) {
        context.push(AppRoutes.sulcosResultados);
      }
      if (next.erro != null && next.erro != previous?.erro) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.erro!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo projeto'),
        actions: [
          if (_currentStep < 6)
            TextButton(
              onPressed: () => _goToStep(6),
              child: const Text('Pular para revisão'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IrrigationStepIndicator(
                      currentStep: _currentStep,
                      completedSteps: _completedSteps,
                      titles: _stepTitles,
                      icons: _stepIcons,
                      accent: accent,
                      onStepTapped: _goToStep,
                    ),
                    const SizedBox(height: 20),
                    _buildStepContent(state, accent, wide),
                    const SizedBox(height: 24),
                    if (_currentStep == 6 && !_allStepsConfirmed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PendingConfirmationsAlert(
                          stepTitles: _stepTitles,
                          unconfirmedSteps: _unconfirmedSteps,
                        ),
                      ),
                    StepNavigationButtons(
                      currentStep: _currentStep,
                      isFirst: _currentStep == 0,
                      isLast: _currentStep == 6,
                      executando: state.executando,
                      isConfirmed: _completedSteps.contains(_currentStep),
                      canCalculate: _allStepsConfirmed,
                      onPrevious: () => _goToStep(_currentStep - 1),
                      onNext: () => _goToStep(_currentStep + 1),
                      onConfirm: _confirmCurrentStep,
                      onCalculate: () {
                        FocusScope.of(context).unfocus();
                        if (!_allStepsConfirmed) return;
                        if (_formKey.currentState!.validate()) {
                          setState(() => _completedSteps.add(_currentStep));
                          ref
                              .read(parametersProvider.notifier)
                              .executarSimulacao();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ParametersState state, Color accent, bool wide) {
    return switch (_currentStep) {
      0 => AreaStep(state: state, accent: accent, wide: wide),
      1 => SoloStep(state: state, accent: accent, wide: wide),
      2 => CulturaStep(state: state, accent: accent, wide: wide),
      3 => ClimaStep(state: state, accent: accent, wide: wide),
      4 => OrigemAvancoStep(state: state, accent: accent, wide: wide),
      5 => OperacaoStep(state: state, accent: accent, wide: wide),
      6 => RevisaoStep(state: state, accent: accent),
      _ => const SizedBox.shrink(),
    };
  }
}
