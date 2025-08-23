import Foundation
import SwiftUI
import os.log
import EventKit

enum TransitionDirection {
    case none, left, right
}

enum ViewMode: String {
    case month, week, day
}

@Observable
class CalendarViewModel {
    private let logger = Logger(subsystem: "com.vskim.PractiCal", category: "CalendarViewModel")

    var selectedDate = Date()
    var currentMonth = Date()
    var viewMode: ViewMode = .month {
        didSet { saveLastViewMode() }
    }
    var events: [Date: [Event]] = [:]

    // Use the settings manager for reactive settings
    private let settingsManager = AppSettingsManager.shared

    var firstDayOfWeek: FirstDayOfWeek {
        settingsManager.firstDayOfWeek
    }

    var highlightHolidays: Bool {
        settingsManager.highlightHolidays
    }

    var highlightSaturdays: Bool {
        settingsManager.highlightSaturdays
    }

    var highlightSundays: Bool {
        settingsManager.highlightSundays
    }

    // Non-observable preload cache (won't trigger recomposition)
    private var preloadedEvents: [Date: [Event]] = [:]
    private var preloadedMonths: Set<Date> = []
    var isLoading: Bool = false
    var isTransitioning = false
    var transitionDirection: TransitionDirection = .none
    var isDebugMode: Bool = false


    // Smart caching to prevent redundant event loading
    private var loadedMonths: Set<Date> = []

    // Month range system (200 months centered around current)
    private let monthRangeSize = 200
    private let monthRangeCenter = 100

    // Month range centered around a fixed reference point - computed once at init
    private var monthRangeStartDate: Date

    // Lazy computed month range
    private var monthRange: [Date] {
        return (0..<monthRangeSize).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: monthRangeStartDate)
        }
    }

    // Flag to prevent reloading during TabView navigation
    private var isNavigatingViaTabView = false
    
    // Holiday manager
    private let holidayManager = HolidayManager()
    
    // Language manager for locale-aware formatting
    private let languageManager: LanguageManager
    private let lastViewModeKey: String = "last_view_mode"
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = firstDayOfWeek.rawValue
        return cal
    }
    let calendarManager = CalendarManager()
    
    init(languageManager: LanguageManager) {
        self.languageManager = languageManager

        // Initialize month range start date
        let today = Date()
        var cal = Calendar.current
        // Initialize monthRangeStartDate first, then we can use firstDayOfWeek
        self.monthRangeStartDate = cal.date(byAdding: .month, value: -monthRangeCenter, to: today) ?? today

        // Now update calendar with first day of week
        cal.firstWeekday = firstDayOfWeek.rawValue

        // Don't handle permissions here - let MainView handle it like Android's MainActivity

        // Observe color changes and reload events
        Task { @MainActor in
            for await _ in calendarManager.$calendarColors.values {
                guard !isNavigatingViaTabView else {
                    continue
                }
                await loadCalendarEvents()
            }
        }

        // Observe permission changes and reload events
        Task { @MainActor in
            for await _ in calendarManager.$hasPermission.values {
                if calendarManager.hasPermission {
                    guard !isNavigatingViaTabView else {
                        continue
                    }
                    await loadCalendarEvents()
                }
            }
        }

        // Observe settings changes to trigger view updates
        Task { @MainActor in
            for await _ in settingsManager.$firstDayOfWeek.values {
                await loadCalendarEvents() // Reload to refresh with new settings
            }
        }
        Task { @MainActor in
            for await _ in calendarManager.$selectedCalendarIds.values {
                guard !isNavigatingViaTabView else {
                    continue
                }
                // Clear cache to force reload with new calendar selection
                loadedMonths.removeAll()
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
        
        // Restore last saved view mode
        restoreLastViewMode()
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
            // Clear cache to force reload with new calendar selection
            loadedMonths.removeAll()
            Task { @MainActor in
                guard !isNavigatingViaTabView else {
                    return
                }
                await loadCalendarEvents()
            }
        }
    }

    
    private func requestCalendarPermission() {
        Task {
            await calendarManager.requestPermission { [weak self] granted in
                if granted {
                    Task { @MainActor in
                        await self?.loadCalendarEvents()
                    }
                }
            }
        }
    }
    
    func manualPermissionRequest() {
        requestCalendarPermission()
    }

    // Add this method similar to Android's onPermissionsGranted()
    func onPermissionsGranted() {
        // Force refresh calendar manager state
        calendarManager.forceRefresh()

        // Clear loaded months cache to force reload
        loadedMonths.removeAll()

        // Load events immediately (similar to Android)
        Task { @MainActor in
            await loadCalendarEvents()
        }
    }
    
    func reloadEvents() async {
        // Force refresh calendar data from EventKit first
        calendarManager.forceRefresh()
        await loadCalendarEvents()
    }
    
    // Check if we should load events for a month (smart caching)
    func shouldLoadEventsForMonth(_ month: Date) -> Bool {
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) ?? month
        
        // Normalize months to first day for consistent comparison
        let normalizedPrevious = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
        let normalizedCurrent = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let normalizedNext = calendar.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
        
        let shouldLoad = !loadedMonths.contains(normalizedPrevious) ||
                        !loadedMonths.contains(normalizedCurrent) ||
                        !loadedMonths.contains(normalizedNext)
        
        
        return shouldLoad
    }
    
    // Load events for current month and adjacent months (only if needed)
    @MainActor
    func loadEventsForMonthAndAdjacent(_ month: Date) async {
        
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) ?? month
        
        var loadCount = 0
        
        // Normalize months to first day for consistent comparison
        let normalizedPrevious = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
        let normalizedCurrent = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let normalizedNext = calendar.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
        
        // Only load months that haven't been loaded yet
        if !loadedMonths.contains(normalizedPrevious) {
            await loadEventsForMonth(previousMonth)
            loadCount += 1
        }
        if !loadedMonths.contains(normalizedCurrent) {
            await loadEventsForMonth(month)
            loadCount += 1
        }
        if !loadedMonths.contains(normalizedNext) {
            await loadEventsForMonth(nextMonth)
            loadCount += 1
        }
        
    }
    
    @MainActor
    func loadEventsForMonth(_ month: Date) async {
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return
        }
        
        isLoading = true
        
        // Load only the specific month (no +/- expansion like before)
        let calendarEvents = await calendarManager.fetchEventsAsync(from: monthInterval.start, to: monthInterval.end)
        
        // Merge with existing events more efficiently
        var currentEvents = events
        
        // Remove existing events for this month from the events map
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        let monthEnd = calendar.startOfDay(for: monthInterval.end)
        
        var dateToCheck = monthStart
        while dateToCheck <= monthEnd {
            // Remove events that originated from this month loading
            currentEvents[dateToCheck] = currentEvents[dateToCheck]?.filter { event in
                !calendar.isDate(event.time, equalTo: month, toGranularity: .month)
            } ?? []
            
            if currentEvents[dateToCheck]?.isEmpty == true {
                currentEvents.removeValue(forKey: dateToCheck)
            }
            
            dateToCheck = calendar.date(byAdding: .day, value: 1, to: dateToCheck) ?? dateToCheck
        }
        
        // Add new events for this month
        for (date, eventList) in calendarEvents {
            var unique: [String: Event] = [:]
            for e in eventList {
                let key = "\(e.name)|\(e.time.timeIntervalSince1970)"
                unique[key] = e
            }
            let sortedEvents = Array(unique.values).sorted { $0.time < $1.time }
            
            if currentEvents[date] == nil {
                currentEvents[date] = sortedEvents
            } else {
                currentEvents[date]?.append(contentsOf: sortedEvents)
                currentEvents[date] = currentEvents[date]?.sorted { $0.time < $1.time }
            }
        }
        
        events = currentEvents
        
        // Mark this month as loaded
        let normalizedMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        loadedMonths.insert(normalizedMonth)
        
        
        isLoading = false
    }
    
    @MainActor
    private func loadCalendarEvents() async {
        // Skip loading if we're in the middle of TabView navigation
        guard !isNavigatingViaTabView else {
            return
        }

        // Use smart caching approach instead of loading +/- 1 month range

        guard shouldLoadEventsForMonth(currentMonth) else {
            return
        }

        await loadEventsForMonthAndAdjacent(currentMonth)
    }
    
    
    var eventsForSelectedDate: [Event] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let dayEvents = events[startOfDay] ?? []

        // Deduplicate events by id to prevent multi-day events from showing multiple times
        var seenEventIds = Set<String>()
        let uniqueEvents = dayEvents.filter { event in
            if seenEventIds.contains(event.id) {
                return false
            }
            seenEventIds.insert(event.id)
            return true
        }

        return uniqueEvents.sorted { event1, event2 in
            // First, sort by full-day/multi-day events (they come first)
            if event1.isFullDay != event2.isFullDay {
                return event1.isFullDay && !event2.isFullDay
            }
            // Then sort by time
            return event1.time < event2.time
        }
    }
    
    var monthName: String {
        return languageManager.localizedMonthName(for: selectedDate)
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

    // New method to set selectedDate to today
    func setSelectedDateToToday() {
        selectedDate = Date()
    }

    // New method to set selectedDate to first day of a month
    func setSelectedDateToFirstOfMonth(_ month: Date) {
        let firstDay = calendar.dateInterval(of: .month, for: month)?.start ?? month
        selectedDate = firstDay
    }
    
    func toggleView() {
        switch viewMode {
        case .month:
            viewMode = .week
        case .week:
            viewMode = .day
        case .day:
            viewMode = .month
        }
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
        if weekday == FirstDayOfWeek.sunday.rawValue && highlightSundays {
            return true
        }
        
        // Check for Saturday (weekday = 7)
        if weekday == FirstDayOfWeek.saturday.rawValue && highlightSaturdays {
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

        // Deduplicate events by id to prevent multi-day events from showing multiple times
        var seenEventIds = Set<String>()
        let uniqueEvents = dayEvents.filter { event in
            if seenEventIds.contains(event.id) {
                return false
            }
            seenEventIds.insert(event.id)
            return true
        }

        return uniqueEvents.sorted { event1, event2 in
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
            isNavigatingViaTabView = true
            transitionDirection = .left

            // No animation needed - TabView handles the visual transition
            currentMonth = nextMonth

            // No delays needed - clean up immediately
            transitionDirection = .none
            isNavigatingViaTabView = false
            // No need to reload events - smart caching already preloaded adjacent months
        }
    }

    // Silent navigation that doesn't trigger recomposition + preloads next month
    func navigateToNextMonthSilently() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {

            // Set flag to prevent event loading observers from triggering
            isNavigatingViaTabView = true

            // Promote any preloaded events for the new current month
            promotePreloadedEvents(for: nextMonth)

            // Clear flag BEFORE updating observable properties
            isNavigatingViaTabView = false

            // Update observable properties (this should trigger UI updates)
            currentMonth = nextMonth

            // Keep selectedDate unchanged - don't jump to first day of new month

            // Preload into non-observable cache (no flicker)
            if let monthToPreload = calendar.date(byAdding: .month, value: 1, to: nextMonth) {
                Task {
                    await self.preloadEventsForMonth(monthToPreload)
                }
            }
        }
    }
    
    func navigateToPreviousMonth() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            isNavigatingViaTabView = true
            transitionDirection = .right

            // No animation needed - TabView handles the visual transition
            currentMonth = previousMonth

            // No delays needed - clean up immediately
            transitionDirection = .none
            isNavigatingViaTabView = false
            // No need to reload events - smart caching already preloaded adjacent months
        }
    }

    // Silent navigation that doesn't trigger recomposition + preloads previous month
    func navigateToPreviousMonthSilently() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {

            // Set flag to prevent event loading observers from triggering
            isNavigatingViaTabView = true

            // Promote any preloaded events for the new current month
            promotePreloadedEvents(for: previousMonth)

            // Clear flag BEFORE updating observable properties
            isNavigatingViaTabView = false

            // Update observable properties (this should trigger UI updates)
            currentMonth = previousMonth

            // Keep selectedDate unchanged - don't jump to first day of new month

            // Preload into non-observable cache (no flicker)
            if let monthToPreload = calendar.date(byAdding: .month, value: -1, to: previousMonth) {
                Task {
                    await self.preloadEventsForMonth(monthToPreload)
                }
            }
        }
    }
    
    func navigateToNextDay() {
        let calendar = Calendar.current
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        
        transitionDirection = .left
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = nextDay
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionDirection = .none
        }
    }
    
    func navigateToPreviousDay() {
        let calendar = Calendar.current
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        
        transitionDirection = .right
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = previousDay
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionDirection = .none
        }
    }
    
    func navigateToNextWeek() {
        let calendar = Calendar.current
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) else { return }

        transitionDirection = .left
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = nextWeek
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionDirection = .none
        }
    }

    func navigateToPreviousWeek() {
        let calendar = Calendar.current
        guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) else { return }

        transitionDirection = .right
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = previousWeek
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionDirection = .none
        }
    }

    // MARK: - MonthView callback methods

    // Get month for a specific page index
    func getMonthForPage(_ pageIndex: Int) -> Date {
        guard pageIndex >= 0 && pageIndex < monthRangeSize else {
            return currentMonth
        }
        return monthRange[pageIndex]
    }

    // Get current month index in the range
    func getCurrentMonthIndex() -> Int {
        // Find the index of currentMonth in the monthRange
        let currentMonthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth

        for (index, monthDate) in monthRange.enumerated() {
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            if calendar.isDate(currentMonthStart, equalTo: monthStart, toGranularity: .month) {
                return index
            }
        }

        // Fallback to center if not found
        return monthRangeCenter
    }


    // Android month change callback - exposed for MonthView
    func onMonthChanged(_ month: Date) {
        currentMonth = month
    }

    // Android load events callback - exposed for MonthView
    func onLoadEventsForMonth(_ month: Date) {
        Task { @MainActor in
            await loadEventsForMonthAndAdjacent(month)
        }
    }

    // Get month range size for MonthView
    func getMonthRangeSize() -> Int {
        return monthRangeSize
    }

}

// MARK: - Persistence
extension CalendarViewModel {
    private func saveLastViewMode() {
        UserDefaults.standard.set(viewMode.rawValue, forKey: lastViewModeKey)
    }
    
    private func restoreLastViewMode() {
        if let raw = UserDefaults.standard.string(forKey: lastViewModeKey),
           let mode = ViewMode(rawValue: raw) {
            viewMode = mode
        }
    }

    // Preload events into non-observable cache (won't trigger SwiftUI recomposition)
    @MainActor
    private func preloadEventsForMonth(_ month: Date) async {
        let normalizedMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month

        // Skip if already preloaded
        guard !preloadedMonths.contains(normalizedMonth) else {
            return
        }


        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return
        }

        // Load events for this month
        let calendarEvents = await calendarManager.fetchEventsAsync(from: monthInterval.start, to: monthInterval.end)

        // Store in preloaded cache (not observable events)
        for (date, eventList) in calendarEvents {
            var unique: [String: Event] = [:]
            for e in eventList {
                let key = "\(e.name)|\(e.time.timeIntervalSince1970)"
                unique[key] = e
            }
            let sortedEvents = Array(unique.values).sorted { $0.time < $1.time }
            preloadedEvents[date] = sortedEvents
        }

        // Mark as preloaded
        preloadedMonths.insert(normalizedMonth)

    }

    // Promote preloaded events to observable events when month becomes active
    private func promotePreloadedEvents(for month: Date) {
        let normalizedMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month

        guard preloadedMonths.contains(normalizedMonth) else {
            return
        }


        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return
        }

        // Move events from preloaded cache to observable events
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        let monthEnd = calendar.startOfDay(for: monthInterval.end)

        var dateToCheck = monthStart
        while dateToCheck <= monthEnd {
            if let preloadedEventsForDate = preloadedEvents[dateToCheck] {
                events[dateToCheck] = preloadedEventsForDate
                preloadedEvents.removeValue(forKey: dateToCheck)
            }
            dateToCheck = calendar.date(byAdding: .day, value: 1, to: dateToCheck) ?? dateToCheck
        }

        // Remove from preloaded months
        preloadedMonths.remove(normalizedMonth)
    }
}