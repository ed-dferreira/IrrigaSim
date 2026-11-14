import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_hidraulica.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 8: revisão das etapas confirmadas.
List<Widget> revisaoStep(BorderProjectFields fields, BorderProject p) => [
  IrrigationAuditSection(
    title: 'Área e geometria',
    icon: AppIcons.projetoArea,
    children: [
      fields.review(
        'Geometria',
        '${fields.format(p.comprimentoM)} × ${fields.format(p.larguraM)} m',
      ),
      fields.review(
        'Gleba',
        '${fields.format(p.comprimentoAreaM)} × ${fields.format(p.larguraAreaM)} m',
      ),
      fields.review(
        'Declive longitudinal S0',
        '${fields.format(p.declividadeLongitudinal)} m/m',
      ),
      fields.review(
        'Declive transversal St',
        '${fields.format(p.declividadeTransversal)} m/m',
      ),
      fields.review(
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
      fields.review('Cobertura', switch (p.cobertura) {
        CoberturaFaixa.soloExposto => 'Solo exposto',
        CoberturaFaixa.culturaInstalada => 'Cultura instalada',
        CoberturaFaixa.coberturaTotal => 'Cobertura total',
      }),
      fields.review('Textura do solo', p.textura?.displayName ?? 'Não informada'),
      fields.review(
        'Propriedades hídricas do solo',
        'UCC ${fields.format(p.agronomia?.uccPercentual)}% · UPMP ${fields.format(p.agronomia?.upmpPercentual)}% · Da ${fields.format(p.agronomia?.densidadeGcm3)} g/cm³',
      ),
      fields.review(
        'Cultura e raízes',
        '${p.cultura ?? 'Não informada'} · Pr ${fields.format(p.agronomia?.profundidadeRaizesCm)} cm · fração disponível ${fields.format(p.agronomia?.fracaoAguaDisponivel)}',
      ),
      fields.review(
        'Parâmetros da cultura',
        'Kc ${fields.format(p.agronomia?.kc)} · fileiras ${fields.format(p.agronomia?.espacamentoFileirasM)} m · plantas ${fields.format(p.agronomia?.espacamentoPlantasM)} m',
      ),
    ],
  ),
  const SizedBox(height: 12),
  IrrigationAuditSection(
    title: 'Clima e demanda',
    icon: AppIcons.projetoClima,
    children: [
      fields.review(
        'Clima e demanda',
        'ETc ${fields.format(p.agronomia?.evapotranspiracaoMmDia)} mm/dia · Pef ${fields.format(p.agronomia?.precipitacaoEfetivaMmDia)} mm/dia',
      ),
      fields.review(
        'Infiltração',
        'k=${fields.format(p.k)} m/minᵃ · a=${fields.format(p.a)} · VIB=${fields.format(p.vibMMin)} m/min',
      ),
      fields.review(
        'IRN (${p.origemIrn.name})',
        '${fields.format(p.irnEfetivaMm)} mm',
      ),
      fields.review('Cenário de infiltração', p.cenarioInfiltracao.name),
    ],
  ),
  const SizedBox(height: 12),
  IrrigationAuditSection(
    title: 'Avanço e operação',
    icon: AppIcons.projetoOperacao,
    children: [
      fields.review('q0', '${fields.format(p.vazaoUnitariaLsM)} L/s/m'),
      fields.review('Qfaixa = q0 × W', '${fields.format(p.vazaoFaixaLs)} L/s'),
      fields.review(
        'Dique / hn',
        '${fields.format(p.alturaDiqueM)} / ${fields.format(p.laminaSuperficialM)} m (não informados quando —)',
      ),
      fields.review('Tipo do dique', p.tipoDique ?? 'Não informado'),
      fields.review(
        'Corte antecipado de referência',
        p.fracaoCortePlanejada == null
            ? 'Não selecionado'
            : '${(p.fracaoCortePlanejada! * 100).toStringAsFixed(1)}% de L · bloqueado até haver modelo pós-corte',
      ),
      fields.review(
        'qmax alternativa (F02)',
        switch (BorderHydraulics.vazaoMaximaF02DoProjeto(p)) {
          null => 'Não informada (requer ρ1, ρ2 e Vmax)',
          final qmax => '${fields.format(qmax)} m³/min/m',
        },
      ),
      fields.review('Oferta de água', '${fields.format(p.vazaoDisponivelLs)} L/s'),
      fields.review(
        'PI · TDF · tmu · NFP · janela',
        '${p.periodoDias ?? '—'} dias · ${fields.format(p.jornadaHoras)} h/dia · ${fields.format(p.mudancaMin)} min · ${p.faixasSimultaneas ?? '—'} · ${fields.format(p.inicioFornecimentoH)} h por ${fields.format(p.janelaFornecimentoHorasDia)} h nos dias ${p.diasFornecimento.isEmpty ? '—' : p.diasFornecimento.join(', ')}',
      ),
    ],
  ),
  const Text(
    'Comprimento usual, declive e largura são referências, não validações hidráulicas nesta etapa.',
  ),
];
