package com.irrigasim.android

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.userProfileChangeRequest
import com.irrigasim.domain.Usuario
import com.irrigasim.ui.IrrigaSIMApp
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity : ComponentActivity() {

    private lateinit var auth: FirebaseAuth

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        auth = FirebaseAuth.getInstance()

        setContent {
            var currentUser by remember { mutableStateOf(auth.currentUser?.toUsuario()) }
            var authError by remember { mutableStateOf<String?>(null) }
            var authLoading by remember { mutableStateOf(false) }
            val scope = rememberCoroutineScope()

            IrrigaSIMApp(
                currentUser = currentUser,
                authError = authError,
                authLoading = authLoading,
                onClearError = { authError = null },

                onEmailSignIn = { email, senha ->
                    authLoading = true
                    authError = null
                    auth.signInWithEmailAndPassword(email, senha)
                        .addOnSuccessListener { currentUser = it.user?.toUsuario(); authLoading = false }
                        .addOnFailureListener { authError = traduzirErro(it); authLoading = false }
                },

                onEmailSignUp = { nome, email, instituicao, curso, senha ->
                    authLoading = true
                    authError = null
                    auth.createUserWithEmailAndPassword(email, senha)
                        .addOnSuccessListener { result ->
                            result.user?.updateProfile(
                                userProfileChangeRequest { displayName = nome }
                            )?.addOnCompleteListener {
                                currentUser = result.user?.toUsuario()?.copy(
                                    nome = nome, instituicao = instituicao, curso = curso
                                )
                                authLoading = false
                            }
                        }
                        .addOnFailureListener { authError = traduzirErro(it); authLoading = false }
                },

                onGoogleSignIn = {
                    scope.launch {
                        authLoading = true
                        authError = null
                        try {
                            val user = signInWithGoogle()
                            currentUser = user
                        } catch (e: Exception) {
                            Log.e("IrrigaSIM", "Google Sign-In failed", e)
                            authError = "Falha no login com Google: ${e.localizedMessage}"
                        }
                        authLoading = false
                    }
                },

                onSignOut = {
                    auth.signOut()
                    currentUser = null
                }
            )
        }
    }

    private suspend fun signInWithGoogle(): Usuario? {
        val credentialManager = CredentialManager.create(this)

        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(getString(R.string.default_web_client_id))
            .build()

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val result = credentialManager.getCredential(this, request)
        val credential = result.credential

        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
        val firebaseCredential = GoogleAuthProvider.getCredential(googleIdTokenCredential.idToken, null)

        val authResult = auth.signInWithCredential(firebaseCredential).await()
        return authResult.user?.toUsuario()
    }

    private fun traduzirErro(e: Exception): String {
        val msg = e.localizedMessage ?: e.message ?: "Erro desconhecido"
        return when {
            "INVALID_LOGIN_CREDENTIALS" in msg || "invalid" in msg.lowercase() -> "E-mail ou senha incorretos"
            "no user record" in msg.lowercase() -> "Conta não encontrada"
            "email already in use" in msg.lowercase() -> "Este e-mail já está cadastrado"
            "badly formatted" in msg.lowercase() -> "E-mail inválido"
            "weak password" in msg.lowercase() || "6 characters" in msg.lowercase() -> "A senha deve ter no mínimo 6 caracteres"
            "network" in msg.lowercase() -> "Sem conexão com a internet"
            else -> msg
        }
    }
}

private fun com.google.firebase.auth.FirebaseUser.toUsuario(): Usuario {
    return Usuario(
        uid = uid,
        nome = displayName ?: "",
        email = email ?: "",
        fotoUrl = photoUrl?.toString()
    )
}
