import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/preferencias_app.dart';
import '../models/tamanho_fonte.dart';
import '../../authentication/models/user.dart';

class PerfilState {
  final bool editando;
  final String nome;
  final String instituicao;
  final String curso;
  final bool temaEscuro;
  final TamanhoFonte tamanhoFonte;
  final bool altoContraste;
  final bool textoNegrito;
  final bool animacoesReduzidas;
  final bool modoLeitorTela;
  final int totalSimulacoes;
  final String? metodoFavorito;

  const PerfilState({
    this.editando = false,
    this.nome = '',
    this.instituicao = '',
    this.curso = '',
    this.temaEscuro = false,
    this.tamanhoFonte = TamanhoFonte.medio,
    this.altoContraste = false,
    this.textoNegrito = false,
    this.animacoesReduzidas = false,
    this.modoLeitorTela = false,
    this.totalSimulacoes = 0,
    this.metodoFavorito,
  });

  PerfilState copyWith({
    bool? editando,
    String? nome,
    String? instituicao,
    String? curso,
    bool? temaEscuro,
    TamanhoFonte? tamanhoFonte,
    bool? altoContraste,
    bool? textoNegrito,
    bool? animacoesReduzidas,
    bool? modoLeitorTela,
    int? totalSimulacoes,
    String? metodoFavorito,
    bool clearMetodoFavorito = false,
  }) {
    return PerfilState(
      editando: editando ?? this.editando,
      nome: nome ?? this.nome,
      instituicao: instituicao ?? this.instituicao,
      curso: curso ?? this.curso,
      temaEscuro: temaEscuro ?? this.temaEscuro,
      tamanhoFonte: tamanhoFonte ?? this.tamanhoFonte,
      altoContraste: altoContraste ?? this.altoContraste,
      textoNegrito: textoNegrito ?? this.textoNegrito,
      animacoesReduzidas: animacoesReduzidas ?? this.animacoesReduzidas,
      modoLeitorTela: modoLeitorTela ?? this.modoLeitorTela,
      totalSimulacoes: totalSimulacoes ?? this.totalSimulacoes,
      metodoFavorito: clearMetodoFavorito
          ? null
          : (metodoFavorito ?? this.metodoFavorito),
    );
  }
}

class PerfilController extends StateNotifier<PerfilState> {
  User? _user;

  PerfilController()
    : super(
        PerfilState(
          temaEscuro: PreferenciasApp.temaEscuro(),
          tamanhoFonte: PreferenciasApp.tamanhoFonte(),
          altoContraste: PreferenciasApp.altoContraste(),
          textoNegrito: PreferenciasApp.textoNegrito(),
          animacoesReduzidas: PreferenciasApp.animacoesReduzidas(),
          modoLeitorTela: PreferenciasApp.modoLeitorTela(),
        ),
      );

  // ---- Edição do perfil ----

  void iniciarEdicao() {
    state = state.copyWith(editando: true);
  }

  void cancelarEdicao() {
    state = state.copyWith(
      editando: false,
      nome: _user?.nome ?? '',
      instituicao: _user?.instituicao ?? '',
      curso: _user?.curso ?? '',
    );
  }

  void salvarEdicao() {
    state = state.copyWith(editando: false);
    // TODO: Persistir no Firestore
  }

  void atualizarNome(String nome) {
    state = state.copyWith(nome: nome);
  }

  void atualizarInstituicao(String instituicao) {
    state = state.copyWith(instituicao: instituicao);
  }

  void atualizarCurso(String curso) {
    state = state.copyWith(curso: curso);
  }

  // ---- Acessibilidade ----

  void alternarTemaEscuro(bool ativo) {
    state = state.copyWith(temaEscuro: ativo);
    PreferenciasApp.definirTemaEscuro(ativo);
  }

  void definirTamanhoFonte(TamanhoFonte tamanho) {
    state = state.copyWith(tamanhoFonte: tamanho);
    PreferenciasApp.definirTamanhoFonte(tamanho);
  }

  void alternarAltoContraste(bool ativo) {
    state = state.copyWith(altoContraste: ativo);
    PreferenciasApp.definirAltoContraste(ativo);
  }

  void alternarTextoNegrito(bool ativo) {
    state = state.copyWith(textoNegrito: ativo);
    PreferenciasApp.definirTextoNegrito(ativo);
  }

  void alternarAnimacoesReduzidas(bool ativo) {
    state = state.copyWith(animacoesReduzidas: ativo);
    PreferenciasApp.definirAnimacoesReduzidas(ativo);
  }

  void alternarModoLeitorTela(bool ativo) {
    state = state.copyWith(modoLeitorTela: ativo);
    PreferenciasApp.definirModoLeitorTela(ativo);
  }

  // ---- Sincronização com conta ----

  void sincronizarCom(User? user) {
    _user = user;
    if (user == null || state.editando) return;
    state = state.copyWith(
      nome: user.nome ?? '',
      instituicao: user.instituicao ?? '',
      curso: user.curso ?? '',
    );
  }

  // ---- Estatísticas ----

  void atualizarEstatisticas(int totalSimulacoes, String? metodoFavorito) {
    state = state.copyWith(
      totalSimulacoes: totalSimulacoes,
      metodoFavorito: metodoFavorito,
    );
  }
}

final perfilProvider = StateNotifierProvider<PerfilController, PerfilState>((
  ref,
) {
  return PerfilController();
});
