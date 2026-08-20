package com.irrigasim.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.AddCircle
import androidx.compose.material.icons.rounded.Agriculture
import androidx.compose.material.icons.rounded.Assignment
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.CalendarToday
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Grain
import androidx.compose.material.icons.rounded.Layers
import androidx.compose.material.icons.rounded.MenuBook
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.RocketLaunch
import androidx.compose.material.icons.rounded.Save
import androidx.compose.material.icons.rounded.Straighten
import androidx.compose.material.icons.rounded.Summarize
import androidx.compose.material.icons.rounded.Terrain
import androidx.compose.material.icons.rounded.Visibility
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.material.icons.rounded.Water
import androidx.compose.material.icons.rounded.WaterDrop
import androidx.compose.material.icons.rounded.WavingHand
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Constantes centrais de ícones do IrrigaSIM.
 *
 * Padroniza o uso de Material Icons (estilo Rounded) em toda a interface,
 * substituindo emojis por ícones vetoriais com renderização consistente
 * entre plataformas e interpretáveis por leitores de tela.
 */
object AppIcons {
    // Marca e navegação inferior
    val LogoApp: ImageVector = Icons.Rounded.WaterDrop
    val NavSimulacao: ImageVector = Icons.Rounded.WaterDrop
    val NavCenarios: ImageVector = Icons.Rounded.Assignment
    val NavPerfil: ImageVector = Icons.Rounded.Person

    // Métodos de irrigação por superfície
    val Sulco: ImageVector = Icons.Rounded.Agriculture
    val Faixa: ImageVector = Icons.Rounded.Straighten
    val Inundacao: ImageVector = Icons.Rounded.Water

    // Guia didático / tutorial
    val GuiaDidatico: ImageVector = Icons.Rounded.MenuBook
    val Saudacao: ImageVector = Icons.Rounded.WavingHand
    val PularTutorial: ImageVector = Icons.Rounded.Bolt

    // Presets de solo (Kostiakov-Lewis)
    val SoloArenoso: ImageVector = Icons.Rounded.Grain
    val SoloFranco: ImageVector = Icons.Rounded.Layers
    val SoloArgiloso: ImageVector = Icons.Rounded.Terrain

    // Simulação
    val Simular: ImageVector = Icons.Rounded.PlayArrow
    val ExecutarSimulacao: ImageVector = Icons.Rounded.RocketLaunch
    val ResumoConfiguracao: ImageVector = Icons.Rounded.Summarize
    val Declividade: ImageVector = Icons.Rounded.Straighten

    // Resultados
    val DesempenhoExcelente: ImageVector = Icons.Rounded.EmojiEvents
    val Atencao: ImageVector = Icons.Rounded.Warning
    val SalvarCenario: ImageVector = Icons.Rounded.Save
    val Sucesso: ImageVector = Icons.Rounded.CheckCircle

    // Histórico de cenários
    val NovoCenario: ImageVector = Icons.Rounded.Add
    val CriarNovaSimulacao: ImageVector = Icons.Rounded.AddCircle
    val DataSalvamento: ImageVector = Icons.Rounded.CalendarToday
    val VisualizarCenario: ImageVector = Icons.Rounded.Visibility
    val ExcluirCenario: ImageVector = Icons.Rounded.Delete

    // Perfil e autenticação
    val EditarPerfil: ImageVector = Icons.Rounded.Edit
    val FecharErro: ImageVector = Icons.Rounded.Close
}
