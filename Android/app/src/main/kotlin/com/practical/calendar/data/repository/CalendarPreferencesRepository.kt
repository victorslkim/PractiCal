package com.practical.calendar.data.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for calendar-related user preferences.
 * This is a singleton shared across ViewModels that need access to calendar selection state.
 */
@Singleton
class CalendarPreferencesRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs by lazy {
        context.getSharedPreferences("calendar_preferences", Context.MODE_PRIVATE)
    }

    private val _selectedCalendarIds = MutableStateFlow<Set<String>>(loadSavedSelection())
    val selectedCalendarIds: StateFlow<Set<String>> = _selectedCalendarIds.asStateFlow()

    private fun loadSavedSelection(): Set<String> {
        return prefs.getStringSet("selected_calendar_ids", emptySet()) ?: emptySet()
    }

    private fun saveSelection(ids: Set<String>) {
        prefs.edit()
            .putStringSet("selected_calendar_ids", ids)
            .apply()
    }

    fun updateSelectedCalendars(calendarIds: Set<String>) {
        _selectedCalendarIds.value = calendarIds
        saveSelection(calendarIds)
    }

    fun initializeWithAllCalendars(calendarIds: Set<String>) {
        if (_selectedCalendarIds.value.isEmpty()) {
            updateSelectedCalendars(calendarIds)
        }
    }
}
