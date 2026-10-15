// Planejamento operacional da irrigação por inundação (Aula 8, pp. 60–62).
// Camada de aplicação sobre o núcleo basin_reference_math.dart: converte
// ArgumentError/StateError em FormatException amigável e expõe os campos de
// IrrigationParameters usados pela operação (jornadaDiariaH,
// tempoMudancaParcelaMin, periodoIrrigacaoDias).
//
// A seleção de vazão devolve o melhor candidato fornecido, não o ótimo
// global (risco reconhecido no plano de implementação).
import 'package:irrigasim/models/irrigation_parameters.dart';

import 'basin_reference_math.dart' as nucleo;

/// Resultado da checagem operacional obrigatória (G3): a vazão planejada
/// cabe na vazão disponível e a geometria do tabuleiro cabe na área.
class BasinChecagemOperacional {
  const BasinChecagemOperacional({
    required this.vazaoPlanejadaLs,
    required this.vazaoDisponivelLs,
    required this.areaTabuleiroM2,
    required this.areaDeclaradaM2,
    required this.atendeVazao,
    required this.geometriaCabeNaArea,
    this.motivo,
  });

  /// Vazão planejada (Qe no contínuo; vazão total aplicada no intermitente).
  final double vazaoPlanejadaLs;

  /// Vazão disponível na fonte, L/s.
  final double vazaoDisponivelLs;

  /// Comprimento × largura do tabuleiro, m².
  final double areaTabuleiroM2;

  /// Área declarada da unidade, m².
  final double areaDeclaradaM2;

  /// Q planejado ≤ vazão disponível.
  final bool atendeVazao;

  /// Comprimento × largura ≤ área declarada.
  final bool geometriaCabeNaArea;

  /// Primeira violação identificada; null quando viável.
  final String? motivo;

  bool get viavel => atendeVazao && geometriaCabeNaArea;

  Map<String, Object?> toMap() => {
    'vazao_planejada_l_s': vazaoPlanejadaLs,
    'vazao_disponivel_l_s': vazaoDisponivelLs,
    'area_tabuleiro_m2': areaTabuleiroM2,
    'area_declarada_m2': areaDeclaradaM2,
    'atende_vazao': atendeVazao,
    'geometria_cabe_na_area': geometriaCabeNaArea,
    'motivo': motivo,
    'viavel': viavel,
  };

  factory BasinChecagemOperacional.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    double numero(String chave) => (map[chave] as num).toDouble();
    return BasinChecagemOperacional(
      vazaoPlanejadaLs: numero('vazao_planejada_l_s'),
      vazaoDisponivelLs: numero('vazao_disponivel_l_s'),
      areaTabuleiroM2: numero('area_tabuleiro_m2'),
      areaDeclaradaM2: numero('area_declarada_m2'),
      atendeVazao: map['atende_vazao'] == true,
      geometriaCabeNaArea: map['geometria_cabe_na_area'] == true,
      motivo: map['motivo'] as String?,
    );
  }
}

/// Planejamento em parcelas, seleção de vazão e checagem operacional da
/// inundação, pelas fórmulas da Aula 8.
class BasinPlanning {
  const BasinPlanning();

  T _doNucleo<T>(T Function() acao) {
    try {
      return acao();
    } on ArgumentError catch (e) {
      throw FormatException('Planejamento da inundação: ${e.message}');
    } on StateError catch (e) {
      throw FormatException('Planejamento da inundação: ${e.message}');
    }
  }

  /// Planejamento em parcelas (p. 61–62): W0, NTT, Q, TPP, NPD e APP.
  /// Jornada em horas, mudança de parcela em minutos e período em dias,
  /// como nos campos de [IrrigationParameters].
  nucleo.ParcelasResult planejarParcelas({
    required double areaTotalM2,
    required double comprimentoM,
    required int tabuleirosPorParcela,
    required double q0M3MinM,
    required double tiMin,
    required double jornadaDiariaH,
    required double tempoMudancaParcelaMin,
    required int periodoIrrigacaoDias,
  }) => _doNucleo(
    () => nucleo.parcelas(
      areaTotalM2: areaTotalM2,
      comprimentoM: comprimentoM,
      tabuleirosPorParcela: tabuleirosPorParcela,
      q0M3MinM: q0M3MinM,
      tiMin: tiMin,
      mudancaMin: tempoMudancaParcelaMin,
      jornadaMinDia: jornadaDiariaH * 60,
      periodoDias: periodoIrrigacaoDias,
    ),
  );

  /// Planejamento em parcelas lendo jornada, mudança e período dos
  /// parâmetros do projeto; área em m² e comprimento em metros.
  nucleo.ParcelasResult planejarParcelasProjeto(
    IrrigationParameters params, {
    required double q0M3MinM,
    required double tiMin,
    required int tabuleirosPorParcela,
    double? areaTotalM2,
    double? comprimentoM,
  }) => planejarParcelas(
    areaTotalM2: areaTotalM2 ?? params.areaHectares * 10000,
    comprimentoM: comprimentoM ?? params.comprimento,
    tabuleirosPorParcela: tabuleirosPorParcela,
    q0M3MinM: q0M3MinM,
    tiMin: tiMin,
    jornadaDiariaH: params.jornadaDiariaH,
    tempoMudancaParcelaMin: params.tempoMudancaParcelaMin,
    periodoIrrigacaoDias: params.periodoIrrigacaoDias,
  );

  /// Melhor vazão entre candidatos explícitos (p. 60), verificando vazão
  /// não erosiva, altura da taipa com margem livre e eficiência ≤ 100%.
  /// Não garante ótimo global.
  nucleo.BasinDimensioningResult selecionarMelhorVazao({
    required nucleo.Infiltracao solo,
    required List<double> candidatosQ0M3MinM,
    required double comprimentoM,
    required double manningN,
    required double laminaRequeridaM,
    required double alturaDiqueM,
    required double margemLivreM,
    double vmaxMMin = 8,
    double rInicial = 0.7,
  }) => _doNucleo(
    () => nucleo.selecionarMelhorVazao(
      solo,
      candidatosQ0M3MinM,
      l: comprimentoM,
      n: manningN,
      irn: laminaRequeridaM,
      vmax: vmaxMMin,
      rInicial: rInicial,
      alturaDiqueM: alturaDiqueM,
      margemLivreM: margemLivreM,
    ),
  );

  /// Altura da taipa com margem livre (p. 35 e 54).
  bool diqueComporta({
    required double alturaDiqueM,
    required double y0M,
    required double margemLivreM,
  }) => _doNucleo(() => nucleo.diqueComporta(alturaDiqueM, y0M, margemLivreM));

  /// Checagem operacional obrigatória (G3): Q planejado ≤ vazão disponível
  /// e comprimento × largura ≤ área declarada. Tolerância relativa 1e-9
  /// para comparações de ponto flutuante.
  BasinChecagemOperacional checarOperacao({
    required double vazaoPlanejadaLs,
    required double vazaoDisponivelLs,
    required double areaTabuleiroM2,
    required double areaDeclaradaM2,
  }) {
    nucleo.positivo(vazaoPlanejadaLs, 'vazão planejada');
    nucleo.positivo(vazaoDisponivelLs, 'vazão disponível');
    nucleo.positivo(areaTabuleiroM2, 'área do tabuleiro');
    nucleo.positivo(areaDeclaradaM2, 'área declarada');
    final atendeVazao = vazaoPlanejadaLs <= vazaoDisponivelLs * (1 + 1e-9);
    final geometriaCabe = areaTabuleiroM2 <= areaDeclaradaM2 * (1 + 1e-9);
    final motivo = !atendeVazao
        ? 'A vazão planejada supera a vazão disponível.'
        : !geometriaCabe
        ? 'A geometria do tabuleiro (comprimento × largura) excede a área '
              'declarada.'
        : null;
    return BasinChecagemOperacional(
      vazaoPlanejadaLs: vazaoPlanejadaLs,
      vazaoDisponivelLs: vazaoDisponivelLs,
      areaTabuleiroM2: areaTabuleiroM2,
      areaDeclaradaM2: areaDeclaradaM2,
      atendeVazao: atendeVazao,
      geometriaCabeNaArea: geometriaCabe,
      motivo: motivo,
    );
  }
}
