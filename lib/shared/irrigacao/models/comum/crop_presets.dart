// Predefinições de cultura compartilhadas pelos projetos de irrigação
// superficial (migradas de lib/views/irrigation/faixas/border_project_screen.dart
// para reuso no wizard de inundação, conforme o plano de cultura/clima).
class CropPreset {
  const CropPreset(
    this.name,
    this.kc,
    this.rows,
    this.plants,
    this.roots,
    this.fraction,
  );

  final String name;
  final double kc, rows, plants, roots, fraction;
}

const cropPresets = <CropPreset>[
  CropPreset('Soja', 1.15, .45, .07, 60, .50),
  CropPreset('Arroz irrigado', 1.20, .17, .03, 20, .20),
  CropPreset('Milho', 1.20, .80, .20, 100, .55),
  CropPreset('Trigo', 1.15, .17, .02, 100, .55),
  CropPreset('Fumo', 1.10, 1.10, .50, 60, .30),
  CropPreset('Feijão', 1.15, .45, .07, 50, .45),
  CropPreset('Cevada', 1.15, .17, .02, 100, .55),
  CropPreset('Aveia', 1.15, .17, .02, 100, .55),
  CropPreset('Mandioca', .80, 1.00, .60, 80, .35),
  CropPreset('Cana-de-açúcar', 1.25, 1.40, .50, 120, .65),
  CropPreset('Uva', .70, 2.50, 1.20, 100, .35),
  CropPreset('Batata', 1.15, .80, .30, 40, .35),
  CropPreset('Cebola', 1.05, .30, .10, 30, .30),
  CropPreset('Canola', 1.15, .35, .04, 100, .60),
  CropPreset('Sorgo', 1.00, .50, .05, 100, .55),
  CropPreset('Tomate', 1.15, 1.00, .50, 70, .40),
  CropPreset('Melancia', 1.00, 2.00, 1.00, 80, .40),
  CropPreset('Amendoim', 1.15, .50, .10, 50, .50),
  CropPreset('Triticale', 1.15, .17, .02, 100, .55),
  CropPreset('Azevém (forragem)', 1.05, .17, .02, 40, .60),
];

/// Predefinição que corresponde ao projeto quando nome, Kc, espaçamentos,
/// raízes e fração ainda coincidem com os valores do preset.
CropPreset? selectedCropPreset({
  required String? cultura,
  required double? kc,
  required double? rows,
  required double? plants,
  required double? roots,
  required double? fraction,
}) {
  for (final preset in cropPresets) {
    if (preset.name == cultura &&
        preset.kc == kc &&
        preset.rows == rows &&
        preset.plants == plants &&
        preset.roots == roots &&
        preset.fraction == fraction) {
      return preset;
    }
  }
  return null;
}
