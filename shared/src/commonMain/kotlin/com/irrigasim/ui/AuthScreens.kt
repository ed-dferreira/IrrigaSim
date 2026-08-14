package com.irrigasim.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun LoginScreen(
    onLogin: (String, String) -> Unit, onGoogleSignIn: () -> Unit = {},
    onCadastro: () -> Unit = {}, errorMessage: String? = null,
    isLoading: Boolean = false, onClearError: () -> Unit = {}
) {
    var email by remember { mutableStateOf("") }
    var senha by remember { mutableStateOf("") }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.fillMaxWidth().height(240.dp).background(Brush.verticalGradient(listOf(MaterialTheme.colorScheme.primary, MaterialTheme.colorScheme.primaryContainer))), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(80.dp).clip(CircleShape).background(MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.2f)), contentAlignment = Alignment.Center) { Text("💧", fontSize = 42.sp) }
                Spacer(Modifier.height(16.dp))
                Text("IrrigaSIM", color = MaterialTheme.colorScheme.onPrimaryContainer, style = MaterialTheme.typography.headlineLarge)
                Text("Simulação de Irrigação por Superfície", color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f), style = MaterialTheme.typography.bodyMedium)
            }
        }
        Column(Modifier.padding(24.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text("Entrar na sua conta", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onBackground)
            if (errorMessage != null) {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("⚠ $errorMessage", color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                        Text("✕", color = MaterialTheme.colorScheme.onErrorContainer, modifier = Modifier.clickable { onClearError() }.padding(8.dp))
                    }
                }
            }
            OutlinedTextField(email, { email = it }, label = { Text("E-mail") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
            OutlinedTextField(senha, { senha = it }, label = { Text("Senha") }, modifier = Modifier.fillMaxWidth(), singleLine = true, visualTransformation = PasswordVisualTransformation(), shape = RoundedCornerShape(12.dp))
            Button({ onLogin(email.trim(), senha) }, Modifier.fillMaxWidth().height(54.dp), enabled = email.isNotBlank() && senha.length >= 6 && !isLoading, shape = RoundedCornerShape(12.dp)) {
                if (isLoading) CircularProgressIndicator(Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp) else Text("Entrar", style = MaterialTheme.typography.titleMedium)
            }
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f).height(1.dp).background(MaterialTheme.colorScheme.outlineVariant))
                Text("  ou  ", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.labelLarge)
                Box(Modifier.weight(1f).height(1.dp).background(MaterialTheme.colorScheme.outlineVariant))
            }
            OutlinedButton(onGoogleSignIn, Modifier.fillMaxWidth().height(54.dp), enabled = !isLoading, shape = RoundedCornerShape(12.dp), border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outline)) {
                Text("G", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.width(12.dp))
                Text("Entrar com Google", color = MaterialTheme.colorScheme.onSurface, style = MaterialTheme.typography.titleMedium)
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                Text("Não tem conta? ", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyLarge)
                Text("Criar conta", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium, modifier = Modifier.clickable { onCadastro() }.padding(horizontal = 4.dp))
            }
        }
    }
}

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
