# PractiCal Calendar App - Requirements

PractiCal is a practical calendar mobile application for schedule management.
Available on iOS and Android platforms.

## Dependencies and Setup

This project uses:
- iOS 17.0+ (required for @Observable and modern SwiftUI features)
- Swift 5.9+
- SwiftUI for the user interface
- EventKit for calendar integration
- No external dependencies or Package Manager needed

### Build Requirements
- Xcode 15.0+
- Apple Developer account (for device deployment)
- macOS with iOS SDK

### Setup Instructions
1. Clone the repository
2. Copy `build.config.template` to `build.config`
3. Edit `build.config` with your Apple Developer details
4. Run `./build.sh` to build and install

## Localization

The app supports 43+ languages with automated translation tools:
- **localize.py**: Python-based localization automation using OpenAI API
- Run `./localize.py` to generate translations for new strings
- Manual review recommended for accuracy

# FEATURE DESCRIPTION

## Main Screen (Design: /Design/MainScreen.png)

The main screen consists of 3 parts:

### 1. Top Part (Fixed height, 10% of screen height)
- Month name on the left (format: "JAN", "FEB", etc.)
- 5 buttons on the right:
  - "today" button: navigates to current month/date
  - "calendar" button: opens Calendar Selection screen
  - "settings" button: opens Settings screen
  - "search" button: opens Search screen for event search
  - "add" button: opens Event creation screen

### 2. Middle Part (Fixed height, 65% of screen height)

#### Month View:
- 7 columns × 4-6 rows grid displaying days of the month (variable height based on month)
- Each cell represents a day and is clickable
- Each cell is taller and shows preview of up to 3 events for that date
- Clicking a cell updates the bottom part to show events for that day
- First row shows previous month's days to complete the first week
- Last row shows next month's days to complete the last week
- Swiping left/right navigates to next/previous month with immediate visual feedback
- Multi-day events appear as connected bars spanning across multiple days
- Event names are shown at the start of each week for multi-day events
- Single-day events appear directly below multi-day events without gaps

#### Week View:
- 7 columns × 2 rows grid
- First row: days of the week
- Second row: events for currently selected day (scrollable)

### 3. Bottom Part (Dynamic length, remaining screen space)
- Selected day display (format: "Fri, Sep 5, 2025")
- Event list for selected day:
  - Event cards with: name, time, location, description
  - Sorted by event time
  - Scrollable list

### Additional Main Screen Requirements:
- Current day: highlighted with slightly brighter black color
- Selected day: highlighted with white color
- Bottom part overflows below screen
- When scrolling any part of the screen, the entire screen scrolls as one unit
- Event list scrolling should scroll the entire screen, not just the bottom part

---

# Android Performance Optimizations (Completed)

## Issue: Laggy Month Swiping
**Problem**: HorizontalPager month swiping felt laggy due to multiple performance bottlenecks.

**Root Causes Identified**:
1. **Excessive event loading**: Loading +/- 31 day ranges (51 events per month) instead of targeted monthly data
2. **Recomposition storms**: Using `currentPage` instead of `settledPage` caused loading on every scroll frame  
3. **Multiple page rendering**: HorizontalPager was rendering 3-4 pages simultaneously during swipes
4. **Inefficient event merging**: Redistributing entire event list on every month load

**Solutions Implemented**:

### 1. Fixed Event Range Loading
- **File**: `CalendarViewModel.kt:288-294`
- **Change**: Replaced expensive +/- 31 day loading with smart caching approach
- **Impact**: November month now loads only 9 events instead of 51

### 2. Optimized Event Merging Logic  
- **File**: `CalendarViewModel.kt:206-243`
- **Change**: Replaced full `distributeEventsAcrossDays()` with targeted updates for specific months only
- **Impact**: Significantly reduced computation overhead on each month load

### 3. Enhanced Smart Caching
- **Implementation**: `loadedMonths` set prevents redundant API calls
- **Behavior**: Only loads adjacent months when actually needed
- **Verification**: Debug logs confirm "Events already loaded for settled month"

### 4. HorizontalPager Optimization
- **File**: `MonthView.kt:131`
- **Change**: Added `beyondBoundsPageCount = 1` to limit simultaneous page rendering
- **Impact**: Reduced recompositions during swipe gestures

**Performance Improvements Achieved**:
- ✅ Targeted loading: Months load only their specific events instead of expanded ranges
- ✅ Eliminated redundant calls: Smart caching prevents unnecessary API calls  
- ✅ Reduced recompositions: Limited simultaneous page rendering
- ✅ Faster event merging: Incremental updates instead of full redistribution

### Android Performance Status: ✅ OPTIMIZED
The core performance issues have been resolved:
- ✅ Excessive event loading → Smart caching with targeted monthly loading
- ✅ Recomposition storms → Using `settledPage` instead of `currentPage`
- ✅ Multiple page rendering → `beyondBoundsPageCount = 1`
- ✅ Inefficient event merging → Incremental updates only for affected months

**User Experience**: Month swiping is now smooth and lag-free.

## Other Screens

### Search Screen
Empty screen (design to be updated later)

### Event Creation Screen
Empty screen (design to be updated later)

### Event Editing Screen
Empty screen (design to be updated later)

### Settings Screen
Settings screen opens as a sheet when the settings button (gear icon) in the main screen header is tapped.

#### Layout:
- **Header**: Large text that says "Settings"
- **3 Sections** with the following structure:

1. **General**
   - Appearance
   - Edit Event  
   - Notification

2. **Support**
   - Send Feedback
   - Help

3. **Support PractiCal**
   - Share App
   - Write an App Store Review
   - Donation

#### UI Design:
- Each section has a title text
- Items in each section have:
  - Same background color as event list in main screen (systemGray6)
  - Icon constrained to the left of the cell (using relevant SF Symbols)
  - Item text (e.g. "Appearance") constrained to the right of the icon
  - ">" chevron constrained to the right of the cell
  - Rounded corners (12px radius)
  - Proper padding and spacing

### Calendar Selection Screen
Calendar selection screen opens as a sheet when the calendar button (calendar icon) in the main screen header is tapped.

#### Layout:
- **Header**: Large text that says "Calendars" with X button for closing
- **3 Sections** organized by calendar provider:

1. **Google Calendar**
   - Section header with globe icon and "Google Calendar" text
   - Individual calendar entries (e.g., xxx@gmail.com, Holidays in United States)

2. **iCloud Calendar**
   - Section header with iCloud icon and "iCloud Calendar" text
   - Individual calendar entries (e.g., Personal, Family, Work)

3. **Apple Calendar**
   - Section header with calendar icon and "Apple Calendar" text
   - Individual calendar entries (e.g., Calendar, Reminders)

#### Calendar Cell Design:
Each calendar row contains:
- **Toggle circle** (left): Shows calendar color as border, filled with color and checkmark when selected
- **Calendar name** (center): Name of the calendar (e.g., "xxx@gmail.com", "Personal")
- **Info button** (right): "i" icon that opens calendar settings sheet

#### Interaction:
- **Toggle selection**: Tap the colored circle to enable/disable calendar
- **Calendar settings**: Tap info button to open settings sheet (empty for now)
- **Visual states**:
  - Selected: Circle filled with calendar color + white checkmark
  - Deselected: Hollow circle with colored border only

# PLATFORM REQUIREMENTS

## Directory Structure Requirements
- **MainScreen/** - Contains all files specific to the main calendar screen
- **SearchScreen/** - Contains all files specific to the search functionality
- **EventEditorScreen/** - Contains all files specific to event creation and editing
- **SettingsScreen/** - Contains all files specific to the settings functionality
- **CalendarSelectionScreen/** - Contains all files specific to calendar selection functionality
- **Shared/** - Contains files shared across multiple screens (data models, utilities, etc.)
- Files used for a specific screen should belong to that screen's directory
- Files used across multiple screens should be in the Shared directory

## iOS Platform Requirements
- iOS Version: Minimum iOS 17.0
- Device Support: iPhone only
- Orientation: Portrait only
- Language: Swift 5.9+
- UI Framework: SwiftUI
- State Management: @State, @StateObject, @ObservableObject
- Networking: Swift Async/Await

## Android Platform Requirements
- Android Version: Minimum Android 15.0+ (or specify your target)
- Device Support: Android only
- Orientation: Portrait only
- Language: Kotlin
- UI Framework: Jetpack Compose
- Networking: Kotlin Coroutines
