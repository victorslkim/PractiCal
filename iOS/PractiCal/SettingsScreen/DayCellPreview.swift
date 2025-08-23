import SwiftUI

struct DayCellPreview: View {
    let textSize: Double
    let boldText: Bool
    let showBackground: Bool
    @EnvironmentObject var appSettings: AppSettings
    
    private var fontSize: CGFloat {
        10.0 + CGFloat(textSize) // Smaller base for preview
    }
    
    private var fontWeight: Font.Weight {
        boldText ? .bold : .regular
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Single day cell with 3 events
            DayCellPreviewItem(
                dayNumber: "15",
                events: ["Meeting", "Lunch", "Call"],
                fontSize: fontSize,
                fontWeight: fontWeight,
                showBackground: showBackground,
                chipHeight: appSettings.getDayCellChipHeight()
            )
            .frame(width: 60, height: 60)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct DayCellPreviewItem: View {
    let dayNumber: String
    let events: [String]
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let showBackground: Bool
    let isToday: Bool
    let isSelected: Bool
    let chipHeight: CGFloat
    
    init(dayNumber: String, events: [String], fontSize: CGFloat, fontWeight: Font.Weight, showBackground: Bool, isToday: Bool = false, isSelected: Bool = false, chipHeight: CGFloat) {
        self.dayNumber = dayNumber
        self.events = events
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.showBackground = showBackground
        self.isToday = isToday
        self.isSelected = isSelected
        self.chipHeight = chipHeight
    }
    
    var body: some View {
        VStack(spacing: 1) {
            // Day number
            Text(dayNumber)
                .font(.caption2)
                .fontWeight(fontWeight)
                .foregroundColor(dayNumberColor)
                .frame(width: 20, height: 12)
            
            // Events - match the new chip designs
            VStack(spacing: 1) {
                ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { index, event in
                    if index == 0 {
                        // First event: all-day event with background
                        HStack(spacing: 0) {
                            // Vertical color bar
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2)
                            
                            // Background with brighter color
                            Rectangle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: chipHeight)
                        .overlay(
                            Text(event)
                                .font(.system(size: fontSize, weight: fontWeight))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity, maxHeight: chipHeight, alignment: .leading)
                        )
                        .contentShape(Rectangle())
                    } else {
                        // Other events: regular events with vertical bar but no background
                        HStack(spacing: 0) {
                            // Vertical color bar
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2)
                            
                            // No background color
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: chipHeight)
                        .overlay(
                            Text(event)
                                .font(.system(size: fontSize, weight: fontWeight))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity, maxHeight: chipHeight, alignment: .leading)
                        )
                        .contentShape(Rectangle())
                    }
                }
            }
            .frame(minHeight: max(30, fontSize * 3 + 6))
        }
        .frame(width: 60, height: max(46, fontSize * 3 + 16))
        .background(backgroundColor)
        .cornerRadius(4)
    }
    
    private var dayNumberColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return Color.blue.opacity(0.2)
        } else {
            return .clear
        }
    }
}

#Preview {
    DayCellPreview(
        textSize: 0,
        boldText: false,
        showBackground: true
    )
    .padding()
}
