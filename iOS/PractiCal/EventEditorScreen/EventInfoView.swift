import SwiftUI
import EventKit

struct EventInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CalendarViewModel
    
    // Event to display
    let event: Event
    
    private var selectedCalendar: EKCalendar? {
        viewModel.availableCalendars.first { $0.calendarIdentifier == event.calendarId }
    }
    
    private var calendarColor: Color {
        EventHelpers.calendarColor(
            for: event.calendarId,
            from: viewModel.availableCalendars,
            calendarColors: viewModel.calendarManager.calendarColors
        )
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                // Event Title Section
                Section {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(calendarColor)
                            .frame(width: 12, height: 12)
                        
                        Text(event.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Date & Time Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("start_date"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(event.time, isAllDay: event.isAllDay))
                                    .font(.system(size: 17))
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("end_date"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(event.endTime, isAllDay: event.isAllDay))
                                    .font(.system(size: 17))
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Calendar Section
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("calendar"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(calendarColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(selectedCalendar?.title ?? "Unknown Calendar")
                                    .font(.system(size: 17))
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                
                // Location Section (if available)
                if !event.location.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("location"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.location)
                                    .font(.system(size: 17))
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Notes Section (if available)
                if !event.description.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("notes"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.description)
                                    .font(.system(size: 17))
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L("event_details"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date, isAllDay: Bool) -> String {
        EventHelpers.formatDate(date, isAllDay: isAllDay)
    }
}

#Preview {
    EventInfoView(
        viewModel: CalendarViewModel(languageManager: LanguageManager()),
        event: Event(
            id: "preview",
            name: "Sample Event",
            time: Date(),
            endTime: Date().addingTimeInterval(3600),
            location: "Sample Location",
            description: "Sample description",
            calendarId: "preview",
            calendarColor: .blue,
            isAllDay: false,
            isRecurring: false
        )
    )
}
