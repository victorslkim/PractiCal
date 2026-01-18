package com.practical.calendar.ui.viewmodel

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.practical.calendar.data.WeekSettings
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

    // Appearance settings
    var highlightSundays by mutableStateOf(WeekSettings.getHighlightSundays(context))
        private set

    var highlightSaturdays by mutableStateOf(WeekSettings.getHighlightSaturdays(context))
        private set

    var highlightHolidays by mutableStateOf(WeekSettings.getHighlightHolidays(context))
        private set

    // Active sub-sheet navigation
    var activeSheet by mutableStateOf<SettingsSheet?>(null)
        private set

    fun navigateToSheet(sheet: SettingsSheet?) {
        activeSheet = sheet
    }

    fun updateHighlightSundays(value: Boolean) {
        highlightSundays = value
        WeekSettings.setHighlightSundays(context, value)
    }

    fun updateHighlightSaturdays(value: Boolean) {
        highlightSaturdays = value
        WeekSettings.setHighlightSaturdays(context, value)
    }

    fun updateHighlightHolidays(value: Boolean) {
        highlightHolidays = value
        WeekSettings.setHighlightHolidays(context, value)
    }
}

enum class SettingsSheet {
    Appearance,
    EditEvent,
    Notification,
    Help
}
