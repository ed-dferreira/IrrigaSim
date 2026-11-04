import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

/// Abre a prévia de CSV comum às telas de resultado de irrigação.
Future<void> showIrrigationExportSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String csv,
  String copyLabel = 'Copiar CSV',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  sheetContext,
                ).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'CSV copiado. Cole em um arquivo ou planilha.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(AppIcons.exportarDados),
              label: Text(copyLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
