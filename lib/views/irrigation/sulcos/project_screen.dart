import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart'
    show PontoEnsaio;
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/services/simulation/lamina_requerida.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final Set<int> _completedSteps = <int>{};

  static const _stepTitles = [
    'Área e geometria',
    'Dimensões do sulco',
    'Solo',
    'Cultura e raízes',
    'Clima e demanda',
    'Origem do avanço',
    'Operação',
    'Revisão',
  ];

  static const _stepIcons = [
    AppIcons.projetoArea,
    AppIcons.projetoSulco,
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
    if (_currentStep == 5) {
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

  /// Etapas 0..6 precisam estar confirmadas para liberar o cálculo.
  bool get _allStepsConfirmed =>
      _completedSteps.containsAll(const {0, 1, 2, 3, 4, 5, 6});

  List<int> get _unconfirmedSteps =>
      [0, 1, 2, 3, 4, 5, 6].where((s) => !_completedSteps.contains(s)).toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parametersProvider);
    final accent = _methodColor(state.metodo);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    ref.listen(parametersProvider, (previous, next) {
      if (next.resultado != null && previous?.resultado == null) {
        context.push('/home/irrigation/project-results');
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
          if (_currentStep < 7)
            TextButton(
              onPressed: () => _goToStep(7),
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
                    _StepIndicator(
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
                    if (_currentStep == 7 && !_allStepsConfirmed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PendingConfirmationsAlert(
                          stepTitles: _stepTitles,
                          unconfirmedSteps: _unconfirmedSteps,
                        ),
                      ),
                    _NavigationButtons(
                      currentStep: _currentStep,
                      isFirst: _currentStep == 0,
                      isLast: _currentStep == 7,
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
      0 => _AreaStep(state: state, accent: accent, wide: wide),
      1 => _SulcoStep(state: state, accent: accent, wide: wide),
      2 => _SoloStep(state: state, accent: accent, wide: wide),
      3 => _CulturaStep(state: state, accent: accent, wide: wide),
      4 => _ClimaStep(state: state, accent: accent, wide: wide),
      5 => _OrigemAvancoStep(state: state, accent: accent, wide: wide),
      6 => _OperacaoStep(state: state, accent: accent, wide: wide),
      7 => _RevisaoStep(state: state, accent: accent),
      _ => const SizedBox.shrink(),
    };
  }
}

// ──────────────────────── Step Indicator ────────────────────────

class _StepIndicator extends StatefulWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.completedSteps,
    required this.titles,
    required this.icons,
    required this.accent,
    required this.onStepTapped,
  });

  final int currentStep;
  final Set<int> completedSteps;
  final List<String> titles;
  final List<IconData> icons;
  final Color accent;
  final ValueChanged<int> onStepTapped;

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator> {
  final _scrollController = ScrollController();
  late final List<GlobalKey> _stepKeys = List.generate(
    widget.titles.length,
    (_) => GlobalKey(),
  );
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollAvailability);
  }

  @override
  void didUpdateWidget(covariant _StepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _stepKeys[widget.currentStep].currentContext;
        if (target != null) {
          _scrollController.position.ensureVisible(
            target.findRenderObject()!,
            duration: const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  void _updateScrollAvailability() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final back = position.pixels > position.minScrollExtent;
    final forward = position.pixels < position.maxScrollExtent;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
  }

  void _scroll(int direction) {
    final position = _scrollController.position;
    final target =
        (position.pixels + direction * position.viewportDimension * 0.7).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showArrows = MediaQuery.sizeOf(context).width >= 760;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          if (showArrows)
            IconButton(
              tooltip: 'Ver etapas anteriores',
              onPressed: _canScrollBack ? () => _scroll(-1) : null,
              icon: const Icon(AppIcons.etapasAnteriores),
            ),
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updateScrollAvailability();
                });
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < widget.titles.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 8),
                        _buildStep(context, colors, index),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showArrows)
            IconButton(
              tooltip: 'Ver próximas etapas',
              onPressed: _canScrollForward ? () => _scroll(1) : null,
              icon: const Icon(AppIcons.etapasSeguintes),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, ColorScheme colors, int index) {
    final isCompleted = widget.completedSteps.contains(index);
    final isCurrent = index == widget.currentStep;
    return Semantics(
      key: _stepKeys[index],
      button: true,
      selected: isCurrent,
      label:
          '${isCompleted
              ? "Preenchida: "
              : isCurrent
              ? "Etapa atual: "
              : ""}${widget.titles[index]}',
      child: InkWell(
        onTap: () => widget.onStepTapped(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent
                ? widget.accent.withValues(alpha: 0.12)
                : isCompleted
                ? colors.primaryContainer
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? widget.accent
                  : isCompleted
                  ? colors.primary
                  : colors.outlineVariant,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted)
                Icon(Icons.check_rounded, size: 18, color: colors.primary)
              else
                Icon(
                  widget.icons[index],
                  size: 18,
                  color: isCurrent ? widget.accent : colors.onSurfaceVariant,
                ),
              const SizedBox(width: 8),
              Text(
                widget.titles[index],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isCurrent
                      ? widget.accent
                      : isCompleted
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Navigation Buttons ────────────────────────

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.currentStep,
    required this.isFirst,
    required this.isLast,
    required this.executando,
    required this.isConfirmed,
    required this.canCalculate,
    required this.onPrevious,
    required this.onNext,
    required this.onConfirm,
    required this.onCalculate,
  });

  final int currentStep;
  final bool isFirst;
  final bool isLast;
  final bool executando;
  final bool isConfirmed;
  final bool canCalculate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onConfirm;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Voltar'),
          ),
        const Spacer(),
        if (!isLast) ...[
          isConfirmed
              ? Chip(
                  avatar: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  label: const Text('Confirmada'),
                  backgroundColor: colors.primaryContainer,
                  side: BorderSide.none,
                )
              : OutlinedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Confirmar'),
                ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Próximo'),
          ),
        ] else
          FilledButton.icon(
            onPressed: executando || !canCalculate ? null : onCalculate,
            icon: executando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.executarSimulacao),
            label: Text(executando ? 'Calculando…' : 'Calcular projeto'),
          ),
      ],
    );
  }
}

// ──────────────────────── Shared BentoCard ────────────────────────

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

// ──────────────────────── Shared Field ────────────────────────

class _Field extends ConsumerWidget {
  const _Field({
    required this.name,
    required this.label,
    required this.value,
    this.suffix,
    this.helper,
    this.allowZero = false,
    this.optional = false,
  });
  final String name;
  final String label;
  final double? value;
  final String? suffix;
  final String? helper;
  final bool allowZero;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value == null ? '' : _format(value!),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
        ],
        decoration: InputDecoration(suffixText: suffix, helperText: helper),
        onChanged: (text) => ref
            .read(parametersProvider.notifier)
            .updateField(campo: name, valor: text),
        validator: (text) {
          if (optional && (text == null || text.trim().isEmpty)) {
            return null;
          }
          final number = double.tryParse((text ?? '').replaceAll(',', '.'));
          if (number == null) return 'Informe um número válido';
          if (allowZero ? number < 0 : number <= 0) {
            return allowZero
                ? 'Use zero ou um valor positivo'
                : 'Use um valor maior que zero';
          }
          if ((name == 'a' ||
                  name == 'porosidade' ||
                  name == 'fatorDisponibilidade' ||
                  name == 'kc') &&
              number > 1.4) {
            return 'O valor máximo é 1,4';
          }
          if (name == 'periodoIrrigacaoDias' &&
              number != number.truncateToDouble()) {
            return 'Informe o período como número inteiro de dias';
          }
          return null;
        },
      ),
    ],
  );
}

class _StringField extends ConsumerWidget {
  const _StringField({
    required this.name,
    required this.label,
    required this.value,
    this.helper,
  });
  final String name;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        decoration: InputDecoration(helperText: helper),
        onChanged: (text) =>
            ref.read(parametersProvider.notifier).setNomeCultura(text),
      ),
    ],
  );
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.fields, required this.wide});
  final List<Widget> fields;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: fields
            .map(
              (e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: e),
            )
            .toList(),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: fields.map((e) => SizedBox(width: 300, child: e)).toList(),
    );
  }
}

// ──────────────────────── Step 0: Área ────────────────────────

class _AreaStep extends ConsumerWidget {
  const _AreaStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _BentoCard(
        title: 'Área e geometria do terreno',
        subtitle: 'Informe as dimensões da parcela e o desnível longitudinal.',
        icon: AppIcons.projetoArea,
        accent: accent,
        child: _FieldGrid(
          wide: wide,
          fields: [
            _Field(
              name: 'comprimento',
              label: 'Comprimento do sulco',
              value: state.comprimento,
              suffix: 'm',
            ),
            _Field(
              name: 'comprimentoMaximoTerrenoM',
              label: 'Limite de comprimento do terreno',
              value: state.comprimentoMaximoTerrenoM,
              suffix: 'm',
            ),
            if (state.metodo == MetodoIrrigacao.sulco)
              _Field(
                name: 'areaHectares',
                label: 'Área efetiva da parcela',
                value: state.areaHectares,
                suffix: 'ha',
              ),
            _Field(
              name: 'larguraOuEspacamento',
              label: state.metodo == MetodoIrrigacao.sulco
                  ? 'Espaçamento entre sulcos'
                  : state.metodo == MetodoIrrigacao.faixa
                  ? 'Largura da faixa'
                  : 'Largura',
              value: state.larguraOuEspacamento,
              suffix: 'm',
            ),
            _Field(
              name: 'desnivelM',
              label: 'Desnível longitudinal (ΔH)',
              value: state.desnivelM,
              suffix: 'm',
              allowZero: true,
            ),
            _Field(
              name: 'distanciaHorizontalM',
              label: 'Distância longitudinal',
              value: state.distanciaHorizontalM,
              suffix: 'm',
            ),
            if (state.metodo != MetodoIrrigacao.sulco) ...[
              _Field(
                name: 'desnivelTransversalM',
                label: 'Desnível transversal (ΔH)',
                value: state.desnivelTransversalM,
                suffix: 'm',
                allowZero: true,
              ),
              _Field(
                name: 'distanciaTransversalM',
                label: 'Distância transversal',
                value: state.distanciaTransversalM,
                suffix: 'm',
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SlopeSummaryCard(state: state),
      const SizedBox(height: 12),
      Semantics(
        button: true,
        label: 'Usar maior comprimento viável',
        child: FilledButton.icon(
          onPressed: () => ref
              .read(parametersProvider.notifier)
              .recomendarMaiorComprimento(),
          icon: const Icon(AppIcons.recomendacao),
          label: const Text('Usar maior comprimento viável'),
        ),
      ),
      if (state.mensagemPlanejamento != null) ...[
        const SizedBox(height: 8),
        Text(
          state.mensagemPlanejamento!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
      const SizedBox(height: 12),
      _SlopeRangeAlert(state: state),
    ],
  );
}

class _SlopeRangeAlert extends StatelessWidget {
  const _SlopeRangeAlert({required this.state});
  final ParametersState state;

  @override
  Widget build(BuildContext context) {
    if (state.metodo != MetodoIrrigacao.sulco) return const SizedBox.shrink();
    final tipo = state.tipoSulco;
    if (tipo == null) return const SizedBox.shrink();

    final info = TipoSulcoInfo.getInfo(tipo);
    final percent = state.declividade * 100;
    final faixa = info.declividade.classificar(percent);
    final mensagem = info.declividade.alertaDeclividade(
      tipo: tipo,
      percent: percent,
    );
    if (mensagem == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final critico = faixa == FaixaDeclividade.fora;
    final background = critico
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final foreground = critico
        ? colors.onErrorContainer
        : colors.onTertiaryContainer;
    final titulo = switch (faixa) {
      FaixaDeclividade.usavel => 'Declividade fora do aconselhável',
      FaixaDeclividade.fora => 'Declividade fora da faixa usável',
      FaixaDeclividade.ideal || FaixaDeclividade.aconselhavel => '',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: foreground, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Pending Confirmations Alert ────────────────────────

class _PendingConfirmationsAlert extends StatelessWidget {
  const _PendingConfirmationsAlert({
    required this.stepTitles,
    required this.unconfirmedSteps,
  });

  final List<String> stepTitles;
  final List<int> unconfirmedSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendentes = unconfirmedSteps.map((s) => stepTitles[s]).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etapas pendentes de confirmação',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confirme as seguintes etapas antes de calcular: $pendentes.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Step 1: Sulco ────────────────────────

class _SulcoStep extends StatelessWidget {
  const _SulcoStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _Field(
        name: 'larguraOuEspacamento',
        label: 'Espaçamento entre sulcos',
        value: state.larguraOuEspacamento,
        suffix: 'm',
      ),
      if (state.metodo == MetodoIrrigacao.sulco) ...[
        _Field(
          name: 'larguraSulcoM',
          label: 'Largura superior do sulco (opcional)',
          value: state.larguraSulcoM,
          suffix: 'm',
          helper: 'Mantenha em branco quando não medida.',
          optional: true,
        ),
        _Field(
          name: 'profundidadeSulcoM',
          label: 'Profundidade do sulco (opcional)',
          value: state.profundidadeSulcoM,
          suffix: 'm',
          helper: 'Mantenha em branco quando não medida.',
          optional: true,
        ),
        CalculatedField(
          label: 'Vazão por sulco',
          value: state.vazao,
          suffix: 'L/s',
        ),
        _Field(
          name: 'tempoAplicacao',
          label: 'Tempo de oportunidade no final',
          value: state.tempoAplicacao,
          suffix: 'min',
        ),
        CalculatedField(
          label: 'Avanço até metade do comprimento',
          value: state.tempoAvancoMetadeMin,
          suffix: 'min',
        ),
        CalculatedField(
          label: 'Avanço até o final',
          value: state.tempoAvancoFinalMin,
          suffix: 'min',
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.metodo == MetodoIrrigacao.sulco &&
            state.tipoSulco != null) ...[
          _TipoSulcoInfoCard(tipo: state.tipoSulco!),
          const SizedBox(height: 16),
          if (!state.tipoSulco!.suportaEscoamentoTerminal) ...[
            _UnsupportedFurrowModelNotice(tipo: state.tipoSulco!),
            const SizedBox(height: 16),
          ],
        ],
        _BentoCard(
          title: 'Dimensões e operação do sulco',
          subtitle: 'Geometria e espaçamento. Vazão e tempos de avanço são calculados pela aplicação; o tempo de oportunidade pode ser editado.',
          icon: AppIcons.projetoSulco,
          accent: accent,
          child: _FieldGrid(fields: fields, wide: wide),
        ),
      ],
    );
  }
}

class _UnsupportedFurrowModelNotice extends StatelessWidget {
  const _UnsupportedFurrowModelNotice({required this.tipo});

  final TipoSulco tipo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${tipo.motivoSemSuporteTerminal} A simulação genérica está bloqueada para evitar resultados hidráulicos enganosos.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Step 2: Solo ────────────────────────

class _SoloStep extends ConsumerWidget {
  const _SoloStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.metodo == MetodoIrrigacao.sulco)
        _BentoCard(
          title: 'Textura do solo',
          subtitle: 'Selecione a textura para fórmula de erosão por tipo.',
          icon: Icons.landscape_rounded,
          accent: accent,
          child: SegmentedButton<TexturaSolo>(
            segments: TexturaSolo.values
                .map((t) => ButtonSegment(value: t, label: Text(t.displayName)))
                .toList(),
            selected: {state.texturaSolo},
            onSelectionChanged: (value) => ref
                .read(parametersProvider.notifier)
                .setTexturaSolo(value.first),
          ),
        ),
      if (state.metodo == MetodoIrrigacao.sulco) const SizedBox(height: 16),
      _BentoCard(
        title: 'Água disponível no solo',
        subtitle:
            'Dados para calcular automaticamente a lâmina requerida (IRN).',
        icon: Icons.water_drop_outlined,
        accent: accent,
        child: _FieldGrid(
          wide: wide,
          fields: [
            _Field(
              name: 'uccPercentual',
              label: 'Umidade na capacidade de campo (UCC)',
              value: state.uccPercentual,
              suffix: '%',
            ),
            _Field(
              name: 'upmpPercentual',
              label: 'Umidade no ponto de murcha (UPMP)',
              value: state.upmpPercentual,
              suffix: '%',
            ),
            _Field(
              name: 'densidadeAparenteGcm3',
              label: 'Densidade aparente',
              value: state.densidadeAparenteGcm3,
              suffix: 'g/cm³',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _BentoCard(
        title: 'Infiltração do solo',
        subtitle: state.metodo == MetodoIrrigacao.sulco
            ? 'Parâmetros da curva de infiltração acumulada.'
            : 'Parâmetros do modelo Kostiakov–Lewis.',
        icon: AppIcons.projetoSolo,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldGrid(
              wide: wide,
              fields: [
                if (state.metodo != MetodoIrrigacao.sulco ||
                    state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.equacaoAcumuladaInformada) ...[
                  _Field(
                    name: 'k',
                    label: state.metodo == MetodoIrrigacao.sulco
                        ? 'Coeficiente acumulado aI'
                        : 'Coeficiente de infiltração k',
                    value: state.k,
                    suffix: state.metodo == MetodoIrrigacao.sulco
                        ? 'mm/minⁿ'
                        : 'm/minᵃ',
                  ),
                  _Field(
                    name: 'a',
                    label: state.metodo == MetodoIrrigacao.sulco
                        ? 'Expoente acumulado n'
                        : 'Expoente a',
                    value: state.a,
                    helper: 'Entre 0 e 1',
                  ),
                ],
                if (state.metodo != MetodoIrrigacao.sulco)
                  _Field(
                    name: 'vib',
                    label: 'Infiltração básica (VIB)',
                    value: state.vib,
                    suffix: 'm/min',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.metodo == MetodoIrrigacao.sulco
                  ? 'A lâmina infiltrada é calculada por aI·Toⁿ, com tempo em minutos.'
                  : 'O tempo do ensaio deve estar em minutos; k e VIB devem usar as unidades indicadas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.metodo == MetodoIrrigacao.sulco) ...[
              const SizedBox(height: 14),
              SegmentedButton<OrigemCurvaInfiltracao>(
                segments: const [
                  ButtonSegment(
                    value: OrigemCurvaInfiltracao.equacaoAcumuladaInformada,
                    label: Text('Equação acumulada'),
                  ),
                  ButtonSegment(
                    value: OrigemCurvaInfiltracao.ensaioEntradaSaida,
                    label: Text('Ensaio entrada/saída'),
                  ),
                ],
                selected: {state.origemCurvaInfiltracao},
                onSelectionChanged: (value) => ref
                    .read(parametersProvider.notifier)
                    .setOrigemCurvaInfiltracao(value.first),
              ),
              if (state.origemCurvaInfiltracao ==
                  OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
                const SizedBox(height: 12),
                _FieldGrid(
                  wide: wide,
                  fields: [
                    _Field(
                      name: 'distanciaEnsaioInfiltracaoM',
                      label: 'Comprimento ensaiado',
                      value: state.distanciaEnsaioInfiltracaoM,
                      suffix: 'm',
                    ),
                    _Field(
                      name: 'espacamentoEnsaioInfiltracaoM',
                      label: 'Espaçamento ensaiado',
                      value: state.espacamentoEnsaioInfiltracaoM,
                      suffix: 'm',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _EntradaSaidaEditor(
                  pontos: state.medicoesEntradaSaida,
                  onChanged: ref
                      .read(parametersProvider.notifier)
                      .setMedicoesEntradaSaida,
                ),
                Text(
                  'Informe as vazões totais do trecho ensaiado. Se o dado estiver '
                  'normalizado por 100 m, use 100 m no comprimento ensaiado. '
                  'O ajuste usa VI = (Qentrada − Qsaída) × 3600 / '
                  '(comprimento × espaçamento). A integração converte VI '
                  '(mm/h) para a equação acumulada usada no perfil.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    ],
  );
}

// ──────────────────────── Step 3: Cultura ────────────────────────

class _CulturaStep extends ConsumerWidget {
  const _CulturaStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _BentoCard(
    title: 'Cultura e sistema radicular',
    subtitle: 'Informações da cultura para estimativa de demanda hídrica.',
    icon: AppIcons.projetoCultura,
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldGrid(
          wide: wide,
          fields: [
            _StringField(
              name: 'nomeCultura',
              label: 'Nome da cultura',
              value: state.nomeCultura,
              helper: 'Ex: Milho, Soja, Algodão',
            ),
            _Field(
              name: 'kc',
              label: 'Coeficiente da cultura (Kc)',
              value: state.kc,
              helper: '0 a 1,4',
            ),
            _Field(
              name: 'espacamentoFileirasM',
              label: 'Espaçamento entre fileiras',
              value: state.espacamentoFileirasM,
              suffix: 'm',
            ),
            _Field(
              name: 'espacamentoPlantasM',
              label: 'Espaçamento entre plantas',
              value: state.espacamentoPlantasM,
              suffix: 'm',
            ),
            _Field(
              name: 'profundidadeRaizesCm',
              label: 'Profundidade das raízes',
              value: state.profundidadeRaizesCm,
              suffix: 'cm',
            ),
            _Field(
              name: 'fracaoAguaDisponivel',
              label: 'Fração de água disponível',
              value: state.fracaoAguaDisponivel,
              helper: 'Entre 0 e 1',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LaminaRequeridaCard(resultado: state.laminaRequeridaResultado),
      ],
    ),
  );
}

// ──────────────────────── Step 4: Clima ────────────────────────

class _ClimaStep extends StatelessWidget {
  const _ClimaStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) => _BentoCard(
    title: 'Clima e demanda hídrica',
    subtitle: 'Evapotranspiração, precipitação e demanda líquida para cálculo do turno de rega.',
    icon: AppIcons.projetoClima,
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldGrid(
          wide: wide,
          fields: [
            _Field(
              name: 'evapotranspiracaoMmDia',
              label: 'Evapotranspiração da cultura (ETc)',
              value: state.evapotranspiracaoMmDia,
              suffix: 'mm/dia',
            ),
            _Field(
              name: 'precipitacaoEfetivaMmDia',
              label: 'Precipitação efetiva (Pef)',
              value: state.precipitacaoEfetivaMmDia,
              suffix: 'mm/dia',
              allowZero: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LaminaRequeridaCard(resultado: state.laminaRequeridaResultado),
      ],
    ),
  );
}

class _LaminaRequeridaCard extends StatelessWidget {
  const _LaminaRequeridaCard({required this.resultado});

  final LaminaRequeridaResultado? resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final res = resultado;
    if (res == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Informe uma demanda líquida positiva e dados válidos do solo para calcular a IRN.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Lâmina requerida (IRN): ${res.irnMm.toStringAsFixed(1)} mm\n'
        'Demanda líquida: ${res.demandaLiquidaMmDia.toStringAsFixed(1)} mm/dia\n'
        'Turno de rega: ${res.turnoCalculadoDias.toStringAsFixed(1)} dias '
        '(operacional: ${res.turnoOperacionalDias} dias)',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

// ──────────────────────── Step 5: Origem do avanço ────────────────────────

class _OrigemAvancoStep extends ConsumerWidget {
  const _OrigemAvancoStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _BentoCard(
    title: 'Origem do avanço',
    subtitle:
        'Escolha como a curva de avanço é obtida e informe os tempos medidos.',
    icon: AppIcons.curvaAvanco,
    accent: accent,
    child: state.metodo == MetodoIrrigacao.faixa
        ? Text(
            'Na irrigação por faixa, o avanço é estimado pela rugosidade de '
            'Manning (etapa Operação). Não há ensaio de avanço nesta etapa.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<OrigemAvanco>(
                segments: const [
                  ButtonSegment(
                    value: OrigemAvanco.estimativa,
                    label: Text('Estimativa'),
                    icon: Icon(AppIcons.curvaAvanco),
                  ),
                  ButtonSegment(
                    value: OrigemAvanco.ensaio,
                    label: Text('Ensaio de campo'),
                    icon: Icon(AppIcons.projetoEnsaio),
                  ),
                ],
                selected: {state.origemAvanco},
                onSelectionChanged: (origem) => ref
                    .read(parametersProvider.notifier)
                    .setOrigemAvanco(origem.first),
              ),
              const SizedBox(height: 16),
              _FieldGrid(
                wide: wide,
                fields: [
                  if (state.origemAvanco == OrigemAvanco.estimativa) ...[
                    _Field(
                      name: 'coeficienteAvancoK',
                      label: 'Coeficiente k da curva',
                      value: state.coeficienteAvancoK,
                      suffix: 'min/mᵇ',
                    ),
                    _Field(
                      name: 'expoenteAvancoB',
                      label: 'Expoente b da curva',
                      value: state.expoenteAvancoB,
                    ),
                    _Field(
                      name: 'distanciaReferenciaAvancoM',
                      label: 'Distância X alcançada pela frente',
                      value: state.distanciaReferenciaAvancoM,
                      suffix: 'm',
                    ),
                    CalculatedField(
                      label: 'Tempo Tx em X',
                      value:
                          state.coeficienteAvancoK *
                          math
                              .pow(
                                state.distanciaReferenciaAvancoM,
                                state.expoenteAvancoB,
                              )
                              .toDouble(),
                      suffix: 'min',
                    ),
                  ],
                ],
              ),
              if (state.origemAvanco == OrigemAvanco.ensaio) ...[
                const SizedBox(height: 12),
                SegmentedButton<MetodoCurvaAvanco>(
                  segments: const [
                    ButtonSegment(
                      value: MetodoCurvaAvanco.doisPontos,
                      label: Text('Dois pontos'),
                    ),
                    ButtonSegment(
                      value: MetodoCurvaAvanco.minimosQuadrados,
                      label: Text('Mínimos quadrados'),
                    ),
                  ],
                  selected: {state.metodoCurvaAvanco},
                  onSelectionChanged: (value) => ref
                      .read(parametersProvider.notifier)
                      .setMetodoCurvaAvanco(value.first),
                ),
                const SizedBox(height: 10),
                _PontosAvancoEditor(
                  pontos: state.pontosEnsaioAvanco,
                  comprimentoM: state.comprimento,
                  metodo: state.metodoCurvaAvanco,
                  onChanged: ref
                      .read(parametersProvider.notifier)
                      .setPontosEnsaioAvanco,
                ),
              ],
              if (state.metodo == MetodoIrrigacao.sulco) ...[
                const SizedBox(height: 12),
                SegmentedButton<HipoteseRecessao>(
                  segments: const [
                    ButtonSegment(
                      value: HipoteseRecessao.desprezada,
                      label: Text('Recessão desprezada'),
                    ),
                    ButtonSegment(
                      value: HipoteseRecessao.medidaPorEstaca,
                      label: Text('Recessão medida'),
                    ),
                  ],
                  selected: {state.hipoteseRecessao},
                  onSelectionChanged: (value) => ref
                      .read(parametersProvider.notifier)
                      .setHipoteseRecessao(value.first),
                ),
                if (state.hipoteseRecessao == HipoteseRecessao.desprezada)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Hipótese simplificada: depleção e recessão desprezadas; '
                      'To(x) = Tc − Tx(x).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (state.hipoteseRecessao ==
                    HipoteseRecessao.medidaPorEstaca) ...[
                  const SizedBox(height: 10),
                  _RecessaoEditor(
                    pontos: state.medicoesRecessao,
                    onChanged: ref
                        .read(parametersProvider.notifier)
                        .setMedicoesRecessao,
                  ),
                  Text(
                    'Informe instantes absolutos desde o início da aplicação. '
                    'A depleção é desprezada. A curva será interpolada entre '
                    'estacas e oportunidades negativas serão rejeitadas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ],
          ),
  );
}

class _PontosAvancoEditor extends StatefulWidget {
  const _PontosAvancoEditor({
    required this.pontos,
    required this.comprimentoM,
    required this.metodo,
    required this.onChanged,
  });

  final List<PontoEnsaio> pontos;
  final double comprimentoM;
  final MetodoCurvaAvanco metodo;
  final ValueChanged<List<PontoEnsaio>> onChanged;

  @override
  State<_PontosAvancoEditor> createState() => _PontosAvancoEditorState();
}

class _PontosAvancoEditorState extends State<_PontosAvancoEditor> {
  late final TextEditingController _countController;
  late final TextEditingController _spacingController;
  late final TextEditingController _timesController;

  List<PontoEnsaio> get _positivePoints => widget.pontos
      .where((point) => point.distanciaM > 0 && point.tempoMin > 0)
      .toList();

  @override
  void initState() {
    super.initState();
    final measured = _positivePoints;
    final count = measured.isEmpty ? 10 : measured.length;
    final interval = measured.length >= 2
        ? measured[1].distanciaM - measured[0].distanciaM
        : widget.comprimentoM / count;
    _countController = TextEditingController(text: '$count');
    _spacingController = TextEditingController(
      text: interval.toStringAsFixed(2),
    );
    _timesController = TextEditingController(
      text: measured.map((point) => point.tempoMin).join('\n'),
    );
  }

  void _emit() {
    final count = int.tryParse(_countController.text.trim());
    final spacing = double.tryParse(
      _spacingController.text.trim().replaceAll(',', '.'),
    );
    if (count == null ||
        count <= 0 ||
        count > 500 ||
        spacing == null ||
        !spacing.isFinite ||
        spacing <= 0) {
      widget.onChanged(const []);
      return;
    }
    final times = _timesController.text
        .split('\n')
        .where((item) => item.trim().isNotEmpty)
        .map((item) => double.tryParse(item.trim().replaceAll(',', '.')))
        .toList();
    final points = <PontoEnsaio>[const PontoEnsaio(distanciaM: 0, tempoMin: 0)];
    for (var index = 0; index < count && index < times.length; index++) {
      final time = times[index];
      if (time == null) continue;
      points.add(
        PontoEnsaio(distanciaM: (index + 1) * spacing, tempoMin: time),
      );
    }
    widget.onChanged(points);
  }

  @override
  void dispose() {
    _countController.dispose();
    _spacingController.dispose();
    _timesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FieldGrid(
        wide: MediaQuery.sizeOf(context).width >= 700,
        fields: [
          TextFormField(
            controller: _countController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Número de estacas medidas',
              suffixText: 'estacas',
            ),
          ),
          TextFormField(
            controller: _spacingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Distância entre estacas',
              suffixText: 'm',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _timesController,
        minLines: 3,
        maxLines: 9,
        keyboardType: TextInputType.multiline,
        onChanged: (_) => _emit(),
        decoration: InputDecoration(
          labelText: 'Tempo de avanço de cada estaca (${widget.metodo.name})',
          hintText: '20\n43\n68\n95',
          helperText: 'Um tempo (min) por linha, na ordem das estacas. As distâncias são geradas pelo espaçamento informado; a origem (0, 0) é acrescentada automaticamente.',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        widget.metodo == MetodoCurvaAvanco.doisPontos
            ? 'Usa o último tempo medido e o tempo na metade do ensaio. Se não houver estaca exatamente no meio, o tempo intermediário é interpolado entre as estacas vizinhas.'
            : 'A regressão log-log usa todas as estacas com distância e tempo positivos; a origem é preservada nos dados, mas excluída dos logaritmos.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _EntradaSaidaEditor extends StatefulWidget {
  const _EntradaSaidaEditor({required this.pontos, required this.onChanged});
  final List<MedicaoEntradaSaida> pontos;
  final ValueChanged<List<MedicaoEntradaSaida>> onChanged;

  @override
  State<_EntradaSaidaEditor> createState() => _EntradaSaidaEditorState();
}

class _EntradaSaidaEditorState extends State<_EntradaSaidaEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.pontos
          .map((p) => '${p.tempoMin}; ${p.vazaoEntradaLs}; ${p.vazaoSaidaLs}')
          .join('\n'),
    );
  }

  void _parse(String value) {
    final observations = <MedicaoEntradaSaida>[];
    for (final line in value.split('\n')) {
      final cells = line.split(';').map((cell) => cell.trim()).toList();
      if (cells.length != 3) continue;
      final values = cells
          .map((cell) => double.tryParse(cell.replaceAll(',', '.')))
          .toList();
      if (values.any((value) => value == null)) continue;
      observations.add(
        MedicaoEntradaSaida(
          tempoMin: values[0]!,
          vazaoEntradaLs: values[1]!,
          vazaoSaidaLs: values[2]!,
        ),
      );
    }
    widget.onChanged(observations);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    minLines: 3,
    maxLines: 9,
    keyboardType: TextInputType.multiline,
    onChanged: _parse,
    decoration: const InputDecoration(
      labelText: 'Tempo (min); Qentrada do trecho (L/s); Qsaída (L/s)',
      hintText: '0; 1,2; 0,2\n10; 1,2; 0,35\n20; 1,2; 0,5',
      helperText:
          'Uma observação por linha, com vazões totais do trecho ensaiado. '
          'Use ponto e vírgula entre colunas. '
          'O instante zero pode ser incluído e não entra nos logaritmos.',
      border: OutlineInputBorder(),
    ),
  );
}

class _RecessaoEditor extends StatefulWidget {
  const _RecessaoEditor({required this.pontos, required this.onChanged});
  final List<MedicaoRecessao> pontos;
  final ValueChanged<List<MedicaoRecessao>> onChanged;

  @override
  State<_RecessaoEditor> createState() => _RecessaoEditorState();
}

class _RecessaoEditorState extends State<_RecessaoEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.pontos
          .map((p) => '${p.distanciaM}; ${p.instanteRecessaoMin}')
          .join('\n'),
    );
  }

  void _parse(String value) {
    final observations = <MedicaoRecessao>[];
    for (final line in value.split('\n')) {
      final cells = line.split(';').map((cell) => cell.trim()).toList();
      if (cells.length != 2) continue;
      final distance = double.tryParse(cells[0].replaceAll(',', '.'));
      final instant = double.tryParse(cells[1].replaceAll(',', '.'));
      if (distance == null || instant == null) continue;
      observations.add(
        MedicaoRecessao(distanciaM: distance, instanteRecessaoMin: instant),
      );
    }
    widget.onChanged(observations);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    minLines: 2,
    maxLines: 8,
    keyboardType: TextInputType.multiline,
    onChanged: _parse,
    decoration: const InputDecoration(
      labelText: 'Recessão por estaca: distância (m); instante (min)',
      hintText: '0; 210\n50; 225\n100; 240\n200; 270',
      helperText:
          'Inclua as estacas de 0 m e do final do sulco; instantes desde '
          'o início da aplicação.',
      border: OutlineInputBorder(),
    ),
  );
}

// ──────────────────────── Step 6: Operação ────────────────────────

class _OperacaoStep extends ConsumerWidget {
  const _OperacaoStep({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.metodo == MetodoIrrigacao.sulco) ...[
        _BentoCard(
          title: 'Manejo da aplicação',
          subtitle:
              'Escolha o tipo de manejo antes de configurar os parâmetros.',
          icon: AppIcons.projetoOperacao,
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ManejoSulco>(
                segments: ManejoSulco.values
                    .map(
                      (m) =>
                          ButtonSegment(value: m, label: Text(m.displayName)),
                    )
                    .toList(),
                selected: {state.manejoSulco},
                onSelectionChanged: (value) => ref
                    .read(parametersProvider.notifier)
                    .setManejoSulco(value.first),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors(context).surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  state.manejoSulco.descricao,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      _BentoCard(
        title: state.metodo == MetodoIrrigacao.sulco
            ? 'Parâmetros do manejo'
            : 'Manejo da aplicação',
        subtitle:
            'Dados operacionais para calcular desempenho e balanço hídrico.',
        icon: AppIcons.projetoOperacao,
        accent: accent,
        child: _FieldGrid(
          wide: wide,
          fields: [
            if (state.metodo == MetodoIrrigacao.sulco) ...[
              CalculatedField(
                label: 'Vazão por sulco',
                value: state.vazao,
                suffix: 'L/s',
              ),
              _Field(
                name: 'tempoAplicacao',
                label: 'Tempo de oportunidade no final',
                value: state.tempoAplicacao,
                suffix: 'min',
              ),
            ] else ...[
              _Field(
                name: 'vazao',
                label: state.metodo == MetodoIrrigacao.faixa
                    ? 'Vazão unitária'
                    : 'Vazão total',
                value: state.vazao,
                suffix: state.metodo == MetodoIrrigacao.faixa ? 'L/s/m' : 'L/s',
              ),
              _Field(
                name: 'tempoAplicacao',
                label: 'Tempo de aplicação',
                value: state.tempoAplicacao,
                suffix: 'min',
              ),
            ],
            if (state.metodo == MetodoIrrigacao.sulco &&
                state.manejoSulco == ManejoSulco.reduzida) ...[
              _Field(
                name: 'vazaoReduzidaLs',
                label: 'Vazão reduzida (após avanço)',
                value: state.vazaoReduzidaLs,
                suffix: 'L/s',
                allowZero: true,
              ),
              _Field(
                name: 'tempoMudancaMin',
                label: 'Atraso para redução após avanço',
                value: state.tempoMudancaMin,
                suffix: 'min',
                allowZero: true,
              ),
            ],
            if (state.metodo == MetodoIrrigacao.sulco &&
                state.manejoSulco == ManejoSulco.surtir) ...[
              _Field(
                name: 'cicloSurtirMin',
                label: 'Duração do ciclo (aplicação)',
                value: state.cicloSurtirMin,
                suffix: 'min',
              ),
              _Field(
                name: 'tempoMudancaMin',
                label: 'Duração da pausa',
                value: state.tempoMudancaMin,
                suffix: 'min',
                allowZero: true,
              ),
            ],
            if (state.metodo == MetodoIrrigacao.sulco) ...[
              _Field(
                name: 'periodoIrrigacaoDias',
                label: 'Período de irrigação adotado',
                value: state.periodoIrrigacaoDias.toDouble(),
                suffix: 'dias',
              ),
              _Field(
                name: 'tempoMudancaParcelaMin',
                label: 'Tempo entre parcelas',
                value: state.tempoMudancaParcelaMin,
                suffix: 'min',
                allowZero: true,
              ),
              _Field(
                name: 'jornadaDiariaH',
                label: 'Jornada diária disponível',
                value: state.jornadaDiariaH,
                suffix: 'h',
              ),
              _Field(
                name: 'perdasConducaoLs',
                label: 'Perdas de condução',
                value: state.perdasConducaoLs,
                suffix: 'L/s',
                allowZero: true,
              ),
              _Field(
                name: 'vazaoDisponivelLps',
                label: 'Vazão disponível na fonte',
                value: state.vazaoDisponivelLps,
                suffix: 'L/s',
              ),
            ],
            if (state.metodo == MetodoIrrigacao.faixa) ...[
              _Field(
                name: 'manningN',
                label: 'Rugosidade de Manning',
                value: state.manningN,
              ),
              _Field(
                name: 'sigmaZ',
                label: 'r inicial para avanço',
                value: state.sigmaZ,
                helper: 'Valor atribuído antes da iteração',
              ),
            ],
          ],
        ),
      ),
    ],
  );

  ColorScheme colors(BuildContext context) => Theme.of(context).colorScheme;
}

// ──────────────────────── Step 7: Revisão ────────────────────────

class _RevisaoStep extends StatelessWidget {
  const _RevisaoStep({required this.state, required this.accent});
  final ParametersState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: .72)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  AppIcons.projetoRevisao,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisão antes de calcular',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifique os dados antes de executar o dimensionamento.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white.withValues(alpha: .9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(section.icon, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 160,
                            child: Text(
                              '${row.label}:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<_ReviewSection> _buildSections(ParametersState state) {
    final lamina = state.laminaRequeridaResultado;
    return [
      _ReviewSection(
        icon: AppIcons.projetoArea,
        title: 'Geometria',
        rows: [
          _ReviewRow('Método', state.metodo.displayName),
          if (state.tipoSulco != null)
            _ReviewRow('Tipo de sulco', state.tipoSulco!.displayName),
          _ReviewRow(
            'Comprimento',
            '${state.comprimento.toStringAsFixed(0)} m',
          ),
          _ReviewRow(
            state.metodo == MetodoIrrigacao.sulco ? 'Espaçamento' : 'Largura',
            '${state.larguraOuEspacamento.toStringAsFixed(2)} m',
          ),
          if (state.metodo == MetodoIrrigacao.sulco)
            _ReviewRow(
              'Limite do terreno',
              '${state.comprimentoMaximoTerrenoM.toStringAsFixed(0)} m',
            ),
          _ReviewRow(
            'Declividade',
            '${state.declividade.toStringAsFixed(4)} m/m '
                '(${(state.declividade * 100).toStringAsFixed(2)}%)',
          ),
          if (state.metodo != MetodoIrrigacao.sulco) ...[
            _ReviewRow(
              'Desnível transversal',
              '${state.desnivelTransversalM.toStringAsFixed(2)} m em '
                  '${state.distanciaTransversalM.toStringAsFixed(0)} m',
            ),
            _ReviewRow(
              'Declividade transversal',
              '${state.declividadeTransversal.toStringAsFixed(4)} m/m '
                  '(${(state.declividadeTransversal * 100).toStringAsFixed(2)}%)',
            ),
          ],
          if (state.metodo == MetodoIrrigacao.sulco) ...[
            _ReviewRow(
              'Largura superior do sulco',
              state.larguraSulcoM == null
                  ? 'Não informada (opcional)'
                  : '${state.larguraSulcoM!.toStringAsFixed(2)} m',
            ),
            _ReviewRow(
              'Profundidade do sulco',
              state.profundidadeSulcoM == null
                  ? 'Não informada (opcional)'
                  : '${state.profundidadeSulcoM!.toStringAsFixed(2)} m',
            ),
          ],
          _ReviewRow(
            'Desnível longitudinal',
            '${state.desnivelM.toStringAsFixed(2)} m em '
                '${state.distanciaHorizontalM.toStringAsFixed(0)} m',
          ),
        ],
      ),
      _ReviewSection(
        icon: Icons.landscape_rounded,
        title: 'Solo',
        rows: [
          if (state.metodo == MetodoIrrigacao.sulco)
            _ReviewRow('Textura', state.texturaSolo.displayName),
          _ReviewRow(
            'Umidade na capacidade de campo (UCC)',
            '${state.uccPercentual.toStringAsFixed(1)}%',
          ),
          _ReviewRow(
            'Umidade no ponto de murcha (UPMP)',
            '${state.upmpPercentual.toStringAsFixed(1)}%',
          ),
          _ReviewRow(
            'Densidade aparente',
            '${state.densidadeAparenteGcm3.toStringAsFixed(2)} g/cm³',
          ),
        ],
      ),
      _ReviewSection(
        icon: AppIcons.projetoSolo,
        title: 'Infiltração',
        rows: [
          _ReviewRow(
            state.metodo == MetodoIrrigacao.sulco
                ? 'Coeficiente aI'
                : 'Coeficiente k',
            '${state.k} ${state.metodo == MetodoIrrigacao.sulco ? "mm/minⁿ" : "m/minᵃ"}',
          ),
          _ReviewRow(
            state.metodo == MetodoIrrigacao.sulco ? 'Expoente n' : 'Expoente a',
            state.a.toString(),
          ),
          if (state.metodo != MetodoIrrigacao.sulco)
            _ReviewRow('Infiltração básica (VIB)', '${state.vib} m/min'),
        ],
      ),
      _ReviewSection(
        icon: AppIcons.projetoClima,
        title: 'Clima e demanda',
        rows: [
          _ReviewRow(
            'Evapotranspiração (ETc)',
            '${state.evapotranspiracaoMmDia.toStringAsFixed(1)} mm/dia',
          ),
          _ReviewRow(
            'Precipitação efetiva (Pef)',
            '${state.precipitacaoEfetivaMmDia.toStringAsFixed(1)} mm/dia',
          ),
          _ReviewRow(
            'Lâmina requerida',
            '${state.laminaRequerida.toStringAsFixed(1)} mm',
          ),
          if (lamina != null) ...[
            _ReviewRow(
              'Demanda líquida',
              '${lamina.demandaLiquidaMmDia.toStringAsFixed(1)} mm/dia',
            ),
            _ReviewRow(
              'Turno de rega calculado',
              '${lamina.turnoCalculadoDias.toStringAsFixed(1)} dias',
            ),
            _ReviewRow(
              'Turno operacional',
              '${lamina.turnoOperacionalDias} dia(s)',
            ),
          ],
        ],
      ),
      if (state.nomeCultura.isNotEmpty || state.kc != 1.0)
        _ReviewSection(
          icon: AppIcons.projetoCultura,
          title: 'Cultura',
          rows: [
            if (state.nomeCultura.isNotEmpty)
              _ReviewRow('Cultura', state.nomeCultura),
            _ReviewRow('Kc', state.kc.toStringAsFixed(2)),
            _ReviewRow(
              'Espaç. fileiras',
              '${state.espacamentoFileirasM.toStringAsFixed(2)} m',
            ),
            _ReviewRow(
              'Espaç. plantas',
              '${state.espacamentoPlantasM.toStringAsFixed(2)} m',
            ),
            _ReviewRow(
              'Profund. raízes',
              '${state.profundidadeRaizesCm.toStringAsFixed(0)} cm',
            ),
            _ReviewRow(
              'Fração água disp.',
              state.fracaoAguaDisponivel.toStringAsFixed(2),
            ),
          ],
        ),
      if (state.metodo != MetodoIrrigacao.faixa)
        _ReviewSection(
          icon: AppIcons.curvaAvanco,
          title: 'Origem do avanço',
          rows: [
            _ReviewRow(
              'Origem',
              state.origemAvanco == OrigemAvanco.ensaio
                  ? 'Ensaio de campo'
                  : 'Estimativa',
            ),
            if (state.origemAvanco == OrigemAvanco.estimativa) ...[
              _ReviewRow(
                'Equação informada',
                'Tx = ${state.coeficienteAvancoK.toStringAsPrecision(6)} · '
                    'x^${state.expoenteAvancoB.toStringAsFixed(5)}',
              ),
              _ReviewRow(
                'Distância X de referência',
                '${state.distanciaReferenciaAvancoM.toStringAsFixed(2)} m',
              ),
              _ReviewRow(
                'Tempo Tx calculado em X',
                '${(state.coeficienteAvancoK * math.pow(state.distanciaReferenciaAvancoM, state.expoenteAvancoB)).toStringAsFixed(2)} min',
              ),
            ] else ...[
              _ReviewRow(
                'Método de ajuste',
                state.metodoCurvaAvanco == MetodoCurvaAvanco.doisPontos
                    ? 'Dois pontos com interpolação do meio'
                    : 'Mínimos quadrados log-log',
              ),
              for (final (index, point) in state.pontosEnsaioAvanco.indexed)
                _ReviewRow(
                  'Estaca ${index + 1}',
                  '${point.distanciaM.toStringAsFixed(2)} m · '
                      '${point.tempoMin.toStringAsFixed(2)} min',
                ),
            ],
            if (state.metodo == MetodoIrrigacao.sulco)
              _ReviewRow(
                'Hipótese de recessão',
                state.hipoteseRecessao == HipoteseRecessao.desprezada
                    ? 'Recessão e depleção desprezadas'
                    : 'Curva de recessão informada por estaca',
              ),
          ],
        ),
      if (state.metodo == MetodoIrrigacao.inundacao)
        _ReviewSection(
          icon: AppIcons.inundacao,
          title: 'Inundação',
          rows: [
            _ReviewRow('Regime', state.tipoInundacao.displayName),
            if (state.tipoInundacao == TipoInundacao.permanente) ...[
              _ReviewRow(
                'Área irrigada',
                '${state.areaHectares.toStringAsFixed(2)} ha',
              ),
              _ReviewRow('Porosidade', state.porosidade.toStringAsFixed(2)),
              _ReviewRow(
                'Profundidade da camada',
                '${state.profundidadeCamadaMm.toStringAsFixed(0)} mm',
              ),
              _ReviewRow(
                'Condutividade hidráulica K₀',
                '${state.condutividadeHidraulicaMmDia.toStringAsFixed(1)} mm/dia',
              ),
              _ReviewRow(
                'Disponibilidade total de água',
                '${state.dtaMmCm.toStringAsFixed(1)} mm/cm',
              ),
              _ReviewRow(
                'Fator de disponibilidade',
                state.fatorDisponibilidade.toStringAsFixed(2),
              ),
              _ReviewRow(
                'Lâmina superficial',
                '${state.laminaSuperficialMm.toStringAsFixed(0)} mm',
              ),
              _ReviewRow(
                'Vazão disponível',
                '${state.vazaoDisponivelLps.toStringAsFixed(1)} L/s',
              ),
            ],
          ],
        ),
      _ReviewSection(
        icon: AppIcons.projetoOperacao,
        title: 'Operação',
        rows: [
          if (state.metodo == MetodoIrrigacao.sulco) ...[
            _ReviewRow(
              'Área efetiva',
              '${state.areaHectares.toStringAsFixed(2)} ha',
            ),
            _ReviewRow(
              'Período de irrigação',
              '${state.periodoIrrigacaoDias} dias',
            ),
            _ReviewRow(
              'Tempo entre parcelas',
              '${state.tempoMudancaParcelaMin.toStringAsFixed(0)} min',
            ),
          ],
          if (state.metodo == MetodoIrrigacao.sulco)
            _ReviewRow('Manejo', state.manejoSulco.displayName),
          _ReviewRow(
            state.metodo == MetodoIrrigacao.faixa
                ? 'Vazão unitária'
                : state.metodo == MetodoIrrigacao.inundacao
                ? 'Vazão total'
                : 'Vazão por sulco',
            '${state.vazao.toStringAsFixed(2)} '
            '${state.metodo == MetodoIrrigacao.faixa ? 'L/s/m' : 'L/s'}',
          ),
          _ReviewRow(
            state.metodo == MetodoIrrigacao.sulco
                ? 'Tempo de oportunidade no final'
                : 'Tempo de aplicação',
            '${state.tempoAplicacao.toStringAsFixed(0)} min',
          ),
          if (state.metodo == MetodoIrrigacao.faixa) ...[
            _ReviewRow(
              'Rugosidade de Manning',
              state.manningN.toStringAsFixed(3),
            ),
            _ReviewRow(
              'r inicial para avanço',
              state.sigmaZ.toStringAsFixed(2),
            ),
          ],
          if (state.metodo == MetodoIrrigacao.sulco &&
              state.manejoSulco == ManejoSulco.reduzida) ...[
            _ReviewRow(
              'Vazão reduzida',
              '${state.vazaoReduzidaLs.toStringAsFixed(2)} L/s',
            ),
            _ReviewRow(
              'Atraso para redução',
              '${state.tempoMudancaMin.toStringAsFixed(0)} min',
            ),
          ],
          if (state.metodo == MetodoIrrigacao.sulco &&
              state.manejoSulco == ManejoSulco.surtir) ...[
            _ReviewRow(
              'Duração do ciclo',
              '${state.cicloSurtirMin.toStringAsFixed(0)} min',
            ),
            _ReviewRow(
              'Duração da pausa',
              '${state.tempoMudancaMin.toStringAsFixed(0)} min',
            ),
          ],
          if (state.metodo == MetodoIrrigacao.sulco) ...[
            _ReviewRow(
              'Jornada diária',
              '${state.jornadaDiariaH.toStringAsFixed(1)} h',
            ),
            _ReviewRow(
              'Vazão disponível',
              '${state.vazaoDisponivelLps.toStringAsFixed(2)} L/s',
            ),
            _ReviewRow(
              'Perdas de condução',
              '${state.perdasConducaoLs.toStringAsFixed(2)} L/s',
            ),
          ],
        ],
      ),
    ];
  }
}

class _ReviewSection {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.rows,
  });
  final IconData icon;
  final String title;
  final List<_ReviewRow> rows;
}

class _ReviewRow {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
}

// ──────────────────────── Tipo Sulco Info ────────────────────────

class _TipoSulcoInfoCard extends StatelessWidget {
  const _TipoSulcoInfoCard({required this.tipo});
  final TipoSulco tipo;

  @override
  Widget build(BuildContext context) {
    final info = TipoSulcoInfo.getInfo(tipo);
    final accent = AppColors.sulco;

    return _BentoCard(
      title: info.tipo.displayName,
      subtitle: info.tipo.descricao,
      icon: Icons.info_outline_rounded,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Alinhamento', value: info.alinhamento),
          _InfoRow(label: 'Formas', value: info.formas.join(', ')),
          _InfoRow(label: 'Comprimento', value: info.comprimentoFaixa),
          _InfoRow(
            label: 'Declividade ideal',
            value: info.declividade.faixaIdealLabel,
          ),
          if (info.declividade.aconselhavelMax != null)
            _InfoRow(
              label: 'Declividade aconselhável',
              value: info.declividade.faixaAconselhavelLabel,
            ),
          if (info.declividade.usavelMax != null)
            _InfoRow(
              label: 'Declividade usável',
              value: info.declividade.faixaUsavelLabel,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Slope Summary ────────────────────────

class _SlopeSummaryCard extends StatelessWidget {
  const _SlopeSummaryCard({required this.state});
  final ParametersState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final slopePercent = state.declividade * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _slopeItem(
            context,
            'Declividade longitudinal',
            '${state.declividade.toStringAsFixed(4)} m/m',
            detail: '${slopePercent.toStringAsFixed(2)}%',
          ),
          if (state.metodo != MetodoIrrigacao.sulco)
            _slopeItem(
              context,
              'Declividade transversal',
              '${state.declividadeTransversal.toStringAsFixed(4)} m/m',
              detail:
                  '${(state.declividadeTransversal * 100).toStringAsFixed(2)}%',
            ),
          _slopeItem(
            context,
            'Desnível total',
            '${state.desnivelM.toStringAsFixed(2)} m em ${state.distanciaHorizontalM.toStringAsFixed(0)} m',
          ),
        ],
      ),
    );
  }

  Widget _slopeItem(
    BuildContext context,
    String label,
    String value, {
    String? detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
      ],
    );
  }
}

// ──────────────────────── Helpers ────────────────────────

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

Color _methodColor(MetodoIrrigacao method) => switch (method) {
  MetodoIrrigacao.sulco => AppColors.sulco,
  MetodoIrrigacao.faixa => AppColors.faixa,
  MetodoIrrigacao.inundacao => AppColors.inundacao,
};
