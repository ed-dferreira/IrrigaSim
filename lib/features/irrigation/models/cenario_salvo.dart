import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';

import 'simulation_result_model.dart';

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
        'tempoAvancoMetadeMin': parametros.tempoAvancoMetadeMin,
        'tempoAvancoFinalMin': parametros.tempoAvancoFinalMin,
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
        tempoAvancoMetadeMin:
            (paramData['tempoAvancoMetadeMin'] as num?)?.toDouble() ?? 20,
        tempoAvancoFinalMin:
            (paramData['tempoAvancoFinalMin'] as num?)?.toDouble() ?? 60,
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
