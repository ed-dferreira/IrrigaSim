// Enums climáticos compartilhados entre os métodos de irrigação superficial
// (sulcos, faixas e inundação). Foram extraídos de
// lib/models/sulcos/entradas_projeto_sulco.dart mantendo os mesmos nomes de
// valor e a serialização por `.name`, de modo que nenhum dado persistido
// mude de significado (os typedefs de compatibilidade ficam em
// `entradas_projeto_sulco.dart`).

/// Origem da precipitação usada como demanda líquida (ETc − Pef).
///
/// `provavel` registra chuva observada que **não** foi convertida em
/// precipitação efetiva e portanto não entra no balanço.
enum OrigemChuva { naoInformada, efetiva, provavel, observada }

/// Método de estimação da evapotranspiração da cultura (ETc).
enum MetodoEtc { adotada, etoVezesKc, blaneyCriddle }
