package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.practical.calendar.data.model.ViewMode

@Composable
fun HeaderView(
    monthName: String,
    onTodayTapped: () -> Unit,
    onSearchTapped: () -> Unit,
    onSettingsTapped: () -> Unit,
    onCalendarSelectionTapped: () -> Unit,
    onMonthTapped: () -> Unit = {},
    viewMode: ViewMode,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(60.dp)
            .background(Color.Black)
            .padding(horizontal = 20.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Month name, clickable for debug toggle
            Text(
                text = monthName,
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.clickable { onMonthTapped() }
            )

            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Today button - minimal like iOS
                Row(
                    modifier = Modifier.clickable { onTodayTapped() },
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = Color(0xFFFFD700) // Same yellow as other icons
                    )
                    Text(
                        text = "Today",
                        fontSize = 12.sp,
                        color = Color(0xFFFFD700) // Same yellow as other icons
                    )
                }

                // View mode indicator - Yellow like iOS
                Text(
                    text = getViewModeText(viewMode),
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFFFD700) // iOS yellow
                )

                // Yellow icons like iOS
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = "Search",
                    tint = Color(0xFFFFD700),
                    modifier = Modifier
                        .size(24.dp)
                        .clickable { onSearchTapped() }
                )

                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = "Calendar",
                    tint = Color(0xFFFFD700),
                    modifier = Modifier
                        .size(24.dp)
                        .clickable { onCalendarSelectionTapped() }
                )

                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = "Settings",
                    tint = Color(0xFFFFD700),
                    modifier = Modifier
                        .size(24.dp)
                        .clickable { onSettingsTapped() }
                )
            }
        }
    }
}


private fun getViewModeText(viewMode: ViewMode): String {
    return when (viewMode) {
        ViewMode.MONTH -> "30"
        ViewMode.WEEK -> "7"
        ViewMode.DAY -> "1"
    }
}