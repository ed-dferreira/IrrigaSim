import 'package:shared_preferences/shared_preferences.dart';
import 'tamanho_fonte.dart';

class PreferenciasApp {
  static SharedPreferences? _prefs;

  static const _keyTemaEscuro = 'tema_escuro';
  static const _keyAltoContraste = 'alto_contraste';
  static const _keyTextoNegrito = 'texto_negrito';
  static const _keyAnimacoesReduzidas = 'animacoes_reduzidas';
  static const _keyModoLeitorTela = 'modo_leitor_tela';
  static const _keyTamanhoFonte = 'tamanho_fonte';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferenciasApp.init() não foi chamado');
    }
    return _prefs!;
  }

  // Tema escuro
  static bool temaEscuro() => prefs.getBool(_keyTemaEscuro) ?? false;
  static Future<void> definirTemaEscuro(bool ativo) =>
      prefs.setBool(_keyTemaEscuro, ativo);

  // Alto contraste
  static bool altoContraste() => prefs.getBool(_keyAltoContraste) ?? false;
  static Future<void> definirAltoContraste(bool ativo) =>
      prefs.setBool(_keyAltoContraste, ativo);

  // Texto em negrito
  static bool textoNegrito() => prefs.getBool(_keyTextoNegrito) ?? false;
  static Future<void> definirTextoNegrito(bool ativo) =>
      prefs.setBool(_keyTextoNegrito, ativo);

  // Animações reduzidas
  static bool animacoesReduzidas() =>
      prefs.getBool(_keyAnimacoesReduzidas) ?? false;
  static Future<void> definirAnimacoesReduzidas(bool ativo) =>
      prefs.setBool(_keyAnimacoesReduzidas, ativo);

  // Modo leitor de tela
  static bool modoLeitorTela() => prefs.getBool(_keyModoLeitorTela) ?? false;
  static Future<void> definirModoLeitorTela(bool ativo) =>
      prefs.setBool(_keyModoLeitorTela, ativo);

  // Tamanho da fonte
  static TamanhoFonte tamanhoFonte() {
    final index = prefs.getInt(_keyTamanhoFonte) ?? TamanhoFonte.padrao.index;
    return TamanhoFonte.values[index.clamp(0, TamanhoFonte.values.length - 1)];
  }

  static Future<void> definirTamanhoFonte(TamanhoFonte tamanho) =>
      prefs.setInt(_keyTamanhoFonte, tamanho.index);

  // Limpar todas as preferências
  static Future<void> limpar() async {
    await prefs.remove(_keyTemaEscuro);
    await prefs.remove(_keyAltoContraste);
    await prefs.remove(_keyTextoNegrito);
    await prefs.remove(_keyAnimacoesReduzidas);
    await prefs.remove(_keyModoLeitorTela);
    await prefs.remove(_keyTamanhoFonte);
  }
}
