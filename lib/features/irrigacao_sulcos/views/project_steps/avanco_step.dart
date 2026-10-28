import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/ensaios_sulco.dart'
    show PontoEnsaioAvanco;
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';

// ──────────────────────── Step 5: Origem do avanço ────────────────────────

class OrigemAvancoStep extends ConsumerWidget {
  const OrigemAvancoStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final EstadoParametrosSulco state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StepBentoCard(
    title: 'Origem do avanço',
    subtitle:
        'Escolha como a curva de avanço é obtida e informe os tempos medidos.',
    icon: AppIcons.curvaAvanco,
    accent: accent,
    child: Column(
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
              .read(provedorParametrosSulco.notifier)
              .definirOrigemAvanco(origem.first),
        ),
        const SizedBox(height: 16),
        StepFieldGrid(
          wide: wide,
          fields: [
            if (state.origemAvanco == OrigemAvanco.estimativa) ...[
              StepField(
                name: 'coeficienteAvancoK',
                label: 'Coeficiente k da curva',
                value: state.coeficienteAvancoK,
                suffix: 'min/mᵇ',
              ),
              StepField(
                name: 'expoenteAvancoB',
                label: 'Expoente b da curva',
                value: state.expoenteAvancoB,
              ),
              StepField(
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
          StepField(
            name: 'vazaoEnsaioAvancoLs',
            label: 'Vazão medida no ensaio de avanço',
            value: state.vazaoEnsaioAvancoLs ?? 0,
            suffix: 'L/s',
            allowZero: true,
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: state.condicoesEnsaioAvanco,
            onChanged: ref
                .read(provedorParametrosSulco.notifier)
                .definirCondicoesEnsaioAvanco,
            decoration: const InputDecoration(
              labelText: 'Solo, seção e orientação ensaiados',
              helperText:
                  'Descreva as condições em que a curva de avanço foi medida.',
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<MetodoAjusteAvanco>(
            segments: const [
              ButtonSegment(
                value: MetodoAjusteAvanco.doisPontos,
                label: Text('Dois pontos'),
              ),
              ButtonSegment(
                value: MetodoAjusteAvanco.minimosQuadrados,
                label: Text('Mínimos quadrados'),
              ),
            ],
            selected: {state.metodoCurvaAvanco},
            onSelectionChanged: (value) => ref
                .read(provedorParametrosSulco.notifier)
                .definirMetodoCurvaAvanco(value.first),
          ),
          const SizedBox(height: 10),
          PontosAvancoEditor(
            pontos: state.pontosEnsaioAvanco,
            comprimentoM: state.comprimento,
            metodo: state.metodoCurvaAvanco,
            onChanged: ref
                .read(provedorParametrosSulco.notifier)
                .definirPontosEnsaioAvanco,
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => ref
              .read(provedorParametrosSulco.notifier)
              .definirEnsaioErosao(
                state.ensaioErosao == null
                    ? EnsaioErosao(
                        vazaoLs: state.vazao,
                        condicoes: '',
                        erosaoObservada: false,
                      )
                    : null,
              ),
          child: Text(
            state.ensaioErosao == null
                ? 'Registrar ensaio de erosão'
                : 'Remover ensaio de erosão',
          ),
        ),
        if (state.ensaioErosao case final ensaio?) ...[
          const SizedBox(height: 10),
          TextFormField(
            initialValue: ensaio.vazaoLs.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => ref
                .read(provedorParametrosSulco.notifier)
                .definirEnsaioErosao(
                  EnsaioErosao(
                    vazaoLs:
                        double.tryParse(value.replaceAll(',', '.')) ??
                        double.nan,
                    condicoes: ensaio.condicoes,
                    erosaoObservada: ensaio.erosaoObservada,
                  ),
                ),
            decoration: const InputDecoration(
              labelText: 'Vazão ensaiada (L/s)',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: ensaio.condicoes,
            onChanged: (value) => ref
                .read(provedorParametrosSulco.notifier)
                .definirEnsaioErosao(
                  EnsaioErosao(
                    vazaoLs: state.ensaioErosao!.vazaoLs,
                    condicoes: value,
                    erosaoObservada: state.ensaioErosao!.erosaoObservada,
                  ),
                ),
            decoration: const InputDecoration(
              labelText: 'Condições do ensaio de erosão',
              helperText: 'Descreva solo, seção e orientação do mesmo local.',
            ),
          ),
          SwitchListTile(
            title: const Text('Erosão observada em campo'),
            value: ensaio.erosaoObservada,
            onChanged: (value) => ref
                .read(provedorParametrosSulco.notifier)
                .definirEnsaioErosao(
                  EnsaioErosao(
                    vazaoLs: state.ensaioErosao!.vazaoLs,
                    condicoes: state.ensaioErosao!.condicoes,
                    erosaoObservada: value,
                  ),
                ),
          ),
        ],
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
              .read(provedorParametrosSulco.notifier)
              .definirHipoteseRecessao(value.first),
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
        if (state.hipoteseRecessao == HipoteseRecessao.medidaPorEstaca) ...[
          const SizedBox(height: 10),
          RecessaoEditor(
            pontos: state.medicoesRecessao,
            onChanged: ref
                .read(provedorParametrosSulco.notifier)
                .definirMedicoesRecessao,
          ),
          Text(
            'Informe instantes absolutos desde o início da aplicação. '
            'A depleção é desprezada. A curva será interpolada entre '
            'estacas e oportunidades negativas serão rejeitadas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class PontosAvancoEditor extends StatefulWidget {
  const PontosAvancoEditor({
    super.key,
    required this.pontos,
    required this.comprimentoM,
    required this.metodo,
    required this.onChanged,
  });

  final List<PontoEnsaioAvanco> pontos;
  final double comprimentoM;
  final MetodoAjusteAvanco metodo;
  final ValueChanged<List<PontoEnsaioAvanco>> onChanged;

  @override
  State<PontosAvancoEditor> createState() => PontosAvancoEditorState();
}

class PontosAvancoEditorState extends State<PontosAvancoEditor> {
  late final TextEditingController _countController;
  late final TextEditingController _spacingController;
  late final TextEditingController _timesController;

  List<PontoEnsaioAvanco> get _positivePoints => widget.pontos
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
    final points = <PontoEnsaioAvanco>[
      const PontoEnsaioAvanco(distanciaM: 0, tempoMin: 0),
    ];
    for (var index = 0; index < count && index < times.length; index++) {
      final time = times[index];
      if (time == null) continue;
      points.add(
        PontoEnsaioAvanco(distanciaM: (index + 1) * spacing, tempoMin: time),
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
      StepFieldGrid(
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
        widget.metodo == MetodoAjusteAvanco.doisPontos
            ? 'Usa o último tempo medido e o tempo na metade do ensaio. Se não houver estaca exatamente no meio, o tempo intermediário é interpolado entre as estacas vizinhas.'
            : 'A regressão log-log usa todas as estacas com distância e tempo positivos; a origem é preservada nos dados, mas excluída dos logaritmos.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class EntradaSaidaEditor extends StatefulWidget {
  const EntradaSaidaEditor({
    super.key,
    required this.pontos,
    required this.onChanged,
  });
  final List<MedicaoEntradaSaida> pontos;
  final ValueChanged<List<MedicaoEntradaSaida>> onChanged;

  @override
  State<EntradaSaidaEditor> createState() => EntradaSaidaEditorState();
}

class EntradaSaidaEditorState extends State<EntradaSaidaEditor> {
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

class RecessaoEditor extends StatefulWidget {
  const RecessaoEditor({
    super.key,
    required this.pontos,
    required this.onChanged,
  });
  final List<MedicaoRecessao> pontos;
  final ValueChanged<List<MedicaoRecessao>> onChanged;

  @override
  State<RecessaoEditor> createState() => RecessaoEditorState();
}

class RecessaoEditorState extends State<RecessaoEditor> {
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
