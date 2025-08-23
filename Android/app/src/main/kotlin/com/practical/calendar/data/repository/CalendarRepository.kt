package com.practical.calendar.data.repository

import android.content.ContentResolver
import android.content.ContentUris
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import androidx.compose.ui.graphics.Color
import com.practical.calendar.data.model.Event
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.Instant
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.toInstant
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.plus
import kotlin.math.max
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CalendarRepository @Inject constructor(
    private val contentResolver: ContentResolver
) {

    suspend fun getEvents(
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        selectedCalendarIds: Set<String>
    ): List<Event> = withContext(Dispatchers.IO) {
        val events = mutableListOf<Event>()
        
        android.util.Log.d("CalendarRepository", "getEvents called with startDate=$startDate, endDate=$endDate")
        android.util.Log.d("CalendarRepository", "selectedCalendarIds=$selectedCalendarIds (size=${selectedCalendarIds.size})")
        
        if (selectedCalendarIds.isEmpty()) {
            android.util.Log.d("CalendarRepository", "No calendars selected, returning empty list")
            return@withContext events
        }

        val startMillis = startDate.toInstant(TimeZone.currentSystemDefault()).toEpochMilliseconds()
        val endMillis = endDate.toInstant(TimeZone.currentSystemDefault()).toEpochMilliseconds()
        
        android.util.Log.d("CalendarRepository", "Query range: $startMillis to $endMillis")


        // Use Instances table to get expanded recurring events
        val instancesUri = CalendarContract.Instances.CONTENT_URI.buildUpon()
            .appendPath(startMillis.toString())
            .appendPath(endMillis.toString())
            .build()
            
        val instancesProjection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.CALENDAR_COLOR,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.RRULE
        )

        val cursor: Cursor? = contentResolver.query(
            instancesUri,
            instancesProjection,
            null, // Instances URI already includes time range
            null,
            "${CalendarContract.Instances.BEGIN} ASC"
        )

        android.util.Log.d("CalendarRepository", "Query executed, cursor has ${cursor?.count ?: 0} rows")
        
        cursor?.use { c ->
            var eventsProcessed = 0
            while (c.moveToNext()) {
                eventsProcessed++
                val calendarId = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID))
                
                if (!selectedCalendarIds.contains(calendarId)) {
                    android.util.Log.d("CalendarRepository", "Skipping event from unselected calendar: $calendarId")
                    continue
                }

                val id = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))
                val title = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)) ?: "Untitled"
                val startTimeMillis = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN))
                val endTimeMillis = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.END))
                val location = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION)) ?: ""
                val description = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION)) ?: ""
                val colorInt = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_COLOR))
                val allDay = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)) == 1
                val rrule = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.RRULE))
                val isRecurring = !rrule.isNullOrEmpty()

                val startDateTime = if (allDay) {
                    // For all-day events, use the date part at start of day (like iOS)
                    val startDateObj = Instant.fromEpochMilliseconds(startTimeMillis)
                        .toLocalDateTime(TimeZone.UTC).date
                    kotlinx.datetime.LocalDateTime(startDateObj.year, startDateObj.monthNumber, startDateObj.dayOfMonth, 0, 0)
                } else {
                    Instant.fromEpochMilliseconds(startTimeMillis)
                        .toLocalDateTime(TimeZone.currentSystemDefault())
                }

                val endDateTime = if (allDay) {
                    // For all-day events, use end date but subtract 1 day since Android stores it as next day at midnight
                    val endDateObj = Instant.fromEpochMilliseconds(endTimeMillis)
                        .toLocalDateTime(TimeZone.UTC).date

                    // Android Calendar always stores all-day events with end time as start of next day
                    // So we always subtract 1 day to get the actual last day of the event
                    val actualEndDay = java.time.LocalDate.of(endDateObj.year, endDateObj.monthNumber, endDateObj.dayOfMonth).minusDays(1)
                    val actualEndDate = kotlinx.datetime.LocalDate(actualEndDay.year, actualEndDay.monthValue, actualEndDay.dayOfMonth)

                    kotlinx.datetime.LocalDateTime(actualEndDate.year, actualEndDate.monthNumber, actualEndDate.dayOfMonth, 23, 59)
                } else {
                    Instant.fromEpochMilliseconds(endTimeMillis)
                        .toLocalDateTime(TimeZone.currentSystemDefault())
                }

                val event = Event(
                    id = id,
                    name = title,
                    startTime = startDateTime,
                    endTime = endDateTime,
                    location = location,
                    description = description,
                    calendarId = calendarId,
                    calendarColor = colorInt.toUInt().toLong(),
                    isAllDay = allDay,
                    isRecurring = isRecurring
                )

                events.add(event)
                android.util.Log.d("CalendarRepository", "Added event: ${event.name} (${event.startTime.date} to ${event.endTime.date}, isAllDay=${event.isAllDay})")
            }
            android.util.Log.d("CalendarRepository", "Processed $eventsProcessed cursor rows, found ${events.size} valid events")
        }

        android.util.Log.d("CalendarRepository", "Returning ${events.size} events")
        events
    }

    suspend fun getAvailableCalendars(): List<CalendarInfo> = withContext(Dispatchers.IO) {
        val calendars = mutableListOf<CalendarInfo>()

        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE
        )

        val cursor: Cursor? = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME + " ASC"
        )

        cursor?.use { c ->
            while (c.moveToNext()) {
                val id = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                val displayName = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                val colorInt = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                val accountName = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                val accountType = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))

                val calendarInfo = CalendarInfo(
                    id = id,
                    name = displayName,
                    color = colorInt.toUInt().toLong(),
                    accountName = accountName,
                    accountType = accountType
                )

                calendars.add(calendarInfo)
            }
        }

        calendars
    }
}

data class CalendarInfo(
    val id: String,
    val name: String,
    val color: Long,
    val accountName: String,
    val accountType: String
) {
    val displaySource: String
        get() = when {
            accountType.contains("google") -> "Google Calendar"
            accountType.contains("icloud") -> "iCloud Calendar"
            else -> "Local Calendar"
        }
}