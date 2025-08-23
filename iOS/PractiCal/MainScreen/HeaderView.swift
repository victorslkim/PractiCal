import SwiftUI

struct HeaderView: View {
    @Environment(CalendarViewModel.self) var viewModel
    let onSearchTapped: () -> Void
    let onToggleTapped: () -> Void
    let onSettingsTapped: () -> Void
    let onCalendarSelectionTapped: () -> Void
    let onDebugToggled: () -> Void
    
    private var viewModeText: String {
        switch viewModel.viewMode {
        case .month:
            return "30"
        case .week:
            return "7"
        case .day:
            return "1"
        }
    }
    
    var body: some View {
        HStack {
            Text(viewModel.monthName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .onTapGesture {
                    onDebugToggled()
                }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { viewModel.goToToday() }) {
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
        onSearchTapped: {},
        onToggleTapped: {},
        onSettingsTapped: {},
        onCalendarSelectionTapped: {},
        onDebugToggled: {}
    )
    .environment(CalendarViewModel(languageManager: LanguageManager()))
}