package com.practical.calendar.data.repository

import com.practical.calendar.data.model.Event
import kotlinx.datetime.LocalDateTime

/**
 * Interface defining the calendar repository API for PractiCal.
 *
 * This provides a common interface for calendar operations across the Android app.
 * The iOS equivalent is CalendarRepositoryProtocol in CalendarRepositoryProtocol.swift.
 *
 * ## Cross-Platform API Overview
 *
 * The CalendarRepository provides a unified interface for calendar operations:
 *
 * ### Permission Management (handled externally on Android)
 * - Permissions are managed via Android's runtime permission system
 * - Required: READ_CALENDAR, WRITE_CALENDAR
 *
 * ### Calendar Information
 * - `getAvailableCalendars()` - All calendars the app can access
 *
 * ### Event Operations
 * - `getEvents(startDate, endDate, selectedCalendarIds)` - Fetch events in a date range
 * - `saveEvent(...)` - Create or update an event
 * - `deleteEvent(eventId)` - Delete an event
 *
 * ## Platform Differences
 *
 * ### Android (ContentResolver + CalendarContract)
 * - Uses ContentResolver with CalendarContract provider
 * - Permission requested via runtime permission system (READ_CALENDAR, WRITE_CALENDAR)
 * - Calendar colors from CalendarContract.Calendars.CALENDAR_COLOR
 * - Events identified by CalendarContract.Events._ID
 * - Uses Instances table for recurring event expansion
 *
 * ### iOS (EventKit)
 * - Uses EKEventStore for all calendar operations
 * - Permission requested via requestFullAccessToEvents()
 * - Calendar colors from EKCalendar.cgColor
 * - Events identified by EKEvent.eventIdentifier
 */
interface ICalendarRepository {

    // MARK: - Calendar Information

    /**
     * Fetches all calendars available on the device.
     *
     * @return List of CalendarInfo objects representing available calendars.
     *         Returns an empty list if permission is not granted.
     */
    suspend fun getAvailableCalendars(): List<CalendarInfo>

    // MARK: - Event Fetching

    /**
     * Fetches events within the specified date range.
     *
     * @param startDate The start of the date range (inclusive)
     * @param endDate The end of the date range (inclusive)
     * @param selectedCalendarIds Set of calendar IDs to fetch events from.
     *                            Only events from these calendars are returned.
     * @return List of Event objects within the date range, sorted by start time.
     *         Multi-day events are included if they overlap the range.
     *         Recurring events are expanded into individual instances.
     *
     * Note: All-day events are handled specially:
     * - Start time is set to 00:00 of the event day
     * - End time is set to 23:59 of the last day (Android stores as next day midnight)
     */
    suspend fun getEvents(
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        selectedCalendarIds: Set<String>
    ): List<Event>

    // MARK: - Event Modification

    /**
     * Saves a new event or updates an existing one.
     *
     * @param eventId The ID of an existing event to update, or null to create a new event
     * @param title The event title/name (required, non-empty)
     * @param startDate When the event starts
     * @param endDate When the event ends (must be >= startDate)
     * @param isAllDay Whether this is an all-day event
     * @param location The event location (pass empty string for none)
     * @param description Additional notes/description (pass empty string for none)
     * @param calendarId The ID of the calendar to save the event to (must be writable)
     * @return The ID of the saved event on success, null on failure
     *
     * Note: For recurring events, this modifies only the single instance.
     * Note: All-day events are stored with end time as start of next day (Android convention).
     */
    suspend fun saveEvent(
        eventId: String?,
        title: String,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        isAllDay: Boolean,
        location: String,
        description: String,
        calendarId: String
    ): String?

    /**
     * Deletes an event from the calendar.
     *
     * @param eventId The ID of the event to delete
     * @return True if the event was deleted successfully, false otherwise.
     *
     * Note: Returns false if:
     * - The event doesn't exist
     * - Permission is denied
     * - The calendar is read-only
     * For recurring events, this deletes only the single instance.
     */
    suspend fun deleteEvent(eventId: String): Boolean
}
