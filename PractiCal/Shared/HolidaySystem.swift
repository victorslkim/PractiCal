import Foundation

// MARK: - Holiday System Protocol
protocol HolidayProvider {
    var name: String { get }
    func isHoliday(_ date: Date) -> Bool
    func getHolidays(for year: Int) -> [Holiday]
}

// MARK: - Holiday Model
struct Holiday {
    let name: String
    let date: Date
    let type: HolidayType
}

enum HolidayType {
    case federal
    case religious
    case cultural
    case regional
}

// MARK: - Holiday Date Helper
enum HolidayDateHelper {
    /// Get the nth occurrence of a weekday in a month
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - weekday: Weekday (1=Sunday, 2=Monday, etc.)
    ///   - occurrence: Which occurrence (1=first, 2=second, etc.)
    static func nthWeekdayOfMonth(year: Int, month: Int, weekday: Int, occurrence: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let firstOfMonth = calendar.date(from: components) else { return nil }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToAdd = (weekday - firstWeekday + 7) % 7 + (occurrence - 1) * 7
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: firstOfMonth)
    }
    
    /// Get the last occurrence of a weekday in a month
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - weekday: Weekday (1=Sunday, 2=Monday, etc.)
    static func lastWeekdayOfMonth(year: Int, month: Int, weekday: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0 // Last day of the month
        
        guard let lastOfMonth = calendar.date(from: components) else { return nil }
        
        let lastWeekday = calendar.component(.weekday, from: lastOfMonth)
        let daysToSubtract = (lastWeekday - weekday + 7) % 7
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: lastOfMonth)
    }
    
    /// Create a date for a specific month and day
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day of month
    static func fixedDate(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}

// MARK: - US Federal Holidays Provider
class USFederalHolidayProvider: HolidayProvider {
    let name = "US Federal Holidays"
    
    func isHoliday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let holidays = getHolidays(for: year)
        
        return holidays.contains { holiday in
            calendar.isDate(date, inSameDayAs: holiday.date)
        }
    }
    
    func getHolidays(for year: Int) -> [Holiday] {
        var holidays: [Holiday] = []
        
        // New Year's Day — January 1
        if let newYears = HolidayDateHelper.fixedDate(year: year, month: 1, day: 1) {
            holidays.append(Holiday(name: "New Year's Day", date: newYears, type: .federal))
        }
        
        // Martin Luther King Jr. Day — Third Monday in January
        if let mlkDay = HolidayDateHelper.nthWeekdayOfMonth(year: year, month: 1, weekday: 2, occurrence: 3) {
            holidays.append(Holiday(name: "Martin Luther King Jr. Day", date: mlkDay, type: .federal))
        }
        
        // Washington's Birthday (Presidents Day) — Third Monday in February
        if let presidentsDay = HolidayDateHelper.nthWeekdayOfMonth(year: year, month: 2, weekday: 2, occurrence: 3) {
            holidays.append(Holiday(name: "Presidents Day", date: presidentsDay, type: .federal))
        }
        
        // Memorial Day — Last Monday in May
        if let memorialDay = HolidayDateHelper.lastWeekdayOfMonth(year: year, month: 5, weekday: 2) {
            holidays.append(Holiday(name: "Memorial Day", date: memorialDay, type: .federal))
        }
        
        // Juneteenth National Independence Day — June 19
        if let juneteenth = HolidayDateHelper.fixedDate(year: year, month: 6, day: 19) {
            holidays.append(Holiday(name: "Juneteenth", date: juneteenth, type: .federal))
        }
        
        // Independence Day — July 4
        if let independenceDay = HolidayDateHelper.fixedDate(year: year, month: 7, day: 4) {
            holidays.append(Holiday(name: "Independence Day", date: independenceDay, type: .federal))
        }
        
        // Labor Day — First Monday in September
        if let laborDay = HolidayDateHelper.nthWeekdayOfMonth(year: year, month: 9, weekday: 2, occurrence: 1) {
            holidays.append(Holiday(name: "Labor Day", date: laborDay, type: .federal))
        }
        
        // Columbus Day / Indigenous Peoples' Day — Second Monday in October
        if let columbusDay = HolidayDateHelper.nthWeekdayOfMonth(year: year, month: 10, weekday: 2, occurrence: 2) {
            holidays.append(Holiday(name: "Columbus Day", date: columbusDay, type: .federal))
        }
        
        // Veterans Day — November 11
        if let veteransDay = HolidayDateHelper.fixedDate(year: year, month: 11, day: 11) {
            holidays.append(Holiday(name: "Veterans Day", date: veteransDay, type: .federal))
        }
        
        // Thanksgiving Day — Fourth Thursday in November
        if let thanksgiving = HolidayDateHelper.nthWeekdayOfMonth(year: year, month: 11, weekday: 5, occurrence: 4) {
            holidays.append(Holiday(name: "Thanksgiving", date: thanksgiving, type: .federal))
        }
        
        // Christmas Day — December 25
        if let christmas = HolidayDateHelper.fixedDate(year: year, month: 12, day: 25) {
            holidays.append(Holiday(name: "Christmas", date: christmas, type: .federal))
        }
        
        return holidays
    }
}

// MARK: - Holiday Manager
class HolidayManager {
    private var currentProvider: HolidayProvider
    
    init(provider: HolidayProvider = USFederalHolidayProvider()) {
        self.currentProvider = provider
    }
    
    /// Switch to a different holiday provider
    func setProvider(_ provider: HolidayProvider) {
        self.currentProvider = provider
    }
    
    /// Check if a date is a holiday using the current provider
    func isHoliday(_ date: Date) -> Bool {
        return currentProvider.isHoliday(date)
    }
    
    /// Get all holidays for a year using the current provider
    func getHolidays(for year: Int) -> [Holiday] {
        return currentProvider.getHolidays(for: year)
    }
    
    /// Get the name of the current holiday provider
    var providerName: String {
        return currentProvider.name
    }
}

// MARK: - Future Holiday Providers (Examples)

// Example: Canadian Federal Holidays (for future implementation)
class CanadianFederalHolidayProvider: HolidayProvider {
    let name = "Canadian Federal Holidays"
    
    func isHoliday(_ date: Date) -> Bool {
        // Implementation would go here
        return false
    }
    
    func getHolidays(for year: Int) -> [Holiday] {
        // Implementation would go here
        return []
    }
}

// Example: Religious Holidays (for future implementation)
class ChristianHolidayProvider: HolidayProvider {
    let name = "Christian Holidays"
    
    func isHoliday(_ date: Date) -> Bool {
        // Implementation would go here (Easter, etc.)
        return false
    }
    
    func getHolidays(for year: Int) -> [Holiday] {
        // Implementation would go here
        return []
    }
}