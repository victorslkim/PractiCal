import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(title: "Getting Started", items: [
                        "Tap a date to select it and view events",
                        "Tap the + button to create new events",
                        "Swipe up and down to navigate months",
                        "Tap the calendar icon to select which calendars to show"
                    ])
                    
                    HelpSection(title: "Creating Events", items: [
                        "Fill in the event title and select a calendar",
                        "Choose start and end times, or toggle 'All Day'",
                        "Add location, notes, and set alerts",
                        "Tap the checkmark to save"
                    ])
                    
                    HelpSection(title: "Managing Calendars", items: [
                        "Only writable calendars can be used for new events",
                        "Read-only calendars (like subscribed calendars) show an info icon",
                        "Add Google calendars through iOS Settings > Calendar > Accounts",
                        "Calendar colors can be customized"
                    ])
                    
                    HelpSection(title: "Search", items: [
                        "Use the search icon to find events across all time",
                        "Search by event name, description, or location",
                        "Tap any result to view or edit the event"
                    ])
                }
                .padding(20)
            }
            .navigationTitle(L("help"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) { dismiss() }
                }
            }
        }
    }
}

struct HelpSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(item)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HelpView()
}