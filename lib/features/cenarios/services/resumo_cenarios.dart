import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

import '../models/cenario_salvo.dart';

/// Resumo dos cenários salvos usado pelo Perfil.
class ResumoCenarios {
  final int total;
  final MetodoIrrigacao? metodoMaisUsado;

  const ResumoCenarios({required this.total, this.metodoMaisUsado});
}

/// Conta os cenários e elege o método mais usado.
///
/// Em caso de empate, vence o método do cenário modificado mais recentemente;
/// se as datas também empatarem, vale a ordem de [MetodoIrrigacao].
ResumoCenarios resumirCenarios(List<CenarioSalvo> cenarios) {
  if (cenarios.isEmpty) {
    return const ResumoCenarios(total: 0);
  }

  final quantidades = <MetodoIrrigacao, int>{};
  final ultimaModificacao = <MetodoIrrigacao, DateTime>{};

  for (final cenario in cenarios) {
    quantidades.update(
      cenario.metodo,
      (quantidade) => quantidade + 1,
      ifAbsent: () => 1,
    );
    final dataAtual = ultimaModificacao[cenario.metodo];
    if (dataAtual == null || cenario.dataModificacao.isAfter(dataAtual)) {
      ultimaModificacao[cenario.metodo] = cenario.dataModificacao;
    }
  }

  MetodoIrrigacao? favorito;
  var maiorQuantidade = 0;
  for (final metodo in MetodoIrrigacao.values) {
    final quantidade = quantidades[metodo] ?? 0;
    if (quantidade == 0) continue;
    if (quantidade > maiorQuantidade) {
      maiorQuantidade = quantidade;
      favorito = metodo;
      continue;
    }
    if (quantidade == maiorQuantidade && favorito != null) {
      final dataMetodo = ultimaModificacao[metodo]!;
      final dataFavorito = ultimaModificacao[favorito]!;
      if (dataMetodo.isAfter(dataFavorito)) {
        favorito = metodo;
      }
    }
  }

  return ResumoCenarios(total: cenarios.length, metodoMaisUsado: favorito);
}

extension MetodoCenarioNome on MetodoIrrigacao {
  String get nomeNoPerfil => switch (this) {
    MetodoIrrigacao.sulco => 'Sulcos',
    MetodoIrrigacao.faixa => 'Faixas',
    MetodoIrrigacao.inundacao => 'Inundação',
  };
}
