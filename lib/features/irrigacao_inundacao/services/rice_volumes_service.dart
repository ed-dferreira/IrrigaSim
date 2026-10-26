// Volumes de água da irrigação por inundação permanente (arroz).
// Fonte: Aula 8 — Irrigação por Inundação, pp. 74–84. Espelha as fórmulas
// de basin_reference_math.dart (volumesArroz, materiaSecaTotal, vazaoVolume),
// preservando nulls quando a fonte não informa Ua, massa do saco, área ou
// tempos (solução parcial da p. 84). Nenhum dado ausente é presumido.
//
// Unidades da referência: densidades em g/cm³; PCI e altura da lâmina em m;
// evaporação e Ksat em m/dia; períodos em dias; produção em sacos/ha; massa
// do saco em kg; volumes em m³/ha; Q1 e Q2 em m³/s (não L/s).
import 'basin_reference_math.dart';

/// Resultado dos volumes de água do arroz (Aula 8, pp. 74–84).
class RiceVolumesResultado {
  const RiceVolumesResultado({
    required this.pt,
    required this.us,
    required this.v1M3Ha,
    required this.v2M3Ha,
    required this.v3M3Ha,
    required this.v4M3Ha,
    required this.v5M3Ha,
    required this.vtM3Ha,
    required this.materiaSecaTotalKgHa,
    required this.q1M3S,
    required this.q2M3S,
    required this.dadosAusentes,
  });

  /// Porosidade total PT = 1 − Ds/Dp.
  final double pt;

  /// Umidade de saturação gravimétrica Us = PT/Ds.
  final double us;

  /// Volume de saturação V1 = (Us − Ua) PCI 10000 Ds, m³/ha.
  /// Null quando Ua não é informada (p. 84).
  final double? v1M3Ha;

  /// Volume para formação da lâmina V2 = h·10000, m³/ha.
  final double v2M3Ha;

  /// Volume para compensar evaporação V3 = h2·PI·10000, m³/ha.
  final double v3M3Ha;

  /// Volume para compensar infiltração V4 = Ksat (h+PCI)/PCI·PI·10000, m³/ha.
  final double v4M3Ha;

  /// Volume para transpiração/MS V5 = 0,4·MS_total, m³/ha.
  /// Null quando a massa do saco não é informada (p. 84).
  final double? v5M3Ha;

  /// Volume total VT = V1+V2+V3+V4+V5, m³/ha. Null com qualquer lacuna.
  final double? vtM3Ha;

  /// Matéria seca total, kg/ha. Null sem produção, massa do saco, umidade
  /// dos grãos e índice de colheita.
  final double? materiaSecaTotalKgHa;

  /// Vazão de formação da lâmina Q1 = (V1+V2) A/(Td 86400), m³/s (p. 82).
  final double? q1M3S;

  /// Vazão de manutenção da lâmina Q2 = (V3+V4+V5) A/(Tr 86400), m³/s
  /// (p. 83). Tr é o tempo restante disponível, não o turno de rega TR
  /// da p. 67.
  final double? q2M3S;

  /// Entradas ausentes que mantêm campos nulos; nunca presumir (G4).
  final List<String> dadosAusentes;

  Map<String, Object?> toMap() => {
    'pt': pt,
    'us_gravimetrica': us,
    'v1_m3_ha': v1M3Ha,
    'v2_m3_ha': v2M3Ha,
    'v3_m3_ha': v3M3Ha,
    'v4_m3_ha': v4M3Ha,
    'v5_m3_ha': v5M3Ha,
    'vt_m3_ha': vtM3Ha,
    'materia_seca_total_kg_ha': materiaSecaTotalKgHa,
    'q1_m3_s': q1M3S,
    'q2_m3_s': q2M3S,
    'dados_ausentes': dadosAusentes,
  };

  factory RiceVolumesResultado.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    double? numero(String chave) {
      final valor = map[chave];
      return valor is num ? valor.toDouble() : null;
    }

    return RiceVolumesResultado(
      pt: numero('pt') ?? 0,
      us: numero('us_gravimetrica') ?? 0,
      v1M3Ha: numero('v1_m3_ha'),
      v2M3Ha: numero('v2_m3_ha') ?? 0,
      v3M3Ha: numero('v3_m3_ha') ?? 0,
      v4M3Ha: numero('v4_m3_ha') ?? 0,
      v5M3Ha: numero('v5_m3_ha'),
      vtM3Ha: numero('vt_m3_ha'),
      materiaSecaTotalKgHa: numero('materia_seca_total_kg_ha'),
      q1M3S: numero('q1_m3_s'),
      q2M3S: numero('q2_m3_s'),
      dadosAusentes:
          (map['dados_ausentes'] as List?)?.map((v) => v.toString()).toList() ??
          const [],
    );
  }
}

/// Camada de volumes do arroz sobre o núcleo da Aula 8.
class RiceVolumesService {
  const RiceVolumesService();

  /// Ua gravimétrica a partir da umidade volumétrica (p. 76):
  /// Ua_grav = u_vol/Ds. Não inserir umidade volumétrica diretamente em Ua.
  static double umidadeGravimetrica(double umidadeVolumetrica, double ds) {
    naoNegativo(umidadeVolumetrica, 'umidade volumétrica');
    positivo(ds, 'Ds');
    return umidadeVolumetrica / ds;
  }

  /// V1 pela forma volumétrica equivalente (p. 76):
  /// V1 = (PT − u_inicial)·PCI·10000, com u_inicial volumétrica.
  static double v1PorUmidadeVolumetrica({
    required double pt,
    required double umidadeVolumetricaInicial,
    required double pciM,
  }) {
    if (!pt.isFinite || pt <= 0 || pt > 1) {
      throw ArgumentError('PT deve estar em (0,1]');
    }
    naoNegativo(umidadeVolumetricaInicial, 'umidade volumétrica inicial');
    positivo(pciM, 'PCI');
    if (umidadeVolumetricaInicial > pt) {
      throw ArgumentError('Umidade inicial supera a porosidade total');
    }
    return (pt - umidadeVolumetricaInicial) * pciM * 10000;
  }

  /// Calcula PT, Us, V1–V5, VT, matéria seca total, Q1 e Q2. Campos com
  /// entrada ausente permanecem null e constam em
  /// [RiceVolumesResultado.dadosAusentes].
  RiceVolumesResultado calcular({
    required double ds,
    required double dp,
    double? uaGravimetrica,
    required double pciM,
    required double alturaLaminaM,
    required double evaporacaoDiaM,
    required double ksatDiaM,
    required double periodoDias,
    double? produtividadeSacosHa,
    double? umidadeGraos,
    double? indiceColheita,
    double? massaSacoKg,
    double? areaHa,
    double? tdDias,
    double? trDias,
  }) {
    positivo(ds, 'Ds');
    positivo(dp, 'Dp');
    positivo(pciM, 'PCI');
    positivo(periodoDias, 'período');
    naoNegativo(alturaLaminaM, 'altura da lâmina');
    naoNegativo(evaporacaoDiaM, 'evaporação');
    naoNegativo(ksatDiaM, 'Ksat');
    if (ds >= dp) {
      throw ArgumentError('Ds deve ser menor que Dp');
    }
    if (areaHa != null) positivo(areaHa, 'área');
    if (tdDias != null) positivo(tdDias, 'Td');
    if (trDias != null) positivo(trDias, 'Tr');
    if (massaSacoKg != null) positivo(massaSacoKg, 'massa do saco');

    final pt = 1 - ds / dp;
    final us = pt / ds;
    final ausentes = <String>[];

    // V2, V3 e V4 independem de Ua e MS; o núcleo é chamado com os
    // faltantes zerados apenas para reaproveitar as fórmulas validadas.
    final base = volumesArroz(
      ds: ds,
      dp: dp,
      ua: uaGravimetrica ?? 0,
      pci: pciM,
      h: alturaLaminaM,
      evaporacaoDia: evaporacaoDiaM,
      ksatDia: ksatDiaM,
      periodoDias: periodoDias,
      materiaSecaKgHa: 0,
    );

    double? v1;
    if (uaGravimetrica == null) {
      ausentes.add('Ua gravimétrica (V1, VT, Q1)');
    } else {
      naoNegativo(uaGravimetrica, 'Ua');
      if (uaGravimetrica > us) {
        throw ArgumentError('Ua supera a saturação');
      }
      v1 = base.v1M3Ha;
    }

    double? materiaSeca;
    if (produtividadeSacosHa == null ||
        massaSacoKg == null ||
        umidadeGraos == null ||
        indiceColheita == null) {
      ausentes.add(
        'produção, massa do saco, umidade ou índice de colheita '
        '(MS total, V5, VT, Q2)',
      );
    } else {
      materiaSeca = materiaSecaTotal(
        produtividadeSacosHa,
        massaSacoKg,
        umidadeGraos,
        indiceColheita,
      );
    }
    final v5 = materiaSeca == null ? null : 0.4 * materiaSeca;
    final vt = v1 == null || v5 == null
        ? null
        : v1 + base.v2M3Ha + base.v3M3Ha + base.v4M3Ha + v5;

    double? q1, q2;
    if (areaHa == null || tdDias == null) {
      ausentes.add('área ou Td (Q1)');
    } else if (v1 != null) {
      q1 = vazaoVolume(v1 + base.v2M3Ha, areaHa, tdDias);
    }
    if (areaHa == null || trDias == null) {
      ausentes.add('área ou Tr (Q2)');
    } else if (v5 != null) {
      q2 = vazaoVolume(base.v3M3Ha + base.v4M3Ha + v5, areaHa, trDias);
    }

    return RiceVolumesResultado(
      pt: pt,
      us: us,
      v1M3Ha: v1,
      v2M3Ha: base.v2M3Ha,
      v3M3Ha: base.v3M3Ha,
      v4M3Ha: base.v4M3Ha,
      v5M3Ha: v5,
      vtM3Ha: vt,
      materiaSecaTotalKgHa: materiaSeca,
      q1M3S: q1,
      q2M3S: q2,
      dadosAusentes: ausentes,
    );
  }

  /// Solução parcial do exercício da p. 84 com os dados do enunciado
  /// (Ds 1,25; Dp 2,65; PCI 0,60 m; lâmina 0,07 m; Ksat 0,0006 m/dia;
  /// evaporação de tanque 0,008 m/dia; período 100 dias; produtividade
  /// 435,6 sacos/ha com 13% de umidade; índice de colheita 40%).
  /// Ua, massa do saco, área, Td e Tr só entram se informados.
  RiceVolumesResultado solucaoPagina84({
    double? uaGravimetrica,
    double? massaSacoKg,
    double? areaHa,
    double? tdDias,
    double? trDias,
  }) => calcular(
    ds: 1.25,
    dp: 2.65,
    uaGravimetrica: uaGravimetrica,
    pciM: 0.60,
    alturaLaminaM: 0.07,
    evaporacaoDiaM: 0.008,
    ksatDiaM: 0.0006,
    periodoDias: 100,
    produtividadeSacosHa: 435.6,
    umidadeGraos: 0.13,
    indiceColheita: 0.40,
    massaSacoKg: massaSacoKg,
    areaHa: areaHa,
    tdDias: tdDias,
    trDias: trDias,
  );
}
