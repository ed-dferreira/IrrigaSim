class PreferenciasApp {
  double fontScale;
  bool highContrast;
  bool boldText;
  bool reducedAnimations;
  bool screenReaderMode;

  PreferenciasApp({
    this.fontScale = 1.0,
    this.highContrast = false,
    this.boldText = false,
    this.reducedAnimations = false,
    this.screenReaderMode = false,
  });
}
