package com.practical.calendar.ui.viewmodel

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.practical.calendar.data.model.Event
import com.practical.calendar.data.model.ViewMode
import com.practical.calendar.data.repository.CalendarInfo
import com.practical.calendar.data.repository.CalendarRepository
import com.practical.calendar.data.WeekSettings
import com.practical.calendar.data.HolidayManager
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.LocalDate
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.plus
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime
import java.time.LocalDateTime as JavaLocalDateTime
import java.time.ZoneId
import javax.inject.Inject

@HiltViewModel
class CalendarViewModel @Inject constructor(
    private val calendarRepository: CalendarRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val holidayManager = HolidayManager()

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    private val _events = MutableStateFlow<List<Event>>(emptyList())
    val events: StateFlow<List<Event>> = _events.asStateFlow()
    
    private val _eventsByDate = MutableStateFlow<Map<LocalDate, List<Event>>>(emptyMap())
    val eventsByDate: StateFlow<Map<LocalDate, List<Event>>> = _eventsByDate.asStateFlow()

    private val _availableCalendars = MutableStateFlow<List<CalendarInfo>>(emptyList())
    val availableCalendars: StateFlow<List<CalendarInfo>> = _availableCalendars.asStateFlow()

    private val _searchEvents = MutableStateFlow<List<Event>>(emptyList())
    val searchEvents: StateFlow<List<Event>> = _searchEvents.asStateFlow()

    var selectedDate by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set

    var currentMonth by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set
        
    // Month range for HorizontalPager (200 months centered around current)
    val monthRange: List<LocalDate> by lazy {
        val startMonth = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date.minus(100, DateTimeUnit.MONTH)
        (0..199).map { offset ->
            startMonth.plus(offset, DateTimeUnit.MONTH)
        }
    }
    
    // Get current month index in the range
    fun getCurrentMonthIndex(): Int {
        return monthRange.indexOfFirst { it == currentMonth }.takeIf { it >= 0 } ?: 100
    }
    
    // Get month for a given page index
    fun getMonthForPage(pageIndex: Int): LocalDate {
        return monthRange.getOrNull(pageIndex) ?: currentMonth
    }

    // Get page index for a given month
    fun getPageIndexForMonth(month: LocalDate): Int {
        return monthRange.indexOfFirst {
            it.year == month.year && it.monthNumber == month.monthNumber
        }.takeIf { it >= 0 } ?: getCurrentMonthIndex()
    }

    // Get page index for today
    fun getTodayPageIndex(): Int {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        return getPageIndexForMonth(today)
    }

    var viewMode by mutableStateOf(ViewMode.MONTH)
        private set

    var selectedCalendarIds by mutableStateOf(setOf<String>())
        private set

    var isDebugMode by mutableStateOf(false)
        private set

    var shouldScrollToToday by mutableStateOf(false)
        private set

    private var hasPermissions = false
    
    // Track which months have been loaded to avoid redundant loading
    private val loadedMonths = mutableSetOf<LocalDate>()

    // Don't load data in init - wait for permissions
    init {
        _uiState.value = _uiState.value.copy(
            isLoading = false,
            error = null // Start with no error, MainActivity will set appropriate message
        )
    }

    fun onPermissionsGranted() {
        hasPermissions = true
        _uiState.value = _uiState.value.copy(error = null)
        loadAvailableCalendars()
        // loadEvents() will be called automatically after calendars are loaded
    }

    fun onPermissionsDenied() {
        hasPermissions = false
        _uiState.value = _uiState.value.copy(
            isLoading = false,
            error = "Calendar permissions are required to access your calendar events"
        )
    }

    fun selectDate(date: LocalDate) {
        selectedDate = date
        _uiState.value = _uiState.value.copy(selectedDate = date)
    }

    fun navigateToMonth(month: LocalDate) {
        currentMonth = month
        _uiState.value = _uiState.value.copy(currentMonth = month)

        // Smart date selection: Choose today if in this month, otherwise first day
        updateSelectedDateForMonth(month)

        // Don't call loadEvents() here to avoid refresh during pager settling
    }
    
    // Check if we should load events for a month (smart caching)
    fun shouldLoadEventsForMonth(month: LocalDate): Boolean {
        val previousMonth = month.minus(1, DateTimeUnit.MONTH)
        val nextMonth = month.plus(1, DateTimeUnit.MONTH)
        
        val shouldLoad = !loadedMonths.contains(previousMonth) || 
                        !loadedMonths.contains(month) || 
                        !loadedMonths.contains(nextMonth)
        
        android.util.Log.d("PerformanceDebug", "shouldLoadEventsForMonth($month): $shouldLoad - loadedMonths: ${loadedMonths.size} months")
        
        return shouldLoad
    }
    
    // Load events for current month and adjacent months (only if needed)
    fun loadEventsForMonthAndAdjacent(month: LocalDate) {
        if (!hasPermissions) return
        
        android.util.Log.d("PerformanceDebug", "loadEventsForMonthAndAdjacent($month) called")
        
        val previousMonth = month.minus(1, DateTimeUnit.MONTH)
        val nextMonth = month.plus(1, DateTimeUnit.MONTH)
        
        var loadCount = 0
        
        // Only load months that haven't been loaded yet
        if (!loadedMonths.contains(previousMonth)) {
            android.util.Log.d("PerformanceDebug", "Loading previousMonth: $previousMonth")
            loadEventsForMonth(previousMonth)
            loadCount++
        }
        if (!loadedMonths.contains(month)) {
            android.util.Log.d("PerformanceDebug", "Loading currentMonth: $month")
            loadEventsForMonth(month)
            loadCount++
        }
        if (!loadedMonths.contains(nextMonth)) {
            android.util.Log.d("PerformanceDebug", "Loading nextMonth: $nextMonth")
            loadEventsForMonth(nextMonth)
            loadCount++
        }
        
        android.util.Log.d("PerformanceDebug", "loadEventsForMonthAndAdjacent completed - loaded $loadCount months")
    }
    
    private fun loadEventsForMonth(month: LocalDate) {
        android.util.Log.d("PerformanceDebug", "loadEventsForMonth($month) - START")
        viewModelScope.launch {
            try {
                // Create simple date range for the month using kotlinx.datetime
                val daysInMonth = when (month.monthNumber) {
                    1, 3, 5, 7, 8, 10, 12 -> 31
                    4, 6, 9, 11 -> 30
                    2 -> if (month.year % 4 == 0 && (month.year % 100 != 0 || month.year % 400 == 0)) 29 else 28
                    else -> 30
                }
                
                val startDate = kotlinx.datetime.LocalDateTime(
                    month.year,
                    month.monthNumber,
                    1,
                    0, 0, 0
                )
                val endDate = kotlinx.datetime.LocalDateTime(
                    month.year,
                    month.monthNumber,
                    daysInMonth,
                    23, 59, 59
                )
                
                val events = calendarRepository.getEvents(
                    startDate = startDate,
                    endDate = endDate,
                    selectedCalendarIds = selectedCalendarIds
                )
                
                // Merge with existing events more efficiently
                val currentEvents = _events.value.toMutableList()
                val existingEventsForMonth = currentEvents.filter { event ->
                    val eventMonth = event.startTime.date
                    eventMonth.year == month.year && eventMonth.monthNumber == month.monthNumber
                }
                
                // Remove old events for this month and add new ones
                currentEvents.removeAll(existingEventsForMonth)
                currentEvents.addAll(events)
                
                _events.value = currentEvents
                
                // Update eventsByDate more efficiently - only redistribute new events for this month
                val currentEventsByDate = _eventsByDate.value.toMutableMap()
                
                // Remove existing events for this month from eventsByDate
                val monthStart = kotlinx.datetime.LocalDate(month.year, month.monthNumber, 1)
                val monthEnd = kotlinx.datetime.LocalDate(month.year, month.monthNumber, daysInMonth)
                
                // Clear events for this month's date range
                var currentDate = monthStart
                while (currentDate <= monthEnd) {
                    currentEventsByDate[currentDate] = currentEventsByDate[currentDate]?.filter { event ->
                        val eventMonth = event.startTime.date
                        !(eventMonth.year == month.year && eventMonth.monthNumber == month.monthNumber)
                    }?.takeIf { it.isNotEmpty() } ?: emptyList()
                    currentDate = currentDate.plus(1, DateTimeUnit.DAY)
                }
                
                // Add new events for this month only
                events.forEach { event ->
                    var eventDate = event.startTime.date
                    val eventEndDate = event.endTime.date

                    while (eventDate <= eventEndDate) {
                        if (currentEventsByDate[eventDate] == null) {
                            currentEventsByDate[eventDate] = mutableListOf()
                        }
                        currentEventsByDate[eventDate] = (currentEventsByDate[eventDate]!! + event)
                        eventDate = eventDate.plus(1, DateTimeUnit.DAY)
                    }
                }
                
                _eventsByDate.value = currentEventsByDate
                
                // Mark this month as loaded
                loadedMonths.add(month)
                
                android.util.Log.d("PerformanceDebug", "loadEventsForMonth($month) - COMPLETED - loaded ${events.size} events")
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = null
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to load events: ${e.message}"
                )
            }
        }
    }

    fun goToToday() {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        selectedDate = today
        currentMonth = today
        _uiState.value = _uiState.value.copy(
            selectedDate = today,
            currentMonth = today
        )

        // Trigger scroll to today in MonthView
        shouldScrollToToday = true
        // Reset the trigger after a short delay
        viewModelScope.launch {
            kotlinx.coroutines.delay(100)
            shouldScrollToToday = false
        }

        if (hasPermissions) {
            loadEvents()
        }
    }

    // Smart date selection: Choose today if in this month, otherwise first day
    fun updateSelectedDateForMonth(month: LocalDate) {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date

        // Check if today is in this month
        if (today.year == month.year && today.monthNumber == month.monthNumber) {
            // Today is in this month, select today
            selectedDate = today
        } else {
            // Today is not in this month, select first day
            selectedDate = LocalDate(month.year, month.monthNumber, 1)
        }

        _uiState.value = _uiState.value.copy(selectedDate = selectedDate)
    }

    fun toggleViewMode() {
        viewMode = when (viewMode) {
            ViewMode.MONTH -> ViewMode.WEEK
            ViewMode.WEEK -> ViewMode.DAY
            ViewMode.DAY -> ViewMode.MONTH
        }
        _uiState.value = _uiState.value.copy(viewMode = viewMode)
    }

    fun updateSelectedCalendars(calendarIds: Set<String>) {
        selectedCalendarIds = calendarIds
        _uiState.value = _uiState.value.copy(selectedCalendarIds = calendarIds)
        if (hasPermissions) {
            // Clear cache to force reload with new calendar selection
            loadedMonths.clear()
            loadEvents()
        }
    }

    fun refreshEvents() {
        if (hasPermissions) {
            loadEvents()
        }
    }

    private fun loadAvailableCalendars() {
        if (!hasPermissions) return
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val calendars = calendarRepository.getAvailableCalendars()
                _availableCalendars.value = calendars
                
                // Auto-select all calendars initially
                if (selectedCalendarIds.isEmpty()) {
                    val allIds = calendars.map { it.id }.toSet()
                    selectedCalendarIds = allIds
                    _uiState.value = _uiState.value.copy(selectedCalendarIds = allIds)
                }
                
                // Load events now that calendars are available and selected
                loadEvents()
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.message)
            } finally {
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }

    private fun loadEvents() {
        if (!hasPermissions) return
        
        // Use smart caching approach instead of loading expanded range
        android.util.Log.d("PerformanceDebug", "loadEvents() called - using smart caching approach")
        loadEventsForMonthAndAdjacent(currentMonth)
    }

    private fun distributeEventsAcrossDays(events: List<Event>): Map<LocalDate, List<Event>> {
        val eventsByDate = mutableMapOf<LocalDate, MutableList<Event>>()
        
        android.util.Log.d("CalendarViewModel", "Distributing ${events.size} events")
        
        events.forEach { event ->
            var currentDate = event.startTime.date
            val endDate = event.endTime.date
            
            android.util.Log.d("CalendarViewModel", "Event '${event.name}': ${event.startTime.date} to ${event.endTime.date} (isAllDay=${event.isAllDay}, isMultiDay=${event.isMultiDay})")
            
            // Add event to all days it spans (like iOS does)
            while (currentDate <= endDate) {
                if (eventsByDate[currentDate] == null) {
                    eventsByDate[currentDate] = mutableListOf()
                }
                eventsByDate[currentDate]?.add(event)
                android.util.Log.d("CalendarViewModel", "  -> Added to $currentDate")
                
                // Move to next day
                currentDate = currentDate.plus(1, DateTimeUnit.DAY)
            }
        }
        
        android.util.Log.d("CalendarViewModel", "Final eventsByDate has ${eventsByDate.size} dates with events")
        
        return eventsByDate
    }

    fun getEventsForDate(date: LocalDate): List<Event> {
        val events = _eventsByDate.value[date] ?: emptyList()
        // Deduplicate events by ID to prevent multi-day events from appearing multiple times
        return events.distinctBy { it.id }.sortedBy { it.startTime }
    }

    fun getMonthName(): String {
        return when (currentMonth.monthNumber) {
            1 -> "JAN"
            2 -> "FEB"
            3 -> "MAR"
            4 -> "APR"
            5 -> "MAY"
            6 -> "JUN"
            7 -> "JUL"
            8 -> "AUG"
            9 -> "SEP"
            10 -> "OCT"
            11 -> "NOV"
            12 -> "DEC"
            else -> "JAN"
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    fun toggleDebugMode() {
        isDebugMode = !isDebugMode
    }

    fun shouldHighlightDate(date: LocalDate): Boolean {
        val dayOfWeek = date.dayOfWeek.value // Monday = 1, Sunday = 7

        // Check for Sunday (dayOfWeek = 7)
        if (dayOfWeek == 7 && WeekSettings.getHighlightSundays(context)) {
            return true
        }

        // Check for Saturday (dayOfWeek = 6)
        if (dayOfWeek == 6 && WeekSettings.getHighlightSaturdays(context)) {
            return true
        }

        // Check for holidays
        if (WeekSettings.getHighlightHolidays(context) && holidayManager.isHoliday(date)) {
            return true
        }

        return false
    }

    fun loadSearchEvents() {
        android.util.Log.d("CalendarViewModel", "loadSearchEvents called - hasPermissions: $hasPermissions")
        if (!hasPermissions) {
            android.util.Log.w("CalendarViewModel", "loadSearchEvents: No permissions, returning")
            return
        }

        android.util.Log.d("CalendarViewModel", "loadSearchEvents: selectedCalendarIds: $selectedCalendarIds (${selectedCalendarIds.size} calendars)")

        viewModelScope.launch {
            try {
                val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date

                // Create +/- 2 years date range for search
                val startDate = kotlinx.datetime.LocalDateTime(
                    today.year - 2,
                    today.monthNumber,
                    today.dayOfMonth,
                    0, 0, 0
                )
                val endDate = kotlinx.datetime.LocalDateTime(
                    today.year + 2,
                    today.monthNumber,
                    today.dayOfMonth,
                    23, 59, 59
                )

                android.util.Log.d("CalendarViewModel", "loadSearchEvents: Querying events from $startDate to $endDate")

                val events = calendarRepository.getEvents(
                    startDate = startDate,
                    endDate = endDate,
                    selectedCalendarIds = selectedCalendarIds
                )

                android.util.Log.d("CalendarViewModel", "loadSearchEvents: Fetched ${events.size} events")
                events.take(5).forEach { event ->
                    android.util.Log.d("CalendarViewModel", "  Sample event: '${event.name}' at ${event.startTime}")
                }

                _searchEvents.value = events.sortedByDescending { it.startTime }
                android.util.Log.d("CalendarViewModel", "loadSearchEvents: Set searchEvents to ${_searchEvents.value.size} events")

            } catch (e: Exception) {
                android.util.Log.e("CalendarViewModel", "Failed to load search events: ${e.message}")
                e.printStackTrace()
                // Keep existing search events on error
            }
        }
    }
}

data class CalendarUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedDate: LocalDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date,
    val currentMonth: LocalDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date,
    val viewMode: ViewMode = ViewMode.MONTH,
    val selectedCalendarIds: Set<String> = emptySet()
)