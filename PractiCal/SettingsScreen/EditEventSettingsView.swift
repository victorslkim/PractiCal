import SwiftUI
import EventKit

struct EditEventSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("default_event_duration") private var defaultDuration = 60
    @AppStorage("default_alert_minutes") private var defaultAlert = 30
    @AppStorage("default_all_day") private var defaultAllDay = false
    @AppStorage("default_calendar_id") private var defaultCalendarId = ""
    @Bindable var viewModel: CalendarViewModel
    @State private var showingCalendarPicker = false
    
    private var alertOptions: [(label: String, minutes: Int)] {
        [
            (label: "None", minutes: 0),
            (label: "At time of event", minutes: -1),
            (label: "5 minutes before", minutes: 5),
            (label: "15 minutes before", minutes: 15),
            (label: "30 minutes before", minutes: 30),
            (label: "1 hour before", minutes: 60),
            (label: "1 day before", minutes: 1440)
        ]
    }
    
    private var selectedCalendar: EKCalendar? {
        viewModel.availableCalendars.first { $0.calendarIdentifier == defaultCalendarId }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L("default_event_settings"))) {
                    Picker("Duration", selection: $defaultDuration) {
                        Text(L("15_minutes")).tag(15)
                        Text(L("30_minutes")).tag(30)
                        Text(L("1_hour")).tag(60)
                        Text(L("2_hours")).tag(120)
                        Text(L("all_day")).tag(1440)
                    }
                    
                    Picker("Alert", selection: $defaultAlert) {
                        ForEach(alertOptions, id: \.minutes) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }
                    
                    // Default Calendar Selection
                    HStack {
                        Text(L("default_calendar"))
                        Spacer()
                        if let calendar = selectedCalendar {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(viewModel.calendarManager.calendarColors[calendar.calendarIdentifier] ?? 
                                         (calendar.cgColor != nil ? Color(calendar.cgColor!) : .blue))
                                    .frame(width: 12, height: 12)
                                Text(calendar.title)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(L("choose_calendar"))
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingCalendarPicker = true
                    }
                    
                    Toggle("All Day by Default", isOn: $defaultAllDay)
                }
            }
            .navigationTitle(L("edit_event"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingCalendarPicker) {
            DefaultCalendarPickerSheet(
                selectedCalendarId: $defaultCalendarId,
                availableCalendars: viewModel.availableCalendars,
                calendarColors: viewModel.calendarManager.calendarColors
            )
        }
    }
}

#Preview {
    EditEventSettingsView(viewModel: CalendarViewModel(languageManager: LanguageManager()))
}