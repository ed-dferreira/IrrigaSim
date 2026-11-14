import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/indicadores_balanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/furrow_details_section.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/operational_planning_section.dart';

/// Seções auditáveis dos resultados de sulcos (medidas de segurança até
/// fórmulas). O SaveCard fica fora, pois depende do estado de salvamento.
List<Widget> secoesAuditoriaSulco(
  EstadoParametrosSulco state,
  SimulationResult result,
) {
  final tempoAvancoNaMetade = result.curvaAvanco.isEmpty
      ? state.tempoAvancoMetadeMin
      : result.curvaAvanco.reduce((left, right) {
          final leftDistance = (left.y - state.comprimento / 2).abs();
          final rightDistance = (right.y - state.comprimento / 2).abs();
          return leftDistance <= rightDistance ? left : right;
        }).x;
  return [
    IrrigationAuditSection(
      title: 'Medidas de segurança',
      icon: Icons.shield_rounded,
      children: [
        if (result.alertaInfiltracao case final aviso?)
          IrrigationAuditRow(
            'Domínio da infiltração',
            aviso,
            isWarning: true,
          ),
        IrrigationAuditRow(
          'Percolação integral',
          '${result.perdaPercolacao.toStringAsFixed(1)}%',
          detail: result.perdaPercolacao > 15
              ? 'Acima da referência indicativa (>15%)'
              : 'Abaixo da referência indicativa',
          isWarning: result.perdaPercolacao > 15,
        ),
        IrrigationAuditRow(
          'Escoamento integral',
          '${result.perdaEscoamento.toStringAsFixed(1)}%',
          detail: result.perdaEscoamento > 10
              ? 'Acima da referência indicativa (>10%)'
              : 'Abaixo da referência indicativa',
          isWarning: result.perdaEscoamento > 10,
        ),
        IrrigationAuditRow(
          'Eficiência para avaliação (${result.balancoSulco == null ? 'Ea' : 'Ea integral'})',
          '${(result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? result.eficiencia).toStringAsFixed(1)}%',
          detail:
              (result
                          .balancoSulco
                          ?.eficienciaAplicacaoIntegralPercentual ??
                      result.eficiencia) <
                  60
              ? 'Abaixo do critério indicativo (60%)'
              : (result
                            .balancoSulco
                            ?.eficienciaAplicacaoIntegralPercentual ??
                        result.eficiencia) >=
                    75
              ? 'Acima da referência de 75%'
              : 'Atende ao critério indicativo',
          isWarning:
              (result
                      .balancoSulco
                      ?.eficienciaAplicacaoIntegralPercentual ??
                  result.eficiencia) <
              60,
        ),
      ],
    ),
    const SizedBox(height: 20),
    IrrigationAuditSection(
      title: 'Dados de entrada',
      icon: Icons.input_rounded,
      children: [
        IrrigationAuditRow('Método', 'Sulco'),
        if (state.tipoSulco != null)
          IrrigationAuditRow('Tipo de sulco', state.tipoSulco!.displayName),
        IrrigationAuditRow(
          'Comprimento',
          '${state.comprimento.toStringAsFixed(0)} m',
        ),
        IrrigationAuditRow(
          'Espaçamento',
          '${state.larguraOuEspacamento.toStringAsFixed(2)} m',
        ),
        IrrigationAuditRow(
          'Declividade',
          '${state.declividade.toStringAsFixed(6)} m/m',
          detail: '${(state.declividade * 100).toStringAsFixed(4)}%',
        ),
        IrrigationAuditRow('Textura do solo', state.texturaSolo.displayName),
        IrrigationAuditRow('Coef. infiltração k', '${state.k}'),
        IrrigationAuditRow('Expoente a', '${state.a}'),
        if (state.origemAvanco == OrigemAvanco.estimativa)
          IrrigationAuditRow(
            'Curva de avanço informada',
            'Tx = ${state.coeficienteAvancoK.toStringAsPrecision(6)} · '
                'x^${state.expoenteAvancoB.toStringAsFixed(5)}; '
                'X=${state.comprimento.toStringAsFixed(2)} m',
            detail: 'k em min/mᵇ; Tx em minutos.',
          ),
        if (state.origemAvanco == OrigemAvanco.ensaio) ...[
          IrrigationAuditRow(
            'Pontos originais do ensaio de avanço',
            state.pontosEnsaioAvanco.isEmpty
                ? '2 pontos informados nas estacas intermediária e final'
                : '${state.pontosEnsaioAvanco.length} pontos medidos',
          ),
          for (final (index, point) in state.pontosEnsaioAvanco.indexed)
            IrrigationAuditRow(
              'Avanço medido ${index + 1}',
              '${point.distanciaM.toStringAsFixed(2)} m · ${point.tempoMin.toStringAsFixed(2)} min',
            ),
        ],
        if (state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
          IrrigationAuditRow(
            'Área do ensaio de infiltração',
            '${(state.distanciaEnsaioInfiltracaoM * state.espacamentoEnsaioInfiltracaoM).toStringAsFixed(2)} m²',
          ),
          for (final (index, point) in state.medicoesEntradaSaida.indexed)
            IrrigationAuditRow(
              'Entrada/saída ${index + 1}',
              't=${point.tempoMin.toStringAsFixed(2)} min · '
                  'Qin=${point.vazaoEntradaLs.toStringAsFixed(3)} L/s · '
                  'Qout=${point.vazaoSaidaLs.toStringAsFixed(3)} L/s',
            ),
        ],
        if (state.hipoteseRecessao == HipoteseRecessao.medidaPorEstaca)
          for (final (index, point) in state.medicoesRecessao.indexed)
            IrrigationAuditRow(
              'Recessão medida ${index + 1}',
              '${point.distanciaM.toStringAsFixed(2)} m · ${point.instanteRecessaoMin.toStringAsFixed(2)} min',
            ),
        IrrigationAuditRow(
          'Lâmina requerida',
          '${state.laminaRequerida.toStringAsFixed(0)} mm',
        ),
      ],
    ),
    const SizedBox(height: 16),
    IrrigationAuditSection(
      title: 'Avanço e infiltração',
      icon: Icons.output_rounded,
      children: [
        IrrigationAuditRow(
          'Vazão por sulco',
          '${(result.metricas['Vazão por sulco'] ?? state.vazao).toStringAsFixed(2)} L/s',
          detail: 'Calculado pela aplicação',
        ),
        IrrigationAuditRow(
          'Tempo de oportunidade',
          '${(result.metricas['Tempo de oportunidade'] ?? state.tempoAplicacao).toStringAsFixed(0)} min',
          detail: 'Calculado pela aplicação',
        ),
        IrrigationAuditRow(
          'Tempo de avanço em X',
          '${(result.metricas['Tempo Tx calculado em X'] ?? result.tempoAvanco).toStringAsFixed(2)} min',
          detail:
              'X = ${(result.metricas['Distância X de referência'] ?? state.distanciaReferenciaAvancoM).toStringAsFixed(2)} m',
        ),
        IrrigationAuditRow(
          'Tempo de fornecimento (Ti/Tt)',
          result.tempoFornecimentoMin == null
              ? 'Não calculado'
              : '${result.tempoFornecimentoMin!.toStringAsFixed(0)} min (${(result.tempoFornecimentoMin! / 60).toStringAsFixed(2)} h)',
          detail: 'Calculado pela aplicação',
        ),
        IrrigationAuditRow(
          'Avanço até metade',
          '${tempoAvancoNaMetade.toStringAsFixed(2)} min',
          detail: 'Na estaca mais próxima da metade do comprimento',
        ),
        IrrigationAuditRow(
          'Avanço até o final',
          '${result.tempoAvanco.toStringAsFixed(1)} min',
          detail: 'Calculado pela aplicação',
        ),
        IrrigationAuditRow(
          'Origem e ajuste do avanço',
          '${result.origemCurvaAvanco ?? 'Não registrado'} · '
              '${result.metodoCurvaAvanco ?? 'método indisponível'}',
        ),
        if (result.metricas['Coeficiente da curva de avanço']
            case final advanceK?)
          IrrigationAuditRow(
            'Curva ajustada Tx = k·xᵇ',
            'k = ${advanceK.toStringAsPrecision(6)}; '
                'b = ${(result.metricas['Expoente da curva de avanço'] ?? 0).toStringAsPrecision(5)}',
          ),
        if (result.metricas['R² log da curva de avanço']
            case final advanceR2?)
          IrrigationAuditRow(
            'Ajuste da regressão de avanço',
            'R² log = ${advanceR2.toStringAsFixed(5)}',
          ),
        IrrigationAuditRow(
          'Origem da infiltração',
          result.origemCurvaInfiltracao ?? 'Não registrada',
        ),
        if (result.metricas['Coeficiente VI ajustado'] case final viK?)
          IrrigationAuditRow(
            'Curva de taxa ajustada',
            'VI = ${viK.toStringAsPrecision(5)} · '
                'T^${(result.metricas['Expoente VI ajustado'] ?? 0).toStringAsFixed(4)} mm/h',
            detail: 'Integrada com fator 1/60 para infiltração acumulada.',
          ),
        if (result.metricas['Coeficiente acumulado ajustado']
            case final infiltrationK?)
          IrrigationAuditRow(
            'Equação acumulada ajustada',
            'I(T) = ${infiltrationK.toStringAsPrecision(6)} · '
                'T^${(result.metricas['Expoente acumulado ajustado'] ?? 0).toStringAsFixed(5)} mm',
            detail: 'Curva que alimenta o perfil de infiltração; k em mm/minⁿ e T em minutos.',
          ),
        if (state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
          IrrigationAuditRow(
            'Curva acumulada informada',
            'I = ${state.k} · T^${state.a} mm',
            detail: 'Coeficiente em mm/minⁿ; tempo em minutos.',
          ),
        IrrigationAuditRow(
          'Hipótese de recessão',
          result.hipoteseRecessao ?? 'Não registrada',
        ),
        if (result.extrapolouAvanco)
          const IrrigationAuditRow(
            'Cobertura do ensaio',
            'Curva extrapolada além da maior estaca medida',
            isWarning: true,
          ),
      ],
    ),
    const SizedBox(height: 16),
    IrrigationAuditSection(
      title: 'Aplicação e desempenho',
      icon: AppIcons.waterDrop,
      children: [
        IrrigationAuditRow(
          result.balancoSulco == null
              ? 'Eficiência de aplicação (Ea)'
              : 'Ea slide (Lf/Lm; não fecha balanço)',
          '${result.eficiencia.toStringAsFixed(2)}%',
          detail: result.classificacaoEa,
        ),
        if (result.balancoSulco case final balanco?) ...[
          IrrigationAuditRow(
            'Ea integral (Lútil/Lm)',
            '${balanco.eficienciaAplicacaoIntegralPercentual.toStringAsFixed(2)}%',
            detail: 'Usada nos critérios de avaliação; perfil de 0 a L',
          ),
          IrrigationAuditRow(
            'Pp slide (Lmi−IRN)/Lm',
            balanco.perdaPercolacaoSlidePercentual == null
                ? 'Não aplicável sob déficit'
                : '${balanco.perdaPercolacaoSlidePercentual!.toStringAsFixed(2)}%',
          ),
          IrrigationAuditRow(
            'Déficit espacial',
            '${balanco.deficitMm.toStringAsFixed(2)} mm',
            detail: 'IRN = lâmina útil + déficit',
          ),
        ],
        IrrigationAuditRow(
          'Uniformidade de Christiansen (CUC)',
          '${result.cuc.toStringAsFixed(2)}%',
          detail: result.classificacaoCuc,
        ),
        IrrigationAuditRow(
          'Uniformidade de distribuição (DU)',
          '${result.du.toStringAsFixed(2)}%',
          detail: result.classificacaoDu,
        ),
        if (result.eficienciaDistribuicaoEd != null)
          IrrigationAuditRow(
            'Eficiência de distribuição (Ed)',
            '${result.eficienciaDistribuicaoEd!.toStringAsFixed(2)}%',
            detail: 'Lf / [(Li + Lf) / 2] × 100',
          ),
        if (result.adequacaoUtilGa != null)
          IrrigationAuditRow(
            'Adequação útil (GA)',
            '${result.adequacaoUtilGa!.toStringAsFixed(2)}%',
            detail: 'Lâmina útil limitada à requerida; máximo 100%',
          ),
        IrrigationAuditRow(
          'Lâmina média infiltrada (Lmi)',
          '${(result.laminaMedia * 1000).toStringAsFixed(2)} mm',
        ),
        IrrigationAuditRow(
          'Tempo de avanço',
          '${result.tempoAvanco.toStringAsFixed(2)} min',
        ),
        IrrigationAuditRow(
          result.balancoSulco == null
              ? 'Perda por percolação'
              : 'Percolação integral',
          '${result.perdaPercolacao.toStringAsFixed(2)}%',
        ),
        IrrigationAuditRow(
          result.balancoSulco == null
              ? 'Perda por escoamento'
              : state.manejoSulco == ManejoSulco.reduzida
              ? 'Escoamento residual (cenário condicionado)'
              : 'Escoamento integral',
          '${result.perdaEscoamento.toStringAsFixed(2)}%',
          detail: state.manejoSulco == ManejoSulco.reduzida
              ? 'Pe = (Lm − Lmi) / Lm × 100; resíduo do balanço sob a hipótese de cobertura, não previsão hidráulica.'
              : 'Pe integral = (Lm − Lmi) / Lm × 100; balanço válido',
        ),
        if (state.manejoSulco == ManejoSulco.reduzida) ...[
          IrrigationAuditRow(
            'Tempo com vazão inicial',
            '${result.metricas['Tempo com vazão inicial']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão inicial'] == null ? '' : ' min'}',
            detail: 'Inclui avanço e atraso informado após Ta',
          ),
          IrrigationAuditRow(
            'Tempo com vazão reduzida',
            '${result.metricas['Tempo com vazão reduzida']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão reduzida'] == null ? '' : ' min'}',
            detail: 'As duas fases somam Ti/Tt',
          ),
        ],
        IrrigationAuditRow(
          'Eficiência de requerimento (Er)',
          '${result.eficienciaRequerimento.toStringAsFixed(2)}%',
        ),
      ],
    ),
    const SizedBox(height: 16),
    IrrigationAuditSection(
      title: 'Necessidade hídrica',
      icon: AppIcons.projetoClima,
      children: [
        if (state.laminaRequeridaResultado != null) ...[
          IrrigationAuditRow(
            'IRN',
            '${state.laminaRequeridaResultado!.irnMm.toStringAsFixed(2)} mm',
          ),
          IrrigationAuditRow(
            'Demanda líquida',
            '${state.laminaRequeridaResultado!.demandaLiquidaMmDia.toStringAsFixed(2)} mm/dia',
          ),
          IrrigationAuditRow(
            'Turno de rega (TR)',
            '${state.laminaRequeridaResultado!.turnoCalculadoDias.toStringAsFixed(2)} dias (operacional: ${state.laminaRequeridaResultado!.turnoOperacionalDias} dias)',
          ),
        ] else ...[
          const IrrigationAuditRow('IRN', 'Não calculada'),
          const IrrigationAuditRow('Demanda líquida', 'Não calculada'),
          const IrrigationAuditRow('Turno de rega (TR)', 'Não calculado'),
        ],
      ],
    ),
    const SizedBox(height: 16),
    FurrowDetailsSection(state: state, result: result),
    const SizedBox(height: 16),
    if (result.planejamentoOperacional != null) ...[
      OperationalPlanningSection(
        planejamento: result.planejamentoOperacional!,
      ),
      const SizedBox(height: 16),
    ],
    IrrigationAuditSection(
      title: 'Fórmulas utilizadas',
      icon: Icons.functions_rounded,
      children: [
        IrrigationFormulaCard(
          formula: result.balancoSulco == null
              ? 'Ea = (Lf / Lm) × 100'
              : 'Ea slide = (Lf / Lm) × 100',
          description: result.balancoSulco == null
              ? 'Eficiência de aplicação: lâmina infiltrada no final (Lf) sobre lâmina média aplicada (Lm).'
              : 'Indicador didático pelo final do sulco; não representa o fechamento volumétrico.',
        ),
        const IrrigationFormulaCard(
          formula: 'NTS = área / (C × E); NSD = NTS / período',
          description: 'Número total de sulcos e sulcos que precisam ser irrigados por dia.',
        ),
        const IrrigationFormulaCard(
          formula: 'TIP = Ti + tmudParcela; NPD = piso(jornada / TIP)',
          description: 'Ti/Tt é o fornecimento por sulco; tmudParcela é o intervalo entre parcelas, separado do atraso de redução de vazão.',
        ),
        const IrrigationFormulaCard(
          formula: 'NSP = NSD / NPD; Qprojeto = NSP × qi + perdas',
          description: 'A operação verifica lotes parciais no período, vazão disponível e se TIP cabe na jornada.',
        ),
        const IrrigationFormulaCard(
          formula: 'Ed = Lf / [(Li + Lf) / 2] × 100',
          description: 'Eficiência de distribuição pelos extremos do perfil; não é a DU.',
        ),
        const IrrigationFormulaCard(
          formula: 'GA útil = média[min(Li(x), IRN)] / IRN × 100',
          description: 'Adequação limitada a 100%; o excesso fica contabilizado como percolação.',
        ),
        const IrrigationFormulaCard(
          formula: 'Ea integral = Lútil/Lm; Pp integral = Lpercolada/Lm; Pe integral = (Lm−Lmi)/Lm',
          description: 'Médias espaciais por trapézios de 0 a L: Lmi = Lútil + Lpercolada; IRN = Lútil + déficit. Balanço inconsistente impede o resultado.',
        ),
        IrrigationFormulaCard(
          formula: state.manejoSulco == ManejoSulco.reduzida
              ? 'Lm = [qi·tInicial + qr·tReduzido] × 60 / (C·E)'
              : 'Lm = q·Tt × 60 / (C·E)',
          description: 'Vazão em L/s, tempos em min, comprimento e espaçamento em m; lâmina em mm.',
        ),
        IrrigationFormulaCard(
          formula: 'CUC = (1 - Σ|yi - ȳ| / (n × ȳ)) × 100',
          description: 'Uniformidade de Christiansen baseada na média absoluta dos desvios.',
        ),
        IrrigationFormulaCard(
          formula: 'DU = (L25 / ȳ) × 100',
          description: 'Uniformidade de distribuição: média dos 25% menores sobre a média.',
        ),
        IrrigationFormulaCard(
          formula: 'Tx = k × x^b',
          description: 'Curva de avanço: tempo na distância x.',
        ),
        if (state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
          const IrrigationFormulaCard(
            formula: 'I(To) = aI × Toⁿ',
            description: 'Equação acumulada informada; aI em mm/minⁿ e To em min.',
          ),
        if (state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
          const IrrigationFormulaCard(
            formula: 'VI(T) = K × Tⁿ',
            description: 'Taxa ajustada ao ensaio; K em mm/h e T em min.',
          ),
          const IrrigationFormulaCard(
            formula: 'I(T) = [K/(60×(n+1))] × T^(n+1)',
            description: 'Integração da taxa para formar a lâmina acumulada em mm.',
          ),
        ],
      ],
    ),
    const SizedBox(height: 16),
    if (result.alertaVazaoExcedida != null)
      IrrigationAlertBanner(message: result.alertaVazaoExcedida!),
  ];
}
