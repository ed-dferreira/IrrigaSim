import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_planejamento.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

import 'package:irrigasim/features/irrigacao_faixas/viewmodels/border_project_controller.dart';

import 'border_results_kpis.dart';

/// Botão e fluxo da comparação de vazões (diálogo de grade) e das seções
/// 'Alternativas testadas' / 'Alternativas salvas'.
List<Widget> secoesAlternativasFaixa({
  required BuildContext context,
  required WidgetRef ref,
  required BorderProject project,
  required BorderAlternatives? alternatives,
  required BorderCandidate? selectedAlternative,
  required bool buscando,
}) {
  if (project.comprimentoAreaM == null || project.larguraAreaM == null) {
    return const [];
  }
  return [
    OutlinedButton.icon(
      onPressed: buscando
          ? null
          : () => _executarComparacaoDeVazoes(context, ref, project),
      icon: buscando
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.recomendacao),
      label: Text(
        buscando
            ? 'Avaliando alternativas…'
            : 'Configurar comparação de vazões',
      ),
    ),
    if (alternatives != null)
      _section('Alternativas testadas', [
        _row(
          'Melhor entre candidatas viáveis',
          (selectedAlternative ?? alternatives.melhor) == null
              ? 'Nenhuma'
              : 'Melhor na grade por ${alternatives.objetivo} · L=${f((selectedAlternative ?? alternatives.melhor)!.comprimentoM)} m · q0=${f((selectedAlternative ?? alternatives.melhor)!.vazaoLsM)} L/s/m · Ea=${f((selectedAlternative ?? alternatives.melhor)!.resultado!.ea)}% · Er=${f((selectedAlternative ?? alternatives.melhor)!.resultado!.er)}%',
        ),
        for (final c in alternatives.candidatos)
          Semantics(
            button: true,
            label:
                'Selecionar alternativa L ${f(c.comprimentoM)} metros, q0 ${f(c.vazaoLsM)} litros por segundo por metro',
            child: InkWell(
              onTap: c.resultado == null
                  ? null
                  : () =>
                        ref
                                .read(
                                  borderSelectedAlternativeProvider.notifier,
                                )
                                .state =
                            c,
              child: _row(
                'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m${identical(c, selectedAlternative ?? alternatives.melhor) ? ' · selecionada' : ''}',
                c.motivoRejeicao == null
                    ? 'Ea=${f(c.resultado!.ea)}% · Er=${f(c.resultado!.er)}% · Pp=${f(c.resultado!.pp)}% · Pe=${f(c.resultado!.pe)}% · demanda Q=${f(c.vazaoLsM * c.resultado!.larguraM)} L/s'
                    : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao} · Qfaixa=${f(c.vazaoLsM * c.larguraM)} L/s',
              ),
            ),
          ),
        _row(
          'Grade e critério',
          'q0 ${f(alternatives.menorLsM)}–${f(alternatives.maiorLsM)} L/s/m · passo ${f(alternatives.passoLsM)} · maximizar ${alternatives.objetivo}',
        ),
      ]),
    if (alternatives == null && project.alternativas.isNotEmpty)
      _section('Alternativas salvas', [
        for (final c in project.alternativas)
          _row(
            'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m',
            c.motivoRejeicao == null
                ? 'Ea=${f(c.eficienciaPercentual!)}% · Er=${f(c.erPercentual ?? 0)}% · Pp=${f(c.ppPercentual ?? 0)}% · Pe=${f(c.pePercentual ?? 0)}% · Q=${f(c.demandaLs ?? 0)} L/s${c.selecionada ? ' · selecionada' : ''} · objetivo ${c.objetivo ?? 'Ea'}'
                : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao}',
          ),
      ]),
  ];
}

/// Seção 'Comparar cenários de infiltração' com o botão de cálculo em paralelo.
List<Widget> secaoComparacaoCenariosFaixa({
  required BuildContext context,
  required WidgetRef ref,
  required BorderProject project,
  required BorderScenarioComparison? scenarioComparison,
}) {
  if (project.dadosPrimeira == null && project.dadosTerceira == null) {
    return const [];
  }
  return [
    _section('Comparar cenários de infiltração', [
      _row(
        'Primeira irrigação · k, a, VIB',
        '${f(project.dadosPrimeira?.k ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.k : null))} · ${f(project.dadosPrimeira?.a ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.a : null))} · ${f(project.dadosPrimeira?.vibMMin ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.vibMMin : null))}',
      ),
      _row(
        'Terceira irrigação · k, a, VIB',
        '${f(project.dadosTerceira?.k ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.k : null))} · ${f(project.dadosTerceira?.a ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.a : null))} · ${f(project.dadosTerceira?.vibMMin ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.vibMMin : null))}',
      ),
      OutlinedButton.icon(
        onPressed: () {
          try {
            ref
                .read(borderScenarioComparisonProvider.notifier)
                .state = calcularComparacaoCenarios(
              project,
            );
          } on FormatException catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          }
        },
        icon: const Icon(AppIcons.comparar),
        label: const Text('Calcular em paralelo'),
      ),
      if (scenarioComparison case final comparison?) ...[
        _row(
          'Primeira · Ea / Er / Pp / Pe',
          '${f(comparison.primeira.ea)}% · ${f(comparison.primeira.er)}% · ${f(comparison.primeira.pp)}% · ${f(comparison.primeira.pe)}%',
        ),
        _row(
          'Terceira · Ea / Er / Pp / Pe',
          '${f(comparison.terceira.ea)}% · ${f(comparison.terceira.er)}% · ${f(comparison.terceira.pp)}% · ${f(comparison.terceira.pe)}%',
        ),
        _row(
          'Premissas mantidas',
          'Mesma geometria, q0, IRN e rugosidade; cada cenário usa seus próprios k, a e VIB.',
        ),
      ],
    ]),
  ];
}

void _executarComparacaoDeVazoes(
  BuildContext context,
  WidgetRef ref,
  BorderProject project,
) async {
  ref.read(borderAlternativesLoadingProvider.notifier).state = true;
  final qAtual = project.vazaoUnitariaLsM!;
  final menor = TextEditingController(
    text: (qAtual * .75).toStringAsFixed(2),
  );
  final maior = TextEditingController(
    text: (qAtual * 1.25).toStringAsFixed(2),
  );
  final passo = TextEditingController(text: '0.05');
  var objetivo = 'Ea';
  final grade = await showDialog<(double, double, double, String)>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Configurar comparação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: menor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'q0 mínimo (L/s/m)',
              ),
            ),
            TextField(
              controller: maior,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'q0 máximo (L/s/m)',
              ),
            ),
            TextField(
              controller: passo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Passo da grade (L/s/m)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: objetivo,
              decoration: const InputDecoration(
                labelText: 'Objetivo da busca',
              ),
              items: const [
                DropdownMenuItem(value: 'Ea', child: Text('Maximizar Ea')),
                DropdownMenuItem(value: 'Er', child: Text('Maximizar Er')),
              ],
              onChanged: (value) =>
                  setDialogState(() => objetivo = value ?? 'Ea'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              double? parse(String text) =>
                  double.tryParse(text.replaceAll(',', '.'));
              final values = (
                parse(menor.text),
                parse(maior.text),
                parse(passo.text),
              );
              if (values.$1 == null ||
                  values.$2 == null ||
                  values.$3 == null ||
                  values.$1! <= 0 ||
                  values.$2! < values.$1! ||
                  values.$3! <= 0) {
                return;
              }
              Navigator.pop(
                dialogContext,
                (values.$1!, values.$2!, values.$3!, objetivo),
              );
            },
            child: const Text('Comparar'),
          ),
        ],
      ),
    ),
  );
  menor.dispose();
  maior.dispose();
  passo.dispose();
  if (grade == null) return;
  try {
    final found = await buscarAlternativas(
      project,
      menorLsM: grade.$1,
      maiorLsM: grade.$2,
      passoLsM: grade.$3,
      objetivo: grade.$4,
    );
    if (context.mounted) {
      ref.read(borderAlternativesProvider.notifier).state = found;
    }
  } on FormatException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } finally {
    if (context.mounted) {
      ref.read(borderAlternativesLoadingProvider.notifier).state = false;
    }
  }
}

Widget _row(
  String label,
  String value, {
  String? detail,
  bool warning = false,
}) => IrrigationAuditRow(label, value, detail: detail, isWarning: warning);

Widget _section(
  String title,
  List<Widget> children, {
  bool advanced = false,
}) => IrrigationAuditSection(
  title: title,
  icon: AppIcons.relatorio,
  initiallyExpanded: !advanced,
  children: children,
);
