import 'package:cloud_firestore/cloud_firestore.dart';

import '../irrigation_parameters.dart';
import '../simulation_result.dart';
import '../sulcos/tipo_sulco_info.dart';

import '../simulation_result_model.dart';
import '../sulcos/field_measurements.dart';

class CenarioSalvo {
  final String id;
  final String nome;
  final MetodoIrrigacao metodo;
  final IrrigationParameters parametros;
  final SimulationResult resultado;
  final DateTime dataCriacao;
  final DateTime dataModificacao;
  final String? usuarioId;

  const CenarioSalvo({
    required this.id,
    required this.nome,
    required this.metodo,
    required this.parametros,
    required this.resultado,
    required this.dataCriacao,
    required this.dataModificacao,
    this.usuarioId,
  });

  CenarioSalvo copyWith({
    String? id,
    String? nome,
    MetodoIrrigacao? metodo,
    IrrigationParameters? parametros,
    SimulationResult? resultado,
    DateTime? dataCriacao,
    DateTime? dataModificacao,
    String? usuarioId,
  }) {
    return CenarioSalvo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      metodo: metodo ?? this.metodo,
      parametros: parametros ?? this.parametros,
      resultado: resultado ?? this.resultado,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataModificacao: dataModificacao ?? this.dataModificacao,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'metodo': metodo.name,
      'parametros': {
        'comprimento': parametros.comprimento,
        'declividade': parametros.declividade,
        'declividadeTransversal': parametros.declividadeTransversal,
        'larguraOuEspacamento': parametros.larguraOuEspacamento,
        'k': parametros.k,
        'a': parametros.a,
        'vib': parametros.vib,
        'vazao': parametros.vazao,
        'tempoAplicacao': parametros.tempoAplicacao,
        'laminaRequerida': parametros.laminaRequerida,
        'manningN': parametros.manningN,
        'sigmaZ': parametros.sigmaZ,
        'texturaSolo': parametros.texturaSolo.name,
        'tipoSulco': parametros.tipoSulco?.name,
        'tempoAvancoMetadeMin': parametros.tempoAvancoMetadeMin,
        'tempoAvancoFinalMin': parametros.tempoAvancoFinalMin,
        'coeficienteAvancoK': parametros.coeficienteAvancoK,
        'expoenteAvancoB': parametros.expoenteAvancoB,
        'distanciaReferenciaAvancoM': parametros.distanciaReferenciaAvancoM,
        'instanteRecessaoInicioMin': parametros.instanteRecessaoInicioMin,
        'instanteRecessaoFinalMin': parametros.instanteRecessaoFinalMin,
        'tipoInundacao': parametros.tipoInundacao.name,
        'areaHectares': parametros.areaHectares,
        'porosidade': parametros.porosidade,
        'profundidadeCamadaMm': parametros.profundidadeCamadaMm,
        'condutividadeHidraulicaMmDia': parametros.condutividadeHidraulicaMmDia,
        'dtaMmCm': parametros.dtaMmCm,
        'fatorDisponibilidade': parametros.fatorDisponibilidade,
        'evapotranspiracaoMmDia': parametros.evapotranspiracaoMmDia,
        'laminaSuperficialMm': parametros.laminaSuperficialMm,
        'vazaoDisponivelLps': parametros.vazaoDisponivelLps,
        'manejoSulco': parametros.manejoSulco.name,
        'vazaoReduzidaLs': parametros.vazaoReduzidaLs,
        'tempoMudancaMin': parametros.tempoMudancaMin,
        'cicloSurtirMin': parametros.cicloSurtirMin,
        'jornadaDiariaH': parametros.jornadaDiariaH,
        'periodoIrrigacaoDias': parametros.periodoIrrigacaoDias,
        'tempoMudancaParcelaMin': parametros.tempoMudancaParcelaMin,
        'perdasConducaoLs': parametros.perdasConducaoLs,
        'precipitacaoEfetivaMmDia': parametros.precipitacaoEfetivaMmDia,
        'nomeCultura': parametros.nomeCultura,
        'kc': parametros.kc,
        'espacamentoFileirasM': parametros.espacamentoFileirasM,
        'espacamentoPlantasM': parametros.espacamentoPlantasM,
        'larguraSulcoM': parametros.larguraSulcoM,
        'profundidadeSulcoM': parametros.profundidadeSulcoM,
        'metodoCurvaAvanco': parametros.metodoCurvaAvanco.name,
        'usarEnsaioAvanco': parametros.usarEnsaioAvanco,
        'medicoesAvanco': parametros.medicoesAvanco
            .map((point) => point.toMap())
            .toList(),
        'origemCurvaInfiltracao': parametros.origemCurvaInfiltracao.name,
        'distanciaEnsaioInfiltracaoM': parametros.distanciaEnsaioInfiltracaoM,
        'espacamentoEnsaioInfiltracaoM':
            parametros.espacamentoEnsaioInfiltracaoM,
        'medicoesEntradaSaida': parametros.medicoesEntradaSaida
            .map((point) => point.toMap())
            .toList(),
        'hipoteseRecessao': parametros.hipoteseRecessao.name,
        'medicoesRecessao': parametros.medicoesRecessao
            .map((point) => point.toMap())
            .toList(),
      },
      'resultado': SimulationResultModel.toMap(resultado),
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataModificacao': Timestamp.fromDate(dataModificacao),
      'usuarioId': usuarioId,
    };
  }

  factory CenarioSalvo.fromMap(Map<String, dynamic> map, {String? id}) {
    final paramData = map['parametros'] as Map<String, dynamic>;
    return CenarioSalvo(
      id: id ?? map['id'] ?? '',
      nome: map['nome'] ?? '',
      metodo: MetodoIrrigacaoExtension.fromString(map['metodo'] ?? 'sulco'),
      parametros: IrrigationParameters(
        comprimento: (paramData['comprimento'] as num).toDouble(),
        declividade: (paramData['declividade'] as num).toDouble(),
        declividadeTransversal:
            (paramData['declividadeTransversal'] as num?)?.toDouble() ?? 0,
        larguraOuEspacamento: (paramData['larguraOuEspacamento'] as num)
            .toDouble(),
        k: (paramData['k'] as num).toDouble(),
        a: (paramData['a'] as num).toDouble(),
        vib: (paramData['vib'] as num).toDouble(),
        vazao: (paramData['vazao'] as num).toDouble(),
        tempoAplicacao: (paramData['tempoAplicacao'] as num).toDouble(),
        laminaRequerida: (paramData['laminaRequerida'] as num).toDouble(),
        manningN: (paramData['manningN'] as num?)?.toDouble() ?? 0.015,
        sigmaZ: (paramData['sigmaZ'] as num?)?.toDouble() ?? 0.4,
        texturaSolo: TexturaSoloExtension.fromString(
          paramData['texturaSolo'] as String?,
        ),
        tipoSulco: TipoSulco.values
            .where((tipo) => tipo.name == paramData['tipoSulco'])
            .firstOrNull,
        tempoAvancoMetadeMin:
            (paramData['tempoAvancoMetadeMin'] as num?)?.toDouble() ?? 20,
        tempoAvancoFinalMin:
            (paramData['tempoAvancoFinalMin'] as num?)?.toDouble() ?? 60,
        coeficienteAvancoK: (paramData['coeficienteAvancoK'] as num?)
            ?.toDouble(),
        expoenteAvancoB: (paramData['expoenteAvancoB'] as num?)?.toDouble(),
        distanciaReferenciaAvancoM:
            (paramData['distanciaReferenciaAvancoM'] as num?)?.toDouble(),
        instanteRecessaoInicioMin:
            (paramData['instanteRecessaoInicioMin'] as num?)?.toDouble() ?? 125,
        instanteRecessaoFinalMin:
            (paramData['instanteRecessaoFinalMin'] as num?)?.toDouble() ?? 180,
        tipoInundacao: TipoInundacaoExtension.fromString(
          paramData['tipoInundacao'] as String?,
        ),
        areaHectares: (paramData['areaHectares'] as num?)?.toDouble() ?? 2,
        porosidade: (paramData['porosidade'] as num?)?.toDouble() ?? 0.5,
        profundidadeCamadaMm:
            (paramData['profundidadeCamadaMm'] as num?)?.toDouble() ?? 500,
        condutividadeHidraulicaMmDia:
            (paramData['condutividadeHidraulicaMmDia'] as num?)?.toDouble() ??
            7,
        dtaMmCm: (paramData['dtaMmCm'] as num?)?.toDouble() ?? 2,
        fatorDisponibilidade:
            (paramData['fatorDisponibilidade'] as num?)?.toDouble() ?? 0.5,
        evapotranspiracaoMmDia:
            (paramData['evapotranspiracaoMmDia'] as num?)?.toDouble() ?? 7.2,
        laminaSuperficialMm:
            (paramData['laminaSuperficialMm'] as num?)?.toDouble() ?? 150,
        vazaoDisponivelLps:
            (paramData['vazaoDisponivelLps'] as num?)?.toDouble() ?? 36,
        manejoSulco: ManejoSulco.values.firstWhere(
          (manejo) => manejo.name == paramData['manejoSulco'],
          orElse: () => ManejoSulco.constante,
        ),
        vazaoReduzidaLs:
            (paramData['vazaoReduzidaLs'] as num?)?.toDouble() ?? 0,
        tempoMudancaMin:
            (paramData['tempoMudancaMin'] as num?)?.toDouble() ?? 0,
        cicloSurtirMin: (paramData['cicloSurtirMin'] as num?)?.toDouble() ?? 0,
        jornadaDiariaH: (paramData['jornadaDiariaH'] as num?)?.toDouble() ?? 24,
        periodoIrrigacaoDias:
            (paramData['periodoIrrigacaoDias'] as num?)?.toInt() ?? 10,
        tempoMudancaParcelaMin:
            (paramData['tempoMudancaParcelaMin'] as num?)?.toDouble() ?? 30,
        perdasConducaoLs:
            (paramData['perdasConducaoLs'] as num?)?.toDouble() ?? 0,
        precipitacaoEfetivaMmDia:
            (paramData['precipitacaoEfetivaMmDia'] as num?)?.toDouble() ?? 0,
        nomeCultura: paramData['nomeCultura'] as String? ?? '',
        kc: (paramData['kc'] as num?)?.toDouble() ?? 1,
        espacamentoFileirasM:
            (paramData['espacamentoFileirasM'] as num?)?.toDouble() ?? 0.9,
        espacamentoPlantasM:
            (paramData['espacamentoPlantasM'] as num?)?.toDouble() ?? 0.15,
        larguraSulcoM: (paramData['larguraSulcoM'] as num?)?.toDouble(),
        profundidadeSulcoM: (paramData['profundidadeSulcoM'] as num?)
            ?.toDouble(),
        metodoCurvaAvanco: MetodoCurvaAvanco.values.firstWhere(
          (value) => value.name == paramData['metodoCurvaAvanco'],
          orElse: () => MetodoCurvaAvanco.doisPontos,
        ),
        usarEnsaioAvanco: paramData['usarEnsaioAvanco'] as bool? ?? false,
        medicoesAvanco:
            (paramData['medicoesAvanco'] as List<dynamic>?)
                ?.map(
                  (point) => MedicaoAvanco.fromMap(
                    Map<String, dynamic>.from(point as Map),
                  ),
                )
                .toList() ??
            const [],
        origemCurvaInfiltracao: OrigemCurvaInfiltracao.values.firstWhere(
          (value) => value.name == paramData['origemCurvaInfiltracao'],
          orElse: () => OrigemCurvaInfiltracao.equacaoAcumuladaInformada,
        ),
        distanciaEnsaioInfiltracaoM:
            (paramData['distanciaEnsaioInfiltracaoM'] as num?)?.toDouble() ?? 0,
        espacamentoEnsaioInfiltracaoM:
            (paramData['espacamentoEnsaioInfiltracaoM'] as num?)?.toDouble() ??
            0,
        medicoesEntradaSaida:
            (paramData['medicoesEntradaSaida'] as List<dynamic>?)
                ?.map(
                  (point) => MedicaoEntradaSaida.fromMap(
                    Map<String, dynamic>.from(point as Map),
                  ),
                )
                .toList() ??
            const [],
        hipoteseRecessao: HipoteseRecessao.values.firstWhere(
          (value) => value.name == paramData['hipoteseRecessao'],
          orElse: () => HipoteseRecessao.desprezada,
        ),
        medicoesRecessao:
            (paramData['medicoesRecessao'] as List<dynamic>?)
                ?.map(
                  (point) => MedicaoRecessao.fromMap(
                    Map<String, dynamic>.from(point as Map),
                  ),
                )
                .toList() ??
            const [],
      ),
      resultado: SimulationResultModel.fromMap(
        map['resultado'] as Map<String, dynamic>,
      ),
      dataCriacao: map['dataCriacao'] is Timestamp
          ? (map['dataCriacao'] as Timestamp).toDate()
          : DateTime.now(),
      dataModificacao: map['dataModificacao'] is Timestamp
          ? (map['dataModificacao'] as Timestamp).toDate()
          : DateTime.now(),
      usuarioId: map['usuarioId'],
    );
  }

  factory CenarioSalvo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CenarioSalvo.fromMap(data, id: doc.id);
  }
}
