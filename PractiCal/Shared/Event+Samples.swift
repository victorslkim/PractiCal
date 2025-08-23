import Foundation
import SwiftUI

extension Event {
    static let sampleEvents: [Event] = [
        Event(
            id: "sample-1",
            name: "Team Meeting",
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(),
            location: "Conference Room A",
            description: "Weekly team sync and project updates",
            calendarId: "sample_calendar",
            calendarColor: .blue,
            isAllDay: false,
        ),
        Event(
            id: "sample-2",
            name: "Lunch with Sarah",
            time: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date()) ?? Date(),
            location: "Downtown Cafe",
            description: "Catch up over lunch",
            calendarId: "sample_calendar",
            calendarColor: .blue,
            isAllDay: false,
        ),
        Event(
            id: "sample-3",
            name: "Doctor Appointment",
            time: Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: Date()) ?? Date(),
            location: "Medical Center",
            description: "Annual checkup",
            calendarId: "sample_calendar",
            calendarColor: .blue,
            isAllDay: false,
        ),
        Event(
            id: "sample-4",
            name: "Conference Trip",
            time: Calendar.current.startOfDay(for: Date()),
            endTime: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date())) ?? Date(),
            location: "San Francisco",
            description: "Multi-day conference",
            calendarId: "sample_calendar",
            calendarColor: .green,
            isAllDay: true,
        ),
        Event(
            id: "sample-5",
            name: "Project Deadline",
            time: Calendar.current.startOfDay(for: Date()),
            endTime: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date(),
            location: "",
            description: "Final submission",
            calendarId: "sample_calendar",
            calendarColor: .red,
            isAllDay: true,
        )
    ]
}


