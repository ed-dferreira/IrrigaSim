import 'package:flutter/widgets.dart';

/// Assunto usado para agrupar os artigos no índice do tutorial.
enum CategoriaTutorial {
  primeirosPassos('Primeiros passos'),
  metodos('Métodos de irrigação'),
  resultados('Resultados'),
  cenarios('Cenários'),
  perfil('Perfil e acessibilidade');

  const CategoriaTutorial(this.titulo);

  final String titulo;
}

/// Um artigo do manual de operação do aplicativo.
class ArtigoTutorial {
  const ArtigoTutorial({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.categoria,
    required this.icone,
    required this.secoes,
    this.atalhos = const [],
  });

  final String id;
  final String titulo;
  final String resumo;
  final CategoriaTutorial categoria;
  final IconData icone;
  final List<SecaoTutorial> secoes;
  final List<AtalhoTutorial> atalhos;
}

/// Bloco de leitura de um artigo.
class SecaoTutorial {
  const SecaoTutorial({
    required this.titulo,
    this.paragrafos = const [],
    this.passos = const [],
  });

  final String titulo;
  final List<String> paragrafos;
  final List<String> passos;
}

/// Atalho para uma tela real do aplicativo.
class AtalhoTutorial {
  const AtalhoTutorial({
    required this.rotulo,
    required this.descricao,
    required this.rota,
    required this.icone,
  });

  final String rotulo;
  final String descricao;
  final String rota;
  final IconData icone;
}
