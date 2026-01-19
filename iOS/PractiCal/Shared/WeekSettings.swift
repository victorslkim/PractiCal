import Foundation

enum FirstDayOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var displayName: String {
        let formatter = DateFormatter()
        let symbols = formatter.weekdaySymbols ?? []
        let index = self.rawValue - 1
        guard index >= 0 && index < symbols.count else { return "" }
        return symbols[index]
    }

    var shortLabel: String {
        let formatter = DateFormatter()
        let symbols = formatter.veryShortWeekdaySymbols ?? []
        let index = self.rawValue - 1
        guard index >= 0 && index < symbols.count else { return "" }
        return symbols[index].uppercased()
    }

    static var current: FirstDayOfWeek {
        let rawValue = UserDefaults.standard.integer(forKey: "first_day_of_week")
        return FirstDayOfWeek(rawValue: rawValue) ?? .sunday
    }
}

struct WeekSettings {
    static var highlightHolidays: Bool {
        // Check if the key exists, if not, return the default value (true)
        if UserDefaults.standard.object(forKey: "highlight_holidays") == nil {
            return true // Default to true for holidays
        }
        return UserDefaults.standard.bool(forKey: "highlight_holidays")
    }
    
    static var highlightSaturdays: Bool {
        // Check if the key exists, if not, return the default value (false for now)
        if UserDefaults.standard.object(forKey: "highlight_saturdays") == nil {
            return false // Default to false for Saturdays
        }
        return UserDefaults.standard.bool(forKey: "highlight_saturdays")
    }
    
    static var highlightSundays: Bool {
        // Check if the key exists, if not, return the default value (true)
        if UserDefaults.standard.object(forKey: "highlight_sundays") == nil {
            return true // Default to true for Sundays
        }
        return UserDefaults.standard.bool(forKey: "highlight_sundays")
    }
}