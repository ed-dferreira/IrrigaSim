import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

import '../models/cenario_salvo.dart';

/// Arquivo escolhido pelo usuário: conteúdo decodificado e nome do arquivo.
typedef ArquivoCsvEscolhido = ({String conteudo, String nome});

/// Seleciona um arquivo CSV. Injetável para testes; `null` = cancelado.
typedef EscolherArquivoCsv = Future<ArquivoCsvEscolhido?> Function();

/// Erro padrão quando o conteúdo não é um CSV de cenário do IrrigaSim.
const _mensagemFormato = FormatException(
  'Este arquivo não é um CSV exportado pelo IrrigaSim. '
  'Exporte um cenário em “Meus cenários” e importe o arquivo gerado.',
);

/// Importa um cenário gravado pelo próprio IrrigaSim.
///
/// O formato aceito é exatamente o que `ProjectStore.exportarCsv` gera:
/// colunas `Seção;Campo;Valor`, separador `;`, decimal com vírgula e
/// BOM UTF-8 — garantindo que exportar e importar usem o mesmo tipo de
/// arquivo. A seleção usa o seletor de arquivos do sistema
/// (`file_selector.openFile`), suportado no Android, iOS, desktop e web.
///
/// Como o CSV é um resumo, o cenário reconstruído contém os parâmetros
/// principais e os indicadores-chave; curvas, métricas adicionais e
/// planejamento operacional não são incluídos (não constam no arquivo).
/// A revisão antes de salvar é feita na camada de UI.
class CenarioImportador {
  CenarioImportador({this.escolherArquivo = _escolherArquivoPadrao});

  final EscolherArquivoCsv escolherArquivo;

  /// Abre o seletor de arquivos, lê o CSV e devolve o cenário pronto para
  /// revisão. Retorna `null` quando o usuário cancela a seleção.
  ///
  /// Lança `FormatException` com mensagem amigável quando o arquivo não é
  /// um CSV válido do IrrigaSim.
  Future<CenarioSalvo?> importarDoArquivo() async {
    final arquivo = await escolherArquivo();
    if (arquivo == null) return null;
    return importarCsv(arquivo.conteudo, nomeArquivo: arquivo.nome);
  }

  /// Reconstrói um `CenarioSalvo` a partir do conteúdo do CSV.
  ///
  /// O cenário vem sem id (vazio): a camada de UI gera o id no momento
  /// de salvar, depois da revisão.
  CenarioSalvo importarCsv(String conteudo, {String? nomeArquivo}) {
    final tabela = _tabela(conteudo);
    if (tabela.isEmpty || !_eCabecalho(tabela.first)) {
      throw _mensagemFormato;
    }

    final campos = <String, String>{};
    for (final linha in tabela.skip(1)) {
      if (linha.length < 3) continue;
      final campo = linha[1].trim();
      if (campo.isNotEmpty) campos[campo] = linha[2].trim();
    }

    final metodo = _metodoDe(campos['Método']);
    final nome = _nomeDe(campos['Nome'], nomeArquivo);

    final laminaRequerida = _numeroObrigatorio(
      campos['Lâmina requerida (mm)'],
      campo: 'Lâmina requerida (mm)',
    );

    final paramData = <String, dynamic>{
      'comprimento': _numeroObrigatorio(
        campos['Comprimento (m)'],
        campo: 'Comprimento (m)',
      ),
      'declividade': _numeroObrigatorio(
        campos['Declividade (m/m)'],
        campo: 'Declividade (m/m)',
      ),
      'larguraOuEspacamento': _numeroObrigatorio(
        campos['Espaçamento/largura (m)'],
        campo: 'Espaçamento/largura (m)',
      ),
      'vazao': _numeroObrigatorio(campos['Vazão (L/s)'], campo: 'Vazão (L/s)'),
      'tempoAplicacao': _numeroObrigatorio(
        campos['Tempo de aplicação (min)'],
        campo: 'Tempo de aplicação (min)',
      ),
      'laminaRequerida': laminaRequerida,
      'k': _numeroObrigatorio(
        campos['Coeficiente de infiltração k'],
        campo: 'Coeficiente de infiltração k',
      ),
      'a': _numeroObrigatorio(campos['Expoente a'], campo: 'Expoente a'),
      // O CSV resumido não exporta a VIB (dado de ensaio): usa o padrão.
      if (campos.containsKey('Velocidade de infiltração básica (m/min)'))
        'vib': _numeroObrigatorio(
          campos['Velocidade de infiltração básica (m/min)'],
          campo: 'Velocidade de infiltração básica (m/min)',
        )
      else
        'vib': 0.0,
      'areaHectares': ?_numeroOpcional(campos['Área efetiva (ha)']),
      'periodoIrrigacaoDias': ?_numeroOpcional(
        campos['Período de irrigação (dias)'],
      )?.round(),
      'texturaSolo': ?_texturaDe(campos['Textura do solo'])?.name,
      'manejoSulco': ?_manejoDe(campos['Manejo'])?.name,
    };

    final resultadoData = <String, dynamic>{
      'eficiencia': _numeroObrigatorio(
        campos['Eficiência de aplicação Ea (%)'],
        campo: 'Eficiência de aplicação Ea (%)',
      ),
      'eficienciaRequerimento': _numeroObrigatorio(
        campos['Eficiência de requerimento (%)'],
        campo: 'Eficiência de requerimento (%)',
      ),
      'cuc': _numeroObrigatorio(
        campos['Uniformidade CUC (%)'],
        campo: 'Uniformidade CUC (%)',
      ),
      'du': _numeroObrigatorio(
        campos['Distribuição DU (%)'],
        campo: 'Distribuição DU (%)',
      ),
      'laminaMedia':
          _numeroObrigatorio(
                campos['Lâmina média infiltrada (mm)'],
                campo: 'Lâmina média infiltrada (mm)',
              ) /
              1000,
      'laminaRequerida': laminaRequerida,
      'tempoAvanco': _numeroObrigatorio(
        campos['Tempo de avanço (min)'],
        campo: 'Tempo de avanço (min)',
      ),
      'perdaPercolacao': _numeroObrigatorio(
        campos['Perda por percolação (%)'],
        campo: 'Perda por percolação (%)',
      ),
      'perdaEscoamento': _numeroObrigatorio(
        campos['Perda por escoamento (%)'],
        campo: 'Perda por escoamento (%)',
      ),
      // O CSV resumido não traz curvas nem perfil: deixam vazias e a
      // interface oculta as abas correspondentes.
      'curvaAvanco': const <dynamic>[],
      'perfilLongitudinal': const <dynamic>[],
      'resumoTextual': '',
    };

    return CenarioSalvo.fromMap({
      'nome': nome,
      'metodo': metodo.name,
      'parametros': paramData,
      'resultado': resultadoData,
    }, id: '');
  }

  static Future<ArquivoCsvEscolhido?> _escolherArquivoPadrao() async {
    const tipoCsv = XTypeGroup(label: 'CSV', extensions: ['csv']);
    final arquivo = await openFile(acceptedTypeGroups: [tipoCsv]);
    if (arquivo == null) return null;
    final bytes = await arquivo.readAsBytes();
    return (
      conteudo: utf8.decode(bytes, allowMalformed: true),
      nome: arquivo.name,
    );
  }

  String _nomeDe(String? doCsv, String? doArquivo) {
    if (doCsv != null && doCsv.trim().isNotEmpty) return doCsv.trim();
    final base = doArquivo?.replaceAll(RegExp(r'\.[^.]+$'), '').trim() ?? '';
    return base.isNotEmpty ? base : 'Cenário importado';
  }

  MetodoIrrigacao _metodoDe(String? valor) {
    final texto = (valor ?? '').trim().toLowerCase();
    if (texto.isEmpty) throw _mensagemFormato;
    for (final metodo in MetodoIrrigacao.values) {
      if (metodo.displayName.toLowerCase() == texto ||
          metodo.name.toLowerCase() == texto) {
        return metodo;
      }
    }
    throw FormatException('Método de irrigação desconhecido no CSV: "$valor".');
  }

  TexturaSolo? _texturaDe(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    for (final textura in TexturaSolo.values) {
      if (textura.displayName.toLowerCase() == texto.toLowerCase() ||
          textura.name.toLowerCase() == texto.toLowerCase()) {
        return textura;
      }
    }
    return null;
  }

  ManejoSulco? _manejoDe(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    for (final manejo in ManejoSulco.values) {
      if (manejo.displayName.toLowerCase() == texto.toLowerCase() ||
          manejo.name.toLowerCase() == texto.toLowerCase()) {
        return manejo;
      }
    }
    return null;
  }

  bool _eCabecalho(List<String> linha) {
    if (linha.length < 3) return false;
    return linha[0].trim() == 'Seção' &&
        linha[1].trim() == 'Campo' &&
        linha[2].trim() == 'Valor';
  }

  double _numeroObrigatorio(String? valor, {required String campo}) {
    final numero = _numeroOpcional(valor);
    if (numero == null) {
      throw _mensagemFormato;
    }
    return numero;
  }

  double? _numeroOpcional(String? valor) {
    var texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    texto = texto
        .replaceFirst('\uFEFF', '')
        .replaceAll('\u00A0', ' ')
        .replaceAll(' ', '');
    if (texto.contains(',')) {
      // Padrão pt-BR: ponto de milhar (se houver) sai, vírgula vira ponto.
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(texto);
  }

  /// Analisa o CSV completo respeitando aspas: células entre `"..."` podem
  /// conter `;`, `"` dupla (`""`) e até quebra de linha. Linhas em branco
  /// são descartadas.
  List<List<String>> _tabela(String conteudo) {
    final tabela = <List<String>>[];
    final celula = StringBuffer();
    final linha = <String>[];
    var dentroAspas = false;

    void encerrarCelula() {
      linha.add(celula.toString());
      celula.clear();
    }

    void encerrarLinha() {
      encerrarCelula();
      if (linha.any((c) => c.trim().isNotEmpty)) tabela.add(linha.toList());
      linha.clear();
    }

    for (var i = 0; i < conteudo.length; i++) {
      final c = conteudo[i];
      if (dentroAspas) {
        if (c == '"') {
          if (i + 1 < conteudo.length && conteudo[i + 1] == '"') {
            celula.write('"');
            i++;
          } else {
            dentroAspas = false;
          }
        } else {
          celula.write(c);
        }
      } else if (c == '"') {
        dentroAspas = true;
      } else if (c == ';') {
        encerrarCelula();
      } else if (c == '\n') {
        encerrarLinha();
      } else if (c != '\r') {
        celula.write(c);
      }
    }
    if (celula.isNotEmpty || linha.isNotEmpty || dentroAspas) encerrarLinha();
    return tabela;
  }
}
