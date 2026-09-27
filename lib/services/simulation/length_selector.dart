import 'package:irrigasim/services/simulation/advance_curve_model.dart';
import 'package:irrigasim/services/simulation/infiltration_model.dart';
import 'package:irrigasim/services/simulation/flow_management.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';

/// Resultado da avaliação de um comprimento.
class AvaliacaoComprimento {
  final double comprimentoM;
  final bool aprovado;
  final String motivo;
  final double? tempoAvancoFinalMin;
  final double? eficienciaEstimada;

  const AvaliacaoComprimento({
    required this.comprimentoM,
    required this.aprovado,
    required this.motivo,
    this.tempoAvancoFinalMin,
    this.eficienciaEstimada,
  });
}

/// Resultado da seleção do comprimento.
class SelecaoComprimentoResultado {
  final double? comprimentoEscolhidoM;
  final List<AvaliacaoComprimento> avaliacoes;

  const SelecaoComprimentoResultado({
    required this.comprimentoEscolhidoM,
    required this.avaliacoes,
  });
}

/// Seleciona o maior comprimento viável para o sulco.
///
/// Não escolhe o maior comprimento cegamente. Avalia sequencialmente:
/// comprimento, declividade, erosão, tempo de avanço, uniformidade,
/// eficiência e operação.
class LengthSelector {
  const LengthSelector._();

  /// Seleciona o maior comprimento viável.
  ///
  /// [comprimentosCandidatos] — Lista de comprimentos a avaliar (m)
  /// [parametrosAvanco] — Parâmetros da curva de avanço
  /// [parametrosInfiltracao] — Parâmetros de infiltração
  /// [vazaoLs] — Vazão por sulco (L/s)
  /// [espacamentoM] — Espaçamento entre sulcos (m)
  /// [declividadePercent] — Declividade (%)
  /// [eficienciaMinima] — Eficiência mínima aceitável (%, padrão 60)
  /// [comprimentoMaximo] — Comprimento máximo do terreno (m)
  static SelecaoComprimentoResultado selecionar({
    required List<double> comprimentosCandidatos,
    required AdvanceCurveResult parametrosAvanco,
    required InfiltrationParameters parametrosInfiltracao,
    required double vazaoLs,
    required double espacamentoM,
    required double declividadePercent,
    required double tempoAplicacaoMin,
    double eficienciaMinima = 60,
    double? comprimentoMaximo,
    TexturaSolo textura = TexturaSolo.media,
  }) {
    if (comprimentosCandidatos.isEmpty ||
        vazaoLs < 0 ||
        espacamentoM <= 0 ||
        declividadePercent <= 0 ||
        tempoAplicacaoMin < 0 ||
        eficienciaMinima < 0) {
      throw ArgumentError('Entradas de seleção de comprimento inválidas');
    }
    final ordenados = List<double>.from(comprimentosCandidatos)..sort();
    final avaliacoes = <AvaliacaoComprimento>[];
    double? comprimentoAprovado;

    for (final comp in ordenados) {
      if (comp <= 0) {
        avaliacoes.add(
          AvaliacaoComprimento(
            comprimentoM: comp,
            aprovado: false,
            motivo: 'Comprimento deve ser positivo',
          ),
        );
        continue;
      }
      final qmax = FlowManagement.calcularVazaoMaxima(
        declividadePercent: declividadePercent,
        textura: textura,
      ).qmaxLs;
      if (vazaoLs > qmax) {
        avaliacoes.add(
          AvaliacaoComprimento(
            comprimentoM: comp,
            aprovado: false,
            motivo:
                'Vazão erosiva (${vazaoLs.toStringAsFixed(2)} > ${qmax.toStringAsFixed(2)} L/s)',
          ),
        );
        continue;
      }
      // Verificar se excede o comprimento máximo do terreno
      if (comprimentoMaximo != null && comp > comprimentoMaximo) {
        avaliacoes.add(
          AvaliacaoComprimento(
            comprimentoM: comp,
            aprovado: false,
            motivo:
                'Excede o comprimento máximo do terreno ($comprimentoMaximo m)',
          ),
        );
        continue;
      }

      // Calcular tempo de avanço no final do sulco
      final tempoAvanco = AdvanceCurveModel.tempoAvanco(
        distanciaM: comp,
        parametros: parametrosAvanco,
      );

      if (tempoAvanco <= 0) {
        avaliacoes.add(
          AvaliacaoComprimento(
            comprimentoM: comp,
            aprovado: false,
            motivo:
                'Tempo de avanço inválido (${tempoAvanco.toStringAsFixed(2)} min)',
          ),
        );
        continue;
      }

      // Verificar eficiência estimada
      final eficienciaEst = _estimarEficiencia(
        comprimentoM: comp,
        tempoAvancoMin: tempoAvanco,
        tempoAplicacaoMin: tempoAplicacaoMin,
        vazaoLs: vazaoLs,
        espacamentoM: espacamentoM,
        parametrosInfiltracao: parametrosInfiltracao,
      );

      // Critérios de rejeição
      if (eficienciaEst < eficienciaMinima) {
        avaliacoes.add(
          AvaliacaoComprimento(
            comprimentoM: comp,
            aprovado: false,
            motivo:
                'Eficiência estimada (${eficienciaEst.toStringAsFixed(1)}%) '
                'abaixo do mínimo ($eficienciaMinima%)',
            tempoAvancoFinalMin: tempoAvanco,
            eficienciaEstimada: eficienciaEst,
          ),
        );
        continue;
      }

      // Aprovar — mantém o maior comprimento viável
      comprimentoAprovado = comp;
      avaliacoes.add(
        AvaliacaoComprimento(
          comprimentoM: comp,
          aprovado: true,
          motivo:
              'Aprovado: tempo avanço=${tempoAvanco.toStringAsFixed(1)} min, '
              'eficiência≈${eficienciaEst.toStringAsFixed(1)}%',
          tempoAvancoFinalMin: tempoAvanco,
          eficienciaEstimada: eficienciaEst,
        ),
      );
    }

    return SelecaoComprimentoResultado(
      comprimentoEscolhidoM: comprimentoAprovado,
      avaliacoes: avaliacoes,
    );
  }

  /// Estima a eficiência para um comprimento dado.
  static double _estimarEficiencia({
    required double comprimentoM,
    required double tempoAvancoMin,
    required double tempoAplicacaoMin,
    required double vazaoLs,
    required double espacamentoM,
    required InfiltrationParameters parametrosInfiltracao,
  }) {
    final tempoTotal = tempoAvancoMin + tempoAplicacaoMin;

    // Lâmina aplicada (mm)
    final laminaAplicada =
        (vazaoLs * tempoTotal * 60) / (comprimentoM * espacamentoM) * 1000;

    // Lâmina média infiltrada estimada (ponto médio)
    final tempoMedioOportunidade = tempoAplicacaoMin / 2;
    final laminaMinima = InfiltrationModel.infiltracaoAcumulada(
      tempoMin: tempoMedioOportunidade,
      parametros: parametrosInfiltracao,
    );
    final laminaMaxima = InfiltrationModel.infiltracaoAcumulada(
      tempoMin: tempoTotal,
      parametros: parametrosInfiltracao,
    );
    final laminaMedia = (laminaMinima + laminaMaxima) / 2;

    if (laminaAplicada <= 0) return 0;

    // Eficiência = lâmina útil / lâmina aplicada
    final eficiencia = (laminaMedia / laminaAplicada) * 100;
    return eficiencia.clamp(0, 100);
  }

  /// Gera comprimentos candidatos automaticamente.
  ///
  /// Cria pontos entre [comprimentoMinimo] e [comprimentoMaximo]
  /// com intervalos regulares.
  static List<double> gerarCandidatos({
    required double comprimentoMaximo,
    double comprimentoMinimo = 50,
    double intervalo = 50,
  }) {
    final candidatos = <double>[];
    for (var c = comprimentoMinimo; c <= comprimentoMaximo; c += intervalo) {
      candidatos.add(c);
    }
    if (!candidatos.contains(comprimentoMaximo)) {
      candidatos.add(comprimentoMaximo);
    }
    return candidatos;
  }
}
