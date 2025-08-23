import SwiftUI
import UIKit

// Shared event layout logic
struct EventLayoutCalculator {
    struct EventLayout {
        let event: Event
        let columnIndex: Int
        let totalColumns: Int
        let dayIndex: Int
    }
    
    static func calculateEventLayouts(events: [Event], dayIndex: Int) -> [EventLayout] {
        let sortedEvents = events.sorted { $0.time < $1.time }
        var layouts: [EventLayout] = []
        
        // Group overlapping events together using transitive closure
        var eventGroups: [[Event]] = []
        
        for event in sortedEvents {
            var mergedGroups: [[Event]] = []
            var eventAdded = false
            
            // Find all groups that this event overlaps with
            for group in eventGroups {
                if group.contains(where: { existingEvent in
                    eventsOverlap(event1: event, event2: existingEvent)
                }) {
                    // This event overlaps with this group
                    if !eventAdded {
                        // First overlapping group - add event to it
                        mergedGroups.append(group + [event])
                        eventAdded = true
                    } else {
                        // Additional overlapping group - merge with the first one
                        if let lastIndex = mergedGroups.indices.last {
                            mergedGroups[lastIndex] += group
                        }
                    }
                } else {
                    // No overlap with this group - keep it separate
                    mergedGroups.append(group)
                }
            }
            
            // If event doesn't overlap with any existing group, create new group
            if !eventAdded {
                mergedGroups.append([event])
            }
            
            eventGroups = mergedGroups
        }
        
        // Now assign columns within each group
        for group in eventGroups {
            let sortedGroup = group.sorted { $0.time < $1.time }
            var columns: [[Event]] = []
            
            for event in sortedGroup {
                var columnIndex = 0
                var placed = false
                
                // Try to place in existing columns
                for (index, column) in columns.enumerated() {
                    if !overlapsWithColumn(event: event, column: column) {
                        columns[index].append(event)
                        columnIndex = index
                        placed = true
                        break
                    }
                }
                
                // If can't place in existing column, create new column
                if !placed {
                    columns.append([event])
                    columnIndex = columns.count - 1
                }
                
                layouts.append(EventLayout(
                    event: event,
                    columnIndex: columnIndex,
                    totalColumns: columns.count,
                    dayIndex: dayIndex
                ))
            }
            
            // Update totalColumns for all events in this group
            let totalColumns = columns.count
            for i in layouts.indices {
                if group.contains(where: { $0.id == layouts[i].event.id }) {
                    layouts[i] = EventLayout(
                        event: layouts[i].event,
                        columnIndex: layouts[i].columnIndex,
                        totalColumns: totalColumns,
                        dayIndex: layouts[i].dayIndex
                    )
                }
            }
        }
        
        return layouts
    }
    
    private static func overlapsWithColumn(event: Event, column: [Event]) -> Bool {
        return column.contains { existingEvent in
            eventsOverlap(event1: event, event2: existingEvent)
        }
    }
    
    private static func eventsOverlap(event1: Event, event2: Event) -> Bool {
        let start1 = event1.time
        let end1 = event1.endTime
        let start2 = event2.time
        let end2 = event2.endTime
        
        // Events overlap if one starts before the other ends
        return start1 < end2 && start2 < end1
    }
}

// Simple toast debugging system
class ToastManager: ObservableObject {
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

struct ToastView: View {
    @ObservedObject var toastManager: ToastManager
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
                        .background(Color.black.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct EventSpan {
    let event: Event
    let startDayIndex: Int
    let endDayIndex: Int
}

struct WeekView: View {
    @Bindable var viewModel: CalendarViewModel
    let onEventTapped: (Event) -> Void
    @StateObject private var toastManager = ToastManager()
    
    private let hourHeight: CGFloat = CalendarConstants.hourHeight
    private let hours = Array(stride(from: 0, through: 23, by: 1))
    
    private var weekDates: [Date] {
        getWeekDates(for: viewModel.selectedDate)
    }
    
    private var eventLayoutsByDay: [Int: [EventLayoutCalculator.EventLayout]] {
        var layouts: [Int: [EventLayoutCalculator.EventLayout]] = [:]
        
        for (dayIndex, date) in weekDates.enumerated() {
            let dayEvents = viewModel.eventsForDate(date).filter { !$0.isAllDay }
            layouts[dayIndex] = EventLayoutCalculator.calculateEventLayouts(events: dayEvents, dayIndex: dayIndex)
        }
        
        return layouts
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
            // Week header with dates
            WeekDateHeader(
                viewModel: viewModel,
                weekDates: weekDates,
                dayLabels: dayLabels,
                onDateTapped: { date in
                    viewModel.viewMode = .day
                }
            )
            
            // All-day events section (fixed)
            AllDayEventsSection(
                viewModel: viewModel,
                weekDates: weekDates,
                onEventTapped: onEventTapped
            )
            
            // Time grid (scrollable)
            ScrollViewReader { proxy in
                ScrollView {
                    // Use a container to constrain the transition effect
                    VStack(spacing: 0) {
                        timeGridOnly
                    }
                    .id(getWeekId(for: viewModel.selectedDate))
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
                        toastManager.showToast("WeekView Debug Mode Active")
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
                            viewModel.navigateToPreviousWeek()
                        } else if value.translation.width < -50 && viewModel.transitionDirection != .left {
                            viewModel.navigateToNextWeek()
                        }
                    }
                }
        )
        .overlay(
            VStack {
                Spacer()
                ToastView(toastManager: toastManager, isDebugMode: viewModel.isDebugMode)
            }
        )
    }
    
    private var timeGridOnly: some View {
        // Time grid with events (without all-day section)
        TimeGrid(
            hourHeight: hourHeight,
            hours: hours,
            isDebugMode: viewModel.isDebugMode,
            showVerticalGrid: true
        ) {
            ForEach(weekDates.indices, id: \.self) { dayIndex in
                let dayLayouts = eventLayoutsByDay[dayIndex] ?? []
                let dayWidth = (UIScreen.main.bounds.width - CalendarConstants.timeColumnWidth - CalendarConstants.timeLabelTrailingPadding) / CalendarConstants.daysInWeek
                
                VStack(spacing: 0) {
                    ForEach(dayLayouts, id: \.event.id) { layout in
                        EventBlockView(
                            event: layout.event,
                            dayWidth: dayWidth,
                            hourHeight: hourHeight,
                            columnIndex: layout.columnIndex,
                            totalColumns: layout.totalColumns,
                            toastManager: toastManager,
                            isDebugMode: viewModel.isDebugMode,
                            dayIndex: dayIndex
                        )
                        .onTapGesture {
                            onEventTapped(layout.event)
                        }
                    }
                }
                .offset(x: CGFloat(dayIndex) * dayWidth, y: 0)
            }
        }
    }
    
    
    private func getWeekId(for date: Date) -> String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        return "\(year)-\(weekOfYear)"
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