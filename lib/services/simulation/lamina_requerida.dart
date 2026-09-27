import 'package:irrigasim/services/units_service.dart';

/// Resultado do cálculo da lâmina requerida e turno de rega.
class LaminaRequeridaResultado {
  final double irnMm;
  final double turnoCalculadoDias;
  final int turnoOperacionalDias;
  final double demandaLiquidaMmDia;

  /// Valores intermediários para auditoria.
  final double uccDecimal;
  final double upmpDecimal;
  final double faad;
  final double profundidadeCm;
  final double fatorCultura;
  final double? etoMmDia;
  final double? etcMmDia;
  final double? precipitacaoEfetivaMmDia;

  const LaminaRequeridaResultado({
    required this.irnMm,
    required this.turnoCalculadoDias,
    required this.turnoOperacionalDias,
    required this.demandaLiquidaMmDia,
    required this.uccDecimal,
    required this.upmpDecimal,
    required this.faad,
    required this.profundidadeCm,
    required this.fatorCultura,
    this.etoMmDia,
    this.etcMmDia,
    this.precipitacaoEfetivaMmDia,
  });

  Map<String, dynamic> toMap() {
    return {
      'irn_mm': irnMm,
      'turno_calculado_dias': turnoCalculadoDias,
      'turno_operacional_dias': turnoOperacionalDias,
      'demanda_liquida_mm_dia': demandaLiquidaMmDia,
      'ucc_decimal': uccDecimal,
      'upmp_decimal': upmpDecimal,
      'faad': faad,
      'profundidade_cm': profundidadeCm,
      'fator_cultura': fatorCultura,
      'eto_mm_dia': etoMmDia,
      'etc_mm_dia': etcMmDia,
      'precipitacao_efetiva_mm_dia': precipitacaoEfetivaMmDia,
    };
  }
}

/// Calcula a lâmina líquida de irrigação necessária (IRN) e o turno de rega.
///
/// Fórmulas:
/// ```
/// IRN = [(UCC - UPMP) / 10] * Ds * z_cm * f
/// TR  = IRN / demanda_diaria
/// ```
///
/// Onde:
/// - UCC, UPMP em %
/// - Ds em g/cm³
/// - z em cm
/// - f = fração de água disponível (0 a 1)
/// - demanda diária em mm/dia
class LaminaRequeridaCalculator {
  const LaminaRequeridaCalculator._();

  /// Calcula IRN e turno de rega.
  ///
  /// [uccPercentual] — Umidade de Capacidade de Campo (%)
  /// [upmpPercentual] — Umidade no Ponto de Murcha Permanente (%)
  /// [densidadeGcm3] — Densidade aparente do solo (g/cm³)
  /// [profundidadeRaizesCm] — Profundidade do sistema radicular (cm)
  /// [fracaoAguaDisponivel] — Fração de água disponível (0 a 1)
  /// [demandaLiquidaMmDia] — Demanda líquida diária (mm/dia)
  /// [etoMmDia] — Evapotranspiração de referência (opcional)
  /// [etcMmDia] — Evapotranspiração da cultura (opcional)
  /// [precipitacaoEfetivaMmDia] — Precipitação efetiva (opcional)
  static LaminaRequeridaResultado calcular({
    required double uccPercentual,
    required double upmpPercentual,
    required double densidadeGcm3,
    required double profundidadeRaizesCm,
    required double fracaoAguaDisponivel,
    required double demandaLiquidaMmDia,
    double? etoMmDia,
    double? etcMmDia,
    double? precipitacaoEfetivaMmDia,
  }) {
    final validacao = ValidacaoEntradas();
    validacao.validar(
      () => UnitsService.validarPorcentagem(uccPercentual, 'UCC'),
    );
    validacao.validar(
      () => UnitsService.validarPorcentagem(upmpPercentual, 'UPMP'),
    );
    validacao.validar(() => UnitsService.validarDensidade(densidadeGcm3));
    validacao.validar(
      () => UnitsService.validarPositivo(
        profundidadeRaizesCm,
        'Profundidade das raízes',
      ),
    );
    validacao.validar(
      () => UnitsService.validarFaixa(
        fracaoAguaDisponivel,
        0,
        1,
        'Fração de água disponível',
      ),
    );
    validacao.validar(
      () => UnitsService.validarPositivo(
        demandaLiquidaMmDia,
        'Demanda líquida diária',
      ),
    );

    if (!validacao.tudoValido) {
      throw ArgumentError(validacao.erros.join('; '));
    }
    if (uccPercentual <= upmpPercentual) {
      throw ArgumentError('UCC deve ser maior que UPMP.');
    }

    // Conversão de % para decimal
    final uccDecimal = UnitsService.percentToDecimal(uccPercentual);
    final upmpDecimal = UnitsService.percentToDecimal(upmpPercentual);

    // Fração de Água Disponível Absorvida (FAAD)
    final faad = uccDecimal - upmpDecimal;

    // IRN = [(UCC - UPMP) / 10] * Ds * z_cm * f
    // Equivalente: faad * 100 * Ds * z_cm * f / 10
    final irnMm =
        faad * 10 * densidadeGcm3 * profundidadeRaizesCm * fracaoAguaDisponivel;

    // TR = IRN / demanda diária
    final turnoCalculado = irnMm / demandaLiquidaMmDia;

    // Turno operacional: arredondar para baixo (mínimo 1 dia)
    final turnoOperacional = turnoCalculado.floor().clamp(1, 365);

    return LaminaRequeridaResultado(
      irnMm: irnMm,
      turnoCalculadoDias: turnoCalculado,
      turnoOperacionalDias: turnoOperacional,
      demandaLiquidaMmDia: demandaLiquidaMmDia,
      uccDecimal: uccDecimal,
      upmpDecimal: upmpDecimal,
      faad: faad,
      profundidadeCm: profundidadeRaizesCm,
      fatorCultura: fracaoAguaDisponivel,
      etoMmDia: etoMmDia,
      etcMmDia: etcMmDia,
      precipitacaoEfetivaMmDia: precipitacaoEfetivaMmDia,
    );
  }
}
