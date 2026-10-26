/// Caminhos e nomes canônicos das rotas do aplicativo.
///
/// As features devem navegar usando estas constantes em vez de repetir
/// strings. Os caminhos atuais são preservados para não quebrar deep links
/// nem testes durante a migração para arquitetura por features.
abstract final class AppRoutes {
  static const home = '/home';
  static const guiada = '/home/tutorial';

  static const irrigacao = '/home/irrigation';
  static const sulcosTipo = '/home/irrigation/tipo-sulco';
  static const sulcosProjeto = '/home/irrigation/project';
  static const sulcosResultados = '/home/irrigation/project-results';

  static const faixasProjeto = '/home/irrigation/border-project';
  static const faixasResultados = '/home/irrigation/border-results';

  static const inundacaoProjeto = '/home/irrigation/basin-project';
  static const inundacaoResultados = '/home/irrigation/basin-results';
  static const inundacaoReferencia = '/home/irrigation/basin-reference';

  static const cenarios = '/cenarios';
  static const perfil = '/perfil';

  /// Query param usado para abrir um cenário salvo diretamente na tela de
  /// projeto da feature responsável pelo método.
  static const cenarioId = 'cenarioId';
}
