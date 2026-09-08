import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';

class ParametersScreen extends ConsumerStatefulWidget {
  const ParametersScreen({super.key});

  @override
  ConsumerState<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends ConsumerState<ParametersScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final _comprimentoController = TextEditingController();
  final _desnivelController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _larguraController = TextEditingController();
  final _kController = TextEditingController();
  final _aController = TextEditingController();
  final _vibController = TextEditingController();
  final _vazaoController = TextEditingController();
  final _tempoController = TextEditingController();
  final _laminaController = TextEditingController();
  final _manningController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(parametersProvider);
    _comprimentoController.text = state.comprimento.toString();
    _desnivelController.text = state.desnivelM.toString();
    _distanciaController.text = state.distanciaHorizontalM.toString();
    _larguraController.text = state.larguraOuEspacamento.toString();
    _kController.text = state.k.toString();
    _aController.text = state.a.toString();
    _vibController.text = state.vib.toString();
    _vazaoController.text = state.vazao.toString();
    _tempoController.text = state.tempoAplicacao.toString();
    _laminaController.text = state.laminaRequerida.toString();
    _manningController.text = state.manningN.toString();
  }

  @override
  void dispose() {
    _comprimentoController.dispose();
    _desnivelController.dispose();
    _distanciaController.dispose();
    _larguraController.dispose();
    _kController.dispose();
    _aController.dispose();
    _vibController.dispose();
    _vazaoController.dispose();
    _tempoController.dispose();
    _laminaController.dispose();
    _manningController.dispose();
    super.dispose();
  }

  void _updateField(String campo, String valor) {
    ref.read(parametersProvider.notifier).updateField(campo: campo, valor: valor);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parametersProvider);
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final notifier = ref.read(parametersProvider.notifier);

    ref.listen<ParametersState>(parametersProvider, (prev, next) {
      if (next.resultado != null && prev?.resultado == null) {
        context.push('/home/irrigation/results');
      }
      if (next.erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!)),
        );
      }
    });

    final declividadeCalculada = notifier.calcularDeclividade();

    return Scaffold(
      body: Column(
        children: [
          // Header personalizado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            color: colors.primary,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  state.metodo.displayName,
                  style: textStyles.titleLarge?.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Geometria do Terreno
                    Text(
                      'Geometria do Terreno',
                      style: textStyles.titleLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      context: context,
                      label: 'Comprimento do terreno (m)',
                      controller: _comprimentoController,
                      onChanged: (v) => _updateField('comprimento', v),
                    ),

                    // Declividade
                    Text(
                      'Declividade (2 Medidas)',
                      style: textStyles.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            context: context,
                            label: 'Desnível ΔH (m)',
                            controller: _desnivelController,
                            onChanged: (v) => _updateField('desnivelM', v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campo(
                            context: context,
                            label: 'Distância L (m)',
                            controller: _distanciaController,
                            onChanged: (v) => _updateField('distanciaHorizontalM', v),
                          ),
                        ),
                      ],
                    ),

                    // Card de declividade calculada
                    Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.declividade,
                              color: colors.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Declividade S₀: ${declividadeCalculada.toStringAsFixed(3)}%',
                              style: textStyles.titleSmall?.copyWith(
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _campo(
                      context: context,
                      label: state.metodo == MetodoIrrigacao.sulco
                          ? 'Espaçamento entre sulcos (m)'
                          : 'Largura (m)',
                      controller: _larguraController,
                      onChanged: (v) => _updateField('larguraOuEspacamento', v),
                    ),

                    const SizedBox(height: 14),

                    // Solo — Kostiakov-Lewis
                    Text(
                      'Solo — Kostiakov-Lewis',
                      style: textStyles.titleLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      context: context,
                      label: 'Coeficiente k (mm/hᵃ)',
                      controller: _kController,
                      onChanged: (v) => _updateField('k', v),
                    ),
                    _campo(
                      context: context,
                      label: 'Expoente a (0 < a < 1)',
                      controller: _aController,
                      onChanged: (v) => _updateField('a', v),
                    ),
                    _campo(
                      context: context,
                      label: 'Taxa básica de infiltração VIB (mm/h)',
                      controller: _vibController,
                      onChanged: (v) => _updateField('vib', v),
                    ),

                    const SizedBox(height: 14),

                    // Manejo & Hidráulica
                    Text(
                      'Manejo & Hidráulica',
                      style: textStyles.titleLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      context: context,
                      label: state.metodo == MetodoIrrigacao.sulco
                          ? 'Vazão por sulco (L/s)'
                          : state.metodo == MetodoIrrigacao.faixa
                              ? 'Vazão unitária (L/s/m)'
                              : 'Vazão total da bacia (L/s)',
                      controller: _vazaoController,
                      onChanged: (v) => _updateField('vazao', v),
                    ),
                    _campo(
                      context: context,
                      label: 'Tempo de aplicação (min)',
                      controller: _tempoController,
                      onChanged: (v) => _updateField('tempoAplicacao', v),
                    ),
                    _campo(
                      context: context,
                      label: 'Lâmina líquida requerida LN (mm)',
                      controller: _laminaController,
                      onChanged: (v) => _updateField('laminaRequerida', v),
                    ),
                    _campo(
                      context: context,
                      label: 'Rugosidade de Manning n',
                      controller: _manningController,
                      onChanged: (v) => _updateField('manningN', v),
                    ),

                    const SizedBox(height: 24),

                    // Botão de executar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.executando
                            ? null
                            : () => notifier.executarSimulacao(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.executando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Executar Simulação →',
                                style: textStyles.titleMedium,
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
