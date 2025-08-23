import Foundation
import SwiftUI
import Combine

class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()

    private var cancellables = Set<AnyCancellable>()

    @Published var firstDayOfWeek: FirstDayOfWeek {
        didSet {
            UserDefaults.standard.set(firstDayOfWeek.rawValue, forKey: "first_day_of_week")
        }
    }

    @Published var highlightHolidays: Bool {
        didSet {
            UserDefaults.standard.set(highlightHolidays, forKey: "highlight_holidays")
        }
    }

    @Published var highlightSaturdays: Bool {
        didSet {
            UserDefaults.standard.set(highlightSaturdays, forKey: "highlight_saturdays")
        }
    }

    @Published var highlightSundays: Bool {
        didSet {
            UserDefaults.standard.set(highlightSundays, forKey: "highlight_sundays")
        }
    }

    private init() {
        // Initialize from UserDefaults
        let firstDayRaw = UserDefaults.standard.integer(forKey: "first_day_of_week")
        self.firstDayOfWeek = FirstDayOfWeek(rawValue: firstDayRaw) ?? .sunday

        self.highlightHolidays = UserDefaults.standard.object(forKey: "highlight_holidays") as? Bool ?? true
        self.highlightSaturdays = UserDefaults.standard.object(forKey: "highlight_saturdays") as? Bool ?? false
        self.highlightSundays = UserDefaults.standard.object(forKey: "highlight_sundays") as? Bool ?? true

        // Listen for external UserDefaults changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.loadFromUserDefaults()
            }
            .store(in: &cancellables)
    }

    private func loadFromUserDefaults() {
        let firstDayRaw = UserDefaults.standard.integer(forKey: "first_day_of_week")
        let newFirstDay = FirstDayOfWeek(rawValue: firstDayRaw) ?? .sunday
        if newFirstDay != firstDayOfWeek {
            firstDayOfWeek = newFirstDay
        }

        let newHolidays = UserDefaults.standard.object(forKey: "highlight_holidays") as? Bool ?? true
        if newHolidays != highlightHolidays {
            highlightHolidays = newHolidays
        }

        let newSaturdays = UserDefaults.standard.object(forKey: "highlight_saturdays") as? Bool ?? false
        if newSaturdays != highlightSaturdays {
            highlightSaturdays = newSaturdays
        }

        let newSundays = UserDefaults.standard.object(forKey: "highlight_sundays") as? Bool ?? true
        if newSundays != highlightSundays {
            highlightSundays = newSundays
        }
    }
}