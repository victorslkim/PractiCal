import Foundation

// MARK: - Localization Helper
extension String {
    func localized(using languageManager: LanguageManager? = nil) -> String {
        if let manager = languageManager {
            return manager.localizedString(for: self)
        }
        return NSLocalizedString(self, comment: "")
    }
}


