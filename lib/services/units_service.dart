/// Conversões e validação de unidades centralizadas.
///
/// Toda conversão passa por aqui para evitar silos de unidades espalhados.
class UnitsService {
  const UnitsService._();

  static const double _horasPorMinuto = 60;
  static const double _cmPorMetro = 100;
  static const double _porcentoPorDecimal = 100;
  static const double _litrosPorM3 = 1000;

  // ── Conversões ──────────────────────────────────────────────────────────

  /// Converte minutos para horas.
  static double minToH(double min) => min / _horasPorMinuto;

  /// Converte horas para minutos.
  static double hToMin(double h) => h * _horasPorMinuto;

  /// Converte centímetros para metros.
  static double cmToM(double cm) => cm / _cmPorMetro;

  /// Converte metros para centímetros.
  static double mToCm(double m) => m * _cmPorMetro;

  /// Converte porcentagem para decimal.
  static double percentToDecimal(double pct) => pct / _porcentoPorDecimal;

  /// Converte decimal para porcentagem.
  static double decimalToPercent(double dec) => dec * _porcentoPorDecimal;

  /// Converte L/s para mm/h em uma área dada (m²).
  ///
  /// Fórmula: `VI(mm/h) = Qinfiltrada(L/s) * (3600 / area_m2)`
  static double lpsToMmH(double lps, double areaM2) {
    if (areaM2 <= 0) throw ArgumentError('Área deve ser maior que zero');
    return lps * 3600 / areaM2;
  }

  /// Converte mm/h para L/s em uma área dada (m²).
  static double mmHToLps(double mmH, double areaM2) {
    if (areaM2 <= 0) throw ArgumentError('Área deve ser maior que zero');
    return mmH * areaM2 / 3600;
  }

  /// Converte m³ para litros.
  static double m3ToLitros(double m3) => m3 * _litrosPorM3;

  /// Converte litros para m³.
  static double litrosToM3(double litros) => litros / _litrosPorM3;

  // ── Validações ──────────────────────────────────────────────────────────

  /// Valida se um valor numérico não é negativo.
  static ValidationResult validarNaoNegativo(
    double valor,
    String nomeCampo,
  ) {
    if (valor < 0) {
      return ValidationResult.invalida(
        '$nomeCampo não pode ser negativo (recebido: $valor)',
      );
    }
    return ValidationResult.valida();
  }

  /// Valida se um valor é positivo (maior que zero).
  static ValidationResult validarPositivo(
    double valor,
    String nomeCampo,
  ) {
    if (valor <= 0) {
      return ValidationResult.invalida(
        '$nomeCampo deve ser maior que zero (recebido: $valor)',
      );
    }
    return ValidationResult.valida();
  }

  /// Valida se um valor está dentro de uma faixa [min, max].
  static ValidationResult validarFaixa(
    double valor,
    double min,
    double max,
    String nomeCampo,
  ) {
    if (valor < min || valor > max) {
      return ValidationResult.invalida(
        '$nomeCampo deve estar entre $min e $max (recebido: $valor)',
      );
    }
    return ValidationResult.valida();
  }

  /// Valida a densidade do solo (faixa típica: 1.0 a 2.0 g/cm³).
  static ValidationResult validarDensidade(double densidadeGcm3) {
    return validarFaixa(densidadeGcm3, 1.0, 2.0, 'Densidade do solo');
  }

  /// Valida porcentagem (0 a 100).
  static ValidationResult validarPorcentagem(
    double valor,
    String nomeCampo,
  ) {
    return validarFaixa(valor, 0, 100, nomeCampo);
  }

  /// Valida se dois valores de vazão usam unidades compatíveis.
  static ValidationResult validarVazoesCompativeis(
    double q1,
    String unidade1,
    double q2,
    String unidade2,
  ) {
    if (unidade1 != unidade2) {
      return ValidationResult.invalida(
        'Vazões em unidades incompatíveis: $unidade1 vs $unidade2',
      );
    }
    return ValidationResult.valida();
  }

  /// Valida que a vazão de saída não é maior que a de entrada.
  static ValidationResult validarVazaoSaida(
    double qEntrada,
    double qSaida,
  ) {
    if (qSaida > qEntrada) {
      return ValidationResult.aviso(
        'Vazão de saída ($qSaida) é maior que a de entrada ($qEntrada). '
        'Verifique os dados do ensaio.',
      );
    }
    return ValidationResult.valida();
  }
}

/// Resultado de uma validação.
class ValidationResult {
  final bool isValida;
  final String? mensagem;
  final TipoValidacao tipo;

  const ValidationResult._({
    required this.isValida,
    this.mensagem,
    required this.tipo,
  });

  factory ValidationResult.valida() =>
      const ValidationResult._(isValida: true, tipo: TipoValidacao.ok);

  factory ValidationResult.invalida(String mensagem) =>
      ValidationResult._(
        isValida: false,
        mensagem: mensagem,
        tipo: TipoValidacao.erro,
      );

  factory ValidationResult.aviso(String mensagem) =>
      ValidationResult._(
        isValida: true,
        mensagem: mensagem,
        tipo: TipoValidacao.aviso,
      );
}

enum TipoValidacao { ok, aviso, erro }

/// Conjunto de validações agrupadas.
class ValidacaoEntradas {
  final List<ValidationResult> _resultados = [];

  List<ValidationResult> get resultados => List.unmodifiable(_resultados);

  bool get tudoValido =>
      _resultados.every((r) => r.tipo != TipoValidacao.erro);

  List<String> get erros => _resultados
      .where((r) => r.tipo == TipoValidacao.erro)
      .map((r) => r.mensagem!)
      .toList();

  List<String> get avisos => _resultados
      .where((r) => r.tipo == TipoValidacao.aviso)
      .map((r) => r.mensagem!)
      .toList();

  void adicionar(ValidationResult resultado) {
    _resultados.add(resultado);
  }

  void validar(ValidationResult Function() validacao) {
    _resultados.add(validacao());
  }
}
