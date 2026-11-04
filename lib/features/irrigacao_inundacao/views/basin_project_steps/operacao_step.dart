import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/nucleo_referencia_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/planejamento_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_reference_panel.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 7: vazão, jornada, parcelas e checagem hidráulica (G3), com as
/// lavouras do intermitente (candidatas, G12 e prévia de seleção de vazão).
List<Widget> operacaoStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) => [
  fields.number(
    'vazaoDisponivelLps',
    'Vazão disponível na fonte',
    project.vazaoDisponivelLps,
    'L/s',
  ),
  fields.number('jornadaHoras', 'Jornada de trabalho', project.jornadaHoras, 'h'),
  fields.number(
    'mudancaParcelaMin',
    'Mudança de parcela',
    project.mudancaParcelaMin,
    'min',
    zero: true,
  ),
  fields.number(
    'periodoDias',
    'Período de atendimento (PI)',
    project.periodoDias.toDouble(),
    'dias',
  ),
  fields.number(
    'tabuleirosPorParcela',
    'Tabuleiros por parcela (NTP)',
    project.tabuleirosPorParcela.toDouble(),
    'un.',
  ),
  if (project.regime == TipoInundacao.intermitente) ...[
    fields.number(
      'vazaoTotalLs',
      'Vazão total aplicada (opcional)',
      project.vazaoTotalLs,
      'L/s',
      optional: true,
    ),
    fields.number(
      'rugosidadeN',
      'Rugosidade de Manning (n)',
      project.rugosidadeN,
      '—',
    ),
    fields.number('rInicial', 'Expoente r inicial', project.rInicial, '—'),
    fields.number('vmaxMMin', 'Vazão erosiva Vmax', project.vmaxMMin, 'm/min'),
    fields.number(
      'intervaloDias',
      'Intervalo entre irrigações',
      project.intervaloDias?.toDouble(),
      'dias',
    ),
    TextFormField(
      key: const ValueKey('candidatasVazao'),
      initialValue: project.candidatasVazaoLs
          .map((item) => item.toString())
          .join(', '),
      decoration: const InputDecoration(
        labelText: 'Vazões candidatas (opcional, em L/s)',
        helperText:
            'Separe por vírgula; a candidata com maior Ea entre as viáveis '
            'é escolhida, sem afirmação de ótimo global.',
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\s]')),
      ],
      onChanged: (value) {
        fields.unconfirm();
        fields.controller.setCandidatasVazao(value);
      },
    ),
    ..._vazaoUnidadesFields(fields, project),
    const IrrigationFormulaCard(
      description:
          'Tempo por parcela e número de parcelas diárias; ti vem '
          'da dimensão e tm é a mudança de parcela acima.',
    ),
    const IrrigationFormulaCard(
      description:
          'Área por parcela no período de atendimento; a simulação '
          'anexa também o total de mudanças e a soma das vazões '
          'por turno.',
    ),
    ..._g12AvisoFields(fields, project),
    ..._selecaoCandidatasFields(fields, project),
  ],
  ..._checagemFields(project),
];

/// Aviso G12 (p. 63): o intervalo programado deve cobrir o turno de rega
/// pela IRN; a comparação é só orientativa, a decisão é do usuário.
List<Widget> _g12AvisoFields(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final intervalo = project.intervaloDias;
  final tr = project.turnoRegaIrnDias;
  if (intervalo == null || tr == null || intervalo >= tr) return const [];
  return [
    IrrigationAuditRow(
      'Intervalo × turno de rega',
      '$intervalo dias vs ${fields.format(tr, casas: 1)} dias',
      detail:
          'O intervalo programado é menor que o turno de rega pela IRN; o '
          'mínimo recomendado é IRN/(ETc − Pef).',
      isWarning: true,
    ),
  ];
}

/// Prévia da seleção de melhor Ea entre as vazões candidatas (p. 60);
/// espelha BasinSimulationCoordinator._selecionarVazao sem tocá-la.
List<Widget> _selecaoCandidatasFields(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final candidatas = project.candidatasVazaoLs;
  final largura = project.larguraM;
  final comprimento = project.comprimentoM;
  final n = project.rugosidadeN;
  final k = project.k;
  final a = project.a;
  final vib = project.vibMMin;
  final irnM = project.laminaMediaPlanaltoM;
  final altura = project.alturaDiqueM;
  final margem = project.margemLivreM;
  if (candidatas.isEmpty ||
      largura == null ||
      comprimento == null ||
      n == null ||
      k == null ||
      a == null ||
      vib == null ||
      irnM == null ||
      altura == null ||
      margem == null) {
    return const [];
  }
  final solo = Infiltracao(k, a, vib);
  double? melhorEa;
  double? melhorLs;
  final linhas = <Widget>[];
  for (final qLs in candidatas) {
    final q0 = qLs * 60 / 1000 / largura;
    double? ea;
    String status;
    try {
      final atual = dimensionar(
        solo,
        l: comprimento,
        n: n,
        irn: irnM,
        vmax: project.vmaxMMin,
        vazao: q0,
        rInicial: project.rInicial,
      );
      if (!diqueComporta(altura, atual.y0M, margem)) {
        status = 'Reprovada: y0 com a margem livre excede a taipa.';
      } else if (atual.eficienciaPercent > 100) {
        status = 'Reprovada: Ea maior que 100%.';
      } else {
        ea = atual.eficienciaPercent;
        status = 'Viável.';
        if (melhorEa == null || ea > melhorEa) {
          melhorEa = ea;
          melhorLs = qLs;
        }
      }
    } on ArgumentError catch (erro) {
      status =
          'Reprovada: ${erro.message ?? 'vazão fora do domínio'}.';
    } on StateError {
      status = 'Reprovada: sem convergência na dimensão.';
    }
    linhas.add(
      IrrigationAuditRow(
        'Q = ${fields.format(qLs, casas: 1)} L/s',
        ea == null ? '—' : 'Ea = ${fields.format(ea, casas: 1)}%',
        detail: status,
        isWarning: ea == null,
      ),
    );
  }
  return [
    IrrigationAuditSection(
      title: 'Seleção de vazão entre candidatas',
      icon: AppIcons.projetoOperacao,
      children: [
        ...linhas,
        if (melhorEa != null && melhorLs != null)
          IrrigationAuditRow(
            'Vazão selecionada (maior Ea)',
            '${fields.format(melhorLs, casas: 1)} L/s · '
                'Ea ${fields.format(melhorEa, casas: 1)}%',
            detail:
                'Melhor Ea entre as candidatas viáveis; sem garantia de '
                'ótimo global.',
          ),
      ],
    ),
  ];
}

/// Unidades por unidade de largura (G11) e saldo de vazão da fonte.
List<Widget> _vazaoUnidadesFields(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final aplicada = project.vazaoAplicadaLs;
  final maxima = project.q0MaxLsTotal;
  final largura = project.larguraM;
  final q0Unit = aplicada == null || largura == null || largura <= 0
      ? null
      : aplicada * 60 / 1000 / largura;
  final q0MaxUnit = maxima == null || largura == null || largura <= 0
      ? null
      : maxima * 60 / 1000 / largura;
  final disponivel = project.vazaoDisponivelLps;
  final saldo = aplicada == null || disponivel == null
      ? null
      : disponivel - aplicada;
  return [
    if (q0Unit != null && q0MaxUnit != null)
      IrrigationFormulaCard(
        formula:
            'Q0 = ${fields.format(q0Unit, casas: 4)} m³/(min·m) · '
            'Q0max = ${fields.format(q0MaxUnit, casas: 4)} m³/(min·m)',
        description:
            'Totais: ${fields.format(aplicada, casas: 1)} L/s aplicados e '
            '${fields.format(maxima, casas: 1)} L/s não erosivos. '
            'Hidráulica calculada por unidade de largura.',
      ),
    ..._y0Fields(fields, project),
    if (saldo != null)
      IrrigationAuditRow(
        'Saldo de vazão (disponível − aplicada)',
        '${fields.format(saldo, casas: 1)} L/s',
        detail: saldo < 0
            ? 'A aplicação supera a vazão disponível da fonte.'
            : 'A fonte cobre a vazão aplicada ao tabuleiro.',
        isWarning: saldo < 0,
      ),
  ];
}

/// Profundidade normal na entrada y0 (G11, p. 54) pela mesma vazão
/// aplicada; null quando falta geometria ou a lei de avanço rejeita.
List<Widget> _y0Fields(BasinProjectFields fields, ProjetoInundacao project) {
  final aplicada = project.vazaoAplicadaLs;
  final largura = project.larguraM;
  final n = project.rugosidadeN;
  final l = project.comprimentoM;
  final q0Unit = aplicada == null || largura == null || largura <= 0
      ? null
      : aplicada * 60 / 1000 / largura;
  if (q0Unit == null || n == null || l == null) return const [];
  try {
    final y0 = profundidadeEntrada(q0Unit, n, l);
    return [
      IrrigationFormulaCard(
        formula:
            'y0 = ${fields.format(y0, casas: 4)} m (profundidade normal na '
            'entrada)',
        description:
            'A profundidade avança pela lei de avanço da vazão aplicada; o '
            'cálculo é por unidade de largura.',
      ),
    ];
  } on ArgumentError {
    return const [];
  }
}

/// Status da checagem operacional obrigatória (G3) para o projeto atual;
/// sem geometria/vazões completas não há o que comparar.
List<Widget> _checagemFields(ProjetoInundacao project) {
  final checagem = _checagemPreview(project);
  if (checagem == null) {
    return const [
      IrrigationFormulaCard(
        description:
            'Informe geometria, vazão disponível e área declarada para '
            'exibir a checagem operacional obrigatória.',
      ),
    ];
  }
  return [BasinOperationalCheckSection(checagem: checagem)];
}

ChecagemOperacional? _checagemPreview(ProjetoInundacao project) {
  final areaTabuleiro = project.areaTabuleiroM2;
  final areaDeclarada =
      project.areaTotalM2 ??
      project.areaUtilM2 ??
      (project.areaHectares == null ? null : project.areaHectares! * 10000);
  final disponivel = project.vazaoDisponivelLps;
  if (areaTabuleiro == null ||
      areaDeclarada == null ||
      areaDeclarada <= 0 ||
      disponivel == null ||
      disponivel <= 0) {
    return null;
  }
  final planejada = project.regime == TipoInundacao.intermitente
      ? project.vazaoAplicadaLs
      : fluxoPermanente(project)?.qeLS;
  if (planejada == null || planejada <= 0) return null;
  try {
    return const PlanejamentoInundacao().checarOperacao(
      vazaoPlanejadaLs: planejada,
      vazaoDisponivelLs: disponivel,
      areaTabuleiroM2: areaTabuleiro,
      areaDeclaradaM2: areaDeclarada,
    );
  } on ArgumentError {
    return null;
  }
}
