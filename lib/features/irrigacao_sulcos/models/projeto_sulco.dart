import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

import 'ensaios_sulco.dart';
import 'geometria_sulco.dart';
import 'resultados_sulco.dart';

/// Projeto completo de irrigação por sulcos.
///
/// Reúne as entradas do usuário, os ensaios de campo e os resultados
/// derivados. Os dados ausentes permanecem `null`; nada é inventado.
class ProjetoSulco {
  const ProjetoSulco({
    required this.id,
    required this.versaoCalculo,
    required this.area,
    required this.geometria,
    required this.solo,
    required this.cultura,
    required this.clima,
    this.ensaioAvanco,
    this.ensaioInfiltracao,
    required this.operacao,
    this.resultados,
    this.alertas = const [],
  });

  final String id;
  final String versaoCalculo;
  final AreaProjeto area;
  final GeometriaSulco geometria;
  final SoloProjeto solo;
  final CulturaProjeto cultura;
  final ClimaProjeto clima;
  final EnsaioAvanco? ensaioAvanco;
  final EnsaioInfiltracao? ensaioInfiltracao;
  final OperacaoSulco operacao;
  final ResultadosProjetoSulco? resultados;
  final List<AlertaSulco> alertas;

  ProjetoSulco copyWith({
    String? id,
    String? versaoCalculo,
    AreaProjeto? area,
    GeometriaSulco? geometria,
    SoloProjeto? solo,
    CulturaProjeto? cultura,
    ClimaProjeto? clima,
    EnsaioAvanco? ensaioAvanco,
    bool clearEnsaioAvanco = false,
    EnsaioInfiltracao? ensaioInfiltracao,
    bool clearEnsaioInfiltracao = false,
    OperacaoSulco? operacao,
    ResultadosProjetoSulco? resultados,
    bool clearResultados = false,
    List<AlertaSulco>? alertas,
  }) => ProjetoSulco(
    id: id ?? this.id,
    versaoCalculo: versaoCalculo ?? this.versaoCalculo,
    area: area ?? this.area,
    geometria: geometria ?? this.geometria,
    solo: solo ?? this.solo,
    cultura: cultura ?? this.cultura,
    clima: clima ?? this.clima,
    ensaioAvanco: clearEnsaioAvanco ? null : ensaioAvanco ?? this.ensaioAvanco,
    ensaioInfiltracao: clearEnsaioInfiltracao
        ? null
        : ensaioInfiltracao ?? this.ensaioInfiltracao,
    operacao: operacao ?? this.operacao,
    resultados: clearResultados ? null : resultados ?? this.resultados,
    alertas: alertas ?? this.alertas,
  );

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'id': id,
    'versao_calculo': versaoCalculo,
    'area': area.toMap(),
    'geometria': geometria.toMap(),
    'solo': solo.toMap(),
    'cultura': cultura.toMap(),
    'clima': clima.toMap(),
    'ensaio_avanco': ensaioAvanco?.toMap(),
    'ensaio_infiltracao': ensaioInfiltracao?.toMap(),
    'operacao': operacao.toMap(),
    'resultados': resultados?.toMap(),
    'alertas': alertas.map((alerta) => alerta.toMap()).toList(),
  };

  factory ProjetoSulco.fromMap(Map<String, dynamic> map) => ProjetoSulco(
    id: map['id'] as String? ?? '',
    versaoCalculo: map['versao_calculo'] as String? ?? '1.0',
    area: AreaProjeto.fromMap(map['area'] as Map<String, dynamic>? ?? {}),
    geometria: GeometriaSulco.fromMap(
      map['geometria'] as Map<String, dynamic>? ?? {},
    ),
    solo: SoloProjeto.fromMap(map['solo'] as Map<String, dynamic>? ?? {}),
    cultura: CulturaProjeto.fromMap(
      map['cultura'] as Map<String, dynamic>? ?? {},
    ),
    clima: ClimaProjeto.fromMap(map['clima'] as Map<String, dynamic>? ?? {}),
    ensaioAvanco: map['ensaio_avanco'] is Map
        ? EnsaioAvanco.fromMap(
            Map<String, dynamic>.from(map['ensaio_avanco'] as Map),
          )
        : null,
    ensaioInfiltracao: map['ensaio_infiltracao'] is Map
        ? EnsaioInfiltracao.fromMap(
            Map<String, dynamic>.from(map['ensaio_infiltracao'] as Map),
          )
        : null,
    operacao: OperacaoSulco.fromMap(
      map['operacao'] as Map<String, dynamic>? ?? {},
    ),
    resultados: map['resultados'] is Map
        ? ResultadosProjetoSulco.fromMap(
            Map<String, dynamic>.from(map['resultados'] as Map),
          )
        : null,
    alertas:
        (map['alertas'] as List<dynamic>?)
            ?.map(
              (alerta) =>
                  AlertaSulco.fromMap(Map<String, dynamic>.from(alerta as Map)),
            )
            .toList() ??
        const [],
  );
}

/// Dimensões da área irrigada.
class AreaProjeto {
  const AreaProjeto({
    required this.comprimentoM,
    required this.larguraM,
    required this.declividadePercentual,
  });

  final double comprimentoM;
  final double larguraM;
  final double declividadePercentual;

  double get hectares => comprimentoM * larguraM / 10000;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'comprimento_m': comprimentoM,
    'largura_m': larguraM,
    'declividade_percentual': declividadePercentual,
  };

  factory AreaProjeto.fromMap(Map<String, dynamic> map) => AreaProjeto(
    comprimentoM: (map['comprimento_m'] as num?)?.toDouble() ?? 0,
    larguraM: (map['largura_m'] as num?)?.toDouble() ?? 0,
    declividadePercentual:
        (map['declividade_percentual'] as num?)?.toDouble() ?? 0,
  );
}

/// Características do solo que afetam o balanço hídrico.
class SoloProjeto {
  const SoloProjeto({
    required this.textura,
    required this.uccPercentual,
    required this.upmpPercentual,
    required this.densidadeGcm3,
    required this.vibMmHora,
  });

  final TexturaSolo textura;
  final double uccPercentual;
  final double upmpPercentual;
  final double densidadeGcm3;

  /// Velocidade de infiltração básica, em mm/h.
  final double vibMmHora;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'textura': textura.name,
    'ucc_percentual': uccPercentual,
    'upmp_percentual': upmpPercentual,
    'densidade_gcm3': densidadeGcm3,
    'vib_mm_h': vibMmHora,
  };

  factory SoloProjeto.fromMap(Map<String, dynamic> map) => SoloProjeto(
    textura: TexturaSoloExtension.fromString(map['textura'] as String?),
    uccPercentual: (map['ucc_percentual'] as num?)?.toDouble() ?? 0,
    upmpPercentual: (map['upmp_percentual'] as num?)?.toDouble() ?? 0,
    densidadeGcm3: (map['densidade_gcm3'] as num?)?.toDouble() ?? 1.4,
    vibMmHora: (map['vib_mm_h'] as num?)?.toDouble() ?? 0,
  );
}

/// Características da cultura e do sistema radicular.
class CulturaProjeto {
  const CulturaProjeto({
    required this.nome,
    required this.espacamentoFileirasM,
    required this.espacamentoPlantasM,
    this.kc,
    this.fracaoAguaDisponivel = 0.5,
    this.profundidadeRaizesM = 1.0,
  });

  final String nome;
  final double espacamentoFileirasM;
  final double espacamentoPlantasM;
  final double? kc;
  final double fracaoAguaDisponivel;
  final double profundidadeRaizesM;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'nome': nome,
    'espacamento_fileiras_m': espacamentoFileirasM,
    'espacamento_plantas_m': espacamentoPlantasM,
    'kc': kc,
    'fracao_agua_disponivel': fracaoAguaDisponivel,
    'profundidade_raizes_m': profundidadeRaizesM,
  };

  factory CulturaProjeto.fromMap(Map<String, dynamic> map) => CulturaProjeto(
    nome: map['nome'] as String? ?? '',
    espacamentoFileirasM:
        (map['espacamento_fileiras_m'] as num?)?.toDouble() ?? 0,
    espacamentoPlantasM:
        (map['espacamento_plantas_m'] as num?)?.toDouble() ?? 0,
    kc: (map['kc'] as num?)?.toDouble(),
    fracaoAguaDisponivel:
        (map['fracao_agua_disponivel'] as num?)?.toDouble() ?? 0.5,
    profundidadeRaizesM:
        (map['profundidade_raizes_m'] as num?)?.toDouble() ?? 1.0,
  );
}

/// Demanda climática do projeto.
class ClimaProjeto {
  const ClimaProjeto({
    this.etoMmDia,
    this.etcMmDia,
    this.precipitacaoEfetivaMmDia,
    required this.demandaLiquidaMmDia,
  });

  final double? etoMmDia;
  final double? etcMmDia;
  final double? precipitacaoEfetivaMmDia;
  final double demandaLiquidaMmDia;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'eto_mm_dia': etoMmDia,
    'etc_mm_dia': etcMmDia,
    'precipitacao_efetiva_mm_dia': precipitacaoEfetivaMmDia,
    'demanda_liquida_mm_dia': demandaLiquidaMmDia,
  };

  factory ClimaProjeto.fromMap(Map<String, dynamic> map) => ClimaProjeto(
    etoMmDia: (map['eto_mm_dia'] as num?)?.toDouble(),
    etcMmDia: (map['etc_mm_dia'] as num?)?.toDouble(),
    precipitacaoEfetivaMmDia: (map['precipitacao_efetiva_mm_dia'] as num?)
        ?.toDouble(),
    demandaLiquidaMmDia:
        (map['demanda_liquida_mm_dia'] as num?)?.toDouble() ?? 0,
  );
}

/// Parâmetros operacionais adotados na simulação.
class OperacaoSulco {
  const OperacaoSulco({
    required this.vazaoInicialLs,
    this.vazaoReduzidaLs,
    this.tempoMudancaH,
    required this.jornadaDiariaH,
    this.perdasConducaoLs,
    this.escoamentoReutilizado = false,
  });

  final double vazaoInicialLs;
  final double? vazaoReduzidaLs;
  final double? tempoMudancaH;
  final double jornadaDiariaH;
  final double? perdasConducaoLs;
  final bool escoamentoReutilizado;

  /// As chaves são parte do formato persistido e não devem ser renomeadas.
  Map<String, dynamic> toMap() => {
    'vazao_inicial_ls': vazaoInicialLs,
    'vazao_reduzida_ls': vazaoReduzidaLs,
    'tempo_mudanca_h': tempoMudancaH,
    'jornada_diaria_h': jornadaDiariaH,
    'perdas_conducao_ls': perdasConducaoLs,
    'escoamento_reutilizado': escoamentoReutilizado,
  };

  factory OperacaoSulco.fromMap(Map<String, dynamic> map) => OperacaoSulco(
    vazaoInicialLs: (map['vazao_inicial_ls'] as num?)?.toDouble() ?? 0,
    vazaoReduzidaLs: (map['vazao_reduzida_ls'] as num?)?.toDouble(),
    tempoMudancaH: (map['tempo_mudanca_h'] as num?)?.toDouble(),
    jornadaDiariaH: (map['jornada_diaria_h'] as num?)?.toDouble() ?? 24,
    perdasConducaoLs: (map['perdas_conducao_ls'] as num?)?.toDouble(),
    escoamentoReutilizado: map['escoamento_reutilizado'] as bool? ?? false,
  );
}
