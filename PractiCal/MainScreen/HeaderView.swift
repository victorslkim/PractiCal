import SwiftUI

struct HeaderView: View {
    let monthName: String
    let onTodayTapped: () -> Void
    let onSearchTapped: () -> Void
    let onToggleTapped: () -> Void
    let onSettingsTapped: () -> Void
    let onCalendarSelectionTapped: () -> Void
    
    var body: some View {
        HStack {
            Text(monthName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onTodayTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text(L("today"))
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
                .fixedSize()
                
                Button(action: onSearchTapped) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                }
                
                Button(action: onCalendarSelectionTapped) {
                    Image(systemName: "calendar")
                        .font(.title3)
                }
                
                Button(action: onSettingsTapped) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
                
                // Week/Month toggle disabled for now
                // Button(action: onToggleTapped) {
                //     Image(systemName: "rectangle.grid.1x2")
                //         .font(.title3)
                // }
            }
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding)
        .padding(.vertical, LayoutConstants.verticalPadding)
        .background(Color(.systemBackground))
    }
}

#Preview {
    HeaderView(
        monthName: "JAN",
        onTodayTapped: {},
        onSearchTapped: {},
        onToggleTapped: {},
        onSettingsTapped: {},
        onCalendarSelectionTapped: {}
    )
}