/// Formatação numérica compartilhada das telas de irrigação.
library;

/// Formata [valor] com [casas] decimais; `null` vira [vazio].
///
/// Com [removerZerosFinais], zeros à direita e o separador solitário somem
/// ('2,50' → '2,5'; '2,00' → '2'); útil para grandezas de precisão variável.
String formatarNumero(
  double? valor, {
  int casas = 2,
  bool removerZerosFinais = false,
  String vazio = '—',
}) {
  if (valor == null) return vazio;
  var texto = valor.toStringAsFixed(casas);
  if (removerZerosFinais && texto.contains('.')) {
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    texto = texto.replaceFirst(RegExp(r'\.$'), '');
  }
  return texto;
}

/// Formata [valor] seguido da [unidade]; `null` fica só com [vazio].
String formatarNumeroComUnidade(
  double? valor,
  String unidade, {
  int casas = 2,
  String vazio = '—',
}) => valor == null ? vazio : '${formatarNumero(valor, casas: casas)} $unidade';
