import SwiftUI

struct TimeLabel: View {
    let hour: Int
    let isDebugMode: Bool
    
    var body: some View {
        Text(timeLabel(for: hour))
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: CalendarConstants.timeColumnWidth, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.trailing, CalendarConstants.timeLabelTrailingPadding)
            .border(isDebugMode ? Color.cyan : Color.clear, width: 1)
    }
    
    private func timeLabel(for hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}