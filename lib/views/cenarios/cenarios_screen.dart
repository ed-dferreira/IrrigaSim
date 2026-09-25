import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/models/cenario_salvo.dart';
import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/providers.dart';

class CenariosScreen extends ConsumerStatefulWidget {
  const CenariosScreen({super.key});

  @override
  ConsumerState<CenariosScreen> createState() => _CenariosScreenState();
}

class _CenariosScreenState extends ConsumerState<CenariosScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cenariosAsync = ref.watch(cenariosProvider);
    return Scaffold(
      body: SafeArea(
        child: cenariosAsync.when(
          data: _buildContent,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(cenariosProvider),
            message: error.toString(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<CenarioSalvo> cenarios) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = cenarios.where((cenario) {
      return normalizedQuery.isEmpty ||
          cenario.nome.toLowerCase().contains(normalizedQuery) ||
          cenario.metodo.displayName.toLowerCase().contains(normalizedQuery);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600 ? 16.0 : 28.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 12),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'Meus cenários',
                                      style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cenarios.isEmpty
                                        ? 'Salve simulações para comparar resultados.'
                                        : '${cenarios.length} ${cenarios.length == 1 ? 'simulação salva' : 'simulações salvas'}',
                                    style: text.bodyLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: 'Nova simulação',
                              child: IconButton.filled(
                                onPressed: () => context.go('/home'),
                                icon: const Icon(AppIcons.novoCenario),
                              ),
                            ),
                          ],
                        ),
                        if (cenarios.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nome ou método',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (cenarios.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreate: () => context.go('/home')),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoSearchResults(query: _query),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 8, padding, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          const gap = 14.0;
                          final columns = inner.maxWidth >= 820 ? 2 : 1;
                          final width =
                              (inner.maxWidth - gap * (columns - 1)) / columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: filtered
                                .map(
                                  (cenario) => SizedBox(
                                    width: width,
                                    child: _CenarioCard(
                                      cenario: cenario,
                                      onView: () => _showDetails(cenario),
                                      onDelete: () => _delete(cenario),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _delete(CenarioSalvo cenario) async {
    await ref.read(scenarioServiceProvider).excluir(cenario.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('“${cenario.nome}” foi excluído.')));
  }

  void _showDetails(CenarioSalvo cenario) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ScenarioDetails(cenario: cenario),
    );
  }
}

class _CenarioCard extends StatelessWidget {
  final CenarioSalvo cenario;
  final VoidCallback onView;
  final VoidCallback onDelete;
  const _CenarioCard({
    required this.cenario,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final date = _formatDate(cenario.dataCriacao);
    return Semantics(
      container: true,
      label:
          'Cenário ${cenario.nome}, método ${cenario.metodo.displayName}, salvo em $date',
      child: Card(
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _methodIcon(cenario),
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cenario.nome,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Salvo em $date',
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MethodBadge(label: cenario.metodo.displayName),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        label: 'Eficiência',
                        value: '${cenario.resultado.eficiencia.toInt()}%',
                        tone: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        label: 'Uniformidade',
                        value: '${cenario.resultado.cuc.toInt()}%',
                        tone: colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        label: 'Lâmina média',
                        value:
                            '${cenario.resultado.laminaMedia.toStringAsFixed(1)} mm',
                        tone: colors.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onView,
                        icon: const Icon(AppIcons.visualizarCenario),
                        label: const Text('Ver detalhes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Excluir cenário',
                      child: IconButton.outlined(
                        onPressed: () => _confirmDelete(context),
                        color: colors.error,
                        icon: const Icon(AppIcons.excluirCenario),
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
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.excluirCenario),
        title: const Text('Excluir cenário?'),
        content: Text('“${cenario.nome}” será removido permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  const _Kpi({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.titleMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String label;
  const _MethodBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScenarioDetails extends StatelessWidget {
  final CenarioSalvo cenario;
  const _ScenarioDetails({required this.cenario});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cenario.nome,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MethodBadge(label: cenario.metodo.displayName),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(cenario.dataCriacao),
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Resultados',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        label: 'Eficiência',
                        value:
                            '${cenario.resultado.eficiencia.toStringAsFixed(1)}%',
                        tone: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        label: 'Uniformidade',
                        value: '${cenario.resultado.cuc.toStringAsFixed(1)}%',
                        tone: colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        label: 'Lâmina',
                        value:
                            '${cenario.resultado.laminaMedia.toStringAsFixed(1)} mm',
                        tone: colors.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Parâmetros principais',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: colors.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Comprimento',
                          value:
                              '${cenario.parametros.comprimento.toStringAsFixed(1)} m',
                        ),
                        _DetailRow(
                          label: 'Declividade',
                          value:
                              '${cenario.parametros.declividade.toStringAsFixed(3)} m/m',
                        ),
                        _DetailRow(
                          label: 'Vazão',
                          value:
                              '${cenario.parametros.vazao.toStringAsFixed(2)} L/s',
                        ),
                        _DetailRow(
                          label: 'Tempo de aplicação',
                          value:
                              '${cenario.parametros.tempoAplicacao.toStringAsFixed(0)} min',
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  AppIcons.navCenarios,
                  size: 34,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Seu histórico começa aqui',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Execute uma simulação e salve o resultado para acompanhar e comparar seus cenários.',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(AppIcons.criarNovaSimulacao),
                label: const Text('Criar simulação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;
  const _NoSearchResults({required this.query});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum resultado para “$query”',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorState({required this.onRetry, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar os cenários.'),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

IconData _methodIcon(CenarioSalvo cenario) => switch (cenario.metodo.name) {
  'sulco' => AppIcons.sulco,
  'faixa' => AppIcons.faixa,
  _ => AppIcons.inundacao,
};
