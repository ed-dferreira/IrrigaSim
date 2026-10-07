import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_measurements.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';
import 'package:irrigasim/services/simulation/faixas/border_reference_tables.dart';
import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';
import 'package:irrigasim/views/irrigation/widgets/irrigation_project_components.dart';

import 'border_trial_chart.dart';

class _BorderCropPreset {
  const _BorderCropPreset(
    this.name,
    this.kc,
    this.rows,
    this.plants,
    this.roots,
    this.fraction,
  );

  final String name;
  final double kc, rows, plants, roots, fraction;
}

const _borderCropPresets = <_BorderCropPreset>[
  _BorderCropPreset('Soja', 1.15, .45, .07, 60, .50),
  _BorderCropPreset('Arroz irrigado', 1.20, .17, .03, 20, .20),
  _BorderCropPreset('Milho', 1.20, .80, .20, 100, .55),
  _BorderCropPreset('Trigo', 1.15, .17, .02, 100, .55),
  _BorderCropPreset('Fumo', 1.10, 1.10, .50, 60, .30),
  _BorderCropPreset('Feijão', 1.15, .45, .07, 50, .45),
  _BorderCropPreset('Cevada', 1.15, .17, .02, 100, .55),
  _BorderCropPreset('Aveia', 1.15, .17, .02, 100, .55),
  _BorderCropPreset('Mandioca', .80, 1.00, .60, 80, .35),
  _BorderCropPreset('Cana-de-açúcar', 1.25, 1.40, .50, 120, .65),
  _BorderCropPreset('Uva', .70, 2.50, 1.20, 100, .35),
  _BorderCropPreset('Batata', 1.15, .80, .30, 40, .35),
  _BorderCropPreset('Cebola', 1.05, .30, .10, 30, .30),
  _BorderCropPreset('Canola', 1.15, .35, .04, 100, .60),
  _BorderCropPreset('Sorgo', 1.00, .50, .05, 100, .55),
  _BorderCropPreset('Tomate', 1.15, 1.00, .50, 70, .40),
  _BorderCropPreset('Melancia', 1.00, 2.00, 1.00, 80, .40),
  _BorderCropPreset('Amendoim', 1.15, .50, .10, 50, .50),
  _BorderCropPreset('Triticale', 1.15, .17, .02, 100, .55),
  _BorderCropPreset('Azevém (forragem)', 1.05, .17, .02, 40, .60),
];

_BorderCropPreset? _selectedBorderCropPreset(BorderProject project) {
  for (final preset in _borderCropPresets) {
    if (preset.name == project.cultura &&
        preset.kc == project.agronomia?.kc &&
        preset.rows == project.agronomia?.espacamentoFileirasM &&
        preset.plants == project.agronomia?.espacamentoPlantasM &&
        preset.roots == project.agronomia?.profundidadeRaizesCm &&
        preset.fraction == project.agronomia?.fracaoDisponivel) {
      return preset;
    }
  }
  return null;
}

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

class _BorderProjectScreenState extends ConsumerState<BorderProjectScreen> {
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
                      subtitle: 'Etapa ${_step + 1} de ${_titles.length}',
                      icon: _icons[_step],
                      accent: AppColors.faixa,
                      child: _layoutFields(_fields(project)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                                        _erroEstacas == null &&
                                        _erroPerfil == null) {
                                      setState(
                                        () => _confirmedSteps.add(_step),
                                      );
                                    }
                                  },
                                  icon: const Icon(AppIcons.sucesso),
                                  label: const Text('Confirmar'),
                                ),
                        if (_step < 7) const SizedBox(width: 12),
                        Tooltip(
                          message: _step == 7
                              ? 'Calcular a simulação da faixa'
                              : 'Avançar para a próxima etapa',
                          child: SizedBox(
                            width: 160,
                            height: 48,
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
                                              final result =
                                                  calcularProjetoFaixa(project);
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
                                    ? 'Calcular projeto'
                                    : 'Próximo',
                              ),
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
          Padding(
            padding: const EdgeInsets.only(bottom: IrrigationSpacing.field),
            child: Wrap(
              spacing: IrrigationSpacing.field,
              runSpacing: IrrigationSpacing.field,
              children: [
                for (final field in group)
                  SizedBox(width: fieldWidth, child: field),
              ],
            ),
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
            Padding(
              padding: const EdgeInsets.only(bottom: IrrigationSpacing.field),
              child: field,
            ),
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
      _number('larguraAreaM', 'Largura da área bruta', p.larguraAreaM, 'm'),
      _number(
        'areaUtilM2',
        'Área útil irrigável (opcional)',
        p.areaUtilM2,
        'm²',
        optional: true,
      ),
      _BorderInput(
        label: 'Orientação da área (opcional)',
        child: TextFormField(
          initialValue: p.orientacaoArea,
          decoration: const InputDecoration(
            hintText: 'Ex.: Norte–Sul; sentido do avanço',
          ),
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setOrientacaoArea(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
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
      TextFormField(
        key: const ValueKey('perfilLongitudinal'),
        initialValue: p.perfilLongitudinal
            .map((point) => '${point.xM};${point.cotaM}')
            .join('\n'),
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Perfil longitudinal levantado (opcional)',
          helperText: 'Uma estaca por linha: distância m;cota m. Inclua 0 e o comprimento total. Perfil variável/terminal plano fica registrado, mas requer motor por trechos.',
          errorText: _erroPerfil,
        ),
        onChanged: (text) {
          try {
            final points = text.trim().isEmpty
                ? <BorderTerrainPoint>[]
                : text.trim().split('\n').map((line) {
                    final values = line
                        .split(';')
                        .map(
                          (value) =>
                              double.parse(value.trim().replaceAll(',', '.')),
                        )
                        .toList();
                    if (values.length != 2 ||
                        values.any((value) => !value.isFinite)) {
                      throw const FormatException(
                        'Use distância;cota, ambas em metros.',
                      );
                    }
                    return BorderTerrainPoint(values[0], values[1]);
                  }).toList();
            ref
                .read(borderProjectProvider.notifier)
                .setPerfilLongitudinal(points);
            setState(() {
              _erroPerfil = null;
              _confirmedSteps.remove(_step);
            });
          } on FormatException catch (error) {
            setState(() => _erroPerfil = error.message);
          }
        },
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
      _BorderInput(
        label: 'Tipo de dique (registro construtivo opcional)',
        child: TextFormField(
          initialValue: p.tipoDique,
          decoration: const InputDecoration(
            hintText: 'Ex.: dique de terra compactada',
            helperText: 'Registro descritivo; não altera o cálculo hidráulico.',
          ),
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setTipoDique(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
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
      _BorderInput(
        label: 'Consulta de quantidade de dispositivos (orientativa)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<double>(
              initialValue: p.dispositivoDiametroCm ?? _diametroBooherCm,
              decoration: const InputDecoration(labelText: 'Diâmetro impresso'),
              items: [
                for (final value in BorderReferenceTables.diametrosCm)
                  DropdownMenuItem(value: value, child: Text('$value cm')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _diametroBooherCm = value);
                ref
                    .read(borderProjectProvider.notifier)
                    .setDispositivo(
                      diametroCm: value,
                      cargaCm: p.dispositivoCargaCm ?? _cargaBooherCm,
                    );
                setState(() => _confirmedSteps.remove(_step));
              },
            ),
            const SizedBox(height: IrrigationSpacing.field),
            DropdownButtonFormField<double>(
              initialValue: p.dispositivoCargaCm ?? _cargaBooherCm,
              decoration: const InputDecoration(labelText: 'Carga impressa'),
              items: [
                for (final value in BorderReferenceTables.cargasCm)
                  DropdownMenuItem(value: value, child: Text('$value cm')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _cargaBooherCm = value);
                ref
                    .read(borderProjectProvider.notifier)
                    .setDispositivo(
                      diametroCm: p.dispositivoDiametroCm ?? _diametroBooherCm,
                      cargaCm: value,
                    );
                setState(() => _confirmedSteps.remove(_step));
              },
            ),
            const SizedBox(height: IrrigationSpacing.field),
            Builder(
              builder: (context) {
                final cell = const BorderReferenceTables().booher(
                  p.dispositivoDiametroCm ?? _diametroBooherCm,
                  p.dispositivoCargaCm ?? _cargaBooherCm,
                )!;
                final eligible = const BorderReferenceTables().sugestao(
                  p.dispositivoDiametroCm ?? _diametroBooherCm,
                  p.dispositivoCargaCm ?? _cargaBooherCm,
                );
                if (eligible == null) {
                  return IrrigationAlertBanner(
                    message:
                        'Bloqueado: célula sob revisão. Valor impresso ${cell.impressoLs} L/s; hipótese proposta ${cell.propostoLs} L/s. Não usada para dimensionar dispositivos.',
                  );
                }
                final perDevice = eligible.impressoLs;
                final count = p.vazaoFaixaLs == null
                    ? null
                    : (p.vazaoFaixaLs! / perDevice).ceil();
                final simultaneasPelaOferta =
                    p.vazaoDisponivelLs == null || p.vazaoFaixaLs == null
                    ? null
                    : (p.vazaoDisponivelLs! / p.vazaoFaixaLs!).floor();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IrrigationFormulaCard(
                      formula:
                          'Booher impresso: ${eligible.impressoLs} L/s por dispositivo',
                      description: count == null
                          ? 'Informe q0 e W para estimar quantidade. Consulta orientativa; carga e vazão real devem ser confirmadas em campo.'
                          : '$count dispositivos por faixa (arredondamento para cima) · vazão total estimada ${_fmt(count * perDevice)} L/s para Qfaixa ${_fmt(p.vazaoFaixaLs)} L/s. Não representa cálculo hidráulico de comportas.',
                    ),
                    if (p.vazaoDisponivelLs == null)
                      const Padding(
                        padding: EdgeInsets.only(
                          bottom: IrrigationSpacing.field,
                        ),
                        child: Text(
                          'Qt pendente: informe a oferta disponível para verificar simultaneidade.',
                        ),
                      )
                    else if (p.vazaoFaixaLs != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: IrrigationSpacing.field,
                        ),
                        child: IrrigationAlertBanner(
                          message: simultaneasPelaOferta == 0
                              ? 'Oferta insuficiente: Qt=${_fmt(p.vazaoDisponivelLs)} L/s não atende sequer uma faixa (Qfaixa=${_fmt(p.vazaoFaixaLs)} L/s).'
                              : 'Qt=${_fmt(p.vazaoDisponivelLs)} L/s permite no máximo $simultaneasPelaOferta faixa(s) simultânea(s) a Qfaixa=${_fmt(p.vazaoFaixaLs)} L/s. Defina NFP respeitando esse teto e confirme a divisão real da água.',
                        ),
                      ),
                    const Text(
                      'Registrar tipo de dique e orientação construtiva. A aula recomenda dois sulcos transversais no início e cerca de três adicionais, equidistantes, para declive >3%; o aplicativo não desenha nem dimensiona a construção. Bases ilustradas de diques não são alturas.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ],
    3 => [
      Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informações da cultura para estimativa de demanda hídrica.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _BorderInput(
                label: 'Predefinição de cultura',
                child: DropdownButtonFormField<_BorderCropPreset?>(
                  key: ValueKey('crop-preset-$_cropPresetRevision'),
                  isExpanded: true,
                  initialValue: _selectedBorderCropPreset(p),
                  decoration: const InputDecoration(
                    helperText: 'Selecione uma cultura para preencher os parâmetros; eles podem ser ajustados depois.',
                  ),
                  items: [
                    const DropdownMenuItem<_BorderCropPreset?>(
                      value: null,
                      child: Text('Personalizada / sem predefinição'),
                    ),
                    ..._borderCropPresets.map(
                      (preset) => DropdownMenuItem<_BorderCropPreset?>(
                        value: preset,
                        child: Text(preset.name),
                      ),
                    ),
                  ],
                  onChanged: (preset) {
                    if (preset == null) return;
                    final controller = ref.read(borderProjectProvider.notifier);
                    controller.setCultura(preset.name);
                    for (final value in {
                      'kc': preset.kc,
                      'espacamentoFileirasM': preset.rows,
                      'espacamentoPlantasM': preset.plants,
                      'profundidadeRaizesCm': preset.roots,
                      'fracaoDisponivel': preset.fraction,
                    }.entries) {
                      controller.setNumero(value.key, value.value.toString());
                    }
                    setState(() {
                      _cropPresetRevision++;
                      _confirmedSteps.remove(_step);
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fieldWidth = constraints.maxWidth >= 650
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: _BorderInput(
                          label: 'Nome da cultura',
                          child: TextFormField(
                            key: ValueKey('crop-name-$_cropPresetRevision'),
                            initialValue: p.cultura ?? '',
                            onChanged: (value) {
                              ref
                                  .read(borderProjectProvider.notifier)
                                  .setCultura(value);
                              setState(() => _confirmedSteps.remove(_step));
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _number(
                          'kc',
                          'Coeficiente da cultura (Kc)',
                          p.agronomia?.kc,
                          '',
                          resetKey: _cropPresetRevision,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _number(
                          'espacamentoFileirasM',
                          'Espaçamento entre fileiras',
                          p.agronomia?.espacamentoFileirasM,
                          'm',
                          resetKey: _cropPresetRevision,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _number(
                          'espacamentoPlantasM',
                          'Espaçamento entre plantas',
                          p.agronomia?.espacamentoPlantasM,
                          'm',
                          resetKey: _cropPresetRevision,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _number(
                          'profundidadeRaizesCm',
                          'Profundidade das raízes',
                          p.agronomia?.profundidadeRaizesCm,
                          'cm',
                          resetKey: _cropPresetRevision,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _number(
                          'fracaoDisponivel',
                          'Fração de água disponível',
                          p.agronomia?.fracaoDisponivel,
                          '',
                          resetKey: _cropPresetRevision,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
      const IrrigationAlertBanner(
        message: 'F02 está registrada como fórmula da fonte, mas permanece bloqueada: Vmax e suas unidades/convenção não estão suficientemente definidos no pacote; entradas abaixo são apenas dados de auditoria e não calculam qmax.',
      ),
      _number(
        'rho1F02',
        'ρ1 transcrito (F02, opcional)',
        p.rho1F02,
        '',
        optional: true,
      ),
      _number(
        'rho2F02',
        'ρ2 transcrito (F02, opcional)',
        p.rho2F02,
        '',
        optional: true,
      ),
      _number(
        'vmaxF02',
        'Vmax informado para auditoria (F02, opcional)',
        p.vmaxF02,
        '',
        optional: true,
      ),
      _BorderInput(
        label: 'Unidade declarada de Vmax (F02, não interpretada)',
        child: TextFormField(
          initialValue: p.unidadeVmaxF02,
          decoration: const InputDecoration(
            hintText: 'Unidade conforme a fonte consultada',
          ),
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setUnidadeVmaxF02(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
      _number('rInicial', 'Palpite inicial r', p.rInicial, '', optional: true),
      const Text(
        'O tempo de corte do dimensionamento é calculado. Para avaliar um ensaio medido, informe estacas; o corte abaixo só vale para esse ensaio.',
      ),
      _BorderInput(
        label: 'Referência de corte antecipado (condicional, p.21)',
        child: DropdownButtonFormField<double?>(
          initialValue: p.fracaoCortePlanejada,
          items: const [
            DropdownMenuItem<double?>(
              value: null,
              child: Text('Não selecionar'),
            ),
            DropdownMenuItem<double?>(value: 2 / 3, child: Text('2/3 de L')),
            DropdownMenuItem<double?>(value: .75, child: Text('3/4 de L')),
          ],
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setFracaoCorte(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
      if (p.fracaoCortePlanejada != null)
        const IrrigationAlertBanner(
          message: 'Este manejo antecipa o corte em relação ao avanço completo. O motor ainda não calcula o avanço com água remanescente; a simulação ficará bloqueada até haver modelo por regime.',
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
          helperText: 'Uma por linha: distância m; avanço min; recessão min (opcional). Inclua 0;0, estacas preferencialmente a cada 10–30 m e a última em L.',
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
                  final measured = const BorderFieldTrial().evaluate(
                    p,
                    p.estacas,
                    cutoffMin: p.corteEnsaioMin,
                  );
                  ref.read(borderTrialProvider.notifier).state = measured;
                  try {
                    ref.read(borderTrialSimulationProvider.notifier).state =
                        const BorderHydraulics().dimensionar(p);
                  } on FormatException {
                    ref.read(borderTrialSimulationProvider.notifier).state =
                        null;
                  }
                } on FormatException catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
        icon: const Icon(AppIcons.projetoEnsaio),
        label: const Text('Avaliar ensaio medido'),
      ),
      if (ref.watch(borderTrialProvider) case final trial?) ...[
        BorderTrialChart(
          trial: trial,
          simulated: ref.watch(borderTrialSimulationProvider),
        ),
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
              ClipboardData(
                text: borderTrialCsv(
                  p,
                  trial,
                  simulacao: ref.read(borderTrialSimulationProvider),
                ),
              ),
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
      _BorderInput(
        label: 'Data do ensaio (opcional)',
        child: TextFormField(
          initialValue: p.dataEnsaioIso,
          decoration: const InputDecoration(
            hintText: 'AAAA-MM-DD',
            helperText: 'Data civil local registrada; não é inferida.',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            return DateTime.tryParse(value.trim()) == null
                ? 'Use uma data ISO válida'
                : null;
          },
          onChanged: (value) {
            ref.read(borderProjectProvider.notifier).setDataEnsaio(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
      _BorderInput(
        label: 'Referência do relógio do ensaio (opcional)',
        child: TextFormField(
          initialValue: p.referenciaRelogioEnsaio,
          decoration: const InputDecoration(
            hintText: 'Ex.: instante inicial do cronômetro',
          ),
          onChanged: (value) {
            ref
                .read(borderProjectProvider.notifier)
                .setReferenciaRelogioEnsaio(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
      _BorderInput(
        label: 'Observações de campo (opcional)',
        child: TextFormField(
          initialValue: p.observacoesEnsaio,
          minLines: 2,
          maxLines: 4,
          onChanged: (value) {
            ref
                .read(borderProjectProvider.notifier)
                .setObservacoesEnsaio(value);
            setState(() => _confirmedSteps.remove(_step));
          },
        ),
      ),
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
          _review(
            'Parâmetros da cultura',
            'Kc ${_fmt(p.agronomia?.kc)} · fileiras ${_fmt(p.agronomia?.espacamentoFileirasM)} m · plantas ${_fmt(p.agronomia?.espacamentoPlantasM)} m',
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
          _review('Tipo do dique', p.tipoDique ?? 'Não informado'),
          _review(
            'Corte antecipado de referência',
            p.fracaoCortePlanejada == null
                ? 'Não selecionado'
                : '${(p.fracaoCortePlanejada! * 100).toStringAsFixed(1)}% de L · bloqueado até haver modelo pós-corte',
          ),
          _review(
            'F02 alternativo',
            'Bloqueado · ρ1=${_fmt(p.rho1F02)} · ρ2=${_fmt(p.rho2F02)} · Vmax=${_fmt(p.vmaxF02)} ${p.unidadeVmaxF02 ?? ''}',
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
    int? resetKey,
  }) => _BorderInput(
    label: label,
    child: TextFormField(
      key: ValueKey(resetKey == null ? field : '$field-$resetKey'),
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
