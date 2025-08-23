import SwiftUI

struct MonthView: View {
    @Environment(CalendarViewModel.self) var viewModel

    // State for settled detection
    @State private var isDragging = false
    @State private var settledMonthIndex: Int? = nil
    @State private var scrollOffset: CGFloat = 0

    // State for programmatic scroll control
    @State private var currentPageIndex: Int = 0

    private let screenWidth = UIScreen.main.bounds.width

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
            let index = (viewModel.firstDayOfWeek.rawValue - 1 + i) % 7
            let shortName = weekdays[index]
            // Take first character for single letter display
            labels.append(String(shortName.prefix(1)).uppercased())
        }

        return labels
    }


    private var previousMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: viewModel.currentMonth) ?? viewModel.currentMonth
    }

    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: viewModel.currentMonth) ?? viewModel.currentMonth
    }

    private var weeksInMonth: [[Date]] {
        return weeksInMonth(for: viewModel.currentMonth)
    }

    private func weeksInMonth(for date: Date) -> [[Date]] {
        var calendar = Calendar.current
        calendar.firstWeekday = viewModel.firstDayOfWeek.rawValue

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

            // Horizontally scrollable month view
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<viewModel.getMonthRangeSize(), id: \.self) { pageIndex in
                            MonthContentView(
                                month: viewModel.getMonthForPage(pageIndex),
                                selectedDate: viewModel.selectedDate,
                                eventsByDate: viewModel.events,
                                onDateSelected: viewModel.selectDate,
                                firstDayOfWeek: viewModel.firstDayOfWeek,
                                highlightSundays: viewModel.highlightSundays,
                                highlightSaturdays: viewModel.highlightSaturdays
                            )
                            .containerRelativeFrame(.horizontal)
                            .id(pageIndex)
                        }
                    }
                    .scrollTargetLayout()
                }
                .onAppear {
                    // Scroll to current month on appear
                    let initialIndex = viewModel.getCurrentMonthIndex()
                    proxy.scrollTo(initialIndex, anchor: .leading)
                }
                .onChange(of: viewModel.currentMonth) { _, newMonth in
                    // When currentMonth changes externally, scroll to that month
                    let targetIndex = viewModel.getCurrentMonthIndex()
                    if targetIndex != currentPageIndex {
                        currentPageIndex = targetIndex
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(targetIndex, anchor: .leading)
                        }
                    }
                }
                .onChange(of: viewModel.selectedDate) { _, newSelectedDate in
                    // When selectedDate changes (e.g., today button), scroll to that month
                    let selectedMonth = Calendar.current.dateInterval(of: .month, for: newSelectedDate)?.start ?? newSelectedDate
                    let currentMonthStart = Calendar.current.dateInterval(of: .month, for: viewModel.currentMonth)?.start ?? viewModel.currentMonth

                    // Only scroll if selectedDate is in a different month
                    if !Calendar.current.isDate(selectedMonth, equalTo: currentMonthStart, toGranularity: .month) {
                        // Find the index for the selected month
                        for (index, _) in (0..<viewModel.getMonthRangeSize()).enumerated() {
                            let pageMonth = viewModel.getMonthForPage(index)
                            let pageMonthStart = Calendar.current.dateInterval(of: .month, for: pageMonth)?.start ?? pageMonth
                            if Calendar.current.isDate(selectedMonth, equalTo: pageMonthStart, toGranularity: .month) {
                                currentPageIndex = index
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(index, anchor: .leading)
                                }
                                break
                            }
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .coordinateSpace(name: "ScrollView")
            .modifier(ScrollOffsetModifier(scrollOffset: $scrollOffset, isDragging: $isDragging, onSettled: detectSettledMonth))
            .frame(height: getWeekRowHeight() * 6)
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Initialize to current month index
            let initialIndex = viewModel.getCurrentMonthIndex()
            settledMonthIndex = initialIndex
            currentPageIndex = initialIndex
        }
    }

    // Detect which month is >50% visible
    private func detectSettledMonth() {
        let monthIndex = Int(round(scrollOffset / screenWidth))
        let clampedIndex = max(0, min(monthIndex, viewModel.getMonthRangeSize() - 1))


        if settledMonthIndex != clampedIndex {
            settledMonthIndex = clampedIndex
            currentPageIndex = clampedIndex
            onMonthSettled(clampedIndex)
        }
    }


    // Handle month changes and loading logic
    private func onMonthSettled(_ index: Int) {
        let settledMonth = viewModel.getMonthForPage(index)


        // Month change detection
        if !Calendar.current.isDate(settledMonth, equalTo: viewModel.currentMonth, toGranularity: .month) {
            viewModel.onMonthChanged(settledMonth)
        }

        // Loading logic
        if viewModel.shouldLoadEventsForMonth(settledMonth) {
            viewModel.onLoadEventsForMonth(settledMonth)
        }

        // ENHANCED: Smart date selection
        updateSelectedDateForMonth(settledMonth)

    }

    // Smart date selection: Choose today if in this month, otherwise first day
    private func updateSelectedDateForMonth(_ month: Date) {
        let today = Date()
        let calendar = Calendar.current

        // Check if today is in this month
        if calendar.isDate(today, equalTo: month, toGranularity: .month) {
            // Today is in this month, select today
            viewModel.selectedDate = today
        } else {
            // Today is not in this month, select first day
            viewModel.setSelectedDateToFirstOfMonth(month)
        }
    }

}


// Cross-platform scroll offset modifier that works on iOS 17+ and iOS 18+
private struct ScrollOffsetModifier: ViewModifier {
    @Binding var scrollOffset: CGFloat
    @Binding var isDragging: Bool
    let onSettled: () -> Void

    @State private var lastOffset: CGFloat = 0
    @State private var settleTimer: Timer?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.x
                } action: { oldOffset, newOffset in
                    scrollOffset = newOffset

                    // Detect if scrolling started
                    if abs(newOffset - lastOffset) > 1 && !isDragging {
                        isDragging = true
                    }

                    lastOffset = newOffset

                    // Cancel previous timer and start new one
                    settleTimer?.invalidate()
                    settleTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        if isDragging {
                            isDragging = false
                            onSettled()
                        }
                    }
                }
        } else {
            // Fallback for iOS 17 - use GeometryReader approach
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("ScrollView")).minX)
                    }
                )
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    let newOffset = -offset
                    scrollOffset = newOffset

                    // Detect if scrolling started
                    if abs(newOffset - lastOffset) > 1 && !isDragging {
                        isDragging = true
                    }

                    lastOffset = newOffset

                    // Cancel previous timer and start new one
                    settleTimer?.invalidate()
                    settleTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        if isDragging {
                            isDragging = false
                            onSettled()
                        }
                    }
                }
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Month content view for ScrollView
private struct MonthContentView: View {
    let month: Date
    let selectedDate: Date
    let eventsByDate: [Date: [Event]]
    let onDateSelected: (Date) -> Void
    let firstDayOfWeek: FirstDayOfWeek
    let highlightSundays: Bool
    let highlightSaturdays: Bool

    private func weeksInMonth(for date: Date, firstDayOfWeek: FirstDayOfWeek) -> [[Date]] {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayOfWeek.rawValue

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

        // Add days from next month to complete weeks
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

    // Helper function for date highlighting (holidays, weekends)
    private func shouldHighlightDate(_ date: Date, highlightSundays: Bool, highlightSaturdays: Bool) -> Bool {
        let standardCalendar = Calendar.current
        let weekday = standardCalendar.component(.weekday, from: date)

        // Check for Sunday (weekday = 1)
        if weekday == FirstDayOfWeek.sunday.rawValue && highlightSundays {
            return true
        }

        // Check for Saturday (weekday = 7)
        if weekday == FirstDayOfWeek.saturday.rawValue && highlightSaturdays {
            return true
        }

        // Note: Holiday checking would need HolidayManager access
        // For now, just do weekend highlighting
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(weeksInMonth(for: month, firstDayOfWeek: firstDayOfWeek).enumerated()), id: \.offset) { weekIndex, week in
                WeekRowView(
                    weekDates: week,
                    selectedDate: selectedDate,
                    currentMonth: month,
                    eventsByDate: eventsByDate,
                    onDateSelected: onDateSelected,
                    isToday: { date in
                        Calendar.current.isDateInToday(date)
                    },
                    shouldHighlightDate: { date in
                        shouldHighlightDate(date, highlightSundays: highlightSundays, highlightSaturdays: highlightSaturdays)
                    }
                )
                .id("\(month.timeIntervalSince1970)-week-\(weekIndex)")
            }
        }
    }
}

#Preview {
    MonthView()
        .environment(CalendarViewModel(languageManager: LanguageManager()))
}