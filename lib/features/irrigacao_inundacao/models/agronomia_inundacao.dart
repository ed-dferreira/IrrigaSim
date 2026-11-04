// Agronomia da bacia/tabuleiro de inundação (Fase 6 do plano de cultura e
// clima). Espelha lib/models/faixas/faixa_agronomia.dart: campos imutáveis,
// atualização pontual via withValue e IRN delegado a
// [LaminaRequeridaCalculator] com a mesma convenção de faixas
// (demanda líquida = ETc − Pef, informada pelo projeto).
//
// Diferença de faixas: ETc e Pef vivem no projeto (método ETc e origem da
// chuva), então a chamada é uma função com parâmetros nomeados em vez de um
// getter; a agronomia guarda apenas solo, raízes e cultura.
import 'package:irrigasim/shared/irrigacao/services/lamina_requerida.dart';

class AgronomiaInundacao {
  final String? cultura;
  final double? kc;
  final double? uccPercentual, upmpPercentual, densidadeGcm3;
  final double? profundidadeRaizesCm, fracaoDisponivel;

  const AgronomiaInundacao({
    this.cultura,
    this.kc,
    this.uccPercentual,
    this.upmpPercentual,
    this.densidadeGcm3,
    this.profundidadeRaizesCm,
    this.fracaoDisponivel,
  });

  /// IRN em mm com os dados de solo/raízes desta agronomia e a demanda
  /// climática (ETc e Pef) fornecida pelo projeto. Retorna null quando falta
  /// dado ou quando a demanda não é positiva (G4: nada é fabricado).
  double? irnMm({
    required double etcMmDia,
    required double precipitacaoEfetivaMmDia,
  }) {
    if (!completa) return null;
    try {
      return LaminaRequeridaCalculator.calcular(
        uccPercentual: uccPercentual!,
        upmpPercentual: upmpPercentual!,
        densidadeGcm3: densidadeGcm3!,
        profundidadeRaizesCm: profundidadeRaizesCm!,
        fracaoAguaDisponivel: fracaoDisponivel!,
        demandaLiquidaMmDia: etcMmDia - precipitacaoEfetivaMmDia,
        etcMmDia: etcMmDia,
        precipitacaoEfetivaMmDia: precipitacaoEfetivaMmDia,
      ).irnMm;
    } on ArgumentError {
      return null;
    }
  }

  /// Todos os insumos de solo e raízes necessários à IRN calculada.
  bool get completa =>
      uccPercentual != null &&
      upmpPercentual != null &&
      densidadeGcm3 != null &&
      profundidadeRaizesCm != null &&
      fracaoDisponivel != null;

  AgronomiaInundacao comValor(String campo, double valor) => AgronomiaInundacao(
    cultura: cultura,
    kc: campo == 'kc' ? valor : kc,
    uccPercentual: campo == 'uccPercentual' ? valor : uccPercentual,
    upmpPercentual: campo == 'upmpPercentual' ? valor : upmpPercentual,
    densidadeGcm3: campo == 'densidadeGcm3' ? valor : densidadeGcm3,
    profundidadeRaizesCm: campo == 'profundidadeRaizesCm'
        ? valor
        : profundidadeRaizesCm,
    fracaoDisponivel: campo == 'fracaoDisponivel' ? valor : fracaoDisponivel,
  );

  Map<String, Object?> toMap() => {
    'cultura': cultura,
    'kc': kc,
    'uccPercentual': uccPercentual,
    'upmpPercentual': upmpPercentual,
    'densidadeGcm3': densidadeGcm3,
    'profundidadeRaizesCm': profundidadeRaizesCm,
    'fracaoDisponivel': fracaoDisponivel,
  };

  factory AgronomiaInundacao.fromMap(Object? data) {
    if (data is! Map) return const AgronomiaInundacao();
    final map = Map<String, dynamic>.from(data);
    double? n(String key) => (map[key] as num?)?.toDouble();
    return AgronomiaInundacao(
      cultura: map['cultura'] as String?,
      kc: n('kc'),
      uccPercentual: n('uccPercentual'),
      upmpPercentual: n('upmpPercentual'),
      densidadeGcm3: n('densidadeGcm3'),
      profundidadeRaizesCm: n('profundidadeRaizesCm'),
      fracaoDisponivel: n('fracaoDisponivel'),
    );
  }
}
