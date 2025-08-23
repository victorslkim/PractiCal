import Foundation

// MARK: - Weekday Symbols Helpers
extension LanguageManager {
    /// Returns very short weekday symbols (typically single-letter) localized to the selected language.
    /// Order follows the calendar for the locale (Sunday-first for Gregorian).
    static func localizedVeryShortWeekdaySymbols() -> [String] {
        let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
        let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
        let formatter = DateFormatter()
        if selectedLanguage != .systemDefault {
            let locale = Locale(identifier: selectedLanguage.code)
            formatter.locale = locale
        }
        return formatter.veryShortWeekdaySymbols
    }
    
    /// Returns a single-letter (or locale-appropriate very short) label for a given weekday number.
    /// - Parameter weekday: Calendar weekday index (1 = Sunday ... 7 = Saturday)
    static func localizedVeryShortWeekdayLabel(forWeekday weekday: Int) -> String {
        let symbols = localizedVeryShortWeekdaySymbols()
        let index = max(0, min(6, (weekday - 1)))
        guard index < symbols.count else { return "" }
        // Uppercased matches existing UI style where appropriate
        return symbols[index].uppercased()
    }

    /// Returns full weekday symbols localized to the selected language.
    /// Prefers standalone context where available for UI labels.
    static func localizedWeekdaySymbols() -> [String] {
        let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
        let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
        let formatter = DateFormatter()
        if selectedLanguage != .systemDefault {
            let locale = Locale(identifier: selectedLanguage.code)
            formatter.locale = locale
        }
        // Use standalone symbols when available
        if let standalone = formatter.standaloneWeekdaySymbols, standalone.count == 7 {
            return standalone
        }
        return formatter.weekdaySymbols
    }

    /// Returns full localized label for a specific weekday index (1 = Sunday ... 7 = Saturday)
    static func localizedWeekdayLabel(forWeekday weekday: Int) -> String {
        let symbols = localizedWeekdaySymbols()
        let index = max(0, min(6, (weekday - 1)))
        guard index < symbols.count else { return "" }
        return symbols[index]
    }
}


