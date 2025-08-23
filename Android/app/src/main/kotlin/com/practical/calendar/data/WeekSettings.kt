package com.practical.calendar.data

import android.content.Context
import android.content.SharedPreferences

object WeekSettings {
    private const val PREFS_NAME = "week_settings"
    private const val KEY_HIGHLIGHT_HOLIDAYS = "highlight_holidays"
    private const val KEY_HIGHLIGHT_SATURDAYS = "highlight_saturdays"
    private const val KEY_HIGHLIGHT_SUNDAYS = "highlight_sundays"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getHighlightHolidays(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_HIGHLIGHT_HOLIDAYS, true) // Default to true
    }

    fun getHighlightSaturdays(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_HIGHLIGHT_SATURDAYS, false) // Default to false
    }

    fun getHighlightSundays(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_HIGHLIGHT_SUNDAYS, true) // Default to true
    }

    fun setHighlightHolidays(context: Context, value: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_HIGHLIGHT_HOLIDAYS, value).apply()
    }

    fun setHighlightSaturdays(context: Context, value: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_HIGHLIGHT_SATURDAYS, value).apply()
    }

    fun setHighlightSundays(context: Context, value: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_HIGHLIGHT_SUNDAYS, value).apply()
    }
}