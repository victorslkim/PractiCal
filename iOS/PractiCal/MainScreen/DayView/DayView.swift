import SwiftUI

// Simple toast debugging system
class DayToastManager: ObservableObject {
    @Published var toasts: [ToastMessage] = []
    
    struct ToastMessage: Identifiable {
        let id = UUID()
        let message: String
        let timestamp: Date
    }
    
    func showToast(_ message: String) {
        let toast = ToastMessage(message: message, timestamp: Date())
        toasts.append(toast)
        
        // Auto-dismiss after 1 minute
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.toasts.removeAll { $0.id == toast.id }
        }
        
        // No limit on toast count for debugging - show all events
    }
}

struct DayToastView: View {
    @ObservedObject var toastManager: DayToastManager
    let isDebugMode: Bool
    
    var body: some View {
        if isDebugMode && !toastManager.toasts.isEmpty {
            VStack(spacing: 4) {
                ForEach(toastManager.toasts) { toast in
                    Text(toast.message)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8)) // Red background for DayView toasts
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct DayView: View {
    @Bindable var viewModel: CalendarViewModel
    let onEventTapped: (Event) -> Void
    @StateObject private var toastManager = DayToastManager()
    
    private let hourHeight: CGFloat = CalendarConstants.hourHeight
    private let hours = Array(stride(from: 0, through: 23, by: 1))
    
    private var weekDates: [Date] {
        getWeekDates(for: viewModel.selectedDate)
    }
    
    private var selectedDateEvents: [Event] {
        viewModel.eventsForDate(viewModel.selectedDate)
    }
    
    private var eventLayouts: [EventLayoutCalculator.EventLayout] {
        let timedEvents = selectedDateEvents.filter { !$0.isAllDay }
        return EventLayoutCalculator.calculateEventLayouts(events: timedEvents, dayIndex: 0)
    }
    
    private var dayLabels: [String] {
        var calendar = Calendar.current
        calendar.firstWeekday = viewModel.firstDayOfWeek.rawValue
        
        let weekdays = calendar.shortWeekdaySymbols
        var labels: [String] = []
        
        for i in 0..<7 {
            let index = (viewModel.firstDayOfWeek.rawValue - 1 + i) % 7
            let shortName = weekdays[index]
            labels.append(String(shortName.prefix(1)).uppercased())
        }
        
        return labels
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header showing week with selected day highlighted (static)
            WeekDateHeader(
                viewModel: viewModel,
                weekDates: weekDates,
                dayLabels: dayLabels
            )
            
            // All-day events section (fixed)
            if selectedDateEvents.contains(where: { $0.isAllDay }) {
                allDayEventsSection
            }
            
            // Time grid for selected day (scrollable)
            ScrollViewReader { proxy in
                ScrollView {
                    // Use a container to constrain the transition effect
                    VStack(spacing: 0) {
                        timeGridOnlyForDay
                    }
                    .id(Calendar.current.startOfDay(for: viewModel.selectedDate))
                    .transition(.asymmetric(
                        insertion: .move(edge: viewModel.transitionDirection == .left ? .trailing : .leading),
                        removal: .move(edge: viewModel.transitionDirection == .left ? .leading : .trailing)
                    ))
                    .clipped() // Ensure transition doesn't affect outside elements
                }
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                    
                    // Test toast to verify toast system is working
                    if viewModel.isDebugMode {
                        toastManager.showToast("DayView Debug Mode Active")
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Start transition when swipe reaches threshold
                    if abs(value.translation.width) > 50 {
                        if value.translation.width > 50 && viewModel.transitionDirection != .right {
                            viewModel.navigateToPreviousDay()
                        } else if value.translation.width < -50 && viewModel.transitionDirection != .left {
                            viewModel.navigateToNextDay()
                        }
                    }
                }
        )
        .overlay(
            VStack {
                Spacer()
                DayToastView(toastManager: toastManager, isDebugMode: viewModel.isDebugMode)
            }
        )
    }
    
    private var timeGridForDay: some View {
        VStack(spacing: 0) {
            // All-day events section
            if selectedDateEvents.contains(where: { $0.isAllDay }) {
                allDayEventsSection
            }
            
            // Time grid with events
            TimeGrid(
                hourHeight: hourHeight,
                hours: hours,
                isDebugMode: viewModel.isDebugMode
            ) {
                // Events for the day with overlap handling
                ForEach(eventLayouts, id: \.event.id) { layout in
                    DayEventBlockView(
                        event: layout.event,
                        dayWidth: UIScreen.main.bounds.width - CalendarConstants.timeColumnWidth - CalendarConstants.timeLabelTrailingPadding - 8, // Available width for events
                        hourHeight: hourHeight,
                        columnIndex: layout.columnIndex,
                        totalColumns: layout.totalColumns,
                        toastManager: toastManager,
                        isDebugMode: viewModel.isDebugMode
                    )
                    .onTapGesture {
                        onEventTapped(layout.event)
                    }
                }
            }
        }
    }
    
    private var timeGridOnlyForDay: some View {
        // Time grid with events (without all-day section)
        TimeGrid(
            hourHeight: hourHeight,
            hours: hours,
            isDebugMode: viewModel.isDebugMode
        ) {
            // Events for the day with overlap handling
            ForEach(eventLayouts, id: \.event.id) { layout in
                DayEventBlockView(
                    event: layout.event,
                    dayWidth: UIScreen.main.bounds.width - CalendarConstants.timeColumnWidth - CalendarConstants.timeLabelTrailingPadding - 8, // Available width for events
                    hourHeight: hourHeight,
                    columnIndex: layout.columnIndex,
                    totalColumns: layout.totalColumns,
                    toastManager: toastManager,
                    isDebugMode: viewModel.isDebugMode
                )
                .onTapGesture {
                    onEventTapped(layout.event)
                }
            }
        }
    }
    
    private var allDayEventsSection: some View {
        VStack(spacing: 4) {
            // All-day events area with vertically centered label (consistent with WeekView)
            HStack(spacing: 0) {
                // Time column with "all day" label 
                AllDayLabel(isDebugMode: viewModel.isDebugMode)
                
                // Events area
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(selectedDateEvents.filter { $0.isAllDay }, id: \.id) { event in
                        Button(action: {
                            onEventTapped(event)
                        }) {
                            Text(event.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(event.calendarColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private func getWeekDates(for date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = viewModel.firstDayOfWeek.rawValue
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = weekInterval.start
        
        for _ in 0..<7 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let _ = calendar.component(.minute, from: now)
        
        // Calculate scroll position: go to current hour minus some offset for visibility
        let targetHour = max(0, hour - 2) // Show 2 hours before current time
        let _ = CGFloat(targetHour) * hourHeight
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.6)) {
                proxy.scrollTo("hour-\(targetHour)", anchor: UnitPoint.top)
            }
        }
    }
}