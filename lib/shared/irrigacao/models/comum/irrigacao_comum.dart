/// Aula 5 (docs/Irrigacao_comum): método é a forma de aplicação;
/// sistema é o arranjo que a realiza. Nenhuma faixa didática é parâmetro
/// automático de dimensionamento.
enum MetodoAplicacao { superficie, aspersao, localizada, subsuperficie }

enum SistemaSuperficie { sulcos, faixas, inundacao }

enum PosicaoAplicacao { acimaDoSolo, sobreOSolo, abaixoDoSolo }

class IdentificacaoIrrigacao {
  final MetodoAplicacao metodo;
  final String sistema;
  final PosicaoAplicacao posicao;
  final bool aplicacaoLocalizada;

  const IdentificacaoIrrigacao({
    required this.metodo,
    required this.sistema,
    required this.posicao,
    this.aplicacaoLocalizada = false,
  });

  factory IdentificacaoIrrigacao.superficie(SistemaSuperficie sistema) =>
      IdentificacaoIrrigacao(
        metodo: MetodoAplicacao.superficie,
        sistema: sistema.name,
        posicao: PosicaoAplicacao.sobreOSolo,
      );

  Map<String, dynamic> toMap() => {
    'metodo': metodo.name,
    'sistema': sistema,
    'posicao': posicao.name,
    'aplicacao_localizada': aplicacaoLocalizada,
  };

  factory IdentificacaoIrrigacao.fromMap(Map<String, dynamic> map) =>
      IdentificacaoIrrigacao(
        metodo: MetodoAplicacao.values.byName(map['metodo'] as String),
        sistema: map['sistema'] as String,
        posicao: PosicaoAplicacao.values.byName(map['posicao'] as String),
        aplicacaoLocalizada: map['aplicacao_localizada'] as bool? ?? false,
      );
}

/// Dados observados, sem preenchimento artificial dos campos ausentes.
/// Unidades canônicas: m, %, g/cm³, mm/dia, L/s e minutos.
class CaracterizacaoArea {
  final double? comprimentoM, larguraM, declividadePercentual;
  final String? texturaSolo, cultura;
  final double? uccPercentual, upmpPercentual, densidadeGcm3;
  final double? profundidadeRaizesM, fracaoAguaDisponivel;
  final double? etoMmDia, etcMmDia, precipitacaoEfetivaMmDia;
  final double? vazaoDisponivelLs;

  const CaracterizacaoArea({
    this.comprimentoM,
    this.larguraM,
    this.declividadePercentual,
    this.texturaSolo,
    this.cultura,
    this.uccPercentual,
    this.upmpPercentual,
    this.densidadeGcm3,
    this.profundidadeRaizesM,
    this.fracaoAguaDisponivel,
    this.etoMmDia,
    this.etcMmDia,
    this.precipitacaoEfetivaMmDia,
    this.vazaoDisponivelLs,
  });

  Map<String, dynamic> toMap() => {
    'comprimento_m': comprimentoM,
    'largura_m': larguraM,
    'declividade_percentual': declividadePercentual,
    'textura_solo': texturaSolo,
    'cultura': cultura,
    'ucc_percentual': uccPercentual,
    'upmp_percentual': upmpPercentual,
    'densidade_g_cm3': densidadeGcm3,
    'profundidade_raizes_m': profundidadeRaizesM,
    'fracao_agua_disponivel': fracaoAguaDisponivel,
    'eto_mm_dia': etoMmDia,
    'etc_mm_dia': etcMmDia,
    'precipitacao_efetiva_mm_dia': precipitacaoEfetivaMmDia,
    'vazao_disponivel_ls': vazaoDisponivelLs,
  };

  factory CaracterizacaoArea.fromMap(Map<String, dynamic> map) {
    double? n(String key) => (map[key] as num?)?.toDouble();
    return CaracterizacaoArea(
      comprimentoM: n('comprimento_m'),
      larguraM: n('largura_m'),
      declividadePercentual: n('declividade_percentual'),
      texturaSolo: map['textura_solo'] as String?,
      cultura: map['cultura'] as String?,
      uccPercentual: n('ucc_percentual'),
      upmpPercentual: n('upmp_percentual'),
      densidadeGcm3: n('densidade_g_cm3'),
      profundidadeRaizesM: n('profundidade_raizes_m'),
      fracaoAguaDisponivel: n('fracao_agua_disponivel'),
      etoMmDia: n('eto_mm_dia'),
      etcMmDia: n('etc_mm_dia'),
      precipitacaoEfetivaMmDia: n('precipitacao_efetiva_mm_dia'),
      vazaoDisponivelLs: n('vazao_disponivel_ls'),
    );
  }
}

/// Observação comum de avanço e recessão; recessão é instante absoluto.
class EstacaEnsaio {
  final double distanciaM, avancoMin;
  final double? recessaoMin;

  const EstacaEnsaio(this.distanciaM, this.avancoMin, {this.recessaoMin});

  Map<String, dynamic> toMap() => {
    'distancia_m': distanciaM,
    'avanco_min': avancoMin,
    'recessao_min': recessaoMin,
  };

  factory EstacaEnsaio.fromMap(Map<String, dynamic> map) => EstacaEnsaio(
    (map['distancia_m'] as num).toDouble(),
    (map['avanco_min'] as num).toDouble(),
    recessaoMin: (map['recessao_min'] as num?)?.toDouble(),
  );
}

/// Leituras possíveis de infiltração: cada campanha informa somente as
/// grandezas medidas (entrada/saída ou lâmina acumulada).
class MedicaoInfiltracaoComum {
  final double tempoMin;
  final double? vazaoEntradaLs, vazaoSaidaLs, laminaAcumuladaMm;

  const MedicaoInfiltracaoComum({
    required this.tempoMin,
    this.vazaoEntradaLs,
    this.vazaoSaidaLs,
    this.laminaAcumuladaMm,
  });

  Map<String, dynamic> toMap() => {
    'tempo_min': tempoMin,
    'vazao_entrada_ls': vazaoEntradaLs,
    'vazao_saida_ls': vazaoSaidaLs,
    'lamina_acumulada_mm': laminaAcumuladaMm,
  };

  factory MedicaoInfiltracaoComum.fromMap(Map<String, dynamic> map) =>
      MedicaoInfiltracaoComum(
        tempoMin: (map['tempo_min'] as num).toDouble(),
        vazaoEntradaLs: (map['vazao_entrada_ls'] as num?)?.toDouble(),
        vazaoSaidaLs: (map['vazao_saida_ls'] as num?)?.toDouble(),
        laminaAcumuladaMm: (map['lamina_acumulada_mm'] as num?)?.toDouble(),
      );
}

/// Representação de ensaio, sem presumir que os métodos compartilham o
/// mesmo ajuste ou as mesmas unidades dos coeficientes de infiltração.
class EnsaioComum {
  final List<EstacaEnsaio> estacas;
  final List<MedicaoInfiltracaoComum> medicoesInfiltracao;
  final String? origemInfiltracao;
  final String? equacaoInfiltracao;
  final DateTime? data;

  const EnsaioComum({
    this.estacas = const [],
    this.medicoesInfiltracao = const [],
    this.origemInfiltracao,
    this.equacaoInfiltracao,
    this.data,
  });

  Map<String, dynamic> toMap() => {
    'estacas': estacas.map((e) => e.toMap()).toList(),
    'medicoes_infiltracao': medicoesInfiltracao.map((e) => e.toMap()).toList(),
    'origem_infiltracao': origemInfiltracao,
    'equacao_infiltracao': equacaoInfiltracao,
    'data': data?.toIso8601String(),
  };

  factory EnsaioComum.fromMap(Map<String, dynamic> map) => EnsaioComum(
    estacas: (map['estacas'] as List<dynamic>? ?? const [])
        .map((e) => EstacaEnsaio.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    medicoesInfiltracao:
        (map['medicoes_infiltracao'] as List<dynamic>? ?? const [])
            .map(
              (e) => MedicaoInfiltracaoComum.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
    origemInfiltracao: map['origem_infiltracao'] as String?,
    equacaoInfiltracao: map['equacao_infiltracao'] as String?,
    data: DateTime.tryParse(map['data'] as String? ?? ''),
  );
}

class BaseIrrigacao {
  final IdentificacaoIrrigacao identificacao;
  final CaracterizacaoArea area;
  final EnsaioComum? ensaio;

  const BaseIrrigacao({
    required this.identificacao,
    required this.area,
    this.ensaio,
  });

  Map<String, dynamic> toMap() => {
    'identificacao': identificacao.toMap(),
    'area': area.toMap(),
    'ensaio': ensaio?.toMap(),
  };

  factory BaseIrrigacao.fromMap(Map<String, dynamic> map) => BaseIrrigacao(
    identificacao: IdentificacaoIrrigacao.fromMap(
      Map<String, dynamic>.from(map['identificacao'] as Map),
    ),
    area: CaracterizacaoArea.fromMap(
      Map<String, dynamic>.from(map['area'] as Map),
    ),
    ensaio: map['ensaio'] is Map
        ? EnsaioComum.fromMap(Map<String, dynamic>.from(map['ensaio'] as Map))
        : null,
  );
}
