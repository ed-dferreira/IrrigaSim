import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';
import 'package:irrigasim/services/simulation/faixas/border_reference_tables.dart';
import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';

class BorderProjectScreen extends ConsumerStatefulWidget {
  const BorderProjectScreen({super.key});

  @override
  ConsumerState<BorderProjectScreen> createState() =>
      _BorderProjectScreenState();
}

class _BorderInput extends StatelessWidget {
  const _BorderInput({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _BorderStepIndicator extends StatefulWidget {
  const _BorderStepIndicator({
    required this.titles,
    required this.icons,
    required this.currentStep,
    required this.confirmedSteps,
    required this.onTap,
  });

  final List<String> titles;
  final List<IconData> icons;
  final int currentStep;
  final Set<int> confirmedSteps;
  final ValueChanged<int> onTap;

  @override
  State<_BorderStepIndicator> createState() => _BorderStepIndicatorState();
}

class _BorderStepIndicatorState extends State<_BorderStepIndicator> {
  final _controller = ScrollController();
  late final _keys = List.generate(widget.titles.length, (_) => GlobalKey());
  bool _back = false;
  bool _forward = false;

  void _updateArrows() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final back = position.pixels > position.minScrollExtent;
    final forward = position.pixels < position.maxScrollExtent;
    if (back != _back || forward != _forward) {
      setState(() {
        _back = back;
        _forward = forward;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
  }

  @override
  void didUpdateWidget(covariant _BorderStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _keys[widget.currentStep].currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  void _scroll(int direction) {
    final position = _controller.position;
    _controller.animateTo(
      (position.pixels + direction * position.viewportDimension * .7).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final arrows = MediaQuery.sizeOf(context).width >= 760;
    return Row(
      children: [
        if (arrows)
          IconButton(
            tooltip: 'Ver etapas anteriores',
            onPressed: _back ? () => _scroll(-1) : null,
            icon: const Icon(AppIcons.etapasAnteriores),
          ),
        Expanded(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _updateArrows();
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
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.titles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _step(context, colors, i),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (arrows)
          IconButton(
            tooltip: 'Ver próximas etapas',
            onPressed: _forward ? () => _scroll(1) : null,
            icon: const Icon(AppIcons.etapasSeguintes),
          ),
      ],
    );
  }

  Widget _step(BuildContext context, ColorScheme colors, int index) {
    final active = index == widget.currentStep;
    final completed = widget.confirmedSteps.contains(index);
    final accent = AppColors.faixa;
    return Semantics(
      key: _keys[index],
      button: true,
      selected: active,
      label:
          '${completed
              ? 'Preenchida: '
              : active
              ? 'Etapa atual: '
              : ''}${widget.titles[index]}',
      child: InkWell(
        onTap: () => widget.onTap(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: .12)
                : completed
                ? colors.primaryContainer
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? accent
                  : completed
                  ? colors.primary
                  : colors.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed ? AppIcons.sucesso : widget.icons[index],
                size: 18,
                color: active
                    ? accent
                    : completed
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${index + 1}. ${widget.titles[index]}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active
                      ? accent
                      : completed
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorderProjectScreenState extends ConsumerState<BorderProjectScreen> {
  static const _titles = [
    'Área e geometria',
    'Dimensões da faixa',
    'Solo',
    'Cultura e raízes',
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
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  final Set<int> _confirmedSteps = {};
  bool _calculando = false;
  String? _erroEstacas;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(borderProjectProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Projeto de faixas')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Exemplo ilustrativo de faixa — ajuste às medidas do seu terreno.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _BorderStepIndicator(
                      titles: _titles,
                      icons: _icons,
                      currentStep: _step,
                      confirmedSteps: _confirmedSteps,
                      onTap: (index) => setState(() => _step = index),
                    ),
                    const SizedBox(height: 16),
                    Card(
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
                                Icon(_icons[_step], color: AppColors.faixa),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _titles[_step],
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Etapa ${_step + 1} de ${_titles.length}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            _layoutFields(_fields(project)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Tooltip(
                          message: 'Voltar para a etapa anterior',
                          child: OutlinedButton.icon(
                            onPressed: _step == 0
                                ? null
                                : () => setState(() => _step--),
                            icon: const Icon(AppIcons.etapasAnteriores),
                            label: const Text('Anterior'),
                          ),
                        ),
                        if (_step < 7)
                          _confirmedSteps.contains(_step)
                              ? Chip(
                                  avatar: const Icon(
                                    AppIcons.sucesso,
                                    size: 18,
                                  ),
                                  label: const Text('Confirmada'),
                                  backgroundColor: colors.primaryContainer,
                                  side: BorderSide.none,
                                )
                              : OutlinedButton.icon(
                                  onPressed: () {
                                    if ((_formKey.currentState?.validate() ??
                                            false) &&
                                        _erroEstacas == null) {
                                      setState(
                                        () => _confirmedSteps.add(_step),
                                      );
                                    }
                                  },
                                  icon: const Icon(AppIcons.sucesso),
                                  label: const Text('Confirmar etapa'),
                                ),
                        Tooltip(
                          message: _step == 7
                              ? 'Calcular a simulação da faixa'
                              : 'Avançar para a próxima etapa',
                          child: FilledButton.icon(
                            onPressed: _step == 7
                                ? project.impedimentoModelo != null ||
                                          _calculando ||
                                          !_titles
                                              .asMap()
                                              .keys
                                              .where((i) => i < 7)
                                              .every(_confirmedSteps.contains)
                                      ? null
                                      : () {
                                          setState(() => _calculando = true);
                                          try {
                                            final result = calcularProjetoFaixa(
                                              project,
                                            );
                                            ref
                                                    .read(
                                                      borderProjectResultProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                result;
                                            context.push(
                                              '/home/irrigation/border-results',
                                            );
                                          } on FormatException catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  SnackBar(
                                                    content: Text(e.message),
                                                  ),
                                                );
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _calculando = false,
                                              );
                                            }
                                          }
                                        }
                                : () => setState(() => _step++),
                            icon: _calculando
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _step == 7
                                        ? AppIcons.executarSimulacao
                                        : AppIcons.etapasSeguintes,
                                  ),
                            label: Text(
                              _calculando
                                  ? 'Calculando…'
                                  : _step == 7
                                  ? 'Calcular faixa'
                                  : 'Próxima etapa',
                            ),
                          ),
                        ),
                      ],
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

  Widget _layoutFields(List<Widget> fields) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final fieldWidth = width >= 650 ? (width - 12) / 2 : width;
      final output = <Widget>[];
      final group = <Widget>[];
      void flush() {
        if (group.isEmpty) return;
        output.add(
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final field in group)
                SizedBox(width: fieldWidth, child: field),
            ],
          ),
        );
        group.clear();
      }

      for (final field in fields) {
        if (field is _BorderInput) {
          group.add(field);
        } else {
          flush();
          output.add(
            Padding(padding: const EdgeInsets.only(bottom: 12), child: field),
          );
        }
      }
      flush();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: output,
      );
    },
  );

  List<Widget> _fields(BorderProject p) => switch (_step) {
    0 => [
      const Text(
        'Dados da gleba e levantamento topográfico. O declive longitudinal conduz o avanço; o transversal precisa ser pequeno para manter a lâmina distribuída na faixa (Aula 7, pp. 12–14).',
      ),
      _number(
        'comprimentoAreaM',
        'Comprimento da área',
        p.comprimentoAreaM,
        'm',
      ),
      _number('larguraAreaM', 'Largura da área', p.larguraAreaM, 'm'),
      _number(
        'desnivelLongitudinalM',
        'Desnível longitudinal',
        p.desnivelLongitudinalM,
        'm',
        zero: true,
      ),
      _number(
        'baseLongitudinalM',
        'Distância medida no sentido longitudinal',
        p.baseLongitudinalM,
        'm',
      ),
      _number(
        'desnivelTransversalM',
        'Desnível transversal',
        p.desnivelTransversalM,
        'm',
        zero: true,
      ),
      _number(
        'baseTransversalM',
        'Distância medida no sentido transversal',
        p.baseTransversalM,
        'm',
      ),
      IrrigationFormulaCard(
        formula:
            'S0 = ${_fmt(p.declividadeLongitudinal)} m/m · St = ${_fmt(p.declividadeTransversal)} m/m',
        description: 'Declividades longitudinal e transversal calculadas a partir do levantamento.',
      ),
    ],
    1 => [
      const Text(
        'Defina o comprimento e a largura das faixas dentro da gleba. Referências usuais: L de 50–400 m e W de 4–20 m (Aula 7, pp. 18–19).',
      ),
      _number('comprimentoM', 'Comprimento da faixa (L)', p.comprimentoM, 'm'),
      _number('larguraM', 'Largura da faixa (W)', p.larguraM, 'm'),
      _select<CondicaoJusanteFaixa>(
        'Condição de jusante',
        p.jusante,
        CondicaoJusanteFaixa.values,
        (v) => ref.read(borderProjectProvider.notifier).setJusante(v),
        (v) => v == CondicaoJusanteFaixa.aberta
            ? 'Aberta — escoamento livre'
            : 'Fechada — não simulável',
      ),
      _number(
        'alturaDiqueM',
        'Altura real do dique (opcional)',
        p.alturaDiqueM,
        'm',
        optional: true,
      ),
      _number(
        'laminaSuperficialM',
        'Lâmina superficial hn (opcional)',
        p.laminaSuperficialM,
        'm',
        optional: true,
      ),
    ],
    2 => [
      const Text(
        'A infiltração do solo controla o avanço e as perdas. Informe parâmetros medidos/estimados; a tabela Marr fornece sugestões geométricas e não substitui k, a ou VIB (Aula 7, pp. 11 e 20).',
      ),
      _select<CenarioInfiltracaoFaixa>(
        'Cenário de infiltração',
        p.cenarioInfiltracao,
        CenarioInfiltracaoFaixa.values,
        (v) =>
            ref.read(borderProjectProvider.notifier).setCenarioInfiltracao(v),
        (v) => switch (v) {
          CenarioInfiltracaoFaixa.primeira => 'Primeira irrigação',
          CenarioInfiltracaoFaixa.terceira => 'Terceira irrigação',
          CenarioInfiltracaoFaixa.informado => 'Outro / dados informados',
        },
      ),
      const Text(
        'O cenário identifica a origem; k, a e VIB devem ser informados para cada irrigação, sem misturar coeficientes.',
      ),
      _number('k', 'Coeficiente de infiltração k', p.k, 'm/minᵃ'),
      _number('a', 'Expoente a (entre 0 e 1)', p.a, ''),
      _number(
        'vibMMin',
        'Velocidade de infiltração básica (VIB)',
        p.vibMMin,
        'm/min',
        zero: true,
      ),
      _number(
        'uccPercentual',
        'Umidade na capacidade de campo UCC',
        p.agronomia?.uccPercentual,
        '%',
        optional: true,
      ),
      _number(
        'upmpPercentual',
        'Umidade no ponto de murcha UPMP',
        p.agronomia?.upmpPercentual,
        '%',
        optional: true,
      ),
      _number(
        'densidadeGcm3',
        'Densidade aparente do solo',
        p.agronomia?.densidadeGcm3,
        'g/cm³',
        optional: true,
      ),
      _select<CoberturaFaixa>(
        'Cobertura',
        p.cobertura,
        CoberturaFaixa.values,
        (v) => ref.read(borderProjectProvider.notifier).setCobertura(v),
        (v) => switch (v) {
          CoberturaFaixa.soloExposto => 'Solo exposto',
          CoberturaFaixa.culturaInstalada =>
            'Cultura instalada (cobertura parcial ou desconhecida)',
          CoberturaFaixa.coberturaTotal => 'Cobertura total informada',
        },
      ),
      _number('rugosidadeN', 'Rugosidade de Manning n', p.rugosidadeN, ''),
      _BorderInput(
        label: 'Textura para consulta Marr (opcional)',
        child: DropdownButtonFormField<TexturaSolo>(
          isExpanded: true,
          initialValue: p.textura,
          items: TexturaSolo.values
              .map(
                (v) => DropdownMenuItem(value: v, child: Text(v.displayName)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(borderProjectProvider.notifier).setTextura(v);
              setState(() => _confirmedSteps.remove(_step));
            }
          },
        ),
      ),
      if (p.textura != null) ...[
        for (final row in const BorderReferenceTables().suggest(
          p.textura!,
          (p.declividadeLongitudinal ?? 0) * 100,
        ))
          IrrigationFormulaCard(
            formula:
                'Marr · ${row.decliveMinPercent}–${row.decliveMaxPercent}% · q0 ${row.vazaoLsM} L/s/m',
            description:
                'Largura ${row.larguraM} m · L ${row.comprimentoM} m · lâmina ${row.laminaMm} mm. Sugestão: não fornece k/a/VIB.',
          ),
      ],
      ExpansionTile(
        title: const Text('Tabela Booher p.26 — sifões/tubos, consulta'),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          const IrrigationFormulaCard(
            formula: 'Diâmetro × carga → vazão',
            description: 'Diâmetro e carga em cm; vazões impressas em L/s. Células sob revisão não entram no dimensionamento automático.',
          ),
          for (final diameter in BorderReferenceTables.diametrosCm)
            IrrigationAuditRow(
              'Ø $diameter cm',
              [
                for (final load in BorderReferenceTables.cargasCm)
                  '${load}cm=${const BorderReferenceTables().booher(diameter, load)!.impressoLs}${const BorderReferenceTables().booher(diameter, load)!.revisaoPendente ? ' (sob revisão)' : ''}',
              ].join(' · '),
            ),
        ],
      ),
    ],
    3 => [
      const Text(
        'A cultura define a zona de extração de água. Profundidade radicular e fração disponível participam da lâmina real necessária; a cultura também informa a cobertura usada como hipótese hidráulica.',
      ),
      _BorderInput(
        label: 'Cultura (opcional)',
        child: TextFormField(
          initialValue: p.cultura,
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setCultura(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
      _number(
        'profundidadeRaizesCm',
        'Profundidade efetiva das raízes',
        p.agronomia?.profundidadeRaizesCm,
        'cm',
      ),
      _number(
        'fracaoDisponivel',
        'Fração disponível da água no solo',
        p.agronomia?.fracaoDisponivel,
        '',
      ),
    ],
    4 => [
      const Text(
        'A demanda da cultura e a precipitação efetiva definem a lâmina necessária. Use IRN informada ou calcule com os dados de solo e raízes (Aula 7, pp. 52 e 73).',
      ),
      _number(
        'evapotranspiracaoMmDia',
        'Evapotranspiração da cultura (ETc)',
        p.agronomia?.evapotranspiracaoMmDia,
        'mm/dia',
        optional: true,
      ),
      _number(
        'precipitacaoEfetivaMmDia',
        'Precipitação efetiva',
        p.agronomia?.precipitacaoEfetivaMmDia,
        'mm/dia',
        optional: true,
        zero: true,
      ),
      _select<OrigemIrnFaixa>(
        'Origem da IRN',
        p.origemIrn,
        OrigemIrnFaixa.values,
        (v) => ref.read(borderProjectProvider.notifier).setOrigemIrn(v),
        (v) => v == OrigemIrnFaixa.informada
            ? 'Informada'
            : 'Calculada a partir de solo, raízes e demanda climática',
      ),
      if (p.origemIrn == OrigemIrnFaixa.informada)
        _number('irnMm', 'Irrigação real necessária (IRN)', p.irnMm, 'mm')
      else
        IrrigationFormulaCard(
          formula: 'IRN calculada: ${_fmt(p.irnEfetivaMm)} mm',
          description: 'Lâmina necessária calculada com os dados de solo, raízes e demanda.',
        ),
    ],
    5 => [
      _select<ManejoFaixa>(
        'Manejo',
        p.manejo,
        ManejoFaixa.values,
        (v) => ref.read(borderProjectProvider.notifier).setManejo(v),
        (v) => switch (v) {
          ManejoFaixa.vazaoConstante => 'Vazão constante',
          ManejoFaixa.vazaoReduzida => 'Vazão reduzida — não simulável',
          ManejoFaixa.reuso => 'Reuso — não simulável',
        },
      ),
      _number(
        'vazaoUnitariaLsM',
        'Vazão unitária q0',
        p.vazaoUnitariaLsM,
        'L/s/m',
      ),
      _number('rInicial', 'Palpite inicial r', p.rInicial, '', optional: true),
      const Text(
        'O tempo de corte do dimensionamento é calculado. Para avaliar um ensaio medido, informe estacas; o corte abaixo só vale para esse ensaio.',
      ),
      TextFormField(
        key: const ValueKey('estacas'),
        initialValue: p.estacas
            .map(
              (s) =>
                  '${s.xM};${s.avancoMin}${s.recessaoMin == null ? '' : ';${s.recessaoMin}'}',
            )
            .join('\n'),
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Estacas medidas (opcional)',
          helperText: 'Uma por linha: distância m; avanço min; recessão min (opcional). Inclua 0;0.',
          errorText: _erroEstacas,
        ),
        onChanged: (value) {
          try {
            final stakes = value.trim().isEmpty
                ? <BorderStake>[]
                : value.trim().split('\n').map((line) {
                    final parts = line
                        .split(';')
                        .map((v) => double.parse(v.trim().replaceAll(',', '.')))
                        .toList();
                    if (parts.length < 2 || parts.length > 3) {
                      throw const FormatException(
                        'Use x; avanço; recessão (opcional).',
                      );
                    }
                    return BorderStake(
                      parts[0],
                      parts[1],
                      recessaoMin: parts.length == 3 ? parts[2] : null,
                    );
                  }).toList();
            ref.read(borderProjectProvider.notifier).setEstacas(stakes);
            setState(() {
              _erroEstacas = null;
              _confirmedSteps.remove(_step);
            });
          } on FormatException {
            setState(
              () => _erroEstacas =
                  'Revise as estacas: use x; avanço; recessão (opcional).',
            );
          }
        },
      ),
      _number(
        'corteEnsaioMin',
        'Instante de corte medido (opcional)',
        p.corteEnsaioMin,
        'min',
        optional: true,
      ),
      OutlinedButton.icon(
        onPressed: p.estacas.isEmpty || _erroEstacas != null
            ? null
            : () {
                try {
                  ref
                      .read(borderTrialProvider.notifier)
                      .state = const BorderFieldTrial().evaluate(
                    p,
                    p.estacas,
                    cutoffMin: p.corteEnsaioMin,
                  );
                } on FormatException catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
        icon: const Icon(AppIcons.projetoEnsaio),
        label: const Text('Avaliar ensaio medido'),
      ),
      if (ref.watch(borderTrialProvider) case final trial?) ...[
        Text(
          'Avanço medido ajustado: p=${_fmt(trial.advance.p)} m/minʳ, r=${_fmt(trial.advance.r)}, erro=${_fmt(trial.advance.rmseMin)} min',
        ),
        Text(
          trial.profile.isEmpty
              ? 'Recessão medida ausente: só o ajuste de avanço está disponível.'
              : 'Perfil interpolado em ${trial.profile.length} posições. '
                    'Er: ${_fmt(100 * trial.utilM3M! / (p.irnEfetivaMm! / 1000 * p.comprimentoM!))}%'
                    '${trial.ea == null ? '; Ea, Pp e Pe pendentes de corte e q0 do ensaio.' : '; Ea: ${_fmt(trial.ea)}%, Pp: ${_fmt(100 * trial.percoladoM3M! / trial.entradaM3M!)}%, Pe: ${_fmt(100 * trial.escoadoM3M! / trial.entradaM3M!)}%.'}',
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: borderTrialCsv(p, trial)),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV do ensaio copiado.')),
              );
            }
          },
          icon: const Icon(AppIcons.exportarDados),
          label: const Text('Copiar CSV do ensaio'),
        ),
      ],
    ],
    6 => [
      _number(
        'vazaoDisponivelLs',
        'Oferta de água (opcional)',
        p.vazaoDisponivelLs,
        'L/s',
        optional: true,
      ),
      _number(
        'periodoDias',
        'Período de irrigação PI (opcional)',
        p.periodoDias?.toDouble(),
        'dias',
        optional: true,
      ),
      _number(
        'jornadaHoras',
        'Jornada TDF (opcional)',
        p.jornadaHoras,
        'h/dia',
        optional: true,
      ),
      _number(
        'mudancaMin',
        'Tempo de mudança tmu (opcional)',
        p.mudancaMin,
        'min',
        optional: true,
        zero: true,
      ),
      _number(
        'faixasSimultaneas',
        'Faixas simultâneas NFP (opcional)',
        p.faixasSimultaneas?.toDouble(),
        '',
        optional: true,
      ),
      _number(
        'janelaFornecimentoHorasDia',
        'Duração da janela de fornecimento nos dias indicados (opcional)',
        p.janelaFornecimentoHorasDia,
        'h/dia',
        optional: true,
      ),
      _number(
        'inicioFornecimentoH',
        'Início da janela nos dias indicados (opcional)',
        p.inicioFornecimentoH,
        'h (0–24)',
        optional: true,
        zero: true,
      ),
      TextFormField(
        key: const ValueKey('diasFornecimento'),
        initialValue: p.diasFornecimento.join(', '),
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          labelText: 'Dias com água no período PI (opcional)',
          helperText:
              'Ex.: 1, 3, 5. Dia 1 é o primeiro dia do período informado.',
        ),
        onChanged: (value) {
          ref.read(borderProjectProvider.notifier).setDiasFornecimento(value);
          setState(() => _confirmedSteps.remove(_step));
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          final days = value
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .toList();
          if (days.any(
                (d) =>
                    d == null ||
                    d < 1 ||
                    (p.periodoDias != null && d > p.periodoDias!),
              ) ||
              days.toSet().length != days.length) {
            return 'Informe dias distintos dentro do PI';
          }
          return null;
        },
      ),
      const Text(
        'Sem todos os horários informados, o cronograma permanece pendente.',
      ),
    ],
    _ => [
      IrrigationAuditSection(
        title: 'Área e geometria',
        icon: AppIcons.projetoArea,
        children: [
          _review(
            'Geometria',
            '${_fmt(p.comprimentoM)} × ${_fmt(p.larguraM)} m',
          ),
          _review(
            'Gleba',
            '${_fmt(p.comprimentoAreaM)} × ${_fmt(p.larguraAreaM)} m',
          ),
          _review(
            'Declive longitudinal S0',
            '${_fmt(p.declividadeLongitudinal)} m/m',
          ),
          _review(
            'Declive transversal St',
            '${_fmt(p.declividadeTransversal)} m/m',
          ),
          _review(
            'Jusante',
            p.jusante == CondicaoJusanteFaixa.aberta ? 'Aberta' : 'Fechada',
          ),
        ],
      ),
      const SizedBox(height: 12),
      IrrigationAuditSection(
        title: 'Solo e cultura',
        icon: AppIcons.projetoSolo,
        children: [
          _review('Cobertura', switch (p.cobertura) {
            CoberturaFaixa.soloExposto => 'Solo exposto',
            CoberturaFaixa.culturaInstalada => 'Cultura instalada',
            CoberturaFaixa.coberturaTotal => 'Cobertura total',
          }),
          _review('Textura do solo', p.textura?.displayName ?? 'Não informada'),
          _review(
            'Propriedades hídricas do solo',
            'UCC ${_fmt(p.agronomia?.uccPercentual)}% · UPMP ${_fmt(p.agronomia?.upmpPercentual)}% · Da ${_fmt(p.agronomia?.densidadeGcm3)} g/cm³',
          ),
          _review(
            'Cultura e raízes',
            '${p.cultura ?? 'Não informada'} · Pr ${_fmt(p.agronomia?.profundidadeRaizesCm)} cm · fração disponível ${_fmt(p.agronomia?.fracaoDisponivel)}',
          ),
        ],
      ),
      const SizedBox(height: 12),
      IrrigationAuditSection(
        title: 'Clima e demanda',
        icon: AppIcons.projetoClima,
        children: [
          _review(
            'Clima e demanda',
            'ETc ${_fmt(p.agronomia?.evapotranspiracaoMmDia)} mm/dia · Pef ${_fmt(p.agronomia?.precipitacaoEfetivaMmDia)} mm/dia',
          ),
          _review(
            'Infiltração',
            'k=${_fmt(p.k)} m/minᵃ · a=${_fmt(p.a)} · VIB=${_fmt(p.vibMMin)} m/min',
          ),
          _review('IRN (${p.origemIrn.name})', '${_fmt(p.irnEfetivaMm)} mm'),
          _review('Cenário de infiltração', p.cenarioInfiltracao.name),
        ],
      ),
      const SizedBox(height: 12),
      IrrigationAuditSection(
        title: 'Avanço e operação',
        icon: AppIcons.projetoOperacao,
        children: [
          _review('q0', '${_fmt(p.vazaoUnitariaLsM)} L/s/m'),
          _review('Qfaixa = q0 × W', '${_fmt(p.vazaoFaixaLs)} L/s'),
          _review(
            'Dique / hn',
            '${_fmt(p.alturaDiqueM)} / ${_fmt(p.laminaSuperficialM)} m (não informados quando —)',
          ),
          _review('Oferta de água', '${_fmt(p.vazaoDisponivelLs)} L/s'),
          _review(
            'PI · TDF · tmu · NFP · janela',
            '${p.periodoDias ?? '—'} dias · ${_fmt(p.jornadaHoras)} h/dia · ${_fmt(p.mudancaMin)} min · ${p.faixasSimultaneas ?? '—'} · ${_fmt(p.inicioFornecimentoH)} h por ${_fmt(p.janelaFornecimentoHorasDia)} h nos dias ${p.diasFornecimento.isEmpty ? '—' : p.diasFornecimento.join(', ')}',
          ),
        ],
      ),
      const Text(
        'Comprimento usual, declive e largura são referências, não validações hidráulicas nesta etapa.',
      ),
    ],
  };

  Widget _number(
    String field,
    String label,
    double? value,
    String unit, {
    bool optional = false,
    bool zero = false,
  }) => _BorderInput(
    label: label,
    child: TextFormField(
      key: ValueKey(field),
      initialValue: value?.toString(),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]'))],
      decoration: InputDecoration(
        suffixText: unit.isEmpty ? null : unit,
        helperText: optional ? 'Opcional; vazio = não informado' : null,
      ),
      onChanged: (v) {
        ref.read(borderProjectProvider.notifier).setNumero(field, v);
        setState(() => _confirmedSteps.remove(_step));
      },
      validator: (v) {
        if (optional && (v == null || v.trim().isEmpty)) return null;
        final n = double.tryParse((v ?? '').replaceAll(',', '.'));
        if (n == null || !n.isFinite) return 'Informe um número válido';
        if (zero ? n < 0 : n <= 0) {
          return zero ? 'Use zero ou valor positivo' : 'Use valor positivo';
        }
        if (field == 'a' && n >= 1) return 'O expoente deve ser menor que 1';
        if (field == 'fracaoDisponivel' && n > 1) return 'Use fração até 1';
        if ((field == 'periodoDias' || field == 'faixasSimultaneas') &&
            n != n.roundToDouble()) {
          return 'Informe um número inteiro';
        }
        return null;
      },
    ),
  );

  Widget _select<T>(
    String label,
    T value,
    List<T> options,
    ValueChanged<T> onChanged,
    String Function(T) title,
  ) => _BorderInput(
    label: label,
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      items: options
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                title(v),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
          setState(() => _confirmedSteps.remove(_step));
        }
      },
    ),
  );

  Widget _review(String label, String value) =>
      IrrigationAuditRow(label, value);
  String _fmt(double? n) => n == null
      ? '—'
      : n.abs() < .001 && n != 0
      ? n.toStringAsFixed(6)
      : n.toStringAsFixed(3);
}
