package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Feedback
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue

enum class SettingsSheet {
    Appearance,
    EditEvent,
    Notification,
    Help
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsBottomSheet(
    onDismiss: () -> Unit
) {
    var activeSheet by remember { mutableStateOf<SettingsSheet?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = Modifier.fillMaxSize(),
        containerColor = Color.Black,
        contentColor = Color.White,
        dragHandle = null,
        windowInsets = WindowInsets(0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp) // Account for status bar
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Settings",
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                // Close button
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF3A3A3C))
                        .clickable { onDismiss() },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            // Settings sections
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 20.dp)
            ) {
                // General section
                item {
                    SettingsSectionHeader(
                        title = "General",
                        modifier = Modifier.padding(top = 20.dp, bottom = 12.dp)
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Appearance",
                        icon = Icons.Default.Palette,
                        iconColor = Color(0xFF007AFF), // iOS blue
                        onClick = { activeSheet = SettingsSheet.Appearance }
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Edit Event",
                        icon = Icons.Default.Edit,
                        iconColor = Color(0xFF007AFF),
                        onClick = { activeSheet = SettingsSheet.EditEvent }
                    )
                }

                item {
                    SettingsRow(
                        title = "Notification",
                        icon = Icons.Default.Notifications,
                        iconColor = Color(0xFF007AFF),
                        onClick = { activeSheet = SettingsSheet.Notification }
                    )
                }

                // Support section
                item {
                    SettingsSectionHeader(
                        title = "Support",
                        modifier = Modifier.padding(top = 32.dp, bottom = 12.dp)
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Send Feedback",
                        icon = Icons.Default.Feedback,
                        iconColor = Color(0xFF007AFF),
                        onClick = { }
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Help",
                        icon = Icons.Default.Help,
                        iconColor = Color(0xFF007AFF),
                        onClick = { activeSheet = SettingsSheet.Help }
                    )
                }

                // Support PractiCal section
                item {
                    SettingsSectionHeader(
                        title = "Support PractiCal",
                        modifier = Modifier.padding(top = 32.dp, bottom = 12.dp)
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Share App",
                        icon = Icons.Default.Share,
                        iconColor = Color(0xFF007AFF),
                        onClick = { }
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Write an App Store Review",
                        icon = Icons.Default.Star,
                        iconColor = Color(0xFF007AFF),
                        onClick = { }
                    )
                }
                
                item {
                    SettingsRow(
                        title = "Donation",
                        icon = Icons.Default.Favorite,
                        iconColor = Color(0xFF007AFF),
                        onClick = { }
                    )
                }
            }
        }

        // Show active sheet if needed
        when (activeSheet) {
            SettingsSheet.Appearance -> {
                AppearanceBottomSheet(
                    onDismiss = { activeSheet = null }
                )
            }
            SettingsSheet.EditEvent -> {
                // TODO: Implement EditEventSettingsBottomSheet
            }
            SettingsSheet.Notification -> {
                // TODO: Implement NotificationSettingsBottomSheet
            }
            SettingsSheet.Help -> {
                // TODO: Implement HelpBottomSheet
            }
            null -> {
                // No sheet to show
            }
        }
    }
}

@Composable
private fun SettingsSectionHeader(
    title: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = title,
        fontSize = 20.sp,
        fontWeight = FontWeight.Medium,
        color = Color.White,
        modifier = modifier
    )
}

@Composable
private fun SettingsRow(
    title: String,
    icon: ImageVector,
    iconColor: Color,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = title,
            tint = iconColor,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(16.dp))

        Text(
            text = title,
            fontSize = 18.sp,
            color = Color.White,
            modifier = Modifier.weight(1f)
        )

        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = "Navigate",
            tint = Color(0xFF8E8E93), // iOS secondary color
            modifier = Modifier.size(20.dp)
        )
    }
}

data class SettingsItem(
    val title: String,
    val icon: ImageVector,
    val onClick: () -> Unit
)