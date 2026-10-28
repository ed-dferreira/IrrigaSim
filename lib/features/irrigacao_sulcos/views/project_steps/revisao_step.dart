import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

// ──────────────────────── Step 7: Revisão ────────────────────────

class RevisaoStep extends StatelessWidget {
  const RevisaoStep({super.key, required this.state, required this.accent});
  final EstadoParametrosSulco state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.entradasSulco.podeRecalcularIrrigacao) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Entradas agronômicas originais ausentes ou não utilizáveis. '
                'A IRN histórica permanece registrada, mas o turno não será '
                'recalculado com valores ilustrativos. Informe UCC, UPMP, Ds, '
                'raízes, fração, ETc (ou ETo×Kc) e Pef efetiva para recalcular.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: .72)],
            ),
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
                child: const Icon(
                  AppIcons.projetoRevisao,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisão antes de calcular',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifique os dados antes de executar o dimensionamento.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white.withValues(alpha: .9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(section.icon, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 160,
                            child: Text(
                              '${row.label}:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<ReviewSection> _buildSections(EstadoParametrosSulco state) {
    final lamina = state.laminaRequeridaResultado;
    return [
      ReviewSection(
        icon: AppIcons.projetoArea,
        title: 'Geometria',
        rows: [
          ReviewRow('Método', 'Sulco'),
          if (state.tipoSulco != null)
            ReviewRow('Tipo de sulco', state.tipoSulco!.displayName),
          ReviewRow('Comprimento', '${state.comprimento.toStringAsFixed(0)} m'),
          ReviewRow(
            'Espaçamento',
            '${state.larguraOuEspacamento.toStringAsFixed(2)} m',
          ),
          ReviewRow(
            'Limite do terreno',
            '${state.comprimentoMaximoTerrenoM.toStringAsFixed(0)} m',
          ),
          ReviewRow(
            'Declividade',
            '${state.declividade.toStringAsFixed(4)} m/m '
                '(${(state.declividade * 100).toStringAsFixed(2)}%)',
          ),
          ReviewRow(
            'Largura superior do sulco',
            state.larguraSulcoM == null
                ? 'Não informada (opcional)'
                : '${state.larguraSulcoM!.toStringAsFixed(2)} m',
          ),
          ReviewRow(
            'Profundidade do sulco',
            state.profundidadeSulcoM == null
                ? 'Não informada (opcional)'
                : '${state.profundidadeSulcoM!.toStringAsFixed(2)} m',
          ),
          ReviewRow(
            'Desnível longitudinal',
            '${state.desnivelM.toStringAsFixed(2)} m em '
                '${state.distanciaHorizontalM.toStringAsFixed(0)} m',
          ),
        ],
      ),
      ReviewSection(
        icon: Icons.landscape_rounded,
        title: 'Solo',
        rows: [
          ReviewRow('Textura', state.texturaSolo.displayName),
          ReviewRow(
            'Umidade na capacidade de campo (UCC)',
            '${state.uccPercentual.toStringAsFixed(1)}%',
          ),
          ReviewRow(
            'Umidade no ponto de murcha (UPMP)',
            '${state.upmpPercentual.toStringAsFixed(1)}%',
          ),
          ReviewRow(
            'Densidade aparente',
            '${state.densidadeAparenteGcm3.toStringAsFixed(2)} g/cm³',
          ),
        ],
      ),
      ReviewSection(
        icon: AppIcons.projetoSolo,
        title: 'Infiltração',
        rows: [
          ReviewRow('Coeficiente aI', '${state.k} mm/minⁿ'),
          ReviewRow('Expoente n', state.a.toString()),
        ],
      ),
      ReviewSection(
        icon: AppIcons.projetoClima,
        title: 'Clima e demanda',
        rows: [
          ReviewRow(
            'Evapotranspiração (ETc)',
            '${state.evapotranspiracaoCulturaMmDia.toStringAsFixed(1)} mm/dia',
          ),
          if (state.metodoEtc == MetodoEtc.blaneyCriddle &&
              state.etoBlaneyCriddle != null)
            ReviewRow(
              'ETo estimada (Blaney–Criddle)',
              '${state.etoBlaneyCriddle!.toStringAsFixed(2)} mm/dia',
            ),
          ReviewRow(
            'Precipitação efetiva (Pef)',
            '${state.precipitacaoEfetivaMmDia.toStringAsFixed(1)} mm/dia',
          ),
          ReviewRow(
            'Lâmina requerida',
            '${state.laminaRequerida.toStringAsFixed(1)} mm',
          ),
          if (lamina != null) ...[
            ReviewRow(
              'Demanda líquida',
              '${lamina.demandaLiquidaMmDia.toStringAsFixed(1)} mm/dia',
            ),
            ReviewRow(
              'Turno de rega calculado',
              '${lamina.turnoCalculadoDias.toStringAsFixed(1)} dias',
            ),
            ReviewRow(
              'Turno operacional',
              '${lamina.turnoOperacionalDias} dia(s)',
            ),
          ],
        ],
      ),
      if (state.nomeCultura.isNotEmpty || state.kc != 1.0)
        ReviewSection(
          icon: AppIcons.projetoCultura,
          title: 'Cultura',
          rows: [
            if (state.nomeCultura.isNotEmpty)
              ReviewRow('Cultura', state.nomeCultura),
            ReviewRow('Kc', state.kc.toStringAsFixed(2)),
            ReviewRow(
              'Espaç. fileiras',
              '${state.espacamentoFileirasM.toStringAsFixed(2)} m',
            ),
            ReviewRow(
              'Espaç. plantas',
              '${state.espacamentoPlantasM.toStringAsFixed(2)} m',
            ),
            ReviewRow(
              'Profund. raízes',
              '${state.profundidadeRaizesCm.toStringAsFixed(0)} cm',
            ),
            ReviewRow(
              'Fração água disp.',
              state.fracaoAguaDisponivel.toStringAsFixed(2),
            ),
          ],
        ),
      ReviewSection(
        icon: AppIcons.curvaAvanco,
        title: 'Origem do avanço',
        rows: [
          ReviewRow(
            'Origem',
            state.origemAvanco == OrigemAvanco.ensaio
                ? 'Ensaio de campo'
                : 'Estimativa',
          ),
          if (state.origemAvanco == OrigemAvanco.estimativa) ...[
            ReviewRow(
              'Equação informada',
              'Tx = ${state.coeficienteAvancoK.toStringAsPrecision(6)} · '
                  'x^${state.expoenteAvancoB.toStringAsFixed(5)}',
            ),
            ReviewRow(
              'Distância X de referência',
              '${state.distanciaReferenciaAvancoM.toStringAsFixed(2)} m',
            ),
            ReviewRow(
              'Tempo Tx calculado em X',
              '${(state.coeficienteAvancoK * math.pow(state.distanciaReferenciaAvancoM, state.expoenteAvancoB)).toStringAsFixed(2)} min',
            ),
          ] else ...[
            ReviewRow(
              'Método de ajuste',
              state.metodoCurvaAvanco == MetodoAjusteAvanco.doisPontos
                  ? 'Dois pontos com interpolação do meio'
                  : 'Mínimos quadrados log-log',
            ),
            for (final (index, point) in state.pontosEnsaioAvanco.indexed)
              ReviewRow(
                'Estaca ${index + 1}',
                '${point.distanciaM.toStringAsFixed(2)} m · '
                    '${point.tempoMin.toStringAsFixed(2)} min',
              ),
          ],
          ReviewRow(
            'Hipótese de recessão',
            state.hipoteseRecessao == HipoteseRecessao.desprezada
                ? 'Recessão e depleção desprezadas'
                : 'Curva de recessão informada por estaca',
          ),
        ],
      ),
      ReviewSection(
        icon: AppIcons.projetoOperacao,
        title: 'Operação',
        rows: [
          ReviewRow(
            'Área efetiva',
            '${state.areaHectares.toStringAsFixed(2)} ha',
          ),
          ReviewRow(
            'Período de irrigação',
            '${state.periodoIrrigacaoDias} dias',
          ),
          ReviewRow(
            'Tempo entre parcelas',
            '${state.tempoMudancaParcelaMin.toStringAsFixed(0)} min',
          ),
          ReviewRow('Manejo', state.manejoSulco.displayName),
          ReviewRow('Vazão por sulco', '${state.vazao.toStringAsFixed(2)} L/s'),
          ReviewRow(
            'Tempo de oportunidade no final',
            '${state.tempoAplicacao.toStringAsFixed(0)} min',
          ),
          if (state.manejoSulco == ManejoSulco.reduzida) ...[
            ReviewRow('Origem da redução', state.origemVazaoReduzida.name),
            ReviewRow(
              'Vazão reduzida informada',
              state.origemVazaoReduzida == OrigemVazaoReduzida.informada
                  ? '${state.vazaoReduzidaLs.toStringAsFixed(2)} L/s'
                  : 'Calculada conforme origem selecionada',
            ),
            ReviewRow(
              'Atraso para redução',
              '${state.tempoMudancaMin.toStringAsFixed(0)} min',
            ),
          ],
          if (state.manejoSulco == ManejoSulco.surtir) ...[
            ReviewRow(
              'Duração do ciclo',
              '${state.cicloSurtirMin.toStringAsFixed(0)} min',
            ),
            ReviewRow(
              'Duração da pausa',
              '${state.tempoMudancaMin.toStringAsFixed(0)} min',
            ),
          ],
          ReviewRow(
            'Jornada diária',
            '${state.jornadaDiariaH.toStringAsFixed(1)} h',
          ),
          ReviewRow(
            'Vazão disponível',
            '${state.vazaoDisponivelLps.toStringAsFixed(2)} L/s',
          ),
          ReviewRow(
            'Perdas de condução',
            '${state.perdasConducaoLs.toStringAsFixed(2)} L/s',
          ),
        ],
      ),
    ];
  }
}

class ReviewSection {
  const ReviewSection({
    required this.icon,
    required this.title,
    required this.rows,
  });
  final IconData icon;
  final String title;
  final List<ReviewRow> rows;
}

class ReviewRow {
  const ReviewRow(this.label, this.value);
  final String label;
  final String value;
}
