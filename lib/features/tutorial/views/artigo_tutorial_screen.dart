import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

import '../models/artigo_tutorial.dart';

class ArtigoTutorialScreen extends StatelessWidget {
  final ArtigoTutorial? artigo;

  const ArtigoTutorialScreen({super.key, required this.artigo});

  @override
  Widget build(BuildContext context) {
    final artigo = this.artigo;
    if (artigo == null) return const _ArtigoNaoEncontrado();

    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(artigo.titulo)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoriaChip(categoria: artigo.categoria),
                      const SizedBox(height: 14),
                      Text(
                        artigo.resumo,
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final secao in artigo.secoes) ...[
                        _SecaoConteudo(secao: secao),
                        const SizedBox(height: 24),
                      ],
                      if (artigo.atalhos.isNotEmpty) ...[
                        Semantics(
                          header: true,
                          child: Text(
                            'Ir para',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final atalho in artigo.atalhos) ...[
                          _AtalhoCard(atalho: atalho),
                          const SizedBox(height: 10),
                        ],
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

class _CategoriaChip extends StatelessWidget {
  final CategoriaTutorial categoria;

  const _CategoriaChip({required this.categoria});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(categoria.titulo),
      avatar: Icon(
        AppIcons.guiaDidatico,
        size: 18,
        color: colors.onSecondaryContainer,
      ),
      backgroundColor: colors.secondaryContainer,
      side: BorderSide.none,
    );
  }
}

class _SecaoConteudo extends StatelessWidget {
  final SecaoTutorial secao;

  const _SecaoConteudo({required this.secao});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              secao.titulo,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (final paragrafo in secao.paragrafos) ...[
            Text(paragrafo, style: text.bodyLarge?.copyWith(height: 1.45)),
            const SizedBox(height: 8),
          ],
          if (secao.passos.isNotEmpty)
            for (var i = 0; i < secao.passos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: text.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        secao.passos[i],
                        style: text.bodyLarge?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _AtalhoCard extends StatelessWidget {
  final AtalhoTutorial atalho;

  const _AtalhoCard({required this.atalho});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    void abrir() => context.go(atalho.rota);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '${atalho.rotulo}. ${atalho.descricao}',
        excludeSemantics: true,
        onTap: abrir,
        child: InkWell(
          onTap: abrir,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(atalho.icone, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          atalho.rotulo,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          atalho.descricao,
                          style: text.bodySmall?.copyWith(
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

class _ArtigoNaoEncontrado extends StatelessWidget {
  const _ArtigoNaoEncontrado();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Artigo não encontrado')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.atencao,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Este artigo não está disponível.',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Volte ao índice para escolher outro assunto.',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.tutorial),
                    child: const Text('Voltar ao tutorial'),
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
