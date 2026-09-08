import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/parameter_form.dart';

class ParametersScreen extends ConsumerWidget {
  const ParametersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);

    ref.listen<ParametersState>(parametersProvider, (prev, next) {
      if (next.resultado != null && prev?.resultado == null) {
        context.push('/irrigation/results');
      }
      if (next.erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Parâmetros - ${state.metodo.displayName}'),
      ),
      body: const ParameterForm(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: state.executando
              ? null
              : () => ref.read(parametersProvider.notifier).executarSimulacao(),
          child: state.executando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simular'),
        ),
      ),
    );
  }
}
