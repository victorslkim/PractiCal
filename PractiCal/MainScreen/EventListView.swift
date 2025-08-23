import SwiftUI

struct EventListView: View {
    @Bindable var viewModel: CalendarViewModel
    let onEventTapped: (Event) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.selectedDateString)
                .font(.title2)
                .fontWeight(.medium)
                .padding(.horizontal, LayoutConstants.horizontalPadding)
                .padding(.vertical, LayoutConstants.verticalPadding)
            
            if viewModel.eventsForSelectedDate.isEmpty {
                VStack {
                    Text(L("no_events"))
                        .foregroundColor(.secondary)
                        .font(.body)
                        .padding(.vertical, 32)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.eventsForSelectedDate) { event in
                        EventRowCard(event: event, onTapped: { onEventTapped(event) })
                    }
                }
                .padding(.horizontal, LayoutConstants.horizontalPadding)
                .padding(.vertical, LayoutConstants.verticalPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
}

struct EventRowCard: View {
    let event: Event
    let onTapped: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    private var shouldDim: Bool {
        guard appSettings.eventRowCardDimPastEvents else { return false }
        return event.endTime < Date() // Only dim if the event is completely over
    }
    
    private var opacity: Double {
        return shouldDim ? 0.5 : 1.0
    }
    
    private var timeString: String {
        if event.isFullDay {
            return L("all_day")
        } else {
            return appSettings.use24HourTime ? 
                LanguageManager().localizedTime(for: event.time) :
                event.timeString
        }
    }
    
    var body: some View {
        Button(action: onTapped) {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(width: 60, alignment: .leading)
            
            // Colored vertical line
            Rectangle()
                .fill(event.calendarColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !event.location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(opacity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EventListView(
        viewModel: CalendarViewModel(languageManager: LanguageManager()),
        onEventTapped: { _ in }
    )
}

#Preview("EventRowCard") {
    VStack(spacing: 16) {
        EventRowCard(
            event: Event.sampleEvents.first!,
            onTapped: { print("Event tapped") }
        )
        
        EventRowCard(
            event: Event.sampleEvents.last!,
            onTapped: { print("Event tapped") }
        )
    }
    .padding()
    .background(Color(.systemBackground))
}