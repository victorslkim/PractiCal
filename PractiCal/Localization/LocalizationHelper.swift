import SwiftUI

// MARK: - Environment Key for LanguageManager
// Available if views want to read the manager explicitly
struct LanguageManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: LanguageManager? = nil
}

extension EnvironmentValues {
    var languageManager: LanguageManager? {
        get { self[LanguageManagerEnvironmentKey.self] }
        set { self[LanguageManagerEnvironmentKey.self] = newValue }
    }
}