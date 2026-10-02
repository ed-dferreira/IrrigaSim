import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

class MarrSuggestion {
  final TexturaSolo textura;
  final double decliveMinPercent, decliveMaxPercent;
  final String vazaoLsM, laminaMm, larguraM, comprimentoM;
  const MarrSuggestion(
    this.textura,
    this.decliveMinPercent,
    this.decliveMaxPercent,
    this.vazaoLsM,
    this.laminaMm,
    this.larguraM,
    this.comprimentoM,
  );

  /// Tabela de sugestões: orientativa, nunca coeficiente de infiltração.
  BorderStatus get status => BorderStatus.avisoOrientativo;
}

class BooherCell {
  final double diametroCm, cargaCm, impressoLs;
  final double? propostoLs;
  const BooherCell(
    this.diametroCm,
    this.cargaCm,
    this.impressoLs, [
    this.propostoLs,
  ]);
  bool get revisaoPendente => propostoLs != null;

  /// Célula sob revisão é `dado_fonte_suspeito`; as demais são orientativas.
  BorderStatus get status => revisaoPendente
      ? BorderStatus.dadoFonteSuspeito
      : BorderStatus.avisoOrientativo;
  static const pagina = 26;
}

class BorderReferenceTables {
  const BorderReferenceTables();
  static const marr = <MarrSuggestion>[
    MarrSuggestion(
      TexturaSolo.muitoFina,
      .15,
      .6,
      '3–4',
      '100–150',
      '5–18',
      '150–300',
    ),
    MarrSuggestion(
      TexturaSolo.muitoFina,
      .6,
      1.5,
      '2–3',
      '100–150',
      '5–6',
      '150–400',
    ),
    MarrSuggestion(
      TexturaSolo.muitoFina,
      1.5,
      4,
      '1–2',
      '100–150',
      '5–6',
      '200',
    ),
    MarrSuggestion(
      TexturaSolo.fina,
      .15,
      .6,
      '6–8',
      '50–100',
      '5–18',
      '90–180',
    ),
    MarrSuggestion(
      TexturaSolo.fina,
      .6,
      1.5,
      '4–6',
      '50–100',
      '5–6',
      '100–200',
    ),
    MarrSuggestion(TexturaSolo.fina, 1.5, 4, '2–4', '50–100', '5–6', '100'),
    MarrSuggestion(TexturaSolo.media, 1, 4, '1–4', '25–75', '5–6', '100–300'),
  ];
  List<MarrSuggestion> suggest(TexturaSolo textura, double declivePercent) =>
      marr
          .where(
            (row) =>
                row.textura == textura &&
                declivePercent >= row.decliveMinPercent &&
                declivePercent <= row.decliveMaxPercent,
          )
          .toList();

  static const cargasCm = [5.0, 7.5, 10.0, 12.5, 15.0, 20.0, 25.0];
  static const diametrosCm = [10.0, 12.5, 15.0, 20.0, 25.0, 30.0, 35.0];
  static const valoresLs = <List<double>>[
    [4.7, 5.7, 6.6, 7.4, 8.1, 9.3, 10.4],
    [7.3, 8.9, 1.03, 11.5, 12.6, 14.6, 16.3],
    [10.5, 12.9, 14.9, 16.6, 18.2, 21.0, 23.5],
    [18.7, 22.9, 26.4, 29.5, 32.3, 37.3, 41.8],
    [29.2, 35.7, 41.3, 46.1, 505.5, 58.4, 65.2],
    [42.0, 51.5, 59.4, 66.4, 72.8, 84.0, 94.0],
    [57.2, 70.0, 80.9, 90.4, 993.1, 114.4, 127.9],
  ];
  BooherCell? booher(double diametroCm, double cargaCm) {
    final row = diametrosCm.indexOf(diametroCm),
        col = cargasCm.indexOf(cargaCm);
    if (row < 0 || col < 0) return null;
    final proposed = switch ((row, col)) {
      (1, 2) => 10.3,
      (4, 4) => 50.5,
      (6, 4) => 99.1,
      _ => null,
    };
    return BooherCell(diametroCm, cargaCm, valoresLs[row][col], proposed);
  }

  /// Célula elegível para sugestão automática; valores sob revisão
  /// (1,03/505,5/993,1 L/s) retornam null e nunca viram recomendação.
  BooherCell? sugestao(double diametroCm, double cargaCm) {
    final cell = booher(diametroCm, cargaCm);
    if (cell == null || cell.status == BorderStatus.dadoFonteSuspeito) {
      return null;
    }
    return cell;
  }
}
