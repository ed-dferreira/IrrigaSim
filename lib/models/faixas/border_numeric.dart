/// Grupo numérico declarado (extração §10.1, grupo "Numérico"): tolerâncias de
/// passo e resíduo, teto de iterações, segmentação do perfil, versão dos
/// expoentes de recessão (p.43) e método de integração. Persistido como mapa
/// próprio no projeto, no CSV e no cenário salvo; registros antigos (versões
/// 0 e 1) leem os defaults explícitos abaixo sem reescrever valores salvos.
class BorderNumericConfig {
  static const nSegmentosPadrao = 2000;
  static const toleranciaPassoPadrao = 1e-10;
  static const toleranciaResiduoPadrao = 1e-12;
  static const maxIteracoesPadrao = 250;

  /// Versões conhecidas dos expoentes da recessão; p.63/66 imprimem
  /// arredondamentos e não são misturados dentro de uma execução.
  static const versaoExpoentesPadrao = 'p43';
  static const versoesExpoentes = {'p43'};

  static const metodoIntegracaoPadrao = 'trapezios_cruzamento_irn';
  static const metodosIntegracao = {'trapezios_cruzamento_irn', 'trapezios'};

  static const padrao = BorderNumericConfig();

  final double toleranciaPasso;
  final double toleranciaResiduo;
  final int maxIteracoes;
  final int nSegmentos;
  final String versaoExpoentesRecessao;
  final String metodoIntegracao;

  const BorderNumericConfig({
    this.toleranciaPasso = toleranciaPassoPadrao,
    this.toleranciaResiduo = toleranciaResiduoPadrao,
    this.maxIteracoes = maxIteracoesPadrao,
    this.nSegmentos = nSegmentosPadrao,
    this.versaoExpoentesRecessao = versaoExpoentesPadrao,
    this.metodoIntegracao = metodoIntegracaoPadrao,
  });

  BorderNumericConfig copyWith({
    double? toleranciaPasso,
    double? toleranciaResiduo,
    int? maxIteracoes,
    int? nSegmentos,
    String? versaoExpoentesRecessao,
    String? metodoIntegracao,
  }) => BorderNumericConfig(
    toleranciaPasso: toleranciaPasso ?? this.toleranciaPasso,
    toleranciaResiduo: toleranciaResiduo ?? this.toleranciaResiduo,
    maxIteracoes: maxIteracoes ?? this.maxIteracoes,
    nSegmentos: nSegmentos ?? this.nSegmentos,
    versaoExpoentesRecessao:
        versaoExpoentesRecessao ?? this.versaoExpoentesRecessao,
    metodoIntegracao: metodoIntegracao ?? this.metodoIntegracao,
  );

  /// Versão dos expoentes de recessão efetivamente implementada pelo motor.
  bool get versaoExpoentesImplementada =>
      versoesExpoentes.contains(versaoExpoentesRecessao);

  /// Primeira condição inválida do grupo; null quando o grupo é utilizável.
  String? get impedimento {
    if (!toleranciaPasso.isFinite || toleranciaPasso <= 0) {
      return 'Tolerância de passo deve ser finita e positiva.';
    }
    if (!toleranciaResiduo.isFinite || toleranciaResiduo <= 0) {
      return 'Tolerância de resíduo deve ser finita e positiva.';
    }
    if (maxIteracoes < 1) {
      return 'Teto de iterações deve ser ao menos 1.';
    }
    if (nSegmentos < 2) {
      return 'n_segmentos deve ser pelo menos 2.';
    }
    if (!versaoExpoentesImplementada) {
      return 'Versão de expoentes de recessão não implementada: '
          '$versaoExpoentesRecessao.';
    }
    if (!metodosIntegracao.contains(metodoIntegracao)) {
      return 'Método de integração desconhecido: $metodoIntegracao.';
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    'toleranciaPasso': toleranciaPasso,
    'toleranciaResiduo': toleranciaResiduo,
    'maxIteracoes': maxIteracoes,
    'nSegmentos': nSegmentos,
    'versaoExpoentesRecessao': versaoExpoentesRecessao,
    'metodoIntegracao': metodoIntegracao,
  };

  /// Lê o mapa do grupo (ou o mapa do projeto antigo, que guardava
  /// `nSegmentos` na raiz); chaves ausentes caem nos defaults explícitos.
  factory BorderNumericConfig.fromMap(Map<String, dynamic> map) {
    double? numero(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is! num) {
        throw FormatException('$key deve ser numérico.');
      }
      return value.toDouble();
    }

    int inteiro(String key) {
      final value = map[key];
      if (value == null) return -1;
      if (value is! num || value != value.roundToDouble()) {
        throw FormatException('$key deve ser inteiro.');
      }
      return value.toInt();
    }

    String? texto(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('$key deve ser texto.');
      }
      return value;
    }

    final segmentos = inteiro('nSegmentos');
    final iteracoes = inteiro('maxIteracoes');
    return BorderNumericConfig(
      toleranciaPasso:
          numero('toleranciaPasso') ?? toleranciaPassoPadrao,
      toleranciaResiduo:
          numero('toleranciaResiduo') ?? toleranciaResiduoPadrao,
      maxIteracoes: iteracoes < 0 ? maxIteracoesPadrao : iteracoes,
      nSegmentos: segmentos < 0 ? nSegmentosPadrao : segmentos,
      versaoExpoentesRecessao:
          texto('versaoExpoentesRecessao') ?? versaoExpoentesPadrao,
      metodoIntegracao: texto('metodoIntegracao') ?? metodoIntegracaoPadrao,
    );
  }
}
