# PractiCal Development Guide

PractiCal is a practical calendar mobile application for schedule management, available on iOS and Android.

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
- iOS: `./build.sh --device` or `./build.sh --simulator`
- Android: `cd Android && ./gradlew installDebug`
- Do not use Xcode or Android Studio for builds

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
- `WeekView/` - 7-column weekly view with time grid and event blocks
- `DayView/` - single day view with hourly time slots
- `Shared/` - shared components (TimeGrid, WeekDateHeader, CalendarConstants)

#### SearchScreen/
- `SearchView.swift` - search sheet with query input and results
- `SearchResultRow.swift` - individual search result cell

#### EventEditorScreen/
- `EventEditorView.swift` - event creation/editing form
- `EventFormSections.swift` - form field components
- `AlertPickerSheet.swift` - notification alert picker

#### SettingsScreen/
- `SettingsView.swift` - main settings sheet with section list
- `NotificationSettingsView.swift` - notification preferences
- `EditEventSettingsView.swift` - default event settings

#### CalendarSelectionScreen/
- `CalendarSelectionView.swift` - calendar source picker (Google, iCloud, Apple)
- `CalendarInfoView.swift` - individual calendar details

#### Shared/
- `Event.swift` - event data model
- `CalendarManager.swift` - EventKit wrapper for calendar operations
- `ThemeManager.swift` - app theming
- `AppSettings.swift` - user preferences
- `WeekSettings.swift` - week start day configuration
- `HolidaySystem.swift` - holiday detection

### Android (`Android/app/src/main/kotlin/com/practical/calendar/`)

#### Architecture Pattern: 1:1 Screen-ViewModel

Each screen has exactly one ViewModel. Screens must NOT use ViewModels from other screens.

**Rules:**
1. `MainScreen` → `MainViewModel` only
2. `SearchBottomSheet` → `SearchViewModel` only
3. `SettingsBottomSheet` → `SettingsViewModel` only
4. `CalendarSelectionBottomSheet` → `CalendarSelectionViewModel` only
5. `EventEditorBottomSheet` → `EventEditorViewModel` only

**Shared State Pattern:**
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
- `MainViewModel.kt` - main calendar state (events, selected date, current month, view mode)
- `SearchViewModel.kt` - search events loading and filtering
- `CalendarSelectionViewModel.kt` - available calendars loading
- `EventEditorViewModel.kt` - event creation/editing form state
- `SettingsViewModel.kt` - settings persistence and sub-sheet navigation

#### ui/theme/
- `Color.kt` - color definitions
- `Theme.kt` - Material3 theme setup
- `Type.kt` - typography definitions

#### data/model/
- `Event.kt` - event data model with Parcelable support
- `ViewMode.kt` - enum for Month/Week/Day views

#### data/repository/
- `CalendarRepository.kt` - ContentResolver wrapper for calendar operations
- `CalendarPreferencesRepository.kt` - @Singleton, shared calendar selection state (selectedCalendarIds)

#### di/
- `AppModule.kt` - Hilt module providing dependencies

## Coding Guidelines

### Best Practices
- Always follow platform-native patterns and best practices
- Use hardcoded strings directly instead of wrapper functions or dictionary lookups
- Avoid temporary hacks or workarounds - implement features properly or defer them
- No localization wrappers (like `L()` functions) - use plain strings until proper i18n is needed
- Keep code simple and readable over clever abstractions

## UI Conventions
- iOS: SF Symbols for icons, `.sheet()` for modals
- Android: Material Icons, BottomSheet composables
- Dark theme by default, event colors from calendar source

## Performance Notes
- MonthView paging: use `settledPage` not `currentPage` to avoid recomposition storms
- Event loading: use smart caching per month, avoid loading wide date ranges
- HorizontalPager: set `beyondBoundsPageCount = 1` to limit simultaneous renders

## TODO
- [x] Refactor Android to 1:1 screen-viewmodel pattern (e.g., SettingsViewModel for SettingsBottomSheet)
- [x] Drop localization requirement - remove localization code until production-ready
- [ ] Extract CalendarRepository API to interface with clear documentation for each function (both Android and iOS)
