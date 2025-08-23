package com.practical.calendar.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.Locale
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.activity.compose.BackHandler
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.practical.calendar.data.model.Event

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchBottomSheet(
    events: List<Event> = emptyList(),
    onEventSelected: (Event) -> Unit = {},
    onDismiss: () -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var submittedQuery by remember { mutableStateOf("") }


    val filteredEvents by remember {
        derivedStateOf {
            android.util.Log.d("SearchBottomSheet", "Filtering with query: '$submittedQuery', events count: ${events.size}")
            if (submittedQuery.isBlank()) {
                emptyList()
            } else {
                val filtered = events.filter { event ->
                    event.name.contains(submittedQuery, ignoreCase = true) ||
                    event.description.contains(submittedQuery, ignoreCase = true) ||
                    event.location.contains(submittedQuery, ignoreCase = true)
                }.distinctBy { event ->
                    // Deduplicate recurring events by id + start time
                    "${event.id}|${event.startTime}"
                }.sortedByDescending { event ->
                    // Sort by descending date
                    event.startTime
                }
                android.util.Log.d("SearchBottomSheet", "Filtered to ${filtered.size} results")
                filtered
            }
        }
    }

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
                    text = "Search",
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

            // Search field
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .background(
                        Color(0xFF1C1C1E),
                        RoundedCornerShape(10.dp)
                    )
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = "Search",
                    tint = Color(0xFF8E8E93),
                    modifier = Modifier.size(20.dp)
                )
                
                BasicTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    modifier = Modifier
                        .weight(1f)
                        .padding(start = 8.dp),
                    singleLine = true,
                    textStyle = TextStyle(
                        color = Color.White,
                        fontSize = 16.sp
                    ),
                    keyboardOptions = KeyboardOptions.Default.copy(
                        imeAction = ImeAction.Search
                    ),
                    keyboardActions = KeyboardActions(
                        onSearch = {
                            submittedQuery = searchQuery
                        }
                    ),
                    decorationBox = { innerTextField ->
                        if (searchQuery.isEmpty()) {
                            Text(
                                text = "Search",
                                color = Color(0xFF8E8E93),
                                fontSize = 16.sp
                            )
                        }
                        innerTextField()
                    }
                )
                
                if (searchQuery.isNotEmpty()) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Clear",
                        tint = Color(0xFF8E8E93),
                        modifier = Modifier
                            .size(18.dp)
                            .clickable {
                                searchQuery = ""
                                submittedQuery = ""
                            }
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Search results
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 20.dp)
            ) {
                if (submittedQuery.isNotBlank()) {
                    if (filteredEvents.isEmpty()) {
                        item {
                            Text(
                                text = "No Results",
                                fontSize = 16.sp,
                                color = Color(0xFF8E8E93),
                                modifier = Modifier.padding(vertical = 40.dp)
                            )
                        }
                    } else {
                        items(filteredEvents) { event ->
                            SearchResultRow(
                                event = event,
                                onClick = {
                                    onEventSelected(event)
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
private fun SearchResultRow(
    event: Event,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Purple vertical line
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(40.dp)
                .background(Color(0xFF8E44AD)) // Purple color from iOS design
        )

        Spacer(modifier = Modifier.width(16.dp))

        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = event.name,
                fontSize = 18.sp,
                fontWeight = FontWeight.Medium,
                color = Color.White
            )
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (event.isRecurring) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = "Recurring",
                        tint = Color(0xFF8E8E93),
                        modifier = Modifier.size(12.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                }

                Text(
                    text = if (event.isMultiDay) {
                        // Show date range for multi-day events
                        val startDate = SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(
                            java.util.Calendar.getInstance().apply {
                                set(event.startTime.year, event.startTime.monthNumber - 1, event.startTime.dayOfMonth)
                            }.time
                        )
                        val endDate = SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(
                            java.util.Calendar.getInstance().apply {
                                set(event.endTime.year, event.endTime.monthNumber - 1, event.endTime.dayOfMonth)
                            }.time
                        )
                        "$startDate - $endDate"
                    } else {
                        SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(
                            java.util.Calendar.getInstance().apply {
                                set(event.startTime.year, event.startTime.monthNumber - 1, event.startTime.dayOfMonth)
                            }.time
                        )
                    },
                    fontSize = 14.sp,
                    color = Color(0xFF8E8E93)
                )
            }
            
            if (event.location.isNotBlank()) {
                Text(
                    text = event.location,
                    fontSize = 14.sp,
                    color = Color(0xFF8E8E93)
                )
            }
        }
    }
}