import 'package:flutter/material.dart';

import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/features/cenarios/views/comparacao_graficos.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Comparação lado a lado de cenários salvos do mesmo método de irrigação
/// (ex.: inundação com inundação). Destaca o melhor valor de cada métrica.
class ComparacaoCenariosView extends StatelessWidget {
  final List<CenarioSalvo> cenarios;

  const ComparacaoCenariosView({super.key, required this.cenarios});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final metodo = cenarios.first.metodo;
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar cenários')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetodoChip(label: metodo.displayName),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${cenarios.length} '
                          '${cenarios.length == 1 ? 'cenário' : 'cenários'}',
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Resultados',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SecaoGraficosComparativos(cenarios: cenarios),
                  const SizedBox(height: 20),
                  _TabelaComparacao(cenarios: cenarios),
                  const SizedBox(height: 24),
                  Text(
                    'Resumo do cálculo por cenário',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final cenario in cenarios)
                    _ResumoCenario(cenario: cenario),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetodoChip extends StatelessWidget {
  final String label;
  const _MetodoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricaComparacao {
  final String rotulo;
  final double Function(CenarioSalvo cenario) valor;
  final String Function(double valor) formatar;

  /// 1: maior é melhor; -1: menor é melhor; 0: sem destaque.
  final int orientacao;
  final String? Function(CenarioSalvo cenario)? detalhe;

  const _MetricaComparacao(
    this.rotulo,
    this.valor,
    this.formatar, {
    this.orientacao = 0,
    this.detalhe,
  });
}

class _ParametroComparacao {
  final String rotulo;
  final String Function(CenarioSalvo cenario) valor;
  const _ParametroComparacao(this.rotulo, this.valor);
}

class _TabelaComparacao extends StatelessWidget {
  final List<CenarioSalvo> cenarios;
  const _TabelaComparacao({required this.cenarios});

  static final List<_MetricaComparacao> _metricas = [
    const _MetricaComparacao(
      'Eficiência de aplicação (EA)',
      _lerEficiencia,
      _formatarPct,
      orientacao: 1,
      detalhe: _detalheEa,
    ),
    const _MetricaComparacao(
      'Uniformidade (CUC)',
      _lerCuc,
      _formatarPct,
      orientacao: 1,
      detalhe: _detalheCuc,
    ),
    const _MetricaComparacao(
      'Distribuição (DU)',
      _lerDu,
      _formatarPct,
      orientacao: 1,
      detalhe: _detalheDu,
    ),
    _MetricaComparacao(
      'Eficiência de requerimento (ER)',
      (c) => c.resultado.eficienciaRequerimento,
      _formatarPct,
      orientacao: 1,
    ),
    _MetricaComparacao(
      'Perda por percolação',
      (c) => c.resultado.perdaPercolacao,
      _formatarPct,
      orientacao: -1,
    ),
    _MetricaComparacao(
      'Perda por escoamento',
      (c) => c.resultado.perdaEscoamento,
      _formatarPct,
      orientacao: -1,
    ),
    _MetricaComparacao(
      'Lâmina média aplicada',
      (c) => c.resultado.laminaMedia,
      _formatarMm,
    ),
    _MetricaComparacao(
      'Tempo de avanço',
      (c) => c.resultado.tempoAvanco,
      _formatarMin,
    ),
  ];

  static double _lerEficiencia(CenarioSalvo c) => c.resultado.eficiencia;
  static double _lerCuc(CenarioSalvo c) => c.resultado.cuc;
  static double _lerDu(CenarioSalvo c) => c.resultado.du;
  static String _formatarPct(double v) => '${v.toStringAsFixed(1)}%';
  static String _formatarMm(double v) => '${v.toStringAsFixed(1)} mm';
  static String _formatarMin(double v) => '${v.toStringAsFixed(0)} min';
  static String _detalheEa(CenarioSalvo c) => c.resultado.classificacaoEa;
  static String _detalheCuc(CenarioSalvo c) => c.resultado.classificacaoCuc;
  static String _detalheDu(CenarioSalvo c) => c.resultado.classificacaoDu;

  List<_ParametroComparacao> _parametrosDoMetodo(MetodoIrrigacao metodo) {
    final larguraLabel = switch (metodo) {
      MetodoIrrigacao.faixa => 'Largura da faixa',
      MetodoIrrigacao.sulco => 'Espaçamento entre sulcos',
      MetodoIrrigacao.inundacao => 'Largura / espaçamento',
    };
    final unidadeVazao = metodo == MetodoIrrigacao.faixa ? 'L/s/m' : 'L/s';
    return [
      _ParametroComparacao(
        'Comprimento',
        (c) => '${c.parametros.comprimento.toStringAsFixed(1)} m',
      ),
      _ParametroComparacao(
        'Declividade',
        (c) => '${c.parametros.declividade.toStringAsFixed(3)} m/m',
      ),
      _ParametroComparacao(
        larguraLabel,
        (c) => '${c.parametros.larguraOuEspacamento.toStringAsFixed(2)} m',
      ),
      _ParametroComparacao(
        metodo == MetodoIrrigacao.faixa ? 'Vazão unitária q0' : 'Vazão',
        (c) => '${c.parametros.vazao.toStringAsFixed(2)} $unidadeVazao',
      ),
      _ParametroComparacao(
        'Tempo de aplicação',
        (c) => '${c.parametros.tempoAplicacao.toStringAsFixed(0)} min',
      ),
      _ParametroComparacao(
        'Lâmina requerida',
        (c) => '${c.parametros.laminaRequerida.toStringAsFixed(1)} mm',
      ),
      if (metodo == MetodoIrrigacao.inundacao) ...[
        _ParametroComparacao(
          'Tipo de inundação',
          (c) => c.parametros.tipoInundacao.displayName,
        ),
        _ParametroComparacao(
          'Área',
          (c) => '${c.parametros.areaHectares.toStringAsFixed(2)} ha',
        ),
      ],
      _ParametroComparacao(
        'Textura do solo',
        (c) => c.parametros.texturaSolo.displayName,
      ),
    ];
  }

  double? _melhorValor(_MetricaComparacao metrica) {
    if (metrica.orientacao == 0) return null;
    double melhor = metrica.valor(cenarios.first);
    for (final cenario in cenarios.skip(1)) {
      final valor = metrica.valor(cenario);
      final supera = metrica.orientacao == 1
          ? valor > melhor
          : valor < melhor;
      if (supera) melhor = valor;
    }
    return melhor;
  }

  @override
  Widget build(BuildContext context) {
    final metodo = cenarios.first.metodo;
    final parametros = _parametrosDoMetodo(metodo);
    final chavesMetricas = {
      for (final cenario in cenarios) ...cenario.resultado.metricas.keys,
    }.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabela(context, [
          _linhaCabecalho(context),
          for (final metrica in _metricas)
            _linhaMetrica(context, metrica, _melhorValor(metrica)),
        ]),
        _cabecalhoSecao(context, 'Parâmetros principais'),
        _tabela(
          context,
          [
            for (final parametro in parametros)
              _linhaParametro(context, parametro),
          ],
        ),
        if (chavesMetricas.isNotEmpty) ...[
          _cabecalhoSecao(context, 'Métricas do simulador'),
          _tabela(
            context,
            [
              for (final chave in chavesMetricas)
                _linhaParametro(context, _linhaDeMetrica(chave)),
            ],
          ),
        ],
      ],
    );
  }

  /// Linha da tabela para uma métrica dinâmica do mapa `metricas`, com a
  /// unidade reportada pelo próprio resultado.
  _ParametroComparacao _linhaDeMetrica(String chave) {
    final unidade = cenarios.first.resultado.unidadesMetricas[chave] ?? '';
    String valor(CenarioSalvo cenario) {
      final v = cenario.resultado.metricas[chave];
      if (v == null || v.isNaN || v.isInfinite) return '—';
      final formatado = v.abs() >= 100
          ? v.toStringAsFixed(0)
          : v.abs() < 1
          ? v.toStringAsFixed(3)
          : v.toStringAsFixed(1);
      return unidade.isEmpty ? formatado : '$formatado $unidade';
    }

    return _ParametroComparacao(chave, valor);
  }

  Widget _tabela(BuildContext context, List<TableRow> linhas) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(210),
          for (var i = 0; i < cenarios.length; i++)
            i + 1: const FixedColumnWidth(160),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: colors.outlineVariant),
          verticalInside: BorderSide(color: colors.outlineVariant),
        ),
        children: linhas,
      ),
    );
  }

  TableRow _linhaCabecalho(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return TableRow(
      children: [
        const SizedBox(),
        for (final cenario in cenarios)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cenario.nome,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(cenario.dataCriacao),
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cabecalhoSecao(BuildContext context, String titulo) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
      child: Text(
        titulo,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  TableRow _linhaMetrica(
    BuildContext context,
    _MetricaComparacao metrica,
    double? melhor,
  ) {
    return TableRow(
      children: [
        _celulaRotulo(context, metrica.rotulo),
        for (final cenario in cenarios)
          _celulaMetrica(context, cenario, metrica, melhor),
      ],
    );
  }

  TableRow _linhaParametro(BuildContext context, _ParametroComparacao parametro) {
    return TableRow(
      children: [
        _celulaRotulo(context, parametro.rotulo),
        for (final cenario in cenarios)
          _celulaTexto(context, parametro.valor(cenario)),
      ],
    );
  }

  Widget _celulaRotulo(BuildContext context, String rotulo) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Text(
        rotulo,
        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _celulaMetrica(
    BuildContext context,
    CenarioSalvo cenario,
    _MetricaComparacao metrica,
    double? melhor,
  ) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final valor = metrica.valor(cenario);
    final detalhe = metrica.detalhe?.call(cenario);
    final destaque =
        melhor != null && (valor - melhor).abs() < 0.001 &&
        cenarios.length > 1 &&
        valor != 0;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: destaque ? colors.primary.withValues(alpha: .10) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metrica.formatar(valor),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: destaque ? colors.primary : colors.onSurface,
              ),
            ),
            if (detalhe != null)
              Text(
                detalhe,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            if (destaque)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    metrica.orientacao == 1
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'melhor',
                    style: text.labelSmall?.copyWith(color: colors.primary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _celulaTexto(BuildContext context, String valor) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        valor,
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Card expansível com o resumo textual de um cenário salvo.
class _ResumoCenario extends StatelessWidget {
  final CenarioSalvo cenario;
  const _ResumoCenario({required this.cenario});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            cenario.nome,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Salvo em ${_formatDate(cenario.dataCriacao)}',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                cenario.resultado.resumoTextual,
                style: text.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
