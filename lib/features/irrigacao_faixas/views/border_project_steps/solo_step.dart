import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_tabelas_referencia.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';

/// Etapa 3: solo, infiltração e coberturas.
List<Widget> soloStep(
  BorderProjectFields fields,
  BorderProject p, {
  required double diametroBooherCm,
  required double cargaBooherCm,
}) => [
  const Text(
    'A infiltração do solo controla o avanço e as perdas. Informe parâmetros medidos/estimados; a tabela Marr fornece sugestões geométricas e não substitui k, a ou VIB.',
  ),
  fields.select<CenarioInfiltracaoFaixa>(
    'Cenário de infiltração',
    p.cenarioInfiltracao,
    CenarioInfiltracaoFaixa.values,
    fields.controller.setCenarioInfiltracao,
    (v) => switch (v) {
      CenarioInfiltracaoFaixa.primeira => 'Primeira irrigação',
      CenarioInfiltracaoFaixa.terceira => 'Terceira irrigação',
      CenarioInfiltracaoFaixa.informado => 'Outro / dados informados',
    },
  ),
  const Text(
    'O cenário identifica a origem; k, a e VIB devem ser informados para cada irrigação, sem misturar coeficientes.',
  ),
  fields.number('k', 'Coeficiente de infiltração k', p.k, 'm/minᵃ'),
  fields.number('a', 'Expoente a (entre 0 e 1)', p.a, ''),
  fields.number(
    'vibMMin',
    'Velocidade de infiltração básica (VIB)',
    p.vibMMin,
    'm/min',
    zero: true,
  ),
  fields.number(
    'uccPercentual',
    'Umidade na capacidade de campo UCC',
    p.agronomia?.uccPercentual,
    '%',
    optional: true,
  ),
  fields.number(
    'upmpPercentual',
    'Umidade no ponto de murcha UPMP',
    p.agronomia?.upmpPercentual,
    '%',
    optional: true,
  ),
  fields.number(
    'densidadeGcm3',
    'Densidade aparente do solo',
    p.agronomia?.densidadeGcm3,
    'g/cm³',
    optional: true,
  ),
  fields.select<CoberturaFaixa>(
    'Cobertura',
    p.cobertura,
    CoberturaFaixa.values,
    fields.controller.setCobertura,
    (v) => switch (v) {
      CoberturaFaixa.soloExposto => 'Solo exposto',
      CoberturaFaixa.culturaInstalada =>
        'Cultura instalada (cobertura parcial ou desconhecida)',
      CoberturaFaixa.coberturaTotal => 'Cobertura total informada',
    },
  ),
  fields.number('rugosidadeN', 'Rugosidade de Manning n', p.rugosidadeN, ''),
  IrrigationLabeledField(
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
          fields.controller.setTextura(v);
          fields.unconfirm();
        }
      },
    ),
  ),
  if (p.textura != null) ...[
    for (final row in const BorderReferenceTables().sugestoesMarr(
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
  IrrigationLabeledField(
    label: 'Consulta de quantidade de dispositivos (orientativa)',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<double>(
          initialValue: p.dispositivoDiametroCm ?? diametroBooherCm,
          decoration: const InputDecoration(labelText: 'Diâmetro impresso'),
          items: [
            for (final value in BorderReferenceTables.diametrosCm)
              DropdownMenuItem(value: value, child: Text('$value cm')),
          ],
          onChanged: (value) {
            if (value == null) return;
            fields.setDiametroBooherCm(value);
            fields.controller.setDispositivo(
              diametroCm: value,
              cargaCm: p.dispositivoCargaCm ?? cargaBooherCm,
            );
            fields.unconfirm();
          },
        ),
        const SizedBox(height: IrrigationSpacing.field),
        DropdownButtonFormField<double>(
          initialValue: p.dispositivoCargaCm ?? cargaBooherCm,
          decoration: const InputDecoration(labelText: 'Carga impressa'),
          items: [
            for (final value in BorderReferenceTables.cargasCm)
              DropdownMenuItem(value: value, child: Text('$value cm')),
          ],
          onChanged: (value) {
            if (value == null) return;
            fields.setCargaBooherCm(value);
            fields.controller.setDispositivo(
              diametroCm: p.dispositivoDiametroCm ?? diametroBooherCm,
              cargaCm: value,
            );
            fields.unconfirm();
          },
        ),
        const SizedBox(height: IrrigationSpacing.field),
        _ConsultaDispositivo(
          fields: fields,
          project: p,
          diametroBooherCm: diametroBooherCm,
          cargaBooherCm: cargaBooherCm,
        ),
        const Text(
          'Registrar tipo de dique e orientação construtiva. A aula recomenda dois sulcos transversais no início e cerca de três adicionais, equidistantes, para declive >3%; o aplicativo não desenha nem dimensiona a construção. Bases ilustradas de diques não são alturas.',
        ),
      ],
    ),
  ),
];

class _ConsultaDispositivo extends StatelessWidget {
  const _ConsultaDispositivo({
    required this.fields,
    required this.project,
    required this.diametroBooherCm,
    required this.cargaBooherCm,
  });

  final BorderProjectFields fields;
  final BorderProject project;
  final double diametroBooherCm;
  final double cargaBooherCm;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final cell = const BorderReferenceTables().booher(
      p.dispositivoDiametroCm ?? diametroBooherCm,
      p.dispositivoCargaCm ?? cargaBooherCm,
    )!;
    final eligible = const BorderReferenceTables().sugestao(
      p.dispositivoDiametroCm ?? diametroBooherCm,
      p.dispositivoCargaCm ?? cargaBooherCm,
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
          formula: 'Booher impresso: ${eligible.impressoLs} L/s por dispositivo',
          description: count == null
              ? 'Informe q0 e W para estimar quantidade. Consulta orientativa; carga e vazão real devem ser confirmadas em campo.'
              : '$count dispositivos por faixa (arredondamento para cima) · vazão total estimada ${fields.format(count * perDevice)} L/s para Qfaixa ${fields.format(p.vazaoFaixaLs)} L/s. Não representa cálculo hidráulico de comportas.',
        ),
        if (p.vazaoDisponivelLs == null)
          const Padding(
            padding: EdgeInsets.only(bottom: IrrigationSpacing.field),
            child: Text(
              'Qt pendente: informe a oferta disponível para verificar simultaneidade.',
            ),
          )
        else if (p.vazaoFaixaLs != null)
          Padding(
            padding: const EdgeInsets.only(bottom: IrrigationSpacing.field),
            child: IrrigationAlertBanner(
              message: simultaneasPelaOferta == 0
                  ? 'Oferta insuficiente: Qt=${fields.format(p.vazaoDisponivelLs)} L/s não atende sequer uma faixa (Qfaixa=${fields.format(p.vazaoFaixaLs)} L/s).'
                  : 'Qt=${fields.format(p.vazaoDisponivelLs)} L/s permite no máximo $simultaneasPelaOferta faixa(s) simultânea(s) a Qfaixa=${fields.format(p.vazaoFaixaLs)} L/s. Defina NFP respeitando esse teto e confirme a divisão real da água.',
            ),
          ),
      ],
    );
  }
}
