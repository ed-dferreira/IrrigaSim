import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';

/// Etapa 7: vazão, janela de fornecimento e operação da faixa.
List<Widget> operacaoStep(BorderProjectFields fields, BorderProject p) => [
  fields.number(
    'vazaoDisponivelLs',
    'Oferta de água (opcional)',
    p.vazaoDisponivelLs,
    'L/s',
    optional: true,
  ),
  fields.number(
    'periodoDias',
    'Período de irrigação PI (opcional)',
    p.periodoDias?.toDouble(),
    'dias',
    optional: true,
  ),
  fields.number(
    'jornadaHoras',
    'Jornada TDF (opcional)',
    p.jornadaHoras,
    'h/dia',
    optional: true,
  ),
  fields.number(
    'mudancaMin',
    'Tempo de mudança tmu (opcional)',
    p.mudancaMin,
    'min',
    optional: true,
    zero: true,
  ),
  fields.number(
    'faixasSimultaneas',
    'Faixas simultâneas NFP (opcional)',
    p.faixasSimultaneas?.toDouble(),
    '',
    optional: true,
  ),
  fields.number(
    'janelaFornecimentoHorasDia',
    'Duração da janela de fornecimento nos dias indicados (opcional)',
    p.janelaFornecimentoHorasDia,
    'h/dia',
    optional: true,
  ),
  fields.number(
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
      helperText: 'Ex.: 1, 3, 5. Dia 1 é o primeiro dia do período informado.',
    ),
    onChanged: (value) {
      fields.controller.setDiasFornecimento(value);
      fields.unconfirm();
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
];
