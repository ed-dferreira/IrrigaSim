import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_kpi.dart';

/// Formatador comum das linhas auditáveis e dos KPIs de faixas.
String f(double? v) => v == null ? '—' : v.toStringAsFixed(2);

/// Indicadores principais do resultado de faixa, com acento na cor da paleta.
List<IrrigationKpiItem> kpisResultadoFaixa(BorderResult r, double comprimentoM) =>
    [
      IrrigationKpiItem(
        titulo: 'Eficiência Ea',
        valor: f(r.ea),
        unidade: '%',
        subtitulo: 'Água aplicada aproveitada',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Eficiência Er',
        valor: f(r.er),
        unidade: '%',
        subtitulo: 'Atendimento da IRN',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Percolação Pp',
        valor: f(r.pp),
        unidade: '%',
        subtitulo: 'Perda profunda',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Escoamento Pe',
        valor: f(r.pe),
        unidade: '%',
        subtitulo: 'Perda superficial',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Volume aplicado',
        valor: f(r.volumeEntradaTotalM3),
        unidade: 'm³',
        subtitulo: 'Volume total na faixa',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Volume percolado',
        valor: f(r.volumePercoladoTotalM3),
        unidade: 'm³',
        subtitulo: 'Perda profunda total',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Volume escoado',
        valor: f(r.volumeEscoadoTotalM3),
        unidade: 'm³',
        subtitulo: 'Perda superficial total',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Tempo de avanço',
        valor: f(r.taFinalMin),
        unidade: 'min',
        subtitulo: 'Até o final da faixa',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Oportunidade alvo',
        valor: f(r.t0Min),
        unidade: 'min',
        subtitulo: 'Tempo requerido pela IRN',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Tempo de corte',
        valor: f(r.tiMin),
        unidade: 'min',
        subtitulo: 'Interrupção da aplicação',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Lâmina útil média',
        valor: f(r.volumeUtilM3M / comprimentoM * 1000),
        unidade: 'mm',
        subtitulo: 'Infiltrada e limitada à IRN',
        color: AppColors.faixa,
      ),
      IrrigationKpiItem(
        titulo: 'Comprimento atendido Xa',
        valor: f(r.comprimentoAdequadoM),
        unidade: 'm',
        subtitulo: 'Pode conter trechos separados',
        color: AppColors.faixa,
      ),
    ];
