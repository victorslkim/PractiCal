package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.practical.calendar.data.model.Event
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.toInstant
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun DayView(
    selectedDate: LocalDate,
    events: List<Event>,
    onEventTapped: (Event) -> Unit,
    modifier: Modifier = Modifier
) {
    val dayEvents = events.filter { event ->
        val eventStartDate = event.startTime.date
        val eventEndDate = event.endTime.date
        selectedDate >= eventStartDate && selectedDate <= eventEndDate
    }.sortedBy { it.startTime }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        // Day header
        DayHeader(selectedDate = selectedDate)

        Spacer(modifier = Modifier.height(16.dp))

        // Timeline view with events
        if (dayEvents.isEmpty()) {
            Text(
                text = "No events for this day",
                fontSize = 16.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                modifier = Modifier.padding(vertical = 32.dp)
            )
        } else {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                dayEvents.forEach { event ->
                    DayEventBlock(
                        event = event,
                        onEventTapped = { onEventTapped(event) }
                    )
                }
            }
        }
    }
}

@Composable
private fun DayHeader(selectedDate: LocalDate) {
    val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
    val isToday = selectedDate == today

    val dateFormatter = SimpleDateFormat("EEEE, MMMM d", Locale.getDefault())
    val dateString = try {
        dateFormatter.format(
            Date(selectedDate.toEpochDays().toLong() * 24 * 60 * 60 * 1000)
        )
    } catch (e: Exception) {
        "${selectedDate.dayOfWeek.name}, ${selectedDate.month.name} ${selectedDate.dayOfMonth}"
    }

    Column {
        Text(
            text = dateString,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = if (isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
        )

        if (isToday) {
            Text(
                text = "Today",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(top = 2.dp)
            )
        }
    }
}

@Composable
private fun DayEventBlock(
    event: Event,
    onEventTapped: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onEventTapped() },
        colors = CardDefaults.cardColors(
            containerColor = event.color.copy(alpha = 0.1f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Time column
            Column(
                modifier = Modifier.width(80.dp),
                horizontalAlignment = Alignment.End
            ) {
                if (!event.isAllDay) {
                    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                    val startTimeString = timeFormat.format(
                        Date(event.startTime.toInstant(TimeZone.currentSystemDefault()).toEpochMilliseconds())
                    )
                    val endTimeString = timeFormat.format(
                        Date(event.endTime.toInstant(TimeZone.currentSystemDefault()).toEpochMilliseconds())
                    )

                    Text(
                        text = startTimeString,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = endTimeString,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                } else {
                    Text(
                        text = "All Day",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Color bar
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(60.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(event.color)
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Event details
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = event.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface
                )

                if (event.location.isNotBlank()) {
                    Text(
                        text = event.location,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }

                if (event.description.isNotBlank()) {
                    Text(
                        text = event.description,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}