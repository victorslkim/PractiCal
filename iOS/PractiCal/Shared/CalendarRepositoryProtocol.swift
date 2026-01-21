import Foundation
import EventKit
import SwiftUI

// MARK: - CalendarRepository API Documentation
//
// This file defines the CalendarRepository protocol and documents the calendar API
// used by PractiCal on both iOS and Android platforms.
//
// ## Cross-Platform API Overview
//
// The CalendarRepository provides a unified interface for calendar operations:
//
// ### Permission Management
// - `hasPermission: Bool` - Check if calendar access is granted
// - `requestPermission()` - Request calendar access from the user
//
// ### Calendar Information
// - `selectedCalendarIds: Set<String>` - Currently selected calendar IDs for display
// - `availableCalendars` - All calendars the app can access
// - `calendarColors: [String: Color]` - Custom colors for each calendar
//
// ### Event Operations
// - `fetchEvents(from:to:)` - Fetch events in a date range (sync)
// - `fetchEventsAsync(from:to:)` - Fetch events in a date range (async)
// - `saveEvent(...)` - Create or update an event
// - `deleteEvent(eventId:)` - Delete an event
// - `forceRefresh()` - Refresh calendar data from system
//
// ## Platform Differences
//
// ### iOS (EventKit)
// - Uses EKEventStore for all calendar operations
// - Permission requested via requestFullAccessToEvents()
// - Calendar colors from EKCalendar.cgColor
// - Events identified by EKEvent.eventIdentifier
//
// ### Android (ContentResolver + CalendarContract)
// - Uses ContentResolver with CalendarContract provider
// - Permission requested via runtime permission system (READ_CALENDAR, WRITE_CALENDAR)
// - Calendar colors from CalendarContract.Calendars.CALENDAR_COLOR
// - Events identified by CalendarContract.Events._ID

/// Protocol defining the calendar repository API for PractiCal.
/// Implementations handle all interactions with the device's calendar system.
///
/// ## Thread Safety
/// All async methods are safe to call from any thread and will dispatch UI updates
/// to the main thread automatically.
///
/// ## Usage
/// ```swift
/// let calendar: CalendarRepositoryProtocol = CalendarManager()
/// await calendar.requestPermission { granted in
///     if granted {
///         let events = calendar.fetchEvents(from: startDate, to: endDate)
///     }
/// }
/// ```
protocol CalendarRepositoryProtocol: AnyObject {

    // MARK: - Permission Management

    /// Whether the app has permission to access the user's calendars.
    /// This is updated automatically when permission is requested or changes.
    var hasPermission: Bool { get }

    /// Requests permission to access the user's calendar.
    /// - Parameter onComplete: Callback invoked with the permission result (true if granted)
    /// - Note: On iOS, this presents the system permission dialog if not previously determined.
    ///         On Android, permissions are handled via the manifest and runtime permission system.
    func requestPermission(onComplete: @escaping (Bool) -> Void) async

    // MARK: - Calendar Information

    /// The set of calendar IDs currently selected for display.
    /// Events are only fetched from calendars in this set.
    /// Persisted to UserDefaults/SharedPreferences automatically.
    var selectedCalendarIds: Set<String> { get set }

    /// All calendars available on the device that the app can access.
    /// Returns an empty array if permission has not been granted.
    /// On iOS: Returns [EKCalendar]
    /// On Android: Returns List<CalendarInfo>
    var availableCalendars: [EKCalendar] { get }

    /// Custom colors assigned to each calendar, keyed by calendar ID.
    /// Used for consistent event display across the app.
    var calendarColors: [String: Color] { get }

    // MARK: - Event Fetching

    /// Fetches events within the specified date range synchronously.
    /// - Parameters:
    ///   - startDate: The start of the date range (inclusive)
    ///   - endDate: The end of the date range (inclusive)
    /// - Returns: Dictionary mapping dates to arrays of events occurring on each date.
    ///            Multi-day events appear in each day they span.
    /// - Note: Only events from calendars in `selectedCalendarIds` are returned.
    ///         Events are sorted by: all-day events first, then by start time.
    func fetchEvents(from startDate: Date, to endDate: Date) -> [Date: [Event]]

    /// Fetches events within the specified date range asynchronously.
    /// Preferred for loading large date ranges to avoid blocking the main thread.
    /// - Parameters:
    ///   - startDate: The start of the date range (inclusive)
    ///   - endDate: The end of the date range (inclusive)
    /// - Returns: Dictionary mapping dates to arrays of events occurring on each date.
    func fetchEventsAsync(from startDate: Date, to endDate: Date) async -> [Date: [Event]]

    // MARK: - Event Modification

    /// Saves a new event or updates an existing one.
    /// - Parameters:
    ///   - eventId: The ID of an existing event to update, or nil to create a new event
    ///   - title: The event title/name (required, non-empty)
    ///   - startDate: When the event starts
    ///   - endDate: When the event ends (must be >= startDate)
    ///   - isAllDay: Whether this is an all-day event
    ///   - location: The event location (pass empty string for none)
    ///   - notes: Additional notes/description (pass empty string for none)
    ///   - calendarId: The ID of the calendar to save the event to (must be writable)
    /// - Returns: True if the event was saved successfully, false otherwise
    /// - Note: For recurring events, this modifies only the single instance (span: .thisEvent)
    func saveEvent(
        eventId: String?,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String,
        notes: String,
        calendarId: String
    ) async -> Bool

    /// Deletes an event from the calendar.
    /// - Parameter eventId: The ID of the event to delete
    /// - Returns: True if the event was deleted successfully, false otherwise
    /// - Note: Returns false if:
    ///         - The event doesn't exist
    ///         - Permission is denied
    ///         - The calendar is read-only
    ///         For recurring events, this deletes only the single instance
    func deleteEvent(eventId: String) async -> Bool

    // MARK: - Refresh

    /// Forces a complete refresh of calendar data from the system.
    /// Call this when:
    /// - Returning from background
    /// - After external calendar changes (e.g., from system Calendar app)
    /// - User pulls to refresh
    func forceRefresh()
}

// MARK: - CalendarManager Conformance

extension CalendarManager: CalendarRepositoryProtocol {
    // CalendarManager already implements all required methods
}
