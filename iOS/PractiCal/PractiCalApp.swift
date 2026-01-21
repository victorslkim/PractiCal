import SwiftUI

@main
struct PractiCalApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(themeManager)
                .environmentObject(appSettings)
                .tint(themeManager.colorFromString(themeManager.accentColor))
        }
    }
}
