import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:markdown/markdown.dart' show ExtensionSet;

const assetResumoInundacao =
    'docs/Pacote_Inundacao/Resumo_irrigacao_por_inundacao.md';

/// Equivalente a `MarkdownStyleSheet.fromTheme`, mas construído a partir do
/// `ThemeData` do `material_ui`. O `flutter_markdown` ainda usa os tipos do
/// Material do SDK, então não é possível passar o tema da aplicação direto.
MarkdownStyleSheet _estiloMarkdown(ThemeData theme) {
  final corpo = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  return MarkdownStyleSheet(
    a: const TextStyle(color: Colors.blue),
    p: corpo,
    pPadding: EdgeInsets.zero,
    code: corpo.copyWith(
      backgroundColor: theme.cardTheme.color,
      fontFamily: 'monospace',
      fontSize: (corpo.fontSize ?? 14) * 0.85,
    ),
    h1: theme.textTheme.headlineSmall,
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.titleLarge,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.titleMedium,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.bodyLarge,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.bodyLarge,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.bodyLarge,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockquote: corpo,
    img: corpo,
    checkbox: corpo.copyWith(color: theme.colorScheme.primary),
    blockSpacing: 8,
    listIndent: 24,
    listBullet: corpo,
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: corpo,
    tableHeadAlign: TextAlign.center,
    tablePadding: const EdgeInsets.only(bottom: 4),
    tableBorder: TableBorder.all(color: theme.dividerColor),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.all(8),
    blockquoteDecoration: BoxDecoration(
      color: Colors.blue.shade100,
      borderRadius: BorderRadius.circular(2),
    ),
    codeblockPadding: const EdgeInsets.all(8),
    codeblockDecoration: BoxDecoration(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(2),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(width: 5, color: theme.dividerColor)),
    ),
  );
}

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
                styleSheet: _estiloMarkdown(theme),
              ),
            ),
          );
        },
      ),
    );
  }
}
