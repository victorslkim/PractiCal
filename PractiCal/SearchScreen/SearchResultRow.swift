import SwiftUI

struct SearchResultRow: View {
    let event: Event
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Event color indicator
                Rectangle()
                    .fill(event.calendarColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Event name
                    Text(event.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Date and time
                    Text(formatEventDateTime(event))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // Location (if available)
                    if !event.location.isEmpty {
                        Text(event.location)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Description (if available)
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
    }
    
    private func formatEventDateTime(_ event: Event) -> String {
        if event.isFullDay {
            return localizedMediumDate(for: event.time)
        } else {
            return localizedMediumDateWithTime(for: event.time)
        }
    }
}


