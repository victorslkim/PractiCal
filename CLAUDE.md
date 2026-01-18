# PractiCal Development Guide

PractiCal is a practical calendar mobile application for schedule management, available on iOS and Android.

## Quick Start for AI Assistants

**What is this?** A dual-platform (iOS + Android) calendar app with Month/Week/Day views, event management, and calendar integration.

**Tech Stack:**
- **iOS:** Swift 5.9+, SwiftUI, @Observable, EventKit
- **Android:** Kotlin, Jetpack Compose, Hilt, Calendar Provider

**Key Architecture:**
- **iOS:** Single CalendarViewModel with @Observable, SwiftUI views, @Environment DI
- **Android:** Single CalendarViewModel (planned refactor to 1:1 screen-viewmodel), Jetpack Compose, Hilt DI

**Important Notes:**
- Build scripts in `iOS/build.sh` and `Android/build.sh` (NOT root directory)
- Android has monolithic CalendarViewModel (refactor planned but not done)
- 40+ languages implemented (planned for removal - see TODO)
- Portrait only, dark theme by default
- Read existing code before proposing changes

## Setup

### Build Requirements
- macOS with iOS SDK
- Xcode 15.0+ (for iOS SDK only, not for building)
- Apple Developer account (for device deployment)
- Android SDK

### Setup Instructions
1. Clone the repository
2. Copy `build.config.template` to `build.config`
3. Edit `build.config` with your Apple Developer details
4. Run `./build.sh --device` or `./build.sh --simulator`

### Build Commands
- iOS: `cd iOS && ./build.sh --device` or `cd iOS && ./build.sh --simulator`
- Android: `cd Android && ./gradlew installDebug` or `cd Android && ./build.sh`
- Do not use Xcode or Android Studio for builds

### Additional Documentation
- **LOCALIZATION.md** - Localization automation guide with Python/Bash scripts
- **Android/SETUP.md** - Complete Android setup, build, and deployment guide

## Tech Stack

### iOS
- Swift 5.9+, iOS 17.0+
- SwiftUI with @Observable macro
- EventKit for calendar integration
- Swift Concurrency (async/await)
- @Environment for dependency injection
- GeometryReader for responsive layouts
- Portrait only, iPhone only

### Android
- Kotlin, Android 15+
- Jetpack Compose with Material3
- Kotlin Coroutines + StateFlow
- Hilt for dependency injection
- Portrait only

## Feature Specifications

### Main Screen

The main screen consists of 3 parts:

#### 1. Header (Fixed, 10% of screen height)
- Month name on the left (format: "JAN", "FEB", etc.)
- 5 buttons on the right:
  - "today" button: navigates to current month/date
  - "calendar" button: opens Calendar Selection screen
  - "settings" button: opens Settings screen
  - "search" button: opens Search screen
  - "add" button: opens Event creation screen

#### 2. Calendar View (Fixed, 65% of screen height)

**Month View:**
- 7 columns × 4-6 rows grid displaying days of the month
- Each cell represents a day and is clickable
- Each cell shows preview of up to 3 events for that date
- Clicking a cell updates the bottom part to show events for that day
- First row shows previous month's days to complete the first week
- Last row shows next month's days to complete the last week
- Swiping left/right navigates to next/previous month
- Multi-day events appear as connected bars spanning across multiple days
- Event names are shown at the start of each week for multi-day events
- Single-day events appear directly below multi-day events without gaps

**Week View:**
- 7 columns × 2 rows grid
- First row: days of the week
- Second row: events for currently selected day (scrollable)

**Day View:**
- Single day with hourly time slots

#### 3. Event List (Dynamic, remaining screen space)
- Selected day display (format: "Fri, Sep 5, 2025")
- Event cards with: name, time, location, description
- Sorted by event time
- Scrollable list

#### Visual States
- Current day: highlighted with slightly brighter black color
- Selected day: highlighted with white color
- When scrolling any part of the screen, the entire screen scrolls as one unit

### Settings Screen

Opens as a sheet when the settings button is tapped.

**Sections:**
1. **General** - Appearance, Edit Event, Notification
2. **Support** - Send Feedback, Help
3. **Support PractiCal** - Share App, Write an App Store Review, Donation

**UI Design:**
- Each section has a title text
- Items have: icon (left), label (center), chevron (right)
- Background color: systemGray6
- Rounded corners (12px radius)

### Calendar Selection Screen

Opens as a sheet when the calendar button is tapped.

**Sections by provider:**
1. Google Calendar
2. iCloud Calendar
3. Apple Calendar

**Calendar Cell Design:**
- Toggle circle (left): Shows calendar color as border, filled when selected
- Calendar name (center)
- Info button (right): Opens calendar settings

**Visual States:**
- Selected: Circle filled with calendar color + white checkmark
- Deselected: Hollow circle with colored border only

### Search Screen
- Search query input
- Results list with event cards
- Tap result to navigate to event's date

### Event Editor Screen
- Event creation and editing form
- Fields: title, start/end time, location, description, calendar, alerts

## Module Structure

### iOS (`iOS/PractiCal/`)

#### MainScreen/
- `MainView.swift` - root view with ScrollView, HeaderView, calendar views, EventListView, FAB, and sheet presentation
- `CalendarViewModel.swift` - central state management for calendar data, selected dates, view mode
- `HeaderView.swift` - top bar with month label and action buttons
- `EventListView.swift` - scrollable list of events for selected day
- `WeekRowView.swift` - single week row used in month grid
- `MonthView/` - month grid with swipeable pages, multi-day event lanes, day cells
  - `MonthView.swift` - main month view container
  - `DateNumbersRow.swift` - day numbers header row
  - `EventsAreaView.swift` - event display area container
  - `SingleDayChipsView.swift` - single-day event chips
  - `MultiDayLanesView.swift` - multi-day event lanes layout
  - `LaneEvent.swift` - lane event data model
- `WeekView/` - 7-column weekly view with time grid and event blocks
  - `WeekView.swift` - main week view container
  - `EventBlockView.swift` - timed event block component
  - `AllDayEventsSection.swift` - all-day events section
- `DayView/` - single day view with hourly time slots
  - `DayView.swift` - main day view container
  - `DayEventBlockView.swift` - day view event block component
- `Shared/` - shared components
  - `TimeGrid.swift` - hourly time grid background
  - `WeekDateHeader.swift` - week day header component
  - `CalendarConstants.swift` - calendar layout constants
  - `EventOverlapDetection.swift` - event overlap calculation utilities
  - `TimeLabel.swift` - time display label component
  - `AllDayLabel.swift` - all-day event label component

#### SearchScreen/
- `SearchView.swift` - search sheet with query input and results
- `SearchResultRow.swift` - individual search result cell

#### EventEditorScreen/
- `EventEditorView.swift` - event creation/editing form
- `EventFormSections.swift` - form field components
- `AlertPickerSheet.swift` - notification alert picker
- `EventInfoView.swift` - event information display view

#### SettingsScreen/
- `SettingsView.swift` - main settings sheet with section list
- `NotificationSettingsView.swift` - notification preferences
- `EditEventSettingsView.swift` - default event settings
- `HelpView.swift` - help and support view
- `CalendarPreview.swift` - calendar preview component for settings
- `DayCellPreview.swift` - day cell preview component for settings
- `EventRowCardCustomizationView.swift` - event card customization settings
- `DefaultCalendarPickerSheet.swift` - default calendar selection sheet

#### CalendarSelectionScreen/
- `CalendarSelectionView.swift` - calendar source picker (Google, iCloud, Apple)
- `CalendarInfoView.swift` - individual calendar details

#### Shared/
- `Event.swift` - event data model
- `Event+Samples.swift` - sample event data for testing/previews
- `CalendarManager.swift` - EventKit wrapper for calendar operations
- `ThemeManager.swift` - app theming
- `AppSettings.swift` - user preferences
- `AppSettingsManager.swift` - settings persistence and management
- `WeekSettings.swift` - week start day configuration
- `HolidaySystem.swift` - holiday detection
- `LayoutConstants.swift` - UI layout constants and dimensions
- `EventHelpers.swift` - event manipulation utilities

#### Localization/
- `LanguageManager.swift` - language selection and management
- `LanguageManager+StringLocalized.swift` - localized string extensions
- `LanguageManager+WeekdaySymbols.swift` - localized weekday symbols
- `LocalizationKeys.swift` - centralized localization key definitions
- `LocalizationHelper.swift` - localization utility functions
- `LanguageSelectionView.swift` - language picker UI
- 40+ `.lproj` folders - language-specific string resources (en, ja, ko, es, fr, de, zh, ar, hi, pt, it, nl, sv, da, no, fi, pl, tr, uk, vi, am, bg, ca, cs, cy, el, etc.)

### Android (`Android/app/src/main/kotlin/com/practical/calendar/`)

#### Current Architecture: Monolithic ViewModel

**Current State:**
- Single `CalendarViewModel` manages all application state
- All screens and bottom sheets inject the same CalendarViewModel instance
- State includes: events, selected date, current month, view mode, calendar lists, search results, settings

**Future Architecture (TODO):** 1:1 Screen-ViewModel Pattern

Each screen should have exactly one dedicated ViewModel. Screens must NOT use ViewModels from other screens.

**Planned Rules:**
1. `MainScreen` → `MainViewModel` only
2. `SearchBottomSheet` → `SearchViewModel` only
3. `SettingsBottomSheet` → `SettingsViewModel` only
4. `CalendarSelectionBottomSheet` → `CalendarSelectionViewModel` only
5. `EventEditorBottomSheet` → `EventEditorViewModel` only

**Shared State Pattern (for future refactor):**
If multiple screens need the same data (e.g., selectedCalendarIds):
1. Extract to a `@Singleton` repository class (e.g., `CalendarPreferencesRepository`)
2. Inject the repository into each ViewModel that needs it via Hilt
3. Use `StateFlow` for reactive updates across ViewModels

**Example:**
```kotlin
// Bad - screen using another screen's ViewModel
fun MainScreen(
    viewModel: MainViewModel,
    calendarSelectionViewModel: CalendarSelectionViewModel  // DON'T DO THIS
)

// Good - shared state via injected repository
@HiltViewModel
class MainViewModel @Inject constructor(
    private val calendarPreferencesRepository: CalendarPreferencesRepository
)
```

#### ui/screen/
- `MainScreen.kt` - root composable, uses only MainViewModel

#### ui/components/
- `HeaderView.kt` - top bar with month label and action buttons
- `MonthView.kt` - month grid with HorizontalPager, day cells, multi-day event lanes
- `WeekView.kt` - weekly view with time grid
- `DayView.kt` - daily view with hourly slots
- `EventListView.kt` - scrollable event list for selected day
- `SearchBottomSheet.kt` - search modal, gets SearchViewModel via hiltViewModel()
- `EventEditorBottomSheet.kt` - event creation/editing modal
- `SettingsBottomSheet.kt` - settings modal, gets SettingsViewModel via hiltViewModel()
- `CalendarSelectionBottomSheet.kt` - calendar picker, gets CalendarSelectionViewModel via hiltViewModel()
- `AppearanceBottomSheet.kt` - theme settings modal

#### ui/viewmodel/
- `CalendarViewModel.kt` - **monolithic ViewModel** managing all app state:
  - Calendar events and event-by-date mapping
  - Selected date, current month, view mode (Month/Week/Day)
  - Available calendars and selected calendar IDs
  - Search query and search results
  - Settings and preferences
  - Sheet visibility states (search, settings, calendar selection, event editor)
  - Holiday detection integration

**Note:** Individual ViewModels (SearchViewModel, SettingsViewModel, etc.) are planned but not yet implemented. See "Future Architecture" above.

#### ui/theme/
- `Color.kt` - color definitions
- `Theme.kt` - Material3 theme setup
- `Type.kt` - typography definitions

#### data/model/
- `Event.kt` - event data model with Parcelable support
- `ViewMode.kt` - enum for Month/Week/Day views

#### data/repository/
- `CalendarRepository.kt` - ContentResolver wrapper for calendar operations
  - Loads events from Android Calendar Provider
  - Provides calendar metadata (name, color, account)
  - Handles calendar permissions

**Note:** Dedicated repositories like `CalendarPreferencesRepository` are planned but not yet implemented. Preferences are currently managed in CalendarViewModel.

#### di/
- `AppModule.kt` - Hilt module providing dependencies

## Architectural Patterns

### State Management
**iOS:**
- Use `@Observable` macro for ViewModels (not `ObservableObject`)
- `@Environment` for dependency injection
- Single source of truth in CalendarViewModel
- Unidirectional data flow

**Android:**
- `StateFlow` for observable state
- `@HiltViewModel` with constructor injection
- Repository pattern for data access
- Compose state hoisting

### Data Flow
1. User interaction → View
2. View calls ViewModel method
3. ViewModel updates Repository/Manager
4. Repository/Manager updates data
5. State flows back to View
6. View recomposes/re-renders

### Dependency Injection
**iOS:** `@Environment` for passing dependencies down the view hierarchy
**Android:** Hilt/Dagger for constructor injection

## UI Conventions
- iOS: SF Symbols for icons, `.sheet()` for modals
- Android: Material Icons, BottomSheet composables
- Dark theme by default, event colors from calendar source
- Consistent spacing: 8px base unit (iOS: 8pt, Android: 8dp)
- Rounded corners: 12px for cards and sheets
- Portrait orientation only (landscape not supported)

## Development Workflows

### For AI Assistants

**Before Making Changes:**
1. Read relevant files first - never propose changes to code you haven't seen
2. Understand the existing architecture and patterns
3. Check both iOS and Android implementations for consistency
4. Review the TODO section to understand planned refactoring

**When Adding Features:**
1. Implement for both iOS and Android unless platform-specific
2. Follow existing patterns (SwiftUI @Observable for iOS, Jetpack Compose + StateFlow for Android)
3. Maintain feature parity between platforms
4. Update this CLAUDE.md if adding new modules or changing architecture

**When Refactoring:**
1. Check if it aligns with TODO items
2. Maintain backward compatibility during transitions
3. Update documentation to reflect new architecture
4. Test on both platforms

**Code Style:**
- iOS: Follow Swift API Design Guidelines, use SwiftUI best practices
- Android: Follow Kotlin coding conventions, use Material 3 design system
- Both: Prefer composition over inheritance, keep functions small and focused

**File Naming Conventions:**
- iOS: PascalCase for files, matches the main type name (e.g., `MonthView.swift`)
- Android: PascalCase for files, matches the main type name (e.g., `MonthView.kt`)
- Screens: Suffix with `View` (iOS) or `Screen` (Android) for top-level screens
- Components: Suffix with `View` for both platforms
- ViewModels: Suffix with `ViewModel`
- Repositories: Suffix with `Repository`

**File Organization:**
- Group by feature/screen, not by type
- Keep related components in the same directory
- Use subdirectories for complex features (e.g., `MonthView/` with multiple files)
- Extensions: Use `+` suffix (e.g., `Event+Samples.swift`, `LanguageManager+StringLocalized.swift`)

### Git Workflow
- Work on feature branches prefixed with `claude/`
- Commit messages: Clear, concise, imperative mood ("Add feature" not "Added feature")
- Push to branch specified in the task context
- Create PR when feature is complete

### Common Pitfalls

**iOS:**
- Don't use `ObservableObject` - use `@Observable` macro instead
- Don't forget to request calendar permissions in Info.plist
- Don't use `.currentPage` in TabView/paging - causes recomposition storms
- SF Symbols must be checked for iOS version availability

**Android:**
- Don't pass ViewModels between screens - use shared repositories
- Don't use `currentPage` in HorizontalPager - use `settledPage`
- Calendar permissions require both READ and WRITE in Android 13+
- Material Icons need to be imported from androidx.compose.material.icons

**Both Platforms:**
- Date/time handling: Always consider timezones and daylight saving time
- Multi-day events: Handle events spanning midnight carefully
- Performance: Loading too many events at once causes lag
- Localization: String keys must match between iOS and Android (currently over-engineered, see TODO)

## Performance Notes
- MonthView paging: use `settledPage` not `currentPage` to avoid recomposition storms
- Event loading: use smart caching per month, avoid loading wide date ranges
- HorizontalPager: set `beyondBoundsPageCount = 1` to limit simultaneous renders
- iOS: Use `@Observable` macro for reactive state, avoid excessive `@Published` properties
- Android: Use `StateFlow` for UI state, avoid unnecessary recomposition

## Testing & Quality

### Current State
- **Unit Tests:** Not yet implemented
- **UI Tests:** Not yet implemented
- **Manual Testing:** Primary testing method

### Testing Strategy (Planned)
**iOS:**
- XCTest for unit tests
- SwiftUI Previews for UI iteration
- XCUITest for integration tests

**Android:**
- JUnit + Truth for unit tests
- Compose Testing for UI tests
- Espresso for integration tests

### Quality Checklist
Before committing changes:
- [ ] Code builds without errors on both platforms
- [ ] No new compiler warnings introduced
- [ ] Manual testing on real devices (iOS and Android)
- [ ] Calendar permissions properly requested
- [ ] Event loading performance is acceptable
- [ ] No crashes on rotation or app backgrounding
- [ ] Consistent behavior between iOS and Android

## TODO

### High Priority
- [ ] **Refactor Android to 1:1 screen-viewmodel pattern**
  - Extract SearchViewModel from CalendarViewModel
  - Extract SettingsViewModel from CalendarViewModel
  - Extract CalendarSelectionViewModel from CalendarViewModel
  - Extract EventEditorViewModel from CalendarViewModel
  - Create CalendarPreferencesRepository for shared state
  - Update all bottom sheets to use hiltViewModel() instead of shared CalendarViewModel

- [ ] **Drop localization requirement** - Remove localization code until production-ready
  - **Current state**: 40+ languages fully implemented with automation scripts
  - Remove iOS/PractiCal/Localization/ folder (6 Swift files + 40+ .lproj folders)
  - Remove localize.py and LOCALIZATION.md
  - Remove language selection from settings
  - Simplify to English-only until production release

- [ ] **Extract CalendarRepository API to interface**
  - Create ICalendarRepository interface with clear documentation
  - Document each function's purpose, parameters, and return values
  - Implement for both Android (CalendarRepository.kt) and iOS (CalendarManager.swift)
  - Add comprehensive inline documentation

### Medium Priority
- [ ] Document all public APIs with inline comments
- [ ] Add unit tests for ViewModels and Repositories
- [ ] Performance optimization for event loading
- [ ] Accessibility improvements (VoiceOver/TalkBack support)
