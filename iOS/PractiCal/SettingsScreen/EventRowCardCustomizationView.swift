import SwiftUI

struct EventRowCardCustomizationView: View {
    @State private var use24HourTime: Bool = false
    @State private var dimPastEvents: Bool = false

    var body: some View {
        Form {
            Section {
                EventRowCardPreview(
                    use24HourTime: use24HourTime,
                    dimPastEvents: dimPastEvents
                )
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Time Format") {
                Toggle("24-Hour Time", isOn: $use24HourTime)
            }

            Section("Event Visibility") {
                Toggle("Dim Past Events", isOn: $dimPastEvents)
            }

            Section {
                Button("Reset to Defaults") {
                    use24HourTime = false
                    dimPastEvents = false
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Event Row Card Customization")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventRowCardPreview: View {
    let use24HourTime: Bool
    let dimPastEvents: Bool

    private var sampleEvent: Event {
        Event(
            id: "preview",
            name: "Sample Event",
            time: Date(),
            endTime: Date().addingTimeInterval(3600),
            location: "Sample Location",
            description: "This is a sample event for preview",
            calendarId: "preview",
            calendarColor: .blue,
            isAllDay: false,
            isRecurring: false
        )
    }

    private var pastEvent: Event {
        Event(
            id: "preview-past",
            name: "Past Event",
            time: Date().addingTimeInterval(-3600),
            endTime: Date(),
            location: "Past Location",
            description: "This is a past event",
            calendarId: "preview",
            calendarColor: .red,
            isAllDay: false,
            isRecurring: false
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Event Row Card Preview")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                EventRowCard(
                    event: sampleEvent,
                    onTapped: {}
                )

                EventRowCard(
                    event: pastEvent,
                    onTapped: {}
                )
            }
        }
    }
}

#Preview {
    NavigationView {
        EventRowCardCustomizationView()
    }
}
