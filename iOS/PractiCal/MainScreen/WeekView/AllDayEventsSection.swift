import SwiftUI

struct AllDayEventsSection: View {
    @Bindable var viewModel: CalendarViewModel
    let weekDates: [Date]
    let onEventTapped: (Event) -> Void
    
    
    var body: some View {
        VStack(spacing: 4) {
            // All-day events area with vertically centered label
            HStack(spacing: 0) {
                // Time column with "all day" label (vertically centered)
                AllDayLabel(isDebugMode: viewModel.isDebugMode)
                    .frame(height: max(30, CGFloat(getSpannedAllDayEvents().count * 22)), alignment: .center)
                
                // Events positioned area
                GeometryReader { geometry in
                    let dayWidth = geometry.size.width / CalendarConstants.daysInWeek
                    
                    ZStack(alignment: .topLeading) {
                        // Debug day columns
                        if viewModel.isDebugMode {
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .border(Color.purple, width: 1)
                                        .frame(width: dayWidth)
                                }
                            }
                        }
                        
                        // Event chips
                        ForEach(Array(getSpannedAllDayEvents().enumerated()), id: \.offset) { index, eventSpan in
                            Button(action: {
                                onEventTapped(eventSpan.event)
                            }) {
                                Text(eventSpan.event.name)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: CGFloat(eventSpan.endDayIndex - eventSpan.startDayIndex + 1) * dayWidth - 4, alignment: .leading)
                                    .lineLimit(1)
                                    .background(eventSpan.event.calendarColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            .offset(x: CGFloat(eventSpan.startDayIndex) * dayWidth, y: CGFloat(index * 22))
                        }
                    }
                }
                .frame(height: max(30, CGFloat(getSpannedAllDayEvents().count * 22)))
            }
        }
        .padding(.bottom, 8)
    }
    
    private func getSpannedAllDayEvents() -> [EventSpan] {
        let calendar = Calendar.current
        var spans: [EventSpan] = []
        var processedEventIds: Set<String> = []
        
        // Get all unique all-day events for the week
        for date in weekDates {
            let dayEvents = viewModel.eventsForDate(date).filter { $0.isAllDay }
            for event in dayEvents {
                if !processedEventIds.contains(event.id) {
                    processedEventIds.insert(event.id)
                    
                    // Find the span of this event across the week
                    let eventStartDay = calendar.startOfDay(for: event.time)
                    
                    // Calculate actual end day based on whether it's single or multi-day
                    let eventEndDay: Date
                    if isSingleDayAllDayEvent(event, calendar: calendar) {
                        // Single day event - end day is same as start day
                        eventEndDay = eventStartDay
                    } else {
                        // Multi-day event - subtract 1 day from endTime to get actual last day
                        let actualEventEndDay = calendar.date(byAdding: .day, value: -1, to: event.endTime) ?? event.endTime
                        eventEndDay = calendar.startOfDay(for: actualEventEndDay)
                    }
                    
                    // Find start day index within the week
                    var startDay = 0
                    if let startIndex = weekDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: eventStartDay) }) {
                        startDay = startIndex
                    } else if eventStartDay < calendar.startOfDay(for: weekDates.first ?? Date()) {
                        // Event started before this week
                        startDay = 0
                    } else {
                        // Event starts after this week - shouldn't happen, but default to 0
                        startDay = 0
                    }
                    
                    // Find end day index within the week
                    var endDay = 6
                    if let endIndex = weekDates.lastIndex(where: { calendar.isDate($0, inSameDayAs: eventEndDay) }) {
                        endDay = endIndex
                    } else if eventEndDay > calendar.startOfDay(for: weekDates.last ?? Date()) {
                        // Event extends beyond this week
                        endDay = 6
                    } else {
                        // Event ends before this week - shouldn't happen for events we found, but default to 6
                        endDay = 6
                    }
                    
                    // Alternative calculation using day difference if the above doesn't work
                    if endDay <= startDay {
                        let daysBetween = calendar.dateComponents([.day], from: eventStartDay, to: eventEndDay).day ?? 0
                        endDay = min(6, startDay + daysBetween)
                    }
                    
                    spans.append(EventSpan(event: event, startDayIndex: startDay, endDayIndex: endDay))
                }
            }
        }
        
        return spans.sorted { $0.startDayIndex < $1.startDayIndex }
    }
    
    private func isSingleDayAllDayEvent(_ event: Event, calendar: Calendar) -> Bool {
        // Check if event starts and ends on consecutive days (typical single-day all-day pattern)
        let dayDifference = calendar.dateComponents([.day], from: event.time, to: event.endTime).day ?? 0
        
        // Single-day all-day events typically have exactly 1 day difference
        // (start: Friday 00:00, end: Saturday 00:00)
        if dayDifference == 1 {
            // Double-check that endTime is at start of day (00:00:00)
            let endTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: event.endTime)
            return endTimeComponents.hour == 0 && endTimeComponents.minute == 0 && endTimeComponents.second == 0
        }
        
        // Also handle edge case where start and end are same day (shouldn't happen for all-day but be safe)
        return dayDifference == 0 && calendar.isDate(event.time, inSameDayAs: event.endTime)
    }
}