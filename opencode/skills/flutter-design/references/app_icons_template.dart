// TEMPLATE — registro central de ícones.
// Regras:
// - NUNCA espalhe `Icons.xxx` direto pelos widgets. Toda tela referencia
//   `AppIcons.algumNome`, nunca `Icons.algumNome` diretamente.
// - Agrupe por domínio/feature com um comentário de seção
//   ("==== NOME DA SEÇÃO ===="), não por tipo de ícone. Isso faz o arquivo
//   servir como um mapa do produto: dá pra entender as telas do app só
//   lendo os nomes dos grupos.
// - Prefira a família `_rounded` (ou a família equivalente do estilo visual
//   do projeto) para manter consistência visual — não misture estilos de
//   ícone (rounded, outlined, sharp) no mesmo app.
// - Nomeie pela INTENÇÃO/AÇÃO ("salvarCenario", "excluirCenario"), não pelo
//   ícone em si ("saveIcon", "trashIcon") — o nome deve sobreviver a uma
//   troca de ícone.
// - Mantenha uma seção "genérica" no fim só para ícones realmente
//   reutilizados sem contexto de feature (home, histórico, etc.).

import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  // ==================== MARCA & NAVEGAÇÃO ====================
  static const logoApp = Icons.circle_rounded; // substitua pelo símbolo da marca
  static const navPrincipal = Icons.home_rounded;
  static const navHistorico = Icons.history_rounded;
  static const navPerfil = Icons.person_rounded;

  // ==================== [SUBSTITUA PELO NOME DA FEATURE] ====================
  // Ex.: se o app tem um fluxo de "simulação", agrupe aqui todos os ícones
  // usados nesse fluxo, na ordem em que aparecem nas telas.

  // ==================== AÇÕES DE FORMULÁRIO / FLUXO ====================
  static const confirmar = Icons.check_circle_rounded;
  static const cancelar = Icons.close_rounded;
  static const editar = Icons.edit_rounded;
  static const excluir = Icons.delete_rounded;
  static const salvar = Icons.save_rounded;
  static const adicionar = Icons.add_rounded;

  // ==================== FEEDBACK / STATUS ====================
  static const sucesso = Icons.check_circle_rounded;
  static const atencao = Icons.warning_rounded;
  static const erro = Icons.error_rounded;

  // ==================== ACESSIBILIDADE ====================
  static const temaEscuro = Icons.dark_mode_rounded;
  static const altoContraste = Icons.contrast_rounded;
  static const textoNegrito = Icons.format_bold_rounded;
  static const tamanhoFonte = Icons.format_size_rounded;
  static const animacoesReduzidas = Icons.slow_motion_video_rounded;
  static const leitorDeTela = Icons.record_voice_over_rounded;

  // ==================== GENÉRICOS ====================
  static const home = Icons.home_rounded;
  static const history = Icons.history_rounded;
  static const profile = Icons.person_rounded;
  static const chart = Icons.bar_chart_rounded;
}
