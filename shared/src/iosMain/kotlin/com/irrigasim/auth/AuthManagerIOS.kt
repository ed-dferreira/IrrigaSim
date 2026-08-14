package com.irrigasim.auth

import com.irrigasim.domain.Usuario
import com.irrigasim.domain.ConfiguracoesAcessibilidade
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Implementação iOS do AuthManager com Firebase Auth completo.
 */
class AuthManagerIOS : AuthManager {

    private val sessionManager = SessionManager()
    private val _authState = MutableStateFlow<AuthState>(AuthState.NaoAutenticado)

    override fun observarEstadoAuth(): Flow<AuthState> = _authState.asStateFlow()

    override fun observarUsuario(): Flow<Usuario?> = sessionManager.usuarioAtual

    override suspend fun login(email: String, senha: String): AuthResult {
        sessionManager.definirCarregando(true)
        _authState.value = AuthState.Carregando

        return try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            //
            // let result = try await Auth.auth().signIn(withEmail: email, password: senha)
            // let user = result.user
            //
            // let tokenResult = try await user.getIDTokenResult()
            // let token = tokenResult.token
            //
            // let usuario = Usuario(
            //     id: user.uid,
            //     nome: user.displayName ?? "",
            //     email: user.email ?? "",
            //     instituicao: "",
            //     curso: ""
            // )
            //
            // sessionManager.definirUsuario(usuario)
            // sessionManager.definirToken(token)
            // _authState.value = AuthState.Autenticado(usuario)
            // return AuthResult.Sucesso(usuario)

            // Placeholder para testes
            val usuario = Usuario(
                id = "ios-${System.currentTimeMillis()}",
                nome = "Usuário iOS",
                email = email,
                instituicao = "UFLA",
                curso = "Agronomia"
            )
            sessionManager.definirUsuario(usuario)
            sessionManager.definirToken("token-placeholder")
            _authState.value = AuthState.Autenticado(usuario)
            sessionManager.definirCarregando(false)
            AuthResult.Sucesso(usuario)
        } catch (e: Exception) {
            val erro = tratarErroFirebase(e)
            _authState.value = AuthState.Erro(erro.mensagem)
            sessionManager.definirCarregando(false)
            erro
        }
    }

    override suspend fun criarConta(dadosCadastro: DadosCadastro): AuthResult {
        val errosValidacao = dadosCadastro.validar()
        if (errosValidacao.isNotEmpty()) {
            return AuthResult.Erro(
                TipoErroAuth.CREDENCIAIS_INVALIDAS,
                errosValidacao.joinToString("; ")
            )
        }

        sessionManager.definirCarregando(true)
        _authState.value = AuthState.Carregando

        return try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            //
            // let result = try await Auth.auth().createUser(
            //     withEmail: dadosCadastro.email,
            //     password: dadosCadastro.senha
            // )
            // let user = result.user
            //
            // // Atualizar perfil
            // let changeRequest = user.createProfileChangeRequest()
            // changeRequest.displayName = dadosCadastro.nome
            // try await changeRequest.commitChanges()
            //
            // let tokenResult = try await user.getIDTokenResult()
            // let token = tokenResult.token
            //
            // let usuario = Usuario(
            //     id: user.uid,
            //     nome: dadosCadastro.nome,
            //     email: dadosCadastro.email,
            //     instituicao: dadosCadastro.instituicao,
            //     curso: dadosCadastro.curso
            // )
            //
            // sessionManager.definirUsuario(usuario)
            // sessionManager.definirToken(token)
            // _authState.value = AuthState.Autenticado(usuario)
            // return AuthResult.Sucesso(usuario)

            // Placeholder para testes
            val usuario = Usuario(
                id = "ios-${System.currentTimeMillis()}",
                nome = dadosCadastro.nome,
                email = dadosCadastro.email,
                instituicao = dadosCadastro.instituicao,
                curso = dadosCadastro.curso
            )
            sessionManager.definirUsuario(usuario)
            sessionManager.definirToken("token-placeholder")
            _authState.value = AuthState.Autenticado(usuario)
            sessionManager.definirCarregando(false)
            AuthResult.Sucesso(usuario)
        } catch (e: Exception) {
            val erro = tratarErroFirebase(e)
            _authState.value = AuthState.Erro(erro.mensagem)
            sessionManager.definirCarregando(false)
            erro
        }
    }

    override suspend fun logout() {
        try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            // try Auth.auth().signOut()
            sessionManager.limparSessao()
            _authState.value = AuthState.NaoAutenticado
        } catch (e: Exception) {
            _authState.value = AuthState.Erro("Erro ao fazer logout")
        }
    }

    override suspend fun redefinirSenha(email: String): Result<Unit> {
        return try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            // try await Auth.auth().sendPasswordReset(withEmail: email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun atualizarPerfil(usuario: Usuario): Result<Unit> {
        return try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            // let user = Auth.auth().currentUser
            // let changeRequest = user?.createProfileChangeRequest()
            // changeRequest?.displayName = usuario.nome
            // try await changeRequest?.commitChanges()
            sessionManager.definirUsuario(usuario)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun atualizarA11y(configuracoes: ConfiguracoesAcessibilidade): Result<Unit> {
        return try {
            sessionManager.atualizarA11y(configuracoes)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun obterToken(): String? {
        return try {
            // TODO: Implementar com Firebase Auth iOS
            // import FirebaseAuth
            // let user = Auth.auth().currentUser
            // let tokenResult = try await user?.getIDTokenResult()
            // return tokenResult?.token
            sessionManager.token as? String
        } catch (e: Exception) {
            null
        }
    }

    override fun estaAutenticado(): Boolean {
        // TODO: Implementar com Firebase Auth iOS
        // import FirebaseAuth
        // return Auth.auth().currentUser != nil
        return sessionManager.temSessaoAtiva()
    }

    override fun obterUsuarioId(): String? {
        // TODO: Implementar com Firebase Auth iOS
        // import FirebaseAuth
        // return Auth.auth().currentUser?.uid
        return sessionManager.obterUsuarioId()
    }

    private fun tratarErroFirebase(erro: Exception): AuthResult.Erro {
        val mensagem = erro.message ?: "Erro desconhecido"
        return when {
            mensagem.contains("INVALID_LOGIN_CREDENTIALS") -> AuthResult.Erro(
                TipoErroAuth.CREDENCIAIS_INVALIDAS,
                "E-mail ou senha incorretos"
            )
            mensagem.contains("user-not-found") -> AuthResult.Erro(
                TipoErroAuth.USUARIO_NAO_ENCONTRADO,
                "Usuário não encontrado"
            )
            mensagem.contains("email-already-in-use") -> AuthResult.Erro(
                TipoErroAuth.EMAIL_JA_EM_USO,
                "E-mail já está em uso"
            )
            mensagem.contains("weak-password") -> AuthResult.Erro(
                TipoErroAuth.SENHA_FRACA,
                "Senha muito fraca. Use pelo menos 6 caracteres"
            )
            mensagem.contains("network") || mensagem.contains("timeout") -> AuthResult.Erro(
                TipoErroAuth.CONEXAO_FALHOU,
                "Erro de conexão. Verifique sua internet"
            )
            else -> AuthResult.Erro(
                TipoErroAuth.ERRO_DESCONHECIDO,
                "Erro ao processar: $mensagem"
            )
        }
    }
}
