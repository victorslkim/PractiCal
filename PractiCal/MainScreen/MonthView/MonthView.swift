import SwiftUI

struct MonthView: View {
    @Bindable var viewModel: CalendarViewModel
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Fixed height matching WeekRowView (day number row + 4 event chip rows)
    private func getWeekRowHeight() -> CGFloat {
        let chipHeight: CGFloat = 16
        let dateRowHeight: CGFloat = 24
        let chipRowMax = 4
        let bottomPadding: CGFloat = 8
        let chipBottomPadding: CGFloat = 2
        let extra: CGFloat = 2
        
        let effectiveChipRowHeight = chipHeight + chipBottomPadding
        let eventRowsHeight = CGFloat(chipRowMax) * effectiveChipRowHeight
        return dateRowHeight + eventRowsHeight + bottomPadding + extra
    }
    
    private var dayLabels: [String] {
        var calendar = Calendar.current
        calendar.firstWeekday = FirstDayOfWeek.current.rawValue
        
        let weekdays = calendar.shortWeekdaySymbols
        var labels: [String] = []
        
        for i in 0..<7 {
            let index = (FirstDayOfWeek.current.rawValue - 1 + i) % 7
            let shortName = weekdays[index]
            // Take first character for single letter display
            labels.append(String(shortName.prefix(1)).uppercased())
        }
        
        return labels
    }
    
    
    private var weeksInMonth: [[Date]] {
        return weeksInMonth(for: viewModel.currentMonth)
    }
    
    private func weeksInMonth(for date: Date) -> [[Date]] {
        var calendar = Calendar.current
        calendar.firstWeekday = FirstDayOfWeek.current.rawValue
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        
        // Add days from previous month if needed
        if daysFromPreviousMonth > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) ?? firstOfMonth
            guard let prevMonthInterval = calendar.dateInterval(of: .month, for: previousMonth) else { return [] }
            
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 0
            let startDay = daysInPrevMonth - daysFromPreviousMonth + 1
            
            for day in startDay...daysInPrevMonth {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: prevMonthInterval.start) {
                    days.append(date)
                }
            }
        }
        
        // Add days from current month
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 0
        for day in 1...daysInCurrentMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Only add days from next month if we don't have complete weeks
        // Stop when we have complete weeks (multiples of 7)
        let remainingInLastWeek = days.count % 7
        if remainingInLastWeek > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) ?? firstOfMonth
            let daysToAdd = 7 - remainingInLastWeek
            for day in 1...daysToAdd {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    days.append(date)
                }
            }
        }
        
        // Group days into weeks
        var weeks: [[Date]] = []
        var current: [Date] = []
        for (idx, d) in days.enumerated() {
            current.append(d)
            if current.count == 7 {
                weeks.append(current)
                current = []
            } else if idx == days.count - 1 {
                while current.count < 7 { current.append(d) }
                weeks.append(current)
            }
        }
        return weeks
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day labels header (fixed)
            HStack {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, LayoutConstants.horizontalPadding)
            .padding(.bottom, LayoutConstants.verticalPadding)
            
            // Simple VStack with transition animations and fixed height
            VStack(spacing: 0) {
                ForEach(weeksInMonth, id: \.self) { week in
                    WeekRowView(viewModel: viewModel, weekDates: week)
                }
            }
            .frame(height: getWeekRowHeight() * CGFloat(weeksInMonth.count))
            .id(Calendar.current.dateInterval(of: .month, for: viewModel.currentMonth)?.start ?? viewModel.currentMonth)
            .transition(.asymmetric(
                insertion: .move(edge: viewModel.transitionDirection == .left ? .trailing : .leading),
                removal: .move(edge: viewModel.transitionDirection == .left ? .leading : .trailing)
            ))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Start transition when swipe reaches threshold
                        if abs(value.translation.width) > 50 {
                            if value.translation.width > 50 && viewModel.transitionDirection != .right {
                                viewModel.navigateToPreviousMonth()
                            } else if value.translation.width < -50 && viewModel.transitionDirection != .left {
                                viewModel.navigateToNextMonth()
                            }
                        }
                    }
            )
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    MonthView(viewModel: CalendarViewModel(languageManager: LanguageManager()))
}