package com.irrigasim.ui.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// ─── Light Palette ───
val PrimaryBlueLight = Color(0xFF0061A4)
val OnPrimaryLight = Color(0xFFFFFFFF)
val PrimaryContainerLight = Color(0xFFD1E4FF)
val OnPrimaryContainerLight = Color(0xFF001D36)

val SecondaryGreenLight = Color(0xFF006D36)
val OnSecondaryLight = Color(0xFFFFFFFF)
val SecondaryContainerLight = Color(0xFF94F9B3)
val OnSecondaryContainerLight = Color(0xFF00210C)

val BackgroundLight = Color(0xFFFDFBFF)
val OnBackgroundLight = Color(0xFF1A1C1E)
val SurfaceLight = Color(0xFFFDFBFF)
val OnSurfaceLight = Color(0xFF1A1C1E)
val SurfaceVariantLight = Color(0xFFDFE2EB)
val OnSurfaceVariantLight = Color(0xFF43474E)
val OutlineLight = Color(0xFF73777F)

// ─── Dark Palette ───
val PrimaryBlueDark = Color(0xFF9ECAFF)
val OnPrimaryDark = Color(0xFF003258)
val PrimaryContainerDark = Color(0xFF00497D)
val OnPrimaryContainerDark = Color(0xFFD1E4FF)

val SecondaryGreenDark = Color(0xFF78DC98)
val OnSecondaryDark = Color(0xFF003919)
val SecondaryContainerDark = Color(0xFF005227)
val OnSecondaryContainerDark = Color(0xFF94F9B3)

val BackgroundDark = Color(0xFF1A1C1E)
val OnBackgroundDark = Color(0xFFE2E2E6)
val SurfaceDark = Color(0xFF1A1C1E)
val OnSurfaceDark = Color(0xFFE2E2E6)
val SurfaceVariantDark = Color(0xFF43474E)
val OnSurfaceVariantDark = Color(0xFFC3C7CF)
val OutlineDark = Color(0xFF8D9199)

private val LightColorScheme = lightColorScheme(
    primary = PrimaryBlueLight,
    onPrimary = OnPrimaryLight,
    primaryContainer = PrimaryContainerLight,
    onPrimaryContainer = OnPrimaryContainerLight,
    secondary = SecondaryGreenLight,
    onSecondary = OnSecondaryLight,
    secondaryContainer = SecondaryContainerLight,
    onSecondaryContainer = OnSecondaryContainerLight,
    background = BackgroundLight,
    onBackground = OnBackgroundLight,
    surface = SurfaceLight,
    onSurface = OnSurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = OnSurfaceVariantLight,
    outline = OutlineLight,
    error = Color(0xFFBA1A1A)
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
    background = BackgroundDark,
    onBackground = OnBackgroundDark,
    surface = SurfaceDark,
    onSurface = OnSurfaceDark,
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = OnSurfaceVariantDark,
    outline = OutlineDark,
    error = Color(0xFFFFB4AB)
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
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
        typography = AppTypography,
        content = content
    )
}
