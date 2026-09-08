import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/irrigation_method_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IrrigaSim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, Bem-vindo!', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.help_outline, color: AppColors.secondary),
                title: const Text('Tutorial'),
                subtitle: const Text('Aprenda a usar o IrrigaSim'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 24),
            Text('Método de Irrigação', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.sulco,
              onTap: () {
                ref.read(parametersProvider.notifier).setMetodo(MetodoIrrigacao.sulco);
                context.push('/irrigation/parameters');
              },
            ),
            const SizedBox(height: 8),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.faixa,
              onTap: () {
                ref.read(parametersProvider.notifier).setMetodo(MetodoIrrigacao.faixa);
                context.push('/irrigation/parameters');
              },
            ),
            const SizedBox(height: 8),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.inundacao,
              onTap: () {
                ref.read(parametersProvider.notifier).setMetodo(MetodoIrrigacao.inundacao);
                context.push('/irrigation/parameters');
              },
            ),
          ],
        ),
      ),
    );
  }
}
