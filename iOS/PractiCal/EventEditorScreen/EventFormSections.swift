import SwiftUI
import EventKit

// MARK: - Title Section
struct EventTitleSection: View {
    @Binding var title: String
    let calendarColor: Color
    
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(calendarColor)
                    .frame(width: 4, height: 24)
                    .cornerRadius(2)
                
                TextField("Title", text: $title)
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

// MARK: - Date & Time Section
struct EventDateTimeSection: View {
    @Binding var isAllDay: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onStartDateTap: () -> Void
    let onEndDateTap: () -> Void
    let formatDate: (Date, Bool) -> String
    
    var body: some View {
        Section {
            // All Day Toggle
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Toggle("All Day", isOn: $isAllDay)
                    .onChange(of: isAllDay) { _, newValue in
                        let calendar = Calendar.current
                        if newValue {
                            // Set to start of day
                            startDate = calendar.startOfDay(for: startDate)
                            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                        } else {
                            startDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startDate) ?? startDate
                            endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
                        }
                    }
            }
            
            // Start Date/Time
            Button(action: onStartDateTap) {
                HStack {
                    Text(L("starts"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatDate(startDate, isAllDay))
                        .foregroundColor(.secondary)
                }
            }
            
            // End Date/Time
            Button(action: onEndDateTap) {
                HStack {
                    Text(L("ends"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatDate(endDate, isAllDay))
                        .foregroundColor(.secondary)
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

// MARK: - Repeat Section
struct EventRepeatSection: View {
    @Binding var repeatOption: String
    let onRepeatTap: () -> Void
    
    var body: some View {
        Section {
            Button(action: onRepeatTap) {
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text(L("repeat"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(repeatOption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

// MARK: - Calendar Section
struct EventCalendarSection: View {
    let selectedCalendar: EKCalendar?
    let calendarColor: Color
    let onCalendarTap: () -> Void
    
    var body: some View {
        Section {
            Button(action: onCalendarTap) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text(L("calendar"))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(calendarColor)
                            .frame(width: 12, height: 12)
                        Text(selectedCalendar?.title ?? "Select Calendar")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

// MARK: - Alert Section
struct EventAlertSection: View {
    let selectedAlert: String
    let onAlertTap: () -> Void
    
    var body: some View {
        Section {
            Button(action: onAlertTap) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text(L("alert"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(L(selectedAlert))
                        .foregroundColor(.secondary)
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

// MARK: - Text Field Sections
struct EventTextFieldSection: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let isMultiline: Bool
    
    init(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, autocapitalization: TextInputAutocapitalization = .sentences, isMultiline: Bool = false) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        Section {
            HStack(alignment: isMultiline ? .top : .center) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                    .padding(.top, isMultiline ? 4 : 0)
                
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}