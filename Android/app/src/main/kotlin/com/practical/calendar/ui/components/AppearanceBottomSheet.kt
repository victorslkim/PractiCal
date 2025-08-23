package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppearanceBottomSheet(
    onDismiss: () -> Unit
) {

    // State variables matching iOS implementation
    var firstDayOfWeek by remember { mutableStateOf("Sunday") }
    var selectedTheme by remember { mutableStateOf("System") }
    var selectedAccentColor by remember { mutableStateOf("blue") }
    var selectedLanguage by remember { mutableStateOf("System Default") }
    var highlightHolidays by remember { mutableStateOf(true) }
    var highlightSaturdays by remember { mutableStateOf(false) }
    var highlightSundays by remember { mutableStateOf(true) }
    var textSize by remember { mutableStateOf(0) }
    var boldText by remember { mutableStateOf(false) }
    var showEventBackground by remember { mutableStateOf(true) }
    var use24HourTime by remember { mutableStateOf(false) }
    var dimPastEvents by remember { mutableStateOf(false) }

    val accentColors = listOf(
        "blue" to Color(0xFF007AFF),
        "green" to Color(0xFF34C759),
        "orange" to Color(0xFFFF9500),
        "purple" to Color(0xFFAF52DE),
        "red" to Color(0xFFFF3B30),
        "yellow" to Color(0xFFFFCC00)
    )

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
                .padding(top = 60.dp)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Spacer(modifier = Modifier.width(44.dp)) // Balance for Done button

                Text(
                    text = "Appearance",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )

                TextButton(onClick = onDismiss) {
                    Text(
                        text = "Done",
                        fontSize = 17.sp,
                        color = Color(0xFF007AFF)
                    )
                }
            }

            // Scrollable content
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Calendar preview section
                FormSection {
                    // Calendar preview
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .padding(16.dp)
                    ) {
                        CalendarPreviewContent()
                    }

                    FormRowDivider()

                    // First Day of Week
                    FormRow(
                        title = "First Day of Week",
                        rightContent = {
                            Text(
                                text = firstDayOfWeek,
                                color = Color.Gray,
                                fontSize = 16.sp
                            )
                        },
                        onClick = { /* Handle first day selection */ }
                    )

                    FormRowDivider()

                    // Theme
                    FormRow(
                        title = "Theme",
                        rightContent = {
                            Text(
                                text = selectedTheme,
                                color = Color.Gray,
                                fontSize = 16.sp
                            )
                        },
                        onClick = { /* Handle theme selection */ }
                    )

                    FormRowDivider()

                    // Accent Color
                    FormRow(
                        title = "Accent Color",
                        rightContent = {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                accentColors.forEach { (colorName, color) ->
                                    Box(
                                        modifier = Modifier
                                            .size(20.dp)
                                            .background(color, CircleShape)
                                            .border(
                                                width = if (selectedAccentColor == colorName) 2.dp else 0.dp,
                                                color = if (selectedAccentColor == colorName) Color.White else Color.Transparent,
                                                shape = CircleShape
                                            )
                                            .clickable { selectedAccentColor = colorName }
                                    )
                                }
                            }
                        }
                    )

                    FormRowDivider()

                    // Language
                    FormRow(
                        title = "Language",
                        rightContent = {
                            Text(
                                text = selectedLanguage,
                                color = Color.Gray,
                                fontSize = 16.sp
                            )
                        },
                        onClick = { /* Handle language selection */ }
                    )

                    FormRowDivider()

                    // Highlight
                    FormRow(
                        title = "Highlight",
                        rightContent = {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                HighlightPill(
                                    text = "Holidays",
                                    selected = highlightHolidays,
                                    onClick = { highlightHolidays = !highlightHolidays }
                                )
                                HighlightPill(
                                    text = "Sat",
                                    selected = highlightSaturdays,
                                    onClick = { highlightSaturdays = !highlightSaturdays }
                                )
                                HighlightPill(
                                    text = "Sun",
                                    selected = highlightSundays,
                                    onClick = { highlightSundays = !highlightSundays }
                                )
                            }
                        }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Day cell preview section
                FormSection {
                    // Day cell preview placeholder
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(120.dp)
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        DayCellPreviewContent(
                            textSize = textSize,
                            boldText = boldText,
                            showBackground = showEventBackground
                        )
                    }

                    FormRowDivider()

                    // Text Size
                    FormRow(
                        title = "Text Size",
                        rightContent = {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                IconButton(
                                    onClick = { textSize = maxOf(-4, textSize - 1) },
                                    enabled = textSize > -4,
                                    modifier = Modifier
                                        .size(32.dp)
                                        .background(Color(0xFF007AFF), RoundedCornerShape(8.dp))
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Remove,
                                        contentDescription = "Decrease",
                                        tint = Color.White,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }

                                Text(
                                    text = textSize.toString(),
                                    color = Color.White,
                                    fontSize = 16.sp,
                                    modifier = Modifier.width(20.dp),
                                    textAlign = TextAlign.Center
                                )

                                IconButton(
                                    onClick = { textSize = minOf(4, textSize + 1) },
                                    enabled = textSize < 4,
                                    modifier = Modifier
                                        .size(32.dp)
                                        .background(Color(0xFF007AFF), RoundedCornerShape(8.dp))
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Add,
                                        contentDescription = "Increase",
                                        tint = Color.White,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }
                    )

                    FormRowDivider()

                    // Bold Text
                    FormRow(
                        title = "Bold Text",
                        rightContent = {
                            Switch(
                                checked = boldText,
                                onCheckedChange = { boldText = it },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = Color.White,
                                    checkedTrackColor = Color(0xFF007AFF),
                                    uncheckedThumbColor = Color.White,
                                    uncheckedTrackColor = Color.Gray
                                )
                            )
                        }
                    )

                    FormRowDivider()

                    // Show Event Background
                    FormRow(
                        title = "Show Event Background",
                        rightContent = {
                            Switch(
                                checked = showEventBackground,
                                onCheckedChange = { showEventBackground = it },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = Color.White,
                                    checkedTrackColor = Color(0xFF007AFF),
                                    uncheckedThumbColor = Color.White,
                                    uncheckedTrackColor = Color.Gray
                                )
                            )
                        }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Event preview section
                FormSection {
                    // Event row previews
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        EventRowPreview(
                            title = "Future Meeting",
                            time = "8:41 PM",
                            location = "Conference Room A",
                            description = "This is a future event that should not be dimmed",
                            color = Color(0xFF007AFF),
                            isPast = false,
                            dimPastEvents = dimPastEvents
                        )

                        EventRowPreview(
                            title = "Past Meeting",
                            time = "5:41 PM",
                            location = "Conference Room C",
                            description = "This is a past event that should be dimmed",
                            color = Color(0xFFFF3B30),
                            isPast = true,
                            dimPastEvents = dimPastEvents
                        )
                    }

                    FormRowDivider()

                    // 24-Hour Time
                    FormRow(
                        title = "24-Hour Time",
                        rightContent = {
                            Switch(
                                checked = use24HourTime,
                                onCheckedChange = { use24HourTime = it },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = Color.White,
                                    checkedTrackColor = Color(0xFF007AFF),
                                    uncheckedThumbColor = Color.White,
                                    uncheckedTrackColor = Color.Gray
                                )
                            )
                        }
                    )

                    FormRowDivider()

                    // Dim Past Events
                    FormRow(
                        title = "Dim Past Events",
                        rightContent = {
                            Switch(
                                checked = dimPastEvents,
                                onCheckedChange = { dimPastEvents = it },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = Color.White,
                                    checkedTrackColor = Color(0xFF007AFF),
                                    uncheckedThumbColor = Color.White,
                                    uncheckedTrackColor = Color.Gray
                                )
                            )
                        }
                    )
                }

                Spacer(modifier = Modifier.height(100.dp)) // Bottom padding
            }
        }
    }
}

@Composable
private fun HighlightPill(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) Color(0xFFFF3B30) else Color(0xFF3A3A3C))
            .clickable { onClick() }
            .padding(horizontal = 6.dp, vertical = 3.dp)
    ) {
        Text(
            text = text,
            fontSize = 12.sp,
            color = Color.White
        )
    }
}

@Composable
private fun CalendarPreviewContent() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFF1C1C1E), RoundedCornerShape(8.dp))
            .padding(16.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "December 2024",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Simple calendar grid
            val daysOfWeek = listOf("S", "M", "T", "W", "T", "F", "S")

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                daysOfWeek.forEach { day ->
                    Text(
                        text = day,
                        fontSize = 12.sp,
                        color = Color.Gray,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Calendar dates (simplified) - match iOS with red highlighting
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                CalendarWeek(listOf("1", "2", "3", "4", "5", "6", "7"), listOf(0, 6)) // Sundays
                CalendarWeek(listOf("8", "9", "10", "11", "12", "13", "14"), listOf(0, 6))
                CalendarWeek(listOf("15", "16", "17", "18", "19", "20", "21"), listOf(0, 6))
                CalendarWeek(listOf("22", "23", "24", "25", "26", "27", "28"), listOf(0, 6))
                CalendarWeek(listOf("29", "30", "31", "1", "2", "3", "4"), listOf(0, 6))
            }
        }
    }
}

@Composable
private fun CalendarWeek(dates: List<String>, highlightIndices: List<Int>) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        dates.forEachIndexed { index, date ->
            Text(
                text = date,
                fontSize = 14.sp,
                color = if (highlightIndices.contains(index)) Color(0xFFFF3B30) else Color.White,
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun DayCellPreviewContent(
    textSize: Int,
    boldText: Boolean,
    showBackground: Boolean
) {
    Box(
        modifier = Modifier
            .size(80.dp)
            .background(Color(0xFF1C1C1E), RoundedCornerShape(8.dp)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "15",
                fontSize = (16 + textSize * 2).sp,
                fontWeight = if (boldText) FontWeight.Bold else FontWeight.Normal,
                color = Color.White
            )

            if (showBackground) {
                Spacer(modifier = Modifier.height(4.dp))
                Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    Box(
                        modifier = Modifier
                            .width(60.dp)
                            .height(8.dp)
                            .background(Color(0xFF007AFF), RoundedCornerShape(2.dp))
                    )
                    Box(
                        modifier = Modifier
                            .width(60.dp)
                            .height(8.dp)
                            .background(Color(0xFF34C759), RoundedCornerShape(2.dp))
                    )
                    Box(
                        modifier = Modifier
                            .width(60.dp)
                            .height(8.dp)
                            .background(Color(0xFFFF9500), RoundedCornerShape(2.dp))
                    )
                }
            } else {
                Text(
                    text = "Meeting\nLunch\nCall",
                    fontSize = 8.sp,
                    color = Color.Gray,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun EventRowPreview(
    title: String,
    time: String,
    location: String,
    description: String,
    color: Color,
    isPast: Boolean,
    dimPastEvents: Boolean
) {
    val alpha = if (isPast && dimPastEvents) 0.5f else 1.0f

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFF1C1C1E), RoundedCornerShape(8.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(60.dp)
                .background(color.copy(alpha = alpha), RoundedCornerShape(2.dp))
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column {
            Text(
                text = time,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = alpha)
            )

            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                color = Color.White.copy(alpha = alpha)
            )

            Text(
                text = location,
                fontSize = 12.sp,
                color = Color.Gray.copy(alpha = alpha)
            )

            Text(
                text = description,
                fontSize = 12.sp,
                color = Color.Gray.copy(alpha = alpha)
            )
        }
    }
}