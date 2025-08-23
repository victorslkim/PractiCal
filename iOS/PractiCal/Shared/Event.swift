import Foundation
import SwiftUI

struct Event: Identifiable, Hashable {
    let id: String // EventKit event identifier or UUID for sample events
    let name: String
    let time: Date
    let endTime: Date
    let location: String
    let description: String
    let calendarId: String
    let calendarColor: Color
    let isAllDay: Bool
    let isRecurring: Bool
    
    
    var timeString: String {
        if isAllDay {
            return L("all_day")
        }
        
        // Use global localized time formatting
        return localizedTime(for: time)
    }
    
    var isMultiDay: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(time, inSameDayAs: endTime)
    }
    
    var isFullDay: Bool {
        isAllDay || isMultiDay
    }
    
    // Helper to get the span of days for this event
    func daySpan(in month: Date) -> (start: Date, end: Date, days: Int) {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: time)
        let endDay = calendar.startOfDay(for: endTime)
        let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return (start: startDay, end: endDay, days: dayCount + 1)
    }
    
}

