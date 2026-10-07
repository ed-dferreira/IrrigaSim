import 'curva_infiltracao_sulco.dart';

enum OrigemChuvaSulco { naoInformada, efetiva, provavel, observada }

enum MetodoEtcSulco { adotada, etoVezesKc, blaneyCriddle }

/// Contrato versionado das entradas originais (não dos resultados derivados).
/// null significa ausente, inclusive ao migrar um cenário anterior à versão 1.
class EntradasProjetoSulco {
  const EntradasProjetoSulco({
    this.versao = 1,
    this.uccPercentual,
    this.upmpPercentual,
    this.densidadeAparenteGcm3,
    this.profundidadeRadicularCm,
    this.fracaoDisponivel,
    this.etcAdotadaMmDia,
    this.etoMmDia,
    this.temperaturaMediaC,
    this.latitudeGraus,
    this.mesReferencia,
    this.kc,
    this.precipitacaoMmDia,
    this.origemChuva = OrigemChuvaSulco.naoInformada,
    this.metodoEtc = MetodoEtcSulco.adotada,
    this.desnivelLongitudinalM,
    this.baseLongitudinalM,
    this.decliveEncostaPercent,
    this.orientacaoSulco,
    this.origemGeometria = ProvenienciaSulco.naoInformado,
    this.dimensionarComprimentoCriddle = false,
    this.origens = const {},
    this.curvaInfiltracao,
  });

  final int versao;
  final double? uccPercentual;
  final double? upmpPercentual;
  final double? densidadeAparenteGcm3;
  final double? profundidadeRadicularCm;
  final double? fracaoDisponivel;
  final double? etcAdotadaMmDia;
  final double? etoMmDia;
  final double? temperaturaMediaC;
  final double? latitudeGraus;
  final int? mesReferencia;
  final double? kc;
  final double? precipitacaoMmDia;
  final OrigemChuvaSulco origemChuva;
  final MetodoEtcSulco metodoEtc;
  final double? desnivelLongitudinalM;
  final double? baseLongitudinalM;
  final double? decliveEncostaPercent;
  final String? orientacaoSulco;
  final ProvenienciaSulco origemGeometria;
  final bool dimensionarComprimentoCriddle;
  final Map<String, ProvenienciaSulco> origens;
  final CurvaInfiltracaoSulco? curvaInfiltracao;

  bool get podeRecalcularIrrigacao =>
      uccPercentual != null &&
      upmpPercentual != null &&
      densidadeAparenteGcm3 != null &&
      profundidadeRadicularCm != null &&
      fracaoDisponivel != null &&
      (metodoEtc == MetodoEtcSulco.adotada
          ? etcAdotadaMmDia != null
          : metodoEtc == MetodoEtcSulco.blaneyCriddle
          ? temperaturaMediaC != null &&
                latitudeGraus != null &&
                mesReferencia != null &&
                kc != null
          : etoMmDia != null && kc != null) &&
      precipitacaoMmDia != null &&
      origemChuva != OrigemChuvaSulco.naoInformada &&
      origemChuva != OrigemChuvaSulco.provavel;

  Map<String, dynamic> toMap() => {
    'versao': versao,
    'ucc_percentual': uccPercentual,
    'upmp_percentual': upmpPercentual,
    'densidade_aparente_g_cm3': densidadeAparenteGcm3,
    'profundidade_radicular_cm': profundidadeRadicularCm,
    'fracao_disponivel': fracaoDisponivel,
    'etc_adotada_mm_dia': etcAdotadaMmDia,
    'eto_mm_dia': etoMmDia,
    'temperatura_media_c': temperaturaMediaC,
    'latitude_graus': latitudeGraus,
    'mes_referencia': mesReferencia,
    'kc': kc,
    'precipitacao_mm_dia': precipitacaoMmDia,
    'origem_chuva': origemChuva.name,
    'metodo_etc': metodoEtc.name,
    'desnivel_longitudinal_m': desnivelLongitudinalM,
    'base_longitudinal_m': baseLongitudinalM,
    'declive_encosta_percent': decliveEncostaPercent,
    'orientacao_sulco': orientacaoSulco,
    'origem_geometria': origemGeometria.name,
    'dimensionar_comprimento_criddle': dimensionarComprimentoCriddle,
    'origens': origens.map((key, value) => MapEntry(key, value.name)),
    'curva_infiltracao': curvaInfiltracao?.toMap(),
  };

  factory EntradasProjetoSulco.fromMap(Map<String, dynamic> map) {
    double? number(String key) => (map[key] as num?)?.toDouble();
    return EntradasProjetoSulco(
      versao: (map['versao'] as num?)?.toInt() ?? 1,
      uccPercentual: number('ucc_percentual'),
      upmpPercentual: number('upmp_percentual'),
      densidadeAparenteGcm3: number('densidade_aparente_g_cm3'),
      profundidadeRadicularCm: number('profundidade_radicular_cm'),
      fracaoDisponivel: number('fracao_disponivel'),
      etcAdotadaMmDia: number('etc_adotada_mm_dia'),
      etoMmDia: number('eto_mm_dia'),
      temperaturaMediaC: number('temperatura_media_c'),
      latitudeGraus: number('latitude_graus'),
      mesReferencia: (map['mes_referencia'] as num?)?.toInt(),
      kc: number('kc'),
      precipitacaoMmDia: number('precipitacao_mm_dia'),
      origemChuva: OrigemChuvaSulco.values.firstWhere(
        (value) => value.name == map['origem_chuva'],
        orElse: () => OrigemChuvaSulco.naoInformada,
      ),
      metodoEtc: MetodoEtcSulco.values.firstWhere(
        (value) => value.name == map['metodo_etc'],
        orElse: () => MetodoEtcSulco.adotada,
      ),
      desnivelLongitudinalM: number('desnivel_longitudinal_m'),
      baseLongitudinalM: number('base_longitudinal_m'),
      decliveEncostaPercent: number('declive_encosta_percent'),
      orientacaoSulco: map['orientacao_sulco'] as String?,
      origemGeometria: ProvenienciaSulco.values.firstWhere(
        (value) => value.name == map['origem_geometria'],
        orElse: () => ProvenienciaSulco.naoInformado,
      ),
      dimensionarComprimentoCriddle:
          map['dimensionar_comprimento_criddle'] as bool? ?? false,
      origens:
          (map['origens'] as Map?)?.map(
            (key, value) => MapEntry(
              key as String,
              ProvenienciaSulco.values.firstWhere(
                (origin) => origin.name == value,
                orElse: () => ProvenienciaSulco.naoInformado,
              ),
            ),
          ) ??
          const {},
      curvaInfiltracao: map['curva_infiltracao'] is Map
          ? CurvaInfiltracaoSulco.fromMap(
              Map<String, dynamic>.from(map['curva_infiltracao'] as Map),
            )
          : null,
    );
  }
}
