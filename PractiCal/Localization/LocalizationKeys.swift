import Foundation

// MARK: - Localization Keys
// This file contains all the localization keys used throughout the app

struct LocalizationKeys {
    // MARK: - General
    static let settings = "settings"
    static let done = "done"
    static let cancel = "cancel"
    static let save = "save"
    static let delete = "delete"
    static let edit = "edit"
    static let add = "add"
    static let search = "search"
    static let ok = "ok"
    
    // MARK: - Main Screen
    static let practical = "practical"
    static let today = "today"
    static let allDay = "all_day"
    static let noEvents = "no_events"
    
    // MARK: - Settings
    static let general = "general"
    static let appearance = "appearance"
    static let editEvent = "edit_event"
    static let notification = "notification"
    static let support = "support"
    static let sendFeedback = "send_feedback"
    static let help = "help"
    static let supportPractical = "support_practical"
    static let shareApp = "share_app"
    static let writeReview = "write_review"
    static let donation = "donation"
    
    // MARK: - Appearance Settings
    static let preview = "preview"
    static let calendarSettings = "calendar_settings"
    static let firstDayOfWeek = "first_day_of_week"
    static let theme = "theme"
    static let accentColor = "accent_color"
    static let highlight = "highlight"
    static let language = "language"
    static let holidays = "holidays"
    static let saturdays = "saturdays"
    static let sundays = "sundays"
    static let sat = "sat"
    static let sun = "sun"
    
    // MARK: - Language
    static let systemDefault = "system_default"
    static let searchLanguages = "search_languages"
    
    // MARK: - Week Days
    static let sunday = "sunday"
    static let monday = "monday"
    static let tuesday = "tuesday"
    static let wednesday = "wednesday"
    static let thursday = "thursday"
    static let friday = "friday"
    static let saturday = "saturday"
    
    // MARK: - Themes
    static let system = "system"
    static let light = "light"
    static let dark = "dark"
    
    // MARK: - Event Editor
    static let newEvent = "new_event"
    static let eventTitle = "event_title"
    static let location = "location"
    static let url = "url"
    static let notes = "notes"
    static let startDate = "start_date"
    static let endDate = "end_date"
    static let calendar = "calendar"
    static let alert = "alert"
    static let `repeat` = "repeat"
    static let removeEvent = "remove_event"
    static let removeEventConfirmation = "remove_event_confirmation"
    static let removeEventMessage = "remove_event_message"
    
    // MARK: - Alert Options
    static let none = "none"
    static let atTimeOfEvent = "at_time_of_event"
    static let fiveMinBefore = "5_min_before"
    static let fifteenMinBefore = "15_min_before"
    static let thirtyMinBefore = "30_min_before"
    static let oneHourBefore = "1_hour_before"
    static let oneDayBefore = "1_day_before"
    
    // MARK: - Alerts
    static let couldntSaveEvent = "couldnt_save_event"
    static let tryAgain = "try_again"
    static let emailNotAvailable = "email_not_available"
    static let setupMail = "setup_mail"
    static let readOnlyCalendar = "read_only_calendar"
    
    // MARK: - Error Messages
    static let failedToDelete = "failed_to_delete"
    static let failedToSave = "failed_to_save"
    static let readOnlyCalendarMessage = "read_only_calendar_message"
}

// MARK: - Localized String Function
func localizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}