/// Consulta literal da tabela de Booher (Aula 6, p.9). Células vazias
/// permanecem ausentes; não há interpolação nem extrapolação.
enum RaizCorrugado { profunda, rasa }

enum TexturaCorrugado { fina, media, grossa }

class DimensaoCorrugado {
  const DimensaoCorrugado(this.comprimentoM, this.espacamentoM);
  final double comprimentoM;
  final double espacamentoM;
}

class TabelaCorrugados {
  const TabelaCorrugados._();

  static const _dados = <RaizCorrugado, Map<int, List<DimensaoCorrugado?>>>{
    RaizCorrugado.profunda: {
      2: [
        DimensaoCorrugado(180, .75),
        DimensaoCorrugado(130, .70),
        DimensaoCorrugado(70, .60),
      ],
      4: [
        DimensaoCorrugado(120, .65),
        DimensaoCorrugado(90, .65),
        DimensaoCorrugado(45, .55),
      ],
      6: [
        DimensaoCorrugado(90, .60),
        DimensaoCorrugado(75, .60),
        DimensaoCorrugado(40, .50),
      ],
      8: [
        DimensaoCorrugado(80, .55),
        DimensaoCorrugado(60, .55),
        DimensaoCorrugado(30, .45),
      ],
      10: [DimensaoCorrugado(70, .50), DimensaoCorrugado(50, .50), null],
      12: [DimensaoCorrugado(60, .45), DimensaoCorrugado(40, .45), null],
    },
    RaizCorrugado.rasa: {
      2: [
        DimensaoCorrugado(120, .65),
        DimensaoCorrugado(90, .55),
        DimensaoCorrugado(45, .45),
      ],
      4: [
        DimensaoCorrugado(85, .60),
        DimensaoCorrugado(60, .50),
        DimensaoCorrugado(30, .45),
      ],
      6: [DimensaoCorrugado(70, .55), DimensaoCorrugado(50, .45), null],
      8: [DimensaoCorrugado(60, .50), DimensaoCorrugado(45, .45), null],
      10: [DimensaoCorrugado(55, .45), DimensaoCorrugado(40, .40), null],
      12: [DimensaoCorrugado(50, .40), DimensaoCorrugado(35, .40), null],
    },
  };

  static DimensaoCorrugado? consultar({
    required RaizCorrugado raiz,
    required int declivePercent,
    required TexturaCorrugado textura,
  }) => _dados[raiz]?[declivePercent]?[textura.index];
}
