// Anexos tipados da simulação de inundação: planejamento em parcelas,
// seleção entre vazões candidatas e volumes de água do arroz. Ficam fora de
// basin_project.dart para que simulation_result.dart possa referenciá-los
// sem ciclo de importações.
import 'package:irrigasim/features/irrigacao_inundacao/services/rice_volumes_service.dart';

/// Planejamento em parcelas da Aula 8 (pp. 61–62), anexado ao resultado.
class BasinParcelasAnexo {
  const BasinParcelasAnexo({
    required this.tppMin,
    required this.npdTeorico,
    required this.npdInteiro,
    required this.appM2,
    required this.larguraTabuleiroM,
    required this.tabuleirosPorParcela,
    required this.ntt,
    required this.qTotalLS,
  });

  final double tppMin;
  final double npdTeorico;
  final int npdInteiro;
  final double appM2;
  final double larguraTabuleiroM;
  final int tabuleirosPorParcela;
  final int ntt;
  final double qTotalLS;

  Map<String, Object?> toMap() => {
    'tpp_min': tppMin,
    'npd_teorico': npdTeorico,
    'npd_inteiro': npdInteiro,
    'app_m2': appM2,
    'largura_tabuleiro_m': larguraTabuleiroM,
    'tabuleiros_por_parcela': tabuleirosPorParcela,
    'ntt': ntt,
    'q_total_l_s': qTotalLS,
  };

  factory BasinParcelasAnexo.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    double numero(String chave) => (map[chave] as num).toDouble();
    return BasinParcelasAnexo(
      tppMin: numero('tpp_min'),
      npdTeorico: numero('npd_teorico'),
      npdInteiro: (map['npd_inteiro'] as num).toInt(),
      appM2: numero('app_m2'),
      larguraTabuleiroM: numero('largura_tabuleiro_m'),
      tabuleirosPorParcela: (map['tabuleiros_por_parcela'] as num).toInt(),
      ntt: (map['ntt'] as num).toInt(),
      qTotalLS: numero('q_total_l_s'),
    );
  }
}

/// Melhor vazão entre candidatas explícitas (p. 60). Não afirma ótimo
/// global: registra o candidato escolhido e o motivo da escolha.
class BasinSelecaoVazaoAnexo {
  const BasinSelecaoVazaoAnexo({
    required this.vazaoEscolhidaLs,
    required this.q0M3MinM,
    required this.eficienciaPercent,
    required this.candidatasAvaliadas,
    required this.candidatasRejeitadas,
  });

  final double vazaoEscolhidaLs;
  final double q0M3MinM;
  final double eficienciaPercent;
  final int candidatasAvaliadas;
  final int candidatasRejeitadas;

  Map<String, Object?> toMap() => {
    'vazao_escolhida_l_s': vazaoEscolhidaLs,
    'q0_m3_min_m': q0M3MinM,
    'eficiencia_percent': eficienciaPercent,
    'candidatas_avaliadas': candidatasAvaliadas,
    'candidatas_rejeitadas': candidatasRejeitadas,
  };

  factory BasinSelecaoVazaoAnexo.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    return BasinSelecaoVazaoAnexo(
      vazaoEscolhidaLs: (map['vazao_escolhida_l_s'] as num).toDouble(),
      q0M3MinM: (map['q0_m3_min_m'] as num).toDouble(),
      eficienciaPercent: (map['eficiencia_percent'] as num).toDouble(),
      candidatasAvaliadas: (map['candidatas_avaliadas'] as num).toInt(),
      candidatasRejeitadas: (map['candidatas_rejeitadas'] as num).toInt(),
    );
  }
}

/// Volumes de água do arroz (Aula 8, pp. 74–84) anexados ao resultado,
/// preservando as lacunas do enunciado (G4): nada que a fonte não informa é
/// presumido, e os campos ausentes seguem declarados em
/// [RiceVolumesResultado.dadosAusentes].
class BasinVolumesAnexo {
  const BasinVolumesAnexo(this.volumes, {this.pagina = 84});

  final RiceVolumesResultado volumes;

  /// Página do enunciado de referência dos volumes.
  final int pagina;

  Map<String, Object?> toMap() => {'pagina': pagina, ...volumes.toMap()};

  factory BasinVolumesAnexo.fromMap(Object? data) {
    final map = Map<String, dynamic>.from(data as Map);
    return BasinVolumesAnexo(
      RiceVolumesResultado.fromMap(map),
      pagina: (map['pagina'] as num?)?.toInt() ?? 84,
    );
  }
}
