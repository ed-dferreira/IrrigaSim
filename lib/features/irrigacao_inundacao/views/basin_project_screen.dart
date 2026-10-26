// Wizard do projeto de irrigação por inundação (Fase 6 e Fase 3 do plano de
// cultura/clima/operacao). Espelha
// lib/views/irrigation/faixas/border_project_screen.dart: ListView com etapas
// numeradas, confirmação por etapa e cálculo ao final, mas com conteúdo que
// varia conforme o regime (G8) e presets da Aula 8 (G5). Nove etapas: as
// etapas 5 (Cultura), 6 (Clima e demanda) e a Operação enriquecida são do
// plano docs/Plano_implementacao_bacia_cultura_clima_operacao.md.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/shared/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/crop_presets.dart';
import 'package:irrigasim/shared/irrigacao/models/validacao_superficie.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_project.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_planning.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_math.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_tables.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_reference_panel.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
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
        BasinProject.fromLegacy(cenario.parametros);
    ref.read(basinProjectProvider.notifier).carregar(projeto);
  }

  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  final Set<int> _confirmedSteps = {};
  bool _calculando = false;
  int _presetRevision = 0;

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
    'Planejamento',
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
    AppIcons.resumoConfiguracao,
    AppIcons.projetoRevisao,
  ];

  /// Índice da etapa de Revisão (a última); as anteriores precisam ser
  /// confirmadas para liberar o cálculo.
  static const _revisaoStep = 8;

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
      7,
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
                  const SizedBox(height: IrrigationSpacing.section),
                  IrrigationProjectStepCard(
                    title: _titles[_step],
                    subtitle: 'Etapa ${_step + 1} de ${_titles.length}',
                    icon: _icons[_step],
                    accent: AppColors.inundacao,
                    child: _layoutFields(_fields(project)),
                  ),
                  if (_step == _revisaoStep) ...[
                    const SizedBox(height: IrrigationSpacing.section),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          notice?.mensagem ??
                              'Modelo disponível: as entradas respeitam as '
                                  'regras G1–G9 da Aula 8.',
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
                  const SizedBox(height: IrrigationSpacing.section),
                  _navigationRow(project, notice, bloqueia, todasConfirmadas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Etapas.
  // ---------------------------------------------------------------------------

  List<Widget> _fields(BasinProject project) => switch (_step) {
    0 => _regimeFields(project),
    1 => _areaFields(project),
    2 => _taipaFields(project),
    3 =>
      project.regime == TipoInundacao.permanente
          ? _soloPermanenteFields(project)
          : _soloIntermitenteFields(project),
    4 => _culturaFields(project),
    5 => _climaFields(project),
    6 => _operacaoFields(project),
    7 => [
      ...project.regime == TipoInundacao.permanente
          ? _planejamentoPermanenteFields(project)
          : _planejamentoIntermitenteFields(project),
    ],
    _ => _revisaoFields(project),
  };

  List<Widget> _regimeFields(BasinProject project) => [
    SegmentedButton<TipoInundacao>(
      segments: const [
        ButtonSegment(
          value: TipoInundacao.intermitente,
          label: Text('Intermitente (sem circulação)'),
          icon: Icon(AppIcons.inundacao),
        ),
        ButtonSegment(
          value: TipoInundacao.permanente,
          label: Text('Permanente (com circulação)'),
          icon: Icon(AppIcons.inundacao),
        ),
      ],
      selected: {project.regime},
      onSelectionChanged: (selection) {
        setState(() => _confirmedSteps.remove(_step));
        ref.read(basinProjectProvider.notifier).setRegime(selection.first);
      },
    ),
    const SizedBox(height: IrrigationSpacing.field),
    IrrigationFormulaCard(
      formula: project.regime == TipoInundacao.intermitente
          ? 'Q0 (x) → tx = ta (x/L)^(1/r) · ti = max[ta, (IRN − 0,8 y0) L / Q0 + ta]'
          : 'TR = DTA · Z · f / ET · Qe → lâmina · Qm = 0,116 (ET + K0) A',
      description: project.regime == TipoInundacao.intermitente
          ? 'Enchimento e esvaziamento de cada ciclo (Aula 8, pp. 40–62). '
                'A água entra, avança pelo tabuleiro e escoa na jusante.'
          : 'Rega contínua com nível permanente: Qe forma a lâmina e Qm '
                'recompõe evapotranspiração e percolação (pp. 64–73).',
    ),
    const SizedBox(height: IrrigationSpacing.field),
    FilledButton.tonalIcon(
      onPressed: () {
        setState(() {
          _confirmedSteps.clear();
          _presetRevision++;
        });
        ref.read(basinProjectProvider.notifier).aplicarExemploAula8();
      },
      icon: const Icon(AppIcons.projetoCalcular),
      label: const Text('Exemplo da Aula 8 (presets das pp. 63, 73 e 84)'),
    ),
  ];

  List<Widget> _areaFields(BasinProject project) => [
    _number(
      'comprimentoAreaM',
      'Comprimento da área (L)',
      project.comprimentoAreaM,
      'm',
    ),
    _number('larguraAreaM', 'Largura da área', project.larguraAreaM, 'm'),
    _number(
      'areaUtilM2',
      'Área útil (opcional)',
      project.areaUtilM2,
      'm²',
      optional: true,
    ),
    if (project.regime == TipoInundacao.permanente)
      _number('areaHectares', 'Área irrigada', project.areaHectares, 'ha'),
    _number(
      'comprimentoM',
      'Comprimento do tabuleiro (L)',
      project.comprimentoM,
      'm',
    ),
    _number('larguraM', 'Largura do tabuleiro', project.larguraM, 'm'),
    _number(
      'declividade',
      'Declividade longitudinal (m/m)',
      project.declividade,
      'ex.: 0,0025 = 0,25%',
      zero: true,
    ),
    _select<TexturaSolo>(
      'Textura do solo',
      project.texturaSolo ?? TexturaSolo.media,
      TexturaSolo.values,
      (value) {
        setState(() => _confirmedSteps.remove(_step));
        ref.read(basinProjectProvider.notifier).setTexturaSolo(value);
      },
      (value) => value.displayName,
    ),
    if (project.regime == TipoInundacao.intermitente) ...[
      _number(
        'laminaInicialMm',
        'Lâmina inicial Li (opcional)',
        project.laminaInicialMm,
        'mm',
        optional: true,
      ),
      _number(
        'laminaFinalMm',
        'Lâmina final Lf (opcional)',
        project.laminaFinalMm,
        'mm',
        optional: true,
      ),
    ],
    if (project.areaTabuleiroM2 != null)
      IrrigationFormulaCard(
        formula:
            'Área do tabuleiro = ${_fmt(project.comprimentoM)} × '
            '${_fmt(project.larguraM)} = ${_fmt(project.areaTabuleiroM2)} m²',
        description: 'O tabuleiro precisa caber entre 1 m² e 5 ha (G2).',
      ),
    if (project.laminaMediaPlanaltoM != null &&
        project.declividade != null) ...[
      IrrigationFormulaCard(
        formula:
            'Lm = ${_fmt(project.laminaMediaPlanaltoM! * 100)} cm · '
            'Δz admissível = 2/3 Lm = ${_fmt((project.desnivelAdmissivelM ?? 0) * 100)} cm · '
            'Δz real = ${_fmt((project.desnivelRealM ?? 0) * 100)} cm',
        description:
            'Regra 2/3 (p. 20): o desnível real não pode superar 2/3 da '
            'lâmina média no planalto.',
      ),
      if (project.comprimentoMaximoDesnivelM != null)
        IrrigationFormulaCard(
          formula:
              'L máximo = (2/3 Lm) / S = ${_fmt(project.comprimentoMaximoDesnivelM)} m',
          description:
              'Exemplos da p. 20: 0,25% → 40 m; 0,05% → 200 m, pela '
              'direção avaliada.',
        ),
    ],
    ..._guiaAreaFields(project),
  ];

  /// Sugestão de área do guia da p. 16 para a textura e a vazão atuais.
  List<Widget> _guiaAreaFields(BasinProject project) {
    final vazao = project.vazaoAplicadaLs ?? project.vazaoDisponivelLps;
    final chave = _chaveGuiaSolo(project.texturaSolo);
    final sugerida = chave == null || vazao == null
        ? null
        : const BasinReferenceTables().areaSugerida(chave, vazao);
    return [
      ExpansionTile(
        leading: const Icon(AppIcons.soloArgiloso),
        title: const Text('Sugestão de área × vazão (p. 16)'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          if (sugerida != null)
            IrrigationFormulaCard(
              formula:
                  'Textura ${project.texturaSolo?.displayName ?? '—'} → '
                  '${_fmt(sugerida, casas: 2)} ha para '
                  '${_fmt(vazao, casas: 1)} L/s',
              description:
                  'Guia orientativo da p. 16; não substitui o '
                  'dimensionamento hidráulico.',
            ),
          for (final row in BasinReferenceTables.guiaSolo)
            IrrigationAuditRow(
              row.rotulo,
              vazao == null
                  ? '${row.areaHaBase} ha a 10 L/s'
                  : '${_fmt(row.areaParaVazao(vazao), casas: 2)} ha a '
                        '${_fmt(vazao, casas: 1)} L/s',
              detail: 'Orientativo; não substitui o dimensionamento.',
              isWarning: true,
              pagina: '${BasinReferenceTables.paginaGuiaSolo}',
            ),
        ],
      ),
    ];
  }

  String? _chaveGuiaSolo(TexturaSolo? textura) => switch (textura) {
    TexturaSolo.muitoGrossa || TexturaSolo.grossa => 'arenoso',
    TexturaSolo.media => 'franco-arenoso',
    TexturaSolo.fina => 'franco-argiloso',
    TexturaSolo.muitoFina => 'argiloso',
    null => null,
  };

  List<Widget> _taipaFields(BasinProject project) => [
    _number('alturaDiqueM', 'Altura da taipa', project.alturaDiqueM, 'm'),
    _number('baseDiqueM', 'Base da taipa', project.baseDiqueM, 'm'),
    _number(
      'margemLivreM',
      'Margem livre acima da lâmina',
      project.margemLivreM,
      'm',
    ),
    const IrrigationFormulaCard(
      formula: 'y0 + margem livre ≤ altura da taipa',
      description:
          'A taipa precisa conter a profundidade normal com margem (p. 35). '
          'Limites G2: base 0,60–1,80 m; altura 0,60–0,80 m; margem '
          '0,05–0,20 m.',
    ),
  ];

  List<Widget> _soloIntermitenteFields(BasinProject project) => [
    const Text(
      'A infiltração controla o avanço e o tempo de contato. O material '
      'traz os testes da primeira e da terceira irrigação como entradas do '
      'modelo (Aula 8, pp. 53 e 63), cada um com k, a e VIB próprios.',
    ),
    _select<CenarioInfiltracaoBasin>(
      'Cenário de infiltração',
      project.cenarioInfiltracao,
      CenarioInfiltracaoBasin.values,
      (value) {
        setState(() => _confirmedSteps.remove(_step));
        ref.read(basinProjectProvider.notifier).setCenarioInfiltracao(value);
      },
      (value) => value.displayName,
    ),
    const Text(
      'O cenário identifica a origem dos coeficientes: k, a e VIB vêm da '
      'irrigação escolhida ou dos valores informados, sem misturar '
      'coeficientes entre irrigações.',
    ),
    _number(
      'k',
      'k da infiltração',
      project.k,
      'm/min^a',
      key: 'k-$_presetRevision-${project.cenarioInfiltracao.name}',
    ),
    _number(
      'a',
      'Expoente a',
      project.a,
      '0 < a < 1',
      key: 'a-$_presetRevision-${project.cenarioInfiltracao.name}',
    ),
    _number(
      'vibMMin',
      'VIB',
      project.vibMMin,
      'm/min',
      key: 'vib-$_presetRevision-${project.cenarioInfiltracao.name}',
    ),
    ..._infiltracaoCalculadaFields(project),
  ];

  /// Campo calculado I(t) = (k · t^a + VIB · t) · 1000, com t em minutos.
  List<Widget> _infiltracaoCalculadaFields(BasinProject project) => [
    _BasinInput(
      child: TextFormField(
        key: const ValueKey('tempoInfiltracaoMin'),
        initialValue: _tempoInfiltracaoMin.toString().replaceAll('.', ','),
        decoration: const InputDecoration(
          labelText: 'Tempo de contato t',
          suffixText: 'min',
          helperText: 'Tempo usado no cálculo de I(t)',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
        ],
        validator: (texto) {
          if (texto == null || texto.trim().isEmpty) return 'Informe o tempo.';
          final parsed = double.tryParse(texto.replaceAll(',', '.'));
          if (parsed == null || !parsed.isFinite || parsed <= 0) {
            return 'Maior que zero.';
          }
          return null;
        },
        onChanged: (texto) {
          final parsed = double.tryParse(texto.replaceAll(',', '.'));
          if (parsed == null || !parsed.isFinite || parsed <= 0) return;
          setState(() {
            _tempoInfiltracaoMin = parsed;
            _confirmedSteps.remove(_step);
          });
        },
      ),
    ),
    if (_infiltracaoAcumuladaMm(project) != null)
      CalculatedField(
        label: 'Infiltração acumulada I(t)',
        value: _infiltracaoAcumuladaMm(project)!,
        suffix: 'mm',
        helper: 'I(t) = (k · t^a + VIB · t) · 1000, com t em minutos.',
      ),
  ];

  double? _infiltracaoAcumuladaMm(BasinProject project) {
    final k = project.k;
    final a = project.a;
    final vib = project.vibMMin;
    final t = _tempoInfiltracaoMin;
    if (k == null || a == null || vib == null || k <= 0 || vib < 0 || t <= 0) {
      return null;
    }
    if (!(a > 0 && a < 1)) return null;
    try {
      return Infiltracao(k, a, vib).acumulada(t) * 1000;
    } on ArgumentError {
      return null;
    }
  }

  List<Widget> _soloPermanenteFields(BasinProject project) => [
    const Text(
      'No regime contínuo os dados do solo sustentam o turno de rega e as '
      'vazões Qe e Qm (Aula 8, pp. 64–73). O cenário de infiltração '
      'k/a/VIB é dos testes da primeira e da terceira irrigação (p. 53) e '
      'vale só para o regime intermitente. Porosidade, camada, DTA, fator de '
      'disponibilidade e K0 ficam na etapa Cultura e sistema radicular.',
    ),
    _number(
      'laminaSuperficialMm',
      'Lâmina superficial',
      project.laminaSuperficialMm,
      'mm',
    ),
  ];

  /// Etapa 5 — Cultura e sistema radicular (Fase 3 do plano): presets de
  /// cultura, insumos de solo/raízes da IRN e, no permanente, os campos de
  /// camada movidos da etapa de solo (G15).
  List<Widget> _culturaFields(BasinProject project) {
    final agronomia = project.agronomia;
    return [
      const Text(
        'A cultura e o sistema radicular definem a demanda hídrica e, no '
        'intermitente, a IRN calculada por IRN = (UCC − UPMP)/10 · Ds · z · f '
        '(Aula 8, p. 63). Os presets preenchem Kc, raízes e fração; os dados '
        'de solo (UCC, UPMP e Ds) continuam seus.',
      ),
      _BasinInput(
        child: DropdownButtonFormField<CropPreset?>(
          key: ValueKey('basin-crop-preset-$_cropPresetRevision'),
          isExpanded: true,
          initialValue: _selectedCropPreset(project),
          decoration: const InputDecoration(
            labelText: 'Predefinição de cultura',
            helperText:
                'Selecione uma cultura para preencher os parâmetros; eles '
                'podem ser ajustados depois.',
          ),
          items: [
            const DropdownMenuItem<CropPreset?>(
              value: null,
              child: Text(
                'Personalizada / sem predefinição',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ...cropPresets.map(
              (preset) => DropdownMenuItem<CropPreset?>(
                value: preset,
                child: Text(
                  preset.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
          onChanged: (preset) {
            if (preset == null) return;
            final controller = ref.read(basinProjectProvider.notifier);
            for (final entry in {
              'kc': preset.kc,
              'profundidadeRaizesCm': preset.roots,
              'fracaoDisponivel': preset.fraction,
            }.entries) {
              controller.setAgronomia(entry.key, entry.value.toString());
            }
            controller.setCultura(preset.name);
            setState(() {
              _cropPresetRevision++;
              _confirmedSteps.remove(_step);
            });
          },
        ),
      ),
      _BasinInput(
        child: TextFormField(
          key: ValueKey('basin-crop-name-$_cropPresetRevision'),
          initialValue: project.culturaEfetiva ?? '',
          decoration: const InputDecoration(
            labelText: 'Nome da cultura (opcional)',
            helperText: 'Opcional',
          ),
          onChanged: (value) {
            setState(() => _confirmedSteps.remove(_step));
            ref.read(basinProjectProvider.notifier).setCultura(value);
          },
        ),
      ),
      _number(
        'kc',
        'Coeficiente da cultura (Kc)',
        agronomia?.kc,
        '—',
        key: 'kc-$_cropPresetRevision',
      ),
      _number(
        'profundidadeRaizesCm',
        'Profundidade do sistema radicular (z)',
        agronomia?.profundidadeRaizesCm,
        'cm',
        key: 'raiz-$_cropPresetRevision',
      ),
      _number(
        'fracaoDisponivel',
        'Fração de água disponível (f)',
        agronomia?.fracaoDisponivel,
        '0–1',
        key: 'fracao-$_cropPresetRevision',
      ),
      _number(
        'uccPercentual',
        'Umidade na capacidade de campo (UCC)',
        agronomia?.uccPercentual,
        '%',
        optional: true,
      ),
      _number(
        'upmpPercentual',
        'Umidade no ponto de murcha permanente (UPMP)',
        agronomia?.upmpPercentual,
        '%',
        optional: true,
      ),
      _number(
        'densidadeGcm3',
        'Densidade aparente do solo (Ds)',
        agronomia?.densidadeGcm3,
        'g/cm³',
        optional: true,
      ),
      if (project.regime == TipoInundacao.permanente) ...[
        const Text(
          'Camadas e turno do regime contínuo (G15): porosidade, profundidade '
          'da camada, DTA, fator de disponibilidade e K0 sustentam TR = DTA · '
          'Z · f / ETc e as vazões Qe e Qm (Aula 8, pp. 67–73).',
        ),
        _number('porosidade', 'Porosidade', project.porosidade, '0–1'),
        _number(
          'profundidadeCamadaMm',
          'Profundidade da camada (Z)',
          project.profundidadeCamadaMm,
          'mm',
        ),
        _number(
          'dtaMmCm',
          'Disponibilidade total de água (DTA)',
          project.dtaMmCm,
          'mm/cm',
        ),
        _number(
          'fatorDisponibilidade',
          'Fator de disponibilidade (f)',
          project.fatorDisponibilidade,
          '0–1',
        ),
        _number(
          'condutividadeHidraulicaMmDia',
          'Condutividade hidráulica K0',
          project.condutividadeHidraulicaMmDia,
          'mm/dia',
        ),
        _turnoRegaPermanenteCard(project),
      ],
    ];
  }

  CropPreset? _selectedCropPreset(BasinProject project) {
    final agronomia = project.agronomia;
    if (agronomia == null) return null;
    for (final preset in cropPresets) {
      if (preset.name == project.culturaEfetiva &&
          preset.kc == agronomia.kc &&
          preset.roots == agronomia.profundidadeRaizesCm &&
          preset.fraction == agronomia.fracaoDisponivel) {
        return preset;
      }
    }
    return null;
  }

  /// Card derivado do turno de rega contínuo (G15; p. 73), com o valor vivo
  /// quando DTA, Z, f e ETc estão completos.
  Widget _turnoRegaPermanenteCard(BasinProject project) {
    final tr = _turnoRegaPermanente(project);
    return IrrigationFormulaCard(
      formula: tr == null
          ? 'TR = DTA · Z · f / ETc'
          : 'TR = DTA · Z · f / ETc = ${_fmt(tr, casas: 1)} dias',
      description:
          'Turno de rega do regime contínuo; Qe e Qm saem do fator 0,116 '
          'com a ETc da etapa de clima.',
      pagina: '73',
    );
  }

  /// Etapa 6 — Clima e demanda (Fase 3 do plano): método de ETc, origem da
  /// chuva, origem da IRN (G14) e o card vivo de IRN/volume/TR; no permanente
  /// mostra ETc/Pef/TR do contínuo e esconde a IRN intermitente (G8).
  List<Widget> _climaFields(BasinProject project) {
    final intermitente = project.regime == TipoInundacao.intermitente;
    return [
      const Text(
        'A demanda da cultura (ETc) e a precipitação efetiva alimentam o '
        'balanço e o turno de rega (Aula 7, F25–F32; Aula 8, p. 63). Chuva '
        'registrada como provável não vira crédito de Pef.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final metodo in MetodoEtc.values)
            ChoiceChip(
              label: Text(switch (metodo) {
                MetodoEtc.adotada => 'ETc adotada',
                MetodoEtc.etoVezesKc => 'ETo × Kc',
                MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
              }),
              selected: project.metodoEtc == metodo,
              onSelected: (_) {
                setState(() => _confirmedSteps.remove(_step));
                ref.read(basinProjectProvider.notifier).setMetodoEtc(metodo);
              },
            ),
        ],
      ),
      const SizedBox(height: IrrigationSpacing.field),
      if (project.metodoEtc == MetodoEtc.adotada)
        intermitente
            ? _number(
                'etIntermitenteMmDia',
                'Evapotranspiração do intervalo (ETc)',
                project.etIntermitenteMmDia,
                'mm/dia',
              )
            : _number(
                'evapotranspiracaoMmDia',
                'Evapotranspiração (ETc)',
                project.evapotranspiracaoMmDia,
                'mm/dia',
              ),
      if (project.metodoEtc == MetodoEtc.etoVezesKc) ...[
        _number(
          'etoMmDia',
          'Evapotranspiração de referência (ETo)',
          project.etoMmDia,
          'mm/dia',
        ),
        if (project.etoMmDia != null && project.agronomia?.kc != null)
          CalculatedField(
            label: 'ETc estimada (ETo × Kc)',
            value: project.etcMmDia!,
            suffix: 'mm/dia',
            helper:
                'ETo ${_fmt(project.etoMmDia)} × Kc ${_fmt(project.agronomia?.kc)}.',
          )
        else
          Text(
            'Informe a ETo e o Kc da etapa Cultura para estimar a ETc.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
      if (project.metodoEtc == MetodoEtc.blaneyCriddle) ...[
        _number(
          'temperaturaMediaC',
          'Temperatura média do ar',
          project.temperaturaMediaC,
          '°C',
          optional: true,
          zero: true,
        ),
        _latitudeField(project),
        _mesReferenciaField(project),
        if (project.etoBlaneyCriddleMmDia != null)
          CalculatedField(
            label: 'ETo estimada (Blaney–Criddle)',
            value: project.etoBlaneyCriddleMmDia!,
            suffix: 'mm/dia',
            helper: project.agronomia?.kc == null
                ? 'Informe o Kc da etapa Cultura para obter a ETc.'
                : 'ETc (ETo × Kc) = ${_fmt(project.etcMmDia)} mm/dia.',
          )
        else
          Text(
            'Preencha temperatura, latitude e mês; a latitude fica entre '
            '−60° e 60° (negativa no hemisfério sul).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
      _select<OrigemChuva>(
        'Origem da precipitação',
        project.origemChuva,
        OrigemChuva.values,
        (value) {
          setState(() => _confirmedSteps.remove(_step));
          ref.read(basinProjectProvider.notifier).setOrigemChuva(value);
        },
        (value) => switch (value) {
          OrigemChuva.naoInformada => 'Não informada',
          OrigemChuva.efetiva => 'Efetiva adotada',
          OrigemChuva.observada => 'Efetiva observada',
          OrigemChuva.provavel => 'Provável (não é Pef)',
        },
      ),
      if (project.origemChuva == OrigemChuva.provavel)
        Text(
          'Chuva provável foi registrada, mas não pode ser subtraída da ETc '
          'como Pef sem um método explícito.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      _number(
        'precipitacaoEfetivaMmDia',
        project.origemChuva == OrigemChuva.provavel
            ? 'Precipitação provável (não é Pef)'
            : 'Precipitação efetiva (Pef)',
        project.precipitacaoEfetivaMmDia,
        'mm/dia',
        optional: true,
        zero: true,
      ),
      if (intermitente) ...[
        _select<OrigemIrnBasin>(
          'Origem da IRN',
          project.origemIrn,
          OrigemIrnBasin.values,
          (value) {
            setState(() => _confirmedSteps.remove(_step));
            ref.read(basinProjectProvider.notifier).setOrigemIrn(value);
          },
          (value) => value == OrigemIrnBasin.informada
              ? 'Informada'
              : 'Calculada (solo, raízes e demanda)',
        ),
        if (project.origemIrn == OrigemIrnBasin.informada)
          _number(
            'laminaRequeridaMm',
            'Lâmina requerida (IRN)',
            project.laminaRequeridaMm,
            'mm',
          ),
        ..._irnDemandaFields(project),
      ] else ...[
        _turnoRegaPermanenteCard(project),
      ],
    ];
  }

  Widget _latitudeField(BasinProject project) => _BasinInput(
    child: TextFormField(
      key: const ValueKey('latitudeGraus'),
      initialValue: project.latitudeGraus == null
          ? ''
          : project.latitudeGraus.toString().replaceAll('.', ','),
      decoration: const InputDecoration(
        labelText: 'Latitude (sul negativa)',
        suffixText: '°',
        helperText: 'Opcional; entre −60° e 60°',
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]'))],
      validator: (texto) {
        if (texto == null || texto.trim().isEmpty) return null;
        final parsed = double.tryParse(texto.replaceAll(',', '.'));
        if (parsed == null || !parsed.isFinite) return 'Valor inválido.';
        if (parsed.abs() > 60) return 'Use latitude entre −60° e 60°.';
        return null;
      },
      onChanged: (texto) {
        setState(() => _confirmedSteps.remove(_step));
        ref
            .read(basinProjectProvider.notifier)
            .setNumero('latitudeGraus', texto);
      },
    ),
  );

  Widget _mesReferenciaField(BasinProject project) => _BasinInput(
    child: DropdownButtonFormField<int>(
      initialValue: project.mesReferencia,
      decoration: const InputDecoration(labelText: 'Mês de referência'),
      items: _mesesNomes
          .asMap()
          .entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key + 1,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _confirmedSteps.remove(_step));
        ref.read(basinProjectProvider.notifier).setMesReferencia(value);
      },
    ),
  );

  /// Card vivo da IRN: efetiva com origem, as duas IRNs quando divergentes
  /// (G14), volume no tabuleiro (mm · ha → m³) e TR = IRN/(ETc − Pef).
  List<Widget> _irnDemandaFields(BasinProject project) {
    final informada = project.laminaRequeridaMm;
    final calculada = project.irnCalculadaMm;
    final efetiva = project.irnEfetivaMm;
    final tr = project.turnoRegaIrnDias;
    final areaHa = project.areaTabuleiroHa ?? project.areaHectares;
    final volume = efetiva == null || areaHa == null
        ? null
        : efetiva * areaHa * 10;
    final divergente =
        informada != null &&
        calculada != null &&
        (informada - calculada).abs() > 1e-6;
    return [
      IrrigationAuditSection(
        title: 'Demanda e IRN',
        icon: AppIcons.projetoClima,
        pagina: '63',
        children: [
          IrrigationAuditRow(
            'IRN efetiva (${project.origemIrn.displayName.toLowerCase()})',
            efetiva == null
                ? (project.origemIrn == OrigemIrnBasin.informada
                      ? 'Não informado'
                      : 'Não calculado')
                : '${_fmt(efetiva)} mm',
            detail: project.origemIrn == OrigemIrnBasin.informada
                ? 'IRN digitada; prevalece sobre a calculada (G14).'
                : 'IRN = (UCC − UPMP)/10 · Ds · z · f com a demanda do clima.',
          ),
          if (divergente) ...[
            IrrigationAuditRow(
              'IRN informada',
              '${_fmt(informada)} mm',
              detail:
                  'As duas IRNs são exibidas sem sobrescrever; prevalece a '
                  'informada no cálculo (G14).',
              isWarning: true,
              pagina: '63',
            ),
            IrrigationAuditRow(
              'IRN calculada',
              '${_fmt(calculada)} mm',
              detail: 'Somente auditoria nesta situação (G14).',
              pagina: '63',
            ),
          ],
          IrrigationAuditRow(
            'Volume no tabuleiro (IRN × área × 10)',
            volume == null
                ? 'Não calculado'
                : '${_fmt(volume, casas: 1)} m³ '
                      '(${_fmt(efetiva)} mm × ${_fmt(areaHa)} ha)',
            detail: '1 mm·ha equivale a 10 m³ de água.',
          ),
          IrrigationAuditRow(
            'TR = IRN / (ETc − Pef)',
            tr == null
                ? 'Não calculado'
                : '${_fmt(tr, casas: 1)} dias '
                      '(${_fmt(efetiva)} / (${_fmt(project.etcMmDia)} − '
                      '${_fmt(project.precipitacaoEfetivaEfetivaMmDia)}))',
            detail:
                'Turno de rega pela demanda líquida; compare com o intervalo '
                'na etapa de operação (G12).',
            pagina: '63',
          ),
        ],
      ),
    ];
  }

  List<Widget> _operacaoFields(BasinProject project) => [
    _number(
      'vazaoDisponivelLps',
      'Vazão disponível na fonte',
      project.vazaoDisponivelLps,
      'L/s',
    ),
    _number('jornadaHoras', 'Jornada de trabalho', project.jornadaHoras, 'h'),
    _number(
      'mudancaParcelaMin',
      'Mudança de parcela',
      project.mudancaParcelaMin,
      'min',
      zero: true,
    ),
    _number(
      'periodoDias',
      'Período de atendimento (PI)',
      project.periodoDias.toDouble(),
      'dias',
    ),
    _number(
      'tabuleirosPorParcela',
      'Tabuleiros por parcela (NTP)',
      project.tabuleirosPorParcela.toDouble(),
      'un.',
    ),
    if (project.regime == TipoInundacao.intermitente) ...[
      _number(
        'vazaoTotalLs',
        'Vazão total aplicada (opcional)',
        project.vazaoTotalLs,
        'L/s',
        optional: true,
      ),
      _number(
        'rugosidadeN',
        'Rugosidade de Manning (n)',
        project.rugosidadeN,
        '—',
      ),
      _number('rInicial', 'Expoente r inicial', project.rInicial, '—'),
      _number('vmaxMMin', 'Vazão erosiva Vmax', project.vmaxMMin, 'm/min'),
      _number(
        'intervaloDias',
        'Intervalo entre irrigações',
        project.intervaloDias?.toDouble(),
        'dias',
      ),
      TextFormField(
        key: const ValueKey('candidatasVazao'),
        initialValue: project.candidatasVazaoLs
            .map((item) => item.toString())
            .join(', '),
        decoration: const InputDecoration(
          labelText: 'Vazões candidatas (opcional, em L/s)',
          helperText:
              'Separe por vírgula; a aula escolhe a de maior Ea entre as '
              'viáveis (p. 60), sem afirmar ótimo global.',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\s]')),
        ],
        onChanged: (value) {
          setState(() => _confirmedSteps.remove(_step));
          ref.read(basinProjectProvider.notifier).setCandidatasVazao(value);
        },
      ),
      ..._vazaoUnidadesFields(project),
      const IrrigationFormulaCard(
        formula: 'TPP = ti + tm · NPD = ⌊TDF / TPP⌋',
        description:
            'Tempo por parcela e número de parcelas diárias (p. 61); ti vem '
            'da dimensão e tm é a mudança de parcela acima.',
        pagina: '61',
      ),
      const IrrigationFormulaCard(
        formula: 'APP = Atotal / (NPD · PI)',
        description:
            'Área por parcela no período de atendimento (p. 62); a simulação '
            'anexa também NTT = NTP · NPD · PI e Q = W0 · NTP · Q0.',
        pagina: '62',
      ),
      ..._g12AvisoFields(project),
      ..._selecaoCandidatasFields(project),
    ],
    ..._checagemFields(project),
  ];

  /// Aviso G12 (p. 63): o intervalo programado deve cobrir o turno de rega
  /// pela IRN; a comparação é só orientativa, a decisão é do usuário.
  List<Widget> _g12AvisoFields(BasinProject project) {
    final intervalo = project.intervaloDias;
    final tr = project.turnoRegaIrnDias;
    if (intervalo == null || tr == null || intervalo >= tr) return const [];
    return [
      IrrigationAuditRow(
        'Intervalo × turno de rega (G12)',
        '$intervalo dias vs ${_fmt(tr, casas: 1)} dias',
        detail:
            'O intervalo programado é menor que o turno de rega pela IRN; a '
            'aula recomenda intervalo ≥ IRN/(ETc − Pef).',
        isWarning: true,
        pagina: '63',
      ),
    ];
  }

  /// Prévia da seleção de melhor Ea entre as vazões candidatas (p. 60);
  /// espelha BasinSimulationCoordinator._selecionarVazao sem tocá-la.
  List<Widget> _selecaoCandidatasFields(BasinProject project) {
    final candidatas = project.candidatasVazaoLs;
    final largura = project.larguraM;
    final comprimento = project.comprimentoM;
    final n = project.rugosidadeN;
    final k = project.k;
    final a = project.a;
    final vib = project.vibMMin;
    final irnM = project.laminaMediaPlanaltoM;
    final altura = project.alturaDiqueM;
    final margem = project.margemLivreM;
    if (candidatas.isEmpty ||
        largura == null ||
        comprimento == null ||
        n == null ||
        k == null ||
        a == null ||
        vib == null ||
        irnM == null ||
        altura == null ||
        margem == null) {
      return const [];
    }
    final solo = Infiltracao(k, a, vib);
    double? melhorEa;
    double? melhorLs;
    final linhas = <Widget>[];
    for (final qLs in candidatas) {
      final q0 = qLs * 60 / 1000 / largura;
      double? ea;
      String status;
      try {
        final atual = dimensionar(
          solo,
          l: comprimento,
          n: n,
          irn: irnM,
          vmax: project.vmaxMMin,
          vazao: q0,
          rInicial: project.rInicial,
        );
        if (!diqueComporta(altura, atual.y0M, margem)) {
          status = 'Reprovada: y0 com a margem livre excede a taipa (p. 35).';
        } else if (atual.eficienciaPercent > 100) {
          status = 'Reprovada: Ea maior que 100%.';
        } else {
          ea = atual.eficienciaPercent;
          status = 'Viável.';
          if (melhorEa == null || ea > melhorEa) {
            melhorEa = ea;
            melhorLs = qLs;
          }
        }
      } on ArgumentError catch (erro) {
        status =
            'Reprovada: ${erro.message ?? 'vazão fora do domínio'} (p. 54).';
      } on StateError {
        status = 'Reprovada: sem convergência na dimensão.';
      }
      linhas.add(
        IrrigationAuditRow(
          'Q = ${_fmt(qLs, casas: 1)} L/s',
          ea == null ? '—' : 'Ea = ${_fmt(ea, casas: 1)}%',
          detail: status,
          isWarning: ea == null,
          pagina: '60',
        ),
      );
    }
    return [
      IrrigationAuditSection(
        title: 'Seleção de vazão entre candidatas',
        icon: AppIcons.projetoOperacao,
        pagina: '60',
        children: [
          ...linhas,
          if (melhorEa != null && melhorLs != null)
            IrrigationAuditRow(
              'Vazão selecionada (maior Ea)',
              '${_fmt(melhorLs, casas: 1)} L/s · Ea ${_fmt(melhorEa, casas: 1)}%',
              detail:
                  'Melhor Ea entre as candidatas viáveis; a aula não garante '
                  'ótimo global.',
              pagina: '60',
            ),
        ],
      ),
    ];
  }

  /// Unidades por unidade de largura (G11) e saldo de vazão da fonte.
  List<Widget> _vazaoUnidadesFields(BasinProject project) {
    final aplicada = project.vazaoAplicadaLs;
    final maxima = project.q0MaxLsTotal;
    final largura = project.larguraM;
    final q0Unit = aplicada == null || largura == null || largura <= 0
        ? null
        : aplicada * 60 / 1000 / largura;
    final q0MaxUnit = maxima == null || largura == null || largura <= 0
        ? null
        : maxima * 60 / 1000 / largura;
    final disponivel = project.vazaoDisponivelLps;
    final saldo = aplicada == null || disponivel == null
        ? null
        : disponivel - aplicada;
    return [
      if (q0Unit != null && q0MaxUnit != null)
        IrrigationFormulaCard(
          formula:
              'Q0 = ${_fmt(q0Unit, casas: 4)} m³/(min·m) · '
              'Q0max = ${_fmt(q0MaxUnit, casas: 4)} m³/(min·m)',
          description:
              'Totais: ${_fmt(aplicada, casas: 1)} L/s aplicados e '
              '${_fmt(maxima, casas: 1)} L/s não erosivos (p. 54). '
              'A hidráulica da aula é por unidade de largura (G11).',
          pagina: '54',
        ),
      ..._y0Fields(project),
      if (saldo != null)
        IrrigationAuditRow(
          'Saldo de vazão (disponível − aplicada)',
          '${_fmt(saldo, casas: 1)} L/s',
          detail: saldo < 0
              ? 'A aplicação supera a vazão disponível da fonte (G3).'
              : 'A fonte cobre a vazão aplicada ao tabuleiro.',
          isWarning: saldo < 0,
          pagina: '73',
        ),
    ];
  }

  /// Profundidade normal na entrada y0 (G11, p. 54) pela mesma vazão
  /// aplicada; null quando falta geometria ou a lei de avanço rejeita.
  List<Widget> _y0Fields(BasinProject project) {
    final aplicada = project.vazaoAplicadaLs;
    final largura = project.larguraM;
    final n = project.rugosidadeN;
    final l = project.comprimentoM;
    final q0Unit = aplicada == null || largura == null || largura <= 0
        ? null
        : aplicada * 60 / 1000 / largura;
    if (q0Unit == null || n == null || l == null) return const [];
    try {
      final y0 = profundidade(q0Unit, n, l);
      return [
        IrrigationFormulaCard(
          formula:
              'y0 = ${_fmt(y0, casas: 4)} m (profundidade normal na entrada)',
          description:
              'A profundidade avança pela lei de avanço da vazão aplicada; a '
              'aula trabalha por unidade de largura.',
          pagina: '54',
        ),
      ];
    } on ArgumentError {
      return const [];
    }
  }

  List<Widget> _planejamentoIntermitenteFields(BasinProject project) => [
    ExpansionTile(
      leading: const Icon(AppIcons.projetoSolo),
      title: const Text('Auditoria F02 — ρ1 e ρ2 (G6)'),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Text(
          'ρ1 e ρ2 são exibidos apenas como auditoria de leitura da fonte; '
          'nunca entram nos cálculos da simulação.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _number(
          'rho1F02',
          'ρ1 (auditoria)',
          project.rho1F02,
          '—',
          optional: true,
        ),
        _number(
          'rho2F02',
          'ρ2 (auditoria)',
          project.rho2F02,
          '—',
          optional: true,
        ),
        _number(
          'vmaxF02',
          'Vmax (auditoria)',
          project.vmaxF02,
          'm/min',
          optional: true,
        ),
      ],
    ),
  ];

  /// Status da checagem operacional obrigatória (G3) para o projeto atual;
  /// sem geometria/vazões completas não há o que comparar.
  List<Widget> _checagemFields(BasinProject project) {
    final checagem = _checagemPreview(project);
    if (checagem == null) {
      return const [
        IrrigationFormulaCard(
          formula: 'G3: Q planejado ≤ Q disponível · L × largura ≤ área',
          description:
              'Informe geometria, vazão disponível e área declarada para '
              'exibir a checagem operacional obrigatória.',
        ),
      ];
    }
    return [BasinOperationalCheckSection(checagem: checagem)];
  }

  BasinChecagemOperacional? _checagemPreview(BasinProject project) {
    final areaTabuleiro = project.areaTabuleiroM2;
    final areaDeclarada =
        project.areaTotalM2 ??
        project.areaUtilM2 ??
        (project.areaHectares == null ? null : project.areaHectares! * 10000);
    final disponivel = project.vazaoDisponivelLps;
    if (areaTabuleiro == null ||
        areaDeclarada == null ||
        areaDeclarada <= 0 ||
        disponivel == null ||
        disponivel <= 0) {
      return null;
    }
    final planejada = project.regime == TipoInundacao.intermitente
        ? project.vazaoAplicadaLs
        : _fluxoPermanente(project)?.qeLS;
    if (planejada == null || planejada <= 0) return null;
    try {
      return const BasinPlanning().checarOperacao(
        vazaoPlanejadaLs: planejada,
        vazaoDisponivelLs: disponivel,
        areaTabuleiroM2: areaTabuleiro,
        areaDeclaradaM2: areaDeclarada,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Turno de rega TR do regime contínuo (p. 67); null se faltar entrada.
  double? _turnoRegaPermanente(BasinProject project) {
    final dtaMmCm = project.dtaMmCm;
    final fator = project.fatorDisponibilidade;
    final zMm = project.profundidadeCamadaMm;
    final etMmDia = project.etcMmDia;
    if (dtaMmCm == null || fator == null || zMm == null || etMmDia == null) {
      return null;
    }
    try {
      return turnoRega(dtaMmCm, fator, zMm / 10, etMmDia);
    } on ArgumentError {
      return null;
    }
  }

  /// Vazões Qe (enchimento) e Qm (manutenção) do regime contínuo (p. 67);
  /// null quando o projeto ainda está incompleto.
  BasinContinuaResult? _fluxoPermanente(BasinProject project) {
    final porosidade = project.porosidade;
    final zMm = project.profundidadeCamadaMm;
    final laminaMm = project.laminaSuperficialMm;
    final etMmDia = project.etcMmDia;
    final kMmDia = project.condutividadeHidraulicaMmDia;
    final areaHa = project.areaHectares;
    if (porosidade == null ||
        zMm == null ||
        laminaMm == null ||
        etMmDia == null ||
        kMmDia == null ||
        areaHa == null) {
      return null;
    }
    final tr = _turnoRegaPermanente(project);
    if (tr == null) return null;
    try {
      return continua(
        porosidade: porosidade,
        zMm: zMm,
        laminaMm: laminaMm,
        etMmDia: etMmDia,
        kMmDia: kMmDia,
        areaHa: areaHa,
        turnoDias: tr < 1 ? 1.0 : tr,
      );
    } on ArgumentError {
      return null;
    } on StateError {
      return null;
    }
  }

  List<Widget> _planejamentoPermanenteFields(BasinProject project) {
    final tr = _turnoRegaPermanente(project);
    final fluxo = _fluxoPermanente(project);
    return [
      const IrrigationFormulaCard(
        formula: 'TR = DTA · Z · f / ET → Qe · Qm = 0,116 (ET + K0) A',
        description:
            'No regime contínuo o planejamento é o turno de rega (TR): Qe '
            'forma a lâmina de enchimento e Qm repõe evapotranspiração e '
            'percolação (p. 67).',
      ),
      IrrigationAuditSection(
        title: 'Turno de rega e vazões',
        pagina: '67',
        icon: AppIcons.projetoOperacao,
        children: [
          _review(
            'TR (turno de rega)',
            tr == null ? '—' : '${_fmt(tr, casas: 1)} dias',
          ),
          _review(
            'Qe (enchimento)',
            fluxo == null ? '—' : '${_fmt(fluxo.qeLS)} L/s',
          ),
          _review(
            'Qm (manutenção)',
            fluxo == null ? '—' : '${_fmt(fluxo.qmLS)} L/s',
          ),
        ],
      ),
    ];
  }

  static const _mesesNomes = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  List<Widget> _revisaoFields(BasinProject project) {
    final agro = project.agronomia;
    final irnInformada = project.laminaRequeridaMm;
    final irnCalculada = project.irnCalculadaMm;
    final irnEfetiva = project.irnEfetivaMm;
    final divergente =
        irnInformada != null &&
        irnCalculada != null &&
        (irnInformada - irnCalculada).abs() > 1e-6;
    return [
      IrrigationAuditSection(
        title: 'Regime e infiltração',
        icon: AppIcons.inundacao,
        children: [
          _review(
            'Regime',
            project.regime == TipoInundacao.intermitente
                ? 'Intermitente (sem circulação)'
                : 'Permanente (com circulação)',
          ),
          _review(
            'Cenário de infiltração',
            project.cenarioInfiltracao.displayName,
          ),
          _review('Textura do solo', project.texturaSolo?.displayName ?? '—'),
          _review('k', _fmt(project.k)),
          _review('a', _fmt(project.a)),
          _review('VIB', _fmt(project.vibMMin)),
          _review('Rugosidade n', _fmt(project.rugosidadeN)),
          _review('ρ1 (auditoria, G6)', _fmt(project.rho1F02)),
          _review('ρ2 (auditoria, G6)', _fmt(project.rho2F02)),
        ],
      ),
      IrrigationAuditSection(
        title: 'Área, geometria e taipa',
        icon: AppIcons.projetoArea,
        children: [
          _review(
            'Área da unidade',
            project.areaTotalM2 == null
                ? '—'
                : '${_fmt(project.comprimentoAreaM)} × '
                      '${_fmt(project.larguraAreaM)} m '
                      '(${_fmt(project.areaTotalM2! / 10000)} ha)',
          ),
          _review(
            'Tabuleiro',
            project.areaTabuleiroM2 == null
                ? '—'
                : 'L ${_fmt(project.comprimentoM)} m × '
                      '${_fmt(project.larguraM)} m '
                      '(${_fmt(project.areaTabuleiroM2)} m²)',
          ),
          _review('Declividade', _fmt(project.declividade, casas: 5)),
          _review(
            'Lâmina média Lm',
            _fmt(project.laminaMediaPlanaltoM),
            pagina: '34–35',
          ),
          _review(
            'Δz admissível (2/3 Lm)',
            _fmt(project.desnivelAdmissivelM),
            pagina: '20',
          ),
          _review('Δz real', _fmt(project.desnivelRealM), pagina: '20'),
          _review(
            'L máximo pela regra 2/3',
            _fmt(project.comprimentoMaximoDesnivelM),
            pagina: '20',
          ),
          _review(
            'Taipa',
            'base ${_fmt(project.baseDiqueM)} m · altura '
                '${_fmt(project.alturaDiqueM)} m · margem '
                '${_fmt(project.margemLivreM)} m',
            pagina: '35',
          ),
        ],
      ),
      if (project.regime == TipoInundacao.intermitente)
        IrrigationAuditSection(
          title: 'Intermitente',
          icon: AppIcons.curvaAvanco,
          children: [
            _review(
              'IRN efetiva (${project.origemIrn.displayName.toLowerCase()})',
              irnEfetiva == null
                  ? (project.origemIrn == OrigemIrnBasin.informada
                        ? 'Não informado'
                        : 'Não calculado')
                  : '${_fmt(irnEfetiva)} mm',
              pagina: '63',
            ),
            if (divergente) ...[
              _review(
                'IRN informada (prevalece, G14)',
                '${_fmt(irnInformada)} mm',
                pagina: '63',
              ),
              _review(
                'IRN calculada (auditoria, G14)',
                '${_fmt(irnCalculada)} mm',
                pagina: '63',
              ),
            ],
            _review(
              'Lâmina inicial Li',
              _fmt(project.laminaInicialMm),
              pagina: '34–35',
            ),
            _review(
              'Lâmina final Lf',
              _fmt(project.laminaFinalMm),
              pagina: '34–35',
            ),
            _review(
              'Intervalo (dias)',
              _fmt(project.intervaloDias?.toDouble()),
            ),
            _review('Vazão aplicada', _fmt(project.vazaoAplicadaLs)),
            _review('Vazão disponível', _fmt(project.vazaoDisponivelLps)),
            _review(
              'Q0max não erosiva',
              _fmt(project.q0MaxLsTotal),
              pagina: '54',
            ),
            _review('Vmax', _fmt(project.vmaxMMin), pagina: '54'),
            _review('Expoente r inicial', _fmt(project.rInicial)),
            _review(
              'Candidatas (L/s)',
              project.candidatasVazaoLs.isEmpty
                  ? '—'
                  : project.candidatasVazaoLs.join(', '),
              pagina: '60',
            ),
          ],
        )
      else ...[
        IrrigationAuditSection(
          title: 'Permanente',
          icon: AppIcons.inundacao,
          children: [
            _review('Área irrigada (ha)', _fmt(project.areaHectares)),
            _review('Lâmina superficial', _fmt(project.laminaSuperficialMm)),
            _review('Q disponível', _fmt(project.vazaoDisponivelLps)),
            _review(
              'TR (turno de rega)',
              _fmt(_turnoRegaPermanente(project), casas: 1),
              pagina: '67',
            ),
            _review(
              'Qe (enchimento)',
              _fmt(_fluxoPermanente(project)?.qeLS),
              pagina: '67',
            ),
            _review(
              'Qm (manutenção)',
              _fmt(_fluxoPermanente(project)?.qmLS),
              pagina: '67',
            ),
          ],
        ),
      ],
      IrrigationAuditSection(
        title: 'Cultura e sistema radicular',
        icon: AppIcons.projetoCultura,
        pagina: '63',
        children: [
          _review('Cultura', project.culturaEfetiva ?? 'Não informado'),
          _review('Kc', agro?.kc == null ? 'Não informado' : _fmt(agro?.kc)),
          _review(
            'Profundidade radicular (z)',
            agro?.profundidadeRaizesCm == null
                ? 'Não informado'
                : '${_fmt(agro?.profundidadeRaizesCm)} cm',
          ),
          _review(
            'Fração de água disponível (f)',
            agro?.fracaoDisponivel == null
                ? 'Não informado'
                : _fmt(agro?.fracaoDisponivel),
          ),
          _review(
            'UCC',
            agro?.uccPercentual == null
                ? 'Não informado'
                : '${_fmt(agro?.uccPercentual)} %',
          ),
          _review(
            'UPMP',
            agro?.upmpPercentual == null
                ? 'Não informado'
                : '${_fmt(agro?.upmpPercentual)} %',
          ),
          _review(
            'Ds',
            agro?.densidadeGcm3 == null
                ? 'Não informado'
                : '${_fmt(agro?.densidadeGcm3)} g/cm³',
          ),
          if (project.regime == TipoInundacao.permanente) ...[
            _review(
              'Porosidade',
              project.porosidade == null
                  ? 'Não informado'
                  : _fmt(project.porosidade),
            ),
            _review(
              'Z (profundidade da camada)',
              project.profundidadeCamadaMm == null
                  ? 'Não informado'
                  : '${_fmt(project.profundidadeCamadaMm)} mm',
            ),
            _review(
              'DTA',
              project.dtaMmCm == null
                  ? 'Não informado'
                  : '${_fmt(project.dtaMmCm)} mm/cm',
            ),
            _review(
              'f (camada, regime contínuo)',
              project.fatorDisponibilidade == null
                  ? 'Não informado'
                  : _fmt(project.fatorDisponibilidade),
            ),
            _review(
              'K0',
              project.condutividadeHidraulicaMmDia == null
                  ? 'Não informado'
                  : '${_fmt(project.condutividadeHidraulicaMmDia)} mm/dia',
            ),
          ],
        ],
      ),
      IrrigationAuditSection(
        title: 'Clima e demanda',
        icon: AppIcons.projetoClima,
        pagina: '63',
        children: [
          _review('Método da ETc', switch (project.metodoEtc) {
            MetodoEtc.adotada => 'ETc adotada (digitação)',
            MetodoEtc.etoVezesKc => 'ETo × Kc',
            MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
          }),
          if (project.metodoEtc == MetodoEtc.etoVezesKc)
            _review(
              'ETo',
              project.etoMmDia == null
                  ? 'Não informado'
                  : '${_fmt(project.etoMmDia)} mm/dia',
            ),
          if (project.metodoEtc == MetodoEtc.blaneyCriddle) ...[
            _review(
              'Temperatura média',
              project.temperaturaMediaC == null
                  ? 'Não informado'
                  : '${_fmt(project.temperaturaMediaC)} °C',
            ),
            _review(
              'Latitude',
              project.latitudeGraus == null
                  ? 'Não informado'
                  : '${_fmt(project.latitudeGraus)}°',
            ),
            _review(
              'Mês de referência',
              project.mesReferencia == null
                  ? 'Não informado'
                  : _mesesNomes[project.mesReferencia! - 1],
            ),
            _review(
              'ETo (Blaney–Criddle)',
              project.etoBlaneyCriddleMmDia == null
                  ? 'Não calculado'
                  : '${_fmt(project.etoBlaneyCriddleMmDia)} mm/dia',
            ),
          ],
          _review(
            'ETc efetiva',
            project.etcMmDia == null
                ? 'Não calculado'
                : '${_fmt(project.etcMmDia)} mm/dia',
          ),
          _review('Origem da precipitação', switch (project.origemChuva) {
            OrigemChuva.naoInformada => 'Não informada',
            OrigemChuva.efetiva => 'Efetiva adotada',
            OrigemChuva.observada => 'Efetiva observada',
            OrigemChuva.provavel => 'Provável (não convertida em efetiva)',
          }),
          _review(
            'Pef (precipitação efetiva)',
            project.precipitacaoEfetivaEfetivaMmDia == null
                ? 'Não informado'
                : '${_fmt(project.precipitacaoEfetivaEfetivaMmDia)} mm/dia',
          ),
          if (project.regime == TipoInundacao.intermitente)
            _review(
              'Origem da IRN',
              project.origemIrn == OrigemIrnBasin.informada
                  ? 'Informada'
                  : 'Calculada a partir de solo, raízes e demanda climática',
            ),
        ],
      ),
      IrrigationAuditSection(
        title: 'Operação',
        icon: AppIcons.projetoOperacao,
        children: [
          _review('Jornada', '${_fmt(project.jornadaHoras)} h'),
          _review(
            'Mudança de parcela',
            '${_fmt(project.mudancaParcelaMin)} min',
          ),
          _review('PI', '${project.periodoDias} dias'),
          _review('NTP', '${project.tabuleirosPorParcela}'),
        ],
      ),
      BasinReferencePanel(projeto: project),
    ];
  }

  // ---------------------------------------------------------------------------
  // Controles e ações.
  // ---------------------------------------------------------------------------

  Widget _navigationRow(
    BasinProject project,
    BorderNotice? notice,
    bool bloqueia,
    bool todasConfirmadas,
  ) {
    final colors = Theme.of(context).colorScheme;
    final ultimo = _step >= _revisaoStep;
    final podeCalcular = !bloqueia && todasConfirmadas && !_calculando;
    final voltar = _step > 0
        ? OutlinedButton.icon(
            onPressed: () => setState(() => _step--),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Voltar'),
          )
        : null;
    final confirmar = _confirmedSteps.contains(_step)
        ? Chip(
            avatar: Icon(Icons.check_rounded, size: 16, color: colors.primary),
            label: const Text('Confirmada'),
            backgroundColor: colors.primaryContainer,
            side: BorderSide.none,
          )
        : OutlinedButton.icon(
            onPressed: () {
              final valid = _formKey.currentState?.validate() ?? false;
              if (!valid) return;
              setState(() => _confirmedSteps.add(_step));
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirmar'),
          );
    final proximo = FilledButton.icon(
      onPressed: _calculando
          ? null
          : ultimo
          ? (podeCalcular ? () => _calcular(project) : null)
          : () => setState(() => _step++),
      icon: _calculando
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              ultimo ? AppIcons.projetoCalcular : Icons.arrow_forward_rounded,
            ),
      label: Text(
        _calculando
            ? 'Calculando…'
            : ultimo
            ? 'Calcular projeto'
            : 'Próximo',
      ),
    );
    final acoes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!ultimo) ...[confirmar, const SizedBox(width: 8)],
        proximo,
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (voltar == null) {
          return Align(alignment: Alignment.centerRight, child: acoes);
        }
        if (constraints.maxWidth >= 420) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [voltar, acoes],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            voltar,
            const SizedBox(height: IrrigationSpacing.compact),
            Align(alignment: Alignment.centerRight, child: acoes),
          ],
        );
      },
    );
  }

  Future<void> _calcular(BasinProject project) async {
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

  // ---------------------------------------------------------------------------
  // Helpers de layout e campos.
  // ---------------------------------------------------------------------------

  Widget _layoutFields(List<Widget> fields) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 650;
      if (!wide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in fields) ...[
              field,
              const SizedBox(height: IrrigationSpacing.field),
            ],
          ],
        );
      }
      return Wrap(
        spacing: IrrigationSpacing.section,
        runSpacing: IrrigationSpacing.field,
        children: [
          for (final field in fields)
            SizedBox(
              width: field is _BasinInput
                  ? (constraints.maxWidth - IrrigationSpacing.section) / 2
                  : constraints.maxWidth,
              child: field,
            ),
        ],
      );
    },
  );

  Widget _number(
    String field,
    String label,
    double? value,
    String unit, {
    bool optional = false,
    bool zero = false,
    String? key,
  }) => _BasinInput(
    child: TextFormField(
      key: ValueKey(key ?? field),
      initialValue: value == null ? '' : value.toString().replaceAll('.', ','),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        helperText: optional ? 'Opcional' : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]'))],
      validator: (texto) {
        if (texto == null || texto.trim().isEmpty) {
          return optional ? null : 'Informe $label.';
        }
        final parsed = double.tryParse(texto.replaceAll(',', '.'));
        if (parsed == null || !parsed.isFinite) return 'Valor inválido.';
        if (zero ? parsed < 0 : parsed <= 0) {
          return zero ? 'Não aceite valores negativos.' : 'Maior que zero.';
        }
        if (field == 'a' && parsed >= 1) return 'Exige 0 < a < 1.';
        if (field == 'porosidade' && parsed > 1) return 'Máximo 1.';
        if (field == 'fatorDisponibilidade' && parsed > 1) return 'Máximo 1.';
        if (field == 'umidadeGraos' && parsed > 1) return 'Máximo 1.';
        if (field == 'indiceColheita' && parsed > 1) return 'Máximo 1.';
        if (field == 'fracaoDisponivel' && parsed > 1) return 'Máximo 1.';
        return null;
      },
      onChanged: (texto) {
        setState(() => _confirmedSteps.remove(_step));
        ref.read(basinProjectProvider.notifier).setNumero(field, texto);
      },
    ),
  );

  Widget _select<T>(
    String label,
    T value,
    List<T> options,
    ValueChanged<T> onChanged,
    String Function(T) title,
  ) => _BasinInput(
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(
              title(option),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
      onChanged: (option) {
        if (option == null) return;
        setState(() => _confirmedSteps.remove(_step));
        onChanged(option);
      },
    ),
  );

  Widget _review(String label, String value, {String? pagina}) =>
      IrrigationAuditRow(label, value, pagina: pagina);

  String _fmt(double? value, {int casas = 4}) {
    if (value == null) return '—';
    var texto = value.toStringAsFixed(casas);
    if (texto.contains('.')) {
      texto = texto.replaceFirst(RegExp(r'0+$'), '');
      texto = texto.replaceFirst(RegExp(r'\.$'), '');
    }
    return texto;
  }
}

class _BasinInput extends StatelessWidget {
  const _BasinInput({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      child,
      const SizedBox(height: IrrigationSpacing.field),
    ],
  );
}
