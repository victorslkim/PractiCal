import SwiftUI

struct DayEventBlockView: View {
    let event: Event
    let dayWidth: CGFloat
    let hourHeight: CGFloat
    let columnIndex: Int
    let totalColumns: Int
    let toastManager: DayToastManager?
    let isDebugMode: Bool
    
    private var startHour: Int { Calendar.current.component(.hour, from: event.time) }
    private var startMinute: Int { Calendar.current.component(.minute, from: event.time) }
    private var duration: Int { Calendar.current.dateComponents([.minute], from: event.time, to: event.endTime).minute ?? 60 }
    private var startOffset: CGFloat { (CGFloat(startHour) + CGFloat(startMinute) / 60.0) * hourHeight }
    private var height: CGFloat { max(20, (CGFloat(duration) / 60.0) * hourHeight) }
    
    private var columnWidth: CGFloat { 
        let width = dayWidth / CGFloat(totalColumns)
        
        // Show debugging toast for width calculations
        if isDebugMode, let toastManager = toastManager {
            let message = "DAY '\(event.name)': dayW=\(Int(dayWidth)), totCol=\(totalColumns), colW=\(Int(width))"
            toastManager.showToast(message)
        }
        
        return width
    }
    private var xOffset: CGFloat { CGFloat(columnIndex) * columnWidth }
    
    var body: some View {
        Text(event.name)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(width: columnWidth - 4, height: height, alignment: .topLeading)
            .background(event.calendarColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .offset(x: xOffset, y: startOffset)
    }
}