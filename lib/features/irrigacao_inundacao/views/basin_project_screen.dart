// Wizard do projeto de irrigação por inundação (Fase 6 e Fase 3 do plano de
// cultura/clima/operacao). Espelha
// lib/views/irrigation/faixas/border_project_screen.dart: ListView com etapas
// numeradas, confirmação por etapa e cálculo ao final, mas com conteúdo que
// varia conforme o regime (G8) e presets da Aula 8 (G5). Nove etapas: as
// etapas 5 (Cultura), 6 (Clima e demanda) e a Operação enriquecida são do
// plano docs/Plano_implementacao_bacia_cultura_clima_operacao.md.
//
// Este arquivo é o orquestrador do wizard: estado das etapas, carregamento
// de cenário, navegação e cálculo. O conteúdo de cada etapa fica em
// basin_project_steps/ e os helpers de formulário em basin_project/.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/features/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/core/theme/app_colors.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/area_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/clima_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/cultura_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/operacao_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/regime_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/revisao_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/solo_step.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_steps/taipa_step.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';

class BasinProjectScreen extends ConsumerStatefulWidget {
  const BasinProjectScreen({super.key});

  @override
  ConsumerState<BasinProjectScreen> createState() => _BasinProjectScreenState();
}

class _BasinProjectScreenState extends ConsumerState<BasinProjectScreen> {
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
        cenario.parametros.projetoInundacao ??
        ProjetoInundacao.fromLegacy(cenario.parametros);
    ref.read(basinProjectProvider.notifier).carregar(projeto);
  }

  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  final Set<int> _confirmedSteps = {};
  bool _calculando = false;
  final int _presetRevision = 0;

  /// Chave dos campos da etapa de cultura; muda ao aplicar um preset para
  /// que os TextFormFields reflitam os novos valores.
  int _cropPresetRevision = 0;

  /// Tempo de contato (min) usado no campo calculado I(t) da etapa de solo.
  double _tempoInfiltracaoMin = 10;

  static const _titles = [
    'Regime',
    'Área e geometria',
    'Tabuleiro e taipa',
    'Solo e infiltração',
    'Cultura e sistema radicular',
    'Clima e demanda',
    'Operação',
    'Revisão',
  ];

  static const _icons = [
    AppIcons.inundacao,
    AppIcons.projetoArea,
    AppIcons.basin,
    AppIcons.projetoSolo,
    AppIcons.projetoCultura,
    AppIcons.projetoClima,
    AppIcons.projetoOperacao,
    AppIcons.projetoRevisao,
  ];
  static const _subtitles = [
    'Escolha entre regime intermitente e permanente.',
    'Área, geometria e textura do tabuleiro.',
    'Tabuleiro, taipa e limites construtivos.',
    'Solo, infiltração e cenário de referência.',
    'Cultura, sistema radicular e lâmina requerida.',
    'Clima, evapotranspiração e demanda hídrica.',
    'Vazão, operação e checagem hidráulica.',
    'Revise as etapas e confirme antes de calcular.',
  ];

  /// Índice da etapa de Revisão (a última); as anteriores precisam ser
  /// confirmadas para liberar o cálculo.
  static const _revisaoStep = 7;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(basinProjectProvider);
    final notice = project.impedimento;
    final bloqueia = notice?.status.bloqueia ?? false;
    final todasConfirmadas = _confirmedSteps.containsAll(const {
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeto de inundação'),
        actions: [
          IconButton(
            tooltip: 'Referência — Aula 8',
            onPressed: () => context.push(AppRoutes.inundacaoReferencia),
            icon: const Icon(AppIcons.guiaDidatico),
          ),
          TextButton(
            onPressed: () => setState(() => _step = _revisaoStep),
            child: const Text('Pular para revisão'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IrrigationStepIndicator(
                    titles: _titles,
                    icons: _icons,
                    currentStep: _step,
                    completedSteps: _confirmedSteps,
                    accent: AppColors.inundacao,
                    onStepTapped: (index) => setState(() => _step = index),
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  IrrigationProjectStepCard(
                    title: _titles[_step],
                    subtitle: _subtitles[_step],
                    icon: _icons[_step],
                    accent: AppColors.inundacao,
                    child: IrrigationFieldGrid(fields: _fields(project)),
                  ),
                  if (_step == _revisaoStep) ...[
                    const SizedBox(height: IrrigationSpacing.major),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          notice?.mensagem ??
                              'Modelo disponível: as entradas respeitam as '
                                  'checagens operacionais do modelo.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: bloqueia
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                        ),
                      ),
                    ),
                    if (!todasConfirmadas) ...[
                      const SizedBox(height: IrrigationSpacing.compact),
                      IrrigationAlertBanner(
                        message:
                            'Confirme as etapas pendentes antes de calcular: '
                            '${List.generate(_revisaoStep, (i) => i).where((i) => !_confirmedSteps.contains(i)).map((i) => i + 1).join(', ')}.',
                      ),
                    ],
                  ],
                  const SizedBox(height: IrrigationSpacing.major),
                  _navigationRow(project, bloqueia, todasConfirmadas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Etapas: cada uma vive em basin_project_steps/ e recebe os helpers de
  // formulário, o projeto e o estado local de que precisa.
  // ---------------------------------------------------------------------------

  List<Widget> _fields(ProjetoInundacao project) {
    final fields = BasinProjectFields(ref: ref, unconfirm: _unconfirm);
    return switch (_step) {
      0 => regimeStep(context, fields, project),
      1 => areaStep(context, fields, project),
      2 => taipaStep(context, fields, project),
      3 => project.regime == TipoInundacao.permanente
          ? soloPermanenteStep(context, fields, project)
          : soloIntermitenteStep(
              context,
              fields,
              project,
              presetRevision: _presetRevision,
              tempoInfiltracaoMin: _tempoInfiltracaoMin,
              onTempoInfiltracaoChanged: _alterarTempoInfiltracao,
            ),
      4 => culturaStep(
        context,
        fields,
        project,
        cropPresetRevision: _cropPresetRevision,
        revisarCropPreset: _revisarCropPreset,
      ),
      5 => climaStep(context, fields, project),
      6 => operacaoStep(context, fields, project),
      _ => revisaoStep(context, fields, project),
    };
  }

  // ---------------------------------------------------------------------------
  // Controles e ações.
  // ---------------------------------------------------------------------------

  /// Limpa a confirmação da etapa atual quando qualquer entrada muda.
  void _unconfirm() => setState(() => _confirmedSteps.remove(_step));

  /// Recria os campos da etapa de cultura ao aplicar uma predefinição.
  void _revisarCropPreset() {
    setState(() {
      _cropPresetRevision++;
      _confirmedSteps.remove(_step);
    });
  }

  /// Guarda o tempo de contato e desconfirma a etapa de solo.
  void _alterarTempoInfiltracao(double parsed) {
    setState(() {
      _tempoInfiltracaoMin = parsed;
      _confirmedSteps.remove(_step);
    });
  }

  Widget _navigationRow(
    ProjetoInundacao project,
    bool bloqueia,
    bool todasConfirmadas,
  ) => IrrigationStepNavigation(
    isFirst: _step == 0,
    isLast: _step >= _revisaoStep,
    isConfirmed: _confirmedSteps.contains(_step),
    isBusy: _calculando,
    canCalculate: !bloqueia && todasConfirmadas,
    calculateIcon: AppIcons.projetoCalcular,
    onPrevious: () => setState(() => _step--),
    onConfirm: () {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) return;
      setState(() => _confirmedSteps.add(_step));
    },
    onNext: () => setState(() => _step++),
    onCalculate: () => _calcular(project),
  );

  Future<void> _calcular(ProjetoInundacao project) async {
    setState(() => _calculando = true);
    try {
      final result = calcularProjetoInundacao(project);
      ref.read(basinProjectResultProvider.notifier).state = result;
      if (!mounted) return;
      context.push(AppRoutes.inundacaoResultados);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }
}
