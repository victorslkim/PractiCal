package com.practical.calendar.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Dark theme with high contrast
private val iOSDarkColorScheme = darkColorScheme(
    primary = Color(0xFFFFD700), // Golden yellow primary color
    secondary = Color(0xFF00A4FF), // Blue for FAB
    tertiary = Color(0xFFFF3B30), // Red for weekends
    background = Color.Black, // True black background
    surface = Color.Black, // True black surface
    surfaceVariant = Color(0xFF1C1C1E), // Very dark gray for cards
    onBackground = Color.White,
    onSurface = Color.White,
    onSurfaceVariant = Color(0xFF8E8E93), // Secondary text color
    primaryContainer = Color(0xFF2C2C2E), // Dark container
    onPrimaryContainer = Color.White
)


@Composable
fun PractiCalTheme(
    content: @Composable () -> Unit
) {
    // Always use our custom dark theme
    val colorScheme = iOSDarkColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Black.toArgb() // Black status bar
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}