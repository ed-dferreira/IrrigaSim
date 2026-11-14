import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

import '../content/manual_operacao.dart';
import '../models/artigo_tutorial.dart';
import '../routes.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial e ajuda')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Manual de operação',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aprenda a usar as telas do IrrigaSIM e abra o assunto '
                        'que precisar.',
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final categoria in CategoriaTutorial.values)
                        if (artigosDaCategoria(categoria).isNotEmpty) ...[
                          _CategoriaSection(
                            categoria: categoria,
                            artigos: artigosDaCategoria(categoria),
                          ),
                          const SizedBox(height: 24),
                        ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoriaSection extends StatelessWidget {
  final CategoriaTutorial categoria;
  final List<ArtigoTutorial> artigos;

  const _CategoriaSection({required this.categoria, required this.artigos});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              categoria.titulo,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          for (final artigo in artigos) ...[
            _ArtigoCard(artigo: artigo),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ArtigoCard extends StatelessWidget {
  final ArtigoTutorial artigo;

  const _ArtigoCard({required this.artigo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    void abrir() => context.push(localizacaoArtigoTutorial(artigo.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '${artigo.titulo}. ${artigo.resumo}',
        excludeSemantics: true,
        onTap: abrir,
        child: InkWell(
          onTap: abrir,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      artigo.icone,
                      color: colors.onPrimaryContainer,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artigo.titulo,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          artigo.resumo,
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    AppIcons.etapasSeguintes,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
