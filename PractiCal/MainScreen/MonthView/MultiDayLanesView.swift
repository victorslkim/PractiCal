import SwiftUI

struct MultiDayLanesView: View {
    let weekDates: [Date]
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let chipRowMax: Int
    let eventLayout: [[Event?]] // [dayIndex][rowIndex] = Event
    let shouldShowEventName: (Event, Int) -> Bool
    let selectedDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<chipRowMax, id: \.self) { row in
                MultiDayLanesRow(
                    row: row,
                    weekDates: weekDates,
                    dayWidth: dayWidth,
                    daySpacing: daySpacing,
                    chipHeight: chipHeight,
                    eventLayout: eventLayout,
                    shouldShowEventName: shouldShowEventName,
                    selectedDate: selectedDate
                )
            }
        }
    }
}

struct MultiDayLanesRow: View {
    let row: Int
    let weekDates: [Date]
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let eventLayout: [[Event?]]
    let shouldShowEventName: (Event, Int) -> Bool
    let selectedDate: Date
    
    @ViewBuilder
    private func dayView(dayIndex: Int) -> some View {
        let event = eventLayout[dayIndex][row]
        
        if let event = event, event.isMultiDay {
            // Multi-day event chip
            MultiDayEventChip(
                event: event,
                dayIndex: dayIndex,
                dayDate: weekDates[dayIndex],
                dayWidth: dayWidth,
                chipHeight: chipHeight,
                shouldShowName: shouldShowEventName(event, dayIndex),
                selectedDate: selectedDate
            )
        } else {
            // Empty space
            Rectangle()
                .fill(Color.clear)
                .frame(width: dayWidth, height: chipHeight)
                .padding(.bottom, 2)
        }
    }
    
    var body: some View {
        HStack(spacing: daySpacing) {
            ForEach(weekDates.indices, id: \.self) { dayIndex in
                dayView(dayIndex: dayIndex)
            }
        }
    }
}

struct MultiDayEventChip: View {
    let event: Event
    let dayIndex: Int
    let dayDate: Date
    let dayWidth: CGFloat
    let chipHeight: CGFloat
    let shouldShowName: Bool
    let selectedDate: Date
    
    private var shouldShowVerticalBar: Bool {
        // Show vertical bar if it's the start day of the event OR the first day of the week (Sunday, index 0)
        return isEventStartDay || dayIndex == 0
    }
    
    private var isEventStartDay: Bool {
        let calendar = Calendar.current
        let eventStartDay = calendar.startOfDay(for: event.time)
        let currentDay = calendar.startOfDay(for: dayDate)
        return calendar.isDate(eventStartDay, inSameDayAs: currentDay)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Vertical color bar (conditional)
            if shouldShowVerticalBar {
                Rectangle()
                    .fill(event.calendarColor)
                    .frame(width: 3)
            }
            
            // Background with brighter color
            Rectangle()
                .fill(event.calendarColor.opacity(0.2))
                .frame(maxWidth: .infinity)
        }
        .frame(width: dayWidth, height: chipHeight)
        .overlay(
            HStack {
                if shouldShowName {
                    Text(event.name)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .padding(.leading, shouldShowVerticalBar ? 6 : 3)
                        .allowsHitTesting(false)
                }
                Spacer()
            }
        )
        .padding(.bottom, 2)
        .contentShape(Rectangle())
    }
}