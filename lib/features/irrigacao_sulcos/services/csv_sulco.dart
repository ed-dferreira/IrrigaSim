import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/medicoes_campo.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/estado_parametros_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/indicadores_balanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

/// CSV completo do projeto de sulcos: entradas, ensaios, indicadores,
/// métricas, planejamento e séries dos gráficos.
String csvSulco(EstadoParametrosSulco state, SimulationResult result) {
  final rows = <String>[
    'grupo;indicador;valor;unidade',
    'identificação;método;Sulco;',
    'entrada;comprimento;${state.comprimento};m',
    'entrada;declividade longitudinal;${state.declividade};m/m',
    'entrada;desnível longitudinal;${state.desnivelM};m',
    'entrada;distância longitudinal;${state.distanciaHorizontalM};m',
    'entrada;desnível transversal;${state.desnivelTransversalM};m',
    'entrada;distância transversal;${state.distanciaTransversalM};m',
    'entrada;textura solo;${state.texturaSolo.displayName};',
    'entrada;coeficiente infiltração k;${state.k};',
    'entrada;expoente a;${state.a};',
    if (state.origemAvanco == OrigemAvanco.estimativa) ...[
      'entrada;coeficiente de avanço k;${state.coeficienteAvancoK};min/m^b',
      'entrada;expoente de avanço b;${state.expoenteAvancoB};',
      'entrada;distância X de referência;${state.distanciaReferenciaAvancoM};m',
    ],
    'entrada;vazão;${state.vazao};L/s',
    'entrada;tempo de oportunidade final;${state.tempoAplicacao};min',
    'entrada;lâmina requerida;${state.laminaRequerida};mm',
    'entrada;tipo de sulco;${state.tipoSulco?.name ?? 'não aplicável'};',
    'entrada;manejo de sulco;${state.manejoSulco.name};',
    if (state.manejoSulco == ManejoSulco.reduzida) ...[
      'entrada;origem da vazão reduzida;${state.origemVazaoReduzida.name};',
      if (state.origemVazaoReduzida == OrigemVazaoReduzida.informada)
        'entrada;vazão reduzida informada;${state.vazaoReduzidaLs};L/s',
      if (state.origemVazaoReduzida == OrigemVazaoReduzida.vib) ...[
        'entrada;VIB para F23;${state.vib};m/min',
        'entrada;fator F23;${state.fator11Vib ? 1.1 : 1.0};',
      ],
      'entrada;atraso da redução após Ta;${state.tempoMudancaMin};min',
    ],
    if (state.manejoSulco == ManejoSulco.surtir) ...[
      'entrada;duração do ciclo surtir;${state.cicloSurtirMin};min',
      'entrada;pausa do ciclo surtir;${state.tempoMudancaMin};min',
    ],
    'entrada;área efetiva;${state.areaHectares};ha',
    'entrada;período de irrigação;${state.periodoIrrigacaoDias};dias',
    'entrada;tempo entre parcelas;${state.tempoMudancaParcelaMin};min',
    'entrada;jornada diária;${state.jornadaDiariaH};h/dia',
    'entrada;vazão disponível;${state.vazaoDisponivelLps};L/s',
    'entrada;perdas de condução;${state.perdasConducaoLs};L/s',
    'entrada;Manning n;${state.manningN};',
    'entrada;sigma Z;${state.sigmaZ};',
    'entrada;origem avanço;${state.origemAvanco.name};',
    if (state.origemAvanco == OrigemAvanco.ensaio) ...[
      'ensaio avanço;vazão medida;${state.vazaoEnsaioAvancoLs ?? 'não informada'};L/s',
      'ensaio avanço;condições;${(state.condicoesEnsaioAvanco ?? '').replaceAll(';', ',').replaceAll('\n', ' ')};',
    ],
    if (state.ensaioErosao case final ensaio?) ...[
      'ensaio erosão;vazão medida;${ensaio.vazaoLs};L/s',
      'ensaio erosão;condições;${ensaio.condicoes.replaceAll(';', ',').replaceAll('\n', ' ')};',
      'ensaio erosão;erosão observada;${ensaio.erosaoObservada};',
    ],
    'entrada;método curva avanço;${state.metodoCurvaAvanco.name};',
    'entrada;origem infiltração;${state.origemCurvaInfiltracao.name};',
    if (state.origemCurvaInfiltracao ==
        OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
      'entrada;comprimento do ensaio de infiltração;${state.distanciaEnsaioInfiltracaoM};m',
      'entrada;espaçamento do ensaio de infiltração;${state.espacamentoEnsaioInfiltracaoM};m',
    ],
    'entrada;hipótese recessão;${state.hipoteseRecessao.name};',
    'resultado;${result.balancoSulco == null ? 'eficiência de aplicação' : 'Ea slide (Lf/Lm)'};${result.eficiencia};%',
    if (result.balancoSulco case final balanco?) ...[
      'resultado;Ea integral (Lútil/Lm);${balanco.eficienciaAplicacaoIntegralPercentual};%',
      'resultado;Pp slide (Lmi−IRN)/Lm;${balanco.perdaPercolacaoSlidePercentual?.toString() ?? 'não aplicável'};%',
      'resultado;Pp integral;${balanco.perdaPercolacaoIntegralPercentual};%',
      'resultado;Pe integral;${balanco.perdaEscoamentoIntegralPercentual};%',
      'resultado;déficit espacial;${balanco.deficitMm};mm',
      'resultado;domínio do perfil;0 a ${state.comprimento} m (trapézios igualmente espaçados);',
    ],
    'resultado;CUC;${result.cuc};%',
    'resultado;DU;${result.du};%',
    'resultado;eficiência requerimento;${result.eficienciaRequerimento};%',
    'resultado;lâmina média;${result.laminaMedia * 1000};mm',
    'resultado;tempo de avanço;${result.tempoAvanco};min',
    'resultado;perda percolação;${result.perdaPercolacao};%',
    'resultado;perda escoamento;${result.perdaEscoamento};%',
  ];
  for (final entry in result.metricas.entries) {
    rows.add(
      'resultado;${entry.key};${entry.value};${result.unidadesMetricas[entry.key] ?? ''}',
    );
  }
  if (result.planejamentoOperacional case final planning?) {
    for (final entry in planning.toMap().entries) {
      rows.add('planejamento operacional;${entry.key};${entry.value};');
    }
  }
  for (var index = 0; index < state.pontosEnsaioAvanco.length; index++) {
    final point = state.pontosEnsaioAvanco[index];
    rows.add(
      'ensaio avanço;distância da observação ${index + 1};${point.distanciaM};m',
    );
    rows.add(
      'ensaio avanço;tempo da observação ${index + 1};${point.tempoMin};min',
    );
  }
  if (state.origemAvanco == OrigemAvanco.ensaio &&
      state.metodoCurvaAvanco == MetodoAjusteAvanco.doisPontos &&
      state.pontosEnsaioAvanco.isEmpty) {
    rows.add(
      'ensaio avanço;distância intermediária;${state.distanciaEnsaioIntermediariaM};m',
    );
    rows.add(
      'ensaio avanço;tempo intermediário;${state.tempoEnsaioIntermediarioMin};min',
    );
    rows.add('ensaio avanço;distância final;${state.comprimento};m');
    rows.add('ensaio avanço;tempo final;${state.tempoAvancoFinalMin};min');
  }
  for (var index = 0; index < state.medicoesEntradaSaida.length; index++) {
    final point = state.medicoesEntradaSaida[index];
    rows.add(
      'ensaio infiltração;tempo da observação ${index + 1};${point.tempoMin};min',
    );
    rows.add(
      'ensaio infiltração;vazão de entrada ${index + 1};${point.vazaoEntradaLs};L/s',
    );
    rows.add(
      'ensaio infiltração;vazão de saída ${index + 1};${point.vazaoSaidaLs};L/s',
    );
  }
  for (var index = 0; index < state.medicoesRecessao.length; index++) {
    final point = state.medicoesRecessao[index];
    rows.add(
      'ensaio recessão;distância da estaca ${index + 1};${point.distanciaM};m',
    );
    rows.add(
      'ensaio recessão;instante medido ${index + 1};${point.instanteRecessaoMin};min',
    );
  }
  for (var i = 0; i < result.curvaAvanco.length; i++) {
    final point = result.curvaAvanco[i];
    rows.add('série avanço;posição ${i + 1};${point.y};m');
    rows.add('série avanço;tempo ${i + 1};${point.x};min');
  }
  for (var i = 0; i < result.curvaOportunidade.length; i++) {
    final point = result.curvaOportunidade[i];
    rows.add('série oportunidade;distância ${i + 1};${point.x};m');
    rows.add('série oportunidade;tempo ${i + 1};${point.y};min');
  }
  for (var i = 0; i < result.perfilLongitudinal.length; i++) {
    rows.add(
      'série infiltração;ponto ${i + 1};${result.perfilLongitudinal[i] * 1000};mm',
    );
  }
  return rows.join('\n');
}
