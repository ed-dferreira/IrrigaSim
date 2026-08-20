package com.irrigasim.ui.screens.auth

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp

@Composable
fun CadastroScreen(
    onCadastrar: (String, String, String, String, String) -> Unit, onVoltar: () -> Unit,
    errorMessage: String? = null, isLoading: Boolean = false, onClearError: () -> Unit = {}
) {
    var nome by remember { mutableStateOf("") }; var email by remember { mutableStateOf("") }
    var instituicao by remember { mutableStateOf("") }; var curso by remember { mutableStateOf("") }
    var senha by remember { mutableStateOf("") }; var confirmaSenha by remember { mutableStateOf("") }
    var aceitouTermos by remember { mutableStateOf(false) }
    val senhasIguais = senha == confirmaSenha
    val formValido = nome.isNotBlank() && email.contains("@") && senha.length >= 6 && senhasIguais && aceitouTermos
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Surface(color = MaterialTheme.colorScheme.primary, shadowElevation = 4.dp) {
            Row(Modifier.fillMaxWidth().padding(16.dp).height(48.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("←", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.clickable { onVoltar() }.padding(end = 16.dp))
                Text("Criar Conta", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onPrimary)
            }
        }
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (errorMessage != null) {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("⚠ $errorMessage", color = MaterialTheme.colorScheme.onErrorContainer, modifier = Modifier.weight(1f))
                        Text("✕", color = MaterialTheme.colorScheme.onErrorContainer, modifier = Modifier.clickable { onClearError() }.padding(8.dp))
                    }
                }
            }
            OutlinedTextField(nome, { nome = it }, label = { Text("Nome completo") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
            OutlinedTextField(email, { email = it }, label = { Text("E-mail") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
            OutlinedTextField(instituicao, { instituicao = it }, label = { Text("Instituição (ex: UFLA)") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
            OutlinedTextField(curso, { curso = it }, label = { Text("Curso (ex: Agronomia)") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
            OutlinedTextField(senha, { senha = it }, label = { Text("Senha (mín. 6 caracteres)") }, modifier = Modifier.fillMaxWidth(), singleLine = true, visualTransformation = PasswordVisualTransformation(), shape = RoundedCornerShape(12.dp))
            OutlinedTextField(confirmaSenha, { confirmaSenha = it }, label = { Text("Confirmar senha") }, modifier = Modifier.fillMaxWidth(), singleLine = true, visualTransformation = PasswordVisualTransformation(), isError = confirmaSenha.isNotEmpty() && !senhasIguais, shape = RoundedCornerShape(12.dp), supportingText = if (confirmaSenha.isNotEmpty() && !senhasIguais) {{ Text("As senhas não coincidem") }} else null)
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth().clickable { aceitouTermos = !aceitouTermos }.padding(vertical = 8.dp)) {
                Checkbox(aceitouTermos, { aceitouTermos = it })
                Text("Aceito os Termos de Uso e Política de Privacidade", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onBackground)
            }
            Button({ onCadastrar(nome.trim(), email.trim(), instituicao.trim(), curso.trim(), senha) }, Modifier.fillMaxWidth().height(54.dp), enabled = formValido && !isLoading, shape = RoundedCornerShape(12.dp)) {
                if (isLoading) CircularProgressIndicator(Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp) else Text("Finalizar Cadastro", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}
