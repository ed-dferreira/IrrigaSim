import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/irrigation_method_card.dart';

class TutorialScreen extends ConsumerWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.72),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Simulação guiada',
                      style: textStyles.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.pularTutorial,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sair',
                            style: textStyles.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha o método de irrigação',
                  style: textStyles.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecione a opção mais adequada ao seu terreno. '
                  'Os parâmetros serão configurados na tela seguinte.',
                  style: textStyles.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                IrrigationMethodCard(
                  metodo: MetodoIrrigacao.sulco,
                  onTap: () => _open(context, ref, MetodoIrrigacao.sulco),
                ),
                const SizedBox(height: 8),
                IrrigationMethodCard(
                  metodo: MetodoIrrigacao.faixa,
                  onTap: () => _open(context, ref, MetodoIrrigacao.faixa),
                ),
                const SizedBox(height: 8),
                IrrigationMethodCard(
                  metodo: MetodoIrrigacao.inundacao,
                  onTap: () => _open(context, ref, MetodoIrrigacao.inundacao),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, MetodoIrrigacao method) {
    ref.read(parametersProvider.notifier).setMetodo(method);
    context.push('/home/irrigation/parameters');
  }
}
