import 'dart:math' as math;

import 'package:irrigasim/models/irrigation_parameters.dart';

enum FormaSulco { v, trapezoidal, retangular }

enum MetodoAjusteAvanco { doisPontos, minimosQuadrados, interpolacao }

enum TipoAlerta {
  aviso,
  erro,
  info,
  erosao,
  eficienciaBaixa,
  perdaAlta,
  dadoPendente,
}

class IrrigationProject {
  final String id;
  final String versaoCalculo;
  final Area area;
  final GeometriaSulco geometria;
  final Solo solo;
  final Cultura cultura;
  final Clima clima;
  final EnsaioAvanco? ensaioAvanco;
  final EnsaioInfiltracao? ensaioInfiltracao;
  final ParametrosOperacao operacao;
  final ResultadosProjeto? resultados;
  final List<Alerta> alertas;

  const IrrigationProject({
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

  IrrigationProject copyWith({
    String? id,
    String? versaoCalculo,
    Area? area,
    GeometriaSulco? geometria,
    Solo? solo,
    Cultura? cultura,
    Clima? clima,
    EnsaioAvanco? ensaioAvanco,
    EnsaioInfiltracao? ensaioInfiltracao,
    ParametrosOperacao? operacao,
    ResultadosProjeto? resultados,
    List<Alerta>? alertas,
  }) {
    return IrrigationProject(
      id: id ?? this.id,
      versaoCalculo: versaoCalculo ?? this.versaoCalculo,
      area: area ?? this.area,
      geometria: geometria ?? this.geometria,
      solo: solo ?? this.solo,
      cultura: cultura ?? this.cultura,
      clima: clima ?? this.clima,
      ensaioAvanco: ensaioAvanco ?? this.ensaioAvanco,
      ensaioInfiltracao: ensaioInfiltracao ?? this.ensaioInfiltracao,
      operacao: operacao ?? this.operacao,
      resultados: resultados ?? this.resultados,
      alertas: alertas ?? this.alertas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'alertas': alertas.map((a) => a.toMap()).toList(),
    };
  }

  factory IrrigationProject.fromMap(Map<String, dynamic> map) {
    return IrrigationProject(
      id: map['id'] as String? ?? '',
      versaoCalculo: map['versao_calculo'] as String? ?? '1.0',
      area: Area.fromMap(map['area'] as Map<String, dynamic>? ?? {}),
      geometria: GeometriaSulco.fromMap(
        map['geometria'] as Map<String, dynamic>? ?? {},
      ),
      solo: Solo.fromMap(map['solo'] as Map<String, dynamic>? ?? {}),
      cultura: Cultura.fromMap(map['cultura'] as Map<String, dynamic>? ?? {}),
      clima: Clima.fromMap(map['clima'] as Map<String, dynamic>? ?? {}),
      ensaioAvanco: map['ensaio_avanco'] != null
          ? EnsaioAvanco.fromMap(map['ensaio_avanco'] as Map<String, dynamic>)
          : null,
      ensaioInfiltracao: map['ensaio_infiltracao'] != null
          ? EnsaioInfiltracao.fromMap(
              map['ensaio_infiltracao'] as Map<String, dynamic>,
            )
          : null,
      operacao: ParametrosOperacao.fromMap(
        map['operacao'] as Map<String, dynamic>? ?? {},
      ),
      resultados: map['resultados'] != null
          ? ResultadosProjeto.fromMap(map['resultados'] as Map<String, dynamic>)
          : null,
      alertas:
          (map['alertas'] as List<dynamic>?)
              ?.map((a) => Alerta.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Area {
  final double comprimentoM;
  final double larguraM;
  final double declividadePercentual;

  const Area({
    required this.comprimentoM,
    required this.larguraM,
    required this.declividadePercentual,
  });

  double get hectares => (comprimentoM * larguraM) / 10000;

  Map<String, dynamic> toMap() {
    return {
      'comprimento_m': comprimentoM,
      'largura_m': larguraM,
      'declividade_percentual': declividadePercentual,
    };
  }

  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      comprimentoM: (map['comprimento_m'] as num?)?.toDouble() ?? 0,
      larguraM: (map['largura_m'] as num?)?.toDouble() ?? 0,
      declividadePercentual:
          (map['declividade_percentual'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GeometriaSulco {
  final FormaSulco forma;
  final double? larguraSuperiorM;
  final double? profundidadeM;
  final double? larguraBaseM;
  final double espacamentoM;

  const GeometriaSulco({
    required this.forma,
    this.larguraSuperiorM,
    this.profundidadeM,
    this.larguraBaseM,
    required this.espacamentoM,
  });

  double? get areaSecaoM2 {
    if (forma == FormaSulco.retangular) {
      if (larguraSuperiorM == null || profundidadeM == null) return null;
      return larguraSuperiorM! * profundidadeM!;
    }
    if (forma == FormaSulco.v) {
      if (larguraSuperiorM == null || profundidadeM == null) return null;
      return (larguraSuperiorM! * profundidadeM!) / 2;
    }
    if (forma == FormaSulco.trapezoidal) {
      if (larguraSuperiorM == null ||
          profundidadeM == null ||
          larguraBaseM == null) {
        return null;
      }
      return ((larguraSuperiorM! + larguraBaseM!) / 2) * profundidadeM!;
    }
    return null;
  }

  double? get perimetroMolhadoM {
    if (forma == FormaSulco.retangular) {
      if (larguraSuperiorM == null || profundidadeM == null) return null;
      return larguraSuperiorM! + 2 * profundidadeM!;
    }
    if (forma == FormaSulco.v) {
      if (larguraSuperiorM == null || profundidadeM == null) return null;
      final semiLargura = larguraSuperiorM! / 2;
      final lado = math.sqrt(
        semiLargura * semiLargura + profundidadeM! * profundidadeM!,
      );
      return 2 * lado;
    }
    if (forma == FormaSulco.trapezoidal) {
      if (larguraSuperiorM == null ||
          profundidadeM == null ||
          larguraBaseM == null) {
        return null;
      }
      final lado = ((larguraSuperiorM! - larguraBaseM!) / 2);
      final comprimentoLado = math.sqrt(
        lado * lado + profundidadeM! * profundidadeM!,
      );
      return larguraBaseM! + 2 * comprimentoLado;
    }
    return null;
  }

  double? get raioHidraulicoM {
    final area = areaSecaoM2;
    final perimetro = perimetroMolhadoM;
    if (area == null || perimetro == null || perimetro == 0) return null;
    return area / perimetro;
  }

  /// Regra E ≤ 2z (p.52): z é profundidade das raízes, não do canal.
  bool espacamentoValido(double profundidadeRadicularM) {
    return profundidadeRadicularM.isFinite &&
        profundidadeRadicularM > 0 &&
        espacamentoM.isFinite &&
        espacamentoM > 0 &&
        espacamentoM <= 2 * profundidadeRadicularM;
  }

  Map<String, dynamic> toMap() {
    return {
      'forma': forma.name,
      'largura_superior_m': larguraSuperiorM,
      'profundidade_m': profundidadeM,
      'largura_base_m': larguraBaseM,
      'espacamento_m': espacamentoM,
    };
  }

  factory GeometriaSulco.fromMap(Map<String, dynamic> map) {
    return GeometriaSulco(
      forma: FormaSulco.values.firstWhere(
        (f) => f.name == map['forma'],
        orElse: () => FormaSulco.v,
      ),
      larguraSuperiorM: (map['largura_superior_m'] as num?)?.toDouble(),
      profundidadeM: (map['profundidade_m'] as num?)?.toDouble(),
      larguraBaseM: (map['largura_base_m'] as num?)?.toDouble(),
      espacamentoM: (map['espacamento_m'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Solo {
  final TexturaSolo textura;
  final double uccPercentual;
  final double upmpPercentual;
  final double densidadeGcm3;
  final double vibMmH;

  const Solo({
    required this.textura,
    required this.uccPercentual,
    required this.upmpPercentual,
    required this.densidadeGcm3,
    required this.vibMmH,
  });

  Map<String, dynamic> toMap() {
    return {
      'textura': textura.name,
      'ucc_percentual': uccPercentual,
      'upmp_percentual': upmpPercentual,
      'densidade_gcm3': densidadeGcm3,
      'vib_mm_h': vibMmH,
    };
  }

  factory Solo.fromMap(Map<String, dynamic> map) {
    return Solo(
      textura: TexturaSoloExtension.fromString(map['textura'] as String?),
      uccPercentual: (map['ucc_percentual'] as num?)?.toDouble() ?? 0,
      upmpPercentual: (map['upmp_percentual'] as num?)?.toDouble() ?? 0,
      densidadeGcm3: (map['densidade_gcm3'] as num?)?.toDouble() ?? 1.4,
      vibMmH: (map['vib_mm_h'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Cultura {
  final String nome;
  final double espacamentoFileirasM;
  final double espacamentoPlantasM;
  final double? kc;
  final double fracaoAguaDisponivel;
  final double profundidadeRaizesM;

  const Cultura({
    required this.nome,
    required this.espacamentoFileirasM,
    required this.espacamentoPlantasM,
    this.kc,
    this.fracaoAguaDisponivel = 0.5,
    this.profundidadeRaizesM = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'espacamento_fileiras_m': espacamentoFileirasM,
      'espacamento_plantas_m': espacamentoPlantasM,
      'kc': kc,
      'fracao_agua_disponivel': fracaoAguaDisponivel,
      'profundidade_raizes_m': profundidadeRaizesM,
    };
  }

  factory Cultura.fromMap(Map<String, dynamic> map) {
    return Cultura(
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
}

class Clima {
  final double? etoMmDia;
  final double? etcMmDia;
  final double? precipitacaoEfetivaMmDia;
  final double demandaLiquidaMmDia;

  const Clima({
    this.etoMmDia,
    this.etcMmDia,
    this.precipitacaoEfetivaMmDia,
    required this.demandaLiquidaMmDia,
  });

  Map<String, dynamic> toMap() {
    return {
      'eto_mm_dia': etoMmDia,
      'etc_mm_dia': etcMmDia,
      'precipitacao_efetiva_mm_dia': precipitacaoEfetivaMmDia,
      'demanda_liquida_mm_dia': demandaLiquidaMmDia,
    };
  }

  factory Clima.fromMap(Map<String, dynamic> map) {
    return Clima(
      etoMmDia: (map['eto_mm_dia'] as num?)?.toDouble(),
      etcMmDia: (map['etc_mm_dia'] as num?)?.toDouble(),
      precipitacaoEfetivaMmDia: (map['precipitacao_efetiva_mm_dia'] as num?)
          ?.toDouble(),
      demandaLiquidaMmDia:
          (map['demanda_liquida_mm_dia'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PontoEnsaio {
  final double distanciaM;
  final double tempoMin;

  const PontoEnsaio({required this.distanciaM, required this.tempoMin});

  Map<String, dynamic> toMap() {
    return {'distancia_m': distanciaM, 'tempo_min': tempoMin};
  }

  factory PontoEnsaio.fromMap(Map<String, dynamic> map) {
    return PontoEnsaio(
      distanciaM: (map['distancia_m'] as num?)?.toDouble() ?? 0,
      tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ParametrosAvanco {
  final double k;
  final double b;
  final MetodoAjusteAvanco metodo;

  const ParametrosAvanco({
    required this.k,
    required this.b,
    required this.metodo,
  });

  Map<String, dynamic> toMap() {
    return {'k': k, 'b': b, 'metodo': metodo.name};
  }

  factory ParametrosAvanco.fromMap(Map<String, dynamic> map) {
    return ParametrosAvanco(
      k: (map['k'] as num?)?.toDouble() ?? 0,
      b: (map['b'] as num?)?.toDouble() ?? 0,
      metodo: MetodoAjusteAvanco.values.firstWhere(
        (m) => m.name == map['metodo'],
        orElse: () => MetodoAjusteAvanco.doisPontos,
      ),
    );
  }
}

class EnsaioAvanco {
  final List<PontoEnsaio> pontos;
  final MetodoAjusteAvanco metodo;
  final ParametrosAvanco? parametros;
  final DateTime? data;

  const EnsaioAvanco({
    required this.pontos,
    required this.metodo,
    this.parametros,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'pontos': pontos.map((p) => p.toMap()).toList(),
      'metodo': metodo.name,
      'parametros': parametros?.toMap(),
      'data': data?.toIso8601String(),
    };
  }

  factory EnsaioAvanco.fromMap(Map<String, dynamic> map) {
    return EnsaioAvanco(
      pontos:
          (map['pontos'] as List<dynamic>?)
              ?.map((p) => PontoEnsaio.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      metodo: MetodoAjusteAvanco.values.firstWhere(
        (m) => m.name == map['metodo'],
        orElse: () => MetodoAjusteAvanco.doisPontos,
      ),
      parametros: map['parametros'] != null
          ? ParametrosAvanco.fromMap(map['parametros'] as Map<String, dynamic>)
          : null,
      data: map['data'] != null
          ? DateTime.tryParse(map['data'] as String)
          : null,
    );
  }
}

class PontoInfiltracao {
  final double tempoMin;
  final double volumeInfiltradoMm;

  const PontoInfiltracao({
    required this.tempoMin,
    required this.volumeInfiltradoMm,
  });

  Map<String, dynamic> toMap() {
    return {'tempo_min': tempoMin, 'volume_infiltrado_mm': volumeInfiltradoMm};
  }

  factory PontoInfiltracao.fromMap(Map<String, dynamic> map) {
    return PontoInfiltracao(
      tempoMin: (map['tempo_min'] as num?)?.toDouble() ?? 0,
      volumeInfiltradoMm:
          (map['volume_infiltrado_mm'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ParametrosInfiltracao {
  final double k;
  final double n;
  final double? baseLog;

  const ParametrosInfiltracao({required this.k, required this.n, this.baseLog});

  Map<String, dynamic> toMap() {
    return {'k': k, 'n': n, 'base_log': baseLog};
  }

  factory ParametrosInfiltracao.fromMap(Map<String, dynamic> map) {
    return ParametrosInfiltracao(
      k: (map['k'] as num?)?.toDouble() ?? 0,
      n: (map['n'] as num?)?.toDouble() ?? 0,
      baseLog: (map['base_log'] as num?)?.toDouble(),
    );
  }
}

class ConfiguracaoEnsaioInfiltracao {
  final double? qEntradaLs;
  final double? qSaidaLs;
  final String unidadeVolume;

  const ConfiguracaoEnsaioInfiltracao({
    this.qEntradaLs,
    this.qSaidaLs,
    required this.unidadeVolume,
  });

  Map<String, dynamic> toMap() {
    return {
      'q_entrada_ls': qEntradaLs,
      'q_saida_ls': qSaidaLs,
      'unidade_volume': unidadeVolume,
    };
  }

  factory ConfiguracaoEnsaioInfiltracao.fromMap(Map<String, dynamic> map) {
    return ConfiguracaoEnsaioInfiltracao(
      qEntradaLs: (map['q_entrada_ls'] as num?)?.toDouble(),
      qSaidaLs: (map['q_saida_ls'] as num?)?.toDouble(),
      unidadeVolume: map['unidade_volume'] as String? ?? 'mm',
    );
  }
}

class EnsaioInfiltracao {
  final ConfiguracaoEnsaioInfiltracao configuracao;
  final List<PontoInfiltracao> pontos;
  final ParametrosInfiltracao? parametros;
  final DateTime? data;

  const EnsaioInfiltracao({
    required this.configuracao,
    required this.pontos,
    this.parametros,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'configuracao': configuracao.toMap(),
      'pontos': pontos.map((p) => p.toMap()).toList(),
      'parametros': parametros?.toMap(),
      'data': data?.toIso8601String(),
    };
  }

  factory EnsaioInfiltracao.fromMap(Map<String, dynamic> map) {
    return EnsaioInfiltracao(
      configuracao: ConfiguracaoEnsaioInfiltracao.fromMap(
        map['configuracao'] as Map<String, dynamic>? ?? {},
      ),
      pontos:
          (map['pontos'] as List<dynamic>?)
              ?.map((p) => PontoInfiltracao.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      parametros: map['parametros'] != null
          ? ParametrosInfiltracao.fromMap(
              map['parametros'] as Map<String, dynamic>,
            )
          : null,
      data: map['data'] != null
          ? DateTime.tryParse(map['data'] as String)
          : null,
    );
  }
}

class ParametrosOperacao {
  final double vazaoInicialLs;
  final double? vazaoReduzidaLs;
  final double? tempoMudancaH;
  final double jornadaDiariaH;
  final double? perdasConducaoLs;
  final bool escoamentoReutilizado;

  const ParametrosOperacao({
    required this.vazaoInicialLs,
    this.vazaoReduzidaLs,
    this.tempoMudancaH,
    required this.jornadaDiariaH,
    this.perdasConducaoLs,
    this.escoamentoReutilizado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'vazao_inicial_ls': vazaoInicialLs,
      'vazao_reduzida_ls': vazaoReduzidaLs,
      'tempo_mudanca_h': tempoMudancaH,
      'jornada_diaria_h': jornadaDiariaH,
      'perdas_conducao_ls': perdasConducaoLs,
      'escoamento_reutilizado': escoamentoReutilizado,
    };
  }

  factory ParametrosOperacao.fromMap(Map<String, dynamic> map) {
    return ParametrosOperacao(
      vazaoInicialLs: (map['vazao_inicial_ls'] as num?)?.toDouble() ?? 0,
      vazaoReduzidaLs: (map['vazao_reduzida_ls'] as num?)?.toDouble(),
      tempoMudancaH: (map['tempo_mudanca_h'] as num?)?.toDouble(),
      jornadaDiariaH: (map['jornada_diaria_h'] as num?)?.toDouble() ?? 24,
      perdasConducaoLs: (map['perdas_conducao_ls'] as num?)?.toDouble(),
      escoamentoReutilizado: map['escoamento_reutilizado'] as bool? ?? false,
    );
  }
}

class DadosEstaca {
  final double estacaM;
  final double? tempoAvancoMin;
  final double? tempoDeplecaoMin;
  final double? tempoRecessoMin;
  final double? tempoOportunidadeMin;
  final double? laminaInfiltradaMm;

  const DadosEstaca({
    required this.estacaM,
    this.tempoAvancoMin,
    this.tempoDeplecaoMin,
    this.tempoRecessoMin,
    this.tempoOportunidadeMin,
    this.laminaInfiltradaMm,
  });

  Map<String, dynamic> toMap() {
    return {
      'estaca_m': estacaM,
      'tempo_avanco_min': tempoAvancoMin,
      'tempo_deplecao_min': tempoDeplecaoMin,
      'tempo_recesso_min': tempoRecessoMin,
      'tempo_oportunidade_min': tempoOportunidadeMin,
      'lamina_infiltrada_mm': laminaInfiltradaMm,
    };
  }

  factory DadosEstaca.fromMap(Map<String, dynamic> map) {
    return DadosEstaca(
      estacaM: (map['estaca_m'] as num?)?.toDouble() ?? 0,
      tempoAvancoMin: (map['tempo_avanco_min'] as num?)?.toDouble(),
      tempoDeplecaoMin: (map['tempo_deplecao_min'] as num?)?.toDouble(),
      tempoRecessoMin: (map['tempo_recesso_min'] as num?)?.toDouble(),
      tempoOportunidadeMin: (map['tempo_oportunidade_min'] as num?)?.toDouble(),
      laminaInfiltradaMm: (map['lamina_infiltrada_mm'] as num?)?.toDouble(),
    );
  }
}

class FaseReposicao {
  final double? tempoCorteH;
  final bool escoamentoReutilizado;
  final double? instanteInicioEscoamentoFinalMin;

  const FaseReposicao({
    this.tempoCorteH,
    this.escoamentoReutilizado = false,
    this.instanteInicioEscoamentoFinalMin,
  });

  Map<String, dynamic> toMap() {
    return {
      'tempo_corte_h': tempoCorteH,
      'escoamento_reutilizado': escoamentoReutilizado,
      'instante_inicio_escoamento_final_min': instanteInicioEscoamentoFinalMin,
    };
  }

  factory FaseReposicao.fromMap(Map<String, dynamic> map) {
    return FaseReposicao(
      tempoCorteH: (map['tempo_corte_h'] as num?)?.toDouble(),
      escoamentoReutilizado: map['escoamento_reutilizado'] as bool? ?? false,
      instanteInicioEscoamentoFinalMin:
          (map['instante_inicio_escoamento_final_min'] as num?)?.toDouble(),
    );
  }
}

class Diagnostico {
  final String classificacaoUniformidade;
  final String classificacaoEficiencia;
  final List<String> causas;
  final List<String> acoesSugeridas;

  const Diagnostico({
    required this.classificacaoUniformidade,
    required this.classificacaoEficiencia,
    required this.causas,
    required this.acoesSugeridas,
  });

  Map<String, dynamic> toMap() {
    return {
      'classificacao_uniformidade': classificacaoUniformidade,
      'classificacao_eficiencia': classificacaoEficiencia,
      'causas': causas,
      'acoes_sugeridas': acoesSugeridas,
    };
  }

  factory Diagnostico.fromMap(Map<String, dynamic> map) {
    return Diagnostico(
      classificacaoUniformidade:
          map['classificacao_uniformidade'] as String? ?? '',
      classificacaoEficiencia: map['classificacao_eficiencia'] as String? ?? '',
      causas:
          (map['causas'] as List<dynamic>?)?.map((c) => c as String).toList() ??
          [],
      acoesSugeridas:
          (map['acoes_sugeridas'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
    );
  }
}

class ResultadosProjeto {
  final double irnMm;
  final double turnoRegaCalculadoDias;
  final int turnoRegaOperacionalDias;
  final double? laminaMediaAplicadaMm;
  final double? eficienciaAplicacaoPercentual;
  final double? eficienciaDistribuicaoPercentual;
  final double? perdaPercolacaoPercentual;
  final double? perdaEscoamentoPercentual;
  final Diagnostico? diagnostico;
  final List<DadosEstaca>? dadosEstacas;

  const ResultadosProjeto({
    required this.irnMm,
    required this.turnoRegaCalculadoDias,
    required this.turnoRegaOperacionalDias,
    this.laminaMediaAplicadaMm,
    this.eficienciaAplicacaoPercentual,
    this.eficienciaDistribuicaoPercentual,
    this.perdaPercolacaoPercentual,
    this.perdaEscoamentoPercentual,
    this.diagnostico,
    this.dadosEstacas,
  });

  Map<String, dynamic> toMap() {
    return {
      'irn_mm': irnMm,
      'turno_rega_calculado_dias': turnoRegaCalculadoDias,
      'turno_rega_operacional_dias': turnoRegaOperacionalDias,
      'lamina_media_aplicada_mm': laminaMediaAplicadaMm,
      'eficiencia_aplicacao_percentual': eficienciaAplicacaoPercentual,
      'eficiencia_distribuicao_percentual': eficienciaDistribuicaoPercentual,
      'perda_percolacao_percentual': perdaPercolacaoPercentual,
      'perda_escoamento_percentual': perdaEscoamentoPercentual,
      'diagnostico': diagnostico?.toMap(),
      'dados_estacas': dadosEstacas?.map((e) => e.toMap()).toList(),
    };
  }

  factory ResultadosProjeto.fromMap(Map<String, dynamic> map) {
    return ResultadosProjeto(
      irnMm: (map['irn_mm'] as num?)?.toDouble() ?? 0,
      turnoRegaCalculadoDias:
          (map['turno_rega_calculado_dias'] as num?)?.toDouble() ?? 0,
      turnoRegaOperacionalDias:
          (map['turno_rega_operacional_dias'] as num?)?.toInt() ?? 0,
      laminaMediaAplicadaMm: (map['lamina_media_aplicada_mm'] as num?)
          ?.toDouble(),
      eficienciaAplicacaoPercentual:
          (map['eficiencia_aplicacao_percentual'] as num?)?.toDouble(),
      eficienciaDistribuicaoPercentual:
          (map['eficiencia_distribuicao_percentual'] as num?)?.toDouble(),
      perdaPercolacaoPercentual: (map['perda_percolacao_percentual'] as num?)
          ?.toDouble(),
      perdaEscoamentoPercentual: (map['perda_escoamento_percentual'] as num?)
          ?.toDouble(),
      diagnostico: map['diagnostico'] != null
          ? Diagnostico.fromMap(map['diagnostico'] as Map<String, dynamic>)
          : null,
      dadosEstacas:
          (map['dados_estacas'] as List<dynamic>?)
              ?.map((e) => DadosEstaca.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Alerta {
  final TipoAlerta tipo;
  final String mensagem;
  final Map<String, dynamic>? dados;

  const Alerta({required this.tipo, required this.mensagem, this.dados});

  Map<String, dynamic> toMap() {
    return {'tipo': tipo.name, 'mensagem': mensagem, 'dados': dados};
  }

  factory Alerta.fromMap(Map<String, dynamic> map) {
    return Alerta(
      tipo: TipoAlerta.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoAlerta.aviso,
      ),
      mensagem: map['mensagem'] as String? ?? '',
      dados: map['dados'] as Map<String, dynamic>?,
    );
  }
}
