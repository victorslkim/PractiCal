package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.Info
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
import com.practical.calendar.data.repository.CalendarInfo

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarSelectionBottomSheet(
    calendars: List<CalendarInfo>,
    selectedCalendarIds: Set<String>,
    onSelectionChanged: (Set<String>) -> Unit,
    onDismiss: () -> Unit
) {
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
                    text = "Calendars",
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

            // Calendar list with grouped sections
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 20.dp)
            ) {
                if (calendars.isEmpty()) {
                    item {
                        Text(
                            text = "No calendars available",
                            fontSize = 16.sp,
                            color = Color(0xFF8E8E93),
                            modifier = Modifier.padding(vertical = 40.dp)
                        )
                    }
                } else {
                    // Group calendars by source
                    val groupedCalendars = calendars.groupBy { it.displaySource }
                    
                    groupedCalendars.forEach { (source, sourceCalendars) ->
                        // Section header
                        item {
                            CalendarSourceHeader(
                                source = source,
                                modifier = Modifier.padding(top = 20.dp, bottom = 12.dp)
                            )
                        }
                        
                        // Calendar items
                        items(sourceCalendars) { calendar ->
                            CalendarRow(
                                calendar = calendar,
                                isSelected = selectedCalendarIds.contains(calendar.id),
                                onSelectionChanged = { isSelected ->
                                    val newIds = if (isSelected) {
                                        selectedCalendarIds + calendar.id
                                    } else {
                                        selectedCalendarIds - calendar.id
                                    }
                                    onSelectionChanged(newIds)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarSourceHeader(
    source: String,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
    ) {
        Icon(
            imageVector = getSourceIcon(source),
            contentDescription = source,
            tint = Color(0xFF0A84FF), // iOS blue
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = source,
            fontSize = 20.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White
        )
    }
}

@Composable
private fun CalendarRow(
    calendar: CalendarInfo,
    isSelected: Boolean,
    onSelectionChanged: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelectionChanged(!isSelected) }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Calendar color circle with checkmark
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(CircleShape)
                .background(Color(calendar.color)),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected",
                    tint = Color.White,
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(16.dp))

        // Calendar name
        Text(
            text = calendar.name,
            fontSize = 18.sp,
            color = Color.White,
            modifier = Modifier.weight(1f)
        )

        // Info button
        Icon(
            imageVector = Icons.Default.Info,
            contentDescription = "Calendar Info",
            tint = Color(0xFF0A84FF), // iOS blue
            modifier = Modifier.size(24.dp)
        )
    }
}

private fun getSourceIcon(source: String): ImageVector {
    return when {
        source.contains("Google", ignoreCase = true) -> Icons.Default.CloudDone
        source.contains("iCloud", ignoreCase = true) -> Icons.Default.Cloud
        else -> Icons.Default.CalendarMonth
    }
}