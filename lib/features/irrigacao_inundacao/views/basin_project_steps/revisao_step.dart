import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_reference_panel.dart';
import 'package:irrigasim/shared/clima/models/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 9: revisão completa do projeto, seções auditáveis por tema e o
/// painel didático de referência da Aula 8.
List<Widget> revisaoStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final agro = project.agronomia;
  final irnInformada = project.laminaRequeridaMm;
  final irnCalculada = project.irnCalculadaMm;
  final irnEfetiva = project.irnEfetivaMm;
  final divergente =
      irnInformada != null &&
      irnCalculada != null &&
      (irnInformada - irnCalculada).abs() > 1e-6;
  return [
    IrrigationAuditSection(
      title: 'Regime e infiltração',
      icon: AppIcons.inundacao,
      children: [
        fields.review(
          'Regime',
          project.regime == TipoInundacao.intermitente
              ? 'Intermitente (sem circulação)'
              : 'Permanente (com circulação)',
        ),
        fields.review(
          'Cenário de infiltração',
          project.cenarioInfiltracao.displayName,
        ),
        fields.review('Textura do solo', project.texturaSolo?.displayName ?? '—'),
        fields.review('k', fields.format(project.k)),
        fields.review('a', fields.format(project.a)),
        fields.review('VIB', fields.format(project.vibMMin)),
        fields.review('Rugosidade n', fields.format(project.rugosidadeN)),
        fields.review('ρ1 (auditoria)', fields.format(project.rho1F02)),
        fields.review('ρ2 (auditoria)', fields.format(project.rho2F02)),
      ],
    ),
    IrrigationAuditSection(
      title: 'Área, geometria e taipa',
      icon: AppIcons.projetoArea,
      children: [
        fields.review(
          'Área da unidade',
          project.areaTotalM2 == null
              ? '—'
              : '${fields.format(project.comprimentoAreaM)} × '
                    '${fields.format(project.larguraAreaM)} m '
                    '(${fields.format(project.areaTotalM2! / 10000)} ha)',
        ),
        fields.review(
          'Tabuleiro',
          project.areaTabuleiroM2 == null
              ? '—'
              : 'L ${fields.format(project.comprimentoM)} m × '
                    '${fields.format(project.larguraM)} m '
                    '(${fields.format(project.areaTabuleiroM2)} m²)',
        ),
        fields.review('Declividade', fields.format(project.declividade, casas: 5)),
        fields.review(
          'Lâmina média Lm',
          fields.format(project.laminaMediaPlanaltoM),
        ),
        fields.review(
          'Δz admissível (2/3 Lm)',
          fields.format(project.desnivelAdmissivelM),
        ),
        fields.review('Δz real', fields.format(project.desnivelRealM)),
        fields.review(
          'L máximo pela regra 2/3',
          fields.format(project.comprimentoMaximoDesnivelM),
        ),
        fields.review(
          'Taipa',
          'base ${fields.format(project.baseDiqueM)} m · altura '
              '${fields.format(project.alturaDiqueM)} m · margem '
              '${fields.format(project.margemLivreM)} m',
        ),
      ],
    ),
    if (project.regime == TipoInundacao.intermitente)
      IrrigationAuditSection(
        title: 'Intermitente',
        icon: AppIcons.curvaAvanco,
        children: [
          fields.review(
            'IRN efetiva (${project.origemIrn.displayName.toLowerCase()})',
            irnEfetiva == null
                ? (project.origemIrn == OrigemIrnInundacao.informada
                      ? 'Não informado'
                      : 'Não calculado')
                : '${fields.format(irnEfetiva)} mm',
          ),
          if (divergente) ...[
            fields.review(
              'IRN informada (prevalece, G14)',
              '${fields.format(irnInformada)} mm',
            ),
            fields.review(
              'IRN calculada (auditoria, G14)',
              '${fields.format(irnCalculada)} mm',
            ),
          ],
          fields.review(
            'Lâmina inicial Li',
            fields.format(project.laminaInicialMm),
          ),
          fields.review(
            'Lâmina final Lf',
            fields.format(project.laminaFinalMm),
          ),
          fields.review(
            'Intervalo (dias)',
            fields.format(project.intervaloDias?.toDouble()),
          ),
          fields.review('Vazão aplicada', fields.format(project.vazaoAplicadaLs)),
          fields.review(
            'Vazão disponível',
            fields.format(project.vazaoDisponivelLps),
          ),
          fields.review(
            'Q0max não erosiva',
            fields.format(project.q0MaxLsTotal),
          ),
          fields.review('Vmax', fields.format(project.vmaxMMin)),
          fields.review('Expoente r inicial', fields.format(project.rInicial)),
          fields.review(
            'Candidatas (L/s)',
            project.candidatasVazaoLs.isEmpty
                ? '—'
                : project.candidatasVazaoLs.join(', '),
          ),
        ],
      )
    else ...[
      IrrigationAuditSection(
        title: 'Permanente',
        icon: AppIcons.inundacao,
        children: [
          fields.review('Área irrigada (ha)', fields.format(project.areaHectares)),
          fields.review(
            'Lâmina superficial',
            fields.format(project.laminaSuperficialMm),
          ),
          fields.review('Q disponível', fields.format(project.vazaoDisponivelLps)),
          fields.review(
            'TR (turno de rega)',
            fields.format(turnoRegaPermanente(project), casas: 1),
          ),
          fields.review(
            'Qe (enchimento)',
            fields.format(fluxoPermanente(project)?.qeLS),
          ),
          fields.review(
            'Qm (manutenção)',
            fields.format(fluxoPermanente(project)?.qmLS),
          ),
        ],
      ),
    ],
    IrrigationAuditSection(
      title: 'Cultura e sistema radicular',
      icon: AppIcons.projetoCultura,
      children: [
        fields.review('Cultura', project.culturaEfetiva ?? 'Não informado'),
        fields.review('Kc', agro?.kc == null ? 'Não informado' : fields.format(agro?.kc)),
        fields.review(
          'Profundidade radicular (z)',
          agro?.profundidadeRaizesCm == null
              ? 'Não informado'
              : '${fields.format(agro?.profundidadeRaizesCm)} cm',
        ),
        fields.review(
          'Fração de água disponível (f)',
          agro?.fracaoDisponivel == null
              ? 'Não informado'
              : fields.format(agro?.fracaoDisponivel),
        ),
        fields.review(
          'UCC',
          agro?.uccPercentual == null
              ? 'Não informado'
              : '${fields.format(agro?.uccPercentual)} %',
        ),
        fields.review(
          'UPMP',
          agro?.upmpPercentual == null
              ? 'Não informado'
              : '${fields.format(agro?.upmpPercentual)} %',
        ),
        fields.review(
          'Ds',
          agro?.densidadeGcm3 == null
              ? 'Não informado'
              : '${fields.format(agro?.densidadeGcm3)} g/cm³',
        ),
        if (project.regime == TipoInundacao.permanente) ...[
          fields.review(
            'Porosidade',
            project.porosidade == null
                ? 'Não informado'
                : fields.format(project.porosidade),
          ),
          fields.review(
            'Z (profundidade da camada)',
            project.profundidadeCamadaMm == null
                ? 'Não informado'
                : '${fields.format(project.profundidadeCamadaMm)} mm',
          ),
          fields.review(
            'DTA',
            project.dtaMmCm == null
                ? 'Não informado'
                : '${fields.format(project.dtaMmCm)} mm/cm',
          ),
          fields.review(
            'f (camada, regime contínuo)',
            project.fatorDisponibilidade == null
                ? 'Não informado'
                : fields.format(project.fatorDisponibilidade),
          ),
          fields.review(
            'K0',
            project.condutividadeHidraulicaMmDia == null
                ? 'Não informado'
                : '${fields.format(project.condutividadeHidraulicaMmDia)} mm/dia',
          ),
        ],
      ],
    ),
    IrrigationAuditSection(
      title: 'Clima e demanda',
      icon: AppIcons.projetoClima,
      children: [
        fields.review('Método da ETc', switch (project.metodoEtc) {
          MetodoEtc.adotada => 'ETc adotada (digitação)',
          MetodoEtc.etoVezesKc => 'ETo × Kc',
          MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
        }),
        if (project.metodoEtc == MetodoEtc.etoVezesKc)
          fields.review(
            'ETo',
            project.etoMmDia == null
                ? 'Não informado'
                : '${fields.format(project.etoMmDia)} mm/dia',
          ),
        if (project.metodoEtc == MetodoEtc.blaneyCriddle) ...[
          fields.review(
            'Temperatura média',
            project.temperaturaMediaC == null
                ? 'Não informado'
                : '${fields.format(project.temperaturaMediaC)} °C',
          ),
          fields.review(
            'Latitude',
            project.latitudeGraus == null
                ? 'Não informado'
                : '${fields.format(project.latitudeGraus)}°',
          ),
          fields.review(
            'Mês de referência',
            project.mesReferencia == null
                ? 'Não informado'
                : _mesesNomes[project.mesReferencia! - 1],
          ),
          fields.review(
            'ETo (Blaney–Criddle)',
            project.etoBlaneyCriddleMmDia == null
                ? 'Não calculado'
                : '${fields.format(project.etoBlaneyCriddleMmDia)} mm/dia',
          ),
        ],
        fields.review(
          'ETc efetiva',
          project.etcMmDia == null
              ? 'Não calculado'
              : '${fields.format(project.etcMmDia)} mm/dia',
        ),
        fields.review('Origem da precipitação', switch (project.origemChuva) {
          OrigemChuva.naoInformada => 'Não informada',
          OrigemChuva.efetiva => 'Efetiva adotada',
          OrigemChuva.observada => 'Efetiva observada',
          OrigemChuva.provavel => 'Provável (não convertida em efetiva)',
        }),
        fields.review(
          'Pef (precipitação efetiva)',
          project.precipitacaoEfetivaEfetivaMmDia == null
              ? 'Não informado'
              : '${fields.format(project.precipitacaoEfetivaEfetivaMmDia)} mm/dia',
        ),
        if (project.regime == TipoInundacao.intermitente)
          fields.review(
            'Origem da IRN',
            project.origemIrn == OrigemIrnInundacao.informada
                ? 'Informada'
                : 'Calculada a partir de solo, raízes e demanda climática',
          ),
      ],
    ),
    IrrigationAuditSection(
      title: 'Operação',
      icon: AppIcons.projetoOperacao,
      children: [
        fields.review('Jornada', '${fields.format(project.jornadaHoras)} h'),
        fields.review(
          'Mudança de parcela',
          '${fields.format(project.mudancaParcelaMin)} min',
        ),
        fields.review('PI', '${project.periodoDias} dias'),
        fields.review('NTP', '${project.tabuleirosPorParcela}'),
      ],
    ),
    BasinReferencePanel(projeto: project),
  ];
}

const _mesesNomes = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];
