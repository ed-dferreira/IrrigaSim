import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/features/tutorial/content/manual_operacao.dart';
import 'package:irrigasim/features/tutorial/models/artigo_tutorial.dart';

void main() {
  test('IDs são únicos e todo artigo tem conteúdo', () {
    final ids = manualOperacao.map((artigo) => artigo.id).toList();
    expect(ids.toSet().length, ids.length);

    for (final artigo in manualOperacao) {
      expect(artigo.id.trim(), isNotEmpty);
      expect(artigo.titulo.trim(), isNotEmpty, reason: artigo.id);
      expect(artigo.resumo.trim(), isNotEmpty, reason: artigo.id);
      expect(artigo.secoes, isNotEmpty, reason: artigo.id);
      for (final secao in artigo.secoes) {
        expect(secao.titulo.trim(), isNotEmpty, reason: artigo.id);
        expect(
          secao.paragrafos.isNotEmpty || secao.passos.isNotEmpty,
          isTrue,
          reason: '${artigo.id}/${secao.titulo}',
        );
      }
    }
  });

  test('todas as categorias têm pelo menos um artigo', () {
    for (final categoria in CategoriaTutorial.values) {
      expect(artigosDaCategoria(categoria), isNotEmpty, reason: categoria.name);
    }
  });

  test('atalhos apontam para rotas conhecidas', () {
    const rotasConhecidas = {
      AppRoutes.home,
      AppRoutes.sulcosTipo,
      AppRoutes.sulcosProjeto,
      AppRoutes.sulcosResultados,
      AppRoutes.faixasProjeto,
      AppRoutes.faixasResultados,
      AppRoutes.inundacaoProjeto,
      AppRoutes.inundacaoResultados,
      AppRoutes.inundacaoReferencia,
      AppRoutes.cenarios,
      AppRoutes.perfil,
    };

    for (final artigo in manualOperacao) {
      for (final atalho in artigo.atalhos) {
        expect(atalho.rotulo.trim(), isNotEmpty, reason: artigo.id);
        expect(atalho.descricao.trim(), isNotEmpty, reason: artigo.id);
        expect(
          rotasConhecidas,
          contains(atalho.rota),
          reason: '${artigo.id}/${atalho.rotulo}',
        );
      }
    }
  });

  test('busca artigo por ID e devolve null para desconhecido', () {
    expect(buscarArtigoTutorial('sulcos')?.titulo, 'Sulcos');
    expect(buscarArtigoTutorial('inexistente'), isNull);
  });
}
