package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.practical.calendar.data.model.Event
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.DatePeriod
import kotlinx.datetime.minus
import kotlinx.datetime.plus

@Composable
fun WeekView(
    selectedDate: LocalDate,
    events: List<Event>,
    onDateSelected: (LocalDate) -> Unit,
    onEventTapped: (Event) -> Unit,
    modifier: Modifier = Modifier
) {
    val weekStart = selectedDate.minus(DatePeriod(days = selectedDate.dayOfWeek.ordinal))
    val weekDays = (0..6).map { dayOffset ->
        weekStart.plus(DatePeriod(days = dayOffset))
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // Week header with days
        WeekHeader(
            weekDays = weekDays,
            selectedDate = selectedDate,
            onDateSelected = onDateSelected
        )

        // Events for selected day
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val selectedDayEvents = events.filter { event ->
                val eventStartDate = event.startTime.date
                val eventEndDate = event.endTime.date
                selectedDate >= eventStartDate && selectedDate <= eventEndDate
            }.sortedBy { it.startTime }

            if (selectedDayEvents.isEmpty()) {
                Text(
                    text = "No events for this day",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    modifier = Modifier.padding(vertical = 16.dp)
                )
            } else {
                selectedDayEvents.forEach { event ->
                    WeekEventCard(
                        event = event,
                        onEventTapped = { onEventTapped(event) }
                    )
                }
            }
        }
    }
}

@Composable
private fun WeekHeader(
    weekDays: List<LocalDate>,
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit
) {
    val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
    val daysOfWeek = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")

    Column {
        // Day names
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            daysOfWeek.forEach { day ->
                Text(
                    text = day,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        }

        // Date numbers
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            weekDays.forEach { date ->
                val isSelected = date == selectedDate
                val isToday = date == today

                Box(
                    modifier = Modifier
                        .weight(1f)
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .background(
                            when {
                                isSelected -> MaterialTheme.colorScheme.primary
                                isToday -> MaterialTheme.colorScheme.secondary.copy(alpha = 0.3f)
                                else -> Color.Transparent
                            }
                        )
                        .clickable { onDateSelected(date) },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = date.dayOfMonth.toString(),
                        fontSize = 16.sp,
                        fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
                        color = when {
                            isSelected -> MaterialTheme.colorScheme.onPrimary
                            isToday -> MaterialTheme.colorScheme.secondary
                            else -> MaterialTheme.colorScheme.onSurface
                        },
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun WeekEventCard(
    event: Event,
    onEventTapped: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onEventTapped() },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Color indicator
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(40.dp)
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

                Text(
                    text = event.timeString,
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                    modifier = Modifier.padding(top = 2.dp)
                )

                if (event.location.isNotBlank()) {
                    Text(
                        text = event.location,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }
            }
        }
    }
}