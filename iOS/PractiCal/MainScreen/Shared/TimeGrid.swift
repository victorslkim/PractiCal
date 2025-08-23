import SwiftUI

struct TimeGrid: View {
    let hourHeight: CGFloat
    let hours: [Int]
    let isDebugMode: Bool
    let showVerticalGrid: Bool
    let showCurrentTimeIndicator: Bool
    let content: () -> AnyView
    
    init(hourHeight: CGFloat = CalendarConstants.hourHeight,
         hours: [Int] = Array(stride(from: 0, through: 23, by: 1)),
         isDebugMode: Bool = false,
         showVerticalGrid: Bool = false,
         showCurrentTimeIndicator: Bool = true,
         @ViewBuilder content: @escaping () -> some View) {
        self.hourHeight = hourHeight
        self.hours = hours
        self.isDebugMode = isDebugMode
        self.showVerticalGrid = showVerticalGrid
        self.showCurrentTimeIndicator = showCurrentTimeIndicator
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Time labels column (fixed width)
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    TimeLabel(
                        hour: hour,
                        isDebugMode: isDebugMode
                    )
                    .frame(height: hourHeight)
                    .border(isDebugMode ? Color.red : Color.clear, width: 2) // Debug boundary
                    .id("hour-\(hour)")
                }
            }
            .frame(width: CalendarConstants.timeColumnWidth + CalendarConstants.timeLabelTrailingPadding)
            .border(isDebugMode ? Color.purple : Color.clear, width: 3) // Debug boundary for entire time column
            
            // Right: Events area (flexible width)
            GeometryReader { geometry in
                let dayWidth = geometry.size.width / CalendarConstants.daysInWeek
                
                ZStack(alignment: .topLeading) {
                    // Horizontal grid lines
                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            VStack(spacing: 0) {
                                // Horizontal grid line at top of hour slot
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 0.5)
                                
                                // All empty space below the line
                                Spacer()
                            }
                            .frame(height: hourHeight)
                        }
                    }
                    
                    // Vertical grid lines for day separation
                    if showVerticalGrid {
                        HStack(spacing: 0) {
                            // Vertical lines between days
                            ForEach(1..<7, id: \.self) { dayIndex in
                                Spacer()
                                    .frame(width: dayWidth)
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 0.5)
                            }
                            
                            // Final spacer for last day
                            Spacer()
                        }
                    }
                    
                    // Current time indicator
                    if showCurrentTimeIndicator {
                        currentTimeIndicator
                    }
                    
                    // Custom content overlay
                    content()
                }
            }
            .border(isDebugMode ? Color.orange : Color.clear, width: 3) // Debug boundary for events area
        }
        .frame(height: CGFloat(hours.count) * hourHeight)
    }
    
    private var currentTimeIndicator: some View {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Calculate the exact position within the hour
        let minuteProgress = Double(minute) / 60.0
        let hourProgress = Double(hour) + minuteProgress
        let yPosition = CGFloat(hourProgress) * hourHeight
        
        return HStack(spacing: 0) {
            // Current time line
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
            
            // Dot at the end of the line
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)
        }
        .offset(y: yPosition)
    }
}