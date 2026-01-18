package com.practical.calendar.ui.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.practical.calendar.data.repository.CalendarInfo
import com.practical.calendar.data.repository.CalendarPreferencesRepository
import com.practical.calendar.data.repository.CalendarRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CalendarSelectionViewModel @Inject constructor(
    private val calendarRepository: CalendarRepository,
    private val calendarPreferencesRepository: CalendarPreferencesRepository
) : ViewModel() {

    private val _availableCalendars = MutableStateFlow<List<CalendarInfo>>(emptyList())
    val availableCalendars: StateFlow<List<CalendarInfo>> = _availableCalendars.asStateFlow()

    val selectedCalendarIds: StateFlow<Set<String>> = calendarPreferencesRepository.selectedCalendarIds

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun loadAvailableCalendars() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val calendars = calendarRepository.getAvailableCalendars()
                _availableCalendars.value = calendars
                Log.d("CalendarSelectionVM", "Loaded ${calendars.size} calendars")

                // Auto-select all calendars if none were previously selected
                if (selectedCalendarIds.value.isEmpty()) {
                    val allIds = calendars.map { it.id }.toSet()
                    calendarPreferencesRepository.initializeWithAllCalendars(allIds)
                }
            } catch (e: Exception) {
                Log.e("CalendarSelectionVM", "Failed to load calendars: ${e.message}")
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun updateSelectedCalendars(calendarIds: Set<String>) {
        calendarPreferencesRepository.updateSelectedCalendars(calendarIds)
    }
}
