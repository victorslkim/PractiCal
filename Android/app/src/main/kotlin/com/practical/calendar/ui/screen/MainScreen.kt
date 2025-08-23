package com.practical.calendar.ui.screen

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.practical.calendar.data.model.ViewMode
import com.practical.calendar.ui.components.HeaderView
import com.practical.calendar.ui.components.MonthView
import com.practical.calendar.ui.components.WeekView
import com.practical.calendar.ui.components.DayView
import com.practical.calendar.ui.components.EventListView
import com.practical.calendar.ui.components.SearchBottomSheet
import com.practical.calendar.ui.components.SettingsBottomSheet
import com.practical.calendar.ui.components.CalendarSelectionBottomSheet
import com.practical.calendar.ui.components.EventEditorBottomSheet
import com.practical.calendar.ui.viewmodel.CalendarViewModel
import com.practical.calendar.data.model.Event
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val events by viewModel.events.collectAsStateWithLifecycle()
    val eventsByDate by viewModel.eventsByDate.collectAsStateWithLifecycle()
    val availableCalendars by viewModel.availableCalendars.collectAsStateWithLifecycle()
    val searchEvents by viewModel.searchEvents.collectAsStateWithLifecycle()
    
    var showSearch by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }
    var showCalendarSelection by remember { mutableStateOf(false) }
    var showEventEditor by remember { mutableStateOf(false) }
    var selectedEventForEditing by remember { mutableStateOf<Event?>(null) }

    val today = remember { 
        Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date 
    }

    Box(modifier = Modifier.fillMaxSize()) {
        val scrollState = rememberScrollState()
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
        ) {
            // Header
            HeaderView(
                monthName = viewModel.getMonthName(),
                onTodayTapped = { viewModel.goToToday() },
                onSearchTapped = {
                    android.util.Log.d("MainScreen", "Search tapped - loading search events")
                    viewModel.loadSearchEvents()
                    showSearch = true
                },
                onSettingsTapped = { showSettings = true },
                onCalendarSelectionTapped = { showCalendarSelection = true },
                onMonthTapped = { viewModel.toggleDebugMode() },
                viewMode = viewModel.viewMode
            )

            // Loading indicator
            if (uiState.isLoading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth()
                )
            }

            // Error message for permission issues
            uiState.error?.let { errorMessage ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = errorMessage,
                            color = Color.White,
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center
                        )
                        if (errorMessage.contains("permissions", ignoreCase = true)) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Please grant calendar permissions in Settings to view your events",
                                color = Color.Gray,
                                style = MaterialTheme.typography.bodyMedium,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }

            // Main content - only show if no error
            if (uiState.error == null) {
                when (viewModel.viewMode) {
                    ViewMode.MONTH -> {
                        MonthView(
                            currentMonth = viewModel.currentMonth,
                            selectedDate = viewModel.selectedDate,
                            eventsByDate = eventsByDate,
                            today = today,
                            isDebugMode = viewModel.isDebugMode,
                            onDateSelected = { viewModel.selectDate(it) },
                            onMonthChanged = { viewModel.navigateToMonth(it) },
                            onLoadEventsForMonth = { viewModel.loadEventsForMonthAndAdjacent(it) },
                            shouldLoadEventsForMonth = { viewModel.shouldLoadEventsForMonth(it) },
                            getMonthForPage = { viewModel.getMonthForPage(it) },
                            getCurrentMonthIndex = { viewModel.getCurrentMonthIndex() },
                            getTodayPageIndex = { viewModel.getTodayPageIndex() },
                            monthRangeSize = viewModel.monthRange.size,
                            scrollToToday = viewModel.shouldScrollToToday,
                            shouldHighlightDate = { viewModel.shouldHighlightDate(it) }
                        )
                    }
                    ViewMode.WEEK -> {
                        WeekView(
                            selectedDate = viewModel.selectedDate,
                            events = events,
                            onDateSelected = { viewModel.selectDate(it) },
                            onEventTapped = { /* Handle event tap */ }
                        )
                    }
                    ViewMode.DAY -> {
                        DayView(
                            selectedDate = viewModel.selectedDate,
                            events = events,
                            onEventTapped = { /* Handle event tap */ }
                        )
                    }
                }

                // Event List
                EventListView(
                    selectedDate = viewModel.selectedDate,
                    events = viewModel.getEventsForDate(viewModel.selectedDate),
                    onEventTapped = { event ->
                        selectedEventForEditing = event
                        showEventEditor = true
                    }
                )
            }
        }

        // Floating Action Button
        FloatingActionButton(
            onClick = { showEventEditor = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Add,
                contentDescription = "Add Event"
            )
        }
    }

    // Bottom sheets and dialogs
    if (showSearch) {
        android.util.Log.d("MainScreen", "Showing SearchBottomSheet with ${searchEvents.size} events")
        SearchBottomSheet(
            events = searchEvents,
            onEventSelected = { event ->
                // Navigate to the event's date and open event editor
                viewModel.selectDate(event.startTime.date)
                selectedEventForEditing = event
                showEventEditor = true
                showSearch = false
            },
            onDismiss = { showSearch = false }
        )
    }

    if (showSettings) {
        SettingsBottomSheet(
            onDismiss = { showSettings = false }
        )
    }

    if (showCalendarSelection) {
        CalendarSelectionBottomSheet(
            calendars = availableCalendars,
            selectedCalendarIds = viewModel.selectedCalendarIds,
            onSelectionChanged = { viewModel.updateSelectedCalendars(it) },
            onDismiss = { showCalendarSelection = false }
        )
    }

    if (showEventEditor) {
        EventEditorBottomSheet(
            existingEvent = selectedEventForEditing,
            onDismiss = {
                showEventEditor = false
                selectedEventForEditing = null
            }
        )
    }

    // Error handling
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Show error snackbar or dialog
            viewModel.clearError()
        }
    }
}