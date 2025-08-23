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
            
            Section(L("time_format")) {
                Toggle(L("24_hour_time"), isOn: $use24HourTime)
            }
            
            Section(L("event_visibility")) {
                Toggle(L("dim_past_events"), isOn: $dimPastEvents)
            }
            
            Section {
                Button(L("reset_to_defaults")) {
                    use24HourTime = false
                    dimPastEvents = false
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle(L("event_row_card_customization"))
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
            isAllDay: false
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
            isAllDay: false
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(L("event_row_card_preview"))
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
