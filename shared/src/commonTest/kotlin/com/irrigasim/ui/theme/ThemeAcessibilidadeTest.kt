package com.irrigasim.ui.theme

import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import com.irrigasim.data.TamanhoFonte
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class ThemeAcessibilidadeTest {

    // ---- Escala de fonte ---------------------------------------------------

    @Test
    fun escalaPadraoMantemTipografiaBase() {
        val tipografia = tipografiaAcessivel(TamanhoFonte.MEDIO.escala, negrito = false)

        assertEquals(AppTypography.bodyLarge.fontSize, tipografia.bodyLarge.fontSize)
        assertEquals(AppTypography.headlineLarge.lineHeight, tipografia.headlineLarge.lineHeight)
        assertEquals(AppTypography.titleMedium.fontWeight, tipografia.titleMedium.fontWeight)
    }

    @Test
    fun escalaDeFonteAmpliaTamanhoEAlturaDeLinha() {
        val escala = TamanhoFonte.GRANDE.escala
        val tipografia = tipografiaAcessivel(escala, negrito = false)

        assertEquals(AppTypography.bodyLarge.fontSize * escala, tipografia.bodyLarge.fontSize)
        assertEquals(AppTypography.bodyLarge.lineHeight * escala, tipografia.bodyLarge.lineHeight)
        assertEquals(AppTypography.headlineLarge.fontSize * escala, tipografia.headlineLarge.fontSize)
    }

    @Test
    fun negritoForcaPesoBoldEmTodosOsEstilos() {
        val tipografia = tipografiaAcessivel(1f, negrito = true)

        assertEquals(FontWeight.Bold, tipografia.bodyLarge.fontWeight)
        assertEquals(FontWeight.Bold, tipografia.bodyMedium.fontWeight)
        assertEquals(FontWeight.Bold, tipografia.labelLarge.fontWeight)
        assertEquals(FontWeight.Bold, tipografia.titleMedium.fontWeight)
    }

    @Test
    fun escalasDosTamanhosSaoCrescentesEMedioEhNeutro() {
        assertEquals(1f, TamanhoFonte.MEDIO.escala)
        assertTrue(TamanhoFonte.PEQUENO.escala < TamanhoFonte.MEDIO.escala)
        assertTrue(TamanhoFonte.MEDIO.escala < TamanhoFonte.GRANDE.escala)
        assertTrue(TamanhoFonte.GRANDE.escala < TamanhoFonte.MUITO_GRANDE.escala)
    }

    @Test
    fun fromNameConverteNomePersistidoEFallbackAoPadrao() {
        assertEquals(TamanhoFonte.GRANDE, TamanhoFonte.fromName("GRANDE"))
        assertEquals(TamanhoFonte.PADRAO, TamanhoFonte.fromName("valor_desconhecido"))
    }

    // ---- Alto contraste ----------------------------------------------------

    @Test
    fun altoContrasteClaroUsaPretoSobreBranco() {
        val base = lightColorScheme()
        val hc = esquemaAltoContraste(base, escuro = false)

        assertEquals(Color.White, hc.background)
        assertEquals(Color.Black, hc.onBackground)
        assertEquals(Color.White, hc.surface)
        assertEquals(Color.Black, hc.onSurface)
    }

    @Test
    fun altoContrasteEscuroUsaBrancoSobrePreto() {
        val base = lightColorScheme()
        val hc = esquemaAltoContraste(base, escuro = true)

        assertEquals(Color.Black, hc.background)
        assertEquals(Color.White, hc.onBackground)
        assertEquals(Color.Black, hc.surface)
        assertEquals(Color.White, hc.onSurface)
    }

    @Test
    fun altoContrastePreservaCoresDaMarca() {
        val base = lightColorScheme(primary = Color.Red)
        val hc = esquemaAltoContraste(base, escuro = false)

        assertEquals(base.primary, hc.primary)
        assertNotEquals(base.background, hc.background)
    }
}
