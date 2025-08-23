package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler
import com.practical.calendar.data.model.Event

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventEditorBottomSheet(
    existingEvent: Event? = null,
    onDismiss: () -> Unit
) {
    var eventTitle by remember { mutableStateOf(existingEvent?.name ?: "") }
    var eventLocation by remember { mutableStateOf(existingEvent?.location ?: "") }
    var eventDescription by remember { mutableStateOf(existingEvent?.description ?: "") }
    var isAllDay by remember { mutableStateOf(existingEvent?.isAllDay ?: false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = Modifier.fillMaxSize(),
        containerColor = Color.Black,
        contentColor = Color.White,
        dragHandle = null,
        windowInsets = WindowInsets(0.dp)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = 60.dp) // Account for status bar
                    .verticalScroll(rememberScrollState())
            ) {
            // Header - centered like iOS
            Text(
                text = if (existingEvent != null) "Edit Event" else "New Event",
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Title Section - with colored bar and background like iOS
            FormSection {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Purple bar like iOS
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .height(24.dp)
                            .background(Color(0xFF9C7CF0), RoundedCornerShape(2.dp))
                    )

                    Spacer(modifier = Modifier.width(12.dp))

                    TextField(
                        value = eventTitle,
                        onValueChange = { eventTitle = it },
                        placeholder = { Text("Title", color = Color.Gray) },
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.Transparent,
                            unfocusedContainerColor = Color.Transparent,
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedIndicatorColor = Color.Transparent,
                            unfocusedIndicatorColor = Color.Transparent
                        ),
                        textStyle = androidx.compose.ui.text.TextStyle(
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Date/Time Section - grouped like iOS
            FormSection {
                // All Day toggle
                FormRow(
                    icon = Icons.Default.AccessTime,
                    title = "All Day",
                    rightContent = {
                        Switch(
                            checked = isAllDay,
                            onCheckedChange = { isAllDay = it },
                            colors = androidx.compose.material3.SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF007AFF), // iOS blue
                                uncheckedThumbColor = Color.White,
                                uncheckedTrackColor = Color.Gray
                            )
                        )
                    }
                )

                FormRowDivider()

                // Start date
                FormRow(
                    title = "Starts",
                    rightContent = {
                        Text(
                            text = "Sep 26, 2025",
                            color = Color.Gray,
                            fontSize = 16.sp
                        )
                    },
                    onClick = { /* Handle date picker */ }
                )

                FormRowDivider()

                // End date
                FormRow(
                    title = "Ends",
                    rightContent = {
                        Text(
                            text = "Sep 26, 2025",
                            color = Color.Gray,
                            fontSize = 16.sp
                        )
                    },
                    onClick = { /* Handle date picker */ }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Calendar Section
            FormSection {
                FormRow(
                    icon = Icons.Default.CalendarToday,
                    title = "Calendar",
                    rightContent = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .background(Color(0xFF9C7CF0), CircleShape)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "seungkim14@gmail.com",
                                color = Color.Gray,
                                fontSize = 16.sp
                            )
                        }
                    },
                    onClick = { /* Handle calendar selection */ }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Alert Section
            FormSection {
                FormRow(
                    icon = Icons.Default.NotificationsNone,
                    title = "Alert",
                    rightContent = {
                        Text(
                            text = "None",
                            color = Color.Gray,
                            fontSize = 16.sp
                        )
                    },
                    onClick = { /* Handle alert selection */ }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Location Section
            FormSection {
                FormRow(
                    icon = Icons.Default.LocationOn,
                    title = "Location",
                    rightContent = {
                        TextField(
                            value = eventLocation,
                            onValueChange = { eventLocation = it },
                            placeholder = { Text("", color = Color.Gray) },
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent
                            ),
                            modifier = Modifier.width(200.dp),
                            textStyle = androidx.compose.ui.text.TextStyle(fontSize = 16.sp)
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // URL Section
            FormSection {
                FormRow(
                    icon = Icons.Default.Link,
                    title = "URL",
                    rightContent = {
                        TextField(
                            value = "",
                            onValueChange = { },
                            placeholder = { Text("", color = Color.Gray) },
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent
                            ),
                            modifier = Modifier.width(200.dp),
                            textStyle = androidx.compose.ui.text.TextStyle(fontSize = 16.sp)
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Notes Section
            FormSection {
                FormRow(
                    icon = Icons.Default.Notes,
                    title = "Notes",
                    rightContent = {
                        TextField(
                            value = eventDescription,
                            onValueChange = { eventDescription = it },
                            placeholder = { Text("", color = Color.Gray) },
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent
                            ),
                            modifier = Modifier.width(200.dp),
                            textStyle = androidx.compose.ui.text.TextStyle(fontSize = 16.sp)
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Remove Event button (only show for existing events)
            if (existingEvent != null) {
                TextButton(
                    onClick = { /* Handle remove event */ },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                ) {
                    Text(
                        text = "Remove Event",
                        color = Color.Red,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

                Spacer(modifier = Modifier.height(100.dp)) // Space for FAB
            }

            // Floating Action Button (Save/Done)
            FloatingActionButton(
                onClick = {
                    // Handle save event
                    onDismiss()
                },
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(16.dp),
                containerColor = Color(0xFF007AFF) // iOS blue
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Save",
                    tint = Color.White
                )
            }
        }
    }
}

// iOS-style Form Section with gray background
@Composable
internal fun FormSection(
    content: @Composable () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Color(0xFF2C2C2E), // iOS systemGray6 equivalent
                    RoundedCornerShape(12.dp)
                )
        ) {
            content()
        }
    }
}

// Individual form row within a section
@Composable
internal fun FormRow(
    icon: ImageVector? = null,
    title: String,
    rightContent: @Composable () -> Unit = {},
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .let { modifier ->
                if (onClick != null) {
                    modifier.clickable { onClick() }
                } else {
                    modifier
                }
            }
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = Color.Gray,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
        }

        Text(
            text = title,
            fontSize = 17.sp,
            color = Color.White,
            modifier = Modifier.weight(1f)
        )

        rightContent()
    }
}

// Divider between form rows (like iOS)
@Composable
internal fun FormRowDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(0.5.dp)
            .padding(start = 52.dp) // Indent to align with text after icon + spacing
            .background(Color.Gray.copy(alpha = 0.3f))
    )
}