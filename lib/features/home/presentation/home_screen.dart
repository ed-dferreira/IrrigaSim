import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.nome ?? 'Usuário';
    final firstName = userName.split(' ').firstOrNull ?? userName;

    final metodos = [
      (MetodoIrrigacao.sulco, 'Sulcos (Furrow)', 'Canais paralelos entre fileiras de cultivo'),
      (MetodoIrrigacao.faixa, 'Faixa (Border)', 'Lâmina contínua em declive delimitada'),
      (MetodoIrrigacao.inundacao, 'Inundação / Bacia', 'Talhões nivelados cercados por taipas'),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Olá, $firstName',
                              style: textStyles.headlineMedium?.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              AppIcons.saudacao,
                              color: colors.primary,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Escolha o método de irrigação por superfície',
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card de Tutorial
              Card(
                color: colors.primaryContainer,
                child: InkWell(
                  onTap: () {
                    context.push('/home/tutorial');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.guiaDidatico,
                          color: colors.onPrimaryContainer,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guia Didático da Aula 5',
                                style: textStyles.titleMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'Passo a passo fundamentado em 4 etapas',
                                style: textStyles.bodySmall?.copyWith(
                                  color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '→',
                          style: TextStyle(
                            fontSize: 24,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Título dos métodos
              Text(
                'Métodos de Superfície Rápido',
                style: textStyles.titleMedium?.copyWith(
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Cards dos métodos
              ...metodos.map((metodo) {
                final (enumValue, titulo, desc) = metodo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        ref.read(parametersProvider.notifier).setMetodo(enumValue);
                        context.push('/home/irrigation/parameters');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _iconeMetodo(enumValue),
                                color: colors.onSecondaryContainer,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titulo,
                                    style: textStyles.titleMedium?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    desc,
                                    style: textStyles.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  AppIcons.simular,
                                  color: colors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Simular',
                                  style: textStyles.labelMedium?.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconeMetodo(MetodoIrrigacao metodo) {
    switch (metodo) {
      case MetodoIrrigacao.sulco:
        return AppIcons.sulco;
      case MetodoIrrigacao.faixa:
        return AppIcons.faixa;
      case MetodoIrrigacao.inundacao:
        return AppIcons.inundacao;
    }
  }
}
