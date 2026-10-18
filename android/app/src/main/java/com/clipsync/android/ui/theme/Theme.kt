package com.clipsync.android.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Strict Solid Color Palette (Zero Gradients Rule)
val SolidBlack = Color(0xFF121212)
val SolidSurfaceDark = Color(0xFF1E1E1E)
val SolidSurfaceElevated = Color(0xFF2A2A2A)
val SolidBorderDark = Color(0xFF333333)

val SolidWhite = Color(0xFFFFFFFF)
val SolidSurfaceLight = Color(0xFFF4F4F5)
val SolidSurfaceLightElevated = Color(0xFFE4E4E7)
val SolidBorderLight = Color(0xFFD4D4D8)

val SolidPrimary = Color(0xFF2563EB) // Solid Cobalt Blue
val SolidSuccess = Color(0xFF16A34A) // Solid Green
val SolidWarning = Color(0xFFCA8A04) // Solid Amber
val SolidError = Color(0xFFDC2626)   // Solid Red

val TextPrimaryDark = Color(0xFFFFFFFF)
val TextSecondaryDark = Color(0xFFA1A1AA)

val TextPrimaryLight = Color(0xFF18181B)
val TextSecondaryLight = Color(0xFF71717A)

private val DarkColorScheme = darkColorScheme(
    primary = SolidPrimary,
    background = SolidBlack,
    surface = SolidSurfaceDark,
    onPrimary = Color.White,
    onBackground = TextPrimaryDark,
    onSurface = TextPrimaryDark,
    error = SolidError
)

private val LightColorScheme = lightColorScheme(
    primary = SolidPrimary,
    background = SolidWhite,
    surface = SolidSurfaceLight,
    onPrimary = Color.White,
    onBackground = TextPrimaryLight,
    onSurface = TextPrimaryLight,
    error = SolidError
)

@Composable
fun ClipSyncTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
