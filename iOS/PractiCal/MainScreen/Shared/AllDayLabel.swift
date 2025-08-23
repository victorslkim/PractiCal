import SwiftUI

struct AllDayLabel: View {
    let isDebugMode: Bool
    
    var body: some View {
        Text("all day")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: CalendarConstants.timeColumnWidth, alignment: .trailing)
            .padding(.trailing, CalendarConstants.timeLabelTrailingPadding)
            .border(isDebugMode ? Color.red : Color.clear, width: 1)
    }
}