package com.practical.calendar.ui.viewmodel

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.practical.calendar.data.model.Event
import com.practical.calendar.data.repository.CalendarPreferencesRepository
import com.practical.calendar.data.repository.CalendarRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val calendarRepository: CalendarRepository,
    private val calendarPreferencesRepository: CalendarPreferencesRepository
) : ViewModel() {

    private val _searchEvents = MutableStateFlow<List<Event>>(emptyList())
    val searchEvents: StateFlow<List<Event>> = _searchEvents.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    var searchQuery by mutableStateOf("")
        private set

    var submittedQuery by mutableStateOf("")
        private set

    fun updateSearchQuery(query: String) {
        searchQuery = query
    }

    fun submitSearch() {
        submittedQuery = searchQuery
    }

    fun clearSearch() {
        searchQuery = ""
        submittedQuery = ""
    }

    fun loadSearchEvents() {
        val selectedCalendarIds = calendarPreferencesRepository.selectedCalendarIds.value
        Log.d("SearchViewModel", "loadSearchEvents called with ${selectedCalendarIds.size} calendars")

        if (selectedCalendarIds.isEmpty()) {
            Log.w("SearchViewModel", "No calendars selected, returning")
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            try {
                val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date

                val startDate = LocalDateTime(
                    today.year - 2,
                    today.monthNumber,
                    today.dayOfMonth,
                    0, 0, 0
                )
                val endDate = LocalDateTime(
                    today.year + 2,
                    today.monthNumber,
                    today.dayOfMonth,
                    23, 59, 59
                )

                Log.d("SearchViewModel", "Querying events from $startDate to $endDate")

                val events = calendarRepository.getEvents(
                    startDate = startDate,
                    endDate = endDate,
                    selectedCalendarIds = selectedCalendarIds
                )

                Log.d("SearchViewModel", "Fetched ${events.size} events")

                _searchEvents.value = events.sortedByDescending { it.startTime }

            } catch (e: Exception) {
                Log.e("SearchViewModel", "Failed to load search events: ${e.message}")
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun getFilteredEvents(): List<Event> {
        if (submittedQuery.isBlank()) {
            return emptyList()
        }
        return _searchEvents.value.filter { event ->
            event.name.contains(submittedQuery, ignoreCase = true) ||
            event.description.contains(submittedQuery, ignoreCase = true) ||
            event.location.contains(submittedQuery, ignoreCase = true)
        }.distinctBy { event ->
            "${event.id}|${event.startTime}"
        }.sortedByDescending { event ->
            event.startTime
        }
    }
}
