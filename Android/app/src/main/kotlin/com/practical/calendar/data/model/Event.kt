package com.practical.calendar.data.model

import android.os.Parcelable
import androidx.compose.ui.graphics.Color
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalDate
import kotlinx.parcelize.Parcelize
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Parcelize
data class Event(
    val id: String,
    val name: String,
    val startTime: @kotlinx.parcelize.RawValue LocalDateTime,
    val endTime: @kotlinx.parcelize.RawValue LocalDateTime,
    val location: String = "",
    val description: String = "",
    val calendarId: String,
    val calendarColor: Long, // Color as Long for Parcelize compatibility
    val isAllDay: Boolean = false,
    val isRecurring: Boolean = false
) : Parcelable {

    val timeString: String
        get() = if (isAllDay) {
            "All Day"
        } else {
            val format = SimpleDateFormat("h:mm a", Locale.getDefault())
            val calendar = Calendar.getInstance()
            calendar.set(startTime.year, startTime.monthNumber - 1, startTime.dayOfMonth, 
                        startTime.hour, startTime.minute)
            format.format(calendar.time)
        }

    val isMultiDay: Boolean
        get() = startTime.date != endTime.date

    val isFullDay: Boolean
        get() = isAllDay || isMultiDay

    // Helper to get the span of days for this event
    fun daySpan(): Triple<LocalDate, LocalDate, Int> {
        val startDay = startTime.date
        val endDay = endTime.date
        val daysBetween = java.time.temporal.ChronoUnit.DAYS.between(
            java.time.LocalDate.of(startDay.year, startDay.monthNumber, startDay.dayOfMonth),
            java.time.LocalDate.of(endDay.year, endDay.monthNumber, endDay.dayOfMonth)
        ).toInt() + 1
        return Triple(startDay, endDay, daysBetween)
    }

    // Get color as Compose Color
    val color: Color
        get() = Color(calendarColor)
}