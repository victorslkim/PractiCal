package com.practical.calendar.ui.viewmodel

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.practical.calendar.data.model.Event
import com.practical.calendar.data.repository.CalendarRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import javax.inject.Inject

@HiltViewModel
class EventEditorViewModel @Inject constructor(
    private val calendarRepository: CalendarRepository
) : ViewModel() {

    private val _isSaving = MutableStateFlow(false)
    val isSaving: StateFlow<Boolean> = _isSaving.asStateFlow()

    private val _saveSuccess = MutableStateFlow<Boolean?>(null)
    val saveSuccess: StateFlow<Boolean?> = _saveSuccess.asStateFlow()

    // Form state
    var title by mutableStateOf("")
        private set

    var location by mutableStateOf("")
        private set

    var description by mutableStateOf("")
        private set

    var isAllDay by mutableStateOf(false)
        private set

    var startDate by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set

    var startTime by mutableStateOf(LocalTime(9, 0))
        private set

    var endDate by mutableStateOf(Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date)
        private set

    var endTime by mutableStateOf(LocalTime(10, 0))
        private set

    var selectedCalendarId by mutableStateOf<String?>(null)
        private set

    var url by mutableStateOf("")
        private set

    private var existingEventId: String? = null

    fun initWithEvent(event: Event?) {
        if (event != null) {
            existingEventId = event.id
            title = event.name
            location = event.location
            description = event.description
            isAllDay = event.isAllDay
            startDate = event.startTime.date
            startTime = LocalTime(event.startTime.hour, event.startTime.minute)
            endDate = event.endTime.date
            endTime = LocalTime(event.endTime.hour, event.endTime.minute)
            selectedCalendarId = event.calendarId
        } else {
            resetForm()
        }
    }

    fun initWithDate(date: LocalDate) {
        startDate = date
        endDate = date
    }

    private fun resetForm() {
        existingEventId = null
        title = ""
        location = ""
        description = ""
        isAllDay = false
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        startDate = now.date
        startTime = LocalTime(9, 0)
        endDate = now.date
        endTime = LocalTime(10, 0)
        selectedCalendarId = null
        url = ""
        _saveSuccess.value = null
    }

    fun updateTitle(value: String) { title = value }
    fun updateLocation(value: String) { location = value }
    fun updateDescription(value: String) { description = value }
    fun updateIsAllDay(value: Boolean) { isAllDay = value }
    fun updateStartDate(value: LocalDate) { startDate = value }
    fun updateStartTime(value: LocalTime) { startTime = value }
    fun updateEndDate(value: LocalDate) { endDate = value }
    fun updateEndTime(value: LocalTime) { endTime = value }
    fun updateSelectedCalendarId(value: String?) { selectedCalendarId = value }
    fun updateUrl(value: String) { url = value }

    fun saveEvent() {
        if (title.isBlank()) {
            Log.w("EventEditorVM", "Cannot save event without title")
            return
        }

        viewModelScope.launch {
            _isSaving.value = true
            try {
                val startDateTime = LocalDateTime(
                    startDate.year,
                    startDate.monthNumber,
                    startDate.dayOfMonth,
                    if (isAllDay) 0 else startTime.hour,
                    if (isAllDay) 0 else startTime.minute
                )
                val endDateTime = LocalDateTime(
                    endDate.year,
                    endDate.monthNumber,
                    endDate.dayOfMonth,
                    if (isAllDay) 23 else endTime.hour,
                    if (isAllDay) 59 else endTime.minute
                )

                // TODO: Implement calendarRepository.saveEvent() / updateEvent()
                Log.d("EventEditorVM", "Would save event: $title from $startDateTime to $endDateTime")

                _saveSuccess.value = true
            } catch (e: Exception) {
                Log.e("EventEditorVM", "Failed to save event: ${e.message}")
                _saveSuccess.value = false
            } finally {
                _isSaving.value = false
            }
        }
    }

    fun deleteEvent() {
        val eventId = existingEventId ?: return

        viewModelScope.launch {
            _isSaving.value = true
            try {
                // TODO: Implement calendarRepository.deleteEvent()
                Log.d("EventEditorVM", "Would delete event: $eventId")

                _saveSuccess.value = true
            } catch (e: Exception) {
                Log.e("EventEditorVM", "Failed to delete event: ${e.message}")
                _saveSuccess.value = false
            } finally {
                _isSaving.value = false
            }
        }
    }

    fun isEditing(): Boolean = existingEventId != null
}
