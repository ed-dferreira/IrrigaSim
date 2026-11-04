enum TamanhoFonte {
  pequeno('Pequeno', 0.9),
  medio('Médio', 1.0),
  grande('Grande', 1.15),
  muitoGrande('Muito grande', 1.3);

  final String label;
  final double scale;

  const TamanhoFonte(this.label, this.scale);

  static const TamanhoFonte padrao = TamanhoFonte.medio;
}
