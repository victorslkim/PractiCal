import SwiftUI
import EventKit

struct CalendarSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCalendarIds: Set<String>
    let availableCalendars: [EKCalendar]
    @Binding var calendarColors: [String: Color]
    @State private var showingCalendarInfo = false
    @State private var selectedCalendarForInfo: CalendarItem?
    @State private var localSelectedIds: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with close button
                    HStack {
                        Text(L("calendars"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    VStack(spacing: 24) {
                        // Google Calendar Section
                        if !googleCalendarItems.isEmpty {
                            CalendarSection(
                                title: "Google Calendar",
                                icon: "globe",
                                calendars: googleCalendarItems,
                                selectedCalendars: $localSelectedIds,
                                onToggle: { calendar, isSelected in
                                    updateSelection(for: calendar.id, isSelected: isSelected)
                                },
                                onInfoTapped: { calendar in
                                    selectedCalendarForInfo = calendar
                                    showingCalendarInfo = true
                                }
                            )
                        }

                        // iCloud Calendar Section
                        if !iCloudCalendarItems.isEmpty {
                            CalendarSection(
                                title: "iCloud Calendar",
                                icon: "icloud.fill",
                                calendars: iCloudCalendarItems,
                                selectedCalendars: $localSelectedIds,
                                onToggle: { calendar, isSelected in
                                    updateSelection(for: calendar.id, isSelected: isSelected)
                                },
                                onInfoTapped: { calendar in
                                    selectedCalendarForInfo = calendar
                                    showingCalendarInfo = true
                                }
                            )
                        }

                        // Apple Calendar Section
                        if !appleCalendarItems.isEmpty {
                            CalendarSection(
                                title: "Apple Calendar",
                                icon: "calendar",
                                calendars: appleCalendarItems,
                                selectedCalendars: $localSelectedIds,
                                onToggle: { calendar, isSelected in
                                    updateSelection(for: calendar.id, isSelected: isSelected)
                                },
                                onInfoTapped: { calendar in
                                    selectedCalendarForInfo = calendar
                                    showingCalendarInfo = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGray6).opacity(0.4))
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .sheet(isPresented: $showingCalendarInfo) {
            CalendarInfoView(calendar: selectedCalendarForInfo, calendarColors: $calendarColors)
        }
        .onAppear {
            localSelectedIds = selectedCalendarIds
        }
        .onChange(of: selectedCalendarIds) { _, newValue in
            localSelectedIds = newValue
        }
        .onDisappear {
            // Ensure changes are committed when view disappears
            selectedCalendarIds = localSelectedIds
        }
    }
    
    private func updateSelection(for calendarId: String, isSelected: Bool) {
        if isSelected {
            localSelectedIds.insert(calendarId)
        } else {
            localSelectedIds.remove(calendarId)
        }
        selectedCalendarIds = localSelectedIds
    }
        
    // MARK: - Provider Grouping
    private var googleCalendarItems: [CalendarItem] {
        let items = availableCalendars
            .filter { isGoogle(calendar: $0) }
            .map { toItem($0) }
        return items
    }

    private var iCloudCalendarItems: [CalendarItem] {
        let items = availableCalendars
            .filter { isICloud(calendar: $0) }
            .map { toItem($0) }
        return items
    }

    private var appleCalendarItems: [CalendarItem] {
        let items = availableCalendars
            .filter { isApple(calendar: $0) }
            .map { toItem($0) }
        return items
    }

    private func toItem(_ ek: EKCalendar) -> CalendarItem {
        let color = calendarColors[ek.calendarIdentifier] ?? (ek.cgColor != nil ? Color(ek.cgColor!) : .blue)
        return CalendarItem(id: ek.calendarIdentifier, name: ek.title, color: color)
    }

    private func isGoogle(calendar: EKCalendar) -> Bool {
        let sourceTitle = calendar.source.title.lowercased()
        let calendarTitle = calendar.title.lowercased()
        
        // Check source title for "google" or "gmail"
        if sourceTitle.contains("google") || sourceTitle.contains("gmail") {
            return true
        }
        
        // Check calendar title for Gmail address pattern
        if calendarTitle.contains("@gmail.com") {
            return true
        }
        
        return false
    }

    private func isICloud(calendar: EKCalendar) -> Bool {
        let sourceTitle = calendar.source.title.lowercased()
        return sourceTitle.contains("icloud")
    }

    private func isApple(calendar: EKCalendar) -> Bool {
        // Anything not Google/iCloud treated as Apple (on-device or subscribed)
        return !(isGoogle(calendar: calendar) || isICloud(calendar: calendar))
    }
}

#Preview {
    CalendarSelectionView(
        selectedCalendarIds: .constant(["demo"]),
        availableCalendars: [],
        calendarColors: .constant([:])
    )
}

struct CalendarItem: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color
    
    static func == (lhs: CalendarItem, rhs: CalendarItem) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

struct CalendarSection: View {
    let title: String
    let icon: String
    let calendars: [CalendarItem]
    @Binding var selectedCalendars: Set<String>
    let onToggle: ((CalendarItem, Bool) -> Void)?
    let onInfoTapped: (CalendarItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(calendars) { calendar in
                    CalendarRow(
                        calendar: calendar,
                        isSelected: selectedCalendars.contains(calendar.id),
                        onToggle: {
                            let wasSelected = selectedCalendars.contains(calendar.id)
                            
                            if wasSelected {
                                selectedCalendars.remove(calendar.id)
                            } else {
                                selectedCalendars.insert(calendar.id)
                            }
                            
                            onToggle?(calendar, !wasSelected)
                        },
                        onInfoTapped: { onInfoTapped(calendar) }
                    )
                }
            }
        }
    }
}

struct CalendarRow: View {
    let calendar: CalendarItem
    let isSelected: Bool
    let onToggle: () -> Void
    let onInfoTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Calendar toggle with color
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isSelected ? calendar.color : Color(.systemGray5))
                        .overlay(
                            Circle()
                                .stroke(calendar.color, lineWidth: isSelected ? 0 : 2)
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(calendar.name)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onInfoTapped) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

