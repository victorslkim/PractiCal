import SwiftUI
import EventKit

// MARK: - Event Helper Functions
/// Common helper functions for event-related views

struct EventHelpers {
    
    
    // MARK: - Calendar Color Helper
    
    /// Gets the color for a calendar from the calendar manager or calendar's CGColor
    static func calendarColor(for calendarId: String, from availableCalendars: [EKCalendar], calendarColors: [String: Color]) -> Color {
        if let calendar = availableCalendars.first(where: { $0.calendarIdentifier == calendarId }) {
            return calendarColors[calendar.calendarIdentifier] ?? 
                   (calendar.cgColor != nil ? Color(calendar.cgColor!) : .blue)
        }
        return .blue
    }
    
    // MARK: - Date Formatting
    
    /// Formats date based on whether it's all-day or not
    static func formatDate(_ date: Date, isAllDay: Bool) -> String {
        if isAllDay {
            return localizedMediumDate(for: date)
        } else {
            return localizedMediumDateWithTime(for: date)
        }
    }
}

