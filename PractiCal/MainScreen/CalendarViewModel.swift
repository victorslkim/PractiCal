import Foundation
import SwiftUI
import EventKit

enum TransitionDirection {
    case none, left, right
}

@Observable
class CalendarViewModel {
    var selectedDate = Date()
    var currentMonth = Date()
    var isWeekView = false
    var events: [Date: [Event]] = [:]
    var isLoading: Bool = false
    var isTransitioning = false
    var transitionDirection: TransitionDirection = .none
    
    
    // Holiday manager
    private let holidayManager = HolidayManager()
    
    // Language manager for locale-aware formatting
    private let languageManager: LanguageManager
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = FirstDayOfWeek.current.rawValue
        return cal
    }
    let calendarManager = CalendarManager()
    
    init(languageManager: LanguageManager) {
        self.languageManager = languageManager
        requestCalendarPermission()
        
        // Observe color changes and reload events
        Task { @MainActor in
            for await _ in calendarManager.$calendarColors.values {
                await loadCalendarEvents()
            }
        }
        
        // Observe permission changes and reload events
        Task { @MainActor in
            for await _ in calendarManager.$hasPermission.values {
                if calendarManager.hasPermission {
                    await loadCalendarEvents()
                }
            }
        }
        Task { @MainActor in
            for await _ in calendarManager.$selectedCalendarIds.values {
                await loadCalendarEvents()
            }
        }
        
        // Observe language changes to refresh date formatting
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LanguageChanged"),
            object: nil,
            queue: .main
        ) { _ in
            // Force UI refresh by triggering a property change
            Task { @MainActor in
                // HACK: Force UI refresh by reassigning selectedDate to itself
                // This triggers the @Observable system to think the property changed,
                // causing the UI to re-render with updated date formatting
                let temp = self.selectedDate
                self.selectedDate = temp
            }
        }
        

    }
    
    var availableCalendars: [EKCalendar] { 
        calendarManager.availableCalendars 
    }
    
    var selectedCalendarIds: Set<String> {
        get { 
            calendarManager.selectedCalendarIds
        }
        set { 
            calendarManager.selectedCalendarIds = newValue
            Task { @MainActor in
                await loadCalendarEvents() 
            }
        }
    }

    
    private func requestCalendarPermission() {
        Task {
            await calendarManager.requestPermission()
            await loadCalendarEvents()
        }
    }
    
    func manualPermissionRequest() {
        requestCalendarPermission()
    }
    
    func reloadEvents() async {
        // Force refresh calendar data from EventKit first
        calendarManager.forceRefresh()
        await loadCalendarEvents()
    }
    
    @MainActor
    private func loadCalendarEvents() async {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { 
            return 
        }
        
        let startDate = calendar.date(byAdding: .month, value: -1, to: monthInterval.start) ?? monthInterval.start
        let endDate = calendar.date(byAdding: .month, value: 1, to: monthInterval.end) ?? monthInterval.end

        isLoading = true
        
        let calendarEvents = await calendarManager.fetchEventsAsync(from: startDate, to: endDate)
        
        // Build a brand-new events map so deselected calendars fully clear prior data
        var rebuilt: [Date: [Event]] = [:]
        for (date, eventList) in calendarEvents {
            var unique: [String: Event] = [:]
            for e in eventList {
                let key = "\(e.name)|\(e.time.timeIntervalSince1970)"
                unique[key] = e
            }
            rebuilt[date] = Array(unique.values).sorted { $0.time < $1.time }
        }
        events = rebuilt
        isLoading = false
        
    }
    
    
    var eventsForSelectedDate: [Event] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let dayEvents = events[startOfDay] ?? []
        return dayEvents.sorted { event1, event2 in
            // First, sort by full-day/multi-day events (they come first)
            if event1.isFullDay != event2.isFullDay {
                return event1.isFullDay && !event2.isFullDay
            }
            // Then sort by time
            return event1.time < event2.time
        }
    }
    
    var monthName: String {
        return languageManager.localizedMonthName(for: currentMonth)
    }
    
    var selectedDateString: String {
        return languageManager.localizedFullDate(for: selectedDate)
    }
    
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        
        if daysFromPreviousMonth > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) ?? firstOfMonth
            guard let prevMonthInterval = calendar.dateInterval(of: .month, for: previousMonth) else {
                return []
            }
            
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 0
            let startDay = daysInPrevMonth - daysFromPreviousMonth + 1
            
            for day in startDay...daysInPrevMonth {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: prevMonthInterval.start) {
                    days.append(date)
                }
            }
        }
        
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        for day in 1...daysInCurrentMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        let totalCells = 42
        let remainingCells = totalCells - days.count
        if remainingCells > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) ?? firstOfMonth
            for day in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    func goToToday() {
        let today = Date()
        currentMonth = today
        selectedDate = today
    }
    
    func toggleView() {
        isWeekView.toggle()
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    func shouldHighlightDate(_ date: Date) -> Bool {
        let standardCalendar = Calendar.current // Use standard calendar for weekday detection
        let weekday = standardCalendar.component(.weekday, from: date)
        
        // Check for Sunday (weekday = 1)
        if weekday == FirstDayOfWeek.sunday.rawValue && WeekSettings.highlightSundays {
            return true
        }
        
        // Check for Saturday (weekday = 7)
        if weekday == FirstDayOfWeek.saturday.rawValue && WeekSettings.highlightSaturdays {
            return true
        }
        
        // Check for holidays
        if WeekSettings.highlightHolidays && holidayManager.isHoliday(date) {
            return true
        }
        
        return false
    }
    
    // Method to change holiday provider (for future use)
    func setHolidayProvider(_ provider: HolidayProvider) {
        holidayManager.setProvider(provider)
    }
    
    
    func eventsForDate(_ date: Date) -> [Event] {
        let startOfDay = calendar.startOfDay(for: date)
        let dayEvents = events[startOfDay] ?? []
        return dayEvents.sorted { event1, event2 in
            // First, sort by full-day/multi-day events (they come first)
            if event1.isFullDay != event2.isFullDay {
                return event1.isFullDay && !event2.isFullDay
            }
            // Then sort by time
            return event1.time < event2.time
        }
    }
    
    func navigateToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            transitionDirection = .left
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = nextMonth
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionDirection = .none
            }
            Task {
                await loadCalendarEvents()
            }
        }
    }
    
    func navigateToPreviousMonth() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            transitionDirection = .right
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = previousMonth
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionDirection = .none
            }
            Task {
                await loadCalendarEvents()
            }
        }
    }
}