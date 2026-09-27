import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';
import 'package:irrigasim/views/irrigation/widgets/irrigation_method_card.dart';

class IrrigationScreen extends ConsumerWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Irrigação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nova Simulação', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
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
    );
  }

  void _open(BuildContext context, WidgetRef ref, MetodoIrrigacao method) {
    ref.read(parametersProvider.notifier).setMetodo(method);
    if (method == MetodoIrrigacao.sulco) {
      context.push('/home/irrigation/tipo-sulco');
    } else {
      context.push('/home/irrigation/parameters');
    }
  }
}
