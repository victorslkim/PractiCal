import Foundation
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var hasPermission = false
    @Published var selectedCalendarIds: Set<String> = [] {
        didSet {
            saveSelectedCalendars()
        }
    }
    @Published private(set) var availableCalendars: [EKCalendar] = []
    
    // Unified model that combines selection and color per calendar
    struct ManagedCalendar: Identifiable, Hashable, Codable {
        let id: String           // EKCalendar.calendarIdentifier
        let name: String         // EKCalendar.title
        let source: String       // EKSource.title
        var isSelected: Bool
        // Persisted as RGBA in UserDefaults; not directly Codable in SwiftUI Color
        var colorComponents: [Double]
        
        var color: Color {
            Color(.sRGB,
                  red: colorComponents[0],
                  green: colorComponents[1],
                  blue: colorComponents[2],
                  opacity: colorComponents[3])
        }
    }
    
    @Published private(set) var calendars: [ManagedCalendar] = []
    @Published var calendarColors: [String: Color] = [:] {
        didSet {
            saveCalendarColors()
        }
    }
    
    private static let selectedCalendarsKey = "selectedCalendarIds"
    private static let calendarColorsKey = "calendarColors"
    
    init() {
        loadSelectedCalendars()
        loadCalendarColors()
        checkPermission()
        if hasPermission { refreshAvailableCalendars() }
        rebuildManagedCalendars()
    }
    
    /// Forces a complete refresh of calendar data from EventKit
    func forceRefresh() {
        guard hasPermission else { return }
        
        // Refresh available calendars to pick up any new/changed calendars
        refreshAvailableCalendars()
        rebuildManagedCalendars()
        
        // Note: EventKit automatically refreshes its event data when queried,
        // but we ensure the calendar list is up to date
    }
    
    func requestPermission() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                self.hasPermission = granted
                self.refreshAvailableCalendars()
            }
        } catch {
            await MainActor.run {
                self.hasPermission = false
                self.availableCalendars = []
                self.selectedCalendarIds = []
            }
        }
    }
    
    private func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasPermission = status == .fullAccess
    }
    
    private func refreshAvailableCalendars() {
        let calendars = eventStore.calendars(for: .event)
        self.availableCalendars = calendars
        
        // Generate colors for new calendars
        assignColorsToCalendars(calendars)
        
        // If no calendars are selected and this is first time, select all
        if selectedCalendarIds.isEmpty && !UserDefaults.standard.bool(forKey: "hasSetInitialCalendarSelection") {
            self.selectedCalendarIds = Set(calendars.map { $0.calendarIdentifier })
            UserDefaults.standard.set(true, forKey: "hasSetInitialCalendarSelection")
        }
        
        // Keep unified model in sync
        rebuildManagedCalendars()
    }
    
    private func assignColorsToCalendars(_ calendars: [EKCalendar]) {
        let predefinedColors: [Color] = [
            .red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan,
            .mint, .indigo, .teal, .brown, Color(.systemRed), Color(.systemBlue),
            Color(.systemGreen), Color(.systemOrange), Color(.systemPurple),
            Color(.systemPink), Color(.systemYellow), Color(.systemTeal)
        ]
        
        for (index, calendar) in calendars.enumerated() {
            if calendarColors[calendar.calendarIdentifier] == nil {
                // Try to use the calendar's native color first, fallback to predefined colors
                if let cgColor = calendar.cgColor {
                    calendarColors[calendar.calendarIdentifier] = Color(cgColor)
                } else {
                    let colorIndex = index % predefinedColors.count
                    calendarColors[calendar.calendarIdentifier] = predefinedColors[colorIndex]
                }
            }
        }
        
        // Keep unified model in sync
        rebuildManagedCalendars()
    }
    
    private func loadSelectedCalendars() {
        if let data = UserDefaults.standard.data(forKey: Self.selectedCalendarsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.selectedCalendarIds = decoded
        }
        rebuildManagedCalendars()
    }
    
    private func saveSelectedCalendars() {
        if let encoded = try? JSONEncoder().encode(selectedCalendarIds) {
            UserDefaults.standard.set(encoded, forKey: Self.selectedCalendarsKey)
        }
        rebuildManagedCalendars()
    }
    
    private func loadCalendarColors() {
        if let data = UserDefaults.standard.data(forKey: Self.calendarColorsKey),
           let decoded = try? JSONDecoder().decode([String: [Double]].self, from: data) {
            self.calendarColors = decoded.mapValues { components in
                Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3])
            }
        }
        rebuildManagedCalendars()
    }
    
    private func saveCalendarColors() {
        let colorComponents = calendarColors.mapValues { color in
            let uiColor = UIColor(color)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [Double(red), Double(green), Double(blue), Double(alpha)]
        }
        
        if let encoded = try? JSONEncoder().encode(colorComponents) {
            UserDefaults.standard.set(encoded, forKey: Self.calendarColorsKey)
        }
        rebuildManagedCalendars()
    }

    // Build unified calendar models based on EK calendars + selection + colors
    private func rebuildManagedCalendars() {
        let eks = availableCalendars.isEmpty ? eventStore.calendars(for: .event) : availableCalendars
        var result: [ManagedCalendar] = []
        for ek in eks {
            let id = ek.calendarIdentifier
            let title = ek.title
            let source = ek.source.title
            let isSelected = selectedCalendarIds.contains(id)
            let color = calendarColors[id] ?? (ek.cgColor != nil ? Color(ek.cgColor!) : .blue)
            let uiColor = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            result.append(ManagedCalendar(
                id: id,
                name: title,
                source: source,
                isSelected: isSelected,
                colorComponents: [Double(r), Double(g), Double(b), Double(a)]
            ))
        }
        calendars = result
    }
    
    private func selectedEKCalendars() -> [EKCalendar] {
        // When the user deselects all calendars, interpret as "show none".
        // The initial default selection (select all) is handled in refreshAvailableCalendars().
        if selectedCalendarIds.isEmpty {
            return []
        }
        return selectedCalendarIds.compactMap { eventStore.calendar(withIdentifier: $0) }
    }
    
    
    
    func fetchEvents(from startDate: Date, to endDate: Date) -> [Date: [Event]] {
        guard hasPermission else { 
            return [:] 
        }
        
        let selectedCalendars = selectedEKCalendars()
        
        // If no calendars are selected, return empty results
        guard !selectedCalendars.isEmpty else {
            return [:]
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )
        let ekEvents = eventStore.events(matching: predicate)
        
        var eventsByDate: [Date: [Event]] = [:]
        let calendar = Calendar.current
        
        for ekEvent in ekEvents {
            let calendarId = ekEvent.calendar.calendarIdentifier
            let color = calendarColors[calendarId] ?? .blue
            
            
            let event = Event(
                id: ekEvent.eventIdentifier ?? ekEvent.calendarItemIdentifier,
                name: ekEvent.title ?? "Untitled",
                time: ekEvent.startDate,
                endTime: ekEvent.endDate,
                location: ekEvent.location ?? "",
                description: ekEvent.notes ?? "",
                calendarId: calendarId,
                calendarColor: color,
                isAllDay: ekEvent.isAllDay,
            )
            
            // Add event to all days it spans
            let startDay = calendar.startOfDay(for: ekEvent.startDate)
            let endDay = calendar.startOfDay(for: ekEvent.endDate)
            
            var currentDay = startDay
            while currentDay <= endDay {
                if eventsByDate[currentDay] == nil {
                    eventsByDate[currentDay] = []
                }
                eventsByDate[currentDay]?.append(event)
                
                // Move to next day
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? endDay.addingTimeInterval(86400)
                
                // Safety check to prevent infinite loop
                if currentDay > endDay.addingTimeInterval(86400) {
                    break
                }
            }
        }
        
        let result = eventsByDate.mapValues { events in
            events.sorted { event1, event2 in
                // First, sort by full-day/multi-day events (they come first)
                if event1.isFullDay != event2.isFullDay {
                    return event1.isFullDay && !event2.isFullDay
                }
                // Then sort by time
                return event1.time < event2.time
            }
        }
        return result
    }

    // Async variant to avoid blocking the main thread when fetching large ranges
    func fetchEventsAsync(from startDate: Date, to endDate: Date) async -> [Date: [Event]] {
        guard hasPermission else {
            return [:]
        }

        let selectedCalendars = selectedEKCalendars()

        // If no calendars are selected, return empty results
        guard !selectedCalendars.isEmpty else {
            return [:]
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )

        let ekEvents: [EKEvent] = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let events = self.eventStore.events(matching: predicate)
                continuation.resume(returning: events)
            }
        }

        var eventsByDate: [Date: [Event]] = [:]
        let calendar = Calendar.current

        for ekEvent in ekEvents {
            let calendarId = ekEvent.calendar.calendarIdentifier
            let color = calendarColors[calendarId] ?? .blue
            let eventId = ekEvent.eventIdentifier ?? ekEvent.calendarItemIdentifier
            print("Loading event - ID: \(eventId), Title: \(ekEvent.title ?? "No title")")
            
            
            let event = Event(
                id: eventId,
                name: ekEvent.title ?? "Untitled",
                time: ekEvent.startDate,
                endTime: ekEvent.endDate,
                location: ekEvent.location ?? "",
                description: ekEvent.notes ?? "",
                calendarId: calendarId,
                calendarColor: color,
                isAllDay: ekEvent.isAllDay,
            )

            let startDay = calendar.startOfDay(for: ekEvent.startDate)
            let endDay = calendar.startOfDay(for: ekEvent.endDate)

            var currentDay = startDay
            while currentDay <= endDay {
                if eventsByDate[currentDay] == nil {
                    eventsByDate[currentDay] = []
                }
                eventsByDate[currentDay]?.append(event)

                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? endDay.addingTimeInterval(86400)
                if currentDay > endDay.addingTimeInterval(86400) { break }
            }
        }

        let result = eventsByDate.mapValues { events in
            events.sorted { event1, event2 in
                if event1.isFullDay != event2.isFullDay {
                    return event1.isFullDay && !event2.isFullDay
                }
                return event1.time < event2.time
            }
        }
        return result
    }
    
    func saveEvent(
        eventId: String? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String,
        notes: String,
        calendarId: String,
    ) async -> Bool {
        guard hasPermission else { return false }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    // Ensure target calendar exists
                    guard let targetCalendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    let ekEvent: EKEvent
                    
                    if let eventId = eventId,
                       let existingEvent = self.eventStore.event(withIdentifier: eventId) {
                        // Editing existing event
                        ekEvent = existingEvent
                    } else {
                        // Creating new event
                        ekEvent = EKEvent(eventStore: self.eventStore)
                    }
                    
                    // Set event properties
                    ekEvent.title = title
                    ekEvent.startDate = startDate
                    ekEvent.endDate = endDate
                    ekEvent.isAllDay = isAllDay
                    ekEvent.location = location.isEmpty ? nil : location
                    ekEvent.notes = notes.isEmpty ? nil : notes
                    
                    // Set calendar (use verified target calendar)
                    ekEvent.calendar = targetCalendar
                    
                    
                    // Save the event
                    try self.eventStore.save(ekEvent, span: .thisEvent)
                    continuation.resume(returning: true)
                    
                } catch {
                    print("Error saving event: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func deleteEvent(eventId: String) async -> Bool {
        guard hasPermission else { 
            print("No calendar permission for deletion")
            return false 
        }
        
        // Check if this is a sample event (which can't be deleted from EventKit)
        if eventId.hasPrefix("sample-") {
            print("Cannot delete sample event: \(eventId)")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                print("Attempting to delete event with ID: \(eventId)")
                guard let existingEvent = self.eventStore.event(withIdentifier: eventId) else {
                    print("Event not found in EventKit: \(eventId)")
                    continuation.resume(returning: false)
                    return
                }
                print("Found event in EventKit: \(existingEvent.title ?? "No title")")
                do {
                    try self.eventStore.remove(existingEvent, span: .thisEvent)
                    try self.eventStore.commit()
                    print("Successfully deleted event: \(eventId)")
                    continuation.resume(returning: true)
                } catch {
                    print("Error deleting event: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}