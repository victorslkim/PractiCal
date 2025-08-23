import SwiftUI

struct CalendarPreview: View {
    let firstDayOfWeek: FirstDayOfWeek
    let highlightHolidays: Bool
    let highlightSaturdays: Bool
    let highlightSundays: Bool
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = firstDayOfWeek.rawValue
        return cal
    }
    
    // Fixed preview month: December 2024
    private var referenceMonthDate: Date {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 12
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }

    private var previewDates: [Date] {
        let ref = referenceMonthDate
        guard let monthInterval = calendar.dateInterval(of: .month, for: ref) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var dates: [Date] = []
        
        // Add days from previous month if needed
        if daysFromPreviousMonth > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) ?? firstOfMonth
            guard let prevMonthInterval = calendar.dateInterval(of: .month, for: previousMonth) else { return [] }
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 0
            let startDay = daysInPrevMonth - daysFromPreviousMonth + 1
            
            for day in startDay...daysInPrevMonth {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: prevMonthInterval.start) {
                    dates.append(date)
                }
            }
        }
        
        // Add days from current month
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: ref)?.count ?? 0
        for day in 1...daysInCurrentMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // Add days from next month to fill complete weeks (5 or 6 depending on layout)
        let totalRequired = daysFromPreviousMonth + daysInCurrentMonth
        let totalCells = ((totalRequired + 6) / 7) * 7
        let remainingCells = totalCells - dates.count
        if remainingCells > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) ?? firstOfMonth
            for day in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
    private var weekHeaders: [String] {
        var headers: [String] = []
        let weekdays = calendar.shortWeekdaySymbols
        
        for i in 0..<7 {
            let index = (firstDayOfWeek.rawValue - 1 + i) % 7
            let shortName = weekdays[index]
            // Take first character for single letter display
            headers.append(String(shortName.prefix(1)).uppercased())
        }
        return headers
    }
    
    private func shouldHighlight(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        
        if highlightSundays && weekday == 1 { return true }
        if highlightSaturdays && weekday == 7 { return true }
        if highlightHolidays && isHoliday(date) { return true }
        
        return false
    }
    
    private func isHoliday(_ date: Date) -> Bool {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 12
        comps.day = 25
        guard let dec25 = calendar.date(from: comps) else { return false }
        return calendar.isDate(date, inSameDayAs: dec25)
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: referenceMonthDate, toGranularity: .month)
    }
    
    private func textColor(for date: Date) -> Color {
        if shouldHighlight(date) {
            if isInCurrentMonth(date) {
                return .red
            } else {
                return .red.opacity(0.5)
            }
        }
        
        if isInCurrentMonth(date) {
            return .primary
        }
        return .secondary
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Month header
            Text(L("december_2024"))
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            
            // Week headers
            HStack(spacing: 0) {
                ForEach(weekHeaders, id: \.self) { header in
                    Text(header)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(Array(previewDates.enumerated()), id: \.offset) { index, date in
                    let dayNumber = calendar.component(.day, from: date)
                    
                    Text("\(dayNumber)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(textColor(for: date))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(calendar.isDateInToday(date) ? Color.blue.opacity(0.4) : Color.clear)
                        )
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    CalendarPreview(
        firstDayOfWeek: .sunday,
        highlightHolidays: true,
        highlightSaturdays: false,
        highlightSundays: true
    )
}