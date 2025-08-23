import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @Published var selectedLanguage: SupportedLanguage = .systemDefault
    
    private static let selectedLanguageKey = "selectedLanguage"
    
    init() {
        loadSelectedLanguage()
    }
    
    private func loadSelectedLanguage() {
        if let languageCode = UserDefaults.standard.string(forKey: Self.selectedLanguageKey),
           let language = SupportedLanguage.allCases.first(where: { $0.code == languageCode }) {
            selectedLanguage = language
        }
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        selectedLanguage = language
        UserDefaults.standard.set(language.code, forKey: Self.selectedLanguageKey)
        
        // Set the app's language
        if language == .systemDefault {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        
        // Post notification to inform other components about language change
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
    
    func localizedString(for key: String) -> String {
        if selectedLanguage == .systemDefault {
            return NSLocalizedString(key, comment: "")
        }
        
        guard let bundlePath = Bundle.main.path(forResource: selectedLanguage.code, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return NSLocalizedString(key, comment: "")
        }
        
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    
    // MARK: - Date Formatting
    
    func localizedMonthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        if selectedLanguage != .systemDefault {
            let locale = Locale(identifier: selectedLanguage.code)
            formatter.locale = locale
        }
        
        return formatter.string(from: date).uppercased()
    }
    
    func localizedFullDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        if selectedLanguage != .systemDefault {
            let locale = Locale(identifier: selectedLanguage.code)
            formatter.locale = locale
        }
        
        return formatter.string(from: date)
    }
    
    func localizedTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        // Check if 24-hour time is enabled
        let use24HourTime = UserDefaults.standard.bool(forKey: "use_24_hour_time")
        if use24HourTime {
            formatter.dateFormat = "HH:mm"
        }
        
        if selectedLanguage != .systemDefault {
            let locale = Locale(identifier: selectedLanguage.code)
            formatter.locale = locale
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Global Localization Functions
// These functions provide easy access to localized formatting without needing a LanguageManager instance

func localizedTime(for date: Date) -> String {
    // Get the shared language manager from UserDefaults to check selected language
    let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
    let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    
    // Check if 24-hour time is enabled
    let use24HourTime = UserDefaults.standard.bool(forKey: "use_24_hour_time")
    if use24HourTime {
        formatter.dateFormat = "HH:mm"
    }
    
    if selectedLanguage != .systemDefault {
        let locale = Locale(identifier: selectedLanguage.code)
        formatter.locale = locale
    }
    
    return formatter.string(from: date)
}

func localizedMediumDate(for date: Date) -> String {
    let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
    let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    
    if selectedLanguage != .systemDefault {
        let locale = Locale(identifier: selectedLanguage.code)
        formatter.locale = locale
    }
    
    return formatter.string(from: date)
}

func localizedMediumDateWithTime(for date: Date) -> String {
    let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
    let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    
    if selectedLanguage != .systemDefault {
        let locale = Locale(identifier: selectedLanguage.code)
        formatter.locale = locale
    }
    
    return formatter.string(from: date)
}

func localizedDayNumber(for date: Date) -> String {
    let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage")
    let selectedLanguage = SupportedLanguage.allCases.first(where: { $0.code == selectedLanguageCode }) ?? .systemDefault
    
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    
    if selectedLanguage != .systemDefault {
        let locale = Locale(identifier: selectedLanguage.code)
        formatter.locale = locale
    }
    
    return formatter.string(from: date)
}

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case systemDefault = "system"
    case albanian = "sq"
    case amharic = "am"
    case arabic = "ar"
    case bulgarian = "bg"
    case catalan = "ca"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case estonian = "et"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case icelandic = "is"
    case indonesian = "id"
    case irish = "ga"
    case italian = "it"
    case japanese = "ja"
    case kazakh = "kk"
    case korean = "ko"
    case latvian = "lv"
    case lithuanian = "lt"
    case malay = "ms"
    case malayalam = "ml"
    case norwegian = "no"
    case norwegianBokmal = "nb"
    case polish = "pl"
    case portuguese = "pt"
    case romanian = "ro"
    case russian = "ru"
    case serbian = "sr"
    case slovak = "sk"
    case slovenian = "sl"
    case spanish = "es"
    case swedish = "sv"
    case tamil = "ta"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case urdu = "ur"
    case vietnamese = "vi"
    case welsh = "cy"
    case chinese = "zh"
    
    var id: String { rawValue }
    
    var code: String { rawValue }
    
    var displayName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .albanian: return "Albanian"
        case .amharic: return "Amharic"
        case .arabic: return "Arabic"
        case .bulgarian: return "Bulgarian"
        case .catalan: return "Catalan"
        case .croatian: return "Croatian"
        case .czech: return "Czech"
        case .danish: return "Danish"
        case .dutch: return "Dutch"
        case .english: return "English"
        case .estonian: return "Estonian"
        case .finnish: return "Finnish"
        case .french: return "French"
        case .german: return "German"
        case .greek: return "Greek"
        case .hebrew: return "Hebrew"
        case .hindi: return "Hindi"
        case .hungarian: return "Hungarian"
        case .icelandic: return "Icelandic"
        case .indonesian: return "Indonesian"
        case .irish: return "Irish"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .kazakh: return "Kazakh"
        case .korean: return "Korean"
        case .latvian: return "Latvian"
        case .lithuanian: return "Lithuanian"
        case .malay: return "Malay"
        case .malayalam: return "Malayalam"
        case .norwegian: return "Norwegian"
        case .norwegianBokmal: return "Norwegian Bokmål"
        case .polish: return "Polish"
        case .portuguese: return "Portuguese"
        case .romanian: return "Romanian"
        case .russian: return "Russian"
        case .serbian: return "Serbian"
        case .slovak: return "Slovak"
        case .slovenian: return "Slovenian"
        case .spanish: return "Spanish"
        case .swedish: return "Swedish"
        case .tamil: return "Tamil"
        case .thai: return "Thai"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .urdu: return "Urdu"
        case .vietnamese: return "Vietnamese"
        case .welsh: return "Welsh"
        case .chinese: return "Chinese"
        }
    }
    
    var nativeName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .albanian: return "Shqip"
        case .amharic: return "አማርኛ"
        case .arabic: return "العربية"
        case .bulgarian: return "Български"
        case .catalan: return "Català"
        case .croatian: return "Hrvatski"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .dutch: return "Nederlands"
        case .english: return "English"
        case .estonian: return "Eesti"
        case .finnish: return "Suomi"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .greek: return "Ελληνικά"
        case .hebrew: return "עברית"
        case .hindi: return "हिन्दी"
        case .hungarian: return "Magyar"
        case .icelandic: return "Íslenska"
        case .indonesian: return "Bahasa Indonesia"
        case .irish: return "Gaeilge"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .kazakh: return "Қазақша"
        case .korean: return "한국어"
        case .latvian: return "Latviešu"
        case .lithuanian: return "Lietuvių"
        case .malay: return "Bahasa Melayu"
        case .malayalam: return "മലയാളം"
        case .norwegian: return "Norsk"
        case .norwegianBokmal: return "Norsk Bokmål"
        case .polish: return "Polski"
        case .portuguese: return "Português"
        case .romanian: return "Română"
        case .russian: return "Русский"
        case .serbian: return "Српски"
        case .slovak: return "Slovenčina"
        case .slovenian: return "Slovenščina"
        case .spanish: return "Español"
        case .swedish: return "Svenska"
        case .tamil: return "தமிழ்"
        case .thai: return "ไทย"
        case .turkish: return "Türkçe"
        case .ukrainian: return "Українська"
        case .urdu: return "اردو"
        case .vietnamese: return "Tiếng Việt"
        case .welsh: return "Cymraeg"
        case .chinese: return "中文"
        }
    }
}