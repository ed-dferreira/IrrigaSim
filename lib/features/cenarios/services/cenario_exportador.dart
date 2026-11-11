import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

import '../models/cenario_salvo.dart';
import 'gravador_arquivo.dart';
import 'project_store.dart';

/// Exporta um cenário salvo como CSV ou PDF.
///
/// O conteúdo dos dois formatos vem de `ProjectStore.secoesResumo`,
/// garantindo consistência entre eles. Em plataformas desktop, o destino do
/// arquivo é escolhido pela caixa de diálogo do sistema (`file_selector`);
/// no navegador, o arquivo é baixado diretamente com o nome sugerido; no
/// Android e iOS — onde `file_selector` não oferece diálogo de gravação —
/// o arquivo vai para um temporário e é entregue à folha de
/// compartilhamento do sistema, de onde pode ser salvo em qualquer pasta.
/// Retornar `null` significa que o usuário cancelou.
class CenarioExportador {
  CenarioExportador({
    required this.projectStore,
    this.escolherDestino = _escolherDestinoPadrao,
  });

  final ProjectStore projectStore;

  /// Injeção de dependência para testes: devolve o caminho escolhido ou
  /// `null` para cancelamento.
  final Future<String?> Function(String nomeArquivo, String extensao)
  escolherDestino;

  /// Exporta o cenário como CSV, gravando com BOM para o Excel respeitar
  /// a UTF-8. Retorna o caminho (ou nome do arquivo no navegador) gravado,
  /// ou `null` se o usuário cancelou.
  Future<String?> exportarCsv(CenarioSalvo cenario) async {
    final csv = '\uFEFF${projectStore.exportarCsv(cenario)}';
    return _gravar(cenario, 'csv', utf8.encode(csv));
  }

  /// Exporta o cenário como PDF. Retorna o caminho (ou nome do arquivo no
  /// navegador) gravado, ou `null` se o usuário cancelou.
  Future<String?> exportarPdf(CenarioSalvo cenario) async {
    final bytes = await gerarPdf(cenario);
    return _gravar(cenario, 'pdf', bytes);
  }

  /// Grava `bytes` com o nome derivado do cenário e da extensão. No
  /// desktop, pede o destino no diálogo do sistema e escreve ali; no
  /// navegador não há diálogo — o download acontece direto com o nome
  /// sugerido; no Android/iOS, grava em temporário e abre a folha de
  /// compartilhamento do sistema.
  Future<String?> _gravar(
    CenarioSalvo cenario,
    String extensao,
    List<int> bytes,
  ) async {
    final nome = _nomeArquivo(cenario, extensao);
    if (kIsWeb) {
      return gravarArquivo(nome, bytes);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      // file_selector não implementa getSaveLocation no Android/iOS: sem
      // este atalho, o diálogo lançaria MissingPluginException.
      final temporario = await getTemporaryDirectory();
      final caminho = '${temporario.path}/$nome';
      await gravarArquivo(caminho, bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              caminho,
              mimeType: extensao == 'pdf' ? 'application/pdf' : 'text/csv',
              name: nome,
            ),
          ],
          subject: nome,
        ),
      );
      return caminho;
    }
    final destino = await escolherDestino(nome, extensao);
    if (destino == null) return null;
    return gravarArquivo(destino, bytes);
  }

  /// Gera os bytes do PDF — função pura, sem diálogo nem disco.
  Future<List<int>> gerarPdf(CenarioSalvo cenario) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 28),
        footer:
            (context) => pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'IrrigaSim · página ${context.pageNumber}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
        build:
            (context) => [
              _cabecalho(cenario),
              for (final (titulo, pares) in projectStore.secoesResumo(cenario))
                _secao(titulo, pares),
            ],
      ),
    );
    return document.save();
  }

  pw.Widget _cabecalho(CenarioSalvo cenario) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Relatório de simulação de irrigação',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          cenario.nome,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Método: ${cenario.metodo.displayName} · '
          'gerado em ${_formatarAgora(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Container(color: PdfColors.grey500, height: 1),
      ],
    );
  }

  pw.Widget _secao(String titulo, List<MapEntry<String, String>> pares) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          for (final par in pares)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  ),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(par.key, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          par.value,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _nomeArquivo(CenarioSalvo cenario, String extensao) {
    final base = cenario.nome.replaceAll(RegExp(r'[^\p{L}\p{N}]+'), '-');
    final agora = DateTime.now();
    final data =
        '${agora.year.toString().padLeft(4, '0')}'
        '${agora.month.toString().padLeft(2, '0')}'
        '${agora.day.toString().padLeft(2, '0')}';
    final nome = base.isEmpty ? 'cenario-$data' : 'cenario-$base-$data';
    return '$nome.$extensao';
  }

  String _formatarAgora(DateTime agora) {
    return '${agora.day.toString().padLeft(2, '0')}/'
        '${agora.month.toString().padLeft(2, '0')}/'
        '${agora.year} às ${agora.hour.toString().padLeft(2, '0')}:'
        '${agora.minute.toString().padLeft(2, '0')}';
  }
}

Future<String?> _escolherDestinoPadrao(
  String nomeArquivo,
  String extensao,
) async {
  final localizacao = await getSaveLocation(
    suggestedName: nomeArquivo,
    acceptedTypeGroups: [
      XTypeGroup(label: extensao.toUpperCase(), extensions: [extensao]),
    ],
  );
  return localizacao?.path;
}
