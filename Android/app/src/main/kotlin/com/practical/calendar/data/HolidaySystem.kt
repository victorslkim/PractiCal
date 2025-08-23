package com.practical.calendar.data

import kotlinx.datetime.LocalDate
import java.util.Calendar

// MARK: - Holiday System Protocol
interface HolidayProvider {
    val name: String
    fun isHoliday(date: LocalDate): Boolean
    fun getHolidays(year: Int): List<Holiday>
}

// MARK: - Holiday Model
data class Holiday(
    val name: String,
    val date: LocalDate,
    val type: HolidayType
)

enum class HolidayType {
    FEDERAL,
    RELIGIOUS,
    CULTURAL,
    REGIONAL
}

// MARK: - Holiday Date Helper
object HolidayDateHelper {

    /**
     * Get the nth occurrence of a weekday in a month
     * @param year Year
     * @param month Month (1-12)
     * @param weekday Weekday (1=Sunday, 2=Monday, etc.)
     * @param occurrence Which occurrence (1=first, 2=second, etc.)
     */
    fun nthWeekdayOfMonth(year: Int, month: Int, weekday: Int, occurrence: Int): LocalDate? {
        val calendar = Calendar.getInstance()
        calendar.set(year, month - 1, 1) // month is 0-based in Calendar

        val firstWeekday = calendar.get(Calendar.DAY_OF_WEEK)
        val daysToAdd = (weekday - firstWeekday + 7) % 7 + (occurrence - 1) * 7

        calendar.add(Calendar.DAY_OF_MONTH, daysToAdd)

        // Check if we're still in the same month
        if (calendar.get(Calendar.MONTH) != month - 1) {
            return null
        }

        return LocalDate(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Get the last occurrence of a weekday in a month
     * @param year Year
     * @param month Month (1-12)
     * @param weekday Weekday (1=Sunday, 2=Monday, etc.)
     */
    fun lastWeekdayOfMonth(year: Int, month: Int, weekday: Int): LocalDate? {
        val calendar = Calendar.getInstance()

        // Set to first day of next month, then subtract 1 to get last day of current month
        calendar.set(year, month, 1) // month is 0-based, so this is next month
        calendar.add(Calendar.DAY_OF_MONTH, -1)

        val lastWeekday = calendar.get(Calendar.DAY_OF_WEEK)
        val daysToSubtract = (lastWeekday - weekday + 7) % 7

        calendar.add(Calendar.DAY_OF_MONTH, -daysToSubtract)

        return LocalDate(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Create a date for a specific month and day
     * @param year Year
     * @param month Month (1-12)
     * @param day Day of month
     */
    fun fixedDate(year: Int, month: Int, day: Int): LocalDate {
        return LocalDate(year, month, day)
    }
}

// MARK: - US Federal Holidays Provider
class USFederalHolidayProvider : HolidayProvider {
    override val name = "US Federal Holidays"

    override fun isHoliday(date: LocalDate): Boolean {
        val holidays = getHolidays(date.year)
        return holidays.any { holiday ->
            holiday.date == date
        }
    }

    override fun getHolidays(year: Int): List<Holiday> {
        val holidays = mutableListOf<Holiday>()

        // New Year's Day — January 1
        holidays.add(Holiday("New Year's Day", HolidayDateHelper.fixedDate(year, 1, 1), HolidayType.FEDERAL))

        // Martin Luther King Jr. Day — Third Monday in January
        HolidayDateHelper.nthWeekdayOfMonth(year, 1, 2, 3)?.let { date ->
            holidays.add(Holiday("Martin Luther King Jr. Day", date, HolidayType.FEDERAL))
        }

        // Washington's Birthday (Presidents Day) — Third Monday in February
        HolidayDateHelper.nthWeekdayOfMonth(year, 2, 2, 3)?.let { date ->
            holidays.add(Holiday("Presidents Day", date, HolidayType.FEDERAL))
        }

        // Memorial Day — Last Monday in May
        HolidayDateHelper.lastWeekdayOfMonth(year, 5, 2)?.let { date ->
            holidays.add(Holiday("Memorial Day", date, HolidayType.FEDERAL))
        }

        // Juneteenth National Independence Day — June 19
        holidays.add(Holiday("Juneteenth", HolidayDateHelper.fixedDate(year, 6, 19), HolidayType.FEDERAL))

        // Independence Day — July 4
        holidays.add(Holiday("Independence Day", HolidayDateHelper.fixedDate(year, 7, 4), HolidayType.FEDERAL))

        // Labor Day — First Monday in September
        HolidayDateHelper.nthWeekdayOfMonth(year, 9, 2, 1)?.let { date ->
            holidays.add(Holiday("Labor Day", date, HolidayType.FEDERAL))
        }

        // Columbus Day / Indigenous Peoples' Day — Second Monday in October
        HolidayDateHelper.nthWeekdayOfMonth(year, 10, 2, 2)?.let { date ->
            holidays.add(Holiday("Columbus Day", date, HolidayType.FEDERAL))
        }

        // Veterans Day — November 11
        holidays.add(Holiday("Veterans Day", HolidayDateHelper.fixedDate(year, 11, 11), HolidayType.FEDERAL))

        // Thanksgiving Day — Fourth Thursday in November
        HolidayDateHelper.nthWeekdayOfMonth(year, 11, 5, 4)?.let { date ->
            holidays.add(Holiday("Thanksgiving", date, HolidayType.FEDERAL))
        }

        // Christmas Day — December 25
        holidays.add(Holiday("Christmas", HolidayDateHelper.fixedDate(year, 12, 25), HolidayType.FEDERAL))

        return holidays
    }
}

// MARK: - Holiday Manager
class HolidayManager(
    private var currentProvider: HolidayProvider = USFederalHolidayProvider()
) {

    /**
     * Switch to a different holiday provider
     */
    fun setProvider(provider: HolidayProvider) {
        this.currentProvider = provider
    }

    /**
     * Check if a date is a holiday using the current provider
     */
    fun isHoliday(date: LocalDate): Boolean {
        return currentProvider.isHoliday(date)
    }

    /**
     * Get all holidays for a year using the current provider
     */
    fun getHolidays(year: Int): List<Holiday> {
        return currentProvider.getHolidays(year)
    }

    /**
     * Get the name of the current holiday provider
     */
    val providerName: String
        get() = currentProvider.name
}