import SwiftUI
import EventKit

struct DefaultCalendarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCalendarId: String
    let availableCalendars: [EKCalendar]
    let calendarColors: [String: Color]
    
    var body: some View {
        NavigationView {
            List {
                // Option to not set a default
                HStack {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 12, height: 12)
                    
                    Text(L("no_default"))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedCalendarId.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCalendarId = ""
                    dismiss()
                }
                
                // Available calendars (only writable ones)
                ForEach(availableCalendars.filter { $0.allowsContentModifications }, id: \.calendarIdentifier) { calendar in
                    HStack {
                        Circle()
                            .fill(calendarColors[calendar.calendarIdentifier] ?? 
                                 (calendar.cgColor != nil ? Color(calendar.cgColor!) : .blue))
                            .frame(width: 12, height: 12)
                        
                        Text(calendar.title)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if calendar.calendarIdentifier == selectedCalendarId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCalendarId = calendar.calendarIdentifier
                        dismiss()
                    }
                }
            }
            .navigationTitle(L("default_calendar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DefaultCalendarPickerSheet(
        selectedCalendarId: .constant(""),
        availableCalendars: [],
        calendarColors: [:]
    )
}