import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/viewmodels/border_project_controller.dart';
import 'package:irrigasim/features/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/crop_presets.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/area_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/cultura_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/avanco_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/clima_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/dimensoes_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/operacao_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/revisao_step.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project_steps/solo_step.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Orquestrador do wizard de projeto de faixas: estado do wizard,
/// carregamento de cenário, cálculo e navegação. O conteúdo de cada etapa
/// vive em `border_project_steps/`.
class BorderProjectScreen extends ConsumerStatefulWidget {
  const BorderProjectScreen({super.key});

  @override
  ConsumerState<BorderProjectScreen> createState() =>
      _BorderProjectScreenState();
}

class _BorderProjectScreenState extends ConsumerState<BorderProjectScreen> {
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
    final projeto =
        cenario.parametros.projetoFaixa ??
        BorderProject.fromLegacy(cenario.parametros);
    ref.read(borderProjectProvider.notifier).carregar(projeto);
  }

  static const _titles = [
    'Área e geometria',
    'Dimensões da faixa',
    'Solo',
    'Cultura e sistema radicular',
    'Clima e demanda',
    'Avanço e manejo',
    'Operação',
    'Revisão',
  ];
  static const _icons = [
    AppIcons.projetoArea,
    AppIcons.faixa,
    AppIcons.projetoSolo,
    AppIcons.projetoCultura,
    AppIcons.projetoClima,
    AppIcons.curvaAvanco,
    AppIcons.projetoOperacao,
    AppIcons.projetoRevisao,
  ];
  static const _subtitles = [
    'Dados da gleba, levantamento topográfico e geometria da faixa.',
    'Comprimento, largura e declive que conduzem o avanço da lâmina.',
    'Características do solo e curva de infiltração.',
    'Cultura, sistema radicular e demanda hídrica.',
    'Clima, evapotranspiração e lâmina requerida.',
    'Ensaio de campo ou estimativa da curva de avanço.',
    'Vazão, janela de fornecimento e operação da faixa.',
    'Revise as etapas e confirme antes de calcular.',
  ];
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  final Set<int> _confirmedSteps = {};
  bool _calculando = false;
  String? _erroEstacas;
  String? _erroPerfil;
  double _diametroBooherCm = 10;
  double _cargaBooherCm = 5;
  int _cropPresetRevision = 0;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(borderProjectProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeto de faixas'),
        actions: [
          if (_step < 7)
            TextButton(
              onPressed: () => setState(() => _step = 7),
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
                      titles: _titles,
                      icons: _icons,
                      currentStep: _step,
                      completedSteps: _confirmedSteps,
                      accent: AppColors.faixa,
                      onStepTapped: (index) => setState(() => _step = index),
                    ),
                    const SizedBox(height: IrrigationSpacing.major),
                    IrrigationProjectStepCard(
                      title: _titles[_step],
                      subtitle: _subtitles[_step],
                      icon: _icons[_step],
                      accent: AppColors.faixa,
                      child: IrrigationFieldGrid(fields: _fields(project)),
                    ),
                    const SizedBox(height: IrrigationSpacing.major),
                    if (_step == 7) ...[
                      Card(
                        color: colors.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                AppIcons.atencao,
                                color: colors.onTertiaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  project.impedimentoModelo ?? 'Modelo disponível: faixa aberta em declive, saída livre e vazão constante até o avanço completo. O corte é calculado; faixa fechada, em nível e vazão reduzida exigem outro modelo.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colors.onTertiaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_confirmedSteps.containsAll(const {
                        0,
                        1,
                        2,
                        3,
                        4,
                        5,
                        6,
                      })) ...[
                        IrrigationAlertBanner(
                          message:
                              'Confirme as etapas pendentes antes de calcular: ${[for (var i = 0; i < 7; i++)
                                if (!_confirmedSteps.contains(i)) _titles[i]].join(', ')}.',
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    IrrigationStepNavigation(
                      isFirst: _step == 0,
                      isLast: _step == 7,
                      isConfirmed: _confirmedSteps.contains(_step),
                      isBusy: _calculando,
                      canCalculate: !_calculando &&
                          project.impedimentoModelo == null &&
                          _titles
                              .asMap()
                              .keys
                              .where((i) => i < 7)
                              .every(_confirmedSteps.contains),
                      nextTooltip: 'Avançar para a próxima etapa',
                      calculateTooltip: 'Calcular a simulação da faixa',
                      onPrevious: () => setState(() => _step--),
                      onConfirm: () {
                        if ((_formKey.currentState?.validate() ?? false) &&
                            _erroEstacas == null &&
                            _erroPerfil == null) {
                          setState(() => _confirmedSteps.add(_step));
                        }
                      },
                      onNext: () => setState(() => _step++),
                      onCalculate: () {
                        setState(() => _calculando = true);
                        try {
                          final result = calcularProjetoFaixa(project);
                          ref
                                  .read(borderProjectResultProvider.notifier)
                                  .state =
                              result;
                          context.push('/home/irrigation/border-results');
                        } on FormatException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _calculando = false);
                          }
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

  BorderProjectFields get _campos {
    void confirmacaoInvalidada() => setState(() {
      _confirmedSteps.remove(_step);
    });
    return BorderProjectFields(
      ref: ref,
      unconfirm: confirmacaoInvalidada,
      setState: setState,
      setErroPerfil: (v) => setState(() {
        _erroPerfil = v;
        if (v == null) _confirmedSteps.remove(_step);
      }),
      setErroEstacas: (v) => setState(() {
        _erroEstacas = v;
        if (v == null) _confirmedSteps.remove(_step);
      }),
      setDiametroBooherCm: (v) => setState(() => _diametroBooherCm = v),
      setCargaBooherCm: (v) => setState(() => _cargaBooherCm = v),
      revisarPredefinicaoCultura: () => setState(() {
        _cropPresetRevision++;
        _confirmedSteps.remove(_step);
      }),
    );
  }

  List<Widget> _fields(BorderProject p) => switch (_step) {
    0 => areaStep(_campos, p, _erroPerfil),
    1 => dimensoesStep(_campos, p),
    2 => soloStep(
      _campos,
      p,
      diametroBooherCm: _diametroBooherCm,
      cargaBooherCm: _cargaBooherCm,
    ),
    3 => culturaStep(
      context,
      _campos,
      _selectedBorderCropPreset(p),
      p.cultura,
      _cropPresetRevision,
    ),
    4 => climaStep(_campos, p),
    5 => avancoStep(
      context,
      _campos,
      p,
      erroEstacas: _erroEstacas,
      trial: ref.watch(borderTrialProvider),
      simulacaoEnsaio: ref.watch(borderTrialSimulationProvider),
      montado: () => mounted,
    ),
    6 => operacaoStep(_campos, p),
    _ => revisaoStep(_campos, p),
  };
}

CropPreset? _selectedBorderCropPreset(BorderProject project) =>
    selectedCropPreset(
      cultura: project.cultura,
      kc: project.agronomia?.kc,
      rows: project.agronomia?.espacamentoFileirasM,
      plants: project.agronomia?.espacamentoPlantasM,
      roots: project.agronomia?.profundidadeRaizesCm,
      fraction: project.agronomia?.fracaoAguaDisponivel,
    );
