// Painel didático compartilhado da Aula 8: guia de área × vazão (p. 16),
// relação de Henderson (p. 17), tabela de sifões/tubos de Booher (p. 38) e a
// checagem operacional G3. Usado na revisão do projeto e na tela de
// resultado, com a página da fonte visível em cada seção e nas linhas.
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/services/simulation/inundacao/basin_planning.dart';
import 'package:irrigasim/services/simulation/inundacao/basin_reference_tables.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';
import 'package:irrigasim/views/irrigation/widgets/irrigation_project_components.dart';

class BasinReferencePanel extends StatelessWidget {
  const BasinReferencePanel({super.key, required this.projeto});

  final BasinProject projeto;

  String _fmt(double? value, {int casas = 4}) {
    if (value == null) return '—';
    var texto = value.toStringAsFixed(casas);
    if (texto.contains('.')) {
      texto = texto.replaceFirst(RegExp(r'0+$'), '');
      texto = texto.replaceFirst(RegExp(r'\.$'), '');
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final vazao = projeto.vazaoAplicadaLs ?? projeto.vazaoDisponivelLps;
    final vib = projeto.vibMMin;
    double? areaHenderson;
    if (vazao != null && vib != null && vazao > 0 && vib > 0) {
      areaHenderson = BasinHendersonReference.area(
        vazao * 3.6,
        vib * 60 * 1000,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IrrigationAuditSection(
          title: 'Guia de área por vazão',
          pagina: '${BasinReferenceTables.paginaGuiaSolo}',
          icon: AppIcons.soloArgiloso,
          children: [
            for (final row in BasinReferenceTables.guiaSolo)
              IrrigationAuditRow(
                row.rotulo,
                vazao == null
                    ? '${_fmt(row.areaHaBase, casas: 2)} ha a 10 L/s'
                    : '${_fmt(row.areaParaVazao(vazao), casas: 2)} ha a '
                          '${_fmt(vazao, casas: 1)} L/s',
                detail:
                    'Orientativo; não substitui o dimensionamento hidráulico.',
                isWarning: true,
                pagina: '${BasinReferenceTables.paginaGuiaSolo}',
              ),
          ],
        ),
        IrrigationAuditSection(
          title: 'Henderson',
          pagina: '${BasinReferenceTables.paginaHenderson}',
          icon: AppIcons.projetoSolo,
          children: [
            IrrigationAuditRow(
              'Fórmula',
              BasinHendersonReference.formula,
              detail:
                  'A em ${BasinHendersonReference.unidadeArea}, '
                  'Q em ${BasinHendersonReference.unidadeVazao} e '
                  'VIB em ${BasinHendersonReference.unidadeVib}; '
                  '${BasinHendersonReference.natureza}.',
              pagina: '${BasinReferenceTables.paginaHenderson}',
            ),
            IrrigationAuditRow(
              'Área estimada',
              areaHenderson == null
                  ? '—'
                  : '${_fmt(areaHenderson, casas: 2)} m²',
              detail: areaHenderson == null
                  ? 'Informe a vazão total e a VIB para estimar a área.'
                  : 'Q = ${_fmt(vazao, casas: 1)} L/s · '
                        'VIB = ${_fmt(vib, casas: 6)} m/min.',
              pagina: '${BasinReferenceTables.paginaHenderson}',
            ),
          ],
        ),
        IrrigationAuditSection(
          title: 'Sifões e tubos de Booher',
          pagina: '${BasinReferenceTables.paginaBooher}',
          icon: AppIcons.balancoHidrico,
          children: [
            Text(
              'Vazão em L/s por diâmetro (Ø) e carga na soleira. As células '
              'Ø 30 cm com carga 7,5 e 10 cm não crescem monotonicamente na '
              'fonte e ficam sob revisão: nunca viram sugestão automática.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: IrrigationSpacing.field),
            _BooherTable(formatted: _fmt),
          ],
        ),
      ],
    );
  }
}

class _BooherTable extends StatelessWidget {
  const _BooherTable({required this.formatted});

  final String Function(double?, {int casas}) formatted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final headers = BasinReferenceTables.cargasCm;
    final diameters = BasinReferenceTables.diametrosCm;
    final values = BasinReferenceTables.valoresLs;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerHigh),
        columns: [
          const DataColumn(label: Text('Ø (cm)')),
          for (final carga in headers)
            DataColumn(label: Text('${formatted(carga, casas: 1)} cm')),
        ],
        rows: [
          for (var i = 0; i < diameters.length; i++)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    formatted(diameters[i], casas: 1),
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var j = 0; j < headers.length; j++)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatted(values[i][j], casas: 1)} L/s',
                          style: text.bodyMedium,
                        ),
                        if (basinBooherCelulasSuspeitas.contains((
                          diameters[i],
                          headers[j],
                        )))
                          Text(
                            'sob revisão',
                            style: text.labelSmall?.copyWith(
                              color: colors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Seção da checagem operacional obrigatória (G3): vazão disponível ×
/// planejada e geometria do tabuleiro × área declarada.
class BasinOperationalCheckSection extends StatelessWidget {
  const BasinOperationalCheckSection({
    super.key,
    required this.checagem,
    this.icon,
  });

  final BasinChecagemOperacional checagem;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    String f(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return IrrigationAuditSection(
      title: 'Checagem operacional (G3)',
      icon: icon ?? AppIcons.projetoOperacao,
      children: [
        IrrigationAuditRow(
          'Vazão planejada × disponível',
          '${f(checagem.vazaoPlanejadaLs)} / '
              '${f(checagem.vazaoDisponivelLs)} L/s',
          detail: checagem.atendeVazao
              ? 'A vazão planejada cabe na fonte.'
              : 'A fonte não atende à vazão planejada.',
          isWarning: !checagem.atendeVazao,
          pagina: '73',
        ),
        IrrigationAuditRow(
          'Tabuleiro × área declarada',
          '${f(checagem.areaTabuleiroM2)} / '
              '${f(checagem.areaDeclaradaM2)} m²',
          detail: checagem.geometriaCabeNaArea
              ? 'A geometria do tabuleiro cabe na unidade.'
              : 'O tabuleiro supera a área declarada.',
          isWarning: !checagem.geometriaCabeNaArea,
          pagina: '73',
        ),
        IrrigationAuditRow(
          'Status G3',
          checagem.viavel ? 'Viável' : 'Fora do recomendado',
          detail:
              checagem.motivo ??
              'Vazão e geometria atendem ao critério operacional.',
          isWarning: !checagem.viavel,
          pagina: '73',
        ),
      ],
    );
  }
}
