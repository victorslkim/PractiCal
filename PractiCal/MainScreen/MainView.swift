import SwiftUI
// Import calendar components from MainScreen directory

enum SheetType: Identifiable, Equatable {
    case search
    case eventEditor(Event?)
    case settings
    case calendarSelection
    
    var id: String {
        switch self {
        case .search:
            return "search"
        case .eventEditor(let event):
            return "eventEditor_\(event?.id ?? "new")"
        case .settings:
            return "settings"
        case .calendarSelection:
            return "calendarSelection"
        }
    }
    
    static func == (lhs: SheetType, rhs: SheetType) -> Bool {
        switch (lhs, rhs) {
        case (.search, .search):
            return true
        case (.eventEditor(let lhsEvent), .eventEditor(let rhsEvent)):
            return lhsEvent?.id == rhsEvent?.id
        case (.settings, .settings):
            return true
        case (.calendarSelection, .calendarSelection):
            return true
        default:
            return false
        }
    }
}

struct MainView: View {
    @State private var viewModel: CalendarViewModel
    @State private var activeSheet: SheetType?
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize viewModel with a placeholder - will be set in onAppear
        self._viewModel = State(initialValue: CalendarViewModel(languageManager: LanguageManager()))
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to account for fixed header height
                        Spacer()
                            .frame(height: 60)
                        
                        MonthView(viewModel: viewModel)
                            .frame(width: geometry.size.width)
                            .padding(.vertical, 16)
                        
                        EventListView(
                            viewModel: viewModel,
                            onEventTapped: { event in
                                activeSheet = .eventEditor(event)
                            }
                        )
                        .frame(width: geometry.size.width)
                    }
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.reloadEvents()
                }
                
                // Fixed header at top
                HeaderView(
                    monthName: viewModel.monthName,
                    onTodayTapped: { viewModel.goToToday() },
                    onSearchTapped: { activeSheet = .search },
                    onToggleTapped: { viewModel.toggleView() },
                    onSettingsTapped: { activeSheet = .settings },
                    onCalendarSelectionTapped: { activeSheet = .calendarSelection }
                )
                .frame(width: geometry.size.width, height: 60)
                .background(.ultraThinMaterial)
                // Progress bar under header
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .frame(width: geometry.size.width)
                        .padding(.top, 60)
                }
                
                
                // Floating Action Button (bottom-right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { 
                            activeSheet = .eventEditor(nil)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
            }
            
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .search:
                SearchView(viewModel: viewModel)
            case .eventEditor(let event):
                EventEditorView(viewModel: viewModel, eventToEdit: event)
            case .settings:
                SettingsView(viewModel: viewModel)
            case .calendarSelection:
                CalendarSelectionView(
                    selectedCalendarIds: Binding(
                        get: { 
                            viewModel.selectedCalendarIds
                        },
                        set: { newIds in
                            viewModel.selectedCalendarIds = newIds
                        }
                    ),
                    availableCalendars: viewModel.availableCalendars,
                    calendarColors: Binding(
                        get: { viewModel.calendarManager.calendarColors },
                        set: { viewModel.calendarManager.calendarColors = $0 }
                    )
                )
            }
        }
        .onChange(of: activeSheet) { _, newValue in
            if newValue == nil {
                Task { await viewModel.reloadEvents() }
            }
        }
        .onAppear {
            // Update viewModel with the correct languageManager
            viewModel = CalendarViewModel(languageManager: languageManager)
            Task { await viewModel.reloadEvents() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Refresh events when app becomes active (returns from background)
                Task { await viewModel.reloadEvents() }
            }
        }
    }
    
}


#Preview {
    MainView()
}