import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/shared/cultura/models/crop_presets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';

/// Etapa de cultura e sistema radicular compartilhada pelos projetos de
/// irrigação superficial (sulcos, faixas e inundação).
///
/// Traz o mesmo conteúdo nos três wizards — seletor de predefinição
/// ([cropPresets]), nome da cultura e grade responsiva de campos numéricos —
/// enquanto as diferenças legítimas de cada método ficam nos parâmetros:
///
/// - [mostrarEspacamentos]: métodos sem espaçamento de plantio (ex.: arroz em
///   inundação) ocultam os campos de fileiras/plantas;
/// - [extraFields]: blocos específicos do método, inseridos após a grade
///   (ex.: camadas e turno do regime permanente na inundação);
/// - [footer]: widget final do step (ex.: card da lâmina requerida);
/// - [introducao]: parágrafo opcional acima da grade;
/// - os valores entram por parâmetro e as edições saem por [onCampoAlterado]
///   e [onNomeAlterado], mapeados pelo chamador para o controller de sua
///   feature ([onPresetSelecionado] recebe o preset escolhido intacto).
///
/// A moldura do passo fica por conta de quem usa: os wizards de faixas e
/// inundação já emolduram cada etapa em `IrrigationProjectStepCard` no nível
/// da tela, e o sulcos embrulha em `StepBentoCard` como seus demais passos.
///
/// Os nomes canônicos dos campos emitidos por [onCampoAlterado] são
/// `kc`, `espacamentoFileirasM`, `espacamentoPlantasM`, `profundidadeRaizesCm`
/// e `fracaoDisponivel`; features com nomes distintos (ex.: `fracaoAguaDisponivel`
/// no sulcos) fazem a tradução no chamador.
///
/// [revision] reinicializa os campos quando a predefinição é aplicada
/// programaticamente (o `TextFormField` só relê `initialValue` com chave nova).
/// Pode ser um contador simples ou um objeto com igualdade estrutural
/// (ex.: record com os valores atuais, caso do sulcos).
class CulturaStepForm extends StatelessWidget {
  const CulturaStepForm({
    super.key,
    required this.onPresetSelecionado,
    required this.onCampoAlterado,
    required this.onNomeAlterado,
    this.introducao,
    this.nomeCultura,
    this.presetInicial,
    this.kc,
    this.espacamentoFileirasM,
    this.espacamentoPlantasM,
    this.profundidadeRaizesCm,
    this.fracaoDisponivel,
    this.revision = 0,
    this.mostrarEspacamentos = true,
    this.extraFields = const [],
    this.footer,
  });

  /// Parágrafo opcional acima da grade, com o texto do método.
  final String? introducao;

  final String? nomeCultura;
  final CropPreset? presetInicial;
  final double? kc;
  final double? espacamentoFileirasM;
  final double? espacamentoPlantasM;
  final double? profundidadeRaizesCm;
  final double? fracaoDisponivel;

  /// Rebuild dos campos ao aplicar predefinição (ver doc da classe).
  final Object revision;
  final bool mostrarEspacamentos;
  final List<Widget> extraFields;
  final Widget? footer;

  /// Recebe a predefinição escolhida; o chamador aplica no controller.
  final ValueChanged<CropPreset> onPresetSelecionado;

  /// Campo alterado: nome canônico + texto bruto digitado.
  final void Function(String campo, String texto) onCampoAlterado;
  final ValueChanged<String> onNomeAlterado;

  String? _validarPositivo(String? texto) {
    final n = double.tryParse((texto ?? '').replaceAll(',', '.'));
    if (n == null || !n.isFinite) return 'Informe um número válido';
    if (n <= 0) return 'Use valor positivo';
    return null;
  }

  String? _validarFracao(String? texto) {
    final n = double.tryParse((texto ?? '').replaceAll(',', '.'));
    if (n == null || !n.isFinite) return 'Informe um número válido';
    if (n <= 0) return 'Use valor positivo';
    if (n > 1) return 'Use fração até 1';
    return null;
  }

  Widget _numero(
    String campo,
    String label,
    double? valor, {
    String? unit,
    String? helper,
    String? Function(String?)? validator,
  }) => IrrigationNumberField(
    label: label,
    value: valor,
    unit: unit,
    helper: helper,
    validator: validator,
    fieldKey: ValueKey('$campo-$revision'),
    onChanged: (texto) => onCampoAlterado(campo, texto),
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (introducao != null) ...[
        Text(introducao!),
        const SizedBox(height: 16),
      ],
      IrrigationLabeledField(
        label: 'Predefinição de cultura',
        child: DropdownButtonFormField<CropPreset?>(
          key: ValueKey('cultura-preset-$revision'),
          isExpanded: true,
          initialValue: presetInicial,
          decoration: const InputDecoration(
            helperText:
                'Selecione uma cultura para preencher os parâmetros; eles '
                'podem ser ajustados depois.',
          ),
          items: [
            const DropdownMenuItem<CropPreset?>(
              value: null,
              child: Text(
                'Personalizada / sem predefinição',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ...cropPresets.map(
              (preset) => DropdownMenuItem<CropPreset?>(
                value: preset,
                child: Text(
                  preset.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
          onChanged: (preset) {
            if (preset != null) onPresetSelecionado(preset);
          },
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 650
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          Widget campo(Widget child) =>
              SizedBox(width: fieldWidth, child: child);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              campo(
                IrrigationLabeledField(
                  label: 'Nome da cultura',
                  child: TextFormField(
                    key: ValueKey('cultura-nome-$revision'),
                    initialValue: nomeCultura ?? '',
                    decoration: const InputDecoration(
                      helperText: 'Ex: Milho, Soja, Algodão',
                    ),
                    onChanged: onNomeAlterado,
                  ),
                ),
              ),
              campo(
                _numero(
                  'kc',
                  'Coeficiente da cultura (Kc)',
                  kc,
                  helper: '0 a 1,4',
                  validator: _validarPositivo,
                ),
              ),
              if (mostrarEspacamentos) ...[
                campo(
                  _numero(
                    'espacamentoFileirasM',
                    'Espaçamento entre fileiras',
                    espacamentoFileirasM,
                    unit: 'm',
                    validator: _validarPositivo,
                  ),
                ),
                campo(
                  _numero(
                    'espacamentoPlantasM',
                    'Espaçamento entre plantas',
                    espacamentoPlantasM,
                    unit: 'm',
                    validator: _validarPositivo,
                  ),
                ),
              ],
              campo(
                _numero(
                  'profundidadeRaizesCm',
                  'Profundidade do sistema radicular (z)',
                  profundidadeRaizesCm,
                  unit: 'cm',
                  validator: _validarPositivo,
                ),
              ),
              campo(
                _numero(
                  'fracaoDisponivel',
                  'Fração de água disponível (f)',
                  fracaoDisponivel,
                  helper: 'Entre 0 e 1',
                  validator: _validarFracao,
                ),
              ),
            ],
          );
        },
      ),
      for (final extra in extraFields) ...[
        const SizedBox(height: 12),
        extra,
      ],
      if (footer != null) ...[const SizedBox(height: 12), footer!],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
