import SwiftUI
import MessageUI
import EventKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeSheet: SettingsSheet?
    @State private var showingMailError = false
    @State private var mailComposeDelegate = MailComposeDelegate()
    let viewModel: CalendarViewModel

    enum SettingsSheet: Identifiable {
        case appearance
        case editEvent
        case notification
        case help

        var id: String {
            switch self {
            case .appearance: return "appearance"
            case .editEvent: return "editEvent"
            case .notification: return "notification"
            case .help: return "help"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with close button
                    HStack {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    VStack(spacing: 24) {
                        // General Section
                        SettingsSection(title: "General") {
                            SettingsRow(icon: "paintbrush.fill", title: "Appearance", action: {
                                activeSheet = .appearance
                            })
                            SettingsRow(icon: "pencil", title: "Edit Event", action: {
                                activeSheet = .editEvent
                            })
                            SettingsRow(icon: "bell.fill", title: "Notification", action: {
                                activeSheet = .notification
                            })
                        }

                        // Support Section
                        SettingsSection(title: "Support") {
                            SettingsRow(icon: "envelope.fill", title: "Send Feedback", action: {
                                sendFeedback()
                            })
                            SettingsRow(icon: "questionmark.circle.fill", title: "Help", action: {
                                activeSheet = .help
                            })
                        }

                        // Support PractiCal Section
                        SettingsSection(title: "Support PractiCal") {
                            SettingsRow(icon: "square.and.arrow.up.fill", title: "Share App", action: {
                                shareApp()
                            })
                            SettingsRow(icon: "star.fill", title: "Write an App Store Review", action: {
                                openAppStoreReview()
                            })
                            SettingsRow(icon: "heart.fill", title: "Donation", action: {
                                openDonation()
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGray6).opacity(0.4))
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .appearance:
                AppearanceSettingsView()
            case .editEvent:
                EditEventSettingsView(viewModel: viewModel)
            case .notification:
                NotificationSettingsView()
            case .help:
                HelpView()
            }
        }
        .alert("Email Not Available", isPresented: $showingMailError) {
            Button("OK") { }
        } message: {
            Text("Please set up Mail app or contact us at feedback@practical.app")
        }
    }

    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = mailComposeDelegate
            mail.setToRecipients(["feedback@practical.app"])
            mail.setSubject("PractiCal Feedback")
            mail.setMessageBody("Hi PractiCal team,\n\n", isHTML: false)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(mail, animated: true)
            }
        } else {
            showingMailError = true
        }
    }

    private func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/app/practical-calendar/id123456789")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out PractiCal - the best calendar app!", appURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            }
            window.rootViewController?.present(activityVC, animated: true)
        }
    }

    private func openAppStoreReview() {
        let appStoreURL = URL(string: "https://apps.apple.com/app/practical-calendar/id123456789?action=write-review")!
        UIApplication.shared.open(appStoreURL)
    }

    private func openDonation() {
        let donationURL = URL(string: "https://ko-fi.com/practical")!
        UIApplication.shared.open(donationURL)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                content()
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Detail Views

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appSettings: AppSettings

    @AppStorage("first_day_of_week") private var firstDayOfWeekRaw = FirstDayOfWeek.sunday.rawValue
    @AppStorage("highlight_holidays") private var highlightHolidays = true
    @AppStorage("highlight_saturdays") private var highlightSaturdays = false
    @AppStorage("highlight_sundays") private var highlightSundays = true

    private var firstDayOfWeek: FirstDayOfWeek {
        get { FirstDayOfWeek(rawValue: firstDayOfWeekRaw) ?? .sunday }
        set { firstDayOfWeekRaw = newValue.rawValue }
    }

    private let themes = ["system", "light", "dark"]
    private let themeDisplayNames = ["system": "System", "light": "Light", "dark": "Dark"]
    private let colors = ["blue", "green", "orange", "purple", "red", "yellow"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    CalendarPreview(
                        firstDayOfWeek: firstDayOfWeek,
                        highlightHolidays: highlightHolidays,
                        highlightSaturdays: highlightSaturdays,
                        highlightSundays: highlightSundays
                    )
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Calendar settings items below
                    Picker("First Day of Week", selection: $firstDayOfWeekRaw) {
                        ForEach(FirstDayOfWeek.allCases, id: \.self) { day in
                            Text(day.displayName).tag(day.rawValue)
                        }
                    }

                    // Theme Row
                    HStack {
                        Text("Theme")
                        Spacer()
                        Menu(themeDisplayNames[themeManager.selectedTheme] ?? themeManager.selectedTheme.capitalized) {
                            ForEach(themes, id: \.self) { theme in
                                Button(themeDisplayNames[theme] ?? theme.capitalized) {
                                    themeManager.selectedTheme = theme
                                }
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    // Accent Color Row
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(themeManager.colorFromString(color))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(themeManager.accentColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        themeManager.accentColor = color
                                    }
                            }
                        }
                    }



                    // Highlight Row
                    HStack {
                        Text("Highlight")
                        Spacer()

                        HStack(spacing: 6) {
                            // Holidays pill
                            Button(action: { highlightHolidays.toggle() }) {
                                Text("Holidays")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(highlightHolidays ? Color.red : Color(.systemGray5))
                                    .foregroundColor(highlightHolidays ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Saturdays pill
                            Button(action: { highlightSaturdays.toggle() }) {
                                Text("Sat")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(highlightSaturdays ? Color.red : Color(.systemGray5))
                                    .foregroundColor(highlightSaturdays ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Sundays pill
                            Button(action: { highlightSundays.toggle() }) {
                                Text("Sun")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(highlightSundays ? Color.red : Color(.systemGray5))
                                    .foregroundColor(highlightSundays ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Section {
                    DayCellPreview(
                        textSize: appSettings.dayCellTextSize,
                        boldText: appSettings.dayCellBoldText,
                        showBackground: appSettings.dayCellShowBackground
                    )
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HStack {
                        Text("Text Size")
                        Spacer()
                        Button("-") {
                            appSettings.dayCellTextSize = max(-4, appSettings.dayCellTextSize - 1)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appSettings.dayCellTextSize <= -4)

                        Text("\(Int(appSettings.dayCellTextSize))")
                            .frame(minWidth: 30)
                            .font(.system(.body, design: .monospaced))

                        Button("+") {
                            appSettings.dayCellTextSize = min(4, appSettings.dayCellTextSize + 1)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appSettings.dayCellTextSize >= 4)
                    }

                    Toggle("Bold Text", isOn: $appSettings.dayCellBoldText)

                    Toggle("Show Event Background", isOn: $appSettings.dayCellShowBackground)
                }

                Section {
                    VStack(spacing: 16) {
                        // Future event (should not be dimmed)
                        EventRowCard(
                            event: Event(
                                id: "future-event",
                                name: "Future Meeting",
                                time: Date().addingTimeInterval(3600), // 1 hour from now
                                endTime: Date().addingTimeInterval(7200), // 2 hours from now
                                location: "Conference Room A",
                                description: "This is a future event that should not be dimmed",
                                calendarId: "sample-calendar",
                                calendarColor: .blue,
                                isAllDay: false,
                                isRecurring: false
                            ),
                            onTapped: { }
                        )

                        // Past event (should be dimmed when toggle is on)
                        EventRowCard(
                            event: Event(
                                id: "past-event",
                                name: "Past Meeting",
                                time: Date().addingTimeInterval(-7200), // 2 hours ago
                                endTime: Date().addingTimeInterval(-3600), // 1 hour ago
                                location: "Conference Room C",
                                description: "This is a past event that should be dimmed",
                                calendarId: "sample-calendar",
                                calendarColor: .red,
                                isAllDay: false,
                                isRecurring: false
                            ),
                            onTapped: { }
                        )
                    }
                    .padding(.vertical, 8)

                    Toggle("24-Hour Time", isOn: $appSettings.use24HourTime)

                    Toggle("Dim Past Events", isOn: $appSettings.eventRowCardDimPastEvents)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}




// MARK: - Temporary EventRowCard Customization View
struct EventRowCardCustomizationViewTemp: View {
    @AppStorage("event_row_card_dim_past_events") private var dimPastEvents = false
    @AppStorage("use_24_hour_time") private var use24HourTime = false

    var body: some View {
        Form {
            Section {
                Text("Event Row Card Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

#Preview {
    SettingsView(viewModel: CalendarViewModel())
}
