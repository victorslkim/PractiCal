import SwiftUI

struct EventsAreaView: View {
    let weekDates: [Date]
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let chipRowMax: Int
    let eventLayout: [[Event?]] // [dayIndex][rowIndex] = Event
    let shouldShowEventName: (Event, Int) -> Bool
    let singleDayEventsForDate: (Date) -> [Event]
    let selectedDate: Date
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Multi-day events layer
            MultiDayLanesView(
                weekDates: weekDates,
                dayWidth: dayWidth,
                daySpacing: daySpacing,
                chipHeight: chipHeight,
                chipRowMax: chipRowMax,
                eventLayout: eventLayout,
                shouldShowEventName: shouldShowEventName,
                selectedDate: selectedDate
            )
            
            // Single-day events layer
            SingleDayChipsView(
                weekDates: weekDates,
                dayWidth: dayWidth,
                daySpacing: daySpacing,
                chipHeight: chipHeight,
                chipRowMax: chipRowMax,
                eventLayout: eventLayout,
                selectedDate: selectedDate
            )
        }
        .contentShape(Rectangle())
    }
}