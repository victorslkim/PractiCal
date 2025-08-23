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
    
    var body: some View {
        // Replace HStack with ZStack for absolute positioning
        ZStack(alignment: .leading) {
            // Background spacer to maintain row height
            Rectangle()
                .fill(Color.clear)
                .frame(width: dayWidth * 7 + daySpacing * 6, height: chipHeight)
            
            // Find unique events and create spanning chips
            ForEach(uniqueEventsInRow(), id: \.event.id) { eventInfo in
                SpanningMultiDayEventChip(
                    event: eventInfo.event,
                    startDayIndex: eventInfo.startDayIndex,
                    endDayIndex: eventInfo.endDayIndex,
                    dayWidth: dayWidth,
                    daySpacing: daySpacing,
                    chipHeight: chipHeight,
                    weekDates: weekDates,
                    selectedDate: selectedDate
                )
            }
        }
    }
    
    private func uniqueEventsInRow() -> [(event: Event, startDayIndex: Int, endDayIndex: Int)] {
        var processedEvents = Set<Event>()
        var result: [(event: Event, startDayIndex: Int, endDayIndex: Int)] = []
        
        for dayIndex in weekDates.indices {
            if let event = eventLayout[dayIndex][row],
               event.isMultiDay,
               !processedEvents.contains(event) {
                processedEvents.insert(event)
                
                // Calculate span for this event in this week
                let calendar = Calendar.current
                let startDayIndex = weekDates.firstIndex { calendar.isDate($0, inSameDayAs: event.time) } ?? 0
                let endDayIndex = weekDates.lastIndex { calendar.isDate($0, inSameDayAs: event.endTime) } ?? (weekDates.count - 1)
                
                result.append((event: event, startDayIndex: max(0, startDayIndex), endDayIndex: min(weekDates.count - 1, endDayIndex)))
            }
        }
        
        return result
    }
}

struct SpanningMultiDayEventChip: View {
    let event: Event
    let startDayIndex: Int
    let endDayIndex: Int
    let dayWidth: CGFloat
    let daySpacing: CGFloat
    let chipHeight: CGFloat
    let weekDates: [Date]
    let selectedDate: Date
    
    private var spanDays: Int {
        endDayIndex - startDayIndex + 1
    }
    
    private var chipWidth: CGFloat {
        dayWidth * CGFloat(spanDays) + daySpacing * CGFloat(max(0, spanDays - 1))
    }
    
    private var offsetX: CGFloat {
        (dayWidth + daySpacing) * CGFloat(startDayIndex)
    }
    
    private var isEventStartDay: Bool {
        let calendar = Calendar.current
        return calendar.isDate(weekDates[startDayIndex], inSameDayAs: event.time)
    }
    
    private var shouldShowVerticalBar: Bool {
        isEventStartDay || startDayIndex == 0
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
        .frame(width: chipWidth, height: chipHeight)
        .overlay(
            HStack {
                // Always show event name - let truncation handle sizing
                Text(event.name)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.leading, shouldShowVerticalBar ? 6 : 3)
                    .allowsHitTesting(false)
                Spacer()
            }
        )
        .offset(x: offsetX)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
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