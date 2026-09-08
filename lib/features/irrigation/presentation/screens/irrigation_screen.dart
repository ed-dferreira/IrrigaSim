import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/irrigation_method_card.dart';

class IrrigationScreen extends ConsumerWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nova Simulação', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.sulco,
              onTap: () => context.push('/irrigation/parameters'),
            ),
            const SizedBox(height: 8),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.faixa,
              onTap: () => context.push('/irrigation/parameters'),
            ),
            const SizedBox(height: 8),
            IrrigationMethodCard(
              metodo: MetodoIrrigacao.inundacao,
              onTap: () => context.push('/irrigation/parameters'),
            ),
          ],
        ),
      ),
    );
  }
}
