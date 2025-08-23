import Foundation
import SwiftUI

@MainActor
class AppSettings: ObservableObject {
    // MARK: - Day Cell Settings
    @AppStorage("day_cell_text_size") var dayCellTextSize: Double = 0.0
    @AppStorage("day_cell_bold_text") var dayCellBoldText: Bool = false
    @AppStorage("day_cell_show_background") var dayCellShowBackground: Bool = true
    
    // MARK: - Event Row Card Settings
    @AppStorage("use_24_hour_time") var use24HourTime: Bool = false
    @AppStorage("event_row_card_dim_past_events") var eventRowCardDimPastEvents: Bool = false
    
    // MARK: - Helper Methods
    func resetDayCellSettingsToDefaults() {
        dayCellTextSize = 0.0
        dayCellBoldText = false
        dayCellShowBackground = true
    }
    
    func resetEventRowCardSettingsToDefaults() {
        use24HourTime = false
        eventRowCardDimPastEvents = false
    }
    
    func getDayCellFontSize(baseSize: CGFloat = 12.0) -> CGFloat {
        return baseSize + CGFloat(dayCellTextSize)
    }
    
    func getDayCellFontWeight() -> Font.Weight {
        return dayCellBoldText ? .bold : .regular
    }
    
    func getDayCellChipHeight(baseSize: CGFloat = 8.0) -> CGFloat {
        return getDayCellFontSize(baseSize: baseSize) + CGFloat(4)
        // return max(12, fontSize + 4) // Minimum 12, but scales with font size
    }
    
}
