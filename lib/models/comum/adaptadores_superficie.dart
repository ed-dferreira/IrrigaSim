import 'package:irrigasim/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';

/// Projeções de leitura: os projetos originais continuam sendo a fonte dos
/// cálculos e da persistência. Nenhum dado ausente é substituído por padrão.
extension BaseProjetoSulcos on IrrigationProject {
  BaseIrrigacao get baseComum => BaseIrrigacao(
    identificacao: IdentificacaoIrrigacao.superficie(SistemaSuperficie.sulcos),
    area: CaracterizacaoArea(
      comprimentoM: area.comprimentoM,
      larguraM: area.larguraM,
      declividadePercentual: area.declividadePercentual,
      texturaSolo: solo.textura.name,
      cultura: cultura.nome,
      uccPercentual: solo.uccPercentual,
      upmpPercentual: solo.upmpPercentual,
      densidadeGcm3: solo.densidadeGcm3,
      profundidadeRaizesM: cultura.profundidadeRaizesM,
      fracaoAguaDisponivel: cultura.fracaoAguaDisponivel,
      etoMmDia: clima.etoMmDia,
      etcMmDia: clima.etcMmDia,
      precipitacaoEfetivaMmDia: clima.precipitacaoEfetivaMmDia,
    ),
    ensaio: ensaioAvanco == null && ensaioInfiltracao == null
        ? null
        : EnsaioComum(
            data: ensaioAvanco?.data ?? ensaioInfiltracao?.data,
            estacas:
                ensaioAvanco?.pontos
                    .map((p) => EstacaEnsaio(p.distanciaM, p.tempoMin))
                    .toList() ??
                const [],
            medicoesInfiltracao:
                ensaioInfiltracao?.pontos
                    .map(
                      (p) => MedicaoInfiltracaoComum(
                        tempoMin: p.tempoMin,
                        laminaAcumuladaMm: p.volumeInfiltradoMm,
                      ),
                    )
                    .toList() ??
                const [],
            origemInfiltracao: ensaioInfiltracao == null
                ? null
                : 'ensaio_infiltracao_sulcos',
            equacaoInfiltracao: ensaioInfiltracao?.parametros == null
                ? null
                : 'k·t^n (ver unidades no ensaio de sulcos)',
          ),
  );
}

extension BaseProjetoFaixas on BorderProject {
  BaseIrrigacao get baseComum => BaseIrrigacao(
    identificacao: IdentificacaoIrrigacao.superficie(SistemaSuperficie.faixas),
    area: CaracterizacaoArea(
      comprimentoM: comprimentoAreaM ?? comprimentoM,
      larguraM: larguraAreaM ?? larguraM,
      declividadePercentual: declividadeLongitudinal == null
          ? null
          : declividadeLongitudinal! * 100,
      texturaSolo: textura?.name,
      cultura: cultura,
      uccPercentual: agronomia?.uccPercentual,
      upmpPercentual: agronomia?.upmpPercentual,
      densidadeGcm3: agronomia?.densidadeGcm3,
      profundidadeRaizesM: agronomia?.profundidadeRaizesCm == null
          ? null
          : agronomia!.profundidadeRaizesCm! / 100,
      fracaoAguaDisponivel: agronomia?.fracaoDisponivel,
      etcMmDia: agronomia?.evapotranspiracaoMmDia,
      precipitacaoEfetivaMmDia: agronomia?.precipitacaoEfetivaMmDia,
      vazaoDisponivelLs: vazaoDisponivelLs,
    ),
    ensaio: estacas.isEmpty && k == null && a == null
        ? null
        : EnsaioComum(
            estacas: estacas
                .map(
                  (s) => EstacaEnsaio(
                    s.xM,
                    s.avancoMin,
                    recessaoMin: s.recessaoMin,
                  ),
                )
                .toList(),
            origemInfiltracao: cenarioInfiltracao.name,
            equacaoInfiltracao: k == null || a == null
                ? null
                : 'k·t^a + VIB·t (m; t em min)',
          ),
  );
}

/// Cenários rápidos usam IrrigationParameters em vez de IrrigationProject.
/// A identificação vem do método escolhido, nunca de um padrão implícito.
extension BaseParametrosSuperficie on IrrigationParameters {
  BaseIrrigacao baseComumPara(MetodoIrrigacao metodo) {
    if (metodo == MetodoIrrigacao.faixa) {
      return (projetoFaixa ?? BorderProject.fromLegacy(this)).baseComum;
    }
    final recessao = {
      for (final p in medicoesRecessao) p.distanciaM: p.instanteRecessaoMin,
    };
    return BaseIrrigacao(
      identificacao: IdentificacaoIrrigacao.superficie(
        metodo == MetodoIrrigacao.sulco
            ? SistemaSuperficie.sulcos
            : SistemaSuperficie.inundacao,
      ),
      area: CaracterizacaoArea(
        comprimentoM: comprimento,
        larguraM: larguraOuEspacamento,
        declividadePercentual: declividade * 100,
        texturaSolo: texturaSolo.name,
        cultura: nomeCultura.isEmpty ? null : nomeCultura,
        etcMmDia: evapotranspiracaoMmDia,
        precipitacaoEfetivaMmDia: precipitacaoEfetivaMmDia,
        vazaoDisponivelLs: vazaoDisponivelLps,
      ),
      ensaio:
          metodo != MetodoIrrigacao.sulco ||
              (medicoesAvanco.isEmpty &&
                  medicoesEntradaSaida.isEmpty &&
                  medicoesRecessao.isEmpty)
          ? null
          : EnsaioComum(
              estacas: medicoesAvanco
                  .map(
                    (p) => EstacaEnsaio(
                      p.distanciaM,
                      p.tempoMin,
                      recessaoMin: recessao[p.distanciaM],
                    ),
                  )
                  .toList(),
              medicoesInfiltracao: medicoesEntradaSaida
                  .map(
                    (p) => MedicaoInfiltracaoComum(
                      tempoMin: p.tempoMin,
                      vazaoEntradaLs: p.vazaoEntradaLs,
                      vazaoSaidaLs: p.vazaoSaidaLs,
                    ),
                  )
                  .toList(),
              origemInfiltracao: origemCurvaInfiltracao.name,
            ),
    );
  }
}
