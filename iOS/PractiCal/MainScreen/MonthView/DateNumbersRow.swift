import SwiftUI

struct DateNumbersRow: View {
    let weekDates: [Date]
    let daySpacing: CGFloat
    let dateRowHeight: CGFloat
    let dayNumber: (Date) -> String
    let textColor: (Date) -> Color
    
    var body: some View {
        HStack(spacing: daySpacing) {
            ForEach(weekDates, id: \.self) { date in
                Text(dayNumber(date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor(date))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
            }
        }
        .frame(height: dateRowHeight)
    }
}
