package com.irrigasim.data

import com.irrigasim.domain.Usuario
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/**
 * Implementação iOS do AuthRepository.
 * Usa Firebase Auth nativo do iOS via KMP.
 */
class AuthRepositoryIOS : AuthRepository {

    private var usuarioAtual: Usuario? = null

    override fun observarAutenticacao(): Flow<Usuario?> = flow {
        // TODO: Implementar com Firebase Auth iOS
        // Auth.auth().addStateListener { _, user in
        //     let usuario = user.map { Usuario(
        //         id: $0.uid,
        //         nome: $0.displayName ?? "",
        //         email: $0.email ?? "",
        //         instituicao: "",
        //         curso: ""
        //     )}
        //     continuation.resume(usuario)
        // }
        emit(usuarioAtual)
    }

    override suspend fun login(email: String, senha: String): Result<Usuario> {
        return try {
            // TODO: Implementar com Firebase Auth iOS
            // let result = try await Auth.auth().signIn(withEmail: email, password: senha)
            // let user = result.user
            // let usuario = Usuario(
            //     id: user.uid,
            //     nome: user.displayName ?? "",
            //     email: user.email ?? "",
            //     instituicao: "",
            //     curso: ""
            // )
            // usuarioAtual = usuario
            // return .success(usuario)

            // Placeholder
            val usuario = Usuario(
                id = "ios-${System.currentTimeMillis()}",
                nome = "Usuário iOS",
                email = email,
                instituicao = "UFLA",
                curso = "Agronomia"
            )
            usuarioAtual = usuario
            Result.success(usuario)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun criarConta(
        nome: String,
        email: String,
        senha: String,
        instituicao: String,
        curso: String
    ): Result<Usuario> {
        return try {
            // TODO: Implementar com Firebase Auth iOS
            // let result = try await Auth.auth().createUser(withEmail: email, password: senha)
            // let user = result.user
            // let changeRequest = user.createProfileChangeRequest()
            // changeRequest.displayName = nome
            // try await changeRequest.commitChanges()
            // let usuario = Usuario(
            //     id: user.uid,
            //     nome: nome,
            //     email: email,
            //     instituicao: instituicao,
            //     curso: curso
            // )
            // usuarioAtual = usuario
            // return .success(usuario)

            // Placeholder
            val usuario = Usuario(
                id = "ios-${System.currentTimeMillis()}",
                nome = nome,
                email = email,
                instituicao = instituicao,
                curso = curso
            )
            usuarioAtual = usuario
            Result.success(usuario)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun logout() {
        // TODO: Implementar com Firebase Auth iOS
        // try Auth.auth().signOut()
        usuarioAtual = null
    }

    override fun obterUsuarioAtual(): Usuario? {
        // TODO: Implementar com Firebase Auth iOS
        // guard let user = Auth.auth().currentUser else { return nil }
        // return Usuario(
        //     id: user.uid,
        //     nome: user.displayName ?? "",
        //     email: user.email ?? "",
        //     instituicao: "",
        //     curso: ""
        // )
        return usuarioAtual
    }

    override fun estaAutenticado(): Boolean {
        // TODO: Implementar com Firebase Auth iOS
        // return Auth.auth().currentUser != nil
        return usuarioAtual != null
    }
}
