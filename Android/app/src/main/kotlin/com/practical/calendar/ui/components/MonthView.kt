package com.practical.calendar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import kotlinx.coroutines.launch
import androidx.compose.ui.text.font.FontWeight
import android.util.Log
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.practical.calendar.data.model.Event
import kotlinx.datetime.LocalDate
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.plus
import kotlinx.datetime.minus
import androidx.compose.foundation.ExperimentalFoundationApi

// Constants matching iOS implementation
private const val CHIP_ROW_MAX = 4 // Maximum number of event rows per week
private const val DAYS_PER_WEEK = 7 // Number of days in a week
private const val CHIP_HEIGHT_DP = 16 // Height of each event chip in dp
private const val DATE_ROW_HEIGHT_DP = 24 // Height of date numbers row in dp

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MonthView(
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    eventsByDate: Map<LocalDate, List<Event>>,
    today: LocalDate,
    isDebugMode: Boolean = false,
    onDateSelected: (LocalDate) -> Unit,
    onMonthChanged: (LocalDate) -> Unit,
    onLoadEventsForMonth: (LocalDate) -> Unit, // New callback for loading events
    shouldLoadEventsForMonth: (LocalDate) -> Boolean, // Check if loading is needed
    getMonthForPage: (Int) -> LocalDate, // Get month from ViewModel
    getCurrentMonthIndex: () -> Int, // Get current month index from ViewModel
    getTodayPageIndex: () -> Int, // Get today's page index from ViewModel
    monthRangeSize: Int, // Size of month range from ViewModel
    scrollToToday: Boolean = false, // Trigger to scroll to today
    shouldHighlightDate: (LocalDate) -> Boolean, // Callback for date highlighting
    modifier: Modifier = Modifier
) {
    android.util.Log.d("PerformanceDebug", "MonthView recomposed - currentMonth: $currentMonth, eventsByDate size: ${eventsByDate.size}")
    
    val coroutineScope = rememberCoroutineScope()
    
    // Pager state that starts at current month
    val pagerState = rememberPagerState(
        initialPage = getCurrentMonthIndex(),
        pageCount = { monthRangeSize }
    )
    
    // Monitor page changes and call onMonthChanged when user settles on a new month
    LaunchedEffect(pagerState.settledPage) {
        val settledMonth = getMonthForPage(pagerState.settledPage)
        android.util.Log.d("PerformanceDebug", "Pager settled on page ${pagerState.settledPage} -> month: $settledMonth")
        if (settledMonth != currentMonth) {
            android.util.Log.d("PerformanceDebug", "Month changed from $currentMonth to $settledMonth")
            onMonthChanged(settledMonth)
        }
    }
    
    // Load events for adjacent months when page settles (not during scroll)
    LaunchedEffect(pagerState.settledPage) {
        val settledMonth = getMonthForPage(pagerState.settledPage)
        
        android.util.Log.d("PerformanceDebug", "Checking if events need loading for settled month: $settledMonth")
        
        // Only load if we haven't already loaded this month and its neighbors
        if (shouldLoadEventsForMonth(settledMonth)) {
            android.util.Log.d("PerformanceDebug", "Loading events for settled month: $settledMonth")
            onLoadEventsForMonth(settledMonth)
        } else {
            android.util.Log.d("PerformanceDebug", "Events already loaded for settled month: $settledMonth")
        }
    }

    // Handle scroll to today trigger
    LaunchedEffect(scrollToToday) {
        if (scrollToToday) {
            val todayPageIndex = getTodayPageIndex()
            android.util.Log.d("PerformanceDebug", "Scrolling to today page: $todayPageIndex")
            coroutineScope.launch {
                pagerState.animateScrollToPage(todayPageIndex)
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(Color.Black)
    ) {
        // Days of week header
        DaysOfWeekHeader()

        // HorizontalPager with month range
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxWidth(),
            beyondBoundsPageCount = 1  // Limit to current + 1 page on each side to reduce recompositions
        ) { pageIndex ->
            val month = getMonthForPage(pageIndex)
            android.util.Log.d("PerformanceDebug", "HorizontalPager rendering page $pageIndex -> month: $month")
            MonthContent(
                month = month,
                selectedDate = selectedDate,
                eventsByDate = eventsByDate,
                today = today,
                isDebugMode = isDebugMode,
                shouldHighlightDate = shouldHighlightDate,
                onDateSelected = onDateSelected
            )
        }
    }
}

@Composable
private fun MonthContent(
    month: LocalDate,
    selectedDate: LocalDate,
    eventsByDate: Map<LocalDate, List<Event>>,
    today: LocalDate,
    isDebugMode: Boolean,
    shouldHighlightDate: (LocalDate) -> Boolean,
    onDateSelected: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    android.util.Log.d("PerformanceDebug", "MonthContent recomposed for month: $month, events count: ${eventsByDate.values.flatten().size}")
    val weeks = generateWeeksForMonth(month)
    
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        weeks.forEach { weekDates ->
            WeekRowView(
                weekDates = weekDates,
                currentMonth = month,
                selectedDate = selectedDate,
                eventsByDate = eventsByDate,
                today = today,
                isDebugMode = isDebugMode,
                shouldHighlightDate = shouldHighlightDate,
                onDateSelected = onDateSelected,
                onMonthChanged = { /* No-op in preview */ }
            )
        }
    }
}

@Composable
private fun MultiDayEventsOverlay(
    currentMonth: LocalDate,
    eventsByDate: Map<LocalDate, List<Event>>
) {
    // Generate the same date grid as CalendarGrid
    val year = currentMonth.year
    val month = currentMonth.monthNumber
    
    val firstDayOfMonth = LocalDate(year, month, 1)
    val daysInMonth = when (month) {
        1, 3, 5, 7, 8, 10, 12 -> 31
        4, 6, 9, 11 -> 30
        2 -> if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) 29 else 28
        else -> 30
    }
    
    val firstDayOfWeek = if (firstDayOfMonth.dayOfWeek.value == 7) 0 else firstDayOfMonth.dayOfWeek.value
    val startDayOfMonth = 1 - firstDayOfWeek
    
    val dates = (0 until 42).map { dayOffset ->
        val day = startDayOfMonth + dayOffset
        when {
            day <= 0 -> {
                val prevMonth = if (month == 1) 12 else month - 1
                val prevYear = if (month == 1) year - 1 else year
                val prevMonthDays = when (prevMonth) {
                    1, 3, 5, 7, 8, 10, 12 -> 31
                    4, 6, 9, 11 -> 30
                    2 -> if (prevYear % 4 == 0 && (prevYear % 100 != 0 || prevYear % 400 == 0)) 29 else 28
                    else -> 30
                }
                LocalDate(prevYear, prevMonth, prevMonthDays + day)
            }
            day > daysInMonth -> {
                val nextMonth = if (month == 12) 1 else month + 1
                val nextYear = if (month == 12) year + 1 else year
                LocalDate(nextYear, nextMonth, day - daysInMonth)
            }
            else -> LocalDate(year, month, day)
        }
    }
    
    // Organize into weeks and render multi-day events
    val weeks = dates.chunked(7)
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .padding(top = 30.dp), // Offset to align with calendar cells (below day numbers)
        verticalArrangement = Arrangement.spacedBy(1.dp)
    ) {
        weeks.forEach { weekDates ->
            WeekMultiDayEvents(
                weekDates = weekDates,
                eventsByDate = eventsByDate,
                currentMonth = currentMonth
            )
        }
    }
}

@Composable
private fun WeekMultiDayEvents(
    weekDates: List<LocalDate>,
    eventsByDate: Map<LocalDate, List<Event>>,
    currentMonth: LocalDate
) {
    // Get all events for this week and prioritize them
    val allEvents = weekDates.flatMap { eventsByDate[it] ?: emptyList() }
    
    // Step 1: Get multi-day events (highest priority)
    val multiDayEvents = allEvents.filter { it.isMultiDay }.distinctBy { "${it.id}-${it.startTime}" }
        .sortedBy { it.startTime }
    
    // Step 2: Get all-day single events (medium priority)  
    val allDaySingleEvents = allEvents.filter { !it.isMultiDay && it.isAllDay }.distinctBy { "${it.id}-${it.startTime}" }
        .sortedBy { it.startTime }
    
    // Step 3: Get regular single-day events (lowest priority)
    val singleDayEvents = allEvents.filter { !it.isMultiDay && !it.isAllDay }.distinctBy { "${it.id}-${it.startTime}" }
        .sortedBy { it.startTime }
    
    // Create layout grid for this week with advanced conflict resolution
    val chipRowMax = 4
    val layout = Array(7) { Array<Event?>(chipRowMax) { null } }
    val eventToRowMap = mutableMapOf<Event, Int>()
    
    // Step 1: Advanced multi-day event layout with conflict resolution
    val sortedMultiDayEvents = multiDayEvents.sortedWith(
        compareBy<Event> { it.startTime } // Primary: start time
            .thenByDescending { getEventDurationInDays(it) } // Secondary: prefer longer events
            .thenBy { it.name } // Tertiary: consistent ordering
    )
    
    for (event in sortedMultiDayEvents) {
        val eventRange = getEventRangeInWeek(event, weekDates)
        if (eventRange != null) {
            // Smart row finding: prefer rows that minimize visual conflicts
            val rowScores = (0 until chipRowMax).map { row ->
                var score = 0
                var conflicts = 0

                // Check each day this event would occupy
                for (dayIdx in eventRange.first..eventRange.second) {
                    if (layout[dayIdx][row] != null) {
                        conflicts++
                        score -= 100 // High penalty for conflicts
                    } else {
                        // Prefer rows that align with similar events
                        if (dayIdx > 0 && layout[dayIdx - 1][row]?.isMultiDay == true) {
                            score += 10 // Bonus for visual grouping
                        }
                    }
                }

                if (conflicts == 0) score += 50 // Bonus for no conflicts
                Pair(row, score)
            }.sortedByDescending { it.second }

            // Assign to best available row
            val bestRow = rowScores.firstOrNull { it.second >= 0 }?.first
            if (bestRow != null) {
                eventToRowMap[event] = bestRow
                for (dayIdx in eventRange.first..eventRange.second) {
                    layout[dayIdx][bestRow] = event
                }
            }
        }
    }
    
    // Step 2: Smart all-day single event placement
    val sortedAllDayEvents = allDaySingleEvents.sortedWith(
        compareBy<Event> { it.startTime }
            .thenBy { it.name }
    )
    
    for (event in sortedAllDayEvents) {
        for ((dayIdx, date) in weekDates.withIndex()) {
            if (eventsByDate[date]?.contains(event) == true) {
                // Find best available row for this day
                var bestRow: Int? = null
                var bestScore = Int.MIN_VALUE
                
                for (row in 0 until CHIP_ROW_MAX) {
                    if (layout[dayIdx][row] == null) {
                        var score = 0
                        
                        // Prefer rows after multi-day events but before single events
                        val hasMultiDayAbove = (0 until row).any { layout[dayIdx][it]?.isMultiDay == true }
                        val hasSingleDayBelow = ((row + 1) until chipRowMax).any { 
                            layout[dayIdx][it]?.let { !it.isMultiDay && !it.isAllDay } == true 
                        }
                        
                        if (hasMultiDayAbove) score += 20 // Prefer after multi-day
                        if (hasSingleDayBelow) score += 10 // Prefer before single-day
                        
                        if (score > bestScore) {
                            bestScore = score
                            bestRow = row
                        }
                    }
                }
                
                bestRow?.let { row ->
                    layout[dayIdx][row] = event
                    eventToRowMap[event] = row
                }
                break
            }
        }
    }
    
    // Step 3: Optimized single-day event placement
    val sortedSingleEvents = singleDayEvents.sortedWith(
        compareBy<Event> { it.startTime }
            .thenBy { it.name }
    )
    
    for (event in sortedSingleEvents) {
        for ((dayIdx, date) in weekDates.withIndex()) {
            if (eventsByDate[date]?.contains(event) == true) {
                // Find best available row (prefer bottom rows for single events)
                for (row in (chipRowMax - 1) downTo 0) {
                    if (layout[dayIdx][row] == null) {
                        layout[dayIdx][row] = event
                        eventToRowMap[event] = row
                        break
                    }
                }
                break
            }
        }
    }
    
    // Render the multi-day event rows
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(100.dp), // Increased to match calendar cell height
        verticalArrangement = Arrangement.spacedBy(1.dp)
    ) {
        // Skip space for day number (24dp) + spacing
        Spacer(modifier = Modifier.height(24.dp))
        
        // Render event rows
        for (row in 0 until CHIP_ROW_MAX) {
            ConnectedMultiDayEventRow(
                weekDates = weekDates,
                eventRow = layout.map { it[row] },
                currentMonth = currentMonth
            )
        }
    }
}

@Composable
private fun ConnectedMultiDayEventRow(
    weekDates: List<LocalDate>,
    eventRow: List<Event?>, // One event per day (or null)
    currentMonth: LocalDate
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(12.dp)
            .padding(horizontal = 8.dp), // Apply padding to entire row, not individual cells
        horizontalArrangement = Arrangement.spacedBy(0.dp) // NO spacing between day segments
    ) {
        eventRow.forEachIndexed { dayIndex, event ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(12.dp)
                    // NO horizontal padding - this was breaking the connection!
            ) {
                if (event != null) {
                    val date = weekDates[dayIndex]
                    val isCurrentMonth = date.monthNumber == currentMonth.monthNumber
                    
                    if (isCurrentMonth) {
                        if (event.isMultiDay) {
                            // Multi-day event with connected appearance
                            ConnectedMultiDayChip(
                                event = event,
                                date = date,
                                dayIndex = dayIndex,
                                weekDates = weekDates
                            )
                        } else {
                            // Single-day event (all-day or regular)
                            SingleDayEventChipInGrid(event = event)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ConnectedMultiDayChip(
    event: Event,
    date: LocalDate,
    dayIndex: Int,
    weekDates: List<LocalDate>
) {
    val isEventStartDay = date == event.startTime.date
    val isEventEndDay = date == event.endTime.date
    
    // Determine shape for seamless connection
    val chipShape = when {
        isEventStartDay && isEventEndDay -> RoundedCornerShape(4.dp) // Single day
        isEventStartDay -> RoundedCornerShape(topStart = 4.dp, bottomStart = 4.dp, topEnd = 0.dp, bottomEnd = 0.dp)
        isEventEndDay -> RoundedCornerShape(topStart = 0.dp, bottomStart = 0.dp, topEnd = 4.dp, bottomEnd = 4.dp)
        else -> RoundedCornerShape(0.dp) // Middle days - fully connected
    }
    
    val shouldShowVerticalBar = isEventStartDay || dayIndex == 0
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(12.dp)
            .background(event.color.copy(alpha = 0.3f), chipShape)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxSize()
        ) {
            // Vertical color bar
            if (shouldShowVerticalBar) {
                Box(
                    modifier = Modifier
                        .width(3.dp)
                        .height(12.dp)
                        .background(event.color)
                )
            }
            
            // Event name (only on start day or first day of week)
            if (shouldShowVerticalBar) {
                Text(
                    text = if (event.name.length > 8) {
                        event.name.take(6) + "..."
                    } else {
                        event.name
                    },
                    fontSize = 8.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun SingleDayEventChipInGrid(event: Event) {
    if (event.isAllDay) {
        // All-day event - background with brighter color (like iOS)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(12.dp)
                .background(event.color.copy(alpha = 0.3f), RoundedCornerShape(4.dp))
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxSize()
            ) {
                Box(
                    modifier = Modifier
                        .width(3.dp)
                        .height(12.dp)
                        .background(event.color)
                )
                Text(
                    text = if (event.name.length > 8) {
                        event.name.take(6) + "..."
                    } else {
                        event.name
                    },
                    fontSize = 8.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }
        }
    } else {
        // Regular single-day event - transparent with vertical bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(12.dp)
                    .background(event.color)
            )
            Text(
                text = if (event.name.length > 8) {
                    event.name.take(6) + "..."
                } else {
                    event.name
                },
                fontSize = 8.sp,
                color = Color.White,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(start = 4.dp)
            )
        }
    }
}

@Composable
private fun DaysOfWeekHeader() {
    val daysOfWeek = listOf("S", "M", "T", "W", "T", "F", "S")
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.Black)
            .padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        daysOfWeek.forEachIndexed { index, day ->
            Box(
                modifier = Modifier.weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = day,
                    textAlign = TextAlign.Center,
                    fontSize = 12.sp, // Smaller font like iOS
                    fontWeight = FontWeight.Normal,
                    color = if (index == 0 || index == 6) Color(0xFFFF3B30) else Color(0xFF8E8E93) // iOS colors
                )
            }
        }
    }
}

// Event layout algorithm like iOS WeekRowView
private fun createEventLayout(
    weekDates: List<LocalDate>,
    eventsByDate: Map<LocalDate, List<Event>>,
    chipRowMax: Int = 4
): EventLayout {
    val layout = Array(7) { Array<Event?>(chipRowMax) { null } }
    
    // Step 1: Get all multi-day events for this week
    val allEvents = weekDates.flatMap { eventsByDate[it] ?: emptyList() }
    val multiDayEvents = allEvents.filter { it.isMultiDay }.distinctBy { "${it.id}-${it.startTime}" }
        .sortedBy { it.startTime }
    
    // Step 2: Assign multi-day events to rows
    for (event in multiDayEvents) {
        val eventRange = getEventRangeInWeek(event, weekDates)
        if (eventRange != null) {
            // Find available row for this event across all its days
            var assignedRow: Int? = null
            for (row in 0 until CHIP_ROW_MAX) {
                var canUseRow = true
                for (dayIdx in eventRange.first..eventRange.second) {
                    if (layout[dayIdx][row] != null) {
                        canUseRow = false
                        break
                    }
                }
                if (canUseRow) {
                    assignedRow = row
                    break
                }
            }
            
            // Assign the event to the found row
            assignedRow?.let { row ->
                for (dayIdx in eventRange.first..eventRange.second) {
                    layout[dayIdx][row] = event
                }
            }
        }
    }
    
    // Step 3: Assign single-day events to remaining slots
    for ((dayIdx, date) in weekDates.withIndex()) {
        val singleDayEvents = (eventsByDate[date] ?: emptyList()).filter { !it.isMultiDay }
        var placedSingleDayEvents = 0
        
        for (row in 0 until CHIP_ROW_MAX) {
            if (layout[dayIdx][row] == null && placedSingleDayEvents < singleDayEvents.size) {
                layout[dayIdx][row] = singleDayEvents[placedSingleDayEvents]
                placedSingleDayEvents++
            }
        }
    }
    
    return EventLayout(layout, chipRowMax)
}

private fun getEventRangeInWeek(event: Event, weekDates: List<LocalDate>): Pair<Int, Int>? {
    val eventStart = event.startTime.date
    val eventEnd = event.endTime.date
    
    // Find start and end indices within this week
    val startIdx = weekDates.indexOfFirst { it >= eventStart }.takeIf { it >= 0 } ?: 0
    val endIdx = weekDates.indexOfLast { it <= eventEnd }.takeIf { it >= 0 } ?: 6
    
    // Only return if the event actually spans into this week
    return if (startIdx <= endIdx && endIdx >= 0 && startIdx <= 6) {
        Pair(maxOf(0, startIdx), minOf(6, endIdx))
    } else null
}

private fun getEventDurationInDays(event: Event): Int {
    val eventStart = event.startTime.date
    val eventEnd = event.endTime.date
    
    // Calculate total duration of event (not just within this week)
    return try {
        val startDay = eventStart.toEpochDays()
        val endDay = eventEnd.toEpochDays()
        (endDay - startDay + 1).toInt()
    } catch (e: Exception) {
        1 // Default to 1 day if calculation fails
    }
}


// Data class to represent the event layout grid like iOS
data class EventLayout(
    val grid: Array<Array<Event?>>, // [dayIndex][rowIndex] = Event?
    val chipRowMax: Int = 4
)

@Composable
private fun CalendarDayCell(
    date: LocalDate,
    dayIndex: Int, // Index within the week (0-6)
    isCurrentMonth: Boolean,
    isSelected: Boolean,
    eventLayout: EventLayout,
    shouldHighlightDate: (LocalDate) -> Boolean,
    onDateSelected: () -> Unit
) {
    // iOS styling - selected date gets white background with black text
    val backgroundColor = when {
        isSelected -> Color.White
        else -> Color.Transparent
    }
    
    val shouldHighlight = shouldHighlightDate(date)

    val textColor = when {
        !isCurrentMonth -> Color.Gray
        isSelected -> Color.Black // Black text on white background for selected
        shouldHighlight -> {
            if (isCurrentMonth) {
                Color(0xFFFF3B30) // Red for highlighted dates (weekends/holidays) in current month
            } else {
                Color(0xFFFF3B30).copy(alpha = 0.5f) // Dimmed red for highlighted dates in other months
            }
        }
        else -> Color.White // White text on black background
    }

    Box(
        modifier = Modifier
            .height(100.dp) // Increased height to accommodate 4 events without overlap
            .fillMaxWidth()
            .clip(RoundedCornerShape(if (isSelected) 6.dp else 0.dp))
            .background(backgroundColor)
            .clickable { onDateSelected() }
            .padding(2.dp),
        contentAlignment = Alignment.TopCenter
    ) {
        // ZStack-like layered approach
        Box(modifier = Modifier.fillMaxSize()) {
            // Background layer for day number
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Top,
                modifier = Modifier.fillMaxSize()
            ) {
                // Day number - centered at top
                Text(
                    text = date.dayOfMonth.toString(),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Normal,
                    color = textColor,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            // Events layer - ZStack-like approach
            if (isCurrentMonth && dayIndex < eventLayout.grid.size) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 2.dp)
                        .padding(top = 24.dp), // Start below day number
                    verticalArrangement = Arrangement.spacedBy(1.dp)
                ) {
                    // Multi-day events layer (background chips)
                    for (rowIndex in 0 until eventLayout.chipRowMax) {
                        val event = eventLayout.grid[dayIndex][rowIndex]
                        if (event != null && event.isMultiDay) {
                            MultiDayEventChip(
                                event = event,
                                date = date,
                                dayIndex = dayIndex,
                                isEventStartDay = date == event.startTime.date
                            )
                        } else if (event != null && !event.isMultiDay) {
                            // Single-day event chip
                            SingleDayEventChip(event = event)
                        } else {
                            // Empty space to maintain row alignment
                            Box(modifier = Modifier.height(12.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MultiDayEventChip(
    event: Event,
    date: LocalDate,
    dayIndex: Int,
    isEventStartDay: Boolean
) {
    val isEventEndDay = date == event.endTime.date
    
    // Determine rounded corners for connected appearance
    val chipShape = when {
        isEventStartDay && isEventEndDay -> RoundedCornerShape(2.dp) // Single day (shouldn't happen for multi-day)
        isEventStartDay -> RoundedCornerShape(topStart = 2.dp, bottomStart = 2.dp, topEnd = 0.dp, bottomEnd = 0.dp)
        isEventEndDay -> RoundedCornerShape(topStart = 0.dp, bottomStart = 0.dp, topEnd = 2.dp, bottomEnd = 2.dp)
        else -> RoundedCornerShape(0.dp) // Middle days - no rounded corners for connected look
    }
    
    // Show vertical bar only on start day or first day of week (like iOS)
    val shouldShowVerticalBar = isEventStartDay || dayIndex == 0
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(12.dp)
            .background(event.color.copy(alpha = 0.2f), chipShape)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxSize()
        ) {
            // Vertical color bar (conditional)
            if (shouldShowVerticalBar) {
                Box(
                    modifier = Modifier
                        .width(3.dp)
                        .height(12.dp)
                        .background(event.color)
                )
            }
            
            // Event name (only show on start day or first day of week)
            if (shouldShowVerticalBar) {
                Text(
                    text = if (event.name.length > 6) {
                        event.name.take(4) + "..."
                    } else {
                        event.name
                    },
                    fontSize = 8.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(start = 6.dp)
                )
            }
        }
    }
}

@Composable
private fun SingleDayEventChip(event: Event) {
    if (event.isAllDay) {
        // All-day event - background with brighter color (like iOS)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(12.dp)
                .background(event.color.copy(alpha = 0.2f), RoundedCornerShape(2.dp))
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxSize()
            ) {
                Box(
                    modifier = Modifier
                        .width(3.dp)
                        .height(12.dp)
                        .background(event.color)
                )
                Text(
                    text = if (event.name.length > 6) {
                        event.name.take(4) + "..."
                    } else {
                        event.name
                    },
                    fontSize = 8.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(start = 2.dp)
                )
            }
        }
    } else {
        // Regular single-day event - transparent with vertical bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(12.dp)
                .background(Color.Transparent, RoundedCornerShape(2.dp)),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(12.dp)
                    .background(event.color)
            )
            Text(
                text = if (event.name.length > 6) {
                    event.name.take(4) + "..."
                } else {
                    event.name
                },
                fontSize = 8.sp,
                color = Color.White,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(start = 2.dp)
            )
        }
    }
}

// Event layout functions

private fun generateWeeksForMonth(currentMonth: LocalDate): List<List<LocalDate>> {
    val year = currentMonth.year
    val month = currentMonth.monthNumber
    
    // Get the first day of the month
    val firstDayOfMonth = LocalDate(year, month, 1)
    val daysInMonth = when (month) {
        1, 3, 5, 7, 8, 10, 12 -> 31
        4, 6, 9, 11 -> 30
        2 -> if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) 29 else 28
        else -> 30
    }
    
    // Calculate start date - DayOfWeek.SUNDAY = 7, MONDAY = 1, etc.
    // We want Sunday = 0, Monday = 1, etc. for calendar layout
    val firstDayOfWeek = if (firstDayOfMonth.dayOfWeek.value == 7) 0 else firstDayOfMonth.dayOfWeek.value
    val startDayOfMonth = 1 - firstDayOfWeek
    
    // Generate 42 days (6 weeks) and chunk into weeks
    val dates = (0 until 42).map { dayOffset ->
        val day = startDayOfMonth + dayOffset
        when {
            day <= 0 -> {
                val prevMonth = if (month == 1) 12 else month - 1
                val prevYear = if (month == 1) year - 1 else year
                val prevMonthDays = when (prevMonth) {
                    1, 3, 5, 7, 8, 10, 12 -> 31
                    4, 6, 9, 11 -> 30
                    2 -> if (prevYear % 4 == 0 && (prevYear % 100 != 0 || prevYear % 400 == 0)) 29 else 28
                    else -> 30
                }
                LocalDate(prevYear, prevMonth, prevMonthDays + day)
            }
            day > daysInMonth -> {
                val nextMonth = if (month == 12) 1 else month + 1
                val nextYear = if (month == 12) year + 1 else year
                LocalDate(nextYear, nextMonth, day - daysInMonth)
            }
            else -> LocalDate(year, month, day)
        }
    }
    
    return dates.chunked(7) // Split into weeks of 7 days each
}

@Composable
private fun WeekRowView(
    weekDates: List<LocalDate>,
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    eventsByDate: Map<LocalDate, List<Event>>,
    today: LocalDate,
    isDebugMode: Boolean,
    shouldHighlightDate: (LocalDate) -> Boolean,
    onDateSelected: (LocalDate) -> Unit,
    onMonthChanged: (LocalDate) -> Unit
) {
    // Calculate event layout for this week only (like iOS WeekRowView)
    val eventLayout = createEventLayoutForWeek(weekDates, eventsByDate)
    
    // iOS ZStack with background layer spanning full day cells
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(100.dp) // Fixed height like iOS
            .let { modifier ->
                if (isDebugMode) {
                    modifier.border(2.dp, Color.Green)
                } else {
                    modifier
                }
            },
        contentAlignment = Alignment.TopStart
    ) {
        // Background layer for full day cell highlighting
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            weekDates.forEach { date ->
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .background(
                            color = dayBackgroundColor(date, selectedDate, today, currentMonth),
                            shape = RoundedCornerShape(6.dp) // iOS cornerRadius: 6
                        )
                        .clickable { 
                            onDateSelected(date)
                            if (date.monthNumber != currentMonth.monthNumber) {
                                onMonthChanged(date)
                            }
                        }
                )
            }
        }
        
        // Content layer on top of background
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // DateNumbers row first
            DateNumbersRow(
                weekDates = weekDates,
                currentMonth = currentMonth,
                selectedDate = selectedDate,
                today = today,
                isDebugMode = isDebugMode,
                shouldHighlightDate = shouldHighlightDate,
                onDateSelected = onDateSelected,
                onMonthChanged = onMonthChanged
            )
            
            // EventsAreaView with overlaid events per week  
            EventsAreaView(
                weekDates = weekDates,
                eventLayout = eventLayout,
                selectedDate = selectedDate,
                isDebugMode = isDebugMode
            )
        }
    }
}

// Event layout function for individual weeks
private fun createEventLayoutForWeek(
    weekDates: List<LocalDate>,
    eventsByDate: Map<LocalDate, List<Event>>
): Array<Array<Event?>> {
    // Exactly like iOS WeekRowView.eventLayout
    val layout = Array(DAYS_PER_WEEK) { Array<Event?>(CHIP_ROW_MAX) { null } }
    
    // Step 1: Layout multi-day events  
    val allEvents = weekDates.flatMap { eventsByDate[it] ?: emptyList() }
    val multiDayEvents = allEvents.filter { it.isMultiDay }.distinctBy { "${it.id}-${it.startTime}" }
        .sortedBy { it.startTime }
    
    for (event in multiDayEvents) {
        val eventRange = getEventRangeInWeek(event, weekDates)
        if (eventRange != null) {
            // Find available row for this event across all its days
            var assignedRow: Int? = null
            for (row in 0 until CHIP_ROW_MAX) {
                var canUseRow = true
                for (dayIdx in eventRange.first..eventRange.second) {
                    if (layout[dayIdx][row] != null) {
                        canUseRow = false
                        break
                    }
                }
                if (canUseRow) {
                    assignedRow = row
                    break
                }
            }
            
            // Assign the event to the found row
            assignedRow?.let { row ->
                for (dayIdx in eventRange.first..eventRange.second) {
                    layout[dayIdx][row] = event
                }
            }
        }
    }
    
    // Step 2: Layout single-day events
    for ((dayIdx, date) in weekDates.withIndex()) {
        val singleDayEvents = (eventsByDate[date] ?: emptyList()).filter { !it.isMultiDay }
        var placedSingleDayEvents = 0
        
        for (row in 0 until CHIP_ROW_MAX) {
            if (layout[dayIdx][row] == null && placedSingleDayEvents < singleDayEvents.size) {
                layout[dayIdx][row] = singleDayEvents[placedSingleDayEvents]
                placedSingleDayEvents++
            }
        }
    }
    
    return layout
}

@Composable
private fun DateNumbersRow(
    weekDates: List<LocalDate>,
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    today: LocalDate,
    isDebugMode: Boolean,
    shouldHighlightDate: (LocalDate) -> Boolean,
    onDateSelected: (LocalDate) -> Unit,
    onMonthChanged: (LocalDate) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(DATE_ROW_HEIGHT_DP.dp)
            .let { modifier ->
                if (isDebugMode) {
                    modifier.border(1.dp, Color.Yellow)
                } else {
                    modifier
                }
            },
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        weekDates.forEach { date ->
            Box(
                modifier = Modifier.weight(1f),
                contentAlignment = Alignment.Center
            ) {
                DateNumberCell(
                    date = date,
                    isCurrentMonth = date.monthNumber == currentMonth.monthNumber,
                    isSelected = date == selectedDate,
                    isDebugMode = isDebugMode,
                    shouldHighlightDate = shouldHighlightDate
                )
            }
        }
    }
}

@Composable
private fun DateNumberCell(
    date: LocalDate,
    isCurrentMonth: Boolean,
    isSelected: Boolean,
    isDebugMode: Boolean,
    shouldHighlightDate: (LocalDate) -> Boolean
) {
    val shouldHighlight = shouldHighlightDate(date)
    val textColor = when {
        !isCurrentMonth -> Color.Gray
        isSelected -> Color.Black // Black text on white background for selected
        shouldHighlight -> {
            if (isCurrentMonth) {
                Color(0xFFFF3B30) // Red for highlighted dates (weekends/holidays) in current month
            } else {
                Color(0xFFFF3B30).copy(alpha = 0.5f) // Dimmed red for highlighted dates in other months
            }
        }
        else -> Color.White // White text on black background
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .let { modifier: Modifier ->
                if (isDebugMode) {
                    modifier.border(1.dp, Color.Blue)
                } else {
                    modifier
                }
            },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = date.dayOfMonth.toString(),
            fontSize = 16.sp,
            fontWeight = FontWeight.Normal,
            color = textColor
        )
    }
}

// iOS-exact EventsAreaView structure
@Composable
private fun EventsAreaView(
    weekDates: List<LocalDate>,
    eventLayout: Array<Array<Event?>>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    // iOS ZStack(alignment: .topLeading)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height((CHIP_ROW_MAX * CHIP_HEIGHT_DP + CHIP_ROW_MAX).dp) // 4 rows * 16dp + spacing
            .let { modifier: Modifier ->
                if (isDebugMode) {
                    modifier.border(1.dp, Color.Magenta)
                } else {
                    modifier
                }
            },
        contentAlignment = Alignment.TopStart
    ) {
        // Multi-day events layer
        MultiDayLanesView(
            weekDates = weekDates,
            eventLayout = eventLayout,
            selectedDate = selectedDate,
            isDebugMode = isDebugMode
        )
        
        // Single-day events layer (overlaid)
        SingleDayChipsView(
            weekDates = weekDates,
            eventLayout = eventLayout,
            selectedDate = selectedDate,
            isDebugMode = isDebugMode
        )
    }
}

// iOS-exact MultiDayLanesView
@Composable
private fun MultiDayLanesView(
    weekDates: List<LocalDate>,
    eventLayout: Array<Array<Event?>>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    // iOS VStack(spacing: 0)
    Column(
        verticalArrangement = Arrangement.spacedBy(0.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        for (row in 0 until CHIP_ROW_MAX) {
            MultiDayLanesRow(
                row = row,
                weekDates = weekDates,
                eventLayout = eventLayout,
                selectedDate = selectedDate,
                isDebugMode = isDebugMode
            )
        }
    }
}

// iOS-exact MultiDayLanesRow - single spanning chips
@Composable
private fun MultiDayLanesRow(
    row: Int,
    weekDates: List<LocalDate>,
    eventLayout: Array<Array<Event?>>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxWidth()
            .height(CHIP_HEIGHT_DP.dp)
    ) {
        val totalWidth = maxWidth
        val dayWidth = totalWidth / DAYS_PER_WEEK
        
        // Find unique multi-day events in this row
        val processedEvents = mutableSetOf<Event>()
        
        weekDates.forEachIndexed { dayIndex, _ ->
            val event = eventLayout[dayIndex][row]
            if (event != null && event.isMultiDay && !processedEvents.contains(event)) {
                processedEvents.add(event)
                
                // Calculate span for this event in this week
                val startDayIndex = weekDates.indexOfFirst { it >= event.startTime.date }
                    .let { if (it == -1) 0 else it }
                val endDayIndex = weekDates.indexOfLast { it <= event.endTime.date }
                    .let { if (it == -1) weekDates.size - 1 else it }
                
                if (startDayIndex <= endDayIndex) {
                    MultiDayEventChip(
                        event = event,
                        startDayIndex = startDayIndex,
                        endDayIndex = endDayIndex,
                        dayWidth = dayWidth,
                        weekDates = weekDates,
                        selectedDate = selectedDate,
                        isDebugMode = isDebugMode
                    )
                }
            }
        }
    }
}

// Simplified MultiDayEventChip - single spanning chip with always-visible name
@Composable
private fun MultiDayEventChip(
    event: Event,
    startDayIndex: Int,
    endDayIndex: Int,
    dayWidth: Dp,
    weekDates: List<LocalDate>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    val spanDays = endDayIndex - startDayIndex + 1
    val chipWidth = dayWidth * spanDays
    val offsetX = dayWidth * startDayIndex
    
    val isEventStartDay = event.startTime.date == weekDates[startDayIndex]
    val isEventEndDay = event.endTime.date == weekDates[endDayIndex]
    
    val chipShape = when {
        isEventStartDay && isEventEndDay -> RoundedCornerShape(4.dp)
        isEventStartDay -> RoundedCornerShape(topStart = 4.dp, bottomStart = 4.dp, topEnd = 0.dp, bottomEnd = 0.dp)
        isEventEndDay -> RoundedCornerShape(topStart = 0.dp, bottomStart = 0.dp, topEnd = 4.dp, bottomEnd = 4.dp)
        else -> RoundedCornerShape(0.dp)
    }
    
    Box(
        modifier = Modifier
            .size(width = chipWidth, height = CHIP_HEIGHT_DP.dp)
            .offset(x = offsetX)
            .background(event.color.copy(alpha = 0.3f), chipShape)
            .then(if (isDebugMode) Modifier.border(1.dp, Color.Green) else Modifier)
    ) {
        // Vertical color bar (like iOS background layer)
        if (isEventStartDay || startDayIndex == 0) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(CHIP_HEIGHT_DP.dp)
                    .background(event.color)
                    .align(Alignment.CenterStart)
            )
        }
        
        // Text overlay (like iOS .overlay layer) - padding from absolute left edge
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(start = if (isEventStartDay || startDayIndex == 0) 6.dp else 3.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = event.name,
                fontSize = 10.sp,
                color = eventTextColor(event, weekDates[startDayIndex], selectedDate),
                fontWeight = FontWeight.Normal,
                overflow = TextOverflow.Ellipsis,
                maxLines = 1
            )
        }
    }
}

// iOS-exact MultiDayEventChip logic
@Composable
private fun RowScope.MultiDayEventChipOrEmpty(
    event: Event?,
    dayIndex: Int,
    dayDate: LocalDate,
    weekDates: List<LocalDate>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    if (event != null && event.isMultiDay) {
        // Multi-day event chip
        MultiDayEventChip(
            event = event,
            dayIndex = dayIndex,
            dayDate = dayDate,
            weekDates = weekDates,
            selectedDate = selectedDate,
            isDebugMode = isDebugMode
        )
    } else {
        // Empty space - iOS Rectangle().fill(Color.clear)
        Box(
            modifier = Modifier
                .weight(1f)
                .height(CHIP_HEIGHT_DP.dp)
                .let { modifier ->
                    if (isDebugMode) {
                        modifier.border(1.dp, Color.Gray.copy(alpha = 0.3f))
                    } else {
                        modifier
                    }
                }
        )
    }
}

// iOS-exact MultiDayEventChip
@Composable
private fun RowScope.MultiDayEventChip(
    event: Event,
    dayIndex: Int,
    dayDate: LocalDate,
    weekDates: List<LocalDate>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    val shouldShowVerticalBar = isEventStartDay(event, dayDate) || dayIndex == 0
    val shouldShowName = shouldShowEventName(event, dayIndex, weekDates)
    
    // iOS HStack(spacing: 0)
    Row(
        modifier = Modifier
            .weight(1f)
            .height(CHIP_HEIGHT_DP.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // Vertical color bar (conditional) - iOS Rectangle().fill(event.calendarColor).frame(width: 3)
        if (shouldShowVerticalBar) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .fillMaxHeight()
                    .background(event.color)
            )
        }
        
        // Background with brighter color - iOS Rectangle().fill(event.calendarColor.opacity(0.2)).frame(maxWidth: .infinity)
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .background(event.color.copy(alpha = 0.2f)) // NO rounded corners for connection
                .let { modifier ->
                    if (isDebugMode) {
                        modifier.border(1.dp, Color.Cyan)
                    } else {
                        modifier
                    }
                }
        ) {
            // iOS overlay with HStack
            Row(
                modifier = Modifier.fillMaxSize(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (shouldShowName) {
                    Text(
                        text = event.name,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Normal,
                        color = eventTextColor(event, dayDate, selectedDate),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(start = if (shouldShowVerticalBar) 6.dp else 3.dp)
                    )
                }
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

// iOS-exact SingleDayChipsView
@Composable  
private fun SingleDayChipsView(
    weekDates: List<LocalDate>,
    eventLayout: Array<Array<Event?>>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    // iOS VStack(spacing: 0)
    Column(
        verticalArrangement = Arrangement.spacedBy(0.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        for (row in 0 until CHIP_ROW_MAX) {
            SingleDayChipsRow(
                row = row,
                weekDates = weekDates,
                eventLayout = eventLayout,
                selectedDate = selectedDate,
                isDebugMode = isDebugMode
            )
        }
    }
}

// iOS-exact SingleDayChipsRow
@Composable
private fun SingleDayChipsRow(
    row: Int,
    weekDates: List<LocalDate>,
    eventLayout: Array<Array<Event?>>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    // iOS HStack(spacing: daySpacing)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(CHIP_HEIGHT_DP.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        for (dayIndex in weekDates.indices) {
            SingleDayEventChipOrEmpty(
                event = eventLayout[dayIndex][row],
                dayIndex = dayIndex,
                weekDates = weekDates,
                selectedDate = selectedDate,
                isDebugMode = isDebugMode
            )
        }
    }
}

// iOS-exact SingleDayEventChip logic
@Composable
private fun RowScope.SingleDayEventChipOrEmpty(
    event: Event?,
    dayIndex: Int,
    weekDates: List<LocalDate>,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    if (event != null && !event.isMultiDay) {
        // Single-day event chip
        SingleDayEventChip(
            event = event,
            eventDate = weekDates[dayIndex],
            selectedDate = selectedDate,
            isDebugMode = isDebugMode
        )
    } else {
        // Empty space
        Box(
            modifier = Modifier
                .weight(1f)
                .height(CHIP_HEIGHT_DP.dp)
        )
    }
}

// iOS-exact SingleDayEventChip
@Composable
private fun RowScope.SingleDayEventChip(
    event: Event,
    eventDate: LocalDate,
    selectedDate: LocalDate,
    isDebugMode: Boolean
) {
    // iOS HStack(spacing: 0)
    Row(
        modifier = Modifier
            .weight(1f)
            .height(CHIP_HEIGHT_DP.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // Vertical color bar - iOS Rectangle().fill(event.calendarColor).frame(width: 3)
        Box(
            modifier = Modifier
                .width(3.dp)
                .fillMaxHeight()
                .background(event.color)
        )
        
        if (event.isAllDay) {
            // All-day events: background with brighter color - iOS Rectangle().fill(event.calendarColor.opacity(0.2))
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .background(event.color.copy(alpha = 0.2f))
                    .let { modifier ->
                        if (isDebugMode) {
                            modifier.border(1.dp, Color.Yellow)
                        } else {
                            modifier
                        }
                    }
            ) {
                // iOS overlay
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = event.name,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Normal,
                        color = eventTextColor(event, eventDate, selectedDate),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(start = 6.dp)
                    )
                }
            }
        } else {
            // Regular events: no background color - iOS Rectangle().fill(Color.clear)
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .let { modifier ->
                        if (isDebugMode) {
                            modifier.border(1.dp, Color.Yellow)
                        } else {
                            modifier
                        }
                    }
            ) {
                // iOS overlay
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = event.name,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Normal,
                        color = eventTextColor(event, eventDate, selectedDate),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(start = 6.dp)
                    )
                }
            }
        }
    }
}

// Helper functions matching iOS logic
private fun isEventStartDay(event: Event, dayDate: LocalDate): Boolean {
    return event.startTime.date == dayDate
}


// iOS-exact eventTextColor logic
@Composable
private fun eventTextColor(event: Event, eventDate: LocalDate, selectedDate: LocalDate): Color {
    val isDarkTheme = isSystemInDarkTheme()
    
    // Check if this event is on the selected date (iOS logic)
    if (eventDate == selectedDate) {
        // Use opposite color when day is selected - iOS Color(.systemBackground)
        return MaterialTheme.colorScheme.surface
    }
    
    // Default colors based on event type and theme
    return when {
        event.isAllDay -> Color.White // iOS: all-day events always use .white
        isDarkTheme -> Color.White    // Dark theme: white text
        else -> Color.Black           // Light theme: black text (iOS .primary)
    }
}

// Smart dayBackgroundColor logic with first day highlighting
@Composable
private fun dayBackgroundColor(date: LocalDate, selectedDate: LocalDate, today: LocalDate, currentMonth: LocalDate): Color {
    // Only apply highlighting if this date belongs to the current month being viewed
    val dateIsInCurrentMonth = date.year == currentMonth.year && date.monthNumber == currentMonth.monthNumber

    if (!dateIsInCurrentMonth) {
        // Date is from previous/next month - never highlight, even if selected
        return Color.Transparent
    }

    return when {
        date == selectedDate -> MaterialTheme.colorScheme.onSurface // iOS Color(.label)
        date == today -> Color(0xFF8E8E93).copy(alpha = 0.3f) // iOS Color(.systemGray4)
        shouldHighlightFirstDayOfCurrentMonth(date, currentMonth, today) -> Color(0xFF8E8E93).copy(alpha = 0.2f) // iOS Color(.systemGray5)
        else -> Color.Transparent // iOS .clear
    }
}

// Helper function to determine if first day should be highlighted
private fun shouldHighlightFirstDayOfCurrentMonth(date: LocalDate, currentMonth: LocalDate, today: LocalDate): Boolean {
    // Check if this date is the first day of its month
    val isFirstDayOfMonth = date.dayOfMonth == 1

    // Check if this date's month IS the current month being viewed
    val isCurrentMonth = date.year == currentMonth.year && date.monthNumber == currentMonth.monthNumber

    // Check if today is in the same month as the current month being viewed
    val todayIsInCurrentMonth = today.year == currentMonth.year && today.monthNumber == currentMonth.monthNumber

    // Only highlight first day if:
    // 1. It's the first day of its month
    // 2. AND that month is the same as the month we're currently viewing
    // 3. AND today is NOT in this month (to avoid redundant highlighting)
    return isFirstDayOfMonth && isCurrentMonth && !todayIsInCurrentMonth
}

private fun shouldShowEventName(event: Event, dayIndex: Int, weekDates: List<LocalDate>): Boolean {
    // Show name if this is the original start day in the week
    val eventStartDate = event.startTime.date
    val originalStartIdx = weekDates.indexOfFirst { it == eventStartDate }
    
    if (dayIndex == originalStartIdx) {
        return true
    }
    
    // Show name if this is the start of the week (Sunday, index 0) and event continues from previous week
    if (dayIndex == 0 && originalStartIdx < 0) {
        return true
    }
    
    return false
}

// New function to determine if event name should expand across multiple days
private fun shouldShowEventNameExpanded(event: Event, dayIndex: Int, weekDates: List<LocalDate>): Boolean {
    val eventStartDate = event.startTime.date
    val eventEndDate = event.endTime.date
    val originalStartIdx = weekDates.indexOfFirst { it == eventStartDate }
    val eventEndIdx = weekDates.indexOfFirst { it == eventEndDate }
    
    // Determine the starting day for showing the name
    val nameStartIdx = when {
        originalStartIdx >= 0 -> originalStartIdx // Event starts in this week
        else -> 0 // Event continues from previous week, start from Sunday
    }
    
    // Calculate how many characters can fit per day (rough estimate)
    // Assuming ~6-8 characters per day at 10sp font size
    val charsPerDay = 7
    val eventNameLength = event.name.length
    val daysNeeded = (eventNameLength + charsPerDay - 1) / charsPerDay // Ceiling division
    
    // Determine the range where event spans in this week
    val eventSpanEnd = when {
        eventEndIdx >= 0 -> eventEndIdx // Event ends in this week
        else -> weekDates.size - 1 // Event continues beyond this week
    }
    
    // Show name if current day is within the name expansion range
    val nameEndIdx = minOf(nameStartIdx + daysNeeded - 1, eventSpanEnd)
    
    return dayIndex in nameStartIdx..nameEndIdx
}

