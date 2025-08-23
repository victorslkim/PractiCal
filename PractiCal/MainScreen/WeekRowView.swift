import SwiftUI

struct WeekRowView: View {
    @Bindable var viewModel: CalendarViewModel
    let weekDates: [Date] // exactly 7 dates
    
    private let daySpacing: CGFloat = 0
    private let dateRowHeight: CGFloat = 24
    private let chipRowMax: Int = 4
    private let bottomPadding: CGFloat = 8
    private let chipBottomPadding: CGFloat = 2
    
    private let chipHeight: CGFloat = 16
    
    // Calculate total height: date row + 4 chip rows (including chip bottom padding) + padding
    func getWeekRowHeight() -> CGFloat {
        let effectiveChipRowHeight = chipHeight + chipBottomPadding
        let eventRowsHeight = CGFloat(chipRowMax) * effectiveChipRowHeight
        return dateRowHeight + eventRowsHeight + bottomPadding + 2
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - daySpacing * 6) / 7
            
            ZStack(alignment: .topLeading) {
                // Background layer for full day cell highlighting
                HStack(spacing: daySpacing) {
                    ForEach(weekDates, id: \.self) { date in
                        Rectangle()
                            .fill(backgroundColor(for: date))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectDate(date)
                            }
                    }
                }
                .frame(height: getWeekRowHeight())
            
                VStack(spacing: 0) {
                    DateNumbersRow(
                        weekDates: weekDates,
                        daySpacing: daySpacing,
                        dateRowHeight: dateRowHeight,
                        viewModel: viewModel,
                        dayNumber: dayNumber,
                        textColor: textColor
                    )
                    
                    EventsAreaView(
                        weekDates: weekDates,
                        dayWidth: dayWidth,
                        daySpacing: daySpacing,
                        chipHeight: chipHeight,
                        chipRowMax: chipRowMax,
                        eventLayout: eventLayout,
                        shouldShowEventName: shouldShowEventName,
                        singleDayEventsForDate: singleDayEventsForDate,
                        selectedDate: viewModel.selectedDate
                    )
                    
                    // Bottom padding spacer
                    Spacer()
                        .frame(height: bottomPadding)
                }
                .allowsHitTesting(false)
            }
            .frame(height: getWeekRowHeight(), alignment: .top)
            .clipped()
        }
    }
    
    // MARK: - Event Layout Logic
    
    // Dictionary mapping: [dayIndex][rowIndex] = Event
    private var eventLayout: [[Event?]] {
        var layout = Array(repeating: Array(repeating: nil as Event?, count: chipRowMax), count: 7)
        
        // Step 1: Layout multi-day events
        let multiDayEvents = getMultiDayEvents()
        var assignedRows: [Event: Int] = [:]
        
        for event in multiDayEvents {
            guard let range = rangeInWeek(for: event) else { continue }
            
            // Find available row for this event across all its days
            var assignedRow: Int?
            for row in 0..<chipRowMax {
                var canUseRow = true
                for dayIdx in range.startIdx...range.endIdx {
                    if layout[dayIdx][row] != nil {
                        canUseRow = false
                        break
                    }
                }
                if canUseRow {
                    assignedRow = row
                    break
                }
            }
            
            // Assign the event to the found row
            if let row = assignedRow {
                assignedRows[event] = row
                for dayIdx in range.startIdx...range.endIdx {
                    layout[dayIdx][row] = event
                }
            }
        }
        
        // Step 2: Layout single-day events
        for (dayIdx, date) in weekDates.enumerated() {
            let singleDayEvents = singleDayEventsForDate(date)
            var placedSingleDayEvents = 0
            
            for row in 0..<chipRowMax {
                if layout[dayIdx][row] == nil && placedSingleDayEvents < singleDayEvents.count {
                    layout[dayIdx][row] = singleDayEvents[placedSingleDayEvents]
                    placedSingleDayEvents += 1
                }
            }
        }
        
        return layout
    }
    
    // MARK: - Helper Methods
    
    private func getMultiDayEvents() -> [Event] {
        let all = weekDates.flatMap { viewModel.eventsForDate($0) }
        let unique = Array(Set(all.filter { $0.isMultiDay }))
        return unique.sorted { $0.time < $1.time }
    }
    
    private func rangeInWeek(for event: Event) -> (startIdx: Int, endIdx: Int, originalStartIdx: Int)? {
        let cal = Calendar.current
        let s = cal.startOfDay(for: event.time)
        let e = cal.startOfDay(for: event.endTime)
        guard let first = weekDates.first, let last = weekDates.last else { return nil }
        if e < cal.startOfDay(for: first) || s > cal.startOfDay(for: last) { return nil }
        let startIdx = max(0, weekDates.firstIndex(where: { cal.isDate($0, inSameDayAs: s) }) ?? 0)
        let endIdx = min(6, weekDates.lastIndex(where: { cal.isDate($0, inSameDayAs: e) }) ?? 6)
        let originalStartIdx = weekDates.firstIndex(where: { cal.isDate($0, inSameDayAs: s) }) ?? 0
        return (startIdx, endIdx, originalStartIdx)
    }
    
    private func shouldShowEventName(for event: Event, dayIndex: Int) -> Bool {
        guard let range = rangeInWeek(for: event) else { return false }
        
        // Show name if this is the original start day in the week
        if dayIndex == range.originalStartIdx {
            return true
        }
        
        // Show name if this is the start of the week (Sunday, index 0) and event continues from previous week
        if dayIndex == 0 && range.originalStartIdx < 0 {
            return true
        }
        
        return false
    }
    
    private func singleDayEventsForDate(_ date: Date) -> [Event] {
        return viewModel.eventsForDate(date).filter { !$0.isMultiDay }
    }
    
    private func dayNumber(for date: Date) -> String {
        return localizedDayNumber(for: date)
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if viewModel.isSelected(date) { 
            return Color(.label)
        }
        if viewModel.isToday(date) { 
            return Color(.systemGray4)
        }
        return .clear
    }
    
    private func textColor(for date: Date) -> Color {
        if viewModel.isSelected(date) { 
            return Color(.systemBackground)
        }
        if viewModel.isToday(date) { return .primary }
        
        if viewModel.shouldHighlightDate(date) {
            if viewModel.isInCurrentMonth(date) {
                return .red
            } else {
                return .red.opacity(0.5)
            }
        }
        
        if viewModel.isInCurrentMonth(date) { return .primary }
        return .secondary
    }
}