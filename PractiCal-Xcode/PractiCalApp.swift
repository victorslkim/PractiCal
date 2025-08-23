import SwiftUI

@main
struct PractiCalApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(appSettings)
                .tint(themeManager.colorFromString(themeManager.accentColor))
                // Force lightweight refresh on language change so L("") resolves again
                .id(languageManager.selectedLanguage.code)
        }
    }
}

// MARK: - Global Localization Function
// This function uses the shared LanguageManager instance for consistent localization
func L(_ key: String) -> String {
    // Get the shared language manager from UserDefaults to check selected language
    let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
    let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
    
    print("🔍 L('\(key)') - selected language: \(selectedLanguage.code)")
    
    // Use system default for system language or when no language is set
    if selectedLanguage == .systemDefault {
        let systemResult = NSLocalizedString(key, comment: "")
        print("🔍 Using system default - result: '\(systemResult)'")
        return systemResult
    }
    
    // Attempt to load the selected language bundle directly
    guard let bundlePath = Bundle.main.path(forResource: selectedLanguage.code, ofType: "lproj"),
          let bundle = Bundle(path: bundlePath) else {
        print("🔍 Bundle not found for '\(selectedLanguage.code)', falling back to system")
        let fallback = NSLocalizedString(key, comment: "")
        return fallback
    }
    
    let customResult = bundle.localizedString(forKey: key, value: key, table: nil)
    print("🔍 Using bundle '\(selectedLanguage.code)' - result: '\(customResult)'")
    
    // If the result is the same as the key, it means the translation wasn't found
    if customResult == key {
        print("🔍 Translation not found for '\(key)' in '\(selectedLanguage.code)', falling back to system")
        let fallback = NSLocalizedString(key, comment: "")
        return fallback
    }
    
    return customResult
}