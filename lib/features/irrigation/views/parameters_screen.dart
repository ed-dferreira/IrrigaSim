import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/controllers/parameters_controller.dart';

class ParametersScreen extends ConsumerStatefulWidget {
  const ParametersScreen({super.key});

  @override
  ConsumerState<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends ConsumerState<ParametersScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parametersProvider);
    final accent = _methodColor(state.metodo);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    ref.listen(parametersProvider, (previous, next) {
      if (next.resultado != null && previous?.resultado == null) {
        context.push('/home/irrigation/results');
      }
      if (next.erro != null && next.erro != previous?.erro) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.erro!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Nova simulação')),
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
                    _Hero(method: state.metodo, accent: accent),
                    if (state.metodo == MetodoIrrigacao.inundacao) ...[
                      const SizedBox(height: 16),
                      _BentoCard(
                        title: 'Regime de inundação',
                        subtitle:
                            'Escolha o modelo antes de informar os dados.',
                        icon: Icons.swap_calls_rounded,
                        accent: accent,
                        child: SegmentedButton<TipoInundacao>(
                          segments: TipoInundacao.values
                              .map(
                                (tipo) => ButtonSegment(
                                  value: tipo,
                                  label: Text(tipo.displayName),
                                ),
                              )
                              .toList(),
                          selected: {state.tipoInundacao},
                          onSelectionChanged: (value) => ref
                              .read(parametersProvider.notifier)
                              .setTipoInundacao(value.first),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (state.metodo == MetodoIrrigacao.inundacao &&
                        state.tipoInundacao == TipoInundacao.permanente) ...[
                      _GeometryFields(state: state, accent: accent, wide: wide),
                      const SizedBox(height: 16),
                      _PermanentFields(
                        state: state,
                        accent: accent,
                        wide: wide,
                      ),
                    ] else ...[
                      _GeometryFields(state: state, accent: accent, wide: wide),
                      const SizedBox(height: 16),
                      _SoilFields(state: state, accent: accent, wide: wide),
                      const SizedBox(height: 16),
                      _OperationFields(
                        state: state,
                        accent: accent,
                        wide: wide,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: state.executando
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {
                                ref
                                    .read(parametersProvider.notifier)
                                    .executarSimulacao();
                              }
                            },
                      icon: state.executando
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(AppIcons.executarSimulacao),
                      label: Text(
                        state.executando ? 'Calculando…' : 'Calcular simulação',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ao finalizar, você poderá salvar o cenário e exportar os dados.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
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
}

class _Hero extends StatelessWidget {
  const _Hero({required this.method, required this.accent});
  final MetodoIrrigacao method;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [accent, accent.withValues(alpha: .72)]),
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
          child: Icon(_methodIcon(method), color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preencha os blocos abaixo na ordem apresentada.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: .9)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GeometryFields extends ConsumerWidget {
  const _GeometryFields({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = <Widget>[
      _Field(
        name: 'comprimento',
        label: 'Comprimento',
        value: state.comprimento,
        suffix: 'm',
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
    ];
    return _BentoCard(
      title: '1. Geometria do terreno',
      subtitle: 'Informe medidas em metros. As declividades são calculadas automaticamente.',
      icon: AppIcons.declividade,
      accent: accent,
      child: Column(
        children: [
          _FieldGrid(fields: fields, wide: wide),
          const SizedBox(height: 12),
          _SlopeSummary(state: state),
        ],
      ),
    );
  }
}

class _SoilFields extends ConsumerWidget {
  const _SoilFields({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BentoCard(
    title: '2. Infiltração do solo',
    subtitle: state.metodo == MetodoIrrigacao.sulco
        ? 'Parâmetros da curva de infiltração acumulada.'
        : 'Parâmetros do modelo Kostiakov–Lewis.',
    icon: Icons.layers_rounded,
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldGrid(
          wide: wide,
          fields: [
            _Field(
              name: 'k',
              label: state.metodo == MetodoIrrigacao.sulco
                  ? 'Coeficiente de infiltração aI'
                  : 'Coeficiente de infiltração k',
              value: state.k,
              suffix: state.metodo == MetodoIrrigacao.sulco
                  ? 'mm/minⁿ'
                  : 'm/minᵃ',
            ),
            _Field(
              name: 'a',
              label: state.metodo == MetodoIrrigacao.sulco
                  ? 'Expoente de infiltração n'
                  : 'Expoente a',
              value: state.a,
              helper: 'Entre 0 e 1',
            ),
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
      ],
    ),
  );
}

class _OperationFields extends StatelessWidget {
  const _OperationFields({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;
  @override
  Widget build(BuildContext context) => _BentoCard(
    title: '3. Manejo da aplicação',
    subtitle:
        'Dados operacionais usados para calcular desempenho e balanço hídrico.',
    icon: Icons.tune_rounded,
    accent: accent,
    child: _FieldGrid(
      wide: wide,
      fields: [
        _Field(
          name: 'vazao',
          label: state.metodo == MetodoIrrigacao.sulco
              ? 'Vazão por sulco'
              : state.metodo == MetodoIrrigacao.faixa
              ? 'Vazão unitária'
              : 'Vazão total',
          value: state.vazao,
          suffix: state.metodo == MetodoIrrigacao.faixa ? 'L/s/m' : 'L/s',
        ),
        if (state.metodo == MetodoIrrigacao.sulco)
          _Field(
            name: 'tempoAplicacao',
            label: state.metodo == MetodoIrrigacao.sulco
                ? 'Tempo de oportunidade no final'
                : 'Tempo de aplicação adotado',
            value: state.tempoAplicacao,
            suffix: 'min',
          ),
        _Field(
          name: 'laminaRequerida',
          label: 'Lâmina requerida',
          value: state.laminaRequerida,
          suffix: 'mm',
        ),
        if (state.metodo == MetodoIrrigacao.faixa)
          _Field(
            name: 'manningN',
            label: 'Rugosidade de Manning',
            value: state.manningN,
          ),
        if (state.metodo != MetodoIrrigacao.faixa) ...[
          _Field(
            name: 'tempoAvancoMetadeMin',
            label: 'Avanço até metade do comprimento',
            value: state.tempoAvancoMetadeMin,
            suffix: 'min',
          ),
          _Field(
            name: 'tempoAvancoFinalMin',
            label: 'Avanço até o final',
            value: state.tempoAvancoFinalMin,
            suffix: 'min',
          ),
        ],
        if (state.metodo == MetodoIrrigacao.faixa) ...[
          _Field(
            name: 'sigmaZ',
            label: 'r inicial para avanço',
            value: state.sigmaZ,
            helper: 'Valor atribuído antes da iteração',
          ),
        ],
      ],
    ),
  );
}

class _PermanentFields extends StatelessWidget {
  const _PermanentFields({
    required this.state,
    required this.accent,
    required this.wide,
  });
  final ParametersState state;
  final Color accent;
  final bool wide;
  @override
  Widget build(BuildContext context) => _BentoCard(
    title: 'Dados da inundação permanente',
    subtitle:
        'Dimensionamento por reposição, armazenamento e vazão disponível.',
    icon: Icons.water_rounded,
    accent: accent,
    child: _FieldGrid(
      wide: wide,
      fields: [
        _Field(
          name: 'areaHectares',
          label: 'Área irrigada',
          value: state.areaHectares,
          suffix: 'ha',
        ),
        _Field(
          name: 'porosidade',
          label: 'Porosidade',
          value: state.porosidade,
          helper: '0 a 1',
        ),
        _Field(
          name: 'profundidadeCamadaMm',
          label: 'Profundidade da camada',
          value: state.profundidadeCamadaMm,
          suffix: 'mm',
        ),
        _Field(
          name: 'condutividadeHidraulicaMmDia',
          label: 'Condutividade hidráulica K₀',
          value: state.condutividadeHidraulicaMmDia,
          suffix: 'mm/dia',
        ),
        _Field(
          name: 'dtaMmCm',
          label: 'Disponibilidade total de água',
          value: state.dtaMmCm,
          suffix: 'mm/cm',
        ),
        _Field(
          name: 'fatorDisponibilidade',
          label: 'Fator de disponibilidade',
          value: state.fatorDisponibilidade,
          helper: '0 a 1',
        ),
        _Field(
          name: 'evapotranspiracaoMmDia',
          label: 'Evapotranspiração da cultura',
          value: state.evapotranspiracaoMmDia,
          suffix: 'mm/dia',
        ),
        _Field(
          name: 'laminaSuperficialMm',
          label: 'Lâmina superficial',
          value: state.laminaSuperficialMm,
          suffix: 'mm',
        ),
        _Field(
          name: 'vazaoDisponivelLps',
          label: 'Vazão disponível',
          value: state.vazaoDisponivelLps,
          suffix: 'L/s',
        ),
      ],
    ),
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

class _Field extends ConsumerWidget {
  const _Field({
    required this.name,
    required this.label,
    required this.value,
    this.suffix,
    this.helper,
    this.allowZero = false,
  });
  final String name;
  final String label;
  final double value;
  final String? suffix;
  final String? helper;
  final bool allowZero;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: _format(value),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
        ],
        decoration: InputDecoration(suffixText: suffix, helperText: helper),
        onChanged: (text) => ref
            .read(parametersProvider.notifier)
            .updateField(campo: name, valor: text),
        validator: (text) {
          final number = double.tryParse((text ?? '').replaceAll(',', '.'));
          if (number == null) return 'Informe um número válido';
          if (allowZero ? number < 0 : number <= 0) {
            return allowZero
                ? 'Use zero ou um valor positivo'
                : 'Use um valor maior que zero';
          }
          if ((name == 'a' ||
                  name == 'porosidade' ||
                  name == 'fatorDisponibilidade') &&
              number > 1) {
            return 'O valor máximo é 1';
          }
          return null;
        },
      ),
    ],
  );
}

class _SlopeSummary extends StatelessWidget {
  const _SlopeSummary({required this.state});
  final ParametersState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        Text('Longitudinal: ${state.declividade.toStringAsFixed(4)} m/m'),
        if (state.metodo != MetodoIrrigacao.sulco)
          Text(
            'Transversal: ${state.declividadeTransversal.toStringAsFixed(4)} m/m',
          ),
      ],
    ),
  );
}

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

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
Color _methodColor(MetodoIrrigacao method) => switch (method) {
  MetodoIrrigacao.sulco => AppColors.sulco,
  MetodoIrrigacao.faixa => AppColors.faixa,
  MetodoIrrigacao.inundacao => AppColors.inundacao,
};
IconData _methodIcon(MetodoIrrigacao method) => switch (method) {
  MetodoIrrigacao.sulco => AppIcons.sulco,
  MetodoIrrigacao.faixa => AppIcons.faixa,
  MetodoIrrigacao.inundacao => AppIcons.inundacao,
};
