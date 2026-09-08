import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/irrigation_method_card.dart';

class IrrigationMethodScreen extends StatelessWidget {
  const IrrigationMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Método'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o método de irrigação desejado:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
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
