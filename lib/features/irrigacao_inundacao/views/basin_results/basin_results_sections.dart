// Seções auditáveis do resultado de inundação (Fase 6). Cada linha preserva
// os rótulos e a didática da tela original: hipóteses, cultura,
// clima e demanda, operação por regime, anexos exclusivos do método e
// métricas completas, com referência à Aula 8.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/anexos_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/models/validacao_superficie.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_reference_panel.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

import 'basin_results_kpis.dart';

/// Ícone por status do impedimento do modelo (G1/G2/G9).
IconData iconeStatusBasin(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo => AppIcons.sucesso,
  BorderStatus.avisoOrientativo => AppIcons.atencao,
  _ => AppIcons.statusBloqueio,
};

/// Texto humano por status; o código canônico fica na seção de auditoria.
String textoStatusBasin(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo =>
    'Cálculo concluído dentro do modelo; nenhuma ressalva.',
  BorderStatus.avisoOrientativo =>
    'Cálculo concluído; há recomendação orientativa de referência.',
  BorderStatus.entradaInvalida =>
    'Há entrada pendente ou inválida; complete os dados faltantes.',
  BorderStatus.foraDoDominio =>
    'Geometria ou regime fora do domínio aceito pelo modelo.',
  _ => 'Há ressalva registrada pelo modelo; trate o resultado com cautela.',
};

/// Seções auditáveis do resultado de inundação: dados e hipóteses, cultura,
/// clima e demanda, operação por regime, planejamento, seleção de vazão,
/// volumes do arroz, métricas completas e comparação de cenários. A seção
/// "Salvar este projeto" permanece no orquestrador, junto da exportação.
List<Widget> secoesResultadoBasin({
  required BuildContext context,
  required WidgetRef ref,
  required bool podeCompararCenarios,
  required ProjetoInundacao project,
  required SimulationResult r,
}) {
  final text = Theme.of(context).textTheme;
  String m(String chave) {
    final v = r.metricas[chave];
    if (v == null) return '—';
    final unidade = r.unidadesMetricas[chave];
    return unidade == null || unidade.isEmpty ? f(v) : '${f(v)} $unidade';
  }

  Widget row(
    String label,
    String value, {
    String? detail,
    bool warning = false,
    String? pagina,
  }) => IrrigationAuditRow(
    label,
    value,
    detail: detail,
    isWarning: warning,
    pagina: pagina,
  );
  Widget section(
    String title,
    List<Widget> children, {
    IconData? icon,
    bool advanced = false,
    String? pagina,
  }) => IrrigationAuditSection(
    title: title,
    icon: icon ?? AppIcons.relatorio,
    initiallyExpanded: !advanced,
    pagina: pagina,
    children: children,
  );
  return [
    section('Dados e hipóteses', [
      row(
        'Regime',
        project.regime.displayName,
        detail: 'Rótulo didático do modelo.',
      ),
      row(
        'Cenário de infiltração',
        '${project.cenarioInfiltracao.displayName} · '
            'k = ${f(project.k, casas: 6)}, '
            'a = ${f(project.a)}, '
            'VIB = ${f(project.vibMMin, casas: 6)}',
      ),
      row(
        'Documento de referência',
        'Aula 8 — Irrigação por Inundação (UNIPAMPA)',
      ),
      row(
        'Páginas-fonte',
        '16, 17, 20, 34–35, 38, 45, 54–62, 64–84',
      ),
      row(
        'Comprimento do tabuleiro',
        '${f(project.comprimentoM)} m',
      ),
      row('Largura do tabuleiro', '${f(project.larguraM)} m'),
      row('Área do tabuleiro', m('Área do tabuleiro')),
      row(
        'Declividade',
        '${f(project.declividade, casas: 5)} m/m',
      ),
      row('Altura da taipa', '${f(project.alturaDiqueM)} m'),
      row('Base da taipa', '${f(project.baseDiqueM)} m'),
      row('Margem livre', '${f(project.margemLivreM)} m'),
      row('k', '${f(project.k, casas: 6)} m/min^a'),
      row('Expoente a', f(project.a, casas: 4)),
      row('VIB', '${f(project.vibMMin, casas: 6)} m/min'),
      row('Rugosidade de Manning n', f(project.rugosidadeN)),
    ], icon: AppIcons.projetoArea),
    section(
      'Cultura e sistema radicular',
      [
        row(
          'Cultura',
          project.culturaEfetiva ?? 'Não informado',
          detail:
              'Nome usado pelo preset e pela demanda; vazio é '
              'lacuna, não zero.',
        ),
        row(
          'Coeficiente da cultura Kc',
          project.agronomia?.kc == null
              ? 'Não informado'
              : f(project.agronomia?.kc),
          detail:
              'Entra em ETc = ETo × Kc quando o método usa ETo.',
        ),
        row(
          'Profundidade do sistema radicular z',
          project.agronomia?.profundidadeRaizesCm == null
              ? 'Não informado'
              : '${f(project.agronomia?.profundidadeRaizesCm)} cm',
          detail: 'Entra na IRN calculada.',
        ),
        row(
          'Fração de água disponível f',
          project.agronomia?.fracaoDisponivel == null
              ? 'Não informado'
              : f(project.agronomia?.fracaoDisponivel),
          detail: 'Entra na IRN calculada.',
        ),
        if (project.regime == TipoInundacao.intermitente) ...[
          row(
            'Umidade na capacidade de campo UCC',
            project.agronomia?.uccPercentual == null
                ? 'Não informado'
                : '${f(project.agronomia?.uccPercentual)} %',
            detail: 'Entra na IRN calculada.',
          ),
          row(
            'Umidade no ponto de murcha UPMP',
            project.agronomia?.upmpPercentual == null
                ? 'Não informado'
                : '${f(project.agronomia?.upmpPercentual)} %',
            detail: 'Entra na IRN calculada.',
          ),
          row(
            'Densidade aparente Ds',
            project.agronomia?.densidadeGcm3 == null
                ? 'Não informado'
                : '${f(project.agronomia?.densidadeGcm3)} g/cm³',
            detail: 'Entra na IRN calculada.',
          ),
        ],
      ],
      icon: AppIcons.projetoCultura,
    ),
    section(
      'Clima e demanda',
      [
        row('Método da ETc', switch (project.metodoEtc) {
          MetodoEtc.adotada => 'ETc adotada (digitação)',
          MetodoEtc.etoVezesKc => 'ETo × Kc',
          MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
        }, detail: 'Como o projeto define a demanda da cultura.'),
        if (project.metodoEtc == MetodoEtc.etoVezesKc)
          row(
            'ETo',
            project.etoMmDia == null
                ? 'Não informado'
                : '${f(project.etoMmDia)} mm/dia',
            detail: 'Referência digitada; ETc = ETo × Kc.',
          )
        else if (project.metodoEtc == MetodoEtc.blaneyCriddle)
          row(
            'ETo (Blaney–Criddle)',
            project.etoBlaneyCriddleMmDia == null
                ? 'Não calculado'
                : '${f(project.etoBlaneyCriddleMmDia)} mm/dia',
            detail:
                'Estimada com temperatura, latitude e mês; se '
                'faltar entrada, não vira zero.',
          ),
        row(
          'ETc efetiva',
          project.etcMmDia == null
              ? 'Não calculado'
              : '${f(project.etcMmDia)} mm/dia',
          detail:
              'Demanda da cultura adotada pelo balanço do '
              'resultado.',
        ),
        row(
          'Origem da precipitação',
          switch (project.origemChuva) {
            OrigemChuva.naoInformada => 'Não informada',
            OrigemChuva.efetiva => 'Efetiva adotada',
            OrigemChuva.observada => 'Efetiva observada',
            OrigemChuva.provavel =>
              'Provável (não convertida em efetiva)',
          },
          detail: project.origemChuva == OrigemChuva.provavel
              ? 'Chuva provável registrada; não creditada como '
                    'Pef sem método explícito.'
              : null,
          warning: project.origemChuva == OrigemChuva.provavel,
        ),
        row(
          'Precipitação efetiva Pef',
          project.precipitacaoEfetivaEfetivaMmDia == null
              ? 'Não informado'
              : '${f(project.precipitacaoEfetivaEfetivaMmDia)} '
                    'mm/dia',
          detail: 'Subtraída da ETc no balanço.',
        ),
        if (project.regime == TipoInundacao.intermitente) ...[
          row(
            'IRN efetiva '
            '(${project.origemIrn == OrigemIrnInundacao.informada ? 'informada' : 'calculada'})',
            project.irnEfetivaMm == null
                ? (project.origemIrn == OrigemIrnInundacao.informada
                      ? 'Não informado'
                      : 'Não calculado')
                : '${f(project.irnEfetivaMm)} mm',
            detail:
                'A informada prevalece sobre a calculada; a '
                'origem é sempre exibida.',
          ),
          if (project.laminaRequeridaMm != null &&
              project.irnCalculadaMm != null &&
              (project.laminaRequeridaMm! - project.irnCalculadaMm!)
                      .abs() >
                  1e-6) ...[
            row(
              'IRN informada prevalece',
              '${f(project.laminaRequeridaMm)} mm',
              detail:
                  'As duas IRNs são exibidas; nenhuma '
                  'sobrescreve a outra em silêncio.',
            ),
            row(
              'IRN calculada (auditoria)',
              '${f(project.irnCalculadaMm)} mm',
              detail: 'Somente auditoria nesta situação.',
            ),
          ],
          row(
            'TR = IRN / (ETc − Pef)',
            project.turnoRegaIrnDias == null
                ? 'Não calculado'
                : '${f(project.turnoRegaIrnDias, casas: 1)} dias',
            detail:
                'Turno de rega pela demanda líquida; compare '
                'com o intervalo.',
          ),
        ] else ...[
          row(
            'IRN',
            'Não aplicável',
            detail:
                'O regime contínuo não usa a lâmina requerida '
                'intermitente.',
          ),
          row(
            'TR (turno de rega contínuo)',
            r.metricas['Turno de rega'] == null
                ? 'Não calculado'
                : '${f(r.metricas['Turno de rega'], casas: 1)} '
                      'dias',
            detail:
                'TR = DTA · Z · f / ETc; a ETc vem do clima e '
                'os campos de camada estão na etapa de Cultura.',
          ),
        ],
      ],
      icon: AppIcons.projetoClima,
    ),
    if (project.regime == TipoInundacao.intermitente)
      section('Operação intermitente', [
        row(
          'Lâmina requerida',
          '${f(project.laminaRequeridaMm)} mm',
        ),
        row(
          'Vazão total aplicada',
          '${f(project.vazaoAplicadaLs)} L/s',
        ),
        row(
          'Origem da vazão',
          project.vazaoTotalLs == null
              ? 'Limite de erosão (sem candidata explícita)'
              : 'Vazão informada no projeto',
        ),
        row(
          'Vazão erosiva Vmax',
          '${f(project.vmaxMMin, casas: 4)} m/min',
        ),
        row(
          'ET do intervalo',
          '${f(project.etIntermitenteMmDia)} mm/dia',
        ),
        row(
          'Intervalo entre irrigações',
          '${f(project.intervaloDias?.toDouble())} dias',
        ),
        if (project.candidatasVazaoLs.isNotEmpty)
          row(
            'Candidatas informadas',
            project.candidatasVazaoLs.map((v) => f(v)).join(', '),
          ),
      ], icon: AppIcons.projetoOperacao)
    else
      section('Operação contínua', [
        row('Área irrigada', '${f(project.areaHectares)} ha'),
        row('Porosidade', f(project.porosidade)),
        row(
          'Profundidade da camada',
          '${f(project.profundidadeCamadaMm)} mm',
        ),
        row(
          'Condutividade K0',
          '${f(project.condutividadeHidraulicaMmDia)} mm/dia',
        ),
        row('DTA', '${f(project.dtaMmCm)} mm/cm'),
        row(
          'Fator de disponibilidade',
          f(project.fatorDisponibilidade),
        ),
        row(
          'Evapotranspiração',
          '${f(project.evapotranspiracaoMmDia)} mm/dia',
        ),
        row(
          'Lâmina superficial',
          '${f(project.laminaSuperficialMm)} mm',
        ),
        row(
          'Período de atendimento PI',
          '${project.periodoDias} dias',
        ),
      ], icon: AppIcons.projetoOperacao),
    if (r.checagemOperacional != null)
      BasinOperationalCheckSection(
        checagem: r.checagemOperacional!,
        icon: AppIcons.projetoOperacao,
      ),
    if (r.planejamentoParcelas != null)
      section('Planejamento em parcelas', [
        row(
          'Tempo por parcela TPP',
          '${f(r.planejamentoParcelas!.tppMin)} min',
        ),
        row(
          'NPD teórico',
          '${f(r.planejamentoParcelas!.npdTeorico)} parcelas/dia',
        ),
        row(
          'NPD adotado',
          '${r.planejamentoParcelas!.npdInteiro} parcelas/dia',
        ),
        row(
          'Área por parcela APP',
          '${f(r.planejamentoParcelas!.appM2)} m²',
        ),
        row(
          'Largura útil do tabuleiro w0',
          '${f(r.planejamentoParcelas!.larguraTabuleiroM)} m',
        ),
        row(
          'Tabuleiros na parcela (NTP)',
          '${r.planejamentoParcelas!.tabuleirosPorParcela}',
        ),
        row(
          'Total de tabuleiros NTT',
          '${r.planejamentoParcelas!.ntt}',
        ),
        row(
          'Vazão total Q',
          '${f(r.planejamentoParcelas!.qTotalLS)} L/s',
        ),
      ], icon: AppIcons.projetoOperacao),
    if (r.selecaoVazao != null)
      section('Seleção de vazão', [
        row(
          'Vazão escolhida',
          '${f(r.selecaoVazao!.vazaoEscolhidaLs)} L/s',
        ),
        row(
          'Q0 da escolhida',
          '${f(r.selecaoVazao!.q0M3MinM, casas: 4)} m³/(min·m)',
        ),
        row(
          'Eficiência obtida',
          '${f(r.selecaoVazao!.eficienciaPercent)}%',
        ),
        row(
          'Candidatas avaliadas',
          '${r.selecaoVazao!.candidatasAvaliadas}',
        ),
        row(
          'Candidatas rejeitadas',
          '${r.selecaoVazao!.candidatasRejeitadas}',
          detail:
              'Rejeição por erosão, geometria ou eficiência '
              'abaixo da melhor opção',
        ),
      ], icon: AppIcons.comparar),
    if (r.volumesArroz != null)
      section('Volumes de água do arroz', [
        row(
          'Umidade do ponto de torrão PT',
          f(r.volumesArroz!.volumes.pt),
        ),
        row(
          'Umidade da saturação US',
          f(r.volumesArroz!.volumes.us),
        ),
        row(
          'V1 (sem dados gravimétricos)',
          r.volumesArroz!.volumes.v1M3Ha == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.v1M3Ha)} m³/ha',
        ),
        row('V2', '${f(r.volumesArroz!.volumes.v2M3Ha)} m³/ha'),
        row('V3', '${f(r.volumesArroz!.volumes.v3M3Ha)} m³/ha'),
        row('V4', '${f(r.volumesArroz!.volumes.v4M3Ha)} m³/ha'),
        row(
          'V5 (MS do saco)',
          r.volumesArroz!.volumes.v5M3Ha == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.v5M3Ha)} m³/ha',
        ),
        row(
          'Volume total Vt',
          r.volumesArroz!.volumes.vtM3Ha == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.vtM3Ha)} m³/ha',
        ),
        row(
          'Matéria seca total',
          r.volumesArroz!.volumes.materiaSecaTotalKgHa == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.materiaSecaTotalKgHa)} kg/ha',
        ),
        row(
          'Vazão de enchimento Q1',
          r.volumesArroz!.volumes.q1M3S == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.q1M3S)} m³/s',
          detail: r.volumesArroz!.volumes.q1M3S == null
              ? 'Dado ausente na fonte; não presumido.'
              : 'Vazão calculada pelo método do arroz.',
          warning: r.volumesArroz!.volumes.q1M3S == null,
        ),
        row(
          'Vazão de manutenção Q2',
          r.volumesArroz!.volumes.q2M3S == null
              ? '—'
              : '${f(r.volumesArroz!.volumes.q2M3S)} m³/s',
          detail: r.volumesArroz!.volumes.q2M3S == null
              ? 'Dado ausente na fonte; não presumido.'
              : 'Vazão calculada pelo método do arroz.',
          warning: r.volumesArroz!.volumes.q2M3S == null,
        ),
        for (final ausente in r.volumesArroz!.volumes.dadosAusentes)
          row(
            'Dado ausente na fonte',
            ausente,
            warning: true,
            detail:
                'Não presumido; lacuna preservada do quadro original.',
          ),
      ], icon: AppIcons.balancoHidrico),
    BasinReferencePanel(projeto: project),
    section(
      'Métricas completas',
      [
        for (final chave in r.metricas.keys.toList()..sort())
          row(chave, m(chave)),
        if (r.alertaVazaoExcedida != null)
          row(
            'Alerta de vazão',
            r.alertaVazaoExcedida!,
            warning: true,
          ),
        if (r.alertaInfiltracao != null)
          row(
            'Alerta de infiltração',
            r.alertaInfiltracao!,
            warning: true,
          ),
      ],
      icon: AppIcons.relatorio,
      advanced: true,
    ),
    if (podeCompararCenarios &&
        project.regime == TipoInundacao.intermitente &&
        (project.dadosPrimeira != null || project.dadosTerceira != null))
      section(
        'Comparar cenários de infiltração',
        [
          Text(
            'Simula separadamente a primeira e a terceira '
            'irrigação com k, a e VIB próprios, pelo mesmo '
            'motor de simulação.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {
              try {
                final c = calcularComparacaoCenarios(project);
                ref.read(basinScenarioComparisonProvider.notifier).state =
                    c;
              } on FormatException catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            icon: const Icon(AppIcons.comparar),
            label: const Text('Comparar cenários'),
          ),
        ],
        icon: AppIcons.comparar,
        advanced: true,
      ),
  ];
}
