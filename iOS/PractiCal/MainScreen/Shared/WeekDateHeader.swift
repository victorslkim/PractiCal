import SwiftUI

struct WeekDateHeader: View {
    @Bindable var viewModel: CalendarViewModel
    let weekDates: [Date]
    let dayLabels: [String]
    let onDateTapped: ((Date) -> Void)?
    
    init(viewModel: CalendarViewModel, 
         weekDates: [Date], 
         dayLabels: [String],
         onDateTapped: ((Date) -> Void)? = nil) {
        self.viewModel = viewModel
        self.weekDates = weekDates
        self.dayLabels = dayLabels
        self.onDateTapped = onDateTapped
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width - (CalendarConstants.timeColumnWidth + CalendarConstants.timeLabelTrailingPadding)
                let dayWidth = availableWidth / CalendarConstants.daysInWeek
                
                VStack(spacing: 8) {
                    // Day labels (S M T W T F S)
                    HStack(spacing: 0) {
                        // Time column spacer (match AllDayLabel total width)
                        Spacer()
                            .frame(width: CalendarConstants.timeColumnWidth + CalendarConstants.timeLabelTrailingPadding)
                            .border(viewModel.isDebugMode ? Color.red : Color.clear, width: 1)
                        
                        // Day labels
                        HStack(spacing: 0) {
                            ForEach(dayLabels.indices, id: \.self) { index in
                                Text(dayLabels[index])
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: dayWidth)
                                    .foregroundColor(.secondary)
                                    .border(viewModel.isDebugMode ? Color.blue : Color.clear, width: 1)
                            }
                        }
                    }
                    
                    // Date numbers
                    HStack(spacing: 0) {
                        // Time column spacer (match AllDayLabel total width)
                        Spacer()
                            .frame(width: CalendarConstants.timeColumnWidth + CalendarConstants.timeLabelTrailingPadding)
                            .border(viewModel.isDebugMode ? Color.red : Color.clear, width: 1)
                        
                        // Date numbers
                        HStack(spacing: 0) {
                            ForEach(weekDates, id: \.self) { date in
                                let dayNumber = Calendar.current.component(.day, from: date)
                                Button(action: {
                                    viewModel.selectedDate = date
                                    onDateTapped?(date)
                                }) {
                                    Text("\(dayNumber)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(textColor(for: date))
                                        .frame(width: 32, height: 32)
                                        .background(backgroundColor(for: date))
                                        .clipShape(Circle())
                                }
                                .frame(width: dayWidth)
                                .border(viewModel.isDebugMode ? Color.green : Color.clear, width: 1)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(height: 72)
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
            return Color(.label)
        }
        if Calendar.current.isDateInToday(date) {
            return Color(.systemGray4)
        }
        return .clear
    }
    
    private func textColor(for date: Date) -> Color {
        if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
            return Color(.systemBackground)
        }
        if Calendar.current.isDateInToday(date) {
            return .primary
        }
        
        if Calendar.current.isDate(date, equalTo: viewModel.currentMonth, toGranularity: .month) {
            return .primary
        }
        return .secondary
    }
}