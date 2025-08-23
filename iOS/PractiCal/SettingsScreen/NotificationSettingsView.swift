import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("daily_agenda_time") private var dailyAgendaHour = 8
    @AppStorage("weekend_notifications") private var weekendNotifications = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Toggle("Weekend Notifications", isOn: $weekendNotifications)
                        
                        Picker("Daily Agenda Time", selection: $dailyAgendaHour) {
                            ForEach(6..<22) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                    }
                }
                
                Section(footer: Text(L("notifications_permission_message"))) {
                    Button(L("open_ios_settings")) {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }
            }
            .navigationTitle(L("notifications"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}