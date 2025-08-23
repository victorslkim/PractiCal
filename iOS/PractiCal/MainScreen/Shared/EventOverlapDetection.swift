import Foundation

// Shared event overlap detection and layout calculation logic
struct EventLayoutCalculator {
    
    struct EventLayout {
        let event: Event
        let columnIndex: Int
        let totalColumns: Int
        let dayIndex: Int? // Optional for compatibility with DayView (which doesn't need dayIndex)
        
        init(event: Event, columnIndex: Int, totalColumns: Int, dayIndex: Int? = nil) {
            self.event = event
            self.columnIndex = columnIndex
            self.totalColumns = totalColumns
            self.dayIndex = dayIndex
        }
    }
    
    static func calculateEventLayouts(events: [Event], dayIndex: Int? = nil) -> [EventLayout] {
        let sortedEvents = events.sorted { $0.time < $1.time }
        var layouts: [EventLayout] = []
        
        // Group overlapping events together using transitive closure
        var eventGroups: [[Event]] = []
        
        for event in sortedEvents {
            var mergedGroups: [[Event]] = []
            var eventAdded = false
            
            // Find all groups that this event overlaps with
            for group in eventGroups {
                if group.contains(where: { existingEvent in
                    eventsOverlap(event1: event, event2: existingEvent)
                }) {
                    // This event overlaps with this group
                    if !eventAdded {
                        // First overlapping group - add event to it
                        mergedGroups.append(group + [event])
                        eventAdded = true
                    } else {
                        // Additional overlapping group - merge with the first one
                        if let lastIndex = mergedGroups.indices.last {
                            mergedGroups[lastIndex] += group
                        }
                    }
                } else {
                    // No overlap with this group - keep it separate
                    mergedGroups.append(group)
                }
            }
            
            // If event doesn't overlap with any existing group, create new group
            if !eventAdded {
                mergedGroups.append([event])
            }
            
            eventGroups = mergedGroups
        }
        
        // Now assign columns within each group
        for group in eventGroups {
            let sortedGroup = group.sorted { $0.time < $1.time }
            var columns: [[Event]] = []
            
            for event in sortedGroup {
                var columnIndex = 0
                var placed = false
                
                // Try to place in existing columns
                for (index, column) in columns.enumerated() {
                    if !overlapsWithColumn(event: event, column: column) {
                        columns[index].append(event)
                        columnIndex = index
                        placed = true
                        break
                    }
                }
                
                // If can't place in existing column, create new column
                if !placed {
                    columns.append([event])
                    columnIndex = columns.count - 1
                }
                
                layouts.append(EventLayout(
                    event: event,
                    columnIndex: columnIndex,
                    totalColumns: columns.count,
                    dayIndex: dayIndex
                ))
            }
            
            // Update totalColumns for all events in this group
            let totalColumns = columns.count
            for i in layouts.indices {
                if group.contains(where: { $0.id == layouts[i].event.id }) {
                    layouts[i] = EventLayout(
                        event: layouts[i].event,
                        columnIndex: layouts[i].columnIndex,
                        totalColumns: totalColumns,
                        dayIndex: layouts[i].dayIndex
                    )
                }
            }
        }
        
        return layouts
    }
    
    private static func overlapsWithColumn(event: Event, column: [Event]) -> Bool {
        return column.contains { existingEvent in
            eventsOverlap(event1: event, event2: existingEvent)
        }
    }
    
    private static func eventsOverlap(event1: Event, event2: Event) -> Bool {
        let start1 = event1.time
        let end1 = event1.endTime
        let start2 = event2.time
        let end2 = event2.endTime
        
        // Events overlap if one starts before the other ends
        return start1 < end2 && start2 < end1
    }
}