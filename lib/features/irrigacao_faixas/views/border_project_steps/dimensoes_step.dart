import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 2: dimensões da faixa e condição de jusante.
List<Widget> dimensoesStep(BorderProjectFields fields, BorderProject p) => [
  const Text(
    'Defina o comprimento e a largura das faixas dentro da gleba. Referências usuais: L de 50–400 m e W de 4–20 m.',
  ),
  fields.number('comprimentoM', 'Comprimento da faixa (L)', p.comprimentoM, 'm'),
  fields.number('larguraM', 'Largura da faixa (W)', p.larguraM, 'm'),
  fields.select<CondicaoJusanteFaixa>(
    'Condição de jusante',
    p.jusante,
    CondicaoJusanteFaixa.values,
    fields.controller.setJusante,
    (v) => v == CondicaoJusanteFaixa.aberta
        ? 'Aberta — escoamento livre'
        : 'Fechada — não simulável',
  ),
  fields.number(
    'alturaDiqueM',
    'Altura real do dique (opcional)',
    p.alturaDiqueM,
    'm',
    optional: true,
  ),
  fields.number(
    'laminaSuperficialM',
    'Lâmina superficial hn (opcional)',
    p.laminaSuperficialM,
    'm',
    optional: true,
  ),
  IrrigationLabeledField(
    label: 'Tipo de dique (registro construtivo opcional)',
    child: TextFormField(
      initialValue: p.tipoDique,
      decoration: const InputDecoration(
        hintText: 'Ex.: dique de terra compactada',
        helperText: 'Registro descritivo; não altera o cálculo hidráulico.',
      ),
      onChanged: (value) {
        fields.controller.setTipoDique(value);
        fields.unconfirm();
      },
    ),
  ),
];
