package com.practical.calendar.ui.viewmodel

import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.practical.calendar.data.model.Event
import com.practical.calendar.data.model.ViewMode
import com.practical.calendar.data.repository.CalendarPreferencesRepository
import com.practical.calendar.data.repository.CalendarRepository
import com.practical.calendar.data.WeekSettings
import com.practical.calendar.data.HolidayManager
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.LocalDate
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.plus
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val calendarRepository: CalendarRepository,
    private val calendarPreferencesRepository: CalendarPreferencesRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val holidayManager = HolidayManager()

    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    private val _events = MutableStateFlow<List<Event>>(emptyList())
    val events: StateFlow<List<Event>> = _events.asStateFlow()

    private val _eventsByDate = MutableStateFlow<Map<LocalDate, List<Event>>>(emptyMap())
    val eventsByDate: StateFlow<Map<LocalDate, List<Event>>> = _eventsByDate.asStateFlow()

    var selectedDate by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set

    var currentMonth by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set

    val monthRange: List<LocalDate> by lazy {
        val startMonth = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date.minus(100, DateTimeUnit.MONTH)
        (0..199).map { offset ->
            startMonth.plus(offset, DateTimeUnit.MONTH)
        }
    }

    var viewMode by mutableStateOf(ViewMode.MONTH)
        private set

    var isDebugMode by mutableStateOf(false)
        private set

    var shouldScrollToToday by mutableStateOf(false)
        private set

    private var hasPermissions = false
    private val loadedMonths = mutableSetOf<LocalDate>()

    init {
        _uiState.value = _uiState.value.copy(isLoading = false, error = null)

        // Observe selectedCalendarIds changes and reload events
        viewModelScope.launch {
            calendarPreferencesRepository.selectedCalendarIds.collectLatest { ids ->
                if (hasPermissions && ids.isNotEmpty()) {
                    loadedMonths.clear()
                    loadEvents()
                }
            }
        }
    }

    fun onPermissionsGranted() {
        hasPermissions = true
        _uiState.value = _uiState.value.copy(error = null)
        loadEvents()
    }

    fun onPermissionsDenied() {
        hasPermissions = false
        _uiState.value = _uiState.value.copy(
            isLoading = false,
            error = "Calendar permissions are required to access your calendar events"
        )
    }

    fun getCurrentMonthIndex(): Int {
        return monthRange.indexOfFirst { it == currentMonth }.takeIf { it >= 0 } ?: 100
    }

    fun getMonthForPage(pageIndex: Int): LocalDate {
        return monthRange.getOrNull(pageIndex) ?: currentMonth
    }

    fun getTodayPageIndex(): Int {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        return monthRange.indexOfFirst {
            it.year == today.year && it.monthNumber == today.monthNumber
        }.takeIf { it >= 0 } ?: getCurrentMonthIndex()
    }

    fun selectDate(date: LocalDate) {
        selectedDate = date
    }

    fun navigateToMonth(month: LocalDate) {
        currentMonth = month
        updateSelectedDateForMonth(month)
    }

    private fun updateSelectedDateForMonth(month: LocalDate) {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        selectedDate = if (today.year == month.year && today.monthNumber == month.monthNumber) {
            today
        } else {
            LocalDate(month.year, month.monthNumber, 1)
        }
    }

    fun shouldLoadEventsForMonth(month: LocalDate): Boolean {
        val previousMonth = month.minus(1, DateTimeUnit.MONTH)
        val nextMonth = month.plus(1, DateTimeUnit.MONTH)
        return !loadedMonths.contains(previousMonth) ||
               !loadedMonths.contains(month) ||
               !loadedMonths.contains(nextMonth)
    }

    fun loadEventsForMonthAndAdjacent(month: LocalDate) {
        if (!hasPermissions) return

        val previousMonth = month.minus(1, DateTimeUnit.MONTH)
        val nextMonth = month.plus(1, DateTimeUnit.MONTH)

        if (!loadedMonths.contains(previousMonth)) loadEventsForMonth(previousMonth)
        if (!loadedMonths.contains(month)) loadEventsForMonth(month)
        if (!loadedMonths.contains(nextMonth)) loadEventsForMonth(nextMonth)
    }

    private fun loadEventsForMonth(month: LocalDate) {
        viewModelScope.launch {
            try {
                val daysInMonth = when (month.monthNumber) {
                    1, 3, 5, 7, 8, 10, 12 -> 31
                    4, 6, 9, 11 -> 30
                    2 -> if (month.year % 4 == 0 && (month.year % 100 != 0 || month.year % 400 == 0)) 29 else 28
                    else -> 30
                }

                val startDate = LocalDateTime(month.year, month.monthNumber, 1, 0, 0, 0)
                val endDate = LocalDateTime(month.year, month.monthNumber, daysInMonth, 23, 59, 59)

                val selectedIds = calendarPreferencesRepository.selectedCalendarIds.value
                val events = calendarRepository.getEvents(
                    startDate = startDate,
                    endDate = endDate,
                    selectedCalendarIds = selectedIds
                )

                // Merge with existing events
                val currentEvents = _events.value.toMutableList()
                val existingEventsForMonth = currentEvents.filter { event ->
                    val eventMonth = event.startTime.date
                    eventMonth.year == month.year && eventMonth.monthNumber == month.monthNumber
                }
                currentEvents.removeAll(existingEventsForMonth)
                currentEvents.addAll(events)
                _events.value = currentEvents

                // Update eventsByDate
                val currentEventsByDate = _eventsByDate.value.toMutableMap()
                val monthStart = LocalDate(month.year, month.monthNumber, 1)
                val monthEnd = LocalDate(month.year, month.monthNumber, daysInMonth)

                var currentDate = monthStart
                while (currentDate <= monthEnd) {
                    currentEventsByDate[currentDate] = currentEventsByDate[currentDate]?.filter { event ->
                        val eventMonth = event.startTime.date
                        !(eventMonth.year == month.year && eventMonth.monthNumber == month.monthNumber)
                    }?.takeIf { it.isNotEmpty() } ?: emptyList()
                    currentDate = currentDate.plus(1, DateTimeUnit.DAY)
                }

                events.forEach { event ->
                    var eventDate = event.startTime.date
                    val eventEndDate = event.endTime.date
                    while (eventDate <= eventEndDate) {
                        currentEventsByDate[eventDate] = (currentEventsByDate[eventDate] ?: emptyList()) + event
                        eventDate = eventDate.plus(1, DateTimeUnit.DAY)
                    }
                }

                _eventsByDate.value = currentEventsByDate
                loadedMonths.add(month)

                _uiState.value = _uiState.value.copy(isLoading = false, error = null)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = "Failed to load events: ${e.message}")
            }
        }
    }

    private fun loadEvents() {
        if (!hasPermissions) return
        loadEventsForMonthAndAdjacent(currentMonth)
    }

    fun goToToday() {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        selectedDate = today
        currentMonth = today

        shouldScrollToToday = true
        viewModelScope.launch {
            delay(100)
            shouldScrollToToday = false
        }

        if (hasPermissions) {
            loadEvents()
        }
    }

    fun toggleViewMode() {
        viewMode = when (viewMode) {
            ViewMode.MONTH -> ViewMode.WEEK
            ViewMode.WEEK -> ViewMode.DAY
            ViewMode.DAY -> ViewMode.MONTH
        }
    }

    fun toggleDebugMode() {
        isDebugMode = !isDebugMode
    }

    fun getEventsForDate(date: LocalDate): List<Event> {
        val events = _eventsByDate.value[date] ?: emptyList()
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

    fun shouldHighlightDate(date: LocalDate): Boolean {
        val dayOfWeek = date.dayOfWeek.value
        if (dayOfWeek == 7 && WeekSettings.getHighlightSundays(context)) return true
        if (dayOfWeek == 6 && WeekSettings.getHighlightSaturdays(context)) return true
        if (WeekSettings.getHighlightHolidays(context) && holidayManager.isHoliday(date)) return true
        return false
    }
}

data class MainUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)
