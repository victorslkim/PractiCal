import SwiftUI
import EventKit

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CalendarViewModel
    
    // Event being edited (nil for new event)
    let eventToEdit: Event?
    
    // Check if we should show read-only view
    private var shouldShowReadOnlyView: Bool {
        guard let event = eventToEdit else { return false }
        return viewModel.availableCalendars.first { $0.calendarIdentifier == event.calendarId }?.allowsContentModifications == false
    }
    
    // Form fields
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isAllDay = false
    @State private var selectedCalendarId = ""
    @State private var location = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var selectedAlert = "none"
    
    // UI state
    @State private var activeSheet: EditorSheet?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showRemoveConfirmation = false
    
    private enum DateType {
        case start, end
    }
    private enum EditorSheet: Identifiable {
        case datePicker(DateType)
        case calendarPicker
        case alertPicker
        var id: String {
            switch self {
            case .datePicker(let type):
                return "datePicker_\(type == .start ? "start" : "end")"
            case .calendarPicker:
                return "calendarPicker"
            case .alertPicker:
                return "alertPicker"
            }
        }
    }
    
    private let alertOptions = [
        ("none", "None"),
        ("at_time_of_event", "At time of event"),
        ("5_min_before", "5 minutes before"),
        ("15_min_before", "15 minutes before"),
        ("30_min_before", "30 minutes before"),
        ("1_hour_before", "1 hour before"),
        ("1_day_before", "1 day before")
    ]
    
    
    private var isEditing: Bool {
        eventToEdit != nil
    }
    
    private var navigationTitle: String {
        isEditing ? "Edit Event" : "New Event"
    }
    
    private var selectedCalendar: EKCalendar? {
        viewModel.availableCalendars.first { $0.calendarIdentifier == selectedCalendarId }
    }
    
    private var calendarColor: Color {
        EventHelpers.calendarColor(
            for: selectedCalendarId,
            from: viewModel.availableCalendars,
            calendarColors: viewModel.calendarManager.calendarColors
        )
    }
    
    var body: some View {
        VStack {
            if shouldShowReadOnlyView, let event = eventToEdit {
                EventInfoView(viewModel: viewModel, event: event)
            } else {
            NavigationView {
                ZStack {
                    Form {
                        EventTitleSection(title: $title, calendarColor: calendarColor)
                        
                        EventDateTimeSection(
                            isAllDay: $isAllDay,
                            startDate: $startDate,
                            endDate: $endDate,
                            onStartDateTap: { activeSheet = .datePicker(.start) },
                            onEndDateTap: { activeSheet = .datePicker(.end) },
                            formatDate: formatDate
                        )
                        
                        
                        EventCalendarSection(
                            selectedCalendar: selectedCalendar,
                            calendarColor: calendarColor,
                            onCalendarTap: { activeSheet = .calendarPicker }
                        )
                        
                        EventAlertSection(
                            selectedAlert: selectedAlert,
                            onAlertTap: { activeSheet = .alertPicker }
                        )
                        
                        EventTextFieldSection(
                            icon: "location",
                            placeholder: L("location"),
                            text: $location
                        )
                        
                        EventTextFieldSection(
                            icon: "link",
                            placeholder: L("url"),
                            text: $url,
                            keyboardType: .URL,
                            autocapitalization: .never
                        )
                        
                        EventTextFieldSection(
                            icon: "note.text",
                            placeholder: L("notes"),
                            text: $notes,
                            isMultiline: true
                        )
                        
                        if isEditing && selectedCalendar?.allowsContentModifications != false {
                            Section {
                                Button(action: { 
                                    showRemoveConfirmation = true 
                                }) {
                                    Text(L("remove_event"))
                                        .foregroundColor(.red)
                                        .font(.system(size: 17, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    
                    // Floating Save Button - moved inside ZStack for proper layering
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: saveEvent) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                            }
                            .disabled(title.isEmpty || selectedCalendarId.isEmpty)
                            .opacity(title.isEmpty || selectedCalendarId.isEmpty ? 0.5 : 1.0)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                
            }
        }
        }
        .alert(L("couldnt_save_event"), isPresented: $showErrorAlert) {
            Button(L("ok")) { }
        } message: {
            Text(errorMessage.isEmpty ? L("try_again") : errorMessage)
        }
        .actionSheet(isPresented: $showRemoveConfirmation) {
            ActionSheet(
                title: Text(L("remove_event_confirmation")),
                message: Text(L("remove_event_message")),
                buttons: [
                    .destructive(Text(L("remove_event"))) {
                        removeEvent()
                    },
                    .cancel()
                ]
            )
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .datePicker(let type):
                DatePickerSheet(
                    date: type == .start ? $startDate : $endDate,
                    isAllDay: isAllDay,
                    title: type == .start ? "Start" : "End"
                )
            case .calendarPicker:
                CalendarPickerSheet(
                    selectedCalendarId: $selectedCalendarId,
                    availableCalendars: viewModel.availableCalendars,
                    calendarColors: viewModel.calendarManager.calendarColors
                )
            case .alertPicker:
                AlertPickerSheet(selectedAlert: $selectedAlert)
            }
        }
        .onAppear {
            initializeForm()
        }
    }
    
    
    private func initializeForm() {
        // Load default settings
        let defaultDuration = UserDefaults.standard.integer(forKey: "default_event_duration")
        let defaultAlert = UserDefaults.standard.string(forKey: "default_alert") ?? "none" 
        let defaultAllDay = UserDefaults.standard.bool(forKey: "default_all_day")
        let defaultCalendarId = UserDefaults.standard.string(forKey: "default_calendar_id") ?? ""
        
        if let event = eventToEdit {
            // Editing existing event
            title = event.name
            startDate = event.time
            endDate = event.endTime
            isAllDay = event.isFullDay
            selectedCalendarId = event.calendarId
            location = event.location
            notes = event.description
            // URL and repeat would need to be added to Event model
        } else {
            // Creating new event - use selected date from calendar
            let calendar = Calendar.current
            let selectedDay = viewModel.selectedDate
            let now = Date()
            
            // Creating new event - apply default settings
            isAllDay = defaultAllDay
            selectedAlert = defaultAlert
            
            // Set start date to selected date with current time
            startDate = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                    minute: calendar.component(.minute, from: now),
                                    second: 0, of: selectedDay) ?? selectedDay
            
            // Set end date based on default duration or default to 60 minutes
            let minutesToAdd = (defaultDuration > 0 && defaultDuration != 1440 && !isAllDay) ? defaultDuration : 60
            endDate = calendar.date(byAdding: .minute, value: minutesToAdd, to: startDate) ?? startDate
            
            // Handle all-day events
            if isAllDay {
                startDate = calendar.startOfDay(for: selectedDay)
                endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            }
            
            // Set default calendar
            if !defaultCalendarId.isEmpty,
               let defaultCalendar = viewModel.availableCalendars.first(where: { $0.calendarIdentifier == defaultCalendarId && $0.allowsContentModifications }) {
                selectedCalendarId = defaultCalendar.calendarIdentifier
            } else {
                // Fallback to existing logic if no default set or default not available
                if let preferred = viewModel.availableCalendars.first(where: { cal in
                    viewModel.selectedCalendarIds.contains(cal.calendarIdentifier) && cal.allowsContentModifications
                }) {
                    selectedCalendarId = preferred.calendarIdentifier
                } else if let writable = viewModel.availableCalendars.first(where: { $0.allowsContentModifications }) {
                    selectedCalendarId = writable.calendarIdentifier
                } else if let firstCalendar = viewModel.availableCalendars.first {
                    selectedCalendarId = firstCalendar.calendarIdentifier
                }
            }
        }
    }
    
    private func formatDate(_ date: Date, isAllDay: Bool) -> String {
        EventHelpers.formatDate(date, isAllDay: isAllDay)
    }
    
    private func alertLabel(for alertKey: String) -> String {
        switch alertKey {
        case "none": return L("none")
        case "at_time_of_event": return L("at_time_of_event")
        case "5_min_before": return L("5_min_before")
        case "15_min_before": return L("15_min_before")
        case "30_min_before": return L("30_min_before")
        case "1_hour_before": return L("1_hour_before")
        case "1_day_before": return L("1_day_before")
        default: return L("none")
        }
    }
    
    private func saveEvent() {
        guard !title.isEmpty, !selectedCalendarId.isEmpty else { return }
        
        // Early validation: Selected calendar must allow modifications
        if let cal = viewModel.availableCalendars.first(where: { $0.calendarIdentifier == selectedCalendarId }),
           cal.allowsContentModifications == false {
            errorMessage = "The selected calendar is read-only. Please choose a writable calendar."
            showErrorAlert = true
            return
        }

        Task {
            let success = await viewModel.calendarManager.saveEvent(
                eventId: eventToEdit?.id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: location,
                notes: notes,
                calendarId: selectedCalendarId
            )
            
            if success {
                // Ensure the calendar we saved to is included in the visible selection
                if !viewModel.selectedCalendarIds.contains(selectedCalendarId) {
                    var updated = viewModel.selectedCalendarIds
                    updated.insert(selectedCalendarId)
                    viewModel.selectedCalendarIds = updated
                }
                // Reload events to show the new/updated event
                await viewModel.reloadEvents()
                await MainActor.run {
                    dismiss()
                }
            } else {
                // Show a helpful error
                await MainActor.run {
                    errorMessage = "Failed to save to the selected calendar. It may be read-only or temporarily unavailable."
                    showErrorAlert = true
                }
            }
        }
    }
    
    @MainActor
    private func removeEvent() {
        guard let event = eventToEdit else { 
            return 
        }
        
        Task {
            let success = await viewModel.calendarManager.deleteEvent(eventId: event.id)
            
            await MainActor.run {
                if success {
                    Task {
                        await viewModel.reloadEvents()
                        dismiss()
                    }
                } else {
                    errorMessage = "Failed to delete the event. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let isAllDay: Bool
    let title: String
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    title,
                    selection: $date,
                    displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            })
        }
        .presentationDetents([.medium])
    }
}

struct CalendarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCalendarId: String
    let availableCalendars: [EKCalendar]
    let calendarColors: [String: Color]
    @State private var showInfoAlert = false
    @State private var infoMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                    HStack(spacing: 8) {
                        // Color dot
                        Circle()
                            .fill(calendarColors[calendar.calendarIdentifier] ?? 
                                 (calendar.cgColor != nil ? Color(calendar.cgColor!) : .blue))
                            .frame(width: 12, height: 12)
                        
                        // Title (truncate) + trailing read-only indicators remain visible
                        let isReadOnly = (calendar.allowsContentModifications == false)
                        Text(calendar.title)
                            .foregroundColor(isReadOnly ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(0)

                        if isReadOnly {
                            Text(L("read_only"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .layoutPriority(1)
                            Button(action: {
                                infoMessage = makeReadOnlyInfo(for: calendar)
                                showInfoAlert = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .layoutPriority(1)
                        }

                        Spacer()

                        if calendar.calendarIdentifier == selectedCalendarId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let isReadOnly = (calendar.allowsContentModifications == false)
                        guard !isReadOnly else { return }
                        selectedCalendarId = calendar.calendarIdentifier
                        dismiss()
                    }
                }
            }
            .navigationTitle(L("calendar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            })
        }
        .alert(isPresented: $showInfoAlert) {
            Alert(
                title: Text(L("read_only_calendar")),
                message: Text(infoMessage),
                                        dismissButton: .default(Text(L("ok")))
            )
        }
    }

    private func makeReadOnlyInfo(for calendar: EKCalendar) -> String {
        let source = calendar.source.title
        return "This calendar cannot be modified via iOS Calendars.\n\nPossible reasons:\n- Subscribed (ICS) calendar under \(source)\n- Holidays/Birthdays or other system calendar\n- Shared calendar without 'Make changes' rights\n\nAdd your Google account under Settings > Calendar > Accounts and select a writable Gmail calendar instead."
    }
}



struct RepeatPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: String
    let options: [String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("repeat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            })
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    EventEditorView(viewModel: CalendarViewModel(languageManager: LanguageManager()), eventToEdit: nil)
}