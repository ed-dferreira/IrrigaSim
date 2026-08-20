package com.irrigasim.ui.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// ─── Light Palette ───
// Todas as combinações texto/fundo cumprem WCAG AA (contraste mínimo 4.5:1)

// Primary (azul irrigação)
val PrimaryBlueLight = Color(0xFF0061A4)
val OnPrimaryLight = Color(0xFFFFFFFF)
val PrimaryContainerLight = Color(0xFFD1E4FF)
val OnPrimaryContainerLight = Color(0xFF001D36)

// Secondary (verde vegetação)
val SecondaryGreenLight = Color(0xFF006D36)
val OnSecondaryLight = Color(0xFFFFFFFF)
val SecondaryContainerLight = Color(0xFF94F9B3)
val OnSecondaryContainerLight = Color(0xFF00210C)

// Tertiary (verde-água / teal — apoio e indicadores informativos)
val TertiaryTealLight = Color(0xFF00696B)
val OnTertiaryLight = Color(0xFFFFFFFF)
val TertiaryContainerLight = Color(0xFF9CF1F0)
val OnTertiaryContainerLight = Color(0xFF002021)

// Error
val ErrorRedLight = Color(0xFFBA1A1A)
val OnErrorLight = Color(0xFFFFFFFF)
val ErrorContainerLight = Color(0xFFFFDAD6)
val OnErrorContainerLight = Color(0xFF410002)

// Backgrounds e superfícies
val BackgroundLight = Color(0xFFFDFBFF)
val OnBackgroundLight = Color(0xFF1A1C1E)
val SurfaceLight = Color(0xFFFDFBFF)
val OnSurfaceLight = Color(0xFF1A1C1E)
val SurfaceVariantLight = Color(0xFFDFE2EB)
val OnSurfaceVariantLight = Color(0xFF43474E)
val OutlineLight = Color(0xFF73777F)
val OutlineVariantLight = Color(0xFFC3C7CF)

// Inversos (snackbars, tooltips)
val InverseSurfaceLight = Color(0xFF2F3033)
val InverseOnSurfaceLight = Color(0xFFF1F0F4)
val InversePrimaryLight = Color(0xFF9ECAFF)

// ─── Dark Palette ───

// Primary (azul irrigação)
val PrimaryBlueDark = Color(0xFF9ECAFF)
val OnPrimaryDark = Color(0xFF003258)
val PrimaryContainerDark = Color(0xFF00497D)
val OnPrimaryContainerDark = Color(0xFFD1E4FF)

// Secondary (verde vegetação)
val SecondaryGreenDark = Color(0xFF78DC98)
val OnSecondaryDark = Color(0xFF003919)
val SecondaryContainerDark = Color(0xFF005227)
val OnSecondaryContainerDark = Color(0xFF94F9B3)

// Tertiary (verde-água / teal)
val TertiaryTealDark = Color(0xFF83D5D4)
val OnTertiaryDark = Color(0xFF003737)
val TertiaryContainerDark = Color(0xFF004F50)
val OnTertiaryContainerDark = Color(0xFF9CF1F0)

// Error
val ErrorRedDark = Color(0xFFFFB4AB)
val OnErrorDark = Color(0xFF690005)
val ErrorContainerDark = Color(0xFF93000A)
val OnErrorContainerDark = Color(0xFFFFDAD6)

// Backgrounds e superfícies
val BackgroundDark = Color(0xFF1A1C1E)
val OnBackgroundDark = Color(0xFFE2E2E6)
val SurfaceDark = Color(0xFF1A1C1E)
val OnSurfaceDark = Color(0xFFE2E2E6)
val SurfaceVariantDark = Color(0xFF43474E)
val OnSurfaceVariantDark = Color(0xFFC3C7CF)
val OutlineDark = Color(0xFF8D9199)
val OutlineVariantDark = Color(0xFF43474E)

// Inversos
val InverseSurfaceDark = Color(0xFFE2E2E6)
val InverseOnSurfaceDark = Color(0xFF2F3033)
val InversePrimaryDark = Color(0xFF0061A4)

// ─── Cores de status (sucesso, alerta, informação) ───
// Estendem o esquema Material 3 para indicadores de estado.
// Combinações color/onColor e container/onContainer ≥ 4.5:1 nos dois temas.

data class StatusColors(
    val success: Color,
    val onSuccess: Color,
    val successContainer: Color,
    val onSuccessContainer: Color,
    val warning: Color,
    val onWarning: Color,
    val warningContainer: Color,
    val onWarningContainer: Color,
    val info: Color,
    val onInfo: Color,
    val infoContainer: Color,
    val onInfoContainer: Color
)

val LightStatusColors = StatusColors(
    success = Color(0xFF146C2E),
    onSuccess = Color(0xFFFFFFFF),
    successContainer = Color(0xFFB6F2BB),
    onSuccessContainer = Color(0xFF002105),
    warning = Color(0xFF7E5800),
    onWarning = Color(0xFFFFFFFF),
    warningContainer = Color(0xFFFFE08D),
    onWarningContainer = Color(0xFF261A00),
    info = Color(0xFF006686),
    onInfo = Color(0xFFFFFFFF),
    infoContainer = Color(0xFFC2E8FF),
    onInfoContainer = Color(0xFF001E2C)
)

val DarkStatusColors = StatusColors(
    success = Color(0xFF82D793),
    onSuccess = Color(0xFF003914),
    successContainer = Color(0xFF005323),
    onSuccessContainer = Color(0xFF97F7A9),
    warning = Color(0xFFFFB959),
    onWarning = Color(0xFF4A2800),
    warningContainer = Color(0xFF5C4300),
    onWarningContainer = Color(0xFFFFDEA6),
    info = Color(0xFF7BD0F0),
    onInfo = Color(0xFF003549),
    infoContainer = Color(0xFF004D66),
    onInfoContainer = Color(0xFFBEE9FF)
)

val LocalStatusColors = staticCompositionLocalOf { LightStatusColors }

@Composable
fun statusColors(): StatusColors = LocalStatusColors.current

private val LightColorScheme = lightColorScheme(
    primary = PrimaryBlueLight,
    onPrimary = OnPrimaryLight,
    primaryContainer = PrimaryContainerLight,
    onPrimaryContainer = OnPrimaryContainerLight,
    secondary = SecondaryGreenLight,
    onSecondary = OnSecondaryLight,
    secondaryContainer = SecondaryContainerLight,
    onSecondaryContainer = OnSecondaryContainerLight,
    tertiary = TertiaryTealLight,
    onTertiary = OnTertiaryLight,
    tertiaryContainer = TertiaryContainerLight,
    onTertiaryContainer = OnTertiaryContainerLight,
    background = BackgroundLight,
    onBackground = OnBackgroundLight,
    surface = SurfaceLight,
    onSurface = OnSurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = OnSurfaceVariantLight,
    outline = OutlineLight,
    outlineVariant = OutlineVariantLight,
    inverseSurface = InverseSurfaceLight,
    inverseOnSurface = InverseOnSurfaceLight,
    inversePrimary = InversePrimaryLight,
    error = ErrorRedLight,
    onError = OnErrorLight,
    errorContainer = ErrorContainerLight,
    onErrorContainer = OnErrorContainerLight
)

private val DarkColorScheme = darkColorScheme(
    primary = PrimaryBlueDark,
    onPrimary = OnPrimaryDark,
    primaryContainer = PrimaryContainerDark,
    onPrimaryContainer = OnPrimaryContainerDark,
    secondary = SecondaryGreenDark,
    onSecondary = OnSecondaryDark,
    secondaryContainer = SecondaryContainerDark,
    onSecondaryContainer = OnSecondaryContainerDark,
    tertiary = TertiaryTealDark,
    onTertiary = OnTertiaryDark,
    tertiaryContainer = TertiaryContainerDark,
    onTertiaryContainer = OnTertiaryContainerDark,
    background = BackgroundDark,
    onBackground = OnBackgroundDark,
    surface = SurfaceDark,
    onSurface = OnSurfaceDark,
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = OnSurfaceVariantDark,
    outline = OutlineDark,
    outlineVariant = OutlineVariantDark,
    inverseSurface = InverseSurfaceDark,
    inverseOnSurface = InverseOnSurfaceDark,
    inversePrimary = InversePrimaryDark,
    error = ErrorRedDark,
    onError = OnErrorDark,
    errorContainer = ErrorContainerDark,
    onErrorContainer = OnErrorContainerDark
)

val AppTypography = Typography(
    headlineLarge = TextStyle(fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 36.sp),
    titleLarge = TextStyle(fontWeight = FontWeight.Bold, fontSize = 20.sp, lineHeight = 28.sp),
    titleMedium = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 24.sp),
    bodyLarge = TextStyle(fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 24.sp),
    bodyMedium = TextStyle(fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = TextStyle(fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp)
)

@Composable
fun IrrigaSIMTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    CompositionLocalProvider(
        LocalStatusColors provides if (darkTheme) DarkStatusColors else LightStatusColors
    ) {
        MaterialTheme(
            colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
            typography = AppTypography,
            content = content
        )
    }
}
