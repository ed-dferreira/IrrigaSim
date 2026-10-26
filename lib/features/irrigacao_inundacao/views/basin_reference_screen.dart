import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:markdown/markdown.dart' show ExtensionSet;

const assetResumoInundacao =
    'docs/Pacote_Inundacao/Resumo_irrigacao_por_inundacao.md';

class BasinReferenceScreen extends StatefulWidget {
  const BasinReferenceScreen({super.key});

  @override
  State<BasinReferenceScreen> createState() => _BasinReferenceScreenState();
}

class _BasinReferenceScreenState extends State<BasinReferenceScreen> {
  static String? _cache;
  late Future<String> _fonte;

  @override
  void initState() {
    super.initState();
    _fonte = _carregar();
  }

  Future<String> _carregar() async {
    final cache = _cache;
    if (cache != null) return cache;
    final texto = await rootBundle.loadString(assetResumoInundacao);
    if (texto.trim().isEmpty) {
      throw const FormatException('Resumo da Aula 8 vazio.');
    }
    _cache = texto;
    return texto;
  }

  void _tentarNovamente() {
    setState(() {
      _cache = null;
      _fonte = _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referência — Aula 8'),
        actions: [
          IconButton(
            tooltip: 'Recarregar resumo',
            onPressed: _tentarNovamente,
            icon: const Icon(AppIcons.abrirChangelog),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _fonte,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando resumo da Aula 8…',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.statusBloqueio,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Não foi possível carregar o resumo da Aula 8',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _tentarNovamente,
                        icon: const Icon(AppIcons.projetoCalcular),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Markdown(
                data: snapshot.data ?? '',
                selectable: true,
                extensionSet: ExtensionSet.gitHubFlavored,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                styleSheet: MarkdownStyleSheet.fromTheme(theme)
                    .copyWith(p: theme.textTheme.bodyMedium),
              ),
            ),
          );
        },
      ),
    );
  }
}
