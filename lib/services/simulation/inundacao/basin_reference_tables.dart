// Tabelas de referência da Aula 8 — Irrigação por Inundação (UNIPAMPA).
// Padrão de lib/services/simulation/faixas/border_reference_tables.dart:
// dados transcritos do pacote docs/Pacote_Inundacao, com status explícito
// para células sob revisão e preservação literal do fator das fórmulas.
//
// Páginas: 16 (guia de área por vazão), 17 (Henderson), 38 (Booher) e o
// "Exemplo da Aula 8" das pp. 63, 73 e 84. A tabela Booher das faixas
// (p. 26, border_reference_tables.dart) não é alterada por este arquivo.
//
// Paridade: os valores abaixo são lidos de dados_extraidos.json e
// conferidos por inundacao_reference_golden_test.dart.
import 'package:irrigasim/models/faixas/border_result.dart';

import 'basin_reference_math.dart';

/// Guia de área por vazão (p. 16). Orientativo: não substitui o
/// dimensionamento hidráulico e não fornece coeficientes de infiltração.
class BasinSoilGuideRow {
  const BasinSoilGuideRow(this.chaveJson, this.rotulo, this.areaHaBase);

  /// Chave literal do JSON do pacote (`tabela_pagina_16.area_ha`).
  final String chaveJson;

  /// Rótulo apresentado na interface.
  final String rotulo;

  /// Área sugerida (ha) para a vazão-base de 10 L/s.
  final double areaHaBase;

  /// Vazão de referência da tabela, L/s.
  static const double vazaoBaseLs = 10;

  /// Área sugerida (ha) para uma vazão total em L/s.
  double areaParaVazao(double vazaoLs) {
    positivo(vazaoLs, 'vazão');
    return areaHaBase * vazaoLs / vazaoBaseLs;
  }

  /// Guia, nunca coeficiente de infiltração.
  BorderStatus get status => BorderStatus.avisoOrientativo;
}

/// Célula da tabela de sifões/tubos da p. 38. As duas células em que a
/// linha de Ø 30 cm não cresce monotonicamente com a carga ficam sob
/// revisão e nunca viram sugestão automática.
class BasinBooherCell {
  const BasinBooherCell(
    this.diametroCm,
    this.cargaCm,
    this.impressoLs, {
    this.sobRevisao = false,
  });

  final double diametroCm;
  final double cargaCm;

  /// Valor impresso no PDF (p. 38), em L/s.
  final double impressoLs;

  /// Ø 30 cm com carga 7,5 e 10 cm: linha não monotônica na fonte.
  final bool sobRevisao;

  static const int pagina = 38;

  BorderStatus get status => sobRevisao
      ? BorderStatus.dadoFonteSuspeito
      : BorderStatus.avisoOrientativo;
}

/// Células da tabela da p. 38: Ø 30 cm × carga 7,5 e 10 cm.
const basinBooherCelulasSuspeitas = <(double, double)>[(30, 7.5), (30, 10)];

/// Metadados da relação empírica de Henderson (p. 17). O fator 100 é o da
/// aula (A = 100 Q/VIB) e não deve ser trocado pelo fator volumétrico
/// 1000; a função [areaHenderson] do núcleo é a implementação usada.
class BasinHendersonReference {
  const BasinHendersonReference._();

  static const int pagina = 17;
  static const String formula = 'A = 100 · Q / VIB';
  static const String unidadeArea = 'm²';
  static const String unidadeVazao = 'm³/h';
  static const String unidadeVib = 'mm/h';
  static const String natureza =
      'relação empírica transcrita; fator 100 preservado';

  /// Delegação ao núcleo da referência (fator 100 preservado).
  static double area(double qM3Hora, double vibMmHora) =>
      areaHenderson(qM3Hora, vibMmHora);
}

/// Preset "Exemplo da Aula 8" — intermitente (p. 63).
class BasinPresetIntermitente {
  const BasinPresetIntermitente({
    required this.k,
    required this.a,
    required this.vibMMin,
    required this.kTerceira,
    required this.aTerceira,
    required this.vibTerceiraMMin,
    required this.comprimentoM,
    required this.larguraAreaM,
    required this.declividade,
    required this.manningN,
    required this.rho1,
    required this.rho2,
    required this.irnMm,
    required this.etMmDia,
    required this.vmaxMMin,
    required this.vazaoTotalLs,
    required this.intervaloDias,
  });

  static const int pagina = 63;
  static const String rotulo = 'Exemplo da Aula 8 · intermitente';

  final double k, a, vibMMin;
  final double kTerceira, aTerceira, vibTerceiraMMin;
  final double comprimentoM, larguraAreaM, declividade, manningN;

  /// Auditoria sem cálculo (G6).
  final double rho1, rho2;

  final double irnMm, etMmDia, vmaxMMin, vazaoTotalLs;
  final int intervaloDias;
}

/// Preset "Exemplo da Aula 8" — permanente/contínuo (p. 73).
class BasinPresetContinua {
  const BasinPresetContinua({
    required this.areaHa,
    required this.dtaMmCm,
    required this.porosidade,
    required this.zCm,
    required this.k0MmDia,
    required this.etMmDia,
    required this.laminaMm,
    required this.f,
  });

  static const int pagina = 73;
  static const String rotulo = 'Exemplo da Aula 8 · contínuo';

  final double areaHa, dtaMmCm, porosidade, zCm, k0MmDia, etMmDia, laminaMm, f;

  /// Profundidade da camada ativa em mm (Z em cm × 10).
  double get profundidadeCamadaMm => zCm * 10;
}

/// Preset "Exemplo da Aula 8" — volumes do arroz (p. 84).
/// Dados ausentes no enunciado ficam null e nunca são presumidos (G4).
class BasinPresetArroz {
  const BasinPresetArroz({
    required this.dsGcm3,
    required this.dpGcm3,
    required this.pciM,
    required this.alturaLaminaM,
    required this.ksatMDia,
    required this.evaporacaoMmDia,
    required this.periodoDias,
    required this.produtividadeSacosHa,
    required this.umidadeGraos,
    required this.indiceColheita,
    this.uaGravimetrica,
    this.massaSacoKg,
    this.areaHa,
    this.tdDias,
    this.trDias,
  });

  static const int pagina = 84;
  static const String rotulo = 'Exemplo da Aula 8 · volumes do arroz';

  final double dsGcm3, dpGcm3, pciM, alturaLaminaM, ksatMDia, evaporacaoMmDia;
  final double periodoDias, produtividadeSacosHa, umidadeGraos, indiceColheita;
  final double? uaGravimetrica, massaSacoKg, areaHa, tdDias, trDias;
}

/// Tabelas de referência e presets da irrigação por inundação.
class BasinReferenceTables {
  const BasinReferenceTables();

  static const int paginaGuiaSolo = 16;
  static const int paginaHenderson = BasinHendersonReference.pagina;
  static const int paginaBooher = BasinBooherCell.pagina;

  /// p. 16 — área sugerida por vazão de 10 L/s segundo a textura.
  static const guiaSolo = <BasinSoilGuideRow>[
    BasinSoilGuideRow('arenoso', 'Arenoso', 0.01),
    BasinSoilGuideRow('franco_arenoso', 'Franco-arenoso', 0.02),
    BasinSoilGuideRow('franco_argiloso', 'Franco-argiloso', 0.03),
    BasinSoilGuideRow('argiloso', 'Argiloso', 0.04),
  ];

  /// Mesmo guia com as chaves usadas pelo núcleo ([areaGuiaSolo]).
  static const _chaveNucleo = {
    'arenoso': 'arenoso',
    'franco_arenoso': 'franco-arenoso',
    'franco_argiloso': 'franco-argiloso',
    'argiloso': 'argiloso',
  };

  BasinSoilGuideRow? guia(String chave) {
    for (final row in guiaSolo) {
      if (row.chaveJson == chave || _chaveNucleo[row.chaveJson] == chave) {
        return row;
      }
    }
    return null;
  }

  /// Área sugerida (ha) pela p. 16; null para textura fora da tabela.
  double? areaSugerida(String chave, double vazaoLs) =>
      guia(chave)?.areaParaVazao(vazaoLs);

  static const diametrosCm = <double>[10, 12.5, 15, 20, 25, 30, 35];
  static const cargasCm = <double>[5, 7.5, 10, 12.5, 15, 20, 25];

  /// Valores literais da p. 38 (L/s), linha = diâmetro, coluna = carga.
  static const valoresLs = <List<double>>[
    [4.7, 5.7, 6.6, 7.4, 8.1, 9.3, 10.4],
    [7.3, 8.9, 10.3, 11.5, 12.6, 14.6, 16.3],
    [10.5, 12.9, 14.9, 16.6, 18.2, 21, 23.5],
    [18.7, 22.9, 26.4, 29.5, 32.3, 37.3, 41.8],
    [29.2, 35.7, 41.3, 46.1, 50.5, 58.4, 65.2],
    [42, 31.5, 39.4, 66.4, 72.8, 84, 94],
    [57.2, 70, 80.9, 90.4, 99.1, 114.4, 127.9],
  ];

  BasinBooherCell? booher(double diametroCm, double cargaCm) {
    final row = diametrosCm.indexOf(diametroCm);
    final col = cargasCm.indexOf(cargaCm);
    if (row < 0 || col < 0) return null;
    final suspeita = basinBooherCelulasSuspeitas.contains((
      diametroCm,
      cargaCm,
    ));
    return BasinBooherCell(
      diametroCm,
      cargaCm,
      valoresLs[row][col],
      sobRevisao: suspeita,
    );
  }

  /// Célula elegível para sugestão; células sob revisão retornam null e
  /// nunca viram recomendação automática.
  BasinBooherCell? sugestao(double diametroCm, double cargaCm) {
    final cell = booher(diametroCm, cargaCm);
    if (cell == null || cell.status == BorderStatus.dadoFonteSuspeito) {
      return null;
    }
    return cell;
  }

  /// p. 63 — intermitente com as duas curvas de infiltração da aula.
  static const intermitenteAula8 = BasinPresetIntermitente(
    k: 0.0035,
    a: 0.47,
    vibMMin: 0.00011,
    kTerceira: 0.0034,
    aTerceira: 0.45,
    vibTerceiraMMin: 0.0001,
    comprimentoM: 200,
    larguraAreaM: 400,
    declividade: 0,
    manningN: 0.04,
    rho1: 1,
    rho2: 3.33,
    irnMm: 56,
    etMmDia: 8,
    vmaxMMin: 8,
    vazaoTotalLs: 400,
    intervaloDias: 7,
  );

  /// p. 73 — contínuo (Qe/Qm com o fator 0,116).
  static const continuaAula8 = BasinPresetContinua(
    areaHa: 20,
    dtaMmCm: 2,
    porosidade: 0.5,
    zCm: 50,
    k0MmDia: 7,
    etMmDia: 7.2,
    laminaMm: 150,
    f: 0.5,
  );

  /// p. 84 — volumes do arroz; Ua, massa do saco, área, Td e Tr ausentes.
  static const arrozAula8 = BasinPresetArroz(
    dsGcm3: 1.25,
    dpGcm3: 2.65,
    pciM: 0.60,
    alturaLaminaM: 0.07,
    ksatMDia: 0.0006,
    evaporacaoMmDia: 8,
    periodoDias: 100,
    produtividadeSacosHa: 435.6,
    umidadeGraos: 0.13,
    indiceColheita: 0.40,
  );
}
