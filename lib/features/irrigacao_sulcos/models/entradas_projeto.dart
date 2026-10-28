import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';

import 'curva_infiltracao.dart';
import 'proveniencia_dado.dart';

/// Contrato versionado das entradas originais do projeto de sulcos.
///
/// Guarda apenas o que o usuário informou, não os resultados derivados.
/// `null` significa ausente, inclusive ao migrar um cenário anterior à
/// versão 1.
class EntradasProjeto {
  const EntradasProjeto({
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
    this.origemChuva = OrigemChuva.naoInformada,
    this.metodoEtc = MetodoEtc.adotada,
    this.desnivelLongitudinalM,
    this.baseLongitudinalM,
    this.decliveEncostaPercent,
    this.orientacaoSulco,
    this.provenienciaGeometria = ProvenienciaDado.naoInformado,
    this.dimensionarComprimentoCriddle = false,
    this.origens = const {},
    this.curvaInfiltracao,
  });

  /// Versão do contrato, usada para migrar cenários antigos.
  final int versao;

  final double? uccPercentual;
  final double? upmpPercentual;
  final double? densidadeAparenteGcm3;
  final double? profundidadeRadicularCm;
  final double? fracaoDisponivel;

  // ---- Demanda hídrica ----
  final double? etcAdotadaMmDia;
  final double? etoMmDia;
  final double? temperaturaMediaC;
  final double? latitudeGraus;
  final int? mesReferencia;
  final double? kc;
  final double? precipitacaoMmDia;
  final OrigemChuva origemChuva;
  final MetodoEtc metodoEtc;

  // ---- Geometria do terreno ----
  final double? desnivelLongitudinalM;
  final double? baseLongitudinalM;
  final double? decliveEncostaPercent;
  final String? orientacaoSulco;
  final ProvenienciaDado provenienciaGeometria;
  final bool dimensionarComprimentoCriddle;

  /// Proveniência por campo, quando a origem difere da geometria geral.
  final Map<String, ProvenienciaDado> origens;

  final CurvaInfiltracao? curvaInfiltracao;

  /// Indica se há dados suficientes para recalcular a irrigação.
  bool get podeRecalcularIrrigacao =>
      uccPercentual != null &&
      upmpPercentual != null &&
      densidadeAparenteGcm3 != null &&
      profundidadeRadicularCm != null &&
      fracaoDisponivel != null &&
      switch (metodoEtc) {
        MetodoEtc.adotada => etcAdotadaMmDia != null,
        MetodoEtc.blaneyCriddle =>
          temperaturaMediaC != null &&
              latitudeGraus != null &&
              mesReferencia != null &&
              kc != null,
        MetodoEtc.etoVezesKc => etoMmDia != null && kc != null,
      } &&
      precipitacaoMmDia != null &&
      origemChuva != OrigemChuva.naoInformada &&
      origemChuva != OrigemChuva.provavel;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
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
    'origem_geometria': provenienciaGeometria.name,
    'dimensionar_comprimento_criddle': dimensionarComprimentoCriddle,
    'origens': origens.map((chave, valor) => MapEntry(chave, valor.name)),
    'curva_infiltracao': curvaInfiltracao?.toMap(),
  };

  factory EntradasProjeto.fromMap(Map<String, dynamic> map) {
    double? numero(String chave) => (map[chave] as num?)?.toDouble();
    return EntradasProjeto(
      versao: (map['versao'] as num?)?.toInt() ?? 1,
      uccPercentual: numero('ucc_percentual'),
      upmpPercentual: numero('upmp_percentual'),
      densidadeAparenteGcm3: numero('densidade_aparente_g_cm3'),
      profundidadeRadicularCm: numero('profundidade_radicular_cm'),
      fracaoDisponivel: numero('fracao_disponivel'),
      etcAdotadaMmDia: numero('etc_adotada_mm_dia'),
      etoMmDia: numero('eto_mm_dia'),
      temperaturaMediaC: numero('temperatura_media_c'),
      latitudeGraus: numero('latitude_graus'),
      mesReferencia: (map['mes_referencia'] as num?)?.toInt(),
      kc: numero('kc'),
      precipitacaoMmDia: numero('precipitacao_mm_dia'),
      origemChuva: OrigemChuva.values.firstWhere(
        (valor) => valor.name == map['origem_chuva'],
        orElse: () => OrigemChuva.naoInformada,
      ),
      metodoEtc: MetodoEtc.values.firstWhere(
        (valor) => valor.name == map['metodo_etc'],
        orElse: () => MetodoEtc.adotada,
      ),
      desnivelLongitudinalM: numero('desnivel_longitudinal_m'),
      baseLongitudinalM: numero('base_longitudinal_m'),
      decliveEncostaPercent: numero('declive_encosta_percent'),
      orientacaoSulco: map['orientacao_sulco'] as String?,
      provenienciaGeometria: ProvenienciaDado.values.firstWhere(
        (valor) => valor.name == map['origem_geometria'],
        orElse: () => ProvenienciaDado.naoInformado,
      ),
      dimensionarComprimentoCriddle:
          map['dimensionar_comprimento_criddle'] as bool? ?? false,
      origens:
          (map['origens'] as Map?)?.map(
            (chave, valor) => MapEntry(
              chave as String,
              ProvenienciaDado.values.firstWhere(
                (origem) => origem.name == valor,
                orElse: () => ProvenienciaDado.naoInformado,
              ),
            ),
          ) ??
          const {},
      curvaInfiltracao: map['curva_infiltracao'] is Map
          ? CurvaInfiltracao.fromMap(
              Map<String, dynamic>.from(map['curva_infiltracao'] as Map),
            )
          : null,
    );
  }
}
