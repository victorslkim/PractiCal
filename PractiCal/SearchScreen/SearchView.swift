import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CalendarViewModel
    @State private var searchText = ""
    @State private var filteredEvents: [Event] = []
    @State private var allEvents: [Event] = []
    @State private var editorEvent: Event?
    @State private var hasSubmitted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text(L("search"))
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
                
                // Search Bar
                HStack(spacing: 12) {
                    // Search icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    // Text field
                    TextField(L("search_events"), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.search)
                        .onSubmit {
                            hasSubmitted = true
                            filterEvents(query: searchText)
                        }
                        .onChange(of: searchText) { _, _ in
                            hasSubmitted = false
                            filteredEvents = []
                        }
                    
                    // Clear button (only shown when text exists)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            filteredEvents = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                // Search Results
                if searchText.isEmpty || !hasSubmitted {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(L("search_events"))
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(L("enter_search_term"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                } else if filteredEvents.isEmpty {
                    // No results state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(L("no_results"))
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(L("no_events_found").replacingOccurrences(of: "{search_text}", with: searchText))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                } else {
                    // Results list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredEvents, id: \.id) { event in
                                SearchResultRow(event: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Open event editor
                                        editorEvent = event
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task { await preloadAllEvents() }
        }
        .onChange(of: viewModel.calendarManager.hasPermission) { _, newValue in
            if newValue {
                Task { await preloadAllEvents() }
            }
        }
        .onChange(of: viewModel.selectedCalendarIds) { _, _ in
            Task { await preloadAllEvents() }
        }
        .sheet(item: $editorEvent) { event in
            EventEditorView(viewModel: viewModel, eventToEdit: event)
        }
    }
    
    private func filterEvents(query: String) {
        guard !query.isEmpty else {
            filteredEvents = []
            return
        }
        
        let lowercaseQuery = query.lowercased()
        // Filter against the preloaded full set of events
        filteredEvents = allEvents.filter { event in
            event.name.lowercased().contains(lowercaseQuery) ||
            event.description.lowercased().contains(lowercaseQuery) ||
            event.location.lowercased().contains(lowercaseQuery)
        }.sorted { $0.time > $1.time }
    }

    private func preloadAllEvents() async {
        // Load across a large finite window to ensure predicate returns results
        let now = Date()
        let start = Calendar.current.date(byAdding: .year, value: -2, to: now) ?? now
        let end = Calendar.current.date(byAdding: .year, value: 2, to: now) ?? now
        let allByDate = await viewModel.calendarManager.fetchEventsAsync(from: start, to: end)
        // Flatten and de-duplicate by stable composite key (id + start time) to keep recurring instances
        let flat = allByDate.values.flatMap { $0 }
        var uniqueByKey: [String: Event] = [:]
        for ev in flat {
            let key = "\(ev.id)|\(ev.time.timeIntervalSince1970)"
            uniqueByKey[key] = ev
        }
        await MainActor.run {
            allEvents = Array(uniqueByKey.values).sorted { $0.time > $1.time }
            if !searchText.isEmpty {
                filterEvents(query: searchText)
            }
        }
    }
}

#Preview {
    SearchView(viewModel: CalendarViewModel(languageManager: LanguageManager()))
}