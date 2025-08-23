import SwiftUI

struct SingleDayChipsView: View {
    let weekDates: [Date]
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let chipRowMax: Int
    let eventLayout: [[Event?]] // [dayIndex][rowIndex] = Event
    let selectedDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<chipRowMax, id: \.self) { row in
                SingleDayChipsRow(
                    row: row,
                    dayWidth: dayWidth,
                    daySpacing: daySpacing,
                    chipHeight: chipHeight,
                    eventLayout: eventLayout,
                    selectedDate: selectedDate
                )
            }
        }
    }
}

struct SingleDayChipsRow: View {
    let row: Int
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let eventLayout: [[Event?]]
    let selectedDate: Date
    
    private func eventOrFake(dayIndex: Int) -> Event? {
        let event = eventLayout[dayIndex][row]
        if let event = event, !event.isMultiDay {
            return event
        } else {
            return nil
        }
    }
    
    @ViewBuilder
    private func dayEventView(dayIndex: Int) -> some View {
        if let event = eventOrFake(dayIndex: dayIndex) {
            SingleDayEventChip(event: event, dayIndex: dayIndex, dayWidth: dayWidth, chipHeight: chipHeight, selectedDate: selectedDate)
        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(width: dayWidth, height: chipHeight)
                .padding(.bottom, 2)
        }
    }
    
    var body: some View {
        HStack(spacing: daySpacing) {
            ForEach(0..<7, id: \.self) { dayIndex in
                dayEventView(dayIndex: dayIndex)
            }
        }
    }
}

struct SingleDayEventChip: View {
    let event: Event
    let dayIndex: Int
    let dayWidth: CGFloat
    let chipHeight: CGFloat
    let selectedDate: Date
    
    var body: some View {
        HStack(spacing: 0) {
            // Vertical color bar
            Rectangle()
                .fill(event.calendarColor)
                .frame(width: 3)
            
            if event.isAllDay {
                // All-day events: background with brighter color
                Rectangle()
                    .fill(event.calendarColor.opacity(0.2))
                    .frame(maxWidth: .infinity)
            } else {
                // Regular events: no background color
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: dayWidth, height: chipHeight)
        .overlay(
            Text(event.name)
                .font(.system(size: 10, weight: .regular))
                .lineLimit(1)
                .foregroundColor(eventTextColor(for: event))
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, maxHeight: chipHeight, alignment: .leading)
        )
        .padding(.bottom, 2)
        .contentShape(Rectangle())
    }
    
    private func eventTextColor(for event: Event) -> Color {
        let calendar = Calendar.current
        let eventDate = calendar.startOfDay(for: event.time)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        // Check if this event is on the selected date
        if calendar.isDate(eventDate, inSameDayAs: selectedDay) {
            // Use opposite color when day is selected
            return Color(.systemBackground)
        }
        
        // Default colors based on event type
        return event.isAllDay ? .white : .primary
    }
}